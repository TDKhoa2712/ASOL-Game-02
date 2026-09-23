# Báo cáo bàn giao: M1-PLAN

## Package

`M1-PLAN` — governance; lập và đăng ký hợp đồng M1 cho vertical slice MVP. Hợp đồng bootstrap được tạo theo ngoại lệ người giao, sau đó `python tools/agent_pipeline.py inspect M1-PLAN` đã chạy trước mọi chỉnh sửa file khác. Không triển khai code M1, không đổi trạng thái M0-A03 hoặc M0-GATE.

## Requirements

Front matter của M1-PLAN không nhận mã gameplay/technical requirement làm hoàn tất. Phạm vi kế hoạch đối chiếu GDD 02/03/04/05/07/08/10 và governance; các mã GR/UX/LV/TECH cụ thể được giao cho từng package M1 trong `work/packages/`.

## QA

M1-PLAN không tuyên bố hoàn tất QA runtime. Các package M1 ghi QA owner trong front matter; `M1-GATE` sẽ tổng hợp chứng cứ vertical slice sau khi M0-GATE và các tiền đề M1 được nghiệm thu.

## Changed files

- `work/packages/M1-PLAN.md`: hợp đồng governance bootstrap, checks và phạm vi.
- `work/packages/M1-A01.md`, `M1-A02.md`, `M1-A03.md`, `M1-A04.md`, `M1-A05.md`, `M1-A06.md`, `M1-C01.md`, `M1-GATE.md`: tám hợp đồng M1.
- `work/evidence/M1-PLAN/package-map.md`: dependency, đầu ra và thứ tự bắt đầu.
- `work/evidence/M1-PLAN/verification.txt`: kết quả do pipeline ghi.
- `work/handoffs/M1-PLAN.md`: báo cáo này.

## Validation

`python tools/agent_pipeline.py verify M1-PLAN` đạt với `GODOT_BIN` trỏ tới Godot 4.7.2 đã pin và `PYTHONDONTWRITEBYTECODE=1`. `validate` và `doctor` exit 0; pipeline unit tests 22/22, GDD unit tests 23/23, game Python tests 8/8; level validator xác nhận 5 fixture, không cảnh báo trùng hình vùng. Lượt verify ban đầu thiếu `GODOT_BIN`; cache Python sinh ra từ lượt đó đã được dọn trước khi verify lại.

## Evidence

- `work/evidence/M1-PLAN/verification.txt` ghi command, exit code và output của từng check.
- `work/evidence/M1-PLAN/package-map.md` nêu A01 và A02 là hai package có thể bắt đầu ngay sau M0-GATE; tất cả package triển khai/content đều phụ thuộc trực tiếp gate.
- `work/state/M0-A03.toml` hiện `blocked`; `M0-GATE` chưa có state `done`.

## Remaining risks

M0-A03 còn thiếu bằng chứng thiết bị Android/iPhone, macOS/Xcode/signing và ngân sách atlas; do đó chưa package triển khai M1 nào được phép start. Các check Godot trong package M1 là cổng tương lai, chưa chạy vì deliverable chưa tồn tại. Bốn level M1 không đủ điều kiện `--release`; cổng 24 level, art/audio hoàn chỉnh và QA release thuộc M2/M3.

## Reviewer

Reviewer governance độc lập cần đối chiếu dependency M0-GATE, ranh giới 4 level M1 với 24 level M2, mã QA trong từng hợp đồng và bằng chứng verify trước khi accept M1-PLAN. Chưa có quyết định accept của reviewer.
