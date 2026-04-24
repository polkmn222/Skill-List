---
name: agent-workflow-docs
description: Create project-specific Codex agent workflow docs, including AGENTS.md plus docs for code authoring, code validation, orchestration, and optional plan/task/implement artifacts. Use when the user asks to set up Codex workflow markdown, coding/validation/orchestration md files, agent docs under docs, or reusable plan.md/task.md/implement.md guidance for a project.
---

# Agent Workflow Docs

Use this skill to scaffold durable Codex-facing workflow documentation in the current project.

## Workflow

1. Inspect the project root for `package.json`, lockfiles, `pyproject.toml`, `Makefile`, existing `AGENTS.md`, `CLAUDE.md`, and `docs/`.
2. Run the bundled scaffold script from this skill directory:

```bash
python3 .codex/skills/agent-workflow-docs/scripts/scaffold_agent_workflows.py
```

If the user also asks to create plan/task/implement files, run:

```bash
python3 .codex/skills/agent-workflow-docs/scripts/scaffold_agent_workflows.py --task-artifacts
```

If the skill is installed outside `.codex/skills`, resolve the script path relative to this `SKILL.md`.

3. Review generated files and adjust only when project-specific details are visible from the repository.
4. Validate:

```bash
rg -n "TO[D]O|TB[D]|FIX[M]E" AGENTS.md docs/agent-workflows
wc -l AGENTS.md docs/agent-workflows/*.md
```

## Generated Files

- `AGENTS.md`: short root entry point that forces agents to read workflow docs.
- `docs/agent-workflows/code-authoring.md`: coding rules matched to the project type.
- `docs/agent-workflows/code-validation.md`: file-scoped validation commands inferred from local tooling.
- `docs/agent-workflows/orchestration.md`: planning, execution, and handoff rules.
- With `--task-artifacts`: `docs/tasks/plan.md`, `docs/tasks/phase_001/task.md`, and `docs/tasks/phase_001/implement.md`.

## plan.md, task.md, implement.md

Do not create root-level `plan.md`, `task.md`, or `implement.md` by default.

Use task artifacts only for work that must persist across turns:

```text
docs/tasks/plan.md
docs/tasks/phase_001/task.md
docs/tasks/phase_001/implement.md
```

Rules:

- `docs/tasks/plan.md`: multi-step work with user-visible phases.
- `docs/tasks/phase_001/task.md`: durable requirements, constraints, and acceptance criteria.
- `docs/tasks/phase_001/implement.md`: implementation notes that must survive the current turn.
- Increment phase folders as `phase_002`, `phase_003`, and so on.
- Small single-turn edits should not create task artifacts.

## Backup Policy

- This skill does not create a separate backup skill.
- Preserve existing files by default; the scaffold script skips files that already exist.
- Prefer version control for rollback when the project is a git repository.
- Create manual backups only when the user asks or when a non-git project requires risky broad rewrites.

## Editing Rules

- Keep `AGENTS.md` under 60 lines when possible.
- Prefer commands discovered from the project over generic commands.
- Do not duplicate formatter or linter rules already stored in config files.
- Preserve existing project-specific instructions if an `AGENTS.md` already exists.
