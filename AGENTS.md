# Skill List Agent Notes

This repository is a Markdown-first skill list for multiple agent hosts. It can contain many skills, not only `find-skills`. There is no required runtime for normal skill discovery work.

## Project Layout

- `.codex/skills/` contains Codex skills.
- `.claude/skills/` contains Claude Code skills and plugin-compatible skill files.
- `.cursor/skills/` contains Cursor skills.
- `.gemini/skills/` contains Gemini skills.
- `find-skills/` is one installed skill for discovering and recommending other skills.
- `review-claude/` and `review-agents/` are installed skills for second-pass code review workflows.
- `.codex/skills/review-claude/` contains the shared review scripts used by Codex, Cursor, and Gemini.
- `.cursor/skills/review-agents/` and `.gemini/skills/review-agents/` are thin host-specific entrypoints to those shared review scripts.

## Skill Discovery Workflow

When the user asks to find relevant skills:

1. Read the host-specific `find-skills/SKILL.md`.
2. Follow its checklist-first workflow.
3. Search available `SKILL.md` files directly.
4. Use skill metadata first: `name`, `description`, `When to Use`, headings, routing tables, and examples.
5. Show only precise recommendations in chat unless the user asks for more.
6. If useful, write broader candidates to `.find-skills/<key>/reports/`.

Rules:

- Do not ask the user to run terminal commands manually.
- Do not require Python or any runtime for normal discovery.
- Do not install, scaffold, or modify project artifacts until the relevant checklist and index gates are satisfied.
- When adding new skills, keep the host-specific copies under each `.*/skills/<skill-name>/` path aligned where applicable.

## Review Agents Workflow

This project can run second-pass reviews through Claude Code, Codex, or both.

Use the shared wrapper from the project root:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine claude
.codex/skills/review-claude/scripts/review-with-agents.sh --engine codex
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both
```

Useful review modes:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both --staged
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both --base origin/main
```

Claude Code review behavior:

- Loads `ANTHROPIC_API_KEY` from `.env`.
- Uses `--model sonnet` by default.
- Uses read-only prompt/tool settings.
- Appends estimated dollar cost to project-root `cost.txt`.

Codex review behavior:

- Uses the local `codex` CLI.
- Runs read-only review against the generated diff prompt.
- Does not currently write per-run cost because the CLI does not expose the same `total_cost_usd` field used by Claude Code.

Review rules:

- Treat all reviewer output as advisory.
- Verify findings before editing files or reporting them as confirmed.
- Do not ask reviewers to edit files, commit, push, or run commands.
- Do not paste secrets into review prompts.
- Do not update Claude-specific plugin files; Claude already has a dedicated plugin path in this project.

## Secrets And Cost Files

- `.env` is local-only and should contain secrets such as `ANTHROPIC_API_KEY`.
- `cost.txt` is local-only and records estimated Claude Code review spend in USD.
- Do not print or copy API keys into chat, logs, docs, or review prompts.

## Maintainer Checks

For lightweight repository checks:

```bash
./scripts/check-all.sh
```

For review script syntax checks:

```bash
bash -n .codex/skills/review-claude/scripts/review-with-claude.sh
bash -n .codex/skills/review-claude/scripts/review-with-codex.sh
bash -n .codex/skills/review-claude/scripts/review-with-agents.sh
bash -n .codex/skills/review-claude/scripts/smoke-test-claude-review.sh
```
