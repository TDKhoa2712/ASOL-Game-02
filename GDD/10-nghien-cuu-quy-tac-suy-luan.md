# 10 — S3 cho MVP và nghiên cứu S4–S5

**Trạng thái:** S3 là **ACTIVE-MVP** cho từng level order 19–24; schema v4 và validator chấp nhận trace S2/S3. Level 1–18 không dùng S3. S4/S5 vẫn là `PARKED-RESEARCH` và không thuộc release. Luật GR tại [02](02-luat-choi-va-trang-thai.md) là nguồn chuẩn; nội dung S3 chỉ được phát hành sau khi validator, runtime Hint, fixture, QA và playtest M2 cùng đạt cổng.

## 1. Mục tiêu và nguyên tắc

S3 tạo bước suy luận giao thoa mà người chơi có thể nhìn và hiểu, đồng thời là dependency bắt buộc của chặng cuối MVP. S4 mở rộng thành một cặp khóa. S5 chỉ là hướng nghiên cứu cho level khó sau này vì lời giải thích phản chứng dài dễ biến Hint thành màn hình đọc chứng minh. Thứ tự ưu tiên: **ổn định S3 MVP → nghiên cứu S4 → cân nhắc S5**; mỗi kỹ thuật mới vẫn cần fixture, validator, Hint và playtest trước khi dùng trong nội dung phát hành.

Mô hình nền là mỗi hàng, cột và vùng chứa đúng một mèo, còn các cặp mèo không được kề chéo theo GR-01..04. Đây là dạng ràng buộc số lượng và khác nhau; [nghiên cứu gốc của Régin về `alldifferent`](https://s.aaai.org/Library/AAAI/1994/aaai94-055.php) là cơ sở cho ý tưởng nhóm ứng viên khóa, còn [nghiên cứu Demystify về lời giải thích Star Battle](https://ceur-ws.org/Vol-2894/short8.pdf) cho thấy cần phân biệt suy ra một nước đi với *giải thích được* nước đi ấy. Các công thức S3–S5 dưới đây được suy ra riêng cho luật Vườn Mèo, không chép level hay lời giải của trò khác.

## 2. Ký hiệu và bất biến của bộ suy luận

- `C` là tập N² ô. `U` là một đơn vị: một hàng, một cột hoặc một vùng. Mỗi `U` chứa đúng một mèo theo luật.
- `K` là các mèo đã biết chắc: given và cat đúng đã đặt. Trong validator trace, `K` bắt đầu từ givens rồi nhận các kết luận S2 đã chứng minh.
- `E` là tập ô **bị loại theo chứng minh** từ các bước S3/S4/S5 trước đó. `E` chỉ sống trong trạng thái solver và trace; không phải trạng thái ô thứ năm, không đồng nghĩa X hoặc `x_error` của người chơi.
- `S1(K)` gồm mọi ô khác bị loại bởi một mèo trong `K` vì cùng hàng, cột, vùng hoặc kề chéo. `P = C \ (K ∪ S1(K) ∪ E)` là tập ứng viên còn lại. Với đơn vị chưa có mèo `U`, đặt `P(U) = P ∩ U`.
- Trước và sau mọi bước trace, mọi đơn vị chưa có mèo phải có ít nhất một ứng viên; các mèo trong `K` không xung đột; `E ∩ K = ∅`. Bất biến này phát hiện trace sai hoặc level không nhất quán, không cho phép suy luận từ tiền đề rỗng.

X và X đỏ là ghi chú/đánh dấu thao tác, **không** là tiền đề logic. Riêng X đỏ bị khóa theo quyết định `REV-GD-01`; nó vẫn không trở thành chứng cứ để solver/hint loại thêm ô. `solution` chỉ dùng kiểm nghiệm và đếm nghiệm độc lập; không được dùng để xác nhận một bước suy luận.

## 3. S3 — khóa giao thoa hai đơn vị

Chọn hai đơn vị chưa có mèo, khác loại, `U` (nguồn) và `V` (đích). Điều kiện:

```text
P(U) ≠ ∅  và  P(U) ⊆ V.
```

Vì mèo duy nhất của `U` phải nằm trong `V`, nó cũng là mèo duy nhất của `V`. Do đó loại **toàn bộ** `P(V) \ U` khỏi ứng viên. Bước S3 hợp lệ trong trace chỉ khi tập ô mới bị loại khác rỗng. Hướng thường dễ giải thích là vùng → hàng/cột; chiều ngược lại cũng đúng nếu điều kiện tập hợp thỏa. Không đủ nếu vùng *chỉ có vài ô hình học* giao với hàng: mọi ứng viên còn lại của vùng phải ở hàng ấy.

**Ví dụ dương ở mức tập ứng viên:** vùng A chưa có mèo chỉ còn `(2,1)` và `(2,3)`, đều thuộc hàng 2. Hàng 2 còn ứng viên `(2,1)`, `(2,3)`, `(2,5)`. S3 loại `(2,5)`; không khẳng định mèo A ở `(2,1)` hay `(2,3)`. Nếu sau đó một đơn vị khác chỉ còn `(2,5)`, dữ liệu tiền đề đã mâu thuẫn và không được dùng ví dụ này làm fixture level.

**Phản ví dụ:** A còn `(2,1)` và `(3,4)`. Dù A giao hàng 2 ở `(2,1)`, mèo A có thể ở `(3,4)`, nên không được loại `(2,5)` của hàng 2. Validator phải kiểm `P(A) ⊆ hàng 2` từ trạng thái hiện tại, không tin metadata “intersection” của người biên tập.

## 4. S4 — cặp đơn vị khóa hai đơn vị

Chọn `U1,U2` là hai đơn vị chưa có mèo, khác nhau **trong cùng một loại** (chẳng hạn hai vùng). Chọn `V1,V2` là hai đơn vị chưa có mèo, khác nhau trong cùng một loại khác (chẳng hạn hai hàng). Điều kiện:

```text
P(U1) ∪ P(U2) ⊆ V1 ∪ V2,
và tồn tại một ghép một-một khả thi U1,U2 → V1,V2 theo các ứng viên.
```

Hai mèo nguồn phải khác nhau vì `U1,U2` rời nhau. Mỗi `V` chứa nhiều nhất một mèo, nên hai mèo ấy chiếm hết `V1,V2`. Loại toàn bộ `P(V1 ∪ V2) \ (U1 ∪ U2)`. Điều kiện ghép một-một giúp loại trường hợp tiền đề vốn vô nghiệm; nó có thể kiểm bằng tối đa hai hoán vị, chưa cần thư viện matching. Không suy ra vị trí chính xác hay mèo của `U1` thuộc `V1` nào. Đây là cặp khóa theo nguyên lý tập con của ràng buộc `alldifferent`, giới hạn hai nguồn để hint còn ngắn.

**Ví dụ dương:** A còn `(1,0),(2,0)`, B còn `(1,4),(2,4)`; hai vùng là nguồn, hai hàng 1 và 2 là đích. Nếu hàng 1 còn `(1,5)` ngoài A/B, loại `(1,5)`; tương tự hàng 2. Đây là minh họa tập ứng viên, không phải fixture phát hành và chưa chứng minh có thể nhúng vào một level hợp lệ, liên thông, nghiệm duy nhất.

**Phản ví dụ:** B còn thêm `(3,4)`. Khi đó một mèo nguồn có thể ở hàng 3, nên không được loại `(1,5)`. Phản ví dụ khác: cả A và B chỉ còn ứng viên trong hàng 1; không có ghép một-một với hàng 1/2, phải báo mâu thuẫn, không tạo hint S4.

## 5. S5 — phản chứng ngắn, hoãn kích hoạt

Giả sử một ứng viên chưa biết `q` là mèo trong một nhánh tạm. Chạy tối đa **ba** bước suy luận đã được kiểm riêng (S1 là loại trừ tự động; bước trace nhánh cho phép S2/S3/S4). Nếu nhánh dẫn tới một đơn vị chưa có mèo nhưng `P(U)=∅`, hoặc hai mèo đã biết xung đột trực tiếp, thì giả thiết sai: thêm `q` vào `E` ở nhánh thật. Không được dùng “solver chỉ tìm ra một nghiệm khác” hoặc `solution[q]=false` làm phản chứng. Phải lưu cây chứng cứ tuần tự đủ để người đọc lần theo.

**Ví dụ trừu tượng:** giả sử `q`; S1 của `q` loại `u`, làm vùng B chỉ còn `v`; S2 buộc `v`; S1 của `v` loại hết ứng viên của vùng C. Kết luận `q` không thể là mèo. Ví dụ này chỉ mô tả dạng chứng cứ; fixture dương phải là một bàn hoàn chỉnh, nơi validator độc lập xác nhận mọi tọa độ và bước nhánh.

**Phản ví dụ:** nhánh giả sử `q` còn ít nhất một nghiệm phù hợp luật thì tuyệt đối không loại `q`, kể cả khi nghiệm ấy khác `solution` khai báo hoặc khác hướng giải thích của biên tập viên. Nếu nhánh chạm giới hạn bước/thời gian mà chưa có mâu thuẫn, kết quả là “chưa chứng minh”, không phải “sai”.

S5 có nguy cơ thành một cách đoán được ngụy trang. Chỉ nghiên cứu sau khi S3/S4 có mẫu hint đọc tốt trên điện thoại và playtest cho thấy người chơi hiểu được chuỗi tối đa ba bước. Có thể dùng solver đầy đủ làm *oracle kiểm thử độc lập* cho kết luận, nhưng bằng chứng hiển thị vẫn phải là nhánh cục bộ kể trên.

## 6. Proof trace v4 và cách validator kiểm

Schema v4 chốt S3 bằng `source`, `target`, tọa độ object và tập loại đầy đủ. Đây là hợp đồng dữ liệu chính thức:

```json
{"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"}
```

S4/S5 dưới đây chỉ là hình dạng nghiên cứu, không phải hợp đồng schema v4 và không được nạp vào level MVP:

```json
{"rule":"S4","sources":[{"type":"region","id":"A"},{"type":"region","id":"B"}],"targets":[{"type":"row","id":1},{"type":"row","id":2}],"conclusion":{"type":"eliminate","cells":[[1,5],[2,5]]},"textKey":"hint.lock.pair"}
{"rule":"S5","assume":[1,3],"branchTrace":[{"rule":"S2","focus":{"type":"region","id":"B"},"conclusion":{"type":"place","r":2,"c":4}}],"contradiction":{"type":"emptyUnit","unit":{"type":"region","id":"C"}},"conclusion":{"type":"eliminate","cells":[[1,3]]},"textKey":"hint.short.contradiction"}
```

Validator S3 phải làm tuần tự; các bước S4/S5 dưới đây chỉ áp dụng khi có schema tương lai riêng:

1. Dựng `K` từ givens, `E=∅`, tính S1 từ luật và topology; không đọc X/X đỏ hay `solution` để tính ứng viên.
2. Với mỗi S3/S4, kiểm loại đơn vị, tình trạng chưa có mèo, điều kiện tập hợp và ghép cặp; tự tính **tập ô mới bị loại đầy đủ**, so đúng với `conclusion.cells` đã sắp thứ tự, cấm no-op và trùng lặp.
3. Với mỗi S5, clone `K,E`, thêm giả thiết `q`, kiểm từng bước nhánh theo cùng bộ quy tắc, xác nhận mâu thuẫn được nêu trong giới hạn độ sâu. Chỉ thêm `q` vào `E` của nhánh thật; không để rò các loại trừ tạm.
4. Với mỗi S2, dựng lại `P(focus)` sau S1 và `E`, yêu cầu đúng một ứng viên, rồi thêm mèo vào `K`. Kiểm kết luận không trùng/khác given và không xung đột.
5. Kết thúc phải đủ N mèo. Bộ đếm nghiệm độc lập vẫn xác nhận nghiệm duy nhất nhưng không thay thế proof trace.

Một phép kiểm phụ dùng brute force trên bàn nhỏ: với mọi bước loại ô, mọi hoàn chỉnh hợp luật từ *trạng thái trước bước* phải để ô đó trống. Kiểm này bắt lỗi hiện thực hóa, nhưng phép kiểm chính vẫn là tiền đề cục bộ, vì nghiệm duy nhất có thể khiến một bước suy luận không hợp lệ trông như đúng.

## 7. Hợp đồng hint và thứ tự giải thích

Hint runtime MVP khởi tạo từ given + cat đúng hiện có, tính lại S1/S2/S3 trên trạng thái ấy; không dùng con trỏ trace và không lấy X/X đỏ làm sự thật. Ưu tiên **S2 trực tiếp**, rồi chuỗi ngắn **S3 → S2**. Trong cùng cấp, chọn chuỗi ít ô/đơn vị cần tô sáng nhất, rồi phá hòa theo `(loại đơn vị, id, tọa độ)` để kết quả ổn định. Một Hint có thể hiển thị bước loại trước và bước đặt sau trong hai khung nối tiếp, nhưng không tự ghi X hay đặt mèo. Evidence hợp lệ tiêu thụ Hint duy nhất của lượt; `NoHint` không tiêu thụ.

Nếu chuỗi chưa đưa tới một vị trí mèo, chỉ trình bày một bước loại có ích cùng các ô liên quan; nghiên cứu UX xem người chơi có hiểu và tự ghi X được không. Với S3, câu mẫu: “Mèo vùng A chỉ có thể ở hàng 3, nên các ô còn lại của hàng 3 ngoài vùng A không có mèo.” Với S4: “Hai mèo của A và B nằm trong hai hàng 2–3; hai hàng này không còn mèo ngoài A/B.” Với S5, chia lời giải thích thành giả sử → từng bước → mâu thuẫn → loại giả sử. Hàng/cột nói theo tọa độ UI 1-based. Khi X che ô kết luận đặt mèo, nhắc chạm đôi trực tiếp trên X; X đỏ không thể là ô nghiệm ở level hợp lệ. Không dùng ghi chú ấy làm lý do suy luận.

Không quảng cáo một level là “giải được bằng S3” nếu chỉ có thể suy ra bằng cách xem nghiệm, nếu hint cần quá nhiều khung, hoặc nếu người chơi thử mò mèo nhanh hơn hiểu lời giải. Độ khó nên đo từ đường chứng cứ ngắn nhất và playtest, không chỉ đếm số bước.

## 8. Fixture, QA và cổng quy tắc

| Mã QA đề xuất | Kiểm tra trước khi bật |
| --- | --- |
| QA-37 | Fixture S3 dương: có bước loại mới và S2 sau đó; đảo một ứng viên nguồn ra ngoài đơn vị đích thì validator từ chối; cùng dữ liệu với X/X đỏ khác nhau cho cùng hint. |
| QA-38 | Fixture S4 dương có ghép cặp và loại mới; thêm ứng viên vào đơn vị đích thứ ba hoặc làm mất ghép cặp thì từ chối. |
| QA-39 | Fixture S5 dương có nhánh ≤3 bước đến mâu thuẫn; thiếu bước, kết luận sai, nhánh còn nghiệm hoặc timeout đều từ chối; trạng thái nhánh không rò ra board thật. |
| QA-40 | Trace trộn S2/S3/S4 theo thứ tự bất kỳ nhưng hợp lệ được nhận; đảo bước làm tiền đề chưa có, no-op, ô loại trùng, dùng `solution` hoặc ghi chú làm chứng cứ đều bị chặn. |
| QA-41 | Hint khi người chơi đặt mèo đúng khác thứ tự trace vẫn có bằng chứng hiện hành; đọc được trên màn nhỏ, giảm chuyển động/trình đọc màn hình; hint không tự đặt mèo/X. |
| QA-42 | N=12: kiểm ngân sách solver, validator trace và hint trên thiết bị mục tiêu; timeout là thất bại/cần biên tập, không là nghiệm duy nhất hoặc bằng chứng hợp lệ. |

Lộ trình MVP: (1) schema v4 + fixture S301 dương/âm; (2) checker S3 và test no-op/tập loại/tiền đề; (3) runtime Hint S3 và accessibility; (4) tạo sáu level gốc 19–24 thực sự cần S3; (5) giải mù/playtest và chạy QA-37/40/41/57 trước M2. Sau MVP mới lặp quy trình riêng cho S4, rồi mới cân nhắc S5. Không được hạ yêu cầu S3 của 19–24 chỉ để đạt số lượng content.

## 9. Câu lệnh giao cho agent nghiên cứu tiếp

```text
Bạn là agent phụ trách quy tắc suy luận của Vườn Mèo. Đọc GDD/README.md,
02-luat-choi-va-trang-thai.md, 04-thiet-ke-level.md,
05-kien-truc-va-du-lieu.md, 07-kiem-thu-va-tieu-chi-nghiem-thu.md,
10-nghien-cuu-quy-tac-suy-luan.md và design-reviews/README.md.
Ổn định S3 MVP trước, sau đó nghiên cứu S4; chỉ nghiên cứu S5 khi có bằng chứng
Hint dễ hiểu. Với mỗi quy tắc mới, giao: (1) định nghĩa hình thức và phản ví dụ,
(2) proof trace tuần tự không dựa vào nghiệm/X/X đỏ, (3) fixture level gốc
dương/âm có nghiệm duy nhất và vùng liên thông, (4) validator và unit/property
tests, (5) hint có giải thích đọc được trên màn nhỏ và hỗ trợ accessibility,
(6) mã QA cùng kết quả đo. Không bật level phát hành dùng quy tắc mới trước khi
GDD, schema version, dữ liệu mẫu, validator, runtime hint và QA được cập nhật
đồng bộ; chạy python GDD/tools/validate_levels.py GDD/data/levels.sample.json.
Nêu rõ giới hạn, timeout và các ca chưa chứng minh. Không sao chép level/asset
của game tham chiếu.
```
