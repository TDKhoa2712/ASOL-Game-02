# 10 — CanDoKu: nguyên tắc suy luận và chứng minh

**Phiên bản tài liệu 1.0 · 2026-09-28.** Tài liệu nền cho thiết kế level, bộ giải theo cách con người, Hint và bộ kiểm chứng. Luật thắng vẫn do [GDD 02](02-luat-choi-va-trang-thai.md) quy định. Quy trình tạo nội dung và đo độ khó ở [GDD 11](11-sinh-level-va-danh-gia-do-kho.md).

“Đầy đủ” ở đây gồm mô hình toán, kỹ thuật cơ bản/nâng cao, điều kiện đúng, phản ví dụ, chứng cứ và phương pháp giải tổng quát. Không khẳng định một danh sách hữu hạn mẹo nhìn hình có thể giải mọi bàn. Phần mở rộng là đặc tả để phát triển sau; chưa được đưa vào schema hoặc runtime chỉ vì có mặt trong tài liệu.

## 1. Hợp đồng hiện hành và phần mở rộng

| Nhóm | Phạm vi | Trạng thái |
| --- | --- | --- |
| S1 | Loại theo kẹo đã biết | Nền của bộ tính ứng viên, không có step riêng trong trace v4 |
| S2 | Một ứng viên còn lại trong hàng/cột/vùng | Trace v4 hiện hành |
| S3 | Khóa giao thoa hai đơn vị | Trace v4 hiện hành; bắt buộc cần cho order 19–24 |
| S4 | Hai đơn vị khóa hai đơn vị | Nghiên cứu; giữ nghĩa của mã S4 cũ |
| S5 | Phản chứng ngắn | Nghiên cứu; giữ nghĩa của mã S5 cũ |
| X1–X4 | Vùng cấm chung, hỗ trợ, tập khóa tổng quát, sức chứa | Danh mục mở rộng, chưa có encoding v4 |
| CASE | Xét hết trường hợp và chuỗi mệnh đề | Phương pháp nghiên cứu/chứng minh |
| EXACT | Duyệt nghiệm đầy đủ có giới hạn tài nguyên | Kiểm tồn tại/duy nhất; không dùng thay lời giải cho người chơi |

Baseline campaign: order 1–18 giải hoàn toàn bằng S1/S2, mỗi order 19–24 giải bằng S1/S2/S3 và closure chỉ S1/S2 không hoàn tất. Order 25–30 của playtest cần profile riêng nhưng vẫn chỉ dùng S1–S3. Không gắn S4/S5/X vào step mang tên S3 để qua validator. Tên kỹ thuật candy/TryCandy trong hệ thống hiện có mang nghĩa kẹo/tìm kẹo.

## 2. Mô hình toán chính xác

### 2.1. Biến và ràng buộc

Bàn N×N, ô q=(r,c), tọa độ tài liệu/JSON dùng **0-based**, UI cộng 1. Mỗi ô thuộc đúng một vùng liên thông 4 hướng. Có đúng N vùng, nhãn A..; bản đầu N=4–6, trần dữ liệu N=12.

Đặt x[q] ∈ {0,1}, bằng 1 khi ô chứa kẹo:

- Tổng x trong mỗi hàng bằng 1.
- Tổng x trong mỗi cột bằng 1.
- Tổng x trong mỗi vùng bằng 1.
- Hai ô khác nhau có max(|Δr|,|Δc|)=1 thì tổng x không quá 1.
- Given có x=1. Những ô đã chứng minh bị loại có x=0.

Hàng/cột đã cấm chạm cạnh và trùng hàng/cột ở mọi khoảng cách; điều kiện cuối bổ sung kề chéo. **Không có luật cấm toàn bộ đường chéo như quân hậu cờ vua.** Hai ô (0,0) và (2,2) không bị cấm chỉ vì cùng đường chéo.

Mô hình hoán vị tương đương: solution[r]=c, mỗi cột dùng một lần, các nhãn vùng tại (r,solution[r]) khác nhau, và |solution[r+1]−solution[r]|>1. Mô hình này phù hợp bộ đếm nghiệm độc lập.

### 2.2. Trạng thái tri thức

| Ký hiệu | Nghĩa |
| --- | --- |
| C | Tập toàn bộ N² ô |
| K | Kẹo đã biết chắc: givens và các kết luận đặt đã được chứng minh |
| E | Tập ô loại bằng chứng minh trước đó; không chứa ô trong K |
| conflict(a,b) | a≠b và cùng hàng, cột, vùng, hoặc chạm góc/cạnh |
| F(q) | Tập các ô xung đột với q |
| S1(K) | Hợp các F(q), q∈K |
| P | C \ (K ∪ E ∪ S1(K)); các vị trí kẹo chưa biết còn có thể xảy ra |
| U | Một đơn vị: hàng, cột hoặc vùng |
| P(U) | P ∩ U; chỉ suy luận “còn đúng một” khi U chưa có kẹo |

Đơn vị đã có kẹo không cần ứng viên nữa; P(U)=∅ ở đơn vị đó không phải mâu thuẫn. Đơn vị chưa có kẹo mà P(U)=∅ là mâu thuẫn. Các phần tử K phải đôi một không xung đột, nằm trong bàn và không thuộc E.

X thường là ghi chú có thể sai của người chơi. X đỏ là feedback thử sai nhưng chính sách Hint của game cũng không lấy nó làm tiền đề. **Không đưa X/X đỏ vào E.** Bộ suy luận không đọc solution để chọn kết luận; bộ chấm TryCandy có thể đọc solution theo luật gameplay.

“Không xung đột với kẹo hiện có” chỉ nghĩa là ứng viên, chưa chứng minh có kẹo. “Chưa tìm được mâu thuẫn” cũng không chứng minh ô đúng.

## 3. Chuẩn của một bước suy luận

Một bước gồm: quy tắc, trạng thái trước bước, tiền đề, đơn vị/ô liên quan, kết luận mới và lý do có thể trình bày. Mọi ô loại phải còn là ứng viên; mọi ô đặt phải chưa biết. Bước không thay đổi tri thức là no-op và không được đếm để tăng độ khó.

Chứng cứ phải đủ để checker dựng lại kết luận từ topology, K, E. Danh sách kết luận do generator đưa ra không tự là chứng cứ. Mọi tập hợp có thứ tự xuất ổn định; loại trùng; tọa độ đúng biên. Bằng chứng chỉ là lời văn “chắc chắn ở đây” không được nhận.

Phân biệt hai kiểm tra:

1. **Đúng về đáp án:** mọi nghiệm hoàn chỉnh hợp tiền đề đều thỏa kết luận.
2. **Đúng về kỹ thuật đã khai:** checker xác nhận đúng điều kiện cục bộ của S2/S3/... mà không nhìn đáp án.

Một bước loại đúng ngẫu nhiên theo nghiệm duy nhất vẫn bị từ chối nếu chứng cứ S3 sai. Nghiệm duy nhất là cổng nội dung; không được dùng câu “vì chỉ có một nghiệm” làm Hint.

## 4. S1 — Loại trừ trực tiếp

**Điều kiện:** q∈K. **Kết luận:** mọi ô t∈F(q) không có kẹo. Mỗi ô bị loại lưu ít nhất một chứng cứ (q, quan hệ hàng/cột/vùng/kề chéo). Nếu có nhiều chứng cứ, ưu tiên lời giải thích ngắn và ổn định.

Ví dụ q=(1,3): loại các ô khác hàng 1, cột 3, vùng chứa q và các ô kề chéo (0,2),(0,4),(2,2),(2,4) trong bàn. Không loại (3,5) chỉ vì nằm trên đường chéo kéo dài.

**Chứng minh:** đặt thêm kẹo tại một ô đó vi phạm trực tiếp ít nhất một luật GR-01..04. S1 được tính lại sau mỗi lần K tăng. Không tự ghi X vào board người chơi; đây là trạng thái solver.

**Câu Hint:** “Hàng 2 đã có kẹo, nên những ô còn lại của hàng này không có kẹo.”

## 5. S2 — Ứng viên đơn

**Điều kiện:** U chưa có kẹo và P(U)={q}. **Kết luận:** q∈K.

Gồm ba cách nhìn cùng một quy tắc: ô cuối của hàng, ô cuối của cột, ô cuối của vùng. Vùng chỉ có một ô là S2 từ cấu trúc ngay lúc đầu. Sau một kết luận, dựng lại S1/P trước khi áp bước kế.

**Chứng minh:** U cần đúng một kẹo; tất cả vị trí khác đã bị loại bằng luật/chứng minh, nên q bắt buộc.

**Phản ví dụ:** người chơi tự đánh X ở tất cả ô của U trừ q. Nếu solver vẫn thấy nhiều ứng viên thì không được đặt q. U đã có given cũng không được đặt thêm một viên do nhìn thấy “một ô trống”.

**Câu Hint:** “Luống A chỉ còn ô hàng 1, cột 2 có thể có kẹo.”

Nếu cùng một ô là single của hàng và vùng, đây là **một hành động đặt**, không phải hai bước khó. Giữ nhiều cách giải thích như lựa chọn chứng cứ, không cộng hai lần vào độ khó.

## 6. S3 — Khóa giao thoa

**Điều kiện:** source U và target V chưa có kẹo, khác loại đơn vị; P(U)≠∅ và P(U)⊆V. **Kết luận:** loại toàn bộ P(V)\U; tập này phải khác rỗng.

Thường gặp: vùng→hàng, vùng→cột, hàng→vùng, cột→vùng. Hàng→cột/cột→hàng chỉ còn một ô giao, thường đã có S2; Hint ưu tiên S2.

**Chứng minh:** viên kẹo duy nhất của U chắc chắn nằm trong V. V cũng chỉ có một kẹo, nên phần V ngoài U không thể có thêm viên khác.

**Ví dụ tập ứng viên:** P(A)={(2,1),(2,3)}; hàng 2 còn thêm (2,5) ngoài A. Loại (2,5), chưa biết chọn (2,1) hay (2,3).

**Phản ví dụ:** A còn (3,4) thì không được khóa A vào hàng 2. Nhìn hình vùng giao hàng chưa đủ; phải kiểm mọi ứng viên hiện tại. P(A)=∅ là mâu thuẫn, không phải tập con hợp lệ để dùng S3.

**Chứng cứ:** source, target, tập ứng viên source dựng lại được, toàn bộ tập loại mới và căn cứ của các loại trừ trước đó. Schema v4 yêu cầu conclusion chứa đủ tập loại, không thiếu/thừa/no-op.

**Câu Hint:** “Kẹo luống A chỉ có thể ở hàng 3. Vì vậy, những ô hàng 3 ngoài luống A không có kẹo.”

## 7. Ví dụ trọn bàn có trace hiện hành

Ví dụ dùng fixture gốc **S301** trong [levels.sample.json](data/levels.sample.json), không phải level phát hành và không dùng lại để tăng số lượng campaign.

```text
    c0 c1 c2 c3
r0   A  A  B  B
r1   C  C  C  B
r2   C  C  D  D
r3   D  D  D  D
givens = []
```

| Bước | Chứng cứ | Kết luận |
| --- | --- | --- |
| 1 — S3 | Toàn bộ luống A nằm trên hàng 0 | Loại (0,2),(0,3) thuộc B |
| 2 — S2 | B chỉ còn (1,3) | Tìm kẹo (1,3) |
| 3 — S2 | Cột 2: (0,2) đã loại; (1,2) cùng hàng kẹo; (2,2) kề chéo kẹo | Tìm kẹo (3,2) |
| 4 — S2 | C chỉ còn (2,0) sau loại theo hai viên đã biết | Tìm kẹo (2,0) |
| 5 — S2 | A: (0,0) cùng cột viên (2,0), còn (0,1) | Tìm kẹo (0,1) |

Nghiệm cuối [1,3,0,2]. Ban đầu không hàng/cột/vùng nào có một ứng viên, nên S2-only bị kẹt ngay. Đếm nghiệm độc lập vẫn cần thiết, không suy ra uniqueness chỉ vì tác giả viết một trace.

Encoding bước đầu đúng schema v4:

```json
{"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"}
```

Bước S2 tiếp theo:

```json
{"rule":"S2","focus":{"type":"region","id":"B"},"conclusion":{"type":"place","r":1,"c":3},"textKey":"hint.single.region"}
```

## 8. S4 — Hai đơn vị khóa hai đơn vị

**Chưa thuộc v4.** Chọn U1,U2 khác nhau trong cùng một loại (do đó rời nhau), V1,V2 khác nhau trong một loại khác; cả bốn đơn vị chưa có kẹo.

Điều kiện: mỗi P(Ui) khác rỗng; P(U1)∪P(U2)⊆V1∪V2; đồ thị Ui→Vj có cạnh khi P(Ui)∩Vj≠∅ phải có ghép một-một phủ cả hai nguồn. Loại toàn bộ P(V1∪V2)\(U1∪U2), nếu có ô mới.

**Chứng minh:** hai nguồn cần hai viên khác nhau, hai đích chỉ chứa được hai viên; tất cả sức chứa đích dành cho nguồn. Matching là kiểm cần cho tiền đề, không chứng minh toàn bàn có nghiệm vì chưa xét hết xung đột giữa ô.

Ví dụ trừu tượng: vùng A và B chỉ còn ứng viên trên hàng 1,2, mỗi vùng có thể dùng cả hai hàng; loại ứng viên của vùng khác trên hai hàng này. Không được kết luận A thuộc hàng 1 và B thuộc hàng 2.

Phản ví dụ: A còn ứng viên hàng 3; hoặc chọn U1 là hàng 1 và U2 là vùng A có giao nhau rồi mặc định chúng cần hai viên khác nhau. Một viên ở giao có thể đáp ứng cả hai đơn vị, nên cách đếm đó sai. Nếu hai nguồn chỉ có thể dùng cùng một đích, tiền đề mâu thuẫn, không phát Hint loại như trường hợp hợp lệ.

Chứng cứ phải liệt kê nguồn/đích, ứng viên, matching kiểm được và tập loại. Chỉ bật sau khi có encoding, checker, fixture dương/âm và Hint tương ứng.

## 9. X1 — Vùng cấm chung của mọi vị trí trong một đơn vị

U chưa có kẹo, P(U)≠∅. Mọi ô t∈P\U mà t thuộc **giao** F(p) với tất cả p∈P(U) đều bị loại:

```text
remove = (P \ U) ∩ ⋂[p ∈ P(U)] F(p)
```

**Chứng minh:** U phải chọn một p, và bất kể chọn p nào đều xung đột với t. Không cần biết p cụ thể.

Ví dụ hình học trừu tượng: P(U)={(2,2),(2,3)}. Ô (1,2) ngoài U chạm cả hai, nên bị loại. Nếu U còn (4,4) không xung đột (1,2), kết luận này mất hiệu lực. Đừng dùng **hợp** vùng cấm: t phải bị cấm trong mọi trường hợp, không chỉ một trường hợp.

S3 là một trường hợp dễ giải thích của vùng cấm chung theo hàng/cột/vùng. X1 mở rộng sang các tổ hợp quan hệ, đặc biệt không-chạm; chưa được ngầm thêm vào solver MVP. Câu Hint phải nêu cả hai khả năng và lý do chúng đều loại cùng ô.

## 10. X2 — Ứng viên không có hỗ trợ

Xét một ứng viên q và đơn vị U chưa có kẹo, q∉U. Hỗ trợ của q trong U là:

```text
support(q,U) = {p ∈ P(U) : not conflict(q,p)}
```

Nếu support(q,U)=∅, loại q: giả sử q đúng thì U không còn vị trí. Đây là cách tìm cùng kết luận X1 từ góc nhìn ô bị loại; **không đếm thành hai kỹ thuật độc lập hoặc hai bước** nếu chứng cứ tương đương.

Có thể mở rộng sang hỗ trợ ở hai đơn vị rời nhau: với q giả định, không tồn tại cặp p1∈P(U1), p2∈P(U2) tương thích với q và với nhau thì loại q. Phải duyệt hết mọi cặp trong miền; một cặp thất bại không đủ. Kết quả search timeout là chưa biết.

Đây là mức kiểm nhất quán cục bộ, không phải nhìn solution. Lưu bảng các hỗ trợ bị bác bỏ và quan hệ xung đột; nếu chứng cứ quá dài thì giữ cho công cụ nghiên cứu, không xuất thành Hint bản đầu.

## 11. X3 — Tập khóa k đơn vị và Hall/matching

Tổng quát S4: k nguồn rời nhau cùng loại cần k viên; hợp ứng viên của chúng nằm trong k đích rời nhau cùng loại khác. Mọi nguồn/đích phải chưa có kẹo và mọi nguồn còn ít nhất một ứng viên. Khi có matching phủ nguồn, k đích bị chiếm hết; loại ứng viên trong hợp đích nhưng ngoài hợp nguồn.

Nếu hợp các đích có ứng viên chỉ gồm ít hơn k đơn vị, tiền đề không thể hoàn tất. Đây là phát hiện thiếu sức chứa. Kiểm mọi tập con nguồn mới phát hiện được toàn bộ vi phạm Hall của đồ thị hai phía, không chỉ so tổng số nguồn và đích.

Ví dụ: ba vùng chỉ có thể dùng ba cột → các ô thuộc vùng khác trong ba cột bị loại. Phản ví dụ: ba vùng còn một ứng viên ở cột thứ tư thì chưa được khóa ba cột. Có matching không chứng minh các ô ghép cuối cùng không chạm nhau hoặc thỏa nhóm đơn vị thứ ba.

Giới hạn nghiên cứu khởi đầu k≤3 để Hint còn đọc được. k lớn không tự đồng nghĩa level hay; ghi kích thước chứng cứ và số đơn vị cần giữ trong trí nhớ. Không lấy kết quả lọc all-different đầy đủ làm một bước S3 ngụy trang.

## 12. X4 — Sức chứa theo không-chạm và tập ô

Một tập ô T có sức chứa cap(T) là số kẹo lớn nhất có thể cùng đặt trong T theo các quan hệ xung đột đang xét. Có thể dùng **cận trên đã chứng minh** thay giá trị tối ưu, nhưng không dùng ước lượng thấp thiếu chứng minh.

- Bốn ô của một khối 2×2 đôi một chạm nhau, nên chứa nhiều nhất một kẹo.
- Các ứng viên cùng hàng/cột/vùng cũng có sức chứa tối đa một.
- Nếu k đơn vị nguồn rời nhau có mọi ứng viên nằm trong T mà cap(T)<k, trạng thái vô nghiệm.
- Nếu cần k viên trong T và T được phủ bởi đúng k nhóm đôi một xung đột nội bộ, mỗi nhóm có thể chứa tối đa một viên. Để nói “mỗi nhóm có đúng một viên”, cần các nhóm **phân hoạch rời nhau** của T và chứng minh nhu cầu chính xác k; nhóm chồng lấn không được cộng trực tiếp.

Một khối 2×2 có sức chứa 1 **không có nghĩa** nó bắt buộc chứa một kẹo. Không suy luận từ diện tích vùng, số ô chẵn/lẻ hoặc màu trang trí. Muốn loại ô bên ngoài từ saturation cần chứng minh kết luận dưới mọi cách lấp hợp lệ; nên biên dịch thành X1, S4/X3 hoặc xét trường hợp có checker, không dùng từ “đầy” thay chứng cứ.

## 13. S5 — Phản chứng ngắn

Chưa thuộc v4. Giả định q có kẹo trong bản sao trạng thái. Áp S1 tự động và tối đa **ba bước tường minh S2/S3/S4**, không lồng S5. Phát hiện một trong các mâu thuẫn:

- Hai viên trong K xung đột.
- Một đơn vị chưa có kẹo không còn ứng viên.
- Một ô vừa bắt buộc có kẹo vừa được chứng minh không có.

Khi nhánh mâu thuẫn, loại q khỏi trạng thái thật. Nếu dừng do giới hạn hoặc không thấy mâu thuẫn, trả UNKNOWN, không loại q. Không được dùng việc nhánh khác dẫn tới solution làm lý do bác q.

Ví dụ dạng chứng cứ: giả q → S1 làm vùng B chỉ còn p → S2 đặt p → S1 của p loại mọi ứng viên vùng C → q sai. Đây là ví dụ cấu trúc; cần bàn cụ thể và checker trước khi tạo fixture.

Trạng thái K/E, Undo, tim, score, Hint và session thật không bị nhánh tạm tác động. Chứng cứ phải ghi giả định, bước tuần tự và đơn vị mâu thuẫn. Nâng giới hạn hoặc dùng X trong nhánh cần phiên bản ruleset nghiên cứu riêng.

## 14. CASE — Xét hết trường hợp và chuỗi

Nếu U còn đúng {a,b}, mệnh đề là a hoặc b và không đồng thời cả hai. Chứng minh cùng kết luận L trong cả nhánh a và nhánh b thì L đúng ở trạng thái cha. Với hơn hai ứng viên phải xét **tất cả**, hoặc chứng minh những nhánh còn lại bất khả thi.

Các mắt xích cơ bản: q đúng → mọi ô xung đột sai; trong một đơn vị còn hai ứng viên, một ô sai → ô kia đúng. Một chuỗi chỉ đúng khi từng cạnh có nguồn và trạng thái tiền đề hợp lệ. Không ghép các kết luận từ hai nhánh đối nghịch thành một trạng thái chung.

Nếu một nhánh bị bác, nhánh còn lại chỉ bắt buộc khi các lựa chọn đã được chứng minh đầy đủ. Không coi nhánh timeout là nhánh bị bác. CASE tổng quát và chuỗi dài chưa dùng làm Hint/campaign đầu; ghi độ sâu, số nhánh, lượng chứng cứ trước khi đánh giá khả năng đọc.

## 15. EXACT — Phương pháp tổng quát và giới hạn “đầy đủ”

Một bộ duyệt đầy đủ có thể chọn lần lượt cột của từng hàng, cấm cột/vùng đã dùng và chạm với hàng trước, ràng buộc given; quay lui khi vi phạm. Không đọc solution khai báo. Lưu tối đa hai nghiệm:

| Kết quả | Diễn giải |
| --- | --- |
| Duyệt hết, 0 nghiệm | INVALID |
| Duyệt hết, 1 nghiệm | UNIQUE |
| Tìm được nghiệm thứ hai | MULTIPLE, dừng sớm được |
| Hết thời gian/nút trước khi chứng minh | UNKNOWN, kể cả đã thấy một nghiệm |

Đây là thuật toán đầy đủ trên miền hữu hạn **khi được chạy đến hết**, không là bảo đảm hoàn tất trong ngân sách. Để kiểm một kết luận, có thể thêm phủ định của kết luận rồi chứng minh vô nghiệm. Công cụ này là oracle kiểm tính đúng; search tree dài không tự trở thành lời giải người chơi.

Phân biệt: bộ kỹ thuật cho phép có thể bị kẹt trên một bàn UNIQUE; đó là “chưa giải bằng ruleset này”, không phải “bàn cần đoán trong mọi hệ suy luận”. Không nhập các chiến thuật Sudoku số, chẵn/lẻ, hình chữ nhật độc nhất hoặc quy tắc Star Battle nhiều sao mà chưa chứng minh lại cho luật một kẹo CanDoKu.

## 16. Bộ giải logic, closure và chứng minh kỹ thuật cần thiết

```text
K = givens; E = {}
repeat:
    dựng S1 và P; kiểm bất biến
    nếu |K| = N: SOLVED
    liệt kê mọi kết luận hợp lệ bằng ruleset cho phép
    nếu không có: STUCK
    chọn kết luận theo policy đã version hóa
    checker độc lập xác nhận; ghi chứng cứ; cập nhật K hoặc E
until budget exceeded -> UNKNOWN
```

**Closure S2:** lặp S1/S2 tới khi hết single. **Closure S2/S3:** lặp các kết luận S2 và loại S3 tới điểm cố định. Với các luật đơn điệu này, loại/đặt hợp lệ không làm mất nghiệm; phải duyệt đủ các đơn vị để dùng STUCK như bằng chứng không có bước trong ruleset. Một policy bỏ qua đơn vị không được dùng để chứng minh kỹ thuật cao là bắt buộc.

Order 19–24 cần cả hai: S2-only STUCK (không timeout), và trace S2/S3 SOLVED. Trace có một S3 dư trong bàn S2-only vẫn giải được không chứng minh cần S3.

Trong bộ nghiên cứu, so các ruleset lồng nhau để tìm mức thấp nhất giải được; nếu bị timeout, báo khoảng chưa biết. Không gọi “tối thiểu” chỉ vì một đường đi tìm được dùng ít bước.

## 17. Hợp đồng trace, Hint và chứng cứ mở rộng

Schema v4 chỉ có S2/S3 như ví dụ §7. S1 được dựng lại. Không thêm fields vào level JSON để chứa trạng thái nghiên cứu vì validator từ chối trường lạ.

Sidecar nghiên cứu riêng có thể ghi ruleCatalogVersion, stateHash trước/sau, stepId, premiseStepIds, source/target, candidates, conclusion và nhánh/mâu thuẫn. Đây là đề xuất cho công cụ tương lai, không thay schema runtime. Hash chứng cứ bao gồm topology, givens, K/E và ruleset version, không dựa nhãn difficulty hoặc câu văn.

Hint từ board hiện tại dựng lại K từ given + kẹo đúng; E khởi tạo lại rồi suy ra bằng luật, không đọc X/X đỏ và không chạy con trỏ trace cũ. Chọn S2 trực tiếp trước, sau đó chuỗi S3→S2 ngắn, dễ trình bày. Nếu chỉ có bước loại S3 hữu ích, có thể giải thích bước đó theo GDD 04; không tự điền board.

Giải thích có ba phần: **điều đã biết → luật liên quan → kết luận**. Mọi tọa độ UI cộng 1, “region” đọc là “luống”. Nếu ô đích có X thường, nhắc chạm đôi để tìm kẹo; không đề nghị xóa X đỏ.

## 18. Kiểm chứng kỹ thuật suy luận

| Nhóm kiểm | Điều kiện |
| --- | --- |
| Dương | Có bàn/trạng thái đầy đủ và kết luận checker chấp nhận |
| Âm | Thêm ứng viên phá khóa, bỏ tiền đề, trùng/thiếu/thừa ô kết luận, sai loại đơn vị → từ chối |
| No-op | Không đếm bước không tạo tri thức mới |
| Metamorphic | Xoay/lật/đổi nhãn vùng giữ tính hợp lệ; biến đổi cả given/kết luận/chứng cứ |
| Oracle độc lập | Trên bàn nhỏ, mọi nghiệm phù hợp tiền đề đều thỏa kết luận; tiền đề vô nghiệm không được dùng để hợp thức hóa mọi kết luận |
| State isolation | Thử S5/CASE không rò trạng thái sang nhánh khác hoặc session |
| No-answer-leak | Đổi trường solution trong bản sao không làm bộ logic đổi kết luận; validator vẫn phải bác solution khai sai |
| Hint | Khác X/X đỏ nhưng cùng K phải cho cùng tập suy luận hợp lệ; tìm đúng khác thứ tự vẫn dựng chứng cứ hiện tại |
| Budget | Timeout trả UNKNOWN; không sinh PASS hoặc nhãn “cần kỹ thuật cao hơn” |
| Tương thích | V4 bác S4/S5/X/CASE; chỉ bật sau khi schema/checker/runtime/QA cùng hỗ trợ |

Giữ QA-37/40/41/57 cho S3 hiện hành; QA-38/39/42 là cổng nghiên cứu cũ. Đặc tả này chưa chứng nhận các luật mở rộng đã được code hoặc benchmark.

## 19. Nguồn và cách sử dụng

- [Régin, A Filtering Algorithm for Constraints of Difference in CSPs, AAAI 1994](https://cdn.aaai.org/AAAI/1994/AAAI94-055.pdf): tham khảo học thuật cho all-different/matching. Các tiền đề S4/X3 ở đây được trình bày riêng cho CanDoKu; không nhập nguyên thuật toán thành một Hint.
- [Espasa và cộng sự, Towards Generic Explanations for Pen and Paper Puzzles with MUSes, 2021](https://ceur-ws.org/Vol-2894/short8.pdf): phân biệt giải được với giải thích được; tham khảo thiết kế chứng cứ ngắn.
- [GDD 02](02-luat-choi-va-trang-thai.md), [GDD 04](04-thiet-ke-level.md), [GDD 05](05-kien-truc-va-du-lieu.md): luật, cổng nội dung và schema dự án.

Không dùng level, screenshot hoặc đáp án của game thương mại làm đầu vào sinh. Các ví dụ tập ứng viên X/S4 chỉ minh họa logic cục bộ, không được tính là level đã duyệt.
