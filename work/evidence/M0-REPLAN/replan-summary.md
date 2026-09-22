# M0 editor-first replan summary

## Kết quả

Chuỗi M0 đã được phân lại để prototype tương tác có thể phát triển và chạy trực tiếp trong Godot Editor trước khi có thiết bị thật. Không có luật gameplay, schema level hay ngưỡng chất lượng mobile nào bị thay đổi.

| Hạng mục | Trước | Sau |
| --- | --- | --- |
| Godot editor/toolchain | M0-A01 | M0-A01 |
| Android host export | M0-A01 | M0-A01 |
| Editor interaction prototype | M0-A02 draft | M0-A02 ready |
| TECH-13/19/21 device measurements | Phân tán hoặc bị chặn tại M0-A01/M0-A03 | M0-A03 |
| QA-26 offline device run | M0-A01 | M0-A03 |
| Android/iPhone/macOS-Xcode evidence | M0-A01 | M0-A03, được M0-GATE cưỡng chế |

## Trách nhiệm package sau replan

- M0-A01 hoàn tất project/editor/headless baseline và Android host export, không tuyên bố iOS hoặc device validation đã pass.
- M0-A02 tạo prototype T01 bằng asset placeholder nguyên gốc và nghiệm thu interaction trong Godot Editor.
- M0-A03 dùng prototype làm workload đại diện để đo Android/iPhone, iOS/Xcode, safe area, cold load, FPS, stall và memory.
- M0-GATE không được pass nếu A01/A02/A03 chưa `done` hoặc thiếu evidence mobile thật cho TECH-13/19/21 và QA-26.

## Truy vết không bị mất

- D-06 vẫn thuộc M0-A01 và M0-GATE.
- TECH-13, TECH-19 và QA-26 được chuyển khỏi M0-A01 sang M0-A03, đồng thời vẫn được M0-GATE kiểm tra.
- TECH-21 tiếp tục thuộc M0-A03 và M0-GATE.
- Các requirement/QA interaction của M0-A02 được giữ nguyên.

## Thứ tự tiếp tục

Sau khi M0-REPLAN được reviewer/coordinator accept, package thực thi tiếp theo là M0-A01 để verify và đóng baseline theo contract mới đã thỏa mãn. Sau khi M0-A01 được accept, con người giao chính xác M0-A02 để bắt đầu xây prototype chạy trong Godot Editor. M0-A03 chỉ bắt đầu khi prototype đủ đại diện cho phép đo mobile.

Không được bắt đầu package kế tiếp bằng cách sửa tay state; mọi transition phải đi qua pipeline.

## Final review rulings

- Requirement loss: pass — TECH-13/19 và QA-26 vẫn có chủ sở hữu tại M0-A03 và được M0-GATE kiểm tra.
- Dependency ordering: pass — M0-A01 → M0-A02 → M0-A03, không có chu trình.
- False completion: pass — M0-A01 chỉ nhận editor/toolchain/host export và ghi rõ phần device/iOS chưa đo.
- Prototype blocking: pass — M0-A02 nghiệm thu prototype trong Godot Editor, không yêu cầu APK hoặc thiết bị thật.
- Gate weakening: pass — M0-GATE từ chối thiếu Android/iPhone, macOS/Xcode hoặc số đo TECH-13/19/21.
- Scope deviation: accepted — chỉ assertion seed M0-A02 được đồng bộ từ `draft` sang `ready`; pipeline implementation không đổi.
