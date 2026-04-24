---
name: review-claude
description: Use in Gemini when the user asks for Claude Code review or a Codex/Claude second-pass review; delegates to the shared review-agents scripts.
---

# Review Claude

Use `.gemini/skills/review-agents/SKILL.md` for the full workflow.

Common commands:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine claude
.codex/skills/review-claude/scripts/review-with-agents.sh --engine codex
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both
```

Claude uses `.env` `ANTHROPIC_API_KEY`, defaults to `sonnet`, and logs `$` cost to project-root `cost.txt`.
