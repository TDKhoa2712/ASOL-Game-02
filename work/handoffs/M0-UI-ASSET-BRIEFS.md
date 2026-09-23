# Báo cáo bàn giao: M0-UI-ASSET-BRIEFS

## Package

`M0-UI-ASSET-BRIEFS` — content package chuẩn bị UI/asset cho MVP, chạy độc lập sau `M0-PREFLIGHT` và song song với `M0-A02`/`M0-A03`.

## Requirements

Metadata `requirements = []` vì gói này tạo brief sản xuất, chưa triển khai hay chứng minh requirement GDD. Nội dung đối chiếu `UX-01/03..08`, `ART-01..11`, `D-06` và GDD/08; package tích hợp sau phải tự khai báo mã mà scene/asset của nó thực sự đáp ứng.

## QA

Metadata `qa = []` vì chưa có asset nhập Godot, số đo thiết bị hoặc playtest để nhận QA. Brief ghi tiêu chí kiểm cho asset nhận về; `M0-A03` và package tích hợp chịu trách nhiệm QA runtime/mobile theo phạm vi riêng.

## Changed files

- `work/packages/M0-UI-ASSET-BRIEFS.md` — hợp đồng và dependency song song.
- `work/asset-briefs/M0-UI-ASSET-BRIEFS.md` — danh mục 7 màn/luồng, 9 nhóm asset, phiếu cấu tạo, prompt và tiêu chí tiếp nhận.
- `work/state/M0-UI-ASSET-BRIEFS.toml` — trạng thái pipeline.
- `work/evidence/M0-UI-ASSET-BRIEFS/verification.txt` — kết quả verify.
- `work/handoffs/M0-UI-ASSET-BRIEFS.md` — báo cáo này.

## Validation

- `python tools/agent_pipeline.py inspect M0-UI-ASSET-BRIEFS`: package được đọc với dependency chỉ `M0-PREFLIGHT`.
- `python tools/agent_pipeline.py validate`: pass.
- `python tools/agent_pipeline.py doctor`: pass.
- `python tools/agent_pipeline.py verify M0-UI-ASSET-BRIEFS`: pass; 22/22 pipeline unit tests, 23/23 GDD unit tests, validator 5/5 fixtures và 0 cảnh báo trùng geometry.
- Review nội dung thủ công: đủ Home, Puzzle, Tutorial, Result thắng, Result thua, Help và Settings; mỗi nhóm asset có mục đích, cấu tạo, nguồn/xuất, prompt và tiêu chí duyệt; có thứ tự nhận theo lô và ranh giới Godot/asset.

## Evidence

`work/evidence/M0-UI-ASSET-BRIEFS/verification.txt` ghi lệnh, exit code và output từng check. Hợp đồng/brief nằm trong nhánh `work/m0-ui-asset-briefs-mvp-ui-and-asset-creation-briefs` tách từ `main`; checkout `M0-A02` ban đầu không bị chỉnh sửa.

## Remaining risks

- Chủ dự án chưa gửi asset; package này không khẳng định hình, model, clip, âm thanh hoặc UI runtime đã hoàn thành.
- Tên/logo cuối theo O-01 chưa chốt; prompt hiện không phụ thuộc tên tạm.
- Atlas/frame/nén và khả năng đọc trên Android/iPhone cần kết quả thực tế từ `M0-A03` trước khi khóa bản xuất.
- Các package tích hợp sau phải được giao ID, đường dẫn được phép và QA tương ứng; không tự sửa package M0 đã bàn giao.

## Reviewer

Chủ dự án duyệt brief và prompt trước khi sản xuất asset; reviewer pipeline nghiệm thu package sau khi xem evidence và các rủi ro trên.
