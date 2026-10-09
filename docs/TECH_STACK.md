# CanDoKu — Technical Stack

> Cập nhật: 2026-10-09.

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
| State model | CellKind 5 trạng thái: BLANK, MARK, CANDY, ERROR, GIVEN |
| Content | Bank + Pace + Playlist architecture |
| Transform | x8 (4 rotations x 2 mirrors) per level |
| Undo | Undo X luôn hoạt động cố định (RST-021) |
| Hints | Progressive reveal using pace hintCosts |
| Mark | Người chơi tự đánh/xóa X; không auto-lock |
| Save | DualSlotStore A/B atomic JSON |

## 3. Data schemas

| Schema | Version | Description |
|--------|---------|-------------|
| Level bank | v1 | `{bankVersion, size, ranks: {"rank": [levels]}}` |
| Flat bank | v1 | `{bankVersion, type, levels: [...]}` (Variant B) |
| Pace sidecar | v1 | `{bankVersion, size, pacing: {"rank": [{rSeq, hintCosts}]}}` |
| Campaign playlist | v1 | `{campaignVersion, id, playlist: [{label, size, rank, index}]}` |
| Progress | v3 | Campaign + Endless completion tracking |
| Session | v3 | Board, hearts, hints và thời gian |
| Settings | v1 | Audio, haptic, accessibility toggles |

## 4. Content pipeline (offline)

| Tool | Purpose |
|------|---------|
| `tools/convert_extracted_bank.py` | Convert source levels to bank v1 |
| `tools/generate_pace.py` | Generate pace sidecars |
| `tools/validate_content.py` | Validate banks, pace, playlists |
| `tools/verify.py` | Full test suite runner |
| `tools/encode_banks.py` | XOR encode banks for release |
| `tools/endless_coverage_report.py` | Endless mode coverage |

## 5. Module structure

```
game/scripts/
├── core/       3 files — cell_model, candy_rules, board_solver (S1–S7)
├── state/      4 files — dual_slot_store, progress, session, config
├── content/    7+ files — bank_reader, flat_bank_cache, pace_reader, transform, validator, painter, bank_codec
├── input/      touch_decoder, play_session
├── theme/      2 files — palette, layout_tokens
├── feedback/   5 files — pcm_synth, sfx_catalog, sfx_player, bgm_player, vibration
├── campaign/   6+ files — campaign_runtime, bank_cursor, nav_controller, tutorial, endless_runtime, level_selector
└── screens/    app_shell, title, puzzle_screen/board/layout, rule_icon, result, options, pill, cell_animator
```

## 6. Testing

| Layer | Tool | Files |
|-------|------|-------|
| Unit (headless) | `godot --headless --path game --script res://tests/<suite>.gd` | `game/tests/test_*.gd` |
| Validation | Python validators | `tools/*.py` |
| Integration | `test_integration.gd`, `test_screens.gd` | Luồng gameplay và màn hình |
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
- Audio: PCM Synth procedural + OGG Vorbis
- Haptic: Godot Input.vibrate_handheld()

## 8. Build & platform

| Target | Status |
|--------|--------|
| Android | Primary target |
| iOS | Pending (needs Mac + signing) |
| Desktop | Dev/test only |
| Web | Not planned |

## 9. Version management

Xem [VERSIONING](VERSIONING.md) — Release Branch model với nhánh `release/vX.Y.Z`.
