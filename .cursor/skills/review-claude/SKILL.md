---
name: review-claude
description: Use in Cursor only when the user explicitly asks for review-claude, Claude Code review, or a Codex/Claude second-pass review; delegates to the shared review-agents scripts.
---

# Review Claude

Do not use this skill unless the user explicitly asks for `review-claude`, Claude Code review, or a Codex/Claude second-pass review. Do not trigger it merely because code changed, tests ran, a review might be useful, or the user asks for a normal Cursor review.

Use `.cursor/skills/review-agents/SKILL.md` for the full workflow.

Common commands:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine claude
.codex/skills/review-claude/scripts/review-with-agents.sh --engine codex
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both
```

Claude uses `.env` `ANTHROPIC_API_KEY`, defaults to `sonnet`, and logs `$` cost to project-root `cost.txt`.
