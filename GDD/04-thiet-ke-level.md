# 04 — Thiết kế level và quy trình nội dung

Tài liệu này giữ cổng chất lượng và biên tập campaign. Đặc tả kỹ thuật chi tiết nằm ở [10 — Nguyên tắc suy luận](10-nghien-cuu-quy-tac-suy-luan.md) và [11 — Sinh level/đánh giá độ khó](11-sinh-level-va-danh-gia-do-kho.md). Các chỉ số/rating thử nghiệm trong 11 không tự thay logic band hoặc tiêu chí phát hành bên dưới.

## 1. Điều kiện phát hành

| ID | Điều kiện |
| --- | --- |
| LV-01 | Schema N=4–12, bản đầu N=4–6; đúng N vùng không rỗng, mọi vùng liên thông 4 hướng; mỗi ô có đúng một nhãn vùng. |
| LV-02 | Đúng một nghiệm khi áp dụng givens; nghiệm khai báo và givens khớp nghiệm do solver độc lập tìm. Bản phát hành còn ít nhất hai kẹo để người chơi tự tìm. |
| LV-03 | Trace S2/S3 được kiểm chứng tuần tự từ givens đến đủ N kẹo; mỗi Hint runtime có bằng chứng dựng từ kẹo hiện có và tập loại trừ S3 đã chứng minh. |
| LV-04 | Hai level cách nhau không quá 8 vị trí campaign không có cùng hình vùng sau xoay/lật/đổi nhãn; cảnh báo để biên tập, build release chặn đến khi thay level. |
| LV-05 | Mỗi level có `difficulty`, `tags`, biên bản thời gian và điểm kẹt của ít nhất một lượt giải thủ công không nhìn nghiệm. |
| LV-06 | Vùng, dấu và kẹo đọc được ở thang xám, chữ lớn và màn nhỏ; màu không mang luật duy nhất. |
| LV-07 | Biên tập `order=10,20` trong 24 level đầu như mốc đặc biệt về bố cục, motif hình ảnh và nhịp suy luận; vẫn giữ toàn bộ GR và vượt cùng validator/playtest. Puzzle/ID phát hành bất biến, nên generator sau MVP chỉ hỗ trợ mốc mới như `30,40`, không sửa ngược 10/20. |
| LV-08 | Release band cố định: order 1–18 không chứa S3; mỗi order 19–24 chứa ít nhất một S3 hợp lệ và không thể hoàn tất chỉ bằng closure S2. S4/S5 không thuộc MVP. |

Fixture `T01/E01/E02/S301/N12` trong [levels.sample.json](data/levels.sample.json) là đầu vào kỹ thuật, **không** nằm trong 24 level phát hành. Campaign phải có đúng `order=1..24`, mỗi vị trí một ID và không có chương. N12 chỉ chứng minh biên schema/nhãn A–L với given đầy đủ; không chứng minh bàn 12×12 thú vị hoặc UI đạt chuẩn.

## 2. Suy luận được hỗ trợ

**S1 — loại trừ cơ bản:** từ một kẹo đã biết, loại ô khác cùng hàng, cột, vùng hoặc ô chéo kề. Mỗi ô loại phải nêu ít nhất một kẹo nguồn và loại quan hệ. S1 là chứng cứ được dựng từ trạng thái, không cần một bước riêng trong `logicTrace`.

**S2 — ứng viên đơn:** trong một hàng/cột/vùng chưa có kẹo, sau S1 chỉ còn đúng một ô chưa bị loại; ô ấy bắt buộc có kẹo. Một bước trace ghi `focus` và ô đặt. Validator phải tự dựng lại tập ứng viên; không tin danh sách ô loại do người biên tập khai. Tại runtime, hint tính lại từ givens và kẹo đã tìm thấy, rồi hiển thị các ô cùng focus bị S1 loại và ít nhất một nguyên nhân cho từng ô. Nếu focus là vùng một ô, danh sách ô loại rỗng là hợp lệ.

**S3 — khóa giao thoa:** gọi `P(U)` là tập ứng viên hiện tại của một đơn vị `U` sau S1 và các loại trừ S3 trước đó. `source` và `target` phải là hai loại đơn vị khác nhau trong row/column/region. Khi `P(source)` không rỗng và `P(source) ⊆ target`, kẹo của source buộc nằm trong giao thoa, nên loại **toàn bộ** `P(target) \ source`. Tập bị loại phải không rỗng; conclusion thiếu ô, thừa ô, lặp hoặc no-op đều bị từ chối. Checker chỉ dùng topology, givens/candy đã chứng minh và tập loại trừ hiện hành; không dùng `solution`, X hoặc `x_error` làm tiền đề.

Mỗi level order 19–24 phải **cần S3**: thuật toán closure chỉ lặp S2 từ givens không được hoàn tất level, còn trace S2/S3 phải hoàn tất. Hint ưu tiên S2 trực tiếp, sau đó chuỗi S3→S2 ngắn nhất; có thể giải thích riêng bước loại nếu chưa tạo S2. [Tài liệu suy luận](10-nghien-cuu-quy-tac-suy-luan.md) là đặc tả chi tiết cho S3 và nghiên cứu S4/S5. S4/S5 chưa thuộc schema/validator/hint MVP.

Uniqueness không chứng minh người chơi giải được bằng S1/S2. Nếu trace không đi hết, sửa vùng/givens hoặc giữ level cho đợt mở rộng; không chèn một bước đoán.

## 3. Nhịp khó và tiêu chí biên tập

| Nhãn | Đặc trưng mong muốn | Mục tiêu playtest |
| --- | --- | --- |
| `tutorial` | Chỉ Level 1, chứa mốc T1–T6 và bước S2 rõ | 1–3 phút |
| `easy` | Nhiều focus S2 rõ, kẹo cho sẵn nếu cần | 2–4 phút |
| `medium` | Chuỗi S2 dài hơn, giao nhau hàng/cột/vùng | 3–6 phút |

`hard` là enum dự trữ cho nội dung tương lai; validator `--release` từ chối `hard` ở bản đầu. Độ khó không dựa riêng vào N hoặc số givens. Ghi số bước, số focus có thể chọn, số lần người chơi dùng hint, thời gian trung vị và chỗ họ phải đoán. Trong dãy level, cho một level nghỉ sau 3–4 level tăng khó. Nếu người chơi liên tục chạm đôi để dò nghiệm, sửa level/hint/tutorial trước khi gắn nhãn khó hơn.

## 4. Quy trình tạo và duyệt

1. **Sinh nghiệm gốc:** hoán vị cột thỏa GR-04, chọn vùng liên thông quanh đúng một ô nghiệm mỗi vùng; không dựa trên level/screenshot của game khác.
2. **Chọn givens:** tối thiểu đủ để đạt nhịp dạy; không dùng givens để che một bố cục vùng khó đọc.
3. **Đếm nghiệm độc lập:** chạy solver với vùng và givens, dừng ở 2; so nghiệm duy nhất với JSON.
4. **Dựng trace S2/S3:** order 1–18 chỉ dùng S2; order 19–24 có S3 cần thiết. Validator tự dựng ứng viên, kiểm tập loại đầy đủ và cấm dựa vào nghiệm/ghi chú.
5. **Lọc trùng:** chuẩn hóa hình vùng dưới 8 phép xoay/lật và đổi nhãn; kiểm cửa sổ 8 level theo `order` liên tiếp.
6. **Duyệt bằng người:** giải không xem nghiệm, ghi thời gian, hint, bước bất ngờ, khả năng đọc ở thang xám và vấn đề tutorial. Một lượt duyệt là tối thiểu; playtest 10 người ở cổng QA vẫn cần.
7. **Đóng gói:** chạy validator `--release`, kiểm asset và script tutorial gắn với ID thực tế. Không thêm level lỗi vào build.

Gói phát hành là 24 level gốc. Nếu một level không qua cổng, thay nó; không giảm tiêu chuẩn để đạt chỉ tiêu số lượng. Generator offline đã được mở cho pilot theo RST-010; xem [hướng dẫn công cụ](../docs/level-generation.md). Ứng viên vẫn phải qua các bước 3–7 và duyệt người. “Quy luật ẩn” chỉ là motif biên tập như đối xứng, mật độ vùng hoặc nhịp suy luận; không bổ sung luật thắng bí mật đối với người chơi.

## 5. Fixture kỹ thuật

| ID | Lưới | Nghiệm | Givens | Kiểm chính |
| --- | --- | --- | --- | --- |
| T01 | 4×4 | `[1,3,0,2]` | Không | Vùng A một ô, chuỗi S2 |
| E01 | 5×5 | `[2,4,0,3,1]` | `(0,2)` | Loại trừ từ given |
| E02 | 6×6 | `[5,2,4,0,3,1]` | `(0,5)` | Chuỗi S2 nhiều vùng |
| S301 | 4×4 | `[1,3,0,2]` | Không | S3 `region A → row 0`, rồi chuỗi S2; fixture dương, không thuộc campaign |
| N12 | 12×12 | `[0,2,4,6,8,10,1,3,5,7,9,11]` | Cả 12 ô | Biên N=12 và nhãn A–L; không tính là gameplay |

T01 bắt đầu với vùng A chỉ gồm `(0,1)`. Sau khi tìm kẹo ở đó, S1 loại cùng hàng/cột/vùng/ô chéo; trace tiếp tục bằng S2. Đây là dữ liệu gốc của dự án. Chữ A–L là nhãn vùng và khóa nền/viền/họa tiết trong theme; không chọn loại hoặc giấy gói kẹo theo vùng. Tên màu cụ thể không là luật.

## 6. Hợp đồng hint cho người biên tập

Trace lưu **kết luận cần chứng minh**, không lưu văn bản tự do. S2 chỉ lưu ô đặt; S3 khai tập ô loại để validator so với tập tự tính đầy đủ, không tin khai báo. `textKey` chọn mẫu câu theo focus/rule; runtime cung cấp nhãn vùng, tọa độ hiển thị, ô bị loại và kẹo nguồn. Nếu X che ô đích, UI nhắc chạm đôi trực tiếp để thử kẹo; X đỏ không thể che ô nghiệm trong level hợp lệ. Hint chỉ chỉ ra điều logic từ kẹo đã biết và quy tắc; không khẳng định một ghi chú của người chơi là tiền đề.
## 7. Biên tập nội dung CanDoKu

Một level được bàn giao cùng ID/order, JSON hợp lệ, trace, bản ghi lượt giải mù (thời gian, lỗi, Hint, điểm kẹt), kiểm đọc vùng và nguồn gốc bố cục. Dữ liệu mẫu không tự trở thành nội dung đã duyệt. Bốn level R1 là bộ kiểm vòng chơi, không chứng minh đường cong 24 màn đã đạt dải kích thước ở GDD 01.

Motif vườn chỉ nằm ở backdrop và ảnh kết quả; hình ô kẹo bị che trước khi tìm phải giống ô trống. Không dùng hoa, sỏi, vệt giấy gói hoặc ánh sáng khác biệt để lộ nghiệm. Mỗi vùng là một luống liên thông, được gọi nhất quán bằng A–F. Màn 10/20 có hình kết quả riêng, vẫn dùng cùng bốn luật và cùng loại kẹo.

Sau mỗi 3–4 màn tăng tải suy luận có một màn nhịp nhẹ hơn. Trong dải 19–24, màn nhẹ vẫn cần S3; giảm số bước hoặc độ rối vùng, không bỏ điều kiện S3. Nếu mục tiêu thời gian ở GDD 01 không đạt khi thử người thật, chỉnh bố cục/givens và thử lại; không sửa nhãn để che vấn đề.
