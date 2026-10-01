# CanDoKu — Kiến trúc phần mềm

> Kiến trúc rebuild cho bản playtest 30 level. Cập nhật: 2026-10-02.

## 1. Phạm vi và nguồn sự thật

- Luật/domain: [GDD 02](../GDD/02-luat-choi-va-trang-thai.md)
- Rebuild plan: [Master plan](superpowers/plans/2026-10-02-rebuild-master.md)
- Quyết định: [DECISIONS](DECISIONS.md)
- Trạng thái: [STATUS](STATUS.md)

## 2. Nguyên tắc kiến trúc

1. **Composition root, không autoloads** — `app_shell.gd` khởi tạo và inject dependencies.
2. **Signals thay EventBus** — Godot signals native, không global bus.
3. **Static cho pure logic** — cell_model, candy_rules, board_solver, board_transform stateless.
4. **Module ≤ 300 dòng** — một file, một trách nhiệm.
5. **Offline-first** — không backend, network, account.
6. **Bank-based content** — levels trong rank-based banks, transform x8, pace sidecar cho hints.
7. **Auto-mark system** — candy dung tu dong lock cells lien quan.
8. **Testable** — logic tach UI, headless test cho moi module.

## 3. Module map

```
game/scripts/
├── core/           # M01 — Domain logic (stateless)
│   ├── cell_model.gd       CellKind 6-state enum + helpers
│   ├── candy_rules.gd      Luat puzzle, auto-mark computation
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
│   ├── action_recorder.gd  Command pattern grouped undo
│   └── play_session.gd     Session state machine + auto-mark
│
├── theme/          # M05 — Visual tokens
│   ├── palette.gd          Colors for all 6 CellKind states
│   └── layout_tokens.gd    Spacing, sizing, animation timing
│
├── feedback/       # M06 — Audio & haptic
│   ├── sfx_catalog.gd      11 effects + rate limiting config
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
└── screens/        # M08 — UI presentation
    ├── app_shell.gd         Entry point, dependency injection
    ├── title_screen.gd      Home screen
    ├── puzzle_screen.gd     Gameplay + progressive hint flow
    ├── puzzle_board.gd      Board rendering (GIVEN/LOCKED)
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
│   └── ...                   (5x5, 6x6)
└── campaigns/
    └── demo_30.json          {campaignVersion, id, playlist: [{label, size, rank, index}]}
```

## 5. CellKind 6-state model

| Value | Name | Player editable |
|-------|------|-----------------|
| 0 | BLANK | Yes |
| 1 | MARK | Yes (toggle) |
| 2 | CANDY | No |
| 3 | WRONG | No |
| 4 | GIVEN | No (pre-placed) |
| 5 | LOCKED | No (auto-marked) |

## 6. Runtime flow

```
Boot: app_shell → ConfigStore → CampaignRuntime.boot() → NavController → Title

Play: Title → CampaignRuntime.start_level("L01")
  → Resolve playlist → bank (size, rank, index) → BoardTransform.apply()
  → PlaySession._init() → place GIVENs → compute auto-marks → set LOCKED
  → PuzzleBoard.configure() + TouchDecoder

Action: Touch → TouchDecoder → PlaySession.try_candy()
  → CandyRules.attempt_candy() → if correct: CANDY + auto_marks → LOCKED
  → ActionRecorder.push_group([candy + locks])
  → SfxPlayer.play() + Vibration.pulse()

Undo: ActionRecorder.pop_group() → reverse all (candy + locks)

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

8 variants = 4 rotations x 2 mirrors. Bank cursor wraps transform khi het levels, nhan content x8.

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
| Auto-mark | scripts/core/candy_rules.gd → compute_auto_marks() |
| Progressive hint | scripts/core/board_solver.gd → progressive_hint() |
| Touch input | scripts/input/touch_decoder.gd |
| Grouped undo | scripts/input/action_recorder.gd |
| Session state | scripts/input/play_session.gd |
| Save/load | scripts/state/dual_slot_store.gd |
| Board rendering | scripts/screens/puzzle_board.gd |
| Rebuild plan | docs/superpowers/plans/2026-10-02-rebuild-master.md |
