#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  review-with-claude.sh [--staged] [--base <ref>] [--output <file>] [--context <text>] [--model <name>] [--help]

Options:
  --staged          Review staged changes with git diff --cached.
  --base <ref>      Review changes against a base ref, for example origin/main.
  --output <file>   Write the Claude review to this file.
                    Default: .codex/skills/review-claude/reports/review-<timestamp>.md
  --context <text>  Add short task or test context to the review prompt.
  --model <name>    Claude Code model alias/name. Default: sonnet.
                    Use opus when the user explicitly asks for Opus.
  --help            Show this help.

Default mode reviews unstaged and staged working tree changes with git diff HEAD.

Environment:
  CLAUDE_REVIEW_MODEL            Claude model alias/name. Default: sonnet
  CLAUDE_REVIEW_MAX_BUDGET_USD   Per-run spend cap. Default: 0.25
  CLAUDE_REVIEW_COST_FILE        Cost log path from repo root. Default: cost.txt
  CLAUDE_REVIEW_TIMEOUT_SECONDS  Timeout. Default: 120
USAGE
}

mode="head"
base_ref=""
extra_context=""
model_override=""
timestamp="$(date +%Y%m%d-%H%M%S)"
output=".codex/skills/review-claude/reports/review-${timestamp}.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged)
      mode="staged"
      shift
      ;;
    --base)
      mode="base"
      base_ref="${2:-}"
      if [[ -z "$base_ref" ]]; then
        echo "Missing value for --base" >&2
        exit 2
      fi
      shift 2
      ;;
    --output)
      output="${2:-}"
      if [[ -z "$output" ]]; then
        echo "Missing value for --output" >&2
        exit 2
      fi
      shift 2
      ;;
    --context)
      extra_context="${2:-}"
      shift 2
      ;;
    --model)
      model_override="${2:-}"
      if [[ -z "$model_override" ]]; then
        echo "Missing value for --model" >&2
        exit 2
      fi
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "This script must run inside a git repository." >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ANTHROPIC_API_KEY is not set. Add it to .env or export it before running." >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI was not found on PATH." >&2
  exit 1
fi

tmp_diff="$(mktemp)"
tmp_prompt="$(mktemp)"
tmp_response="$(mktemp)"
trap 'rm -f "$tmp_diff" "$tmp_prompt" "$tmp_response"' EXIT

case "$mode" in
  staged)
    git diff --cached --no-ext-diff --binary > "$tmp_diff"
    diff_label="staged changes"
    ;;
  base)
    git diff --no-ext-diff --binary "$base_ref"...HEAD > "$tmp_diff"
    diff_label="changes against ${base_ref}"
    ;;
  head)
    git diff --no-ext-diff --binary HEAD > "$tmp_diff"
    diff_label="working tree changes against HEAD"
    ;;
esac

if [[ ! -s "$tmp_diff" ]]; then
  echo "No diff found for ${diff_label}." >&2
  exit 0
fi

mkdir -p "$(dirname "$output")"

prompt="$(cat <<'PROMPT'
You are a strict, read-only code reviewer. Review the diff below.

Rules:
- Do not modify files.
- Do not ask to run commands.
- Focus on correctness, regressions, security, data loss, edge cases, and missing tests.
- Ignore style-only feedback unless it hides a real maintainability risk.
- If there are no material issues, say so clearly.

Return Markdown with this shape:
1. Findings, ordered by severity.
2. Open questions or assumptions.
3. Brief test/verification gaps.

For each finding include severity, file/line if inferable from the diff, rationale, and a concrete fix.
Use plain Markdown without emoji.
PROMPT
)"

{
  printf '%s\n\n' "$prompt"
  printf 'Review context:\n'
  printf -- '- Repository: %s\n' "$(basename "$repo_root")"
  printf -- '- Scope: %s\n' "$diff_label"
  if [[ -n "$extra_context" ]]; then
    printf -- '- Extra context: %s\n' "$extra_context"
  fi
  printf '\nDiff:\n```diff\n'
  cat "$tmp_diff"
  printf '\n```\n'
} > "$tmp_prompt"

timeout_seconds="${CLAUDE_REVIEW_TIMEOUT_SECONDS:-120}"
max_budget_usd="${CLAUDE_REVIEW_MAX_BUDGET_USD:-0.25}"
model="${model_override:-${CLAUDE_REVIEW_MODEL:-sonnet}}"
cost_file="${CLAUDE_REVIEW_COST_FILE:-cost.txt}"

claude_args=(
  --bare
  --print
  --model "$model"
  --no-session-persistence
  --output-format json
  --permission-mode dontAsk
  --tools ""
  --max-budget-usd "$max_budget_usd"
)

started_at="$(date +%s)"

claude "${claude_args[@]}" < "$tmp_prompt" > "$tmp_response" &
claude_pid=$!

elapsed=0
while kill -0 "$claude_pid" >/dev/null 2>&1; do
  if [[ "$elapsed" -ge "$timeout_seconds" ]]; then
    kill "$claude_pid" >/dev/null 2>&1 || true
    wait "$claude_pid" >/dev/null 2>&1 || true
    echo "Claude review timed out after ${timeout_seconds}s." >&2
    exit 124
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

wait "$claude_pid"
finished_at="$(date +%s)"
elapsed_seconds=$((finished_at - started_at))

node - "$tmp_response" "$output" "$cost_file" "$model" "$diff_label" "$elapsed_seconds" "$max_budget_usd" <<'NODE'
const fs = require("fs");
const [responsePath, outputPath, costPath, model, scope, elapsedSeconds, maxBudgetUsd] = process.argv.slice(2);

const raw = fs.readFileSync(responsePath, "utf8");
let payload;
try {
  payload = JSON.parse(raw);
} catch (error) {
  fs.writeFileSync(outputPath, raw);
  throw new Error(`Claude returned non-JSON output; wrote raw output to ${outputPath}`);
}

const result = payload.result || payload.response || payload.message || raw;
fs.writeFileSync(outputPath, `${result}`.trimEnd() + "\n");

const costField = payload.total_cost_usd !== undefined ? "total_cost_usd" : payload.cost_usd !== undefined ? "cost_usd" : "missing";
const costValue = Number(payload.total_cost_usd ?? payload.cost_usd);
const cost = Number.isFinite(costValue) ? `$${costValue.toFixed(6)}` : "unavailable";
const timestamp = new Date().toISOString();
const line = [
  timestamp,
  `model=${model}`,
  `scope=${scope}`,
  `cost_usd=${cost}`,
  `cost_source=claude_json.${costField}`,
  `budget_usd=$${Number(maxBudgetUsd).toFixed(2)}`,
  `elapsed_seconds=${elapsedSeconds}`,
  `output=${outputPath}`
].join(" | ");

let existingEntries = [];
if (fs.existsSync(costPath)) {
  existingEntries = fs
    .readFileSync(costPath, "utf8")
    .split(/\r?\n/)
    .filter((existingLine) => /^\d{4}-\d{2}-\d{2}T/.test(existingLine));
}

const entries = [line, ...existingEntries];
let totalCost = 0;
let unavailableCount = 0;

for (const entry of entries) {
  const match = entry.match(/cost_usd=\$([0-9]+(?:\.[0-9]+)?)/);
  if (match) {
    totalCost += Number(match[1]);
  } else if (entry.includes("cost_usd=unavailable")) {
    unavailableCount += 1;
  }
}

const summary = `# total_cost_usd=$${totalCost.toFixed(6)} | entries=${entries.length} | unavailable_cost_entries=${unavailableCount}`;
const header = "# timestamp | model | scope | cost_usd | cost_source | budget_usd | elapsed_seconds | output";
fs.writeFileSync(costPath, `# Claude Code review cost log\n${summary}\n${header}\n${entries.join("\n")}\n`);
NODE

echo "Claude review written to $output"
echo "Claude review cost appended to $cost_file"
