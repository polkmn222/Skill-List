---
name: find-skills
description: Use in Codex only when the user explicitly names find-skills or directly asks to use the find-skills workflow to find relevant Codex skills for a project or idea. Runs a checklist-first workflow, ranks local and external skill candidates, writes a project-local search index, and gates installation or implementation.
---

# Find Skills For Codex

Use this skill when the user asks to find, recommend, compare, install, or use Codex skills for a project, project idea, domain, workflow, implementation, or local workspace.

Do not use this skill unless the user explicitly names `find-skills` or directly asks to use the `find-skills` workflow. Do not trigger it merely because the task involves skills, discovery, recommendations, installation, or planning.

This skill is checklist-first. A raw request is not enough to search skill metadata, recommend skills, install skills, or implement artifacts.

## Required References

Always follow:

- `CHECKLIST.md`
- `references/project-local-installation.md`
- `references/search-index-format.md`

Read when needed:

- `references/candidate-scoring.md` when ranking candidates
- `references/recommendation-output.md` when writing chat recommendations
- `references/implementation-traceability.md` when implementation begins

## Language Policy

Write code, skill files, generated indexes, implementation artifacts, configuration files, comments, commit messages, and project documentation in English.

The routine exception is request-specific checklist files under `docs/checklist-###.md`, which may use the user's language so the user can review and maintain them. Keep canonical technical identifiers, file names, commands, metadata keys, code symbols, and index fields in English.

## Core Rules

- Do not ask the user to run Python, shell, install, or validation commands.
- Inspect local files directly. Prefer `rg` and filesystem search.
- Use only skill metadata and lightweight project context unless deeper analysis is requested.
- Search current-project skills first from `.codex/skills/**/SKILL.md`.
- "Local skill" means inside the current project folder, not home-level or global skill directories.
- Search external Git/community/official sources after local discovery unless the completed checklist explicitly restricts that scope.
- Treat external candidates as `candidate to validate` until source, license or portability, install/copy path, and metadata or equivalent documentation are inspected.
- Distinguish installed project-local skills from external candidates in chat and in the index.
- Use `production` as the default maturity target unless the checklist records MVP, demo, prototype, experiment, or learning scope.
- Never implement, install, scaffold, or modify project artifacts before both the completed checklist and generated index have been confirmed for the current request.

## Intent Rules

- Recommendation only: stop at recommendations and the search index.
- Install only: install or copy only the requested/indexed skills into the current project's `.codex/skills/` directory; do not implement, scaffold, or refactor.
- Implementation/build/scaffold request: use the full gate sequence below before changing project artifacts.
- If required checklist details are missing, ask concise questions and wait.
- If the user says assumptions are fine, draft explicit assumptions in the checklist and ask for confirmation before searching.

## Workflow

1. Understand the user's project intent from the request and lightweight project files.
2. Run the checklist gate from `CHECKLIST.md`.
3. Write or update the request-specific checklist under the current project root's `docs/` directory.
4. Ask the user to confirm the completed checklist before skill metadata search.
5. Extract search terms, constraints, maturity target, acceptance criteria, exclusions, and setup/install expectations from the checklist.
6. Search project-local skills in `.codex/skills/**/SKILL.md`.
7. Search external Git/community/official sources unless the checklist forbids or limits external discovery.
8. Check required bootstrap skills in the current project's `.codex/skills/` directory:
   - `skill-installer`
   - `skill-creator`
   - `agents-md`
   - `agent-orchestrator`
   - `antigravity-skill-orchestrator`
   - `acceptance-orchestrator`
   - `plugin-creator`
9. Score and bucket candidates using `references/candidate-scoring.md`.
10. Write `.find-skills/<key>/index.md` using `references/search-index-format.md`.
11. Summarize `Precise` recommendations in chat using `references/recommendation-output.md`.
12. Ask the user to confirm the index.
13. If installation is requested, install/copy required skills into project-local `.codex/skills/`, verify each `SKILL.md`, and update the index installation status.
14. If implementation is requested, verify selected/required project-local skills first, then implement and report traceability using `references/implementation-traceability.md`.

## Project-Local Installation

For project-specific work, a skill counts as installed only when this file exists:

```text
.codex/skills/<skill-name>/SKILL.md
```

The canonical installed location for this skill is `.codex/skills/find-skills/SKILL.md`.
If a matching development or source copy exists outside `.codex/skills/` such as `.codex/find-skills/`,
do not treat that copy as the installed project-local skill path.

Global or home-level installs such as `~/.codex/skills` or `~/.agents/skills` do not satisfy project-local installation. Use them only as sources, caches, or temporary installs. See `references/project-local-installation.md`.

## Search Index

Write the index under the current project root:

```text
.find-skills/<key>/index.md
```

The index must cite the checklist path and rank candidates from checklist contents, not from the raw request alone. It must make installation easy and use project-relative skill paths when installed.

## Failure And Limit Handling

- If filesystem writes are unavailable, show the intended checklist or index in chat and state that it could not be written.
- If external discovery is unavailable due to network, tooling, permission, or time constraints, record the limitation in both checklist-derived search scope and the index.
- If no usable `SKILL.md` files are found, report the paths checked and why recommendations are limited.
- If install verification fails, do not mark the skill as installed.
