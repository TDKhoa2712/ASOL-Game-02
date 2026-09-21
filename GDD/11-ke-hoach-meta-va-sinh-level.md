# 11 — Kế hoạch meta và sinh level sau MVP

**Trạng thái:** hồ sơ nghiên cứu sau MVP cho REV-ECO-01/REV-GD-04/REV-META-01; **không phải cam kết sản phẩm hoặc roadmap đã duyệt**. Luật scorecard, tim, Hint và tiến trình hiện hành ở [02](02-luat-choi-va-trang-thai.md); schema level v4/progress v2 không có wallet, quảng cáo, điểm danh hoặc metadata generator. Mọi meta cần quyết định phạm vi mới sau MVP; không được dùng tài liệu này để biện minh cho luật 3 tim hiện hành.

## 1. Mục tiêu và thứ tự

1. Phát hành puzzle gốc với 3 tim, scorecard GR-18 chỉ ở Result, một Hint mỗi lượt và tiến trình tuyến tính; MVP không có interface meta.
2. Sau khi có số liệu hoàn thành level, có thể nghiên cứu vàng như một phương án độc lập; scorecard MVP không hứa sẽ được quy đổi và thiết kế meta có thể bị loại bỏ hoàn toàn.
3. Vườn mèo là danh sách mèo đã mua bằng vàng. Người chơi chọn một mèo đã mua làm ngoại hình/hoạt ảnh đang dùng, hoặc quay lại mèo mặc định; không xây sân vườn mô phỏng, petting, trang trí hay mèo tự cấp khi thắng level.
4. Biên tập level mốc 10/20 trong 24 level đầu. Sau MVP, dùng công cụ sinh level **offline** để đề xuất ứng viên cho level mới và mốc 30/40 trở đi, có biên tập viên duyệt. Mốc đặc biệt không đổi luật GR.
5. Điểm danh hoặc quảng cáo thưởng để cấp thêm Hint chỉ là nguồn có thể nghiên cứu sau MVP. MVP không có nút, counter, adapter, placeholder hay lời mời cho hai nguồn này; Retry/Restart chỉ cấp Hint của lượt mới theo GR-21..24.

## 2. Vàng, cứu lượt và bộ sưu tập: phương án nghiên cứu chưa cam kết

Điểm cuối lượt thắng vẫn tính `score = max(0, 100 × correctPlacedCount − 25 × mistakeCount)`. Đề xuất cấp `gold = floor(score / 50)` **một lần cho lần thắng đầu của mỗi level**. Lượt thua cấp 0; chơi lại sau này không cấp vàng lần nữa. Ví dụ thắng N=6, không given, 0 lỗi → 600 điểm → 12 vàng; 1 lỗi → 575 điểm → 11 vàng. Công thức/giá cần kiểm trên tập level thật và có thể đổi **trước khi phát hành wallet**, cùng version kinh tế rõ ràng.

Wallet dùng số nguyên không âm và ledger bất biến: `grantId = level:<id>:first_clear`, `spendId` duy nhất cho giao dịch, `economyVersion`, số dư. Grant và cập nhật progress phải nguyên tử hoặc có cơ chế phát lại idempotent sau crash; không thể vừa hiện nhận vàng vừa mất giao dịch. Khi cập nhật từ bản cũ, backfill các level đã thắng theo `results` đúng một lần, với quy tắc version cố định và biên bản migration. Không tính vàng từ X/hint/tốc độ chưa được chốt.

| Nội dung tương lai | Giá | Ranh giới thiết kế |
| --- | ---: | --- |
| Cứu lượt khi tim về 0 | Chốt sau playtest | Hồi 1 tim và đưa riêng ô `x_error` của lần sai cuối về `empty`; giữ nguyên các ô khác, điểm, số lỗi, hint và thời gian |
| Mua mèo trong bộ sưu tập | Chốt theo từng `appearanceId` | Sở hữu vĩnh viễn, chọn mèo để đổi hình và hoạt ảnh; không đổi nghiệm hoặc cơ hội thắng |

Hint S2/S3 cơ bản và trang luật không dùng vàng. Nếu sau MVP nghiên cứu điểm danh/quảng cáo để cấp thêm Hint, phải có đặc tả hạn mức, riêng tư, offline fallback và QA riêng; không tái sử dụng âm thầm `hintCount` 0..1 của MVP. UI meta chỉ được tạo sau quyết định phạm vi mới. Mua mèo và cứu lượt, nếu được duyệt, có `spendId` riêng, xử lý idempotent; mở lại màn, chạm lặp hoặc crash không được trừ hai lần.

Khi tim về 0, phiên chuyển sang **chờ quyết định cứu lượt** và khóa bàn, chưa ghi kết quả thua cuối cùng. Người chơi có thể: (1) trả vàng nếu đủ số dư; (2) nếu không đủ vàng, xem quảng cáo thưởng khi dịch vụ có sẵn; hoặc (3) bỏ qua và Thử lại miễn phí trên cùng level. Chỉ khi trừ vàng thành công **hoặc** nhận xác nhận xem quảng cáo thưởng hợp lệ mới hồi đúng 1 tim, xóa X đỏ của **lần sai vừa làm tim về 0** và trở lại `Playing` trên board cũ. Các X đỏ trước đó vẫn khóa; `mistakeCount` và phạt điểm của lần sai cuối vẫn giữ. Nếu quảng cáo bị hủy, lỗi, không có mạng hoặc không có quảng cáo, phiên vẫn ở màn chờ quyết định với nút Thử lại dùng được. Không tự tiêu vàng, không tự phát quảng cáo và không cấp tim khi khôi phục app.

Trạng thái chờ, tọa độ ô sai cuối và ID giao dịch phải lưu bền vững trước khi hiện lựa chọn. Chi vàng và chuyển session về `Playing` cần cùng một giao dịch khôi phục được sau crash; xác nhận thưởng quảng cáo cũng cần ID duy nhất để không cấp lặp. Tích hợp quảng cáo chỉ thuộc bản mở rộng có SDK/mạng và đánh giá riêng về riêng tư, nền tảng, khả năng sẵn có; bản đầu vẫn chơi offline hoàn toàn. Khi không thể xem quảng cáo, Retry miễn phí luôn là đường tiếp tục. Đây là thay đổi state/save tương lai, **không áp dụng GR-17/19 của bản đầu** cho đến khi migration, fixture hành vi và QA-47/53 được triển khai cùng nhau.

## 3. Công cụ sinh level offline

Generator nhận `seed`, `generatorVersion`, cỡ N, nhịp khó mục tiêu và bộ motif biên tập. Một lần chạy cho ra nhiều ứng viên **chưa phát hành**. Pipeline đề xuất:

1. Sinh hoán vị vị trí mèo thỏa hàng/cột/không chạm chéo.
2. Phân vùng N miền liên thông, mỗi miền chứa đúng một mèo nghiệm; kiểm diện tích và độ đọc hình vùng.
3. Chọn givens và bố trí vùng để tạo một nghiệm duy nhất; đếm nghiệm độc lập với nghiệm gốc.
4. Tìm trace hợp lệ bằng tập quy tắc **đã được bật** (S1/S2 cho order 1–18, S1/S2/S3 cho order 19–24); nếu cần đoán thì loại hoặc chỉnh ứng viên. S4/S5 chỉ được thêm sau khi qua [cổng nghiên cứu](10-nghien-cuu-quy-tac-suy-luan.md).
5. Tính chỉ số: số bước chứng minh, số focus thay thế, số givens, hình vùng trùng dưới xoay/lật, độ khó đọc và thời gian solver. Loại ứng viên trùng hoặc vượt ngân sách.
6. Biên tập viên giải không nhìn nghiệm, chọn/điều chỉnh; chạy `validate_levels.py --release` trên campaign và playtest. Chỉ level đã duyệt mới nhận ID/order phát hành bất biến.

“Quy luật ẩn” ở đây là **mẫu thiết kế nội dung**, như đối xứng vùng, vùng hẹp/rộng xen kẽ, thứ tự loại trừ hoặc chuỗi S3 về sau. Người chơi không phải đoán một luật thắng bí mật. Metadata seed/motif/version nằm ở hồ sơ biên tập; chỉ thêm vào JSON runtime nếu có nhu cầu và migration được duyệt. Không để kết quả ngẫu nhiên runtime thay thế level đã kiểm chứng.

## 4. Level mốc 10/20 và các mốc tiếp theo

Mỗi mốc có một motif hình ảnh riêng, sticker riêng và một khoảnh khắc suy luận nổi bật trong tập quy tắc đã học. `order=10` là tổng kết kỹ năng đầu; `order=20` là thử thách tổng hợp trước chặng cuối. Cả hai được **biên tập thủ công trước release đầu** vì generator chưa có và ID/puzzle đã phát hành bất biến. Chúng vẫn có 3 tim, cùng bốn trạng thái và cùng điều kiện thắng; không ép motif làm hỏng puzzle. Sau MVP, generator có thể đề xuất các mốc mới như `30,40`, hoặc hỗ trợ 10/20 **chỉ nếu nội dung đầu chưa phát hành**. Không thay 10/20 của người chơi đã hoàn thành để đưa level sinh tự động vào.

## 5. Cổng triển khai

| Giai đoạn | Đầu ra | Cổng QA |
| --- | --- | --- |
| Meta prototype | Bảng tính mô phỏng điểm→vàng, giá cứu lượt và giá mèo trên 24 level với nhiều nhóm người chơi | Không có level nào yêu cầu mua để tiến; hint và Retry miễn phí; giá/công thức được chốt bằng dữ liệu |
| Wallet và bộ sưu tập | Version progress mới, ledger, migration/backfill, danh sách mèo mua và lựa chọn hiện hành | QA-46/52; crash, cấp/mua trùng và số dư âm đều được xử lý |
| Cứu lượt và quảng cáo thưởng | Version session mới, trạng thái chờ quyết định, giao dịch cứu lượt và adapter quảng cáo có fallback | QA-47/53; không mất board, không cấp/trừ trùng, Retry miễn phí khi quảng cáo vắng mặt |
| Generator prototype | Seed/version tái tạo, báo cáo ứng viên, fixture level gốc, kiểm trùng/trace | QA-48 và QA-01..07/32/35; timeout không được coi là hợp lệ |
| Mốc đặc biệt bản đầu | Level order10/20 duyệt người, motif/sticker, playtest trước release | QA-49/36; không đổi GR, vẫn đọc được và không cần đoán |
| Mốc đặc biệt về sau | Ứng viên order30/40 hoặc các mốc chưa phát hành từ generator offline | QA-48/49; không thay ID/puzzle cũ |

## 6. Bộ sưu tập và chọn mèo sau MVP

`appearanceId` định danh ngoại hình mèo; `assetVersion` định danh clip đóng gói. Mèo mặc định luôn có sẵn để có lựa chọn ban đầu và nút quay về riêng; **danh sách Vườn mèo chỉ gồm các mèo đã mua bằng vàng**, không tự cấp mèo khi thắng level. Danh sách có ảnh xem trước, trạng thái đang chọn và nút chọn; mèo chưa mua chỉ có thể xuất hiện trong danh mục mua. Không có sân vườn mô phỏng hoặc tương tác petting trong phạm vi này.

`selectedAppearanceId` quyết định hình mèo trên **mọi ô `cat`, gồm given và ô người chơi đặt**, cùng hoạt ảnh đúng/sai/thắng/thua phù hợp. Mèo trên ô đáp án không có giống riêng theo ô hoặc theo vùng; level JSON không gán `appearanceId` cho ô. Vùng A–L vẫn được nhận diện bằng nền, viền, nhãn và họa tiết của ô/hàng tiến độ, độc lập với màu lông và clip của mèo được chọn. Đổi mèo chỉ đổi cách trình bày; không thay nghiệm, trạng thái ô, tim, điểm hay `puzzleHash`.

Khi tính năng bật, nâng `progressVersion` và thêm `purchasedAppearanceIds`, `selectedAppearanceId` với migration: người chơi cũ dùng mèo mặc định và danh sách mua ban đầu rỗng; `selectedAppearanceId` phải là ID mặc định hoặc thuộc danh sách đã mua. Mua mèo bằng vàng dùng ledger idempotent của §2 và ghi quyền sở hữu cùng giao dịch; mua lại không trừ tiền. ID asset không có hoặc lỗi nạp hiển thị mèo mặc định mà không mất quyền sở hữu. Session/level schema không chứa lựa chọn mèo. Việc đổi mèo được ghi bền vững trước khi UI báo “đã chọn”; asset manager nạp clip mới và đổi presenter khi sẵn sàng, không reset bàn đang chơi.

Một hình render tĩnh một lần chỉ dùng cho chân dung/sticker. Hoạt ảnh cần nhiều frame; phương án mặc định là bộ sprite đã render offline **theo từng mèo**, tải và dùng lại khi mèo đó đang được chọn. Màu vùng nằm trên bàn/hàng tiến độ, nên không cần nhân clip theo 6/12 vùng hoặc tô màu mèo theo vùng. Giới hạn cache theo ngân sách thiết bị; gói mèo cũ có thể được giải phóng sau khi đổi. Nhánh bake 3D theo yêu cầu dành cho nhiều biến thể ngoại hình sẽ được thử riêng theo [TECH-21](05-kien-truc-va-du-lieu.md) và QA-51 trước khi thành tính năng.
