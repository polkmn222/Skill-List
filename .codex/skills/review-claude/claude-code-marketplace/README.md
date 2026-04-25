# review-claude Claude Code marketplace

Local Claude Code marketplace for the `review-claude` bridge.

Install from Claude Code:

```text
/plugin marketplace add ./review-claude/claude-code-marketplace
/plugin install review-claude@local-review-tools
/reload-plugins
```

Authentication:

- Store `ANTHROPIC_API_KEY` in the workspace root `.env` or export it before submitting.
- `review-claude` parses only that key, writes it to a locked-down `/tmp` runtime file, and the worker deletes that file immediately after reading it.
- On macOS, the default `auto` backend uses `launchctl` when available so review jobs can survive after the submitting shell exits.

Commands:

- `/review-claude:review` submits a background Claude review job.
- `/review-claude:status` prints the latest or specified job summary.
- `/review-claude:result` is an alias for reading the summary result.

The runtime state is written under `/tmp/review-claude-workers/<job-id>/job`.
Prompts include workspace `AGENTS.md`, `README.md`, and Markdown/text files
under `docs/` as context-only material before the diff. Findings should still
target the diff unless a context file is also part of that diff.
Completed results are recorded in `review-claude/latest_job_id.txt`, a
reverse-chronological JSONL index whose first line is the latest job record.
Costs are recorded in `review-claude/cost.txt` with a `total_cost_usd` header
and per-job JSONL records when Claude Code reports `total_cost_usd`.
The latest notification is written to `review-claude/latest_notification.txt`.

Local validation:

```bash
./review-claude/claude-code-marketplace/plugins/review-claude-plugin/tests/review-claude-smoke.sh
```
