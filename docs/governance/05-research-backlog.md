# Research Backlog

Backlog này ghi câu hỏi và bằng chứng cần thu, không phải kế hoạch triển khai.

## NOW

| RES-ID | Research question / output | Related IDs | Exit evidence | Status |
| --- | --- | --- | --- | --- |
| RES-NOW-01 | Xác định một baseline tài liệu duy nhất và liệt kê mọi drift phải xử lý | CT/DRIFT trong audit, DQ-002 | Không còn phiên bản/architecture/status mâu thuẫn | CLOSED — v0.5.0 |
| RES-NOW-02 | Chốt phạm vi S3 đối với MVP | DQ-001, DEC-013, REV-TECH-04 | Order 1–18 S2; 19–24 bắt buộc S3; schema v4 | CLOSED — DEC-013 |
| RES-NOW-03 | Định nghĩa Design Freeze và change-control | DQ-002, AC-05 | Checklist 06 được phê duyệt và owner roles xác nhận | OPEN-BLOCKER |
| RES-NOW-04 | Định nghĩa ngưỡng đạt cử chỉ và per-level content | DQ-009, QA-08..12/43..45, LV-05/08 | Per-level gate đã chốt; ngưỡng cử chỉ còn cần M0 evidence | PARTIAL — DQ-009 CLOSED |

## M0

| RES-ID | Research question / output | Related IDs | Exit evidence | Status |
| --- | --- | --- | --- | --- |
| RES-M0-01 | Godot minor/renderer/device/OS/toolchain baseline | DQ-003, TECH-13/19 | Device matrix và build Android/iOS thử | OPEN |
| RES-M0-02 | Touch preview/double/drag/multi-touch/background và Undo/Restart trên thiết bị | DQ-004, UX-09..11/22..25 | Contract v2 replay và error report; accidental TryCat <3% | OPEN |
| RES-M0-03 | Atlas mèo mặc định và budget | DQ-005, TECH-19/21 | FPS/stutter/RAM/VRAM/load measurements | OPEN |
| RES-M0-04 | Board N=6, safe area, chữ lớn và vùng chạm | UX-18, QA-27 | Layout evidence trên device matrix | OPEN |
| RES-M0-05 | Khả năng đọc vùng với cùng một mèo trên mọi ô | REV-TECH-05, QA-50 | Visual recognition evidence | OPEN |

## M1

| RES-ID | Research question / output | Related IDs | Exit evidence | Status |
| --- | --- | --- | --- | --- |
| RES-M1-01 | Chiều sâu campaign theo band S1/S2 + S3 | DQ-008, DEC-013, LV-03/05/08 | Candidate corpus, solver metrics, blind solves ≥1 tim; runtime Hint S3 | OPEN |
| RES-M1-02 | Công bằng của 3 tim/Undo X/X đỏ | DQ-007, DEC-014/016, GR-16/17/19 | Player failure/quit/sentiment evidence | OPEN |
| RES-M1-03 | Giá trị của scorecard 100/25 ở Result | DQ-006, DEC-016, GR-18 | Comprehension/motivation evidence | OPEN |
| RES-M1-04 | Tutorial Level 1, một Hint/lượt và accessibility | DQ-012, DEC-015, UX-16..21 | Novice + assistive-technology report | OPEN |
| RES-M1-05 | Nhịp 24 level và mốc 10/20 | DEC-016, DQ-011, LV-05/07 | Per-level acceptance report | OPEN |

## POST-MVP

| RES-ID | Research question / output | Related IDs | Exit evidence | Status |
| --- | --- | --- | --- | --- |
| RES-POST-01 | Khả năng phát hành N=7–12 không zoom/pan | DQ-013, QA-35/42 | Puzzle/UI/device evidence | DEFERRED |
| RES-POST-02 | Economy, cứu lượt và nguồn Hint từ điểm danh/quảng cáo | DQ-014, QA-46/47/53 | Quyết định phạm vi mới, simulation và privacy/platform review | DEFERRED |
| RES-POST-03 | Bộ sưu tập/chọn mèo và nhiều gói asset | D-10, QA-52 | Ownership UX và asset/cache measurement | DEFERRED |
| RES-POST-04 | Generator offline cho level mới | QA-48, GDD/11 | Reproducible candidates qua full content gate | DEFERRED |

## PARKED

| RES-ID | Research question / output | Related IDs | Exit evidence | Status |
| --- | --- | --- | --- | --- |
| RES-PARK-01 | S4 cặp khóa | QA-38/40/41 | Chỉ mở sau S3 đã chứng minh | PARKED |
| RES-PARK-02 | S5 phản chứng ngắn | QA-39/41 | Chỉ mở sau S3/S4 và hint UX đạt | PARKED |
| RES-PARK-03 | Runtime render/bake animation 3D | TECH-21, QA-51 | Chỉ mở khi sprite offline không đáp ứng nhu cầu thật | PARKED |
| RES-PARK-04 | Tổ hợp phụ kiện/mèo tạo cache động | TECH-20/21 | Chỉ mở khi bộ sưu tập post-MVP được duyệt | PARKED |
