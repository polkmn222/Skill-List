# review-claude

`review-claude` is a local Claude Code plugin bridge for asynchronous, read-only code review jobs.

## What it does

- Submits the current git diff to Claude as a background review job.
- Returns control immediately instead of waiting for the review to finish.
- Mirrors completed summaries into a workspace-owned directory.
- Mirrors notification text and notification delivery status into the workspace summary directory.
- Adds workspace `AGENTS.md`, `README.md`, and `docs/` Markdown/text files as context-only prompt material.
- Reads `ANTHROPIC_API_KEY` from the workspace root `.env` or exported environment, then passes only that key through a locked-down temporary runtime file.

## Layout

- `claude-code-marketplace/`
  Local Claude Code marketplace containing the plugin manifest, commands, and runtime scripts.
- `<workspace>/review-claude/latest_job_id.txt`
  Reverse-chronological JSONL review index. The first line is the latest job.
- `<workspace>/review-claude/cost.txt`
  Text cost log with a `total_cost_usd` header followed by reverse-chronological JSONL records.
- `<workspace>/review-claude/latest_notification.txt`
  Latest notification with job id, status, notification status, and message.
- `crm-demo/`
  Small demo repository for manual testing.

## Runtime contract

1. `review-claude-submit` validates the current git diff and writes a locked-down runtime job directory under `/tmp/review-claude-workers/<job-id>`.
2. The submitter builds `prompt.txt` from context-only workspace docs, then the diff under review.
3. The submitter copies only `ANTHROPIC_API_KEY` into `/tmp/review-claude-workers/<job-id>/anthropic.env`.
4. Claude runs in read-only review mode and writes `response.json`, `stderr.log`, `status`, and `exit_code`.
5. The worker deletes the temporary key file immediately after reading it.
6. The worker prepends one JSONL record to `latest_job_id.txt`, replacing any older record for the same job id.
7. The worker mirrors only the latest notification to `latest_notification.txt`.
8. The worker rewrites `cost.txt` with a total-cost header and one JSONL record per job.
9. `review-claude-collect` reads either the `latest_job_id.txt` record or the raw runtime status.

`latest_job_id.txt` is intentionally a reverse-chronological JSONL file. The first
line is the latest job and includes enough data for Codex and the user to inspect
the Claude result together. If a raw job has a successful `response.json` but a
stale failed status from a mirror or rerun problem, collect rebuilds the summary
record as `complete`.

## Validation

- Local regression smoke:

```bash
./review-claude/claude-code-marketplace/plugins/review-claude-plugin/tests/review-claude-smoke.sh
```

- Real API smoke:
  Run `review-claude-submit` inside a git repository with a non-empty diff, then collect the resulting job.
