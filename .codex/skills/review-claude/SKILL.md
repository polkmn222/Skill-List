---
name: review-claude
description: Use only when the user explicitly asks for review-claude, Claude Code review, or a second-pass Claude review. Submit Claude Code as a background read-only reviewer, stop waiting, and collect the result later for Codex verification.
---

# Claude Code Review

Use this skill only when the user explicitly asks for `review-claude`, Claude Code review, or a second-pass Claude review.

## Flow

1. Finish Codex's implementation or local analysis first.
2. Run relevant local checks.
3. Submit a read-only Claude review job:

```bash
.codex/skills/review-claude/claude-code-marketplace/plugins/review-claude-plugin/bin/review-claude-submit --include-untracked
```

4. Tell the user the job id, job directory, summary directory, and that Codex is no longer waiting.
5. When the user asks to collect, run:

```bash
.codex/skills/review-claude/claude-code-marketplace/plugins/review-claude-plugin/bin/review-claude-collect latest
```

or pass the specific job id.

## Rules

- Do not submit diffs containing real secrets.
- The submit script reads only `ANTHROPIC_API_KEY` from the workspace root `.env`, or from the already exported environment.
- The submit script copies only that key into a locked-down runtime file under `/tmp`; the worker deletes it immediately after reading.
- Review records default to `review-claude/latest_job_id.txt` under the workspace root.
- No mirrored job directories are created; raw status, stderr, response JSON, and worker metadata stay under `/tmp/review-claude-workers/<job-id>/job`.
- Review prompts include `AGENTS.md`, `README.md`, and Markdown/text files under `docs/` from the workspace root as context-only material before the diff.
- The latest notification is mirrored to `review-claude/latest_notification.txt` under the workspace root.
- `review-claude/latest_job_id.txt` is a reverse-chronological JSONL index. The first line is the latest job record and includes the job id, status, exit code, raw job directory, cost, and Claude response JSON when available.
- `review-claude-collect` can rebuild `latest_job_id.txt` from `/tmp/review-claude-workers/<job-id>/job/response.json` if the worker completed but the mirror write was blocked.
- `review-claude/cost.txt` is a text log with a `total_cost_usd` header followed by reverse-chronological JSONL cost records from Claude Code's `total_cost_usd` field when present.
- Prefer the default `auto` backend on macOS. It uses `launchctl` when available so the worker can survive after Codex stops waiting.
- Claude output is review input, not source of truth. Codex must verify findings against the code before reporting them.

## Output

Report only verified findings with severity, file/line, why it matters, and a concrete suggested fix. If there are no verified findings, say that clearly and mention validation limits.
