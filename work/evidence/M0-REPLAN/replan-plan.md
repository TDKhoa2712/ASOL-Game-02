# M0 Editor-First Replan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-sequence M0 so a playable interaction prototype can be built in Godot Editor before physical-device validation, while preserving mobile evidence as a hard M0-GATE requirement.

**Architecture:** Update only the four M0 package contracts and replan evidence. `M0-A01` becomes the editor/toolchain baseline, `M0-A02` becomes the ready editor prototype, `M0-A03` becomes the ready device/performance package and consumes A02, and `M0-GATE` remains the hard evidence gate.

**Tech Stack:** Markdown/TOML work-package contracts, Python repository pipeline, Git branches/state.

**Spec:** `work/evidence/M0-REPLAN/replan-spec.md`

## Global Constraints

- Preserve Godot 4.7.2, GDScript, renderer `mobile`, and the canonical gameplay rules.
- Do not edit gameplay implementation, GDD rules/schema, production assets, or pipeline code.
- Do not claim TECH-13/19/21 or QA-26 without representative prototype and physical-device evidence.
- All edits must stay inside `M0-REPLAN.allowed_paths` after the package starts.
- Use pipeline `inspect`, `verify`, and `handoff`; do not manually fabricate lifecycle state.

## Review Focus

- Requirement loss: TECH-13/19 and QA-26 must remain assigned to A03/GATE after removal from A01.
- Dependency ordering: A03 must depend on A02, while A02 continues to depend on accepted A01, with no cycle.
- False completion: A01 acceptance must not imply iOS/device/performance evidence exists.
- Prototype blocking: A02 acceptance must be satisfiable in Godot Editor without an APK or physical device.
- Gate weakening: M0-GATE must explicitly reject missing Android/iPhone, macOS/Xcode, or TECH-13/19/21 evidence.

---

### Task 1: Preserve the existing M0-A01 baseline and start M0-REPLAN

**Files:**
- Preserve/commit: `game/**`
- Preserve/commit: `work/evidence/M0-A01/**`
- Preserve/commit: `work/state/M0-A01.toml`
- Already bootstrapped: `work/packages/M0-REPLAN.md`
- Already approved: `work/evidence/M0-REPLAN/replan-spec.md`
- Plan: `work/evidence/M0-REPLAN/replan-plan.md`

**Interfaces:**
- Consumes: approved replan spec and existing blocked A01 workspace.
- Produces: a clean working tree and `work/state/M0-REPLAN.toml` with `status="in_progress"`.

- [x] **Step 1: Verify the existing A01 files before preserving them**

Run:

```powershell
$env:GODOT_BIN='C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe'
python -B -m unittest discover game/tests -p test_*.py
python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json
```

Expected: 5 game tests pass; all 5 level fixtures validate.

- [x] **Step 2: Commit only the preserved A01 baseline**

```powershell
git add game work/evidence/M0-A01 work/state/M0-A01.toml
git commit -m "build: establish Godot 4.7 editor baseline"
```

Expected: commit succeeds; M0-REPLAN bootstrap/spec/plan remain as the only uncommitted files.

- [x] **Step 3: Commit the approved M0-REPLAN bootstrap and planning artifacts**

```powershell
git add work/packages/M0-REPLAN.md work/evidence/M0-REPLAN/replan-spec.md work/evidence/M0-REPLAN/replan-plan.md
git commit -m "docs: define editor-first M0 replan"
```

Expected: working tree is clean.

- [x] **Step 4: Start the assigned package through the pipeline**

```powershell
python tools/agent_pipeline.py start M0-REPLAN --agent codex
```

Expected: current branch is `work/m0-replan-re-sequence-m0-for-editor-first-playable-prototype`; state is `in_progress`.

- [ ] **Step 5: Commit lifecycle state**

```powershell
git add work/state/M0-REPLAN.toml
git commit -m "chore: start M0-REPLAN"
```

Expected: clean tree on the M0-REPLAN branch.

### Task 2: Reassign M0 package responsibilities

**Files:**
- Modify: `work/packages/M0-A01.md`
- Modify: `work/packages/M0-A02.md`
- Modify: `work/packages/M0-A03.md`
- Modify: `work/packages/M0-GATE.md`

**Interfaces:**
- Consumes: package topology defined in `replan-spec.md`.
- Produces: catalog fields and acceptance text consumed by pipeline inspection and future package agents.

- [ ] **Step 1: Run the contract assertion and observe RED**

Run:

```powershell
python -B -c "from pathlib import Path; from tools.agent_pipeline import load_package; a1=load_package(Path('work/packages/M0-A01.md')); a2=load_package(Path('work/packages/M0-A02.md')); a3=load_package(Path('work/packages/M0-A03.md')); gate=load_package(Path('work/packages/M0-GATE.md')); assert a1.requirements == ('D-06',); assert a1.qa == (); assert a2.status == 'ready'; assert a3.status == 'ready'; assert a3.depends_on == ('M0-A02',); assert {'TECH-13','TECH-19','TECH-21'} <= set(a3.requirements); assert {'QA-26','QA-27','QA-30','QA-50'} <= set(a3.qa); assert 'M0-A03' in gate.depends_on"
```

Expected: assertion failure because the existing catalog still has the old responsibilities/statuses.

- [ ] **Step 2: Update M0-A01**

Change the title to `Godot toolchain and editor baseline`, keep only requirement `D-06`, set `qa = []`, and replace device/iOS completion clauses with these measurable acceptance conditions:

```markdown
- [ ] `game/project.godot` loads under pinned Godot 4.7.2.
- [ ] Editor/headless bootstrap starts cleanly with portrait mobile renderer settings.
- [ ] Automated probes cover the project feature pin, viewport, renderer, ETC2/ASTC and export presets.
- [ ] Android host export creates a signed debug APK; the baseline report identifies all unmeasured device/iOS work without claiming it passed.
```

Keep `game/**`, A01 evidence and A01 handoff as the only allowed paths.

- [ ] **Step 3: Update M0-A02**

Set catalog `status = "ready"`. Keep dependency `M0-A01`, current GR/TECH scope and current checks. Replace the device-evidence acceptance bullet with:

```markdown
- [ ] Prototype T01 runs through the Godot Editor using original placeholder visuals; APK, physical-device and performance evidence are not acceptance conditions of this package.
```

Keep interaction contract, Undo/Restart and timing behavior as package acceptance.

- [ ] **Step 4: Update M0-A03**

Change title to `Mobile device, rendering, and performance validation`, set `status = "ready"`, set `depends_on = ["M0-A02"]`, add `TECH-13` to requirements, and add `QA-26` to QA.

Replace acceptance with explicit requirements for:

```markdown
- [ ] Assign exact low-end Android/iPhone models and OS versions plus RAM/VRAM/load budgets.
- [ ] Export, install and run offline on Android and iPhone; iOS evidence uses macOS/Xcode and valid signing configuration.
- [ ] Measure first-level cold load <2 s, FPS ≥55, no stall >100 ms, RAM/VRAM and atlas load against the assigned budgets.
- [ ] Validate safe area, board readability, one shared cat appearance across regions, and representative interaction workload from M0-A02.
- [ ] Missing host/device evidence makes this package blocked; desktop/headless results cannot substitute for it.
```

- [ ] **Step 5: Strengthen M0-GATE wording**

Keep catalog status/dependencies/IDs unchanged. Add acceptance text requiring A01/A02/A03 to be `done` and explicitly rejecting the gate when Android/iPhone identity, iOS macOS/Xcode smoke, or TECH-13/19/21 measurements are missing.

- [ ] **Step 6: Run the same contract assertion and observe GREEN**

Run the exact command from Step 1.

Expected: exit code 0.

- [ ] **Step 7: Inspect every updated package**

```powershell
python tools/agent_pipeline.py inspect M0-A01
python tools/agent_pipeline.py inspect M0-A02
python tools/agent_pipeline.py inspect M0-A03
python tools/agent_pipeline.py inspect M0-GATE
```

Expected: A01 has only D-06/no QA; A02 and A03 are ready; A03 depends on A02 and owns TECH-13/19/21 plus QA-26/27/30/50.

- [ ] **Step 8: Commit package contract changes**

```powershell
git add work/packages/M0-A01.md work/packages/M0-A02.md work/packages/M0-A03.md work/packages/M0-GATE.md
git commit -m "docs: re-sequence M0 around editor prototype"
```

Expected: commit succeeds.

### Task 3: Record replan evidence and complete package verification

**Files:**
- Create: `work/evidence/M0-REPLAN/replan-summary.md`
- Generated: `work/evidence/M0-REPLAN/verification.txt`
- Create: `work/handoffs/M0-REPLAN.md`

**Interfaces:**
- Consumes: updated package contracts and pipeline validation output.
- Produces: reviewer-readable trace of what moved, what remains blocked, and the next assigned-package sequence.

- [ ] **Step 1: Write replan-summary.md**

Include exact before/after ownership table:

| Concern | Before | After |
| --- | --- | --- |
| Godot editor/toolchain | A01 | A01 |
| Android host export | A01 | A01 |
| Editor interaction prototype | A02 draft | A02 ready |
| TECH-13/19/21 device measurements | Split/blocked at A01/A03 | A03 |
| QA-26 offline device run | A01 | A03 |
| Android/iPhone/macOS-Xcode evidence | A01 | A03, enforced by GATE |

Also state that no gameplay rule/schema or quality threshold changed, and the next execution package after acceptance is `M0-A01` to close its now-satisfied baseline before `M0-A02` starts.

- [ ] **Step 2: Run repository and pipeline suites**

```powershell
python -B -m unittest discover tools/tests -p test_*.py
python tools/agent_pipeline.py validate
python tools/agent_pipeline.py doctor
```

Expected: 22 pipeline tests pass; validate and doctor exit 0.

- [ ] **Step 3: Run required package verification**

```powershell
python tools/agent_pipeline.py verify M0-REPLAN
```

Expected: `work/evidence/M0-REPLAN/verification.txt` is written with both checks at exit 0.

- [ ] **Step 4: Write a complete handoff**

Create `work/handoffs/M0-REPLAN.md` with Package, Requirements, QA, Changed files, Validation, Evidence, Remaining risks and Reviewer sections. It must contain no `<...>` placeholders or TODO markers.

- [ ] **Step 5: Commit evidence and handoff**

```powershell
git add work/evidence/M0-REPLAN/replan-summary.md work/evidence/M0-REPLAN/verification.txt work/handoffs/M0-REPLAN.md
git commit -m "docs: record M0 replan evidence"
```

Expected: commit succeeds and the working tree is clean.

### Task 4: Final review and pipeline handoff

**Files:**
- Update: `work/state/M0-REPLAN.toml` through pipeline only.

**Interfaces:**
- Consumes: complete M0-REPLAN commits and evidence.
- Produces: M0-REPLAN state `review`, ready for coordinator acceptance.

- [ ] **Step 1: Re-read the spec and verify every acceptance item**

Run:

```powershell
python tools/agent_pipeline.py inspect M0-REPLAN
git diff --check
git status --short
```

Expected: package scope matches the spec; no whitespace errors; no uncommitted content before handoff.

- [ ] **Step 2: Run the final full verification**

```powershell
python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json
python -B -m unittest discover GDD/tools -p test_*.py
python -B -m unittest discover tools/tests -p test_*.py
python tools/agent_pipeline.py validate
python tools/agent_pipeline.py doctor
```

Expected: 5 fixtures validate; 23 GDD tests and 22 pipeline tests pass; validate and doctor exit 0.

- [ ] **Step 3: Perform final whole-branch review**

Because repository instructions do not authorize sub-agent delegation, review the full diff from the M0-REPLAN base revision, checking every Review Focus item and recording any ruling or deferred minor in the execution ledger.

- [ ] **Step 4: Handoff through the pipeline**

```powershell
python tools/agent_pipeline.py handoff M0-REPLAN
```

Expected: state changes from `in_progress` to `review`.

- [ ] **Step 5: Commit the review state**

```powershell
git add work/state/M0-REPLAN.toml
git commit -m "chore: hand off M0-REPLAN"
```

Expected: clean tree; M0-REPLAN is ready for coordinator acceptance. Do not start another package until the human assigns its exact ID.
