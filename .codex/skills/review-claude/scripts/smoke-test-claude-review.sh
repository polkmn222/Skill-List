#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "${script_dir}/../../../.." && pwd)"
review_script="${script_dir}/review-with-claude.sh"

if [[ -f "${project_root}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${project_root}/.env"
  set +a
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ANTHROPIC_API_KEY is not set. Add it to ${project_root}/.env or export it." >&2
  exit 1
fi

tmp_repo="$(mktemp -d)"
trap 'rm -rf "$tmp_repo"' EXIT

cd "$tmp_repo"
git init -q
git config user.email "codex-smoke@example.com"
git config user.name "Codex Smoke"

cat > calculator.js <<'JS'
function divide(a, b) {
  return a / b;
}

module.exports = { divide };
JS

git add calculator.js
git commit -q -m "initial"

cat > calculator.js <<'JS'
function divide(a, b) {
  return a / b;
}

function formatPercent(value) {
  return value * 100 + "%";
}

module.exports = { divide, formatPercent };
JS

output="${tmp_repo}/claude-review.md"
cost_file="${project_root}/cost.txt"
CLAUDE_REVIEW_COST_FILE="$cost_file" "$review_script" \
  --output "$output" \
  --context "Smoke test: verify ANTHROPIC_API_KEY authentication, sonnet model selection, cost logging, and Claude Code review execution on a tiny temporary diff."

if [[ ! -s "$output" ]]; then
  echo "Claude review output was empty." >&2
  exit 1
fi

echo "Smoke test passed. Claude review output:"
echo "-----"
sed -n '1,120p' "$output"
