---
description: Submit a read-only Claude review job in the background and collect the result later.
disable-model-invocation: true
---

Use this skill when the user asks for an asynchronous Claude review or a second-pass Claude review.

Submit:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/review-claude-submit" $ARGUMENTS
```

Collect latest:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/review-claude-collect" latest
```

The submit command returns immediately after creating a background job. Do not poll unless the user explicitly asks for status.
