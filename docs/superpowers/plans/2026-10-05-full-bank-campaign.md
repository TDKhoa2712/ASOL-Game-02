# Full Bank Campaign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and validate 998 original puzzles across five ranks, make them playable in a complete campaign, and let a developer choose that campaign or the existing 30-level demo.

**Architecture:** A deterministic offline builder appends bank v1 levels and pace v1 entries while preserving all existing indices. A separate playlist builder includes every bank tuple once after the existing 30-level prefix. A small boot selector chooses playlist and save directory; the existing readers and runtime consume the selected data.

**Tech Stack:** Python 3 standard library, Godot 4.7.2/GDScript, JSON, existing CanDoKu exact and logic solvers.

**Spec:** `docs/superpowers/specs/2026-10-05-full-bank-campaign-design.md`

## Global Constraints

- Targets: 4×4 `12/10/8/3/3`; 5×5 `12/10/8/9/10`; 6×6 `199/196/193/167/158`, totaling 998.
- Preserve existing `(size, rank, index)` positions, puzzle geometry, solutions and givens, and preserve L01–L30 demo references. Repair the invalid logic traces and derived pace for all 30 existing 5×5 levels, as approved by the user; preserve all other old entry values.
- The preserved 5×5 set has three exact repeated puzzles at rank/index pairs `1[10]`–`2[0]`, `1[11]`–`2[1]`, and `2[9]`–`3[0]`. Whitelist only these identified legacy pairs in deep validation. Exclude their geometry from all generated levels and reject any other duplicate.
- Generate original geometries; use the six reference files for counts and pacing context only. Keep N=4–6, S1–S3, bank v1, pace v1, and files at `game/data/banks/bank_NxN.json` plus sidecars.
- No runtime generator, larger boards, additional rules, monetization, analytics, release claim, or player-facing campaign switch.
- Keep modules at most 300 lines, use no autoloads, and commit only files in this task. Leave the user's uncommitted spec edits untouched.
- The current `pace_adjuster.gd` caps promotion at rank 4 after order 30; implement rank-5 promotion to satisfy the spec despite its outdated no-code-change statement.

## Review Focus

- A wrong selector value or missing playlist must show a boot error, not silently fall back.
- Switching modes during an active round must preserve each mode's progress and session independently.
- Existing bank indices and first 30 playlist entries must retain their puzzle meaning.
- A generator stopped by its budget must retain a resumable checkpoint but leave the bank and pace unchanged.
- A full playlist with duplicate tuples or an omitted bank entry must fail validation even when all labels are unique.

---

### Task 1: Deep content and coverage validator

**Files:** Modify `tools/validate_content.py`, `tools/tests/test_validate_content.py`; create `tools/validate_full_content.py`, `tools/tests/test_validate_full_content.py`.

**Interfaces:** `validate_full_banks(banks: dict[int, dict], paces: dict[int, dict], targets: dict[int, dict[str, int]]) -> list[str]`; `validate_full_playlist(playlist: dict, demo: dict, banks: dict[int, dict]) -> list[str]`. The CLI accepts `--banks DIR`, with optional `--playlist FILE --demo FILE`.

- [ ] Write tests that reject duplicate `(size, rank, index)` tuples, omitted tuples, changed L01–L30 references, duplicate canonical geometries, invalid traces or multiple solutions, and mismatched pace; test valid miniature fixtures.
- [ ] Run `rtk python -B -m unittest discover tools/tests -p test_validate_full_content.py` and `test_validate_content.py`; confirm the new tests fail for the missing behavior.
- [ ] Implement tuple checking in the playlist validator and deep full-content checks using the existing independent exact and trace validators. Keep validation separate from generation.
- [ ] Rerun the two test modules; expect PASS. Run `rtk python -B -m unittest discover tools/tests -p test_*.py`; expect PASS.
- [ ] Commit only validator and test files as `feat(content): validate full bank and campaign coverage`.

### Task 2: Deterministic, resumable bank expansion

**Files:** Create `GDD/tools/expand_bank.py`, focused helper module(s) if needed, `GDD/tools/test_expand_bank.py`; retain `GDD/tools/build_playtest_bank.py` for the original 30-level workflow.

**Interfaces:** `expand_bank(size: int, bank_path: Path, pace_path: Path, checkpoint_path: Path, seed: str, max_attempts: int, target_counts: dict[str, int]) -> dict`; CLI accepts `--size`, `--bank`, `--pace`, `--checkpoint`, `--seed`, `--max-attempts` and uses the fixed production targets. Tests pass reduced `target_counts`. Return/report `COMPLETE` or `INCOMPLETE` with attempt index, rejection counts, thresholds, and hashes.

- [ ] Write tests for deterministic results and resume equivalence on reduced targets, append-only old values, duplicate geometry rejection, budget exhaustion without output mutation, and pace entries derived from S2/S3 trace.
- [ ] Run `rtk python -B -m unittest GDD.tools.test_expand_bank`; confirm RED for missing builder behavior.
- [ ] Implement one deterministic candidate stream per size using CanDoKu's `candidate`, `exact_check`, `solve`, `canonical_regions`, and `puzzle_key`. Checkpoint accepted candidates and next attempt atomically in `scratch/`; write bank and pace via temporary files only after full validation. Rank accepted candidates by measured rating and necessary S3, retaining old entries, and report the observed per-size band boundaries. Keep a finite attempt budget and validate monotonic median difficulty across ranks.
- [ ] Rerun `test_expand_bank.py` and the existing generator tests; expect PASS. Run a finite 6×6 calibration sample into `scratch/` and record acceptance rates before choosing production budgets.
- [ ] Commit builder, helper modules, and tests as `feat(content): add resumable original bank expansion`.

### Task 3: Generate and prove the three complete banks

**Files:** Modify the six existing `game/data/banks/bank_*.json` files; create ignored `scratch/content_gen/full_bank/` reports and checkpoints.

**Interfaces:** Uses Task 2 CLI and Task 1 full validator. Target counts are fixed in Global Constraints.

- [ ] Capture SHA-256 and parsed values for all original rank 1–3 entries and pace entries before generation; place evidence in `scratch/verification/`. Record the 5×5 trace failures separately.
- [ ] Run the builder separately for 4×4, 5×5, and 6×6 with versioned seeds, finite budgets, and resumable checkpoints. If a budget is exhausted, inspect the rejection report and adjust only search heuristics or budget while preserving uniqueness and S1–S3 gates.
- [ ] Run `rtk python -B tools/validate_full_content.py --banks game/data/banks`; expect 36/49/913 valid original levels, five ranks per size, matching pace, no new duplicate geometry, and verified traces. Report the three preserved 5×5 duplicates.
- [ ] Recheck saved original values: every old puzzle's `(size, rank, index)`, geometry, solution and givens remain unchanged; every old 4×4 and 6×6 entry remains fully unchanged; the 30 old 5×5 trace and pace entries match the independently checked solver trace. Commit only the six bank and pace files as `feat(content): expand original banks to five ranks`.

### Task 4: Build the 998-entry campaign

**Files:** Create `GDD/tools/build_full_campaign.py`, `GDD/tools/test_build_full_campaign.py`, `game/data/campaigns/full_998.json`; modify `tools/verify.py`.

**Interfaces:** `build_full_campaign(demo: dict, banks: dict[int, dict]) -> dict` preserves the demo prefix and appends each unused tuple in size/rank/index order with consecutive `L31`–`L998` labels.

- [ ] Write tests for unchanged 30-entry prefix, deterministic order, 998 unique labels and tuples, and no missing bank tuple; verify failure on a short bank fixture.
- [ ] Run `rtk python -B -m unittest GDD.tools.test_build_full_campaign`; confirm RED.
- [ ] Implement the builder, generate `full_998.json`, and add full-content and playlist validation to `tools/verify.py`.
- [ ] Run campaign tests and `rtk python -B tools/validate_full_content.py --banks game/data/banks --playlist game/data/campaigns/full_998.json --demo game/data/campaigns/demo_30.json`; expect PASS.
- [ ] Commit only builder, tests, playlist, and gate wiring as `feat(campaign): add complete 998-level playlist`.

### Task 5: Developer selector and separate save slots

**Files:** Create `game/scripts/campaign/campaign_selector.gd`, `game/tests/test_campaign_selector.gd`, `game/data/campaigns/active_campaign.json`; modify `game/scripts/screens/app_shell.gd`, `game/tests/test_integration.gd`.

**Interfaces:** `CampaignSelector.load_config(path: String, base_profile_dir: String) -> Dictionary` returns `{ok, playlist_path, progress_dir, error}`. `demo_30` uses `user://profile`; `full_998` uses `user://profile/full_998`. `ConfigStore` retains the base profile path.

- [ ] Write Godot tests for both choices, invalid or missing selector data and playlist, old demo save preservation, full-mode save isolation, active-session resume after mode switches, and a visible boot error.
- [ ] Run targeted Godot suites; confirm RED for selector behavior.
- [ ] Implement selector load before `CampaignRuntime` construction in `app_shell.gd`; use `demo_30` while full content is absent during development, then set committed `active_campaign.json` to `full_998` after Task 4.
- [ ] Rerun selector, integration, campaign runtime, demo campaign, and screens suites; expect PASS.
- [ ] Commit only selector, config, app shell, and tests as `feat(campaign): select demo or full content at boot`.

### Task 6: Rank-5 DDA and runtime coverage

**Files:** Modify `game/scripts/campaign/pace_adjuster.gd`, `game/tests/test_pace_adjuster.gd`, `game/tests/test_campaign_runtime.gd`; add focused full-campaign smoke test if needed.

**Interfaces:** `rank_offset(level_order: int, base_rank: int) -> int` retains current limits through order 30 and permits promotion from rank 4 to 5 afterward; `CampaignRuntime` falls back to base rank if target index or pace is absent.

- [ ] Add tests for rank 4 → 5 promotion after order 30, no promotion above 5, old order 1–30 limits, rank-5 level loading, and missing-index fallback.
- [ ] Run targeted Godot suites; confirm RED for rank-5 promotion.
- [ ] Change only the post-30 promotion cap and any runtime guard proved necessary by the tests.
- [ ] Rerun DDA, campaign runtime, and full-campaign smoke suites; expect PASS. Commit only these files as `feat(campaign): support rank five in adaptive selection`.

### Task 7: Documentation and final gate

**Files:** Modify `docs/DECISIONS.md`, `docs/STATUS.md`, `README.md` or the existing developer guide for the selector; leave the user's uncommitted spec file unstaged.

**Interfaces:** Document `active_campaign.json` edit values, restart behavior, separate save locations, generation command and evidence, rank counts, and playtest limitations.

- [ ] Update docs for the new product decision and how to switch modes locally before export. Check links, commands, counts, and consistency with the implemented files.
- [ ] Run `rtk proxy rg` clean-room and extracted-source checks from `AGENTS.md`; expect no matches.
- [ ] Run `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>` and inspect `scratch/verification/` output; expect every Python, content, and Godot gate PASS on the final tree.
- [ ] Check `rtk git diff --check`, module line counts, original bank hashes, and `rtk git status --short`; commit only task docs as `docs(content): document full campaign selector and limits`.
- [ ] Report the revision, test commands/results, generation report, and remaining human/device playtest limits. Do not merge, push, or publish without a separate request.
