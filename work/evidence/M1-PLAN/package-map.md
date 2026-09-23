# M1 MVP package map

Ngày lập: 2026-09-24. Nguồn thẩm quyền: `GDD/02`, `GDD/03`–`GDD/05`, `GDD/07`, `GDD/08`, `GDD/10`, `docs/governance/00-design-status.md` và `docs/governance/06-design-freeze-checklist.md`.

## Ranh giới mốc

M1 là vertical slice gồm **4 level phát hành gốc order 1–4**, tutorial chỉ Level 1, schema v4 và chứng cứ S3 kỹ thuật, core/score, một session save, một Hint/lượt, Undo/Restart, Home/Puzzle/Result thắng/Result thua/Help/Settings và 6 màu/nhãn/họa tiết tạm. Fixture T01/E01/E02/S301/N12 không tính vào bốn level. `--release` đòi 24 level nên chỉ dùng ở M2, không dùng để nghiệm thu bốn level M1.

M0-A03 hiện `blocked` vì thiếu bằng chứng Android/iPhone mục tiêu và môi trường iOS; M0-GATE chưa đạt. M1-PLAN chỉ đăng ký hợp đồng. Mọi package M1 triển khai/content đều có **dependency trực tiếp `M0-GATE`**; không có việc triển khai M1 được mở qua cổng này.

## Package và thứ tự

| ID | Đầu ra độc lập | Dependency | Có thể bắt đầu ngay sau M0-GATE? | Kiểm chứng chính |
| --- | --- | --- | --- | --- |
| M1-A01 | Core action/score/event và test Godot | M0-GATE | Có | `run_puzzle_core_tests.gd` |
| M1-A02 | Level loader schema v4/S3 parity và test Godot | M0-GATE | Có | `run_level_loader_tests.gd`, fixture validator |
| M1-C01 | Bốn level gốc order 1–4 và biên bản giải mù | M0-GATE, M1-A02 | Sau A02 | Validator trên `campaign_m1.json` và duyệt người |
| M1-A03 | Save/session/progress v2 và test crash | M0-GATE, M1-A01, M1-A02 | Sau A01 và A02 | `run_save_repository_tests.gd` |
| M1-A04 | Hint S2/S3 từ state hiện hành | M0-GATE, M1-A01, M1-A02, M1-A03 | Sau A03 | `run_hint_engine_tests.gd` |
| M1-A05 | UI shell, accessibility và điều hướng | M0-GATE, M1-A01, M1-A02, M1-A03, M1-A04 | Sau A04 | `run_ui_shell_tests.gd`, review thiết bị |
| M1-A06 | Tutorial T1–T6 trên Level 1 thật | M0-GATE, M1-A03, M1-A04, M1-A05, M1-C01 | Sau A05 và C01 | `run_tutorial_tests.gd` |
| M1-GATE | Biên bản nghiệm thu vertical slice | M0-GATE và toàn bộ A01–A06/C01 | Sau tất cả | Validate, level validator, QA trên thiết bị |

Các lệnh Godot trong hợp đồng là cổng thực thi **sau khi code package tương ứng tồn tại**. Việc `validate`/`doctor` của M1-PLAN chỉ kiểm tra hợp đồng hiện tại, không khẳng định các kiểm chứng M1 tương lai đã chạy.

## Truy vết từ GDD 08

| Gói GDD 08 | Owner M1 | Giới hạn |
| --- | --- | --- |
| B — Core | M1-A01 | Không đo gesture; dùng prototype M0-A02 |
| C — Content tool | M1-A02, M1-C01 | Dùng validator canonical có sẵn; campaign 24 level ở M2 |
| D — Save/progress | M1-A03 | Một session, progress tuyến tính |
| E — Hint | M1-A04 | S2/S3, một Hint/lượt; QA-56 gồm reload/Retry/Restart |
| F — UI/tutorial | M1-A05, M1-A06 | Các màn và tutorial Level 1 gốc |
| J — S3 MVP | M1-A02, M1-A04 | Parity loader/hint với fixture S301; sáu level S3 order 19–24 ở M2 |
| G — Art/sprite/audio | M0-A03 cho atlas mèo mặc định; M1-A05 dùng bộ đã qua gate | Asset và audio hoàn chỉnh ở M2 |
| H — Level design | M1-C01 | Chỉ order 1–4; order 10/20 và 5–24 ở M2 |
| I — QA/release | M1-GATE | Chỉ cổng vertical slice; release candidate ở M3 |
| K — Meta/generator | Không có owner M1 | Sau MVP |

## Điều kiện review

- Review package M1 kiểm đúng ID/QA nêu trong front matter và evidence thực tế; QA device/accessibility cần thiết bị thật, không suy từ headless test.
- Tuning score 100/25, feedback và nhịp level trong M1 chỉ ở giới hạn tuneable đã được governance cho phép. Nếu phải đổi luật, schema, tiến trình hoặc phạm vi, mở decision change có thẩm quyền; không sửa qua package implementation.
- M1 không bao gồm S4/S5, N>6 trong nội dung phát hành, wallet, quảng cáo, cứu lượt, chọn mèo, generator hoặc runtime bake 3D.
