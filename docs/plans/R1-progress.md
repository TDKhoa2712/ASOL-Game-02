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
