# GDD-01 — Game Overview

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-01 |
| Phiên bản | 1.0.0 |
| Trạng thái | Approved · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Liên quan | [GDD-00](README.md), [GDD-02](02-core-gameplay.md), [GDD-03](03-game-systems.md), [GDD-05](05-level-design.md), [GDD-06](06-art-direction.md), [GDD-12](12-glossary.md) |

> **Tóm tắt:** CanDoKu là puzzle suy luận logic offline, chơi dọc trên mobile: tìm đúng một viên kẹo trong mỗi hàng, cột và vùng màu, các viên không chạm nhau. Chương này chốt high concept, pillars, khán giả, nền tảng, quy mô nội dung, danh sách tính năng theo trạng thái và ranh giới phạm vi.

## 1. Mục đích và phạm vi

Chương là one-pager cho mọi bộ phận: quyết định *game là gì, cho ai, chơi ở đâu, có gì và không có gì*. Luật chi tiết ở [GDD-02](02-core-gameplay.md); hệ thống phụ trợ ở [GDD-03](03-game-systems.md); nội dung level ở [GDD-05](05-level-design.md).

## 2. High concept

| Mục | Nội dung |
| --- | --- |
| Tên | CanDoKu |
| Thể loại | Logic puzzle (region placement / star-battle-like), single-player |
| High concept | "Tìm kẹo ẩn sau ô màu, bằng từng suy luận nhỏ." |
| Elevator pitch | Một bàn N×N gồm các ô màu chia thành vùng màu; kẹo ẩn sau một số ô. Tìm đúng một viên kẹo vào mỗi hàng, mỗi cột, mỗi vùng; hai viên không bao giờ chạm nhau, kể cả chéo. Đánh X để loại trừ, chạm đôi để thử kẹo, ba tim cho ba lần đoán sai. Mỗi bàn có đúng một lời giải đạt được bằng suy luận — không cần đoán. |
| Session | 1–6 phút/level (định hướng, chờ số liệu playtest) |
| Nền tảng | Android (chính), iOS; portrait; offline hoàn toàn |
| Engine | Godot 4.7 / GDScript |

### 2.1 Chủ đề và setting

Không có câu chuyện bối cảnh: chủ đề đơn giản là tìm những viên kẹo ẩn sau các ô màu. Bàn là một lưới ô màu sạch, sáng, chia thành các vùng màu; người chơi suy luận để biết ô nào đang giấu kẹo. Kẹo được hé lộ dưới ô màu chính là phần thưởng cho suy luận. Không nhân vật, không cốt truyện tuyến tính, không trang trí cạnh tranh sự chú ý với bàn chơi. Art hướng tới ô màu phẳng, tương phản rõ, viên kẹo bóng bẩy nổi bật khi hé lộ (chi tiết ở [GDD-06](06-art-direction.md)).

## 3. Unique selling points

| USP | Mô tả |
| --- | --- |
| Suy luận thuần, không đoán | Mọi level có nghiệm duy nhất và trace logic hợp lệ (S1–S7, xem [GDD-10](10-reasoning-techniques.md)). |
| Hint dạy, không chỉ lộ đáp án | Hint giải thích kỹ thuật suy luận kèm highlight; chỉ dùng fallback reveal khi không còn kỹ thuật nào ([GDD-03 §2](03-game-systems.md#2-hint-system)). |
| Thao tác một tay, ít ma sát | Tap = X, double-tap = kẹo, swipe = X hàng loạt; không chế độ công cụ. |
| Thưởng cảm giác "candy" | Combo voice 12 cấp + word-art popup cho chuỗi kẹo đúng liên tiếp (RST-026). |
| Quy mô nội dung lớn, offline | 36.573 level gốc, N=4–12, không cần mạng. |
| Tôn trọng người chơi | Không quảng cáo, không IAP, không analytics, không timer đếm ngược. |

## 4. Design pillars

| Pillar | Ý nghĩa | Hệ quả thiết kế (do / don't) |
| --- | --- | --- |
| **P1 — Suy luận rõ ràng** | Mỗi bước tiến có lý do người chơi tự giải thích được. | Do: nghiệm duy nhất, trace hợp lệ, Hint có giải thích. Don't: level cần đoán, luật ẩn, manh mối giấu bằng màu khó phân biệt. |
| **P2 — Thao tác có chủ ý** | Input không bao giờ "tự làm" thay người chơi hoặc gây lỗi ngoài ý muốn. | Do: double-tap mới thử kẹo, guard chống vuốt nhầm, Undo X. Don't: auto-mark, auto-solve, phạt tim vì thao tác X. |
| **P3 — Bàn ô màu dễ đọc, dễ chịu** | Bàn đọc được ngay, phản hồi ấm áp, không gây áp lực. | Do: màu vùng tương phản ΔE ≥ 20, chế độ colorblind, combo vui. Don't: timer, monetization áp lực, hiệu ứng che bàn. |

## 5. Khán giả mục tiêu

| Thuộc tính | Mô tả |
| --- | --- |
| Phân khúc | Casual-to-midcore puzzle player trên mobile |
| Độ tuổi | 18–55 (không nhắm trẻ em làm đối tượng chính) |
| Thói quen | Chơi phiên ngắn lúc chờ, đi lại, trước khi ngủ; thích Sudoku, nonogram, logic grid |
| Động lực | Mastery (tự tìm ra lời giải), completion (đi hết campaign), thư giãn |
| Ngôn ngữ | 7 ngôn ngữ: en, ja, vi, id, pt_BR, es, ko (auto theo hệ thống) |

### 5.1 Player persona

| Persona | Mô tả | Nhu cầu chính |
| --- | --- | --- |
| **Linh, 29, nhân viên văn phòng** | Chơi 5–10 phút trên xe buýt, một tay, thường tắt tiếng. | Resume đúng chỗ, thao tác một tay, đọc được khi tắt âm. |
| **Minh, 45, fan Sudoku** | Muốn bàn lớn, kỹ thuật khó, ghét bị "mớm" đáp án. | Nội dung N=7–12, Hint có lý do chứ không chỉ lộ ô. |
| **An, 22, người mới thể loại** | Chưa biết luật, dễ bỏ cuộc khi sai liên tục. | Tutorial bắt buộc, tips theo ngữ cảnh, Retry miễn phí. |

## 6. Nền tảng và mô hình kinh doanh

| ID | Quyết định | Ghi chú |
| --- | --- | --- |
| OV-01 | Android là nền tảng chính; iOS hỗ trợ | Export presets Android/iOS Debug + Release, Web (nội bộ). Bundle ID `org.asol.game02`. |
| OV-02 | Portrait-only | Cấu hình project Godot. |
| OV-03 | Offline hoàn toàn; save cục bộ | Không tài khoản, cloud save, mạng. |
| OV-04 | Không ads, không IAP, không analytics | Không tự mở; mọi thay đổi cần quyết định sản phẩm trong [DECISIONS](../docs/DECISIONS.md). |
| OV-05 | Premium/free chưa chốt | Quyết định sau playtest; thiết kế hiện tại không phụ thuộc monetization. |

## 7. Session và nhịp chơi

| Tham số | Giá trị đích | Nguồn |
| --- | --- | --- |
| Thời lượng level 4×4–6×6 | 1–4 phút | Định hướng biên tập |
| Thời lượng level 7×7–12×12 | 4–10 phút | Định hướng biên tập |
| Thời lượng một session | 5–15 phút (2–5 level) | Persona |
| Gián đoạn | Resume chính xác board/tim/lỗi/thời gian | [GDD-08](08-technical-design.md) |

## 8. Quy mô nội dung

| Hạng mục | Quy mô | Chi tiết |
| --- | --- | --- |
| Tổng level trong bank | **36.573** | 31 bank JSON trong `game/data/banks/` |
| Kích thước bàn | N = 4–12 | Bank size 4×4…12×12 + bank biến thể và bank theo kiểu |
| Campaign đang chạy | `campaign_100` (100 level, 4×4→12×12) | Chọn qua `game/data/campaigns/active_campaign.json` |
| Campaign playtest | `demo_30` (30 level, 4×4–6×6) | Playlist dự phòng/playtest |
| Campaign nâng cao | `advanced` (80 level, ≥7×7) | Chưa gắn vào luồng người chơi |
| Biến thể hiển thị | ×8 qua `board_transform` | Xoay/lật, không đổi lời giải logic |

Chi tiết kiến trúc nội dung ở [GDD-05](05-level-design.md).

## 9. Danh sách tính năng

| ID | Tính năng | Trạng thái | Tham chiếu |
| --- | --- | --- | --- |
| FT-01 | Core puzzle (luật GR-01..05, X/kẹo/X đỏ, 3 tim) | Live | [GDD-02](02-core-gameplay.md) |
| FT-02 | Input tap / double-tap / swipe có guard | Live | [GDD-02 §5](02-core-gameplay.md#5-điều-khiển) |
| FT-03 | Undo X một bước | Live | [GDD-03 §3](03-game-systems.md#3-undo) |
| FT-04 | Hint engine 7 chiến lược, không giới hạn | Live | [GDD-03 §2](03-game-systems.md#2-hint-system) |
| FT-05 | Combo voice + word-art (RST-026) | Live | [GDD-03 §4](03-game-systems.md#4-combo) |
| FT-06 | Campaign tuyến tính, replay khi hoàn tất | Live | [GDD-03 §5](03-game-systems.md#5-campaign-progression) |
| FT-07 | DDA `pace_adjuster` | Live | [GDD-03 §6](03-game-systems.md#6-dda--pace-adjuster) |
| FT-08 | Tutorial bắt buộc + coach L01/L02 + contextual tips | Live | [GDD-04](04-ux-ui.md) |
| FT-09 | Settings: SFX, nhạc, haptic, reduced motion, high contrast, colorblind, ngôn ngữ | Live | [GDD-04](04-ux-ui.md) |
| FT-10 | Lưu/khôi phục dual-slot | Live | [GDD-08](08-technical-design.md) |
| FT-11 | 7 ngôn ngữ | Live | [GDD-04](04-ux-ui.md) |
| FT-12 | Endless mode | **Off** (đã build, `ENABLE_ENDLESS=false`) | [GDD-03 §7](03-game-systems.md#7-endless-mode) |
| FT-13 | Assist inventory + play streak | **Planned** | [GDD-03 §8](03-game-systems.md#8-planned--assist-inventory-và-play-streak) |
| FT-14 | Hiển thị điểm (score) | Off (công thức dormant) | [GDD-02 §9](02-core-gameplay.md#9-điểm-score) |

## 10. Ngoài phạm vi

| Hạng mục | Lý do |
| --- | --- |
| Ads, IAP, tiền tệ, cứu lượt trả phí | OV-04, P3 |
| Analytics, tài khoản, cloud save, leaderboard, daily challenge | OV-03, OV-04 |
| Chọn level tự do / bản đồ level | Campaign tuyến tính (chỉ debug build có level picker) |
| Givens (kẹo cho sẵn) | Đã loại toàn hệ thống; validator từ chối givens khác rỗng |
| Auto-mark sau khi đặt kẹo đúng | Vi phạm P2 (xem [GDD-02 ID đã hủy](02-core-gameplay.md#13-id-đã-hủy)) |
| Zoom/pan bàn | Xung đột input X |
| Nhân vật, cốt truyện, meta xây dựng/trang trí, gacha | Ngoài pillars |

## 11. Tham khảo và nguyên gốc

- Thể loại tham khảo: họ puzzle đặt quân theo hàng/cột/vùng không chạm nhau (Star Battle, các biến thể "queens" trên mobile). Chỉ tham khảo **luật thể loại** — luật logic không thuộc sở hữu riêng.
- Mọi asset, level, câu chữ, âm thanh, mã nguồn của CanDoKu là tác phẩm gốc. Không sao chép tên thương mại, giao diện, nhân vật, âm thanh hoặc cấu trúc level của game thương mại.
- Thư mục `extracted_reusable/` chỉ dùng để đối chiếu hành vi; không sao chép code, tên hay enum. Gate clean-room trong [GDD-09](09-qa-acceptance.md).
- Chi tiết pháp lý và thuật ngữ: [GDD-12](12-glossary.md).

## 12. Chỉ số thành công (playtest)

| ID | KPI | Ngưỡng đích | Cách đo |
| --- | --- | --- | --- |
| KPI-01 | Hoàn thành tutorial | ≥ 8/10 người mới | Quan sát playtest |
| KPI-02 | Hiểu X đỏ và mất tim | ≥ 8/10 giải thích đúng sau L03 | Phỏng vấn sau phiên |
| KPI-03 | Hoàn thành 10 level đầu trong phiên đầu | ≥ 70% | Quan sát + save `completedLevelIds` |
| KPI-04 | Tỷ lệ fail trung bình L01–L30 | ≤ 15% lượt chơi | Ghi tay / save `results` |
| KPI-05 | Thời gian/level 4×4–6×6 | trung vị 1–4 phút | `results.time_ms` |
| KPI-06 | Cảm nhận "phải đoán" | ≤ 2/10 người báo | Phỏng vấn |
| KPI-07 | Muốn chơi tiếp | ≥ 7/10 | Khảo sát cuối phiên |

Không có analytics: số liệu lấy từ quan sát, phỏng vấn và đọc save trên thiết bị thử (kế hoạch ở [GDD-09](09-qa-acceptance.md)).

## 13. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| OQ-01-1 | Mô hình kinh doanh chưa chốt | Ảnh hưởng store listing, Assist inventory | Quyết định sau playtest, ghi DECISIONS |
| OQ-01-2 | Bàn 10×10–12×12 trên màn nhỏ | Kích thước chạm có thể dưới chuẩn | Device QA Track E |
| OQ-01-3 | Bật Endless cho người chơi | Phạm vi QA tăng | Chờ quyết định sản phẩm |

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất GDD 01, GAME_OVERVIEW và phần tham khảo của GDD 09; đồng bộ với code hiện hành. |
