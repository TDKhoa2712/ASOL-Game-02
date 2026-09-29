# R1 — Kế hoạch bản chơi liền mạch

Trạng thái: chủ dự án duyệt triển khai ngày 2026-09-25 theo RST-002. Khảo sát tại `1600898`; kiểm lại revision khi bắt đầu. Một agent chính thực hiện, không tự mở thêm worktree/agent. Phạm vi bản đầu 24 level; Endless để sau.

**Mục tiêu:** một build chơi xuyên bốn level, chuyển màn hình, tutorial và save/resume nhất quán.

**Kiến trúc:** giữ các module Godot, đưa tiến trình về runtime; flow chỉ điều hướng. Cô lập save test trước khi kiểm tích hợp.

**Công nghệ:** Godot/GDScript và Python validator/test hiện có.

**Đặc tả:** [khảo sát kiến trúc lịch sử](../HISTORY.md), [luật](../../GDD/02-luat-choi-va-trang-thai.md), [UX](../../GDD/03-luong-man-hinh-va-ux.md), [dữ liệu](../../GDD/05-kien-truc-va-du-lieu.md), [QA](../../GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md).

Đây là tiêu chí nghiệm thu, không phải bảng tiến độ. Đối chiếu STATUS và evidence trước khi làm; ô chưa đánh dấu dưới đây không có nghĩa phải triển khai lại code đã có. Thực hiện theo AGENTS, tái hiện vấn đề còn tồn tại và thêm regression trước sửa.

## Ràng buộc

- Giữ luật ba tim, điểm và giới hạn Hint/Undo theo GDD; cửa sổ double tap 280 ms, ngưỡng drag 12 logical px. Thay đổi cần quyết định riêng.
- Giữ hợp đồng level/save hiện hành; không thêm generator, economy, meta hoặc sản xuất art hàng loạt.
- Bốn level 4/5/6/6 hiện tại là corpus tích hợp. Chuẩn hóa bốn level mở đầu theo GDD trước thử người mới R2.
- Headless không thay thế quan sát layout/input và QA Android thật. R1 không chứng nhận phát hành iOS hoặc đủ 24 level.

## Thứ tự và tiêu chí kiểm chứng

### A. Có bộ kiểm tra an toàn, phản ánh bản chơi thật

File trọng tâm: `game/scripts/bootstrap.gd`, `game/tests/run_mvp_runtime_tests.gd`, `game/tests/run_ui_flow_tests.gd`, `game/tests/test_runtime_smoke.py`.

- [ ] Cho phép test cấp repository/profile riêng trước khởi tạo runtime; xác nhận test không đọc, ghi hay xóa profile người chơi.
- [ ] Chuyển integration sang scene tree thực; không gọi `_ready()` thủ công và không sửa progress/flow giữa hành trình để vượt lỗi điều hướng.
- [ ] Kiểm marker smoke cũ so với entry scene; thay assertion bằng hành vi tương ứng, giữ kiểm lỗi khởi động.
- [ ] Chạy baseline trên profile cô lập, lưu revision, lệnh, exit code và lỗi. Không chạy suite có `clear_saved_state()` mặc định trước khi cô lập.

Đạt khi chạy lặp lại không thay profile thật, test quan sát được lifecycle thực và lỗi baseline được phân loại. Không cần tạo một pipeline quản trị thay thế.

### B. Một nguồn tiến trình, đường đi Home/Result đúng

File trọng tâm: `game/scripts/mvp_runtime.gd`, `game/scripts/ui_flow_controller.gd`, `game/scripts/bootstrap.gd`; test runtime/flow ở bước A.

- [ ] Tái hiện và viết regression: thắng L01 → Home → Play phải vào L02; Next cũng vào L02, không tăng hai lần.
- [ ] Runtime quyết định level/session/result; flow không tự tăng chỉ số campaign độc lập.
- [ ] Thua L02 → Home → mở lại phải giữ trạng thái thua; Retry mới bắt đầu lượt mới theo luật.
- [ ] Kết thúc level cuối → Home → mở lại phải hiện hết nội dung, không reset về L01; campaign có thêm level thì chọn level chưa hoàn thành đúng hợp đồng.
- [ ] Result hiển thị điểm/kết quả thật; chặn tín hiệu terminal cũ và double-click gây chuyển màn hình hai lần.
- [ ] Help/Settings quay lại đúng nơi mà không khởi tạo lại lượt chơi.

Đạt khi các hành trình trên qua nút thật đều đúng, không cần chỉnh trạng thái nội bộ giữa đường.

### C. Save/resume bảo toàn trạng thái kể cả khi thất bại

File trọng tâm: `game/scripts/save_repository.gd`, `game/scripts/mvp_runtime.gd`, `game/scripts/board_screen.gd`, `game/scripts/board_view.gd`; test save/runtime/input.

- [ ] Test lỗi ghi file, crash giữa lưu progress và xóa session, primary hỏng/backup tốt, session hỏng và progress hợp lệ.
- [ ] Phân biệt chưa có save với save không hợp lệ; không ghi đè bản còn phục hồi được như một lượt mới.
- [ ] Không báo thắng bền vững/xóa session nếu lưu tiến trình thất bại; có thông báo và đường thử lại, không nhân đôi kết quả.
- [ ] Lưu/khôi phục trạng thái terminal, tim, X/X đỏ/Candy, Hint đã dùng, điểm và thời gian theo hợp đồng; không cấp lại Hint khi resume.
- [ ] Background khi tap đã thả nhưng còn chờ phân loại: commit theo luật. Khi còn giữ drag: hủy phần chưa commit. Kiểm cả Home và focus-out.

Đạt khi khởi động lại từ các điểm gián đoạn không mất tiến trình hợp lệ hoặc tự cấp lượt mới ngoài luật.

### D. Tutorial, Hint và thao tác nối với gameplay thật

File trọng tâm: `game/scripts/tutorial_controller.gd`, `game/scripts/mvp_runtime.gd`, `game/scripts/board_screen.gd`, `game/scripts/bootstrap.gd`; test tutorial/hint/interaction và hành trình UI.

- [ ] Milestone nhận hành vi đã commit trên board: đặt X, xóa X, kéo ít nhất hai ô, Candy đúng target, xem luật, dùng Hint hợp lệ/đóng hướng dẫn theo GDD.
- [ ] Tải đúng level trước chọn target; kiểm hành động sai thứ tự và resume giữa tutorial, không gọi API milestone trực tiếp thay thao tác người chơi trong integration.
- [ ] Miễn phạt chỉ đúng ô/tình huống hướng dẫn; thao tác sai ngoài phạm vi vẫn mất tim theo luật.
- [ ] Hint không có gợi ý thì không tiêu lượt; Hint thành công hiển thị căn cứ và giữ trạng thái qua resume.
- [ ] Undo không vượt TryCandy; drag là một nhóm undo; Restart theo đúng hợp đồng. Help không còn placeholder hoặc mô tả sai luật.

Đạt khi lượt mới đi qua tutorial bằng input thật và các luật trên có regression tương ứng.

### E. Bố cục và thao tác dùng được trên cùng build

File trọng tâm: `game/scripts/board_screen.gd`, `game/scripts/bootstrap.gd`, các scene liên quan trong `game/scenes/`; test UI shell/board smoke.

- [ ] Tái hiện lỗi clipping trong hồ sơ A12; đo toolbar, board, result và safe area trên kích thước 4/5/6.
- [ ] Kiểm bốn luật thường trực, tiến độ vùng, Help/Settings, target tối thiểu 44 logical px, chữ lớn +30%, grayscale và reduced motion theo UX.
- [ ] Settings có state và tác dụng tương ứng đã triển khai; phần audio/haptic cần asset/output ở R3 được ghi chưa đạt, không chứng nhận chỉ vì có toggle.
- [ ] Chạy toàn hành trình từ entry scene thật trên desktop và Android offline, ghi revision/build hash, thiết bị/OS, thao tác và ảnh/video cần thiết.

Thiếu thiết bị vẫn tiếp tục công việc độc lập, nhưng không đánh dấu R1 đạt đầy đủ.

## Bộ kiểm tra cuối chặng

Lệnh hiện hành: `rtk python -B tools/verify.py --godot <executable>`. Runner tìm tất cả `run_*.gd`, gồm các regression R1 bổ sung. Danh sách gốc dưới đây chỉ để tham khảo phạm vi; không dùng thay danh sách tự tìm.

Sau bước A, chạy toàn bộ test áp dụng, không chỉ suite vừa sửa:

- Python unit tests tại `GDD/tools` và `game/tests`; đặt Godot executable theo cơ chế `GODOT_BIN` của suite.
- Level validator hiện có cho corpus/GDD tương ứng.
- Godot suites: `run_puzzle_core_tests.gd`, `run_level_loader_tests.gd`, `run_save_repository_tests.gd`, `run_hint_engine_tests.gd`, `run_tutorial_tests.gd`, `run_interaction_contract.gd`, `run_ui_shell_tests.gd`, `run_ui_flow_tests.gd`, `run_mvp_runtime_tests.gd`, `run_board_scene_smoke.gd`, `run_mobile_rendering_spike_smoke.gd` trong `game/tests/`.

Mẫu lệnh suite (thay executable bằng đường dẫn Godot đã xác nhận):

```text
rtk <godot-executable> --headless --path game --script res://tests/run_ui_flow_tests.gd
```

Xác nhận cú pháp runner/validator từ repo tại thời điểm triển khai. Ghi lệnh thực đã chạy, exit code, log và giới hạn; không lấy evidence cũ làm kết quả mới. Suite lỗi phải được sửa hoặc ghi blocker, không âm thầm loại khỏi danh sách.

## Bàn giao

- [ ] Một build/revision được nhận diện, kèm kết quả từng hành trình A–E và bộ test áp dụng.
- [ ] Không còn lỗi chặn chuyển level, sai luật, mất tiến trình hoặc chặn thao tác thuộc R1.
- [ ] Cập nhật STATUS: đạt/chưa đạt, lỗi còn lại và bằng chứng; không sửa state package lịch sử thành done.
- [ ] Chủ dự án kiểm bản chơi; bước sau là chuẩn hóa onboarding và R2. Không tự mở rộng sang Endless hoặc tuyên bố đủ điều kiện phát hành.
