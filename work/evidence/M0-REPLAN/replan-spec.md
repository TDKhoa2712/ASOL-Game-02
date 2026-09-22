# M0 Editor-First Replan — Design Specification

## Intent

Mục tiêu ưu tiên là có một prototype tương tác chạy được trực tiếp trong Godot Editor càng sớm càng tốt. Việc thiếu iPhone, macOS/Xcode, Android mục tiêu hoặc số đo thiết bị thật không được chặn phát triển gameplay trong editor, nhưng vẫn phải chặn tuyên bố hoàn tất toàn bộ M0 và chặn mọi kết luận về hiệu năng mobile chưa đo.

## Constraints

- Giữ Godot 4.7.2, GDScript và renderer `mobile` làm baseline.
- Không thay đổi luật gameplay canonical, schema level hoặc phạm vi MVP.
- Không hạ ngưỡng TECH-13/19/21 và không giả lập evidence thiết bị thật bằng kết quả desktop/headless.
- Chỉ phân lại trách nhiệm, dependency, readiness và acceptance giữa các work package M0.
- Prototype dùng asset placeholder gốc, không dùng nội dung thương mại hoặc production asset.

## Approaches considered

### 1. Giữ nguyên chuỗi hiện tại

`M0-A02` tiếp tục chờ `M0-A01` đạt cả iOS và thiết bị thật. Cách này giữ hợp đồng hiện tại nhưng trì hoãn prototype vì hạ tầng không liên quan trực tiếp đến vòng lặp gameplay trong editor.

### 2. Bỏ toàn bộ mobile validation khỏi M0

Cho phép làm prototype và coi mobile validation là việc sau M0. Cách này nhanh nhất nhưng làm mất cổng chất lượng TECH-13/19/21 và trái mục tiêu mobile của dự án.

### 3. Editor-first, mobile-gated milestone — selected

Thu hẹp `M0-A01` thành bootstrap/editor/host-export baseline; đưa prototype editor vào `M0-A02`; gom đo thiết bị, iOS, safe area và hiệu năng vào `M0-A03`; giữ `M0-GATE` là nơi không cho M0 hoàn tất nếu evidence mobile còn thiếu. Cách này tạo prototype sớm mà không hạ tiêu chuẩn phát hành.

## Package architecture

### M0-A01 — Godot toolchain and editor baseline

Completion means:

- `game/project.godot` hợp lệ với Godot 4.7.2.
- Project chạy được qua editor/headless và bootstrap scene khởi động sạch.
- Portrait/mobile renderer và export presets được kiểm tra tự động.
- Android host export smoke tạo APK debug hợp lệ.
- Baseline ghi rõ phần chưa đo, nhưng iOS/device measurement không còn là acceptance của package này.

`M0-A01` không nhận TECH-13, TECH-19 hoặc QA-26 vì package không có playable level hay workload sprite đại diện. Requirement duy nhất là D-06. Package chuyển sang handoff/review sau khi verification và báo cáo bàn giao đầy đủ.

### M0-A02 — Playable interaction prototype

Package chuyển từ `draft` sang `ready` và tiếp tục phụ thuộc `M0-A01`. Prototype chạy bằng Godot Editor là đầu ra chính; APK hoặc thiết bị thật không phải điều kiện bắt đầu.

Phạm vi giữ nguyên: board T01 và interaction contract cho single tap, double tap, drag stroke, locked cells, Undo và Restart. Placeholder visuals phải là nội dung gốc và chỉ đủ để đọc trạng thái.

### M0-A03 — Mobile device and rendering validation

Package chuyển từ `draft` sang `ready`, phụ thuộc `M0-A02` để phép đo dùng workload tương tác đại diện thay vì bootstrap rỗng. Package nhận TECH-13, TECH-19, TECH-21 và QA-26/27/30/50.

Completion requires:

- Android mục tiêu và iPhone mục tiêu được định danh cùng OS.
- macOS/Xcode/signing environment cho iOS smoke.
- Offline install/run, cold startup, safe area và touch validation.
- FPS, frame stall, RAM/VRAM và load measurements với prototype/sprite workload đại diện.
- Nếu thiết bị hoặc host chưa có, package phải blocked; không được thay bằng desktop evidence.

### M0-GATE — Milestone evidence gate

Giữ dependency vào `M0-A02` và `M0-A03`. Gate không chặn việc xây prototype, nhưng không được pass nếu A03 thiếu device matrix, iOS build/run evidence hoặc TECH-13/19/21 measurements.

## State transition and restart sequence

1. Bảo toàn toàn bộ thay đổi `M0-A01` hiện tại trên nhánh package.
2. `M0-REPLAN` cập nhật bốn package và chạy repository validation.
3. `M0-REPLAN` handoff; reviewer/coordinator accept.
4. `M0-A01` được resume theo contract mới, verify, điền handoff và chuyển review.
5. Reviewer/coordinator accept `M0-A01`.
6. `M0-A02` bắt đầu trên baseline đã accept và tạo prototype chạy trong Godot Editor.
7. `M0-A03` chỉ bắt đầu sau khi prototype interaction đủ làm workload đo mobile.
8. `M0-GATE` tổng hợp evidence và giữ các blocker thiết bị thật.

Không được đánh dấu package phụ thuộc là bắt đầu/hoàn tất bằng sửa tay state file; mọi transition dùng `tools/agent_pipeline.py` hoặc transition API của chính pipeline khi CLI chưa có subcommand tương ứng.

## Validation

Replan phải chứng minh:

- Catalog không mất requirement/QA khỏi chuỗi M0: TECH-13/19 và QA-26 chuyển từ A01 sang A03/GATE.
- `M0-A01` không còn acceptance yêu cầu gameplay/device mà nó không tạo.
- `M0-A02` và `M0-A03` ở trạng thái catalog `ready` với dependency không tạo vòng.
- `python tools/agent_pipeline.py validate` pass.
- `python tools/agent_pipeline.py doctor` pass.
- Unit tests pipeline pass để phát hiện regression parsing/lifecycle.

## Non-goals

- Không triển khai gameplay trong `M0-REPLAN`.
- Không tạo production art/audio.
- Không thay đổi canonical GDD để hạ chuẩn mobile.
- Không tuyên bố QA-26, TECH-13 hoặc TECH-19 đã đạt khi chưa có prototype và thiết bị thật.
