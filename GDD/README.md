# CanDoKu — Game Design Document

**Phiên bản 0.8.0 · 2026-10-02 · Thiết kế đích cho bản playtest trước phát hành.** CanDoKu là game suy luận tìm kẹo bị đánh rơi trong vườn. Bản này thống nhất chủ đề, campaign playtest 30 level và ranh giới phát hành chính thức sau playtest; không chứng nhận client hiện tại đã đủ nội dung hoặc đạt phát hành. Tiến độ duy nhất ở [STATUS](../docs/STATUS.md).

## Điểm bắt đầu

Người chơi dùng hàng, cột và các luống vườn để suy ra vị trí kẹo. Một chạm ghi chú X, kéo đánh/xóa nhiều X, hai chạm xác nhận tìm kẹo. Đúng thì hé lộ viên kẹo; sai mất một tim. Mục tiêu là tìm đủ kẹo bằng suy luận, không tìm vật thể bằng thị lực hay thử từng ô.

| Tài liệu | Nội dung |
| --- | --- |
| [01 — Tầm nhìn](01-tam-nhin-va-pham-vi.md) | Bối cảnh, người chơi, vòng lặp và phạm vi |
| [02 — Luật chuẩn](02-luat-choi-va-trang-thai.md) | GR, trạng thái, input, tim, điểm, Hint và save |
| [03 — UX](03-luong-man-hinh-va-ux.md) | Màn hình, bố cục, tutorial và câu chữ |
| [04 — Level](04-thiet-ke-level.md) | Campaign playtest 30 màn, đường cong học, trace và biên tập |
| [05 — Kỹ thuật](05-kien-truc-va-du-lieu.md) | Module, schema/API hiện có, tương thích save và chuyển chủ đề |
| [06 — Mỹ thuật/âm thanh](06-my-thuat-va-am-thanh.md) | Kẹo, vườn, asset, chuyển động và âm |
| [07 — Nghiệm thu](07-kiem-thu-va-tieu-chi-nghiem-thu.md) | QA gameplay, chủ đề, nội dung và thiết bị |
| [09 — Rà soát CanDoKu](09-ra-soat-thiet-ke.md) | Những điểm sửa, rủi ro còn lại và thứ tự triển khai |
| [10 — Nguyên tắc suy luận](10-nghien-cuu-quy-tac-suy-luan.md) | Mô hình toán, S1–S5/X1–X4, chứng minh, phản ví dụ, trace và Hint; phân biệt hiện hành/mở rộng |
| [11 — Sinh level và độ khó](11-sinh-level-va-danh-gia-do-kho.md) | Profile/seed, sinh nghiệm/vùng/givens, kiểm nghiệm, thang độ khó thử nghiệm, playtest và mẫu giao việc |

Kế hoạch thực hiện nằm ở [ROADMAP](../docs/ROADMAP.md). Các tài liệu 08/11/12 cũ đã được tinh gọn khỏi GDD theo yêu cầu; cách khôi phục từ Git ở [09](09-ra-soat-thiet-ke.md#6-tinh-gọn-và-truy-vết). File 11 mới chuyên về sinh level/độ khó theo yêu cầu bổ sung, không khôi phục đề án kinh tế/bộ sưu tập cũ. Hai tài liệu 10/11 là nền của [generator pilot offline](../docs/level-generation.md); công cụ chưa tạo campaign phát hành hoặc mở Endless.

## Quyết định hiện hành

| ID | Thiết kế |
| --- | --- |
| D-01 | Playtest trước phát hành có 30 level liên tiếp, N=4–6, không chọn màn/chương; schema giữ N=4–12 |
| D-02 | Order 1–18 dùng S1/S2; từng level 19–24 cần S3; profile 25–30 phải duyệt riêng nhưng chỉ dùng S1–S3; không yêu cầu đoán |
| D-03 | Năm trạng thái kỹ thuật `empty/x/x_error/candy/locked`; `locked` là auto-mark X do hệ thống; `given` là cờ hiển thị |
| D-04 | Chạm/kéo X; chạm đôi thử kẹo; Undo một action X, grouped undo (candy + auto-marks = 1 nhóm); Restart có xác nhận |
| D-05 | Một Hint/lượt với progressive reveal (unit → cell), ba tim, Retry miễn phí; điểm chỉ hiện ở Result |
| D-06 | Godot 4.x/GDScript, runtime 2D; kẹo bọc giấy gốc và hiệu ứng 2D, không bắt buộc model/rig kẹo |
| D-07 | Offline, Android/iOS, tiếng Việt; không tài khoản, quảng cáo, IAP hoặc analytics mạng trong bản đầu |
| D-08 | X đỏ khóa trong lượt; ghi chú X không là chứng cứ của solver/Hint |
| D-09 | Level 10/20 có motif vườn riêng; generator, Endless, kinh tế và bộ sưu tập để sau |
| D-10 | Tên sản phẩm **CanDoKu**; chủ đề tìm kẹo đánh rơi, không có nuôi thú hoặc xây vườn |

GDD 02 giữ luật chuẩn; [DECISIONS](../docs/DECISIONS.md) ghi ngoại lệ/quyết định mới. Replay L01 của bản kiểm thử bốn level theo RST-003 không phải tính năng của campaign phát hành. Đổi tên hiển thị không đổi schema level v4, progress v2, session v3, ID level hoặc hash puzzle.

## Tham khảo có giới hạn

Đã đối chiếu ngày 2026-09-28 với [Meowdoku của Oakever trên Google Play](https://play.google.com/store/apps/details?id=com.oakever.meowdoku) và [App Store](https://apps.apple.com/us/app/meowdoku/id6761760135). Mô tả nhà phát hành xác nhận nền suy luận hàng/cột/vùng, không chạm, chạm đôi và ba cơ hội sai. Đây là nguồn tham khảo cơ chế; chưa phải khảo sát trực tiếp toàn bộ phiên bản game. Không dùng các website trùng tên làm nguồn chính thức.

CanDoKu tự thiết kế bối cảnh, level, layout, câu chữ, logo và asset. Tham khảo không đồng nghĩa đưa daily challenge, leaderboard, quảng cáo hoặc bộ sưu tập vào phạm vi. Chi tiết đối chiếu và các điểm cần kiểm ở [09](09-ra-soat-thiet-ke.md).

## Kiểm chứng

[data/levels.sample.json](data/levels.sample.json) là fixture kỹ thuật, không phải campaign playtest 30 level. [Vector tương tác](data/interactions.sample.json) dùng hoàn toàn token CanDoKu; test migration riêng kiểm save cũ. [Validator](tools/validate_levels.py) kiểm schema/nghiệm/trace; `--release` hiện vẫn là gate legacy 24 level và phải được thay bằng gate playtest 30 level có tên/phạm vi rõ trước nghiệm thu nội dung mới.

Tài liệu dành cho cả nội bộ và người ngoài gồm [tổng quan game](../docs/GAME_OVERVIEW.md), [technical stack](../docs/TECH_STACK.md) và [architecture](../docs/ARCHITECTURE.md). RST-011 trong [DECISIONS](../docs/DECISIONS.md) là quyết định mới nhất về mốc 30 level và phát hành chính thức sau playtest.

Sửa tài liệu: kiểm diff, link và tính nhất quán. Triển khai code: theo runner và GUI/device của [AGENTS](../AGENTS.md). Không lấy GDD hoàn chỉnh hoặc test headless làm bằng chứng game đã hoàn tất.
