# Module 9: Integration & Verification

> **Phụ thuộc:** Tất cả module 1-8
> **Mục tiêu:** Đảm bảo hệ thống hoạt động end-to-end

## Tổng quan

Module cuối: kết nối tất cả modules, chạy full test suite, kiểm tra clean-room compliance, và chuẩn bị cho playtest.

---

## Phase 1: Wiring — Kết nối modules

### 1.1 App Shell wiring

Kiểm tra `app_shell.gd` khởi tạo đúng thứ tự:
1. `ConfigStore` → load settings
2. `CampaignRuntime` → boot (load campaign + progress)
3. `SfxPlayer` + `BgmPlayer` → add as children
4. Apply settings → mute/unmute audio, enable/disable haptic
5. `NavController` → show title screen
6. Connect signals: nav changes, config changes, runtime events

### 1.2 Screen flow wiring

Kiểm tra transitions:
- Title → Play → Puzzle screen (start level)
- Puzzle → Win → Result screen (won)
- Puzzle → Lose → Result screen (lost)
- Result → Next → Puzzle screen (next level)
- Result → Retry → Puzzle screen (same level)
- Result → Home → Title screen
- Any → Options → Settings → Back
- Last level win → Replay from L01 (RST-003)

### 1.3 Save flow wiring

Kiểm tra persistence:
- Session auto-save after each action
- Progress save on level win
- Save failure → dialog → retry
- Pending session recovery on boot
- Settings persist across restart

---

## Phase 2: Clean-room compliance

### 2.1 Không import từ extracted_reusable

```bash
grep -r "extracted_reusable" game/scripts/ game/tests/
```
Expected: Không có kết quả

### 2.2 Không tên/hằng sao chép

Kiểm tra KHÔNG có các identifier từ reference:
```bash
grep -rE "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku|SAVE_PASSWORD|_xor_inplace|Kind\.MARK_X|Kind\.BOARD_ENTER|Kind\.LEVEL_WIN)" game/scripts/
```
Expected: Không có kết quả

### 2.3 Không có asset mới không được phép

Kiểm tra không tạo file .ogg, .png, .svg mới ngoài danh sách đã có.

---

## Phase 3: Test Suite

### 3.1 Unit tests (headless)

Chạy từng test file:
```bash
godot --headless --script game/tests/test_candy_rules.gd
godot --headless --script game/tests/test_board_solver.gd
godot --headless --script game/tests/test_dual_slot_store.gd
godot --headless --script game/tests/test_progress_manager.gd
godot --headless --script game/tests/test_bank_reader.gd
godot --headless --script game/tests/test_touch_decoder.gd
godot --headless --script game/tests/test_play_session.gd
godot --headless --script game/tests/test_feedback.gd
godot --headless --script game/tests/test_campaign_runtime.gd
```

### 3.2 Full verification

```bash
python -B tools/verify.py --godot <executable>
```

### 3.3 Integration tests

Danh sách hành trình cần test thủ công (hoặc qua bootstrap scene):

| # | Hành trình | Expected |
|---|-----------|----------|
| 1 | Boot lần đầu → Title → Play → L01 board | Board hiện đúng 4x4 |
| 2 | Tap ô → mark X | X hiện, SFX phát |
| 3 | Tap ô đã mark → bỏ mark | Ô trống lại |
| 4 | Double-tap ô đúng → candy | Kẹo hiện, SFX + haptic |
| 5 | Double-tap ô sai → wrong | X đỏ, mất tim, SFX + haptic |
| 6 | Hint button → highlight | Ô gợi ý được chỉ ra |
| 7 | Undo → bỏ action cuối | Trạng thái quay lại |
| 8 | Thắng level → Win screen | Điểm, nút tiếp |
| 9 | Thua (hết tim) → Fail screen | Nút thử lại |
| 10 | Settings → toggle audio | SFX tắt/bật |
| 11 | Kill app giữa game → reopen → resume | Session phục hồi |
| 12 | Corrupt save → boot → error dialog | Thông báo lỗi save |
| 13 | Thắng level cuối → completion screen | Hiện hoàn thành nội dung hiện có (replay ẩn cho playtest) |

---

## Phase 4: Dọn dẹp

### 4.1 Xóa code cũ (sau khi rebuild hoàn thành)

Các file hiện tại sẽ được thay thế bởi rebuild. Giữ lại tạm trong quá trình build, xóa khi module mới đã pass test:

| File cũ | Thay bởi |
|---------|----------|
| `scripts/puzzle_core.gd` | `scripts/core/candy_rules.gd` |
| `scripts/interaction_session.gd` | `scripts/input/play_session.gd` |
| `scripts/gesture_engine.gd` | `scripts/input/touch_decoder.gd` |
| `scripts/board_view.gd` | `scripts/screens/puzzle_board.gd` |
| `scripts/board_screen.gd` | `scripts/screens/puzzle_screen.gd` |
| `scripts/home_screen.gd` | `scripts/screens/title_screen.gd` |
| `scripts/bootstrap.gd` | `scripts/screens/app_shell.gd` |
| `scripts/ui_flow_controller.gd` | `scripts/campaign/nav_controller.gd` |
| `scripts/mvp_runtime.gd` | `scripts/campaign/campaign_runtime.gd` |
| `scripts/save_repository.gd` | `scripts/state/*` |
| `scripts/settings.gd` | `scripts/state/config_store.gd` |
| `scripts/level_loader.gd` | `scripts/content/bank_reader.gd` |
| `scripts/hint_engine.gd` | `scripts/core/board_solver.gd` |
| `scripts/tutorial_controller.gd` | `scripts/campaign/tutorial_guide.gd` |
| `scripts/ui_theme.gd` | `scripts/theme/palette.gd` |
| `scripts/ui_tokens.gd` | `scripts/theme/layout_tokens.gd` |
| `scripts/ui/pill_switch.gd` | `scripts/screens/pill_toggle.gd` |
| `scripts/ui/settings_screen.gd` | `scripts/screens/options_screen.gd` |
| `scripts/ui/settings_ui_config.gd` | (merged into options_screen) |
| `scripts/legacy_session_migration.gd` | (merged into session_store) |

**Giữ nguyên** (không thay):
- `scripts/pastel_backdrop.gd` — decorative, dùng lại
- `scripts/spike_board_6x6.gd` — spike, không ảnh hưởng
- `scripts/mobile_rendering_spike.gd` — spike, không ảnh hưởng

### 4.2 Cập nhật scenes

- `bootstrap.tscn` → `main.tscn` (script: app_shell.gd)
- `home.tscn` → `title.tscn` (script: title_screen.gd)
- `board.tscn` → `puzzle.tscn` (script: puzzle_screen.gd)
- `result_win.tscn` / `result_fail.tscn` → `win.tscn` / `fail.tscn`
- `settings.tscn` → `options.tscn`

### 4.3 Project settings

- Main scene: `res://scenes/main.tscn`
- Không autoloads (composition root pattern)

---

## Phase 5: Documentation

- [ ] Cập nhật `docs/ARCHITECTURE.md` với cấu trúc module mới
- [ ] Cập nhật `docs/STATUS.md` với tiến độ rebuild
- [ ] Ghi quyết định rebuild vào `docs/DECISIONS.md`

---

## Checklist thực hiện

- [ ] Kết nối app_shell với tất cả screens
- [ ] Test screen transitions
- [ ] Test save/load flows
- [ ] Chạy clean-room compliance checks
- [ ] Chạy full unit test suite
- [ ] Chạy verify.py
- [ ] Test thủ công 13 hành trình (nếu có device)
- [ ] Xóa code cũ
- [ ] Cập nhật scenes và project settings
- [ ] Cập nhật documentation
- [ ] Commit: `feat: complete CanDoKu rebuild integration`
