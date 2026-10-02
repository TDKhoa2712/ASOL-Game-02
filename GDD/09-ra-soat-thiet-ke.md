# 09 — Rà soát và hướng triển khai CanDoKu

Ngày 2026-09-28, thiết kế 0.6.0. Đây là kết quả rà GDD, không phải báo cáo kiểm thử client. Tiến độ, blocker và bước đang giao chỉ ở [STATUS](../docs/STATUS.md).

## 1. Nhận định về bản cũ

Bản 0.5 có nền tốt ở luật GR, cử chỉ, save, uniqueness và trace S2/S3. Tuy nhiên tầm nhìn bị gắn vào chủ đề thú cưng và bộ sưu tập, yêu cầu model/rig/clip nặng hơn nhu cầu puzzle, nghiên cứu meta/Endless dài dễ bị hiểu là phải làm ngay. Bản review còn ghi “chưa có game chạy được” theo thời điểm cũ dù STATUS đã có các kết quả runtime. Những điểm này làm người triển khai khó phân biệt thiết kế đích, lịch sử và phần chưa làm.

## 2. Tham khảo Meowdoku và lựa chọn CanDoKu

Nguồn đối chiếu: mô tả nhà phát hành Oakever trên [Google Play](https://play.google.com/store/apps/details?id=com.oakever.meowdoku) và [App Store](https://apps.apple.com/us/app/meowdoku/id6761760135), truy cập 2026-09-28. Chưa kiểm trực tiếp hành vi toàn bộ app; không khẳng định timing hoặc thuật toán nội bộ của trò tham chiếu.

| Điều tham khảo | Cách thiết kế trong CanDoKu |
| --- | --- |
| Một mục tiêu mỗi hàng/cột/vùng, không chạm | Giữ họ luật suy luận; viên kẹo và luống vườn là cách trình bày riêng |
| Chạm đôi và ba cơ hội sai trong mô tả chính thức | Giữ contract input/ba tim sẵn có của dự án; ngưỡng 350 ms và kéo 12 điểm là thông số CanDoKu cần playtest |
| Nhịp giải đố offline | Client hiện có bốn màn; mục tiêu kế tiếp là campaign playtest gốc 30 màn, tự lưu cục bộ |
| Chủ đề và phần thưởng cảm xúc | Kẹo hé lộ, giỏ picnic, hoa và lời động viên gốc; không dùng nhân vật của game tham chiếu hoặc sao chép HUD |

Ba hướng đã cân nhắc: chỉ thay icon sẽ nhanh nhưng không thống nhất bối cảnh; xây game tìm đồ vật trong tranh sẽ đổi bản chất luật và level; **tìm kẹo bằng suy luận trên sơ đồ vườn** giữ nền kỹ thuật, đồng thời cho chủ đề có vai trò rõ. Bản GDD này chọn hướng thứ ba theo yêu cầu người dùng.

## 3. Những điều đã làm rõ

| Điểm dễ hiểu sai | Quy định thiết kế |
| --- | --- |
| “Tìm” hay “đặt” kẹo? | Kẹo có vị trí cố định trong nghiệm; thao tác xác nhận tìm thấy, kẹo ở lại ô |
| Luống có phải một hàng? | Luống là vùng liên thông bất quy tắc, nhãn A–F; hàng/cột là hai ràng buộc riêng |
| Trang trí có là manh mối? | Không; mọi ô chưa tìm có cùng mức thông tin, chỉ topology và givens là dữ kiện |
| Có cần đổi schema? | Session nâng lên v3; API/fixture dùng candy/TryCandy/CandyFound. Level v4, progress v2 và puzzle hash giữ nguyên |
| Có cần 3D hoặc bộ sưu tập? | Không; dùng hình 2D và hiệu ứng nhỏ theo GDD 06 |
| Có đủ 30 màn playtest chưa? | GDD quy định đích; fixture và bộ bốn màn R1 không tự được tính là campaign đạt |
| Có mở giai đoạn mới? | Không; giữ R1 và ROADMAP hiện hành, không tự triển khai R2–R4 |
| Sau màn cuối có replay? | Bản kiểm bốn màn theo RST-003; campaign playtest 30 màn không replay L01; phát hành chính thức chờ quyết định sau playtest |

Giữ nguyên GR, công thức điểm, Hint, phạt và điều kiện thắng; điều chỉnh ngôn ngữ/hình ảnh, làm rõ modal Settings và thời gian phản hồi lỗi. QA-CD bổ sung kiểm đổi chủ đề/save cũ. Các ID ART/TECH giữ để truy vết nhưng yêu cầu nhân vật 3D/bộ sưu tập được thay bằng asset kẹo 2D.

## 4. Thứ tự thực hiện khi được giao chuyển client

1. Đối chiếu runtime với GDD 02/03/05; kiểm baseline và save cũ, liệt kê chuỗi/asset cần đổi. Giữ app identifier và đường dẫn save.
2. Đổi tên hiển thị, copy, kẹo/tim/luống/giỏ và accessibility labels đồng bộ trên toàn hành trình. Không chỉ đổi logo Home.
3. Quan sát từ entry scene thật: fresh → tutorial → bốn level, Hint/Undo/Restart, Fail/Retry, Home/resume và replay kiểm thử. Chạy runner theo AGENTS sau cụm sửa.
4. Theo ROADMAP khi R2/R3 được giao: playtest người mới, biên tập 30 màn cho bản chơi thử trước phát hành, asset/audio đại diện và hoàn thiện khả năng tiếp cận.
5. Theo R4 khi được giao: tắt replay kiểm thử, kiểm full campaign và đo Android/iOS, lifecycle/save trên build chốt.

Đây là thứ tự phụ thuộc cho thiết kế, không là bảng tiến độ song song và không cấp quyền mở chặng.

## 5. Điểm cần bằng chứng trước sản xuất/phát hành

- Luật kẹo không chạm là quy ước puzzle: kiểm người mới hiểu đúng và không tưởng là tìm vật thể trong tranh.
- Ba tim và Hint một lần giữ nền hiện có nhưng phải đo mức đoán mò, bế tắc và hiểu Hint S3 bằng playtest.
- Thiết bị Android/iPhone mục tiêu, ngân sách RAM/VRAM và người thử do chủ dự án phối hợp; thiếu thì ghi blocker tại STATUS.
- Asset gốc và logo cuối cần kiểm ở ô N=6/chữ lớn trước khi làm hàng loạt.
- Tài liệu này không chứng nhận quyền thương hiệu CanDoKu, hiệu năng, khả năng tiếp cận hệ điều hành hoặc client đã đổi tên.

## 6. Tinh gọn và truy vết

Theo yêu cầu người dùng, bỏ khỏi GDD ba tài liệu không còn nhiệm vụ trong phạm vi hiện hành: 08 (pipeline M0–M3 cũ), 11 (meta/vàng/bộ sưu tập chủ đề cũ), 12 (đề án generator/Endless chưa triển khai). Không chuyển các đề án thành tính năng CanDoKu. Giữ data/tools vì chúng kiểm hợp đồng và dữ liệu đang dùng.

Theo yêu cầu bổ sung cùng ngày, mở rộng file 10 thành tài liệu nền suy luận và thêm [11 — Sinh level/độ khó](11-sinh-level-va-danh-gia-do-kho.md) với nhiệm vụ riêng, không khôi phục meta/Endless. Đây là tài liệu chuẩn bị công cụ nội dung tương lai; không phải generator đã được triển khai.

Bản trước đợt này có tại revision `b335b1891d1b9927e3b55f2ec8945dda252c779f`. Có thể đọc/khôi phục từng file bằng Git, ví dụ `git show b335b1891d1b9927e3b55f2ec8945dda252c779f:GDD/11-ke-hoach-meta-va-sinh-level.md`. Không xóa code, asset, fixture hoặc test trong đợt tài liệu.
