# CanDoKu — Kiến trúc phần mềm

> Kiến trúc cho bản playtest 30 level. Cập nhật: 2026-10-03.
> **Nhánh realignment:** CellKind 5 trạng thái, không auto-lock, UI qua `puzzle_layout.gd`. Undo X vẫn có trong code và đang lệch RST-015; xem [STATUS](STATUS.md).

## 1. Phạm vi và nguồn sự thật

- Luật/domain: [GDD 02](../GDD/02-luat-choi-va-trang-thai.md)
- Plan hiện tại: [Gameplay & UI Realignment](superpowers/plans/2026-10-02-gameplay-ui-realign.md)
- Quyết định: [DECISIONS](DECISIONS.md)
- Trạng thái: [STATUS](STATUS.md)

## 2. Nguyên tắc kiến trúc

1. **Composition root, không autoloads** — `app_shell.gd` khởi tạo và inject dependencies.
2. **Signals thay EventBus** — Godot signals native, không global bus.
3. **Static cho pure logic** — cell_model, candy_rules, board_solver, board_transform stateless.
4. **Module ≤ 300 dòng** — một file, một trách nhiệm.
5. **Offline-first** — không backend, network, account.
6. **Bank-based content** — levels trong rank-based banks, transform x8, pace sidecar cho hints.
7. **Testable** — logic tách UI, headless test cho mọi module.

## 3. Module map

```
game/scripts/
├── core/           # M01 — Domain logic (stateless)
│   ├── cell_model.gd       CellKind 5-state enum + helpers
│   ├── candy_rules.gd      Luật puzzle (placement + clash detection)
│   └── board_solver.gd     Hint engine, progressive hint
│
├── state/          # M02 — Persistence
│   ├── dual_slot_store.gd  A/B atomic JSON save
│   ├── progress_manager.gd Campaign progress
│   ├── session_store.gd    In-game session
│   └── config_store.gd     Settings/preferences
│
├── content/        # M03 — Content pipeline
│   ├── bank_reader.gd      Load rank-based level banks
│   ├── pace_reader.gd      Load hint economy sidecars
│   ├── board_transform.gd  x8 rotation/mirror transforms
│   ├── level_validator.gd  Schema + logic validation
│   └── region_painter.gd   LAB distance graph coloring
│
├── input/          # M04 — Touch & game session
│   ├── touch_decoder.gd    Tap/double-tap/swipe + interpolation
│   ├── play_session.gd     Session state machine + Undo X gần nhất
│   └── action_recorder.gd  Di sản rebuild, không dùng trong PlaySession
│
├── theme/          # M05 — Visual tokens
│   ├── palette.gd          Colors for cell states + UI
│   └── layout_tokens.gd    Spacing, sizing, animation timing
│
├── feedback/       # M06 — Audio & haptic
│   ├── sfx_catalog.gd      Effects + rate limiting config
│   ├── sfx_player.gd       SFX playback with min_interval
│   ├── bgm_player.gd       Background music
│   └── vibration.gd        Haptic 3 strengths
│
├── campaign/       # M07 — Campaign runtime
│   ├── campaign_runtime.gd Playlist + bank resolution
│   ├── bank_cursor.gd      Position + transform wrapping
│   ├── nav_controller.gd   Screen navigation state machine
│   └── tutorial_guide.gd   Tutorial milestones
│
└── screens/        # M08 — UI presentation (programmatic build)
    ├── app_shell.gd         Entry point, dependency injection
    ├── title_screen.gd      Home screen (orange pill play button)
    ├── puzzle_screen.gd     Điều phối gameplay UI
    ├── puzzle_layout.gd     Dựng layout gameplay
    ├── rule_icon.gd         Minh họa luật
    ├── puzzle_board.gd      Board rendering (_draw)
    ├── result_screen.gd     Win/fail screen
    ├── options_screen.gd    Settings UI
    └── pill_toggle.gd       Toggle widget
```

## 4. Data architecture

```
game/data/
├── banks/
│   ├── bank_4x4.json        {bankVersion, size, ranks: {"1": [levels]}}
│   ├── bank_4x4.pace.json   {bankVersion, size, pacing: {"1": [{rSeq, hintCosts}]}}
│                            Bank playtest hiện chỉ có 4x4
└── campaigns/
    └── demo_30.json          {campaignVersion, id, playlist: [{label, size, rank, index}]}
```

## 5. CellKind 5-state model

| Value | Name | Player editable | Mô tả |
|-------|------|-----------------|--------|
| 0 | BLANK | Yes | Ô trống |
| 1 | MARK | Yes (toggle) | X do player đánh (xóa được) |
| 2 | CANDY | No | Candy đặt đúng (vĩnh viễn) |
| 3 | ERROR | No | Đặt sai — X đỏ vĩnh viễn |
| 4 | GIVEN | No (pre-placed) | Candy cho trước |

## 6. Runtime flow

```
Boot: app_shell → ConfigStore → CampaignRuntime.boot() → NavController → Title

Play: Title → CampaignRuntime.start_level("L01")
  → Resolve playlist → bank (size, rank, index) → BoardTransform.apply()
  → PlaySession._init() → place GIVENs
  → PuzzleBoard.configure() + TouchDecoder

Action: Touch → TouchDecoder → PlaySession.try_candy()
  → CandyRules.attempt_candy()
  → Correct: CANDY (cells stay interactive)
  → Wrong: ERROR (permanent red X, lose heart)
  → SfxPlayer.play() + Vibration.pulse()

Swipe: TouchDecoder.cell_swiped → paint/clear MARK on multiple cells

Undo: PlaySession.undo_mark() → hoàn tác thao tác X gần nhất; không hoàn tác CANDY/ERROR

Hint: BoardSolver.progressive_hint(click=N) → highlight unit/cell
  → Uses hintCosts from PaceReader

Win: CampaignRuntime.on_level_won() → ProgressManager.advance()
  → NavController → Win screen
```

## 7. Persistence

| Data | Store | Atomic |
|------|-------|--------|
| Progress | DualSlotStore("progress") | A/B slots |
| Session | DualSlotStore("session") | A/B slots |
| Settings | DualSlotStore("config") | A/B slots |

## 8. Transform system

8 variants = 4 rotations x 2 mirrors. Bank cursor wraps transform khi hết levels, nhân content x8.

## 9. Testing

```bash
# Per-module headless tests
godot --headless --script game/tests/test_<module>.gd

# Full verification
rtk python -B tools/verify.py --godot <executable>

# Clean-room check
grep -rE "(EventBus|GameState|SaveStore|SoundManager|CellAction|CellState|BankData)" game/scripts/
```

## 10. Quick reference

| Question | File |
|----------|------|
| App boot | scripts/screens/app_shell.gd |
| Level loading | scripts/content/bank_reader.gd |
| Puzzle rules | scripts/core/candy_rules.gd |
| Progressive hint | scripts/core/board_solver.gd → progressive_hint() |
| Touch input | scripts/input/touch_decoder.gd |
| Session state | scripts/input/play_session.gd |
| Save/load | scripts/state/dual_slot_store.gd |
| Board rendering | scripts/screens/puzzle_board.gd |
| Realignment plan | docs/superpowers/plans/2026-10-02-gameplay-ui-realign.md |
