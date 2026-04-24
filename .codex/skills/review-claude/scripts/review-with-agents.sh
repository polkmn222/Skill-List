#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  review-with-agents.sh [--engine claude|codex|both] [--staged] [--base <ref>] [--output-dir <dir>] [--context <text>] [--model <name>] [--help]

Options:
  --engine <name>   Reviewer to run: claude, codex, or both. Default: both
  --staged          Review staged changes.
  --base <ref>      Review changes against a base ref.
  --output-dir <d>  Directory for review reports.
                    Default: .codex/skills/review-claude/reports
  --context <text>  Add short task or test context.
  --model <name>    Claude Code model alias/name for Claude reviews.
                    Default: sonnet. Use opus when the user explicitly asks for Opus.
  --help            Show this help.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
engine="both"
output_dir=".codex/skills/review-claude/reports"
context=""
mode_args=()
claude_model_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      engine="${2:-}"
      if [[ "$engine" != "claude" && "$engine" != "codex" && "$engine" != "both" ]]; then
        echo "--engine must be claude, codex, or both" >&2
        exit 2
      fi
      shift 2
      ;;
    --staged)
      mode_args+=(--staged)
      shift
      ;;
    --base)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --base" >&2
        exit 2
      fi
      mode_args+=(--base "$2")
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      if [[ -z "$output_dir" ]]; then
        echo "Missing value for --output-dir" >&2
        exit 2
      fi
      shift 2
      ;;
    --context)
      context="${2:-}"
      shift 2
      ;;
    --model)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --model" >&2
        exit 2
      fi
      claude_model_args+=(--model "$2")
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

timestamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$output_dir"

run_claude() {
  "$script_dir/review-with-claude.sh" \
    "${mode_args[@]}" \
    "${claude_model_args[@]}" \
    --output "$output_dir/claude-review-${timestamp}.md" \
    --context "$context"
}

run_codex() {
  "$script_dir/review-with-codex.sh" \
    "${mode_args[@]}" \
    --output "$output_dir/codex-review-${timestamp}.md" \
    --context "$context"
}

case "$engine" in
  claude)
    run_claude
    ;;
  codex)
    run_codex
    ;;
  both)
    run_claude
    run_codex
    ;;
esac
