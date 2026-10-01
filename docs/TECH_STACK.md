# CanDoKu — Technical Stack

> Cập nhật: 2026-10-02. Mô tả công nghệ rebuild.

## 1. Runtime

| Component | Technology | Version |
|-----------|-----------|---------|
| Engine | Godot | 4.x |
| Language | GDScript | native |
| Data format | JSON | level banks, pace, campaign, save |
| Persistence | Local file I/O | atomic dual-slot A/B |
| Platform | Android, iOS (future) | offline-only |

## 2. Architecture

| Pattern | Implementation |
|---------|---------------|
| Composition root | `app_shell.gd` — no autoloads |
| Signals | Godot native signals — no EventBus |
| State model | CellKind 6-state enum (BLANK→LOCKED) |
| Content | Bank + Pace + Playlist architecture |
| Transform | x8 (4 rotations x 2 mirrors) per level |
| Undo | Command pattern with grouped actions |
| Hints | Progressive reveal using pace hintCosts |
| Auto-mark | System auto-locks excluded cells |
| Save | DualSlotStore A/B atomic JSON |

## 3. Data schemas

| Schema | Version | Description |
|--------|---------|-------------|
| Level bank | v1 | `{bankVersion, size, ranks: {"rank": [levels]}}` |
| Pace sidecar | v1 | `{bankVersion, size, pacing: {"rank": [{rSeq, hintCosts}]}}` |
| Campaign playlist | v1 | `{campaignVersion, id, playlist: [{label, size, rank, index}]}` |
| Progress | v2 | Campaign completion tracking |
| Session | v3 | In-game state (board, hearts, recorder) |
| Settings | v1 | Audio, haptic, accessibility toggles |

## 4. Content pipeline (offline)

| Tool | Purpose |
|------|---------|
| `GDD/tools/generate_levels.py` | Generate level candidates |
| `GDD/tools/validate_levels.py` | Validate schema, uniqueness, trace |
| `GDD/tools/convert_to_bank.py` | Convert to bank schema v1 |
| `GDD/tools/generate_pace.py` | Generate pace sidecars |
| `tools/verify.py` | Full test suite runner |

## 5. Module structure

```
game/scripts/
├── core/       3 files — cell_model, candy_rules, board_solver
├── state/      4 files — dual_slot_store, progress, session, config
├── content/    5 files — bank_reader, pace_reader, transform, validator, painter
├── input/      3 files — touch_decoder, action_recorder, play_session
├── theme/      2 files — palette, layout_tokens
├── feedback/   4 files — sfx_catalog, sfx_player, bgm_player, vibration
├── campaign/   4 files — campaign_runtime, bank_cursor, nav_controller, tutorial
└── screens/    7 files — app_shell, title, puzzle_screen/board, result, options, pill
Total: 32 files, each ≤ 300 lines
```

## 6. Testing

| Layer | Tool | Files |
|-------|------|-------|
| Unit (headless) | `godot --headless --script` | 8 test files |
| Validation | Python validators | GDD/tools/*.py |
| Integration | Manual + verify.py | 13 journeys |
| Clean-room | grep | No reference names in code |
| Device | Manual QA | Android (iOS pending) |

```bash
# Full gate
rtk python -B tools/verify.py --godot <executable>
```

## 7. Dependencies

- **Zero external dependencies** — only Godot built-in
- No plugins, addons, or third-party libraries
- No network, backend, or account requirements
- Audio: Godot AudioStreamPlayer + OGG Vorbis
- Haptic: Godot Input.vibrate_handheld()

## 8. Build & platform

| Target | Status |
|--------|--------|
| Android | Primary target |
| iOS | Pending (needs Mac + signing) |
| Desktop | Dev/test only |
| Web | Not planned |

No CI/CD configured. Local verification via `tools/verify.py`.
