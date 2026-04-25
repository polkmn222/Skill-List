---
description: Show the latest or specified review-claude job status
argument-hint: '[job-id|latest] [--summary-dir <dir>]'
disable-model-invocation: true
allowed-tools: Bash(*review-claude-collect*)
---

Show review-claude status through the plugin companion script.

Raw slash-command arguments: `$ARGUMENTS`

Run:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/review-claude-collect" $ARGUMENTS
```

Return the command output verbatim. Do not apply fixes.
