---
description: Submit a read-only Claude review against local git state
argument-hint: '[--base <ref>] [--summary-dir <dir>] [focus text]'
disable-model-invocation: true
allowed-tools: Bash(git:*), Bash(*review-claude-submit*)
---

Submit a Claude review job through the plugin companion script.

Raw slash-command arguments: `$ARGUMENTS`

Core constraints:
- This command only submits the review. Do not wait for Claude to finish.
- Do not edit files or apply fixes.
- Preserve the user's arguments exactly.

Run:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/review-claude-submit" $ARGUMENTS
```

Return the command output verbatim. Then tell the user to check `/review-claude:status` or `/review-claude:result` later.
