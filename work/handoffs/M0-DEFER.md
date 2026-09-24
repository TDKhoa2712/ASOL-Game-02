# Báo cáo bàn giao M0-DEFER

## Package

`M0-DEFER` — governance. Quyết định cho phép xây dựng M1 có điều kiện trong lúc M0-A03 thiếu thiết bị/iOS, giữ nguyên gate nghiệm thu M0/M1.

## Requirements

- GDD 08 và DEC-018 phân biệt quyền bắt đầu code với điều kiện qua mốc. Không đổi luật gameplay, schema, điểm, phạm vi MVP hoặc ngưỡng TECH-13/19/21.
- Bảy package triển khai/content M1 phụ thuộc trực tiếp `M0-DEFER`; dependency nội bộ M1 được giữ nguyên. `M0-GATE` vẫn phụ thuộc `M0-A03`; `M1-GATE` vẫn phụ thuộc `M0-GATE`.
- M1-A05 chỉ nhận implementation UI/accessibility tại package; bằng chứng đạt trên Android/iPhone mục tiêu chuyển rõ sang M1-GATE. M1-PLAN đang review được cập nhật hợp đồng, package map và handoff theo DEC-018.

## QA

- Không nhận QA-26/27/30/50 hoặc TECH-13/19/21 từ emulator, headless hay một ảnh Redmi. QA thiết bị và accessibility vẫn ở M0-A03/M0-GATE/M1-GATE theo phạm vi tương ứng.
- Không chấp nhận `M1-GATE` nếu M0-GATE chưa `done`, dù mọi package code M1 đã hoàn thành.

## Changed files

- `work/packages/M0-DEFER.md`: hợp đồng bootstrap, phạm vi và check dependency.
- `GDD/08-ke-hoach-trien-khai-cho-agent.md`, `docs/governance/02-decision-log.md`: ghi ngoại lệ thứ tự triển khai và DEC-018.
- `work/packages/M1-A01.md` đến `M1-A06.md`, `M1-C01.md`: thay dependency đầu vào bằng M0-DEFER; `M1-A05.md` làm rõ ranh giới QA thiết bị.
- `work/packages/M1-GATE.md`, `M1-PLAN.md`; `work/evidence/M1-PLAN/package-map.md`, `work/handoffs/M1-PLAN.md`: giữ gate nghiệm thu và đồng bộ hồ sơ plan đang review.
- `work/evidence/M0-DEFER/dependency-review.md`, `check_dependencies.py`, `verification.txt`; `work/state/M0-DEFER.toml` do pipeline quản lý; báo cáo này.

## Validation

- `python tools/agent_pipeline.py inspect M0-DEFER`: pass sau khi tạo hợp đồng bootstrap theo ủy quyền của người giao.
- `python tools/agent_pipeline.py verify M0-DEFER`: pass. Dependency policy pass; `validate` và `doctor` pass; pipeline unit tests 22/22, GDD unit tests 23/23.
- Game Python unit tests 8/8 pass với Godot 4.7.2 đã pin. Level validator 5/5 fixture pass, 0 cảnh báo hình học trùng. `git diff --check` pass.

## Evidence

- `work/evidence/M0-DEFER/dependency-review.md`: bảng trước/sau, package có thể bắt đầu và ranh giới nghiệm thu.
- `work/evidence/M0-DEFER/check_dependencies.py`: kiểm tự động mọi package M1 build đi qua M0-DEFER và M1-GATE vẫn đi qua M0-GATE/M0-A03.
- `work/evidence/M0-DEFER/verification.txt`: lệnh, exit code và output của check bắt buộc.

## Remaining risks

- M0-A03 vẫn `blocked`; Android OS, iOS/Mac/Xcode/signing, atlas sản xuất, ngân sách RAM/VRAM/cache và phép đo đầy đủ còn thiếu. Ảnh probe Redmi từ commit `bdf8e8b` trên nhánh M0-A03 chưa được nhập vào nhánh này.
- M1-PLAN đang ở trạng thái `review`; reviewer cần xem lại bản đồ dependency đã được DEC-018 thay thế trước khi accept. M0-DEFER chưa tự accept M1-PLAN.
- UI/asset M1 có thể phải chỉnh lại sau khi đo trên thiết bị và atlas cuối. M1-GATE tiếp tục chặn nghiệm thu cho tới khi M0-GATE đạt.

## Reviewer

Đề nghị reviewer governance kiểm tra DEC-018/GDD 08, đối chiếu toàn bộ bảng dependency, xác nhận không có đường nghiệm thu M1 bỏ qua M0-A03 và xét rủi ro triển khai UI khi thiếu iOS. Sau khi M0-DEFER được accept, M1-A01 và M1-A02 là hai package có thể start theo catalog; mỗi package vẫn cần con người giao đúng ID.
