# Repository Restructure and Agent Pipeline Design

**Date:** 2026-09-22  
**Project:** ASOL-Game-02  
**Status:** Approved conversational design; awaiting written-spec review  
**Scope:** Repository organization, document authority, local work-package pipeline, Git baseline, and safe folder rename

## 1. Purpose

Restructure the design-only project into a professional repository that a human or any coding agent can understand and operate without relying on Codex-specific skills, external issue trackers, or undocumented conventions.

Success means:

- Canonical design, governance, active reviews, historical records, work contracts, and execution evidence have visibly different locations and authority.
- A human assigns one explicit work-package ID; an agent cannot self-claim unrelated work.
- The repository can validate package metadata, dependencies, requirement/QA references, internal links, path scope, verification evidence, and handoff completeness using Python standard library only.
- Existing GDD validation continues to pass.
- Historical material remains recoverable while generated caches and duplicate artifacts are removed.
- The final project directory is `D:\Work\Alpaca_Solution\ASOL-Game-02`.

## 2. Constraints and Non-goals

### Constraints

- Keep `GDD/` and its canonical file paths stable.
- Use Markdown with TOML front matter for work packages.
- Use Python 3.11+ standard library only for the agent pipeline; `tomllib` parses metadata.
- Keep the workflow agent-agnostic and offline-capable.
- Preserve unique historical documents under an explicit archive.
- Do not silently change gameplay rules, schemas, progression, scoring, or release content.
- Do not overwrite an existing `ASOL-Game-02` directory during the final rename.

### Non-goals

- Creating the Godot project or game implementation.
- Completing GDD v1.0 Design Freeze.
- Producing the 24-level release campaign.
- Activating post-MVP features, S4/S5, N>6 release content, economy, advertisements, collection systems, or level generation.
- Integrating a hosted issue tracker.

## 3. Target Repository Structure

```text
ASOL-Game-02/
├─ README.md
├─ AGENTS.md
├─ CONTRIBUTING.md
├─ .gitignore
│
├─ GDD/
│  ├─ README.md
│  ├─ 01-tam-nhin-va-pham-vi.md
│  ├─ ...
│  ├─ 12-sinh-level-do-kho-va-endless.md
│  ├─ data/
│  └─ tools/
│
├─ docs/
│  ├─ governance/
│  ├─ reviews/
│  ├─ reports/
│  └─ archive/
│     ├─ reviews/
│     └─ agent-history/
│
├─ work/
│  ├─ README.md
│  ├─ packages/
│  ├─ state/
│  ├─ handoffs/
│  ├─ evidence/
│  └─ templates/
│
└─ tools/
   ├─ agent_pipeline.py
   ├─ reports/
   └─ tests/
```

`game/` is intentionally absent until the M0 bootstrap package creates a real Godot project. Empty product directories must not imply implementation progress that does not exist.

## 4. Document Authority

Documents have six authority classes, in descending order for implementation decisions:

1. **Canonical design:** `GDD/`
2. **Governance:** `docs/governance/`
3. **Work contract:** `work/packages/`
4. **Runtime evidence:** `work/evidence/` and `work/handoffs/`
5. **Active review/reference:** `docs/reviews/`
6. **Historical only:** `docs/archive/`

`docs/governance/document-register.toml` records each governed document with:

- `path`
- `class`
- `status`
- `owner`
- optional `superseded_by`

Archive documents are immutable evidence. They must carry a visible `SUPERSEDED` or `HISTORICAL` notice and point to the current authority. Agents must not derive implementation requirements from archive content.

`GDD/12-sinh-level-do-kho-va-endless.md` remains in `GDD/` for path stability but is registered as `PROPOSED/POST-MVP`. A work package may use it only when `read_first` explicitly names it and the active phase permits post-MVP work.

## 5. Human and Agent Entrypoints

### `README.md`

The human-facing project map explains current status, repository areas, core commands, and the absence of a runnable game.

### `AGENTS.md`

The universal agent entrypoint remains concise and contains only mandatory behavior:

- Follow the authority order.
- Work only on the assigned package ID.
- Run `inspect` before editing.
- Never use archive material as an active requirement.
- Stay inside `allowed_paths`.
- Change rules, schemas, progression, or scoring only through a `design-change` package.
- Run `verify` and create a valid handoff before reporting completion.
- Preserve original assets and levels; do not copy commercial game content.

Tool-specific instructions may supplement this contract but cannot override repository authority or package scope.

### `CONTRIBUTING.md`

The contribution guide explains branch naming, package state ownership, validation, review, commit expectations, and how humans create or approve packages.

## 6. Work-package Contract

Each package is a Markdown file whose opening TOML front matter is delimited by `+++`.

Required fields:

```toml
+++
id = "M0-A01"
title = "Godot toolchain and device baseline"
kind = "implementation"
phase = "M0"
status = "ready"
depends_on = []
requirements = ["D-06", "TECH-13", "TECH-19"]
qa = ["QA-26", "QA-30"]
read_first = [
  "GDD/README.md",
  "GDD/02-luat-choi-va-trang-thai.md",
  "GDD/05-kien-truc-va-du-lieu.md",
]
allowed_paths = ["game/**", "work/evidence/M0-A01/**"]
deliverables = ["game/project.godot"]
out_of_scope = ["production content", "wallet", "ads", "S4", "S5"]
+++
```

The Markdown body defines intent, acceptance criteria, exact verification commands, expected evidence, known risks, and reviewer focus. Validation commands are TOML arrays of process arguments rather than shell command strings.

The package `status` is the coordinator-owned catalog state before execution (`draft` or `ready`). Once `start` creates `work/state/<id>.toml`, the mutable state file becomes the authoritative effective status (`in_progress`, `blocked`, `review`, or `done`) while the package contract remains `ready`. `list` and dependency checks resolve this rule consistently; they never require the two files to be edited in tandem.

Supported `kind` values are:

- `implementation`
- `content`
- `research`
- `design-change`
- `governance`

Implementation packages cannot modify `GDD/`, `docs/governance/`, `AGENTS.md`, or pipeline code unless those paths are explicitly authorized by a governance package. A `design-change` package that changes rules, schema, progression, or scoring must declare the coupled GDD, fixture, validator/test, and QA paths.

## 7. Mutable State and Handoffs

Package contracts remain stable. Mutable execution state lives in `work/state/<id>.toml` and contains:

- assigned agent
- lifecycle status
- branch name
- base revision
- start/update timestamps
- blocker reason when applicable

Handoffs live at `work/handoffs/<id>.md` and must include:

- package ID and agent
- requirements satisfied
- QA covered
- changed files
- validation commands and outcomes
- evidence paths
- remaining risks and limitations
- reviewer disposition

Selected machine-produced logs and measurements live under `work/evidence/<id>/` and are committed when they support acceptance. Raw temporary output stays ignored. The pipeline must not capture environment dumps, secrets, tokens, or unrelated system information.

## 8. Lifecycle and Ownership

```text
human assignment
      ↓
inspect dependencies, authority, scope, and reading list
      ↓
start records agent, branch, and base revision
      ↓
implementation inside allowed paths
      ↓
verify runs checks and inspects Git diff
      ↓
handoff records evidence and remaining risk
      ↓
reviewer accepts or rejects
      ↓
done or returned to in_progress
```

Allowed transitions:

- `draft → ready`: owner/coordinator only
- `ready → in_progress`: assigned agent after dependency and Git checks
- `in_progress → review`: assigned agent after successful verification and complete handoff
- `review → done`: reviewer/coordinator only
- `review → in_progress`: reviewer rejection with reason
- `in_progress → blocked`: assigned agent with a concrete blocker and evidence
- `blocked → in_progress`: coordinator after the blocker is resolved

No command selects or claims the next package. A human supplies the package ID.

Each package uses branch `work/<package-id>-<slug>`. `start` normally requires a clean working tree and records the current commit. Git subprocesses use `-c safe.directory=<resolved-repository-root>` for that exact repository so sandbox ownership differences do not require a global Git configuration change. When a constrained environment cannot create a branch, the handoff must state that limitation and the coordinator owns integration.

## 9. Agent Pipeline CLI

The zero-dependency entrypoint is `python tools/agent_pipeline.py`.

Commands:

```text
validate
doctor
list --status <status>
trace <requirement-id>
inspect <package-id>
start <package-id> --agent <name>
verify <package-id>
handoff <package-id>
accept <package-id>
```

Responsibilities:

- `validate`: validate repository metadata without changing files.
- `doctor`: run structural checks across documents, packages, links, protected paths, and prohibited artifacts.
- `list`: show packages filtered by lifecycle status.
- `trace`: locate a canonical requirement, related QA, decisions, and consuming packages.
- `inspect`: print the package scope, dependencies, reading list, deliverables, checks, and exclusions.
- `start`: validate assignment/dependencies/Git state and create mutable state.
- `verify`: execute declared validation processes, store concise evidence, and compare the diff with `allowed_paths`.
- `handoff`: create a missing handoff skeleton and exit nonzero, or validate a completed handoff and move eligible state to review. It never advances an incomplete handoff.
- `accept`: validate reviewer preconditions and mark the package done.

Commands fail closed. They return a nonzero exit code and identify the file, field, and correction. They do not silently normalize invalid contracts or expand scope.

## 10. Validation Rules

Repository validation covers:

- TOML syntax and required package fields.
- Unique package IDs and valid enums.
- Existing dependencies and acyclic dependency graph.
- Dependency completion before `start`.
- Legal lifecycle transitions.
- Requirement IDs (`D`, `GR`, `UX`, `LV`, `TECH`, `ART`, `DEC`) defined by an authorized document.
- QA IDs defined by `GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md`.
- Internal Markdown links.
- Absence of `file:///`, `ASOL-Game-03`, and workspace-specific absolute links in active documents.
- Normalized relative allowed paths that cannot escape the repository.
- Git diff containment within `allowed_paths`.
- Protected-path rules by package kind.
- Validation commands represented as argument arrays.
- Handoff completeness and evidence existence.
- Absence of Python cache, Godot cache, Repomix snapshots, duplicate reports, and unapproved generated artifacts.

## 11. Initial Backlog

The restructure seeds only work that has enough authority to be represented honestly:

| ID | Status after restructure | Purpose |
| --- | --- | --- |
| `SETUP-001` | `done` after acceptance | Repository restructure and agent pipeline |
| `M0-A01` | `ready` | Godot version, renderer, device, OS, and toolchain baseline |
| `M0-A02` | `draft` | Gesture and interaction prototype |
| `M0-A03` | `draft` | Sprite, board layout, and mobile performance spike |
| `M0-GATE` | `draft` | Review M0 evidence and approve or reject progression to M1 |

Packages corresponding to later GDD/08 work remain conceptual until their dependencies and ownership are ready. The pipeline does not convert all future work into `ready` merely because it appears in a plan.

## 12. Cleanup and Migration

### Preserve and move

```text
design-control/          → docs/governance/
design-control/reviews/  → docs/reviews/
design-reviews/          → docs/archive/reviews/
docs/superpowers/        → docs/archive/agent-history/superpowers/
.superpowers/sdd/        → docs/archive/agent-history/superpowers-sdd/
GDD/tools/generate_game_design_report.py
                         → tools/reports/generate_game_design_report.py
docs/Bao_Cao_...docx     → docs/reports/Bao_Cao_...docx
```

### Remove after baseline commit

- Duplicate root DOCX.
- `meowdoku-clone.xml`, a reproducible Repomix snapshot.
- `__pycache__/` and `*.pyc`.
- Empty tool-state directories after their unique records are archived.

### Ignore going forward

`.gitignore` covers Python caches, `.codegraph/`, Godot `.godot/`, export/build artifacts, Repomix snapshots, temporary files, and transient evidence that is not explicitly selected for a handoff.

All active links are updated after moves. Historical documents may retain quoted obsolete paths only when clearly marked historical; they must not expose obsolete paths as the primary navigation route.

## 13. Git and Folder Rename

The repository first records a pre-restructure baseline commit. The restructure and verified pipeline form a separate commit.

The directory rename occurs only after all repository changes, tests, and commits complete:

1. Resolve source and target absolute paths.
2. Confirm source is exactly `D:\Work\Alpaca_Solution\ASOL-Game-03`.
3. Confirm target is exactly `D:\Work\Alpaca_Solution\ASOL-Game-02` and does not exist.
4. Rename from the common parent with native PowerShell `Move-Item -LiteralPath`.
5. Perform no further writes from the old workspace session.
6. Reopen the project at the new path.

The rename never overwrites or merges into an existing target directory.

## 14. Testing Strategy

`tools/tests/test_agent_pipeline.py` uses `unittest` and temporary repositories to exercise:

- valid and malformed TOML front matter
- missing required fields and duplicate IDs
- nonexistent dependencies and dependency cycles
- illegal lifecycle transitions
- missing requirement and QA references
- broken internal links and obsolete absolute paths
- path traversal and overly broad allowed paths
- protected-path changes by implementation packages
- invalid shell-string validation commands
- incomplete handoffs and missing evidence
- dirty Git state, invalid base revision, and out-of-scope diff

The final verification set is:

```text
python GDD/tools/validate_levels.py GDD/data/levels.sample.json
python -m unittest discover GDD/tools -p "test_*.py" -v
python -m unittest discover tools/tests -p "test_*.py" -v
python tools/agent_pipeline.py doctor
python tools/agent_pipeline.py inspect SETUP-001
python tools/agent_pipeline.py inspect M0-A01
```

## 15. Definition of Done

The restructure is complete only when:

- A baseline commit and a verified restructure commit exist.
- Root contains only clear entrypoints and role-based directories.
- Duplicate reports, caches, and Repomix snapshots are absent.
- Active internal links and the document register validate.
- Existing level validator and all 23 existing unit tests pass.
- New pipeline tests pass.
- `doctor`, `inspect SETUP-001`, and `inspect M0-A01` succeed.
- `SETUP-001` has a complete handoff and evidence.
- No game implementation or gameplay rule changed.
- The project directory is safely renamed to `ASOL-Game-02` and the workspace is reopened there before further work.
