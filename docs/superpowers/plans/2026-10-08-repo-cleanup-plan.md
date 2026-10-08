# Kế hoạch Dọn dẹp & Chuẩn hóa Repository (Repo Cleanup Plan)

> **Mục tiêu:** Xử lý triệt để các thay đổi dở dang, đưa toàn bộ test suite về trạng thái XANH (Clean Gate PASS), dọn dẹp file rác/artifact dư thừa, dọn branch/stash cũ, và đồng bộ hóa tài liệu dự án.  
> **Áp dụng cho:** Nhánh `dev`  
> **Thời điểm lập kế hoạch:** 2026-10-08  

---

## 1. Bối cảnh & Phân loại Hiện trạng

Sau các đợt phát triển dồn dập (Endless Mode, Chiến dịch 100 màn, Rebuild Procedural SFX, Studio Splash Screen), repository hiện đang ở trạng thái:
- **Đã hoàn thành:** Rebuild M01–M10, Endless Levels (Phase 1–4), Bank 4–12 (36.573 levels), SFX tự sinh & Tuner, Native Splash Screen.
- **Dở dang gây lỗi:** Working tree trên `dev` chứa các sửa đổi chưa commit làm **FAIL 4 test suites**:
  1. `test_config_store.gd` (do xóa `undo_x` vi phạm `RST-017`).
  2. `test_board_entry.gd` (do xóa hàm `_on_options_back` trong `app_shell.gd`).
  3. `test_game_features.gd` (do `app_shell.gd` gọi phát BGM khi node chưa vào cây).
  4. `test_export_presets.py` (do `export_presets.cfg` bị ghi đè preset mẫu probe).
- **Rác & Thừa:** Thư mục `rive-assets/` (dự án Rive studio logo bị hủy bỏ), APK build cục bộ (~85MB), log/ảnh trong `scratch/`, các git branch và stash cũ.
- **Tài liệu lệch pha:** `docs/REMAINING_TASKS.md` và `docs/STATUS.md` chưa ghi nhận việc hoàn thành các tài nguyên asset đồ họa.

---

## 2. Kế hoạch Thực hiện Chi tiết (4 Giai đoạn)

### Giai đoạn 1: Khắc phục Working Tree & Khôi phục Clean Gate (P0)

*Mục tiêu: Đưa bộ test về trạng thái 100% PASS trước khi thực hiện bất kỳ thao tác xóa/dọn dẹp nào.*

- [ ] **Nhiệm vụ 1.1: Khôi phục tùy chọn `undo_x` theo đúng quyết định điều hành `RST-017`**
  - **File:** `game/scripts/state/config_store.gd`, `game/tests/test_config_store.gd`, `game/scripts/screens/options_screen.gd`.
  - **Hành động:** Khôi phục `undo_x` vào `DEFAULTS` và `EDITABLE_KEYS` trong `config_store.gd`; khôi phục assert `undo_x` trong `test_config_store.gd`.
  - **Kiểm chứng:** Chạy `godot --headless --path game --script res://tests/test_config_store.gd` -> PASS.

- [ ] **Nhiệm vụ 1.2: Sửa lỗi BGM và tương thích navigation trong `app_shell.gd`**
  - **File:** `game/scripts/screens/app_shell.gd`.
  - **Hành động:**
    - Trong `_start_bgm()`: Kiểm tra `is_inside_tree()` trước khi gọi phát nhạc để tránh lỗi Godot engine khi test headless / test khởi tạo.
    - Đảm bảo hàm `_on_options_back()` vẫn tồn tại hoặc backward-compatible để không làm vỡ `test_board_entry.gd`.
  - **Kiểm chứng:** Chạy `godot --headless --path game --script res://tests/test_board_entry.gd` và `test_game_features.gd` -> PASS.

- [ ] **Nhiệm vụ 1.3: Chuẩn hóa `export_presets.cfg`**
  - **File:** `game/export_presets.cfg`.
  - **Hành động:** Giữ nguyên các preset probe mẫu (`Android M0 Debug` tại `preset.0` và `iOS M0 Debug` tại `preset.1`) mà `test_export_presets.py` yêu cầu; nếu cần thêm `Android Release`, đưa vào section tiếp theo (`preset.2`).
  - **Kiểm chứng:** Chạy `python -B -m unittest game/tests/test_export_presets.py` -> PASS.

- [ ] **Nhiệm vụ 1.4: Tách riêng tính năng Help Screen Overlay sang branch riêng**
  - **File:** `game/scripts/screens/help_screen.gd`, `title_screen.gd`.
  - **Hành động:** Nếu tính năng Help Screen overlay chưa hoàn tất bài test đầy đủ, chuyển sang nhánh mới `feat/help-screen-overlay` để phát triển TDD riêng biệt, trả `dev` về trạng thái ổn định với `help_dialog`.

- [ ] **Nhiệm vụ 1.5: Xác nhận Full Gate**
  - **Lệnh:** `python -B tools/verify.py --godot <Godot console>`
  - **Kỳ vọng:** 100% test Godot và Python PASS, Clean-room 0 match.

---

### Giai đoạn 2: Dọn dẹp File Rác & Artifacts Cục bộ (P1)

*Mục tiêu: Loại bỏ các file đã bỏ rơi, giải phóng dung lượng đĩa.*

- [ ] **Nhiệm vụ 2.1: Xóa thư mục thử nghiệm Rive (`rive-assets/`)**
  - Thư mục `rive-assets/logo-studio/` chứa mã RML và `.riv` thử nghiệm cho Splash screen. Do game đã chốt dùng Godot native `splash_screen.gd`, xóa toàn bộ thư mục `rive-assets/`.
  - Xóa vĩnh viễn 2 file tài liệu Rive đã bị unstage:
    - `docs/superpowers/plans/2026-10-07-studio-splash-animation.md`
    - `docs/superpowers/specs/2026-10-07-studio-splash-animation-design.md`

- [ ] **Nhiệm vụ 2.2: Xóa các file Build APK cục bộ**
  - Xóa `build/android/candoku-debug.apk` (~43MB) và `.idsig`.
  - Xóa `game/build/android/candoku-release.apk` (~41MB) và `.idsig`.
  - Giải phóng ~85MB dung lượng đĩa.

- [ ] **Nhiệm vụ 2.3: Dọn dẹp thư mục `scratch/`**
  - Xóa ảnh tạm `scratch/image.png`.
  - Xóa thư mục xuất bản tạm `scratch/exports/`.
  - Giữ lại thư mục `scratch/verification/` nhưng dọn dẹp các log cũ quá hạn, chỉ giữ lại log của các lần xác nhận gần nhất.

- [ ] **Nhiệm vụ 2.4: Phân loại tài liệu tham khảo ngoại vi**
  - Kiểm tra `docs/superpowers/specs/2026-10-07-meowdoku-engines-techniques-and-architecture-compendium.md`: Nếu muốn lưu làm tài liệu tham khảo kiến trúc thì commit vào repo; nếu là tài liệu tạm thời thì di chuyển sang `scratch/` hoặc xóa bỏ.

- [ ] **Nhiệm vụ 2.5: Đánh giá thư mục `game/assets/archive/`**
  - Đánh giá 30 file icon/SVG cũ từ thời MVP trong `game/assets/archive/`. Nếu không còn mục đích tham khảo lịch sử, tiến hành `git rm -r game/assets/archive/`.

---

### Giai đoạn 3: Dọn dẹp Git Branches & Stashes Cũ (P1)

*Mục tiêu: Làm sạch danh sách nhánh local và stash để tránh nhầm lẫn.*

- [ ] **Nhiệm vụ 3.1: Xóa các branch cục bộ đã hoàn thành hoặc thừa**
  - `feat/core-game-features`: Xóa (`git branch -d feat/core-game-features` hoặc `-D` sau khi kiểm tra các commit đã nằm trong PR #22).
  - `feat/studio-splash-animation`: Xóa (`git branch -D feat/studio-splash-animation`).
  - `fix/audio-bgm-settings-timing`: Xóa (`git branch -d fix/audio-bgm-settings-timing`).

- [ ] **Nhiệm vụ 3.2: Dọn dẹp Git Stash**
  - Xóa `stash@{0}` và `stash@{1}` bằng lệnh `git stash drop`.

---

### Giai đoạn 4: Đồng bộ Hóa & Cập nhật Tài liệu Dự án (P2)

*Mục tiêu: Đưa các tài liệu tiến độ về đúng thực tế.*

- [ ] **Nhiệm vụ 4.1: Cập nhật `docs/STATUS.md`**
  - Bổ sung tình trạng hoàn thành của Native Splash Screen, Bộ Candy Assets chính thức, Bộ UI nút Settings.
  - Ghi nhận trạng thái Pass của Full Gate sau khi dọn dẹp.

- [ ] **Nhiệm vụ 4.2: Cập nhật `docs/REMAINING_TASKS.md`**
  - Gạch bỏ các mục đã xong trong Track D:
    - [x] Logo & Splash Screen.
    - [x] Bộ Sprite Kẹo PNG.
    - [x] Bộ nút UI Settings.
  - Cập nhật mục tiêu trọng tâm còn lại: Kiểm thử thiết bị di động thật (Track E), Phông chữ tiếng Việt có dấu đầy đủ, Cấu hình Release Keystore (Track F).

- [ ] **Nhiệm vụ 4.3: Cập nhật các tài liệu tổng quan cũ**
  - Đồng bộ `docs/ROADMAP.md` và `docs/GAME_OVERVIEW.md` với phạm vi hiện tại (N=4–12, 100 level campaign, Endless mode).

---

## 3. Trình tự Đề xuất Tiếp theo

1. **Bước 1:** Thực hiện Giai đoạn 1 (Sửa test & Working tree) để repo đạt trạng thái **Full Green (Verify PASS)**.
2. **Bước 2:** Thực hiện Giai đoạn 2 (Xóa `rive-assets`, file build APK, dọn `scratch`).
3. **Bước 3:** Thực hiện Giai đoạn 3 (Xóa branches cũ, stashes cũ).
4. **Bước 4:** Thực hiện Giai đoạn 4 (Cập nhật STATUS và REMAINING_TASKS).
