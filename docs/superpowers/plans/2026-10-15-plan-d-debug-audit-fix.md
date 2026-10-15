# Rà soát và sửa công cụ debug (Plan D) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** D1 tìm và ghi lại bug của công cụ chọn màn debug và thanh Cheats trong màn chơi (kể cả lỗi hiển thị ở bề ngang điện thoại), rồi dừng chờ chủ dự án duyệt. D2 sửa từng bug đã duyệt theo TDD, mỗi bug một commit.

**Architecture:** D1 chỉ đọc và chạy thử, không sửa code. Kết quả ghi vào `scratch/verification/debug-audit-2026-10-15.md`. D2 dùng một mẫu task TDD lặp lại cho mỗi bug đã duyệt, đặt test vào `game/tests/test_debug_features.gd` hoặc `game/tests/test_debug_level_picker.gd`.

**Tech Stack:** Godot 4 / GDScript, test headless `extends SceneTree`, `tools/clean_room.py`, `tools/verify.py`.

**Spec:** [2026-10-15-streak-screens-debug-design.md](../specs/2026-10-15-streak-screens-debug-design.md) §3.5 và Q9.

## Global Constraints

- D1 không sửa code, test, asset hay tài liệu. Chỉ tạo file báo cáo trong `scratch/verification/`.
- D2 chỉ sửa bug có trong danh sách đã duyệt. Bug nào chưa duyệt thì không sửa.
- Mỗi file ≤ 300 dòng. `game/scripts/screens/app_shell.gd` đang có đúng **300 dòng**. Nếu bản sửa làm tăng số dòng, phải tách luồng nối màn debug (`_on_debug_level_selected`) sang helper mới, ví dụ `game/scripts/screens/debug_chain.gd`, là static và có test riêng.
- Không autoload, không EventBus. Dependency được inject từ app_shell.
- Câu chữ phải là câu chữ gốc. Không thêm ký tự mà font của game không có.
- Debug chỉ hoạt động khi `OS.is_debug_build()`. Không bật debug trong bản release (spec §5).
- Commit theo Conventional Commits và kèm trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Chỉ stage file thuộc bug đang sửa.

## Thứ tự và xung đột với các plan khác

- D1 chỉ đọc nên chạy song song được với Plan A/B/C.
- D2 phải merge vào `feat/v1.0.1/assist-inventory` **trước Plan C** nếu D2 sửa `debug_level_picker.gd` (hoặc `debug_endless_panel.gd`/`debug_reset_bar.gd`). Lý do: Plan C cũng chạm vào picker, và cả hai cùng sửa một file sẽ gây conflict. Nếu Plan C đã bắt đầu, báo người phụ trách Plan C rebase lên nhánh cha sau khi D2 merge.
- `app_shell.gd` cũng là điểm nóng: các plan streak cũng sửa file này. Trước khi merge D2, rebase lên nhánh cha mới nhất.

---

## Phase D1 — Rà soát (chỉ đọc)

### Task D1.0: Chuẩn bị nhánh

- [ ] **Step 1: Preflight**

```bash
rtk git branch --show-current
rtk git status --short
rtk git checkout feat/v1.0.1/assist-inventory
rtk git checkout -b fix/v1.0.1/debug-audit
```

Nếu working tree đang có thay đổi chưa commit của người khác, không checkout. Dừng lại và hỏi.

- [ ] **Step 2: Đo nền trước khi rà**

```bash
rtk godot --headless --path game --script res://tests/test_debug_features.gd
rtk godot --headless --path game --script res://tests/test_debug_level_picker.gd
rtk godot --headless --path game --script res://tests/test_screens.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
```

Ghi revision (`rtk git rev-parse --short HEAD`) và kết quả pass/fail vào đầu file báo cáo. Nếu suite đã fail sẵn, ghi thành một mục riêng. Không sửa.

### Task D1.1: Chạy game ở các bề ngang điện thoại

Viewport gốc là 1080×1920. Window override là 540×960, cấu hình tại `game/project.godot` dòng 25–28. Chạy game ở bản debug với các kích thước cửa sổ sau:

| Profile | Lệnh (ví dụ) |
|---|---|
| 9:16 chuẩn | `godot --path game --resolution 540x960` |
| 9:19.5 (điện thoại dài) | `godot --path game --resolution 450x975` |
| 9:21 (rất dài) | `godot --path game --resolution 412x961` |
| hẹp 3:4 (tablet đứng) | `godot --path game --resolution 768x1024` |

Ở mỗi profile, chụp màn hình picker (cả 3 tab) và màn chơi (Cheats đóng và mở). Lưu ảnh vào `scratch/verification/debug-audit-2026-10-15/`.

### Task D1.2: Checklist chọn màn — `debug_level_picker.gd`

Với mỗi mục: thực hiện thao tác, quan sát, rồi ghi PASS hoặc ghi bug theo định dạng ở Task D1.6.

**Tab Chiến dịch**
- [ ] Mở picker. Màn đầu tiên của playlist được chọn sẵn và thông tin màn hiển thị đúng.
- [ ] Đổi bộ lọc Size, đổi Độ khó, rồi kết hợp cả hai bộ lọc.
- [ ] Chọn bộ lọc mà kết quả **rỗng** (*suspected, verify* S1).
- [ ] Chọn một màn ở giữa danh sách, chuyển sang tab Bank, rồi quay lại tab Chiến dịch (*suspected, verify* S2).
- [ ] Bấm ▶ khi đã chọn một màn. Màn chơi phải đúng màn đã chọn, đúng transform.

**Tab Bank**
- [ ] Đổi Size qua từng bank (N=4–12). Danh sách Rank và số màn phải đúng với bank.
- [ ] Nhập Index vượt `max_value`, nhập Index = max, rồi đổi Rank sang rank có ít màn hơn (*suspected, verify* S3).
- [ ] Bank/rank không có màn nào, hoặc `get_level` trả về rỗng (*suspected, verify* S4).
- [ ] Thử từng giá trị trong 8 transform. Màn chơi phải là bàn đã biến đổi, không phải bàn gốc.
- [ ] Đổi Size rồi kiểm tra số lần `load_bank` và `select_custom_bank_level` bị gọi (*suspected, verify* S5).

**Tab Vô tận** — `debug_endless_panel.gd`
- [ ] Mở tab Vô tận. Số level phải khớp với tiến trình endless hiện tại.
- [ ] Bấm +1/+5/+10/+50 và "Về Level 1". Bấm tới giới hạn 2000.
- [ ] Ở số level không tìm được màn: nút ▶ phải bị khóa và thông tin trên picker phải khớp (*suspected, verify* S6).
- [ ] Gọi `setup()` khi đang ở tab khác, rồi kiểm tra selection của picker (*suspected, verify* S7).

**Thanh Reset** — `debug_reset_bar.gd`
- [ ] Bấm Reset Campaign, rồi mở Chơi. Game phải vào màn đầu, còn tiến trình endless giữ nguyên.
- [ ] Bấm Reset Endless. Endless phải về Level 1, còn tiến trình campaign giữ nguyên.
- [ ] Bấm Reset Cả hai, rồi đếm số lần `progress_reset` được emit và handler ở app_shell chạy (*suspected, verify* S8).
- [ ] Reset khi runtime là null. Thông báo trạng thái hiện ra như thế nào (*suspected, verify* S9)?
- [ ] Reset campaign: kiểm tra streak và assist inventory không bị ảnh hưởng ngoài ý muốn.

**Kéo panel và bố cục**
- [ ] Kéo header bằng chuột và bằng chạm (touch emulation). Panel không được ra ngoài viewport.
- [ ] Ở cả 4 profile của D1.1: panel `custom_minimum_size = (960, 1380)` có tràn hoặc bị cắt không? Có nằm giữa màn hình không (*suspected, verify* S10)?
- [ ] Ở tab Bank, các hàng `_add_row` có label dài và OptionButton không giãn. Kiểm tra control có bị chen hoặc cắt chữ không (*suspected, verify* S11).
- [ ] Kiểm tra glyph emoji trong tiêu đề và nút ("🛠", "🔄", "▶", "✕") có hiện thành ô vuông (tofu) không (*suspected, verify* S12).

### Task D1.3: Checklist nối màn debug — `app_shell.gd`

- [ ] Chọn màn playlist, thắng, rồi bấm Next. Màn tiếp phải đúng theo thứ tự playlist. Thắng màn cuối của playlist thì về Title.
- [ ] Màn được chọn từ picker có thuộc playlist khác `runtime.playlist_order()` không? Nếu khác, chuỗi Next có bị đứt không (*suspected, verify* S13)?
- [ ] Chọn Bank R1 với index = max−1. Thắng hai lần liên tiếp: lần thứ hai phải về Title.
- [ ] Chọn Endless N. Thắng thì Next phải là N+1, dùng cùng config với panel.
- [ ] Màn Win ở debug mode có hiện thông tin "màn tiếp" không? Ở debug, `_next_level_label` luôn rỗng (`app_shell.gd:193–197`) (*suspected, verify* S14).
- [ ] Thua ở debug, bấm Retry. Phải chơi lại đúng màn debug, không ghi `on_level_lost` vào runtime.
- [ ] Thoát về Home giữa màn debug, rồi bấm Chơi. Phải vào màn campaign thật, không còn dấu vết debug. `_on_puzzle_home` gọi `restart_level()` trên runtime có thể không liên quan tới bàn debug (`app_shell.gd:164–167`) (*suspected, verify* S15).
- [ ] Debug mode không được tính streak, sao hay assist reward (spec: không tính custom/debug).
- [ ] Thoát app giữa màn debug, rồi mở lại. Tiến trình campaign không bị ghi đè bằng màn debug.

### Task D1.4: Checklist thanh Cheats — `puzzle_debug_bar.gd` và vị trí trong `puzzle_layout.gd`

- [ ] Toggle "🔧 Cheats". Hàng công cụ phải mở và đóng được. Khi mở, chiều cao stack tăng: bàn cờ, dock và ad slot có bị đẩy, co lại hoặc tràn không? Thanh được thêm **sau** `AdSlot` (`puzzle_layout.gd:226–232`), nên thanh nằm dưới vùng quảng cáo (*suspected, verify* S16).
- [ ] Ở 4 profile: 4 nút `140×54` cộng khoảng cách có vừa một hàng không. Có nút nào bị cắt không.
- [ ] Bấm Hiện nghiệm rồi Ẩn nghiệm. Text nút phải đổi. Sau khi Restart hoặc Next, trạng thái hiện nghiệm có bị giữ sai không (*suspected, verify* S17)?
- [ ] Bấm Thắng: luồng Win đúng. Kiểm tra elapsed time, sao, streak (không tính ở debug, nhưng có tính khi đang chơi campaign thật). `_on_win_pressed` gán `phase` và emit trực tiếp, bỏ qua API của PlaySession (`puzzle_debug_bar.gd` ~dòng 109–112) (*suspected, verify* S18).
- [ ] Bấm Thua: `hearts = 0` nhưng không emit `state_changed`. Hàng tim trên HUD có cập nhật không, và hiệu ứng mất tim/loss burst có chạy không (*suspected, verify* S19)?
- [ ] Bấm Tự giải trên bàn đã có X hoặc nến sai: chỉ ô nghiệm được gán CANDY, các ô khác giữ nguyên. Bàn hiển thị có sạch không? Định dạng `solution` (mỗi hàng một cột) có đúng với bank N=4–12 không (*suspected, verify* S20)?
- [ ] Bấm Thắng/Thua/Tự giải hai lần liên tiếp, hoặc bấm khi phase không còn ACTIVE. Không được emit hai lần.
- [ ] Bản release (`OS.is_debug_build() == false`): thanh không được tạo. Xác minh bằng export hoặc đọc code, và ghi rõ giới hạn của cách xác minh.

### Task D1.5: Danh sách nghi vấn đã thấy khi đọc code (suspected, verify)

Đây chỉ là gợi ý, chưa phải bug đã xác nhận. Mỗi mục phải được tái hiện hoặc bác bỏ trong báo cáo.

| ID | Vị trí | Nghi vấn |
|---|---|---|
| S1 | `debug_level_picker.gd:223–235` | Khi bộ lọc cho kết quả rỗng, `_selected_level` vẫn giữ màn cũ và nút ▶ vẫn bật. Bấm ▶ sẽ chơi màn không còn hiện trong danh sách. |
| S2 | `debug_level_picker.gd:209` | `_switch_mode(0)` gọi lại `_apply_playlist_filters()`, nên lựa chọn bị reset về item đầu mỗi khi quay lại tab. |
| S3 | `debug_level_picker.gd:254–256` | Đặt `max_value` nhỏ hơn value hiện tại làm SpinBox tự clamp và emit `value_changed`, nên `_update_custom_selection` có thể chạy lồng hoặc hai lần. |
| S4 | `debug_level_picker.gd:99,107,119` | Gán `"id"` vào dict sau `get_level`, nên kể cả khi raw rỗng thì dict cũng không rỗng. `_play_btn.disabled = lvl.is_empty()` không bao giờ khóa nút, và có thể vào chơi một level hỏng. |
| S5 | `debug_level_picker.gd:67–73,240–249` | `setup` gọi `load_bank` và chọn màn nhiều lần (filters, bank sizes, endless, playlist). Có thể chậm với bank lớn. |
| S6 | `debug_endless_panel.gd:94–99` | Khi không tìm được màn, panel xóa selection nhưng không emit `level_changed`, nên picker vẫn giữ màn endless cũ và nút ▶ vẫn bật. |
| S7 | `debug_endless_panel.gd:24–31` và `debug_level_picker.gd:170–173` | Đặt `_spin_level.value` sẽ emit `value_changed`, rồi panel gọi `_update_selection` thêm lần nữa. Cả hai lần đều emit `level_changed` và ghi đè selection của picker, kể cả khi đang ở tab khác. |
| S8 | `debug_reset_bar.gd:81–85` | `reset_all` emit `progress_reset` 3 lần ("campaign", "endless", "all"). |
| S9 | `debug_reset_bar.gd:65,78` | Báo "✓ Đã reset" kể cả khi runtime là null và không có gì được reset. |
| S10 | `debug_level_picker.gd:64,185–195` | Kích thước tối thiểu cố định 960×1380. Vị trí ban đầu và clamp khi kéo chưa được kiểm tra ở màn hẹp hoặc ngang. |
| S11 | `debug_level_picker.gd:202–205` | Hàng `_add_row` không đặt `SIZE_EXPAND_FILL` cho control, nên control có thể bị chen hẹp. |
| S12 | nhiều file | Emoji (🛠 🔄 🔧 👁 ⏩) có thể không có trong font của game (ràng buộc "không ký tự ngoài font"). |
| S13 | `app_shell.gd:136–142` | Chuỗi Next chỉ hoạt động khi label thuộc `runtime.playlist_order()`. Nếu playlist truyền cho picker khác playlist của runtime, Next sẽ về Title. |
| S14 | `app_shell.gd:194–197` | Ở debug mode, Win không có thông tin màn tiếp (size, độ khó). |
| S15 | `app_shell.gd:163–167` | Về Home từ màn debug gọi `restart_level()` trên session của runtime thật, có thể reset một bàn campaign đang dở. |
| S16 | `puzzle_layout.gd:220–232` | DebugBar nằm dưới AdSlot. Khi mở Cheats, stack cao thêm khoảng 62px và có thể đẩy bàn cờ hoặc tràn màn hình. |
| S17 | `puzzle_debug_bar.gd:27–30,97–99` | `update_session` không reset trạng thái hiện nghiệm. Text nút có thể lệch so với trạng thái của board mới. |
| S18 | `puzzle_debug_bar.gd:107–111` | Thắng bằng cách gán `phase` trực tiếp, bỏ qua dừng đồng hồ, chấm sao và hook streak/assist của PlaySession. |
| S19 | `puzzle_debug_bar.gd:113–117` | Thua bằng cách gán `hearts = 0` mà không emit `state_changed`, nên HUD tim và loss burst có thể không cập nhật. |
| S20 | `puzzle_debug_bar.gd:119–131` | Tự giải không xóa X hoặc nến sai, và giả định `solution[r]` là chỉ số cột. |

> Số dòng trong `puzzle_debug_bar.gd` và `debug_*` là vị trí tương đối theo revision lúc viết plan. Khi ghi báo cáo, dùng `file:line` của revision đang rà.

### Task D1.6: Ghi báo cáo và DỪNG

- [ ] **Step 1: Ghi `scratch/verification/debug-audit-2026-10-15.md` theo định dạng:**

```markdown
# Debug audit — 2026-10-15
Revision: <short sha> (nhánh fix/v1.0.1/debug-audit)
Lệnh đã chạy: <danh sách lệnh + pass/fail>
Profiles: 540x960, 450x975, 412x961, 768x1024
Giới hạn: headless/desktop, chưa thử thiết bị thật

## Tóm tắt
| ID | Tiêu đề | Severity | Nguồn (S# hoặc mới) | Đề xuất |
|----|---------|----------|---------------------|---------|

## B01 — <tiêu đề ngắn>
- Nguồn: S4 (đã xác nhận) | mới
- Tái hiện: 1. … 2. … 3. …
- Kỳ vọng: …
- Thực tế: … (ảnh: debug-audit-2026-10-15/B01.png)
- Vị trí: game/scripts/screens/<file>.gd:<dòng>
- Severity: blocker | major | minor | cosmetic
- Test đề xuất: test_debug_level_picker.gd | test_debug_features.gd — <tên test>

## Nghi vấn bị bác bỏ
- S2: không tái hiện được vì …
```

Thang severity:
- **blocker**: crash, mất tiến trình thật, hoặc debug ghi vào dữ liệu người chơi.
- **major**: chọn hoặc chơi sai màn, chuỗi Next sai, nút không hoạt động.
- **minor**: trạng thái UI lệch hoặc emit thừa.
- **cosmetic**: bố cục, chữ, glyph.

- [ ] **Step 2: Không commit code.** Không cần commit file báo cáo vì `scratch/` là log xác minh. Nếu cần commit, chỉ stage đúng file báo cáo.
- [ ] **Step 3: DỪNG.** Gửi chủ dự án bảng tóm tắt và đề xuất: sửa (D2), hoãn, hoặc bỏ. Chờ chủ dự án duyệt danh sách ID trước khi bắt đầu D2.

---

## Phase D2 — Sửa bug đã duyệt

### Task D2.0: Chuẩn bị nhánh

- [ ] **Step 1:** Chỉ bắt đầu khi đã có danh sách ID được chủ dự án duyệt. Chép danh sách đó vào đầu phần ghi chú của báo cáo audit.

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git pull --ff-only   # nếu nhánh có remote
rtk git checkout -b fix/v1.0.1/debug-fixes
```

- [ ] **Step 2:** Sắp thứ tự sửa: blocker → major → minor → cosmetic. Gom các bug cùng file lại với nhau để giảm conflict với Plan C.

### Task D2.N: Mẫu cho mỗi bug đã duyệt (lặp lại cho B01, B02, …)

**Files:**
- Sửa: `game/scripts/screens/<file>.gd` (theo `file:line` trong báo cáo)
- Test: `game/tests/test_debug_level_picker.gd` cho picker, endless panel và reset bar; `game/tests/test_debug_features.gd` cho Cheats, layout và chuỗi Next trong app_shell.

- [ ] **Step 1: Viết test fail.** Test phải tái hiện đúng các bước trong báo cáo. Theo quy ước suite hiện có (`extends SceneTree`, node trong cây hoặc được free), ví dụ cho S4:

```gdscript
func _test_play_disabled_when_level_missing() -> void:
	var picker = DebugLevelPicker.new(); root.add_child(picker)
	picker.setup(_bank_stub_returning_empty(), [])
	picker.select_custom_bank_level(4, 1, 99999, 0)
	_check(picker._play_btn.disabled, "play disabled when bank has no such level")
	picker.queue_free()
```

- [ ] **Step 2: Chạy và xác nhận test FAIL vì đúng lý do của bug.**

```bash
rtk godot --headless --path game --script res://tests/test_debug_level_picker.gd
```

- [ ] **Step 3: Sửa tối thiểu.** Giữ file ≤ 300 dòng. Nếu phải sửa `app_shell.gd` (đang 300 dòng), tách logic sang helper trước rồi mới sửa. Không gộp thêm cải tiến chưa được duyệt.
- [ ] **Step 4: Chạy lại để test PASS, rồi chạy cả hai suite debug cùng `test_screens.gd`.**
- [ ] **Step 5: Commit riêng cho bug này.**

```bash
rtk git add game/scripts/screens/<file>.gd game/tests/<test_file>.gd
rtk git commit -m "fix(debug): <mô tả ngắn> (B0x)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Bug cosmetic về bố cục không test headless được (ví dụ S10/S11/S16 ở từng profile): viết test cho phần đo được (`size`, `custom_minimum_size`, thứ tự node, `get_rect()` nằm trong viewport khi đặt `root.size`). Phần còn lại ghi "cần QA giao diện" trong STATUS.

### Task D2.Z: Gate, STATUS, merge

- [ ] **Step 1: Chạy suite liên quan**

```bash
rtk godot --headless --path game --script res://tests/test_debug_features.gd
rtk godot --headless --path game --script res://tests/test_debug_level_picker.gd
rtk godot --headless --path game --script res://tests/test_screens.gd
rtk godot --headless --path game --script res://tests/test_integration.gd
```

- [ ] **Step 2: Chạy full gate**

```bash
rtk python -B tools/clean_room.py
rtk python -B tools/verify.py --godot <godot-executable>
```

Ghi revision, lệnh và kết quả vào `scratch/verification/`.

- [ ] **Step 3: Cập nhật `docs/STATUS.md`.** Ghi các bug đã sửa (ID và commit), các bug hoãn hoặc bỏ kèm lý do, và QA giao diện/thiết bị cho phần layout vẫn **còn mở**. Commit: `docs(status): record debug audit fixes`.
- [ ] **Step 4: Merge về nhánh cha** (chỉ trong phạm vi quyền được giao)

```bash
rtk git checkout feat/v1.0.1/assist-inventory
rtk git merge --no-ff fix/v1.0.1/debug-fixes
```

Nếu Plan C đang mở và chạm vào `debug_level_picker.gd`, báo người phụ trách Plan C rebase lên nhánh cha mới.

## Review Focus

1. Debug không được ghi vào tiến trình thật, streak hay assist reward (S15, S18).
2. Nút ▶ không được vào chơi màn rỗng hoặc màn cũ (S1, S4, S6).
3. Chuỗi Next ở debug phải đúng cho playlist, bank và endless (S13).
4. Bố cục picker và Cheats ở bề ngang điện thoại (S10, S11, S16). Kiểm chứng headless không thay cho QA thiết bị.
5. `app_shell.gd` vẫn ≤ 300 dòng sau khi sửa.
