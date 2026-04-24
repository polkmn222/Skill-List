# Skills

Markdown-first skill collection for agent-based coding tools.

Use this repository to install or share project-local skills across Codex CLI, Claude Code, Cursor, and Gemini CLI. The repository currently includes skill discovery and AI review helpers, and is intended to grow with more skills over time. Python execution is not required for normal skill usage.

Repository URL:

```text
https://github.com/polkmn222/Skill-List.git
```

## Choose Your Tool

Use the same repository, but install or invoke it in the way your host expects.

| Tool | Install Target | Example Use |
| --- | --- | --- |
| Codex CLI | `.codex/skills/<skill-name>` | `Use find-skills to find relevant skills for this project.` |
| Claude Code | `.claude/skills/<skill-name>` | `Use find-skills to find relevant skills for this project.` |
| Cursor | `.cursor/skills/<skill-name>` | `@find-skills find relevant skills for this project.` |
| Gemini CLI | `.gemini/skills/<skill-name>` | `Use find-skills to find relevant skills for this project.` |

This working copy also includes a shared review helper:

| Tool | Review Entry | Review Engines |
| --- | --- | --- |
| Codex CLI | `.codex/skills/review-claude` | Claude Code, Codex, or both |
| Cursor | `.cursor/skills/review-agents` | Claude Code, Codex, or both |
| Gemini CLI | `.gemini/skills/review-agents` | Claude Code, Codex, or both |

Claude Code has its own plugin path in this project and is not updated by the Cursor/Gemini review entrypoints.

Agents should only use `find-skills`, `review-claude`, or `review-agents` when the user explicitly names or asks for those workflows.

## Included Skills

Current project-local skills include:

| Skill | Purpose | Hosts | Source |
| --- | --- | --- | --- |
| `find-skills` | Search, rank, and recommend skills from available `SKILL.md` metadata. | Codex, Claude Code, Cursor, Gemini | Created in this repository by the maintainer. |
| `review-claude` | Run Claude Code as a read-only second-pass reviewer. | Codex, Cursor alias, Gemini alias | Created in this repository by the maintainer. |
| `review-agents` | Run Claude Code, Codex, or both as read-only reviewers. | Cursor, Gemini | Created in this repository as a host-specific entrypoint to `review-claude`. |
| `agent-workflow-docs` | Generate Codex workflow markdown, including `AGENTS.md`, authoring, validation, orchestration, and optional task artifacts. | Codex | Created in this repository by the maintainer. |
| `agents-md` | Maintain concise, high-signal agent instruction files. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `architecture` | Evaluate architecture decisions, trade-offs, constraints, and ADR-worthy choices. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `ask-questions-if-underspecified` | Clarify requirements before implementation when meaningful ambiguity remains. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `api-design-principles` | Review REST and GraphQL API design quality. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `brainstorming` | Turn vague feature, architecture, or behavior ideas into a clearer design direction. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `code-review-checklist` | Review changes for functionality, security, performance, tests, and maintainability. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `concise-planning` | Convert coding tasks into clear, actionable checklists. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `create-plan` | Create repository-grounded, harness-aware implementation plans. | Codex | Created in this repository by the maintainer. |
| `create-pr` | Compatibility alias for PR creation workflows. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `frontend-design` | Review and guide frontend UI design and implementation quality. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `lint-and-validate` | Run appropriate validation after code changes. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `pr-writer` | Write structured pull request descriptions. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `security-auditor` | Review security risks, controls, and mitigations. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `systematic-debugging` | Investigate bugs and test failures before proposing fixes. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |
| `test-driven-development` | Guide feature and bugfix work with a test-first workflow. | Codex | Imported from `https://github.com/sickn33/antigravity-awesome-skills`. |

The imported Codex skills above were selected from the Antigravity Awesome Skills catalog rather than authored in this repository.

More skills can be added under each host's `.*/skills/<skill-name>/` folder.

## Recommended Codex Starter Skills

These are useful global Codex starter skills to install in `$CODEX_HOME/skills` (`~/.codex/skills` by default). Restart Codex after installing or updating skills so Codex reloads the metadata.

| Skill | Purpose | Source |
| --- | --- | --- |
| `openai-docs` | Use current OpenAI developer documentation for OpenAI API, Codex, Agents SDK, model selection, and upgrade guidance. | `https://github.com/openai/skills/tree/main/skills/.curated/openai-docs` |
| `skill-creator` | Scaffold and maintain Codex skills with `SKILL.md`, optional `agents/openai.yaml`, scripts, references, and assets. | `https://github.com/openai/skills/tree/main/skills/.system/skill-creator` |
| `skill-installer` | Install Codex skills from curated `openai/skills` entries or GitHub repository paths. | `https://github.com/openai/skills/tree/main/skills/.system/skill-installer` |
| `agents-md` | Create or maintain concise repository instructions for Codex and other coding agents. | `https://github.com/sickn33/antigravity-awesome-skills` |

## Install

Install for Codex CLI:

```bash
tmp=$(mktemp -d)
git clone https://github.com/polkmn222/Skill-List.git "$tmp/skills"
mkdir -p .codex/skills
cp -R "$tmp/skills/.codex/skills/"* .codex/skills/
```

Install for Claude Code:

```bash
tmp=$(mktemp -d)
git clone https://github.com/polkmn222/Skill-List.git "$tmp/skills"
mkdir -p .claude/skills
cp -R "$tmp/skills/.claude/skills/"* .claude/skills/
```

Install for Cursor:

```bash
tmp=$(mktemp -d)
git clone https://github.com/polkmn222/Skill-List.git "$tmp/skills"
mkdir -p .cursor/skills
cp -R "$tmp/skills/.cursor/skills/"* .cursor/skills/
```

Install for Gemini CLI:

```bash
tmp=$(mktemp -d)
git clone https://github.com/polkmn222/Skill-List.git "$tmp/skills"
mkdir -p .gemini/skills
cp -R "$tmp/skills/.gemini/skills/"* .gemini/skills/
```

Install all hosts:

```bash
tmp=$(mktemp -d)
git clone https://github.com/polkmn222/Skill-List.git "$tmp/skills"
mkdir -p .codex/skills .claude/skills .cursor/skills .gemini/skills
cp -R "$tmp/skills/.codex/skills/"* .codex/skills/
cp -R "$tmp/skills/.claude/skills/"* .claude/skills/
cp -R "$tmp/skills/.cursor/skills/"* .cursor/skills/
cp -R "$tmp/skills/.gemini/skills/"* .gemini/skills/
```

## Direct Use Without Installing

Point your agent at a host-specific skill file.

Generic shape:

```text
Read `/path/to/Skill-List/<host>/skills/<skill-name>/SKILL.md` and follow that skill.
```

Codex:

```text
Read `/path/to/Skill-List/.codex/skills/find-skills/SKILL.md` and find relevant skills for this project.
```

Claude Code:

```text
Read `/path/to/Skill-List/.claude/skills/find-skills/SKILL.md` and find relevant skills for this project.
```

Cursor:

```text
Read `/path/to/Skill-List/.cursor/skills/find-skills/SKILL.md` and find relevant skills for this project.
```

Gemini CLI:

```text
Read `/path/to/Skill-List/.gemini/skills/find-skills/SKILL.md` and find relevant skills for this project.
```

## Codex Workflow Docs

Use this prompt in a project that has the Codex skills installed:

```text
Create Codex workflow markdown for this project.
Generate code authoring, code validation, and orchestration docs tailored to this repository.
```

The `agent-workflow-docs` skill creates:

```text
AGENTS.md
docs/agent-workflows/code-authoring.md
docs/agent-workflows/code-validation.md
docs/agent-workflows/orchestration.md
```

If task artifacts are requested, it also creates:

```text
docs/tasks/plan.md
docs/tasks/phase_001/task.md
docs/tasks/phase_001/implement.md
```

Use `create-plan` when a request needs read-only planning, harness awareness, or phased work:

```text
Use create-plan to produce a phase-based implementation plan.
```

`create-plan` follows the artifact conventions defined by `agent-workflow-docs`.

## Installed Files

Each host gets one or more self-contained skills:

```text
.codex/skills/find-skills/SKILL.md
.codex/skills/review-claude/SKILL.md
.codex/skills/agent-workflow-docs/SKILL.md
.codex/skills/agents-md/SKILL.md
.codex/skills/architecture/SKILL.md
.codex/skills/ask-questions-if-underspecified/SKILL.md
.codex/skills/api-design-principles/SKILL.md
.codex/skills/brainstorming/SKILL.md
.codex/skills/code-review-checklist/SKILL.md
.codex/skills/concise-planning/SKILL.md
.codex/skills/create-plan/SKILL.md
.codex/skills/create-pr/SKILL.md
.codex/skills/frontend-design/SKILL.md
.codex/skills/lint-and-validate/SKILL.md
.codex/skills/pr-writer/SKILL.md
.codex/skills/security-auditor/SKILL.md
.codex/skills/systematic-debugging/SKILL.md
.codex/skills/test-driven-development/SKILL.md
.claude/skills/find-skills/SKILL.md
.cursor/skills/find-skills/SKILL.md
.cursor/skills/review-agents/SKILL.md
.cursor/skills/review-claude/SKILL.md
.gemini/skills/find-skills/SKILL.md
.gemini/skills/review-agents/SKILL.md
.gemini/skills/review-claude/SKILL.md
```

Each installed skill should be usable from its own `SKILL.md`. Installing only one host folder is enough when you only use that host.

## Local Review Agents

This repository can run second-pass code reviews through Claude Code, Codex, or both. The shared scripts live under:

```text
.codex/skills/review-claude/scripts/
```

Run from the project root:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine claude
.codex/skills/review-claude/scripts/review-with-agents.sh --engine codex
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both
```

Useful scopes:

```bash
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both --staged
.codex/skills/review-claude/scripts/review-with-agents.sh --engine both --base origin/main
```

Claude review details:

- Reads `ANTHROPIC_API_KEY` from `.env`.
- Uses Claude Code `--model sonnet` by default.
- Writes Markdown review reports under `.codex/skills/review-claude/reports/`.
- Appends estimated spend to project-root `cost.txt` in USD.

Codex review details:

- Uses the local `codex` CLI.
- Runs read-only review against the generated diff prompt.
- Writes Markdown review reports under `.codex/skills/review-claude/reports/`.
- Does not currently write per-run cost because the Codex CLI does not expose the same `total_cost_usd` field used by Claude Code.

Smoke test Claude API access with a tiny temporary repository:

```bash
.codex/skills/review-claude/scripts/smoke-test-claude-review.sh
```

## Local Secrets And Cost Tracking

Create a local `.env` file for secrets:

```bash
ANTHROPIC_API_KEY=your-anthropic-api-key
```

`cost.txt` is created at the project root when Claude reviews run:

```text
2026-04-24T00:56:09.651Z | model=sonnet | scope=working tree changes against HEAD | cost_usd=$0.026879 | output=/path/to/review.md
```

Both `.env` and `cost.txt` are intended to stay local.

## Maintainer Checks

Run all lightweight checks before committing:

```bash
./scripts/check-all.sh
```

This runs the host-copy sync check and the structured scoring-case guardrail check.

Check review script syntax:

```bash
bash -n .codex/skills/review-claude/scripts/review-with-claude.sh
bash -n .codex/skills/review-claude/scripts/review-with-codex.sh
bash -n .codex/skills/review-claude/scripts/review-with-agents.sh
bash -n .codex/skills/review-claude/scripts/smoke-test-claude-review.sh
```

## Maintaining Host Copies

When a skill is available for multiple hosts, the host-specific `SKILL.md` files should stay aligned except for host names, workflow headings, and install/search paths.

For `find-skills`, use the Codex copy as the comparison baseline when editing shared content:

```text
.codex/skills/find-skills/SKILL.md
```

Safe update flow:

1. Edit the shared content in all host-specific `SKILL.md` files.
2. Keep only the host-specific labels and paths different.
3. Run the drift check:

```bash
./scripts/check-skill-sync.sh
```

The check normalizes expected host differences and fails when any shared content drifts. It has no external dependencies beyond standard shell tools, so it can also be used as a lightweight CI check.

## Find Skills Behavior

`find-skills` is the current discovery skill in this repository.

Agents should not use `find-skills` unless the user explicitly names or asks for it.

When using `find-skills`, the agent should:

1. Read `SKILL.md`.
2. Understand the project or idea.
3. Search available `SKILL.md` files.
4. Infer whether missing context would change the recommendation.
5. Ask up to 3 clarification questions only when needed.
6. Score candidates and bucket them into `Precise`, `Balanced`, `Recall`, or `Exclude`.
7. Show only `Precise` recommendations in chat unless the user asks for more.
8. Mention broader candidates when useful.

## Scoring Model

Candidate scoring is rubric-first. The installed `SKILL.md` files define a base score from `0-100` using task match, routing fit, actionability, specificity, and confidence. Optional external signals can adjust that score, but the total external adjustment is bounded to `-15..15`.

External signals may include prior successful use, project-local stack evidence, user or repo preferences, recent usage patterns, skill freshness, retrieval scores, and optional SNS/community evidence. Community signals are conservative by design: they can support candidate expansion, trend detection, practical usage evidence, confidence adjustment, and freshness checks, but they cannot override repository metadata, hard constraints, or the base rubric.

Bucket assignment is not score-only. `Precise` requires a strong final score, base score at least `70`, direct task support, no hard conflict, immediate actionability, and explicit metadata evidence. Hard conflicts always force `Exclude`.

Human-readable and machine-readable scoring cases are in:

```text
examples/scoring-cases.md
examples/scoring-cases.yaml
```

Validate the structured cases with:

```bash
./scripts/check-scoring-cases.py
```

## Output Format

Scores are request-relative fit scores, not general skill quality scores. Normal user-facing output should stay concise, with detailed scoring breakdowns reserved for audit/debug or when requested.

```text
Precise

1. <skill-name> - <final_score> final / <base_score> base
   Reason: <one-line request-relative fit reason>
   Evidence: <name, description, When to Use, routing table, or project-context evidence>
   External: <external_adjustment, only if nonzero>

Balanced

1. <skill-name> - <final_score> final / <base_score> base
   Reason: <one-line reason>
   Evidence: <metadata or project-context evidence>
   Why not precise: <missing detail, adjacent scope, weaker actionability, or lower evidence>

Recall

1. <skill-name> - <final_score> final / <base_score> base
   Reason: <fallback, exploration, or follow-up value>
   Evidence: <metadata or project-context evidence>
   Caveat: <why it is broad or conditional>

Excluded

1. <skill-name> - Excluded
   Reason: <hard conflict, contradicted constraint, or out-of-scope explanation>
```

If there are no `Precise` matches, say so and show the best `Balanced` or `Recall` candidates. If the request is ambiguous, state the missing detail that would improve routing. Excluded candidates should only be shown when they explain an important conflict.

The agent also writes a local index under the current project root:

```text
.find-skills/<key>/index.md
```

`<key>` is a short lowercase slug for the user's search, such as `web-game`, `crm`, or `agent-eval`.

The index should include ranked candidates with bucket, score, reason, source path, and install notes.

## Example Domains

CRM project:

```text
revops
hubspot-automation
salesforce-automation
pipedrive-automation
zoho-crm-automation
odoo-sales-crm-expert
```

Small game project:

```text
game-development
2d-games
web-games
game-design
game-art
game-audio
godot-gdscript-patterns
unity-developer
```

Agent project:

```text
agents-md
agent-tool-builder
ai-agents-architect
agent-evaluation
multi-agent-patterns
skill-creator
skill-installer
```

## Search Index

Use key-based folders under the current project root:

```text
.find-skills/<key>/index.md
```

`.find-skills/` is disposable. It can be deleted and recreated.
