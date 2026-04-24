---
name: create-plan
description: Create a concise, repository-grounded implementation plan before coding. Use when the user asks for a plan, wants phased work, needs harness-aware planning, or asks Codex to inspect the project and plan without making implementation changes. For workflow document scaffolding and task artifact paths, defer to the agent-workflow-docs skill.
---

# Create Plan

Use this skill to turn a request into a concrete plan grounded in the current repository.

## Mode

- Default to read-only.
- Do not edit implementation files while creating the plan.
- If the user explicitly asks to write a persistent plan, use the artifact conventions from `agent-workflow-docs`.

## Harness Awareness

Before planning, inspect the smallest useful context:

- Root instructions: `AGENTS.md`, `CLAUDE.md`.
- Project docs: `README.md`, `docs/`, `CONTRIBUTING.md`, architecture notes.
- Tooling: package manager files, `pyproject.toml`, `Makefile`, CI configs.
- Test harnesses: scripts, eval docs, golden prompts, pass criteria, smoke tests.
- Environment limits: missing git repo, sandbox restrictions, network requirements.

Record assumptions when the harness or validation path is incomplete.

## Plan Shape

Return a short plan with:

- Goal: 1-3 sentences.
- Scope: what is in and out.
- Phases: ordered `phase_001`, `phase_002`, `phase_003` items when work is multi-step.
- Validation: specific commands or checks that prove completion.
- Risks: only concrete risks tied to files, tools, data, or permissions.
- Open questions: only blocking questions, maximum 3.

## Persistent Artifacts

This skill does not define the canonical task artifact structure. Follow `agent-workflow-docs` for paths and creation rules.

Current convention:

```text
docs/tasks/plan.md
docs/tasks/phase_001/task.md
docs/tasks/phase_001/implement.md
```

Rules:

- During planning, create or update `docs/tasks/plan.md` only when the user asks for a persistent plan.
- Do not create `task.md` or `implement.md` from this skill unless the user explicitly asks for phase artifacts.
- Do not create root-level `plan.md`, `task.md`, or `implement.md`.

## Template

```markdown
# Plan

## Goal
- <What we are doing and why.>

## Scope
- In: <Included work.>
- Out: <Excluded work.>

## Phases
| Phase | Status | Summary |
|-------|--------|---------|
| `phase_001` | pending | <First concrete phase> |

## Validation
- `<command or check>`

## Risks
- <Concrete risk or `None identified`.>

## Open Questions
- <Blocking question or `None`.>
```
