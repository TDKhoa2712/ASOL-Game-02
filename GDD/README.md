# GDD — Vườn Mèo (tên tạm)

**Phiên bản:** 0.5.0 · **Ngày:** 2026-09-21 · **Trạng thái:** đặc tả ứng viên cho GDD v1.0; còn cổng bằng chứng M0/M2 và chưa có game chạy được.

## Đọc theo thứ tự

| Tài liệu | Vai trò |
| --- | --- |
| [01-tam-nhin-va-pham-vi.md](01-tam-nhin-va-pham-vi.md) | Sản phẩm, phạm vi, điểm, tiến trình level |
| [02-luat-choi-va-trang-thai.md](02-luat-choi-va-trang-thai.md) | **Nguồn chuẩn của luật GR** và thao tác ô |
| [03-luong-man-hinh-va-ux.md](03-luong-man-hinh-va-ux.md) | Luồng màn hình, chạm/kéo/chạm đôi, kết quả, tutorial |
| [04-thiet-ke-level.md](04-thiet-ke-level.md) | Suy luận, biên tập và duyệt level |
| [05-kien-truc-va-du-lieu.md](05-kien-truc-va-du-lieu.md) | Chọn engine, schema, API, save và cache asset mèo |
| [06-my-thuat-va-am-thanh.md](06-my-thuat-va-am-thanh.md) | Mèo đang chọn độc lập với màu vùng, sprite từ model 3D, sticker, âm thanh |
| [07-kiem-thu-va-tieu-chi-nghiem-thu.md](07-kiem-thu-va-tieu-chi-nghiem-thu.md) | Ca QA và cổng phát hành |
| [08-ke-hoach-trien-khai-cho-agent.md](08-ke-hoach-trien-khai-cho-agent.md) | Gói việc và mốc triển khai |
| [09-ra-soat-thiet-ke.md](09-ra-soat-thiet-ke.md) | Quyết định cho từng mã review từ bản 0.3 |
| [10-nghien-cuu-quy-tac-suy-luan.md](10-nghien-cuu-quy-tac-suy-luan.md) | Đặc tả S3 cho MVP; nghiên cứu S4/S5 sau MVP |
| [11-ke-hoach-meta-va-sinh-level.md](11-ke-hoach-meta-va-sinh-level.md) | Kế hoạch vàng, cứu lượt, bộ sưu tập mèo và sinh level sau MVP |
| [12-sinh-level-do-kho-va-endless.md](12-sinh-level-do-kho-va-endless.md) | **Ứng viên chờ duyệt văn bản:** generator có kiểm soát difficulty, nhịp 3 Medium + 1–2 Hard và Endless Garden |
| [data/levels.sample.json](data/levels.sample.json) | Fixture kỹ thuật, không thuộc nội dung phát hành |
| [data/interactions.sample.json](data/interactions.sample.json) | Vector hành vi chạm/kéo và ô khóa cho prototype |
| [tools/validate_levels.py](tools/validate_levels.py) | Validator schema v4, nghiệm, trace S2/S3 và thứ tự release |

## Các quyết định hiện hành

| ID | Quyết định |
| --- | --- |
| D-01 | Một dãy level liên tiếp. Bản đầu 24 level gốc, thứ tự `1..24`, bàn N=4–6. Sau này có thể mở tới N=12 vùng/mèo/màu khi UI, solver, asset và QA đạt cổng riêng. Không có chương hoặc màn chọn level. |
| D-02 | Level 1–18 dùng S1/S2. Mỗi level 19–24 bắt buộc có ít nhất một bước S3 cần thiết trong trace máy kiểm được; S4/S5 để sau MVP. |
| D-03 | Ô có đúng bốn trạng thái `empty`, `x`, `x_error`, `cat`. Một chạm đổi X/empty; hai chạm cùng ô xác nhận mèo. Sai thành `x_error`, mất một trong ba tim. |
| D-04 | Một chạm hiện X/xóa X ngay bằng preview và xác nhận sau cửa sổ chạm đôi; giữ và rê sẽ tô/xóa X theo trạng thái ô đầu. Chạm đôi cùng ô hủy preview rồi thử mèo. Có Undo một action X gần nhất và Restart có xác nhận; không Undo qua `TryCat`, không Redo. |
| D-05 | Màn chơi không hiện điểm; điểm chỉ là scorecard ở Result. Hàng N báo tiến độ theo màu/nhãn/họa tiết vùng. Mỗi lượt có một Hint miễn phí. Chỉ level hiện tại được chơi; thắng chuyển sang level kế, thua cho Retry miễn phí. |
| D-06 | Godot 4.x/GDScript cho game 2D; tạo model/animation mèo 3D gốc rồi xuất **một bộ sprite cho mỗi mèo**. Mọi ô `cat` và hoạt ảnh dùng mèo đang chọn, bản đầu là mèo mặc định; màu vùng nằm ở nền/viền/nhãn, không tô mèo theo vùng. Không dùng SubViewport 3D runtime trong bản đầu. |
| D-07 | Offline Android/iOS, tiếng Việt đầu tiên, không tài khoản/SDK quảng cáo hoặc analytics mạng trong bản đầu. Asset, level và câu chữ gốc. |
| D-08 | Giữ 3 tim và phạt điểm; `x_error` là kết quả sai cố định trong lượt, không thể xóa/đặt lại/Undo. Hết tim thua; Retry hoặc Restart reset toàn bộ lượt trên cùng level. |
| D-09 | Mốc level 10/20 được biên tập trước release đầu. Generator, ví vàng, cứu lượt, quảng cáo, điểm danh và mọi nguồn Hint bổ sung đều là nghiên cứu sau MVP; không có interface hoặc lời hứa quy đổi điểm trong MVP. |
| D-10 | “Vườn Mèo” chỉ là tên tạm. Bộ sưu tập/chọn mèo, nếu làm sau MVP, phải qua quyết định phạm vi riêng; MVP chỉ có mèo mặc định và không có sân vườn tương tác. |

`GR` trong tài liệu 02 là luật chuẩn. Thay đổi luật, schema, thứ tự tiến trình hoặc cách tính điểm phải sửa GDD, fixture, validator/test và QA cùng thay đổi. Nội dung puzzle của ID đã phát hành không được đổi âm thầm.

## Nguồn đối chiếu

Luật nền được đối chiếu với mô tả chính thức của [Meowdoku trên Google Play](https://play.google.com/store/apps/details?id=com.oakever.meowdoku) và [App Store](https://apps.apple.com/us/app/meowdoku/id6761760135). Lựa chọn engine dựa trên [tài liệu Phaser](https://docs.phaser.io/) và [AnimatedSprite2D của Godot](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html). Dự án không dùng tên, level, giao diện, nhân vật hoặc asset của game tham chiếu.

## Kiểm tra fixture

Từ thư mục gốc: `python GDD/tools/validate_levels.py GDD/data/levels.sample.json` và `python -m unittest discover GDD/tools -p "test_*.py"`. Cờ `--release` dùng khi có đủ 24 level campaign, thứ tự `1..24`. Fixture `T01/E01/E02/S301/N12` không tính vào số này.
