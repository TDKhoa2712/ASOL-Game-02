# Nhật ký triển khai — docs/plans/R1-playable-loop.md

Baseline: `f8c4933`; nhánh `fix/r1-playable-loop`, 2026-09-25.

## Quyết định thực thi

- Giữ một checkout và một agent theo quy trình dự án; không tạo worktree mới.
- Kế hoạch A–E là kế hoạch kết quả, không có Task N/chữ ký patch cho script skill. Dùng nhật ký này thay bộ brief/package tự sinh; không tạo lại pipeline quản trị. Rủi ro: cần ghi rõ kết quả từng phần để không bỏ sót khi tiếp tục.
- A và B/C cùng chạm bootstrap/runtime: A chỉ giữ runtime được cấp, không đổi tiến trình hay save schema; B/C phải giữ regression profile khi sửa tiếp.
- Đã tích hợp cải tổ vào dev theo đúng quyền được giao. Code R1 chưa được tích hợp.

## A — Đã cô lập test và ghi baseline; toàn bộ R1 chưa đạt

- Regression `run_bootstrap_profile_tests.gd` ban đầu FAIL vì bootstrap thay runtime được cấp; sửa `_ready` chỉ tạo runtime nếu chưa được cấp, regression PASS.
- UI flow/runtime tests chuyển sang scene tree thật, profile riêng theo process/time. Hai hành trình Win/Fail dùng hai fixture độc lập, không sửa flow/progress giữa hành trình. Cả hai suite PASS.
- Smoke Python tái hiện FAIL vì marker M0 cũ không còn. Thay bằng runner tải main scene cấu hình, bấm Play, ghi X và khôi phục qua repository thật trên profile riêng; kiểm exit code, marker hành vi và lỗi script.
- Không thay luật, campaign, schema hoặc state package lịch sử. Headless chưa chứng minh layout/gesture thực tế.

### Kiểm chứng ngày 2026-09-25

Môi trường: Godot `4.7.2.stable.official.ed1daf0bf`, Windows. Revision nền `f8c4933` cộng thay đổi R1-A trong commit chứa nhật ký này.

| Lệnh | Kết quả |
| --- | --- |
| `rtk python -B -m unittest discover game/tests -p test_*.py` với GODOT_BIN trỏ Godot 4.7.2 | 8/8 PASS |
| `rtk python -B -m unittest discover GDD/tools -p test_*.py` | 23/23 PASS |
| `rtk python -B GDD/tools/validate_levels.py game/data/campaign_m1.json` | 4 level hợp lệ |
| `rtk python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json` | 5 fixture hợp lệ |

Mẫu lệnh Godot thực thi cho từng tên dưới đây: `rtk C:\Users\khoat\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe --headless --path game --script res://tests/<tên>.gd`.

PASS (exit 0): run_puzzle_core_tests, run_level_loader_tests, run_save_repository_tests, run_hint_engine_tests, run_tutorial_tests, run_interaction_contract, run_ui_shell_tests, run_ui_flow_tests, run_mvp_runtime_tests, run_mobile_rendering_spike_smoke, run_bootstrap_profile_tests.

FAIL (exit 1): run_board_scene_smoke — `Status label is clipped`, `_run` dòng 136, `_fail` dòng 168. Lỗi baseline đã có trong hồ sơ A12, tái hiện lại trong lượt này; giữ là blocker R1-E, không loại suite khỏi kiểm tra. Tổng 11/12 bộ Godot đạt.

Bước tiếp theo: R1-B, regression Win → Home → Play/successor và terminal resume; R1-C bảo toàn ghi save; R1-D tutorial; R1-E sửa clipping và quan sát thật. Chưa kiểm thiết bị Android, chưa có final review toàn nhánh, chưa merge code R1 vào dev.

## B–E — Tiến độ trên nhánh R1, chưa nghiệm thu toàn chặng

- B: Flow chỉ điều hướng, runtime nắm level/progress. Integration từ scene tree kiểm Win → Home/Next → L02, Fail → Home/reload → Retry, bốn level → hết nội dung, score Result và Help quay về đúng nơi.
- B: Theo RST-003, sau L04 màn Result Home hoạt động; Home bật `Chơi lại từ L01` trong MVP. Replay tạo lượt mới với session fresh, giữ `currentLevelId = null` và `completedLevelIds` đã hoàn thành; cờ `MVP_ALLOW_CAMPAIGN_REPLAY` là điểm tắt trước release.
- C: Lỗi ghi session/progress (kể cả milestone tutorial) được báo, Home không bỏ phiên chưa lưu; Win chỉ phát khi progress đã ghi. Có thử lại và khôi phục Win pending sau mở lại. Progress primary hỏng/mất không còn làm mất backup hợp lệ khi lưu lại; primary hỏng được giữ ở `.corrupt`. Dữ liệu progress không thêm trường schema mới; target mèo tutorial được suy lại khi tải.
- D: Board thực phát milestone T1–T6; T6 chỉ xong sau khi đóng phần Hint. Miễn phạt sai chỉ ở ô tutorial đang chỉ, sai ô khác mất tim. Hint/Help có đường người chơi thật trong integration headless.
- E: Sửa toolbar tràn ngang, thêm bốn luật luôn thấy và hàng tiến độ vùng lấy từ board/given. Smoke đo 4/5/6 level ở viewport logic 1080×1920, nút và ô đạt tối thiểu 44 px logic. Đây chưa phải quan sát GUI/thiết bị.

### Kiểm chứng mới ngày 2026-09-25

Revision kiểm: nhánh `fix/r1-playable-loop` trên `e5829f9` cộng diff B–E chưa tích hợp; Godot `4.7.2.stable.official.ed1daf0bf` trên Windows.

| Lệnh | Kết quả |
| --- | --- |
| `rtk <Godot 4.7.2> --headless --path game --script res://tests/<suite>.gd` cho 15 suite: 11 suite gốc (gồm board smoke) và `run_bootstrap_profile_tests`, `run_playable_flow_tests`, `run_save_failure_tests`, `run_tutorial_integration_tests` | 15/15 PASS, exit 0 |
| `rtk python -B -m unittest discover game/tests -p test_*.py` với `GODOT_BIN` trỏ Godot 4.7.2 | 8/8 PASS, exit 0; lượt đầu thiếu biến môi trường nên 5 test báo lỗi cấu hình, đã chạy lại đúng |
| `rtk python -B -m unittest discover GDD/tools -p test_*.py` | 23/23 PASS |
| `rtk python -B GDD/tools/validate_levels.py game/data/campaign_m1.json` | 4/4 level hợp lệ |
| `rtk python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json` | 5/5 fixture hợp lệ |
| `rtk git diff --check` | PASS |

Đã chụp render Windows/Godot Vulkan từ entry scene thật trên profile cô lập: [Home](../evidence/r1/home.png), [Puzzle](../evidence/r1/puzzle.png), [Win](../evidence/r1/result_win.png), [Fail](../evidence/r1/result_fail.png). Quan sát phát hiện Title/Score/Message màn Result trắng trên nền sáng; sửa màu chữ và thêm regression `run_ui_shell_tests`; chụp lại hai Result đã đọc được. Script tái tạo: `game/tests/capture_r1_screens.gd`, Godot 4.7.2 chạy không `--headless`, exit 0.

Chưa đạt bằng chứng R1-E đầy đủ: chưa thao tác gesture GUI thật vì Computer Use trong phiên lỗi khởi tạo (`windows sandbox failed: helper_unknown_error`); ADB có nhưng `adb devices -l` không liệt kê thiết bị Android. Settings hiện là placeholder, chưa kiểm chữ lớn +30%, grayscale hoặc reduced motion. Ảnh render không thay thế QA thao tác trên thiết bị. Chưa review/integrate code R1 về dev.
