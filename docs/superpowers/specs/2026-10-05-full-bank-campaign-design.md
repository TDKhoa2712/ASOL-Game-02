# Full bank and selectable campaign design

**Date:** 2026-10-05
**Status:** proposed for implementation planning

## Intent and scope

CanDoKu needs original offline content at the scale of the six reference bank and pace files: 36 puzzles at 4×4, 49 at 5×5, and 913 at 6×6, for 998 puzzles total. The reference files provide count and pacing context only. No region map, solution, trace, text, identifier, or level order is imported from them. The game remains within board sizes 4–6 and rules S1–S3.

The owner wants all 998 puzzles reachable in a campaign with five ranks, while retaining a selectable 30-level playtest campaign. The selection belongs in a developer-editable project file, not in player Settings. The existing 30-level progression and its save files must continue to work.

## Options considered

1. **Separate `full_998.json` and `demo_30.json` (chosen).** A developer selector chooses the campaign at boot. The two modes keep separate progress and sessions. The filenames stay accurate, and the short playtest remains reproducible.
2. Replace `demo_30.json` with 998 entries. This gives one playlist but loses a stable 30-level playtest and makes the file name misleading.

Both options use the existing bank v1 and pace v1 formats. Introducing a new bank schema would add migration work without helping content generation or play.

## Bank and pace data

Retain every existing bank level and pace entry at the same `(size, rank, index)`. Append newly generated levels to the existing rank arrays. Add ranks 4 and 5. Target counts are:

| Size | Rank 1 | Rank 2 | Rank 3 | Rank 4 | Rank 5 | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 4×4 | 12 | 10 | 8 | 3 | 3 | 36 |
| 5×5 | 12 | 10 | 8 | 9 | 10 | 49 |
| 6×6 | 199 | 196 | 193 | 167 | 158 | 913 |

The first three rank counts at 4×4 and 5×5 differ from the reference distribution because preserving shipped indices takes precedence. The 6×6 targets match the reference counts by rank. Rank labels use CanDoKu's measured difficulty, not the reference game's rank semantics.

An offline, deterministic content builder takes target counts and a versioned seed, resumes safely, and writes bank and pace files only after validation. Each accepted puzzle must have connected regions, one solution proven by independent exact search, a complete valid S2/S3 logic trace, a rating, and a canonical geometry key distinct from all existing and accepted puzzles of the same size. Pace `rSeq` and `hintCosts` are derived from that trace. The builder records attempts, rejections, seed, tool revision, and output hashes. It must stop with a clear incomplete report if its search budget is exhausted; it must never relax uniqueness or trace requirements to reach the target.

Rank 1–3 preserve the current rating bands for existing entries. New entries are assigned using measured rating and S3 need, with documented per-size thresholds; ranks 4–5 must represent a real increase in reasoning demand within S1–S3. Thresholds are calibrated against candidate distributions before bulk output and checked by tests. No claim about human-perceived difficulty is made until playtesting.

## Playlists and runtime

`demo_30.json` remains a 30-entry playtest. Its first 30 entries follow the approved cross-size progression: L01–L10 use 4×4, L11–L20 use 5×5, and L21–L30 use 6×6, with existing tutorial entries preserved. `full_998.json` starts with those same 30 entries, then includes every remaining bank entry exactly once. Labels continue as L31–L998. The appended order advances through size and rank in a documented deterministic schedule, introducing ranks 4 and 5 before the campaign ends. A validator checks labels, references, complete coverage, and absence of repeated `(size, rank, index)` entries.

`game/data/campaigns/active_campaign.json` is the developer selector with one enum value: `demo_30` or `full_998`. The project default is `full_998`. `app_shell` loads it before constructing campaign services and passes the selected playlist path to `CampaignRuntime`. Unknown values or missing playlist files produce a visible boot error rather than silently choosing another mode. Changing the file takes effect on the next game launch or export.

The 30-level mode continues to use the existing `user://profile` progress and session slots. Full mode uses separate slots beneath `user://profile/full_998`. Player Settings stay shared. This preserves old saves without a save-schema migration and prevents a mode switch from overwriting an active round. The full campaign's first 30 labels and puzzle references match the demo mode, but progress is intentionally independent. The runtime keeps using its snapshot for an in-progress puzzle. DDA may select any available rank 1–5 in the full campaign after the introductory band, while retaining existing promotion limits for the first 30 levels; it falls back to the base rank when a promoted rank lacks the requested index or pace entry.

## Verification and acceptance

- Test the content builder before implementation: deterministic output, append-only preservation, duplicate rejection, search-budget failure, and matching pace generation.
- Validate all 998 puzzles with exact solution and trace checks, canonical uniqueness, five-rank counts, and bank/pace alignment.
- Validate both playlists; assert the full playlist contains 998 unique entries and starts with the same 30 entries as the short playlist.
- Test developer-selector parsing, mode-specific save paths, resume across mode switches, rank 5 selection, and DDA fallback.
- Run relevant Python and Godot suites, clean-room checks, and `tools/verify.py`; keep revision, commands, results, and limits in `scratch/verification/`.
- Treat headless success as a code gate, not device or human playtest acceptance. Keep release claims outside this work.

## Boundaries and risks

The 998-level count is a content target, not a release commitment. The first 30 entries and existing bank indices remain stable. No runtime generator, larger boards, rules beyond S3, economy, ads, or analytics are introduced. Bulk 6×6 generation can be expensive; the builder needs deterministic checkpoints and a finite budget so progress and failures are inspectable. Very large banks may increase startup time; measure parsing and memory during Godot verification and record the result. The current checkout contains uncommitted cross-size campaign work, so implementation occurs on a separate branch from `dev` and integrates that behavior without touching the original checkout.
