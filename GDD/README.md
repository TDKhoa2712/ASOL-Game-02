# CanDoKu — Game Design Document

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-00 (Master index) |
| Phiên bản bộ GDD | 1.0.0 |
| Trạng thái | Draft · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Nhánh nền | `release/v1.0.1` |

> **Tóm tắt:** CanDoKu là game puzzle suy luận 2D, chơi offline, một người, cầm dọc trên di động. Người chơi tìm những viên kẹo ẩn sau các ô màu trên bàn N×N. Mỗi hàng, mỗi cột và mỗi vùng màu có đúng một kẹo, và hai kẹo không bao giờ chạm nhau, kể cả chạm góc. Bộ GDD này là nguồn chuẩn duy nhất cho thiết kế sản phẩm.

## 1. Cấu trúc bộ tài liệu

| Mã | Chương | Nội dung chính | Người đọc chính |
| --- | --- | --- | --- |
| GDD-01 | [Game Overview](01-game-overview.md) | High concept, pillars, đối tượng, phạm vi, tính năng | Toàn đội, đối tác |
| GDD-02 | [Core Gameplay](02-core-gameplay.md) | Luật chuẩn GR, trạng thái ô, điều khiển, tim, thắng/thua | Design, Dev, QA |
| GDD-03 | [Game Systems](03-game-systems.md) | Hint, Undo, Combo, Campaign, DDA, Endless, Assist | Design, Dev |
| GDD-04 | [UX/UI](04-ux-ui.md) | Screen flow, HUD, FTUE/tutorial, settings, accessibility, localization | UX, Dev, QA |
| GDD-05 | [Level Design](05-level-design.md) | Bank/pace/playlist, campaign, đường cong độ khó, cổng chất lượng level | Level design, Dev |
| GDD-06 | [Art Direction](06-art-direction.md) | Phong cách hình ảnh, màu, typography, animation, danh sách asset | Art, Dev |
| GDD-07 | [Audio](07-audio.md) | SFX, BGM, combo voice, haptics, đặc tả asset âm thanh | Audio, Dev |
| GDD-08 | [Technical Design](08-technical-design.md) | Kiến trúc, schema dữ liệu, save, hiệu năng, build, toolchain | Dev |
| GDD-09 | [QA & Acceptance](09-qa-acceptance.md) | Chiến lược kiểm thử, test case, cổng nghiệm thu, playtest | QA, PM |
| GDD-10 | [Appendix A — Reasoning Techniques](10-reasoning-techniques.md) | Mô hình toán, kỹ thuật S1–S7 kèm chứng minh, mở rộng nghiên cứu | Level design, Dev |
| GDD-11 | [Appendix B — Level Generation](11-level-generation.md) | Pipeline sinh level, mô hình độ khó, công cụ | Level design, Tools |
| GDD-12 | [Glossary & References](12-glossary.md) | Thuật ngữ, quy ước ID, tài liệu tham khảo | Toàn đội |

**Thứ tự đọc gợi ý:**

- Người mới: 01 → 02 → 04 → 03.
- Dev: thêm 08.
- QA: thêm 09.
- Level designer: 05 → 10 → 11.

## 2. Phạm vi GDD và tài liệu liên quan

GDD mô tả **thiết kế đích và hành vi hiện hành** của sản phẩm. Các nội dung sau nằm ngoài GDD:

| Nội dung | Tài liệu |
| --- | --- |
| Tiến độ, blocker, evidence | [STATUS](../docs/STATUS.md) — nguồn tiến độ duy nhất |
| Quyết định sản phẩm (RST-xxx) | [DECISIONS](../docs/DECISIONS.md) |
| Lộ trình và track còn lại | [ROADMAP](../docs/ROADMAP.md), [REMAINING_TASKS](../docs/REMAINING_TASKS.md) |
| Version, nhánh, release | [VERSIONING](../docs/VERSIONING.md) |
| Quy trình làm việc cho agent | [AGENTS](../AGENTS.md) |
| Lịch sử dự án | [HISTORY](../docs/HISTORY.md) |

Khi GDD và code không khớp nhau:

- Nếu code đúng, sửa GDD.
- Nếu thiết kế đúng, mở task sửa code.

Khi có quyết định mới làm thay đổi luật, ghi quyết định vào DECISIONS trước, rồi mới cập nhật chương liên quan và tăng phiên bản.

## 3. Quy ước

### 3.1. Mã yêu cầu

| Tiền tố | Chương | Ý nghĩa |
| --- | --- | --- |
| `GR-` | GDD-02 | Game Rule — luật chơi chuẩn |
| `UX-` | GDD-04 | Yêu cầu UX/UI |
| `LV-` | GDD-05 | Cổng chất lượng level |
| `ART-` | GDD-06 | Yêu cầu hình ảnh và animation |
| `AUD-` | GDD-07 | Yêu cầu âm thanh và haptics |
| `TECH-` | GDD-08 | Yêu cầu kỹ thuật |
| `QA-` | GDD-09 | Test case nghiệm thu |
| `S1–S7`, `X1–X4` | GDD-10 | Kỹ thuật suy luận |

Mỗi mã chỉ mang một nghĩa trong suốt vòng đời dự án. Yêu cầu bị bỏ được chuyển vào mục **"ID đã hủy"** của chương, và mã của nó không được dùng lại. Yêu cầu mới lấy số kế tiếp của tiền tố.

### 3.2. Trạng thái tính năng

| Nhãn | Ý nghĩa |
| --- | --- |
| **Live** | Có trong build và đang bật |
| **Off** | Có code nhưng đang tắt bằng feature flag |
| **Planned** | Đã thiết kế hoặc đang làm trên nhánh, chưa vào nhánh nền |
| **Backlog** | Ý tưởng đã ghi nhận, chưa lên kế hoạch |

### 3.3. Tọa độ và ngôn ngữ

- Dữ liệu và code dùng tọa độ `(r, c)` bắt đầu từ 0.
- UI hiển thị hàng và cột bắt đầu từ 1.
- "Vùng" (region) trong thuật toán là "vùng màu" (hoặc "vùng") khi nói với người chơi.
- Token trong code giữ nguyên: `candy`, `try_candy`, `CellKind`.

## 4. Dữ liệu và công cụ đi kèm

| Đường dẫn | Vai trò |
| --- | --- |
| [data/levels.sample.json](data/levels.sample.json) | Fixture kỹ thuật cho validator; không phải nội dung phát hành |
| [data/interactions.sample.json](data/interactions.sample.json) | Vector hành vi tương tác dùng cho test hợp đồng |
| [tools/](tools/) | Validator, công cụ sinh và mở rộng bank, báo cáo pilot (xem [GDD-11](11-level-generation.md)) |
| `tools/reports/generate_game_design_report.py` | Xuất bộ GDD ra `.docx`. Script đọc `README.md` và các file `GDD/NN-*.md`, nên chương mới phải giữ tiền tố hai chữ số. |

## 5. Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại toàn bộ theo chuẩn GDD studio, đối chiếu với code tại `release/v1.0.1`. Gộp `docs/GAME_OVERVIEW`, `ARCHITECTURE`, `TECH_STACK` và `ASSET_BACKLOG_VISUAL/AUDIO` vào GDD; bỏ bản rà soát 09 cũ. Đưa ra khỏi luật các mục không còn trong code: givens, auto-mark, Hint giới hạn theo budget và hiển thị điểm. |
| 0.9.0 | 2026-10-09 | Bản GDD trước khi viết lại (xem Git history). |
