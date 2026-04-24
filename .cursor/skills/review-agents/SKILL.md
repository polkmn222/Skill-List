---
name: review-agents
description: Use in Cursor only when the user explicitly asks for review-agents, review-claude, Claude Code review, Codex review, or a second-pass AI review using the shared project review scripts and cost logging.
---

# Review Agents

Use this skill when working in Cursor and the user wants another AI reviewer before finalizing changes.

Do not use this skill unless the user explicitly asks for `review-agents`, `review-claude`, Claude Code review, Codex review, or a second-pass AI review. Do not trigger it merely because code changed, tests ran, or a review might be useful.

## Workflow

1. Finish the local implementation or inspection first.
2. Run relevant tests or checks.
3. Choose the reviewer:
   - Claude only: `--engine claude`
   - Codex only: `--engine codex`
   - Both: `--engine both`
4. Run the shared script from the project root.
5. Treat all review output as advisory; verify findings before editing files.

## Commands

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both
.codex/skills/review-claude/scripts/review-with-agents.sh --engine claude --staged
.codex/skills/review-claude/scripts/review-with-agents.sh --engine codex --base origin/main
```

Claude reviews use `ANTHROPIC_API_KEY` from `.env`, default to `--model sonnet`, and append cost lines to `cost.txt` at the project root.

Codex reviews use the local `codex` CLI. Codex cost is not logged by this project script because the CLI does not expose the same per-run `total_cost_usd` field used by Claude Code.

## Rules

- Do not update Claude-specific plugin files from this skill.
- Do not paste secrets into review prompts.
- Do not ask reviewers to edit files, commit, push, or run commands.
- Prefer `--engine both` for high-risk changes and `--engine claude` or `--engine codex` for quick second opinions.
