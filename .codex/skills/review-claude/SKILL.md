---
name: review-claude
description: Use only when the user explicitly asks for review-claude, Claude Code review, or a second-pass Claude review after Codex has made or inspected code changes; runs a read-only code review using the local claude CLI and ANTHROPIC_API_KEY from .env.
---

# Claude Code Review

Use this skill when the user wants Codex work reviewed by Claude Code, or asks for a second opinion from Claude before finalizing code changes.

Do not use this skill unless the user explicitly asks for `review-claude`, Claude Code review, or a second-pass Claude review. Do not trigger it merely because code changed, tests ran, a review might be useful, or the user asks for a normal Codex review.

## Workflow

1. Finish the Codex implementation or analysis first.
2. Run local tests or checks that are appropriate for the change.
3. Use `scripts/review-with-claude.sh` to send only the relevant diff to Claude Code.
4. Treat Claude's output as review input, not as an automatic source of truth.
5. Inspect each finding yourself before changing files or reporting it to the user.

## Review Script

From the project root:

```bash
.codex/skills/review-claude/scripts/review-with-claude.sh
```

Useful modes:

```bash
.codex/skills/review-claude/scripts/review-with-claude.sh --staged
.codex/skills/review-claude/scripts/review-with-claude.sh --base origin/main
.codex/skills/review-claude/scripts/review-with-claude.sh --output .codex/skills/review-claude/reports/latest.md
```

Run Claude Code, Codex, or both through the shared wrapper:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine claude
.codex/skills/review-claude/scripts/review-with-agents.sh --engine codex
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both
```

Smoke test the Claude API path with a tiny temporary repository:

```bash
.codex/skills/review-claude/scripts/smoke-test-claude-review.sh
```

The script loads `.env` when present. It expects `ANTHROPIC_API_KEY` to be available and `claude` to be installed on `PATH`.

By default it uses:

- model: `sonnet`
- per-run budget cap: `$0.25`
- cost log: `cost.txt` at the project root

Override when needed:

```bash
CLAUDE_REVIEW_MODEL=opus .codex/skills/review-claude/scripts/review-with-claude.sh
CLAUDE_REVIEW_MAX_BUDGET_USD=0.50 .codex/skills/review-claude/scripts/review-with-claude.sh
CLAUDE_REVIEW_COST_FILE=.codex/skills/review-claude/reports/cost.txt .codex/skills/review-claude/scripts/review-with-claude.sh
```

Codex reviews use the local `codex` CLI. Codex cost is not logged by this project script because the CLI does not expose the same per-run `total_cost_usd` field used by Claude Code.

## Review Policy

- Reviewers are read-only for this workflow.
- Do not ask reviewers to edit files, run commands, commit, or push.
- Send diffs, test output summaries, and review context only when useful.
- Do not paste secrets into prompts. If a diff contains secrets, stop and rotate them before review.
- Do not blindly apply Claude's suggestions; verify against the codebase and tests.

## Output Expectations

Claude should return concise findings with:

- severity
- file and line when available
- why the issue matters
- a concrete suggested fix

If Claude reports no findings, record that and mention any review limitations such as missing tests, large omitted files, or unavailable base branch.
