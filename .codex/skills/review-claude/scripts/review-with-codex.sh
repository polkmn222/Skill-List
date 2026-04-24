#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  review-with-codex.sh [--staged] [--base <ref>] [--output <file>] [--context <text>] [--help]

Options:
  --staged          Review staged changes by passing git diff --cached to Codex.
  --base <ref>      Review changes against a base ref.
  --output <file>   Write the Codex review to this file.
                    Default: .codex/skills/review-claude/reports/codex-review-<timestamp>.md
  --context <text>  Add short task or test context to the review prompt.
  --help            Show this help.

Environment:
  CODEX_REVIEW_MODEL            Codex model override. Default: CLI default
  CODEX_REVIEW_TIMEOUT_SECONDS  Timeout. Default: 180
USAGE
}

mode="head"
base_ref=""
extra_context=""
timestamp="$(date +%Y%m%d-%H%M%S)"
output=".codex/skills/review-claude/reports/codex-review-${timestamp}.md"

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

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI was not found on PATH." >&2
  exit 1
fi

tmp_diff="$(mktemp)"
tmp_prompt="$(mktemp)"
trap 'rm -f "$tmp_diff" "$tmp_prompt"' EXIT

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

{
  cat <<'PROMPT'
You are a strict, read-only code reviewer. Review only the diff below.

Rules:
- Do not modify files.
- Do not ask to run commands.
- Focus on correctness, regressions, security, data loss, edge cases, and missing tests.
- Ignore style-only feedback unless it hides a real maintainability risk.
- If there are no material issues, say so clearly.
- Use plain Markdown without emoji.

Return:
1. Findings, ordered by severity.
2. Open questions or assumptions.
3. Brief test/verification gaps.
PROMPT
  printf '\nReview context:\n'
  printf -- '- Repository: %s\n' "$(basename "$repo_root")"
  printf -- '- Scope: %s\n' "$diff_label"
  if [[ -n "$extra_context" ]]; then
    printf -- '- Extra context: %s\n' "$extra_context"
  fi
  printf '\nDiff:\n```diff\n'
  cat "$tmp_diff"
  printf '\n```\n'
} > "$tmp_prompt"

timeout_seconds="${CODEX_REVIEW_TIMEOUT_SECONDS:-180}"
codex_args=(exec --ephemeral --sandbox read-only --ask-for-approval never --output-last-message "$output")
if [[ -n "${CODEX_REVIEW_MODEL:-}" ]]; then
  codex_args+=(--model "$CODEX_REVIEW_MODEL")
fi
codex_args+=("-")

codex "${codex_args[@]}" < "$tmp_prompt" >/dev/null &
codex_pid=$!

elapsed=0
while kill -0 "$codex_pid" >/dev/null 2>&1; do
  if [[ "$elapsed" -ge "$timeout_seconds" ]]; then
    kill "$codex_pid" >/dev/null 2>&1 || true
    wait "$codex_pid" >/dev/null 2>&1 || true
    echo "Codex review timed out after ${timeout_seconds}s." >&2
    exit 124
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

wait "$codex_pid"
echo "Codex review written to $output"
