# 02 — Luật chơi và trạng thái

Tài liệu này là nguồn chuẩn của CanDoKu. “Vùng” trong thuật toán tương ứng “luống” trong lời hướng dẫn; toàn bộ ô của một vùng có chung nhãn. Kẹo đã tìm được vẫn nằm trên ô đến hết màn, không rơi/di chuyển hoặc tự dọn ô khác.

Thuật ngữ chuẩn: `candy` là kẹo đã tìm thấy; `TryCandy` là hành động thử tìm kẹo; `CandyFound` là sự kiện tìm đúng. Không dùng alias chủ đề cũ trong API hiện hành. Tọa độ dữ liệu `(r,c)` dùng 0-based; UI đọc hàng/cột 1-based. Schema nhận N=4–12; bản đầu phát hành N=4–6.

## 1. Bàn và nghiệm

Lưới N×N có đúng N vùng, mỗi ô thuộc một vùng; vùng liên thông theo cạnh chung. `solution[r]=c` là kẹo của hàng r.

| ID | Luật | Kiểm tra |
| --- | --- | --- |
| GR-01 | Mỗi hàng đúng một kẹo | N phần tử trong `solution` |
| GR-02 | Mỗi cột đúng một kẹo | Hoán vị `0..N-1` |
| GR-03 | Mỗi vùng đúng một kẹo | Nhãn vùng của các ô nghiệm không lặp |
| GR-04 | Kẹo không chạm nhau kể cả góc | Hàng kề có `abs(solution[r]-solution[r+1]) > 1` |
| GR-05 | Đúng một nghiệm khi tính cả givens | Solver độc lập dừng ở nghiệm thứ hai; nghiệm duy nhất khớp JSON |
| GR-06 | Kẹo cho sẵn là candy cố định thuộc nghiệm | Không đổi trạng thái và không cho điểm |
| GR-07 | Level campaign có trace hợp lệ đến đủ N kẹo: order 1–18 chỉ S2; mỗi order 19–24 có ít nhất một bước S3 cần thiết; order 25–30 theo profile được duyệt và chỉ dùng S1–S3 | Từng bước S2/S3 chứng minh từ trạng thái trước; S3 không được là no-op hoặc thay được bằng closure S2 |
| GR-08 | X là ghi chú tự đặt; `x_error` là ghi chú đỏ tạo bởi lần thử kẹo sai | Cả hai không ràng buộc solver/hint hay điều kiện thắng |

Mọi ô `candy`, kể cả given, dùng cùng hình viên kẹo bọc giấy mặc định. Giấy gói không mã hóa đáp án hoặc vùng. Hàng tiến độ có N vị trí theo nhãn A..(N), dùng nền/viền/nhãn/họa tiết vùng và dấu đã tìm; given tính vào tiến độ nhưng không tính điểm. Màu không ảnh hưởng nghiệm.

## 2. Năm trạng thái và cử chỉ

Ô chưa cho sẵn chỉ có `empty`, `x`, `x_error`, `candy`, `locked`. `given` là cờ hiển thị candy từ level data, không phải trạng thái riêng. `locked` là auto-mark X do hệ thống đặt sau khi tìm đúng kẹo; player không xóa được; hiện X mờ. Kẹo đã tìm thấy và given đều cố định cho đến khi Retry/Restart. Không có công cụ ứng viên hoặc lựa chọn công cụ; Undo và Restart tuân theo GR-31..36.

| ID | Cử chỉ trên cùng một ô khi `Playing` | Kết quả |
| --- | --- | --- |
| GR-09 | Một chạm `empty` | `x` |
| GR-10 | Một chạm `x` | `empty` |
| GR-11 | Một chạm `candy`/given/`locked` | Không đổi; thông báo ngắn nếu cần |
| GR-12 | Hai chạm cùng ô `empty` hoặc `x` | Gọi đúng một `TryCandy` |
| GR-13 | Chạm hoặc kéo qua `x_error`, `candy`, given hoặc `locked` | Không đổi, không mất tim; `x_error` bị khóa trong lượt đến khi Retry/Restart |
| GR-14 | Chạm ở hai ô khác nhau | Hai cử chỉ đơn độc lập; không được nhận là một `TryCandy` |
| GR-29 | Giữ chạm rồi kéo từ `empty` | Đánh X tức thì trên ô đầu và từng ô `empty` đi qua; bỏ qua ô X, X đỏ và candy |
| GR-30 | Giữ chạm rồi kéo từ `x` | Xóa X tức thì trên ô đầu và từng ô `x` đi qua; bỏ qua ô empty, X đỏ và candy |
| GR-31 | `RestartLevel` khi `Playing` | Hiện xác nhận; nếu đồng ý, tạo lượt mới trên cùng level và reset board/tim/lỗi/scorecard/Hint/thời gian như Retry. Hủy xác nhận không đổi gì. |
| GR-32 | `UndoX` | Undo hoàn nguyên action gần nhất: một `MarkX`/`ClearX`/`MarkStroke`, hoặc toàn bộ group gồm `TryCandy` đúng + auto-marks phát sinh. Undo một bước, không Redo. |
| GR-33 | Vòng đời khe Undo | Mỗi action mới thay khe Undo. Grouped undo: candy + tất cả locked cells phát sinh là một undo group duy nhất. `TryCandy` sai, Restart, Retry, Won, Failed, Back To Home và đóng app xóa khe; Undo không được bỏ qua `TryCandy` để tìm action cũ. Khe Undo chỉ ở runtime và không lưu session. |

X đổi **trên hình ngay khi chạm xuống**. Nếu nhấc ngón mà không kéo, lớp cử chỉ mở cửa sổ chạm đôi **280 ms tính từ lần nhấc thứ nhất đến lần chạm xuống thứ hai**; hết cửa sổ thì commit một chạm. Nếu chạm thứ hai nhanh lên **cùng ô** và cũng không kéo, hoàn tác preview của chạm đầu rồi gửi đúng một `TryCandy` từ trạng thái đã commit trước đó. Nếu chạm ô khác, commit chạm đầu rồi mở cử chỉ mới. Hai chạm nhanh lên X cũng thử kẹo, không cần xóa X trước. Preview không lưu vào session và không được dùng để chấm thắng/thua.

Kéo chỉ được nhận khi ngón đầu di chuyển quá ngưỡng 12 điểm logic. Tại thời điểm đó, cử chỉ chuyển sang một nét X: chế độ đánh/xóa lấy từ **trạng thái ô đầu trước preview**, giữ nguyên đến khi nhấc ngón. Mỗi ô chỉ xử lý một lần trong một nét, kể cả đi ngược; đường đi nhanh phải nội suy qua các ô trung gian, không bỏ lỗ. Không nhận chạm đôi từ một nét kéo. Nét được commit thành một action khi nhấc ngón; preview từng ô vẫn hiện tức thì. Nếu chuyển màn/app vào nền **sau khi đã nhấc của chạm đơn đang chờ**, commit chạm đó rồi lưu; nếu vẫn đang giữ ngón hoặc kéo chưa nhấc, hủy preview chưa hoàn tất. Sau `Won`/`Failed` khóa input board. Trình đọc màn hình dùng action ngữ nghĩa “Đánh X/Xóa X” và “Tìm kẹo”, không phụ thuộc tốc độ chạm vật lý.

Undo hoàn nguyên đúng diff thực tế của action gần nhất: các ô bị bỏ qua trong stroke không nằm trong diff. Nhấn Undo khi khe rỗng không đổi state. Với grouped undo, candy đúng + tất cả auto-marks phát sinh được pop cùng lúc. `TryCandy` sai xóa khe và là ranh giới không thể Undo xuyên qua.

### Auto-mark và locked

| ID | Quy tắc |
| --- | --- |
| GR-34 | Sau CandyFound, hệ thống auto-mark tất cả ô BLANK cùng hàng, cột, vùng và láng giềng chéo (diagonal neighbors) thành `locked`. Ô `locked` hiện X mờ và player không thể thay đổi. |
| GR-35 | Sau khi đặt givens lúc khởi tạo board, hệ thống tính auto-marks cho tất cả given cells. |
| GR-36 | Khi undo candy đã đặt đúng, tất cả `locked` cells phát sinh từ candy đó được xóa về trạng thái trước (BLANK hoặc MARK). |

`locked` cells được lưu trong session. Khi khôi phục session, auto-marks được tính lại từ candy đã đặt để xác minh tính nhất quán.

## 3. Đúng/sai, tim và điểm

| ID | Quy tắc |
| --- | --- |
| GR-15 | `TryCandy(r,c)` đúng `solution[r]`: chuyển `empty`/`x` thành `candy`, cố định ô, tăng `correct_count` một lần, kiểm thắng. |
| GR-16 | `TryCandy(r,c)` sai: chuyển ô `empty`/`x` thành `x_error`, giảm đúng 1 tim, tăng `mistake_count` đúng một lần. `x_error` khóa mọi thao tác trong lượt đến khi Retry/Restart; thử lại trên ô đó không tính thêm. |
| GR-17 | Lượt mới có 3 tim. Tim không hồi trong lượt; Retry sau khi hết tim miễn phí. |
| GR-18 | Scorecard được **tính lại** bằng `max(0, 100 × correct_count − 25 × mistake_count)`; chỉ hiện ở Result, không quy đổi trong MVP; không cho điểm từ givens, X, Hint hay animation. |
| GR-19 | Tim về 0 → `Failed`, lưu kết quả thua và khóa board. Retry tạo lượt mới trên **cùng level**, reset ô/tim/scorecard/Hint/thời gian. |
| GR-20 | Một ô sai có thể chưa xung đột với kẹo hiện có; chỉ nêu lý do cục bộ có chứng cứ (hàng, cột, vùng, chạm chéo). Nếu không có, dùng lời trung tính. |

Riêng tutorial Level 1, thao tác sai **trên ô tutorial được gọi rõ bằng tọa độ** được nhắc mà không đặt `x_error`, trừ tim hoặc tăng lỗi; ô này không được tô sáng. Ô khác theo GR-16. Từ Level 2, mọi thao tác dùng phạt bình thường. Không dùng tutorial để dò nhiều ô miễn phí.

## 4. Hint

| ID | Quy tắc |
| --- | --- |
| GR-21 | Mỗi lượt bắt đầu với budget hint từ pace data (`hintCosts`). Hint dùng given và candy đúng đã đặt; bỏ qua X và `x_error` khi tính ứng viên. |
| GR-22 | Hint hợp lệ tìm S2 trực tiếp hoặc chuỗi S3→S2 còn hiệu lực, tô sáng focus/source/target/ô bị loại và kẹo nguồn; không tự đặt X hoặc kẹo. |
| GR-23 | Nếu ô đích đang là X, nhắc chạm đôi trực tiếp để thử kẹo. Ô `x_error` không thể là đích đúng nếu dữ liệu level hợp lệ; không đề nghị xóa X đỏ. |
| GR-24 | Tính lại Hint từ trạng thái hiện tại, không dùng con trỏ trace; bỏ qua bước đã hoàn thành. Chỉ evidence hợp lệ mới đặt `hintCount=1`; `NoHint` không tiêu thụ. |
| GR-37 | Hint dùng progressive reveal: click đầu tiên tô sáng đơn vị (hàng/cột/vùng) chứa ứng viên; click tiếp thu hẹp đến ô cụ thể. Chi phí mỗi bước theo hintCosts từ pace data. |

Hint budget đến từ pace data (`hintCosts`); mỗi click progressive reveal tiêu 1 unit từ budget. Khi budget hết, nút Hint ở trạng thái đã dùng và không phát evidence thêm. Reload cùng session không cấp lại budget. Retry hoặc Restart tạo lượt mới với budget đầy; Back To Home rồi tiếp tục giữ nguyên budget đã dùng. Hint không đổi scorecard, tim hoặc board và có thể đóng để tiếp tục chơi. Nguồn Hint bổ sung từ điểm danh/quảng cáo nằm ngoài MVP.

## 5. Thắng và level hiện tại

| ID | Quy tắc |
| --- | --- |
| GR-25 | Thắng ngay khi có đủ N candy đúng gồm given và còn ít nhất 1 tim, kể cả còn X/`x_error` khác. State `Failed` không thể thắng. |
| GR-26 | Ghi điểm kết quả thắng một lần, đánh dấu hoàn thành và đặt level hiện tại thành `order+1` trước khi hiện màn thắng. Nếu vừa thắng level cuối, hiện trạng thái hết nội dung. |
| GR-27 | Chỉ có **một** session cho level hiện tại. Back To Home/đóng app lưu board, tim, lỗi, hint, thời gian; Play mở đúng level đó. |
| GR-28 | Không có chọn/chơi lại level đã qua trong bản đầu. Người chơi không thể bỏ qua level chưa thắng. Failed/Home/Retry đều ở level hiện tại. |

Danh sách level phát hành sắp theo `order` liên tiếp từ 1. Khi cập nhật thêm nội dung ở cuối dãy, người đã hoàn thành tất cả sẽ bắt đầu level mới đầu tiên. ID và puzzle đã phát hành không đổi nghĩa.

## 6. Máy trạng thái

```text
Home → Playing ──đủ kẹo──→ Won/Result ──Tiếp tục──→ Playing(level kế)
          │
          ├──CandyFound──→ auto-mark locked (GR-34) ──→ Playing
          ├──tim=0──→ Failed/Result ──Thử lại──→ Playing(cùng level)
          ├──Restart + xác nhận──────────────→ Playing(cùng level, lượt mới)
          └──Back To Home/app nền: lưu session, rồi Home/Paused
```

Khi board init, givens cũng kích hoạt auto-mark (GR-35) trước khi vào Playing.

`Paused` chỉ là trạng thái giao diện; thời gian chơi không tăng ở nền, Help, Settings hoặc Result. Retry/Restart là lượt mới và cấp lại một Hint; Back To Home/app nền giữ lượt hiện tại nhưng xóa khe Undo. Lượt thua khôi phục lại màn kết quả thua, không cấp tim ngầm. Lượt thắng đã được commit vào progress; nếu app đóng ở Result, lần Play sau vào level kế. Khi hết level, Home hiện thông báo hoàn thành nội dung hiện có.

Không có cứu lượt bằng tiền/quảng cáo trong CanDoKu. Bản kiểm thử bốn level có ngoại lệ replay từ L01 theo RST-003 ở [DECISIONS](../docs/DECISIONS.md); bản playtest 30 level phải tắt ngoại lệ này và giữ GR-28. Chính sách của bản phát hành chính thức được chốt sau playtest, không suy ra từ cờ MVP hiện tại.

## 7. Hoạt ảnh và tình huống mép

- Sau candy đúng, hiện feedback ngắn “Tìm thấy rồi!”; khi đạt ít nhất một nửa số kẹo do người chơi cần tìm, lần đầu hiện “Giỏi lắm!”. Câu chữ là khóa localization, không thay đổi score/luật. Kẹo cuối ưu tiên màn thắng.
- Sau candy đúng, auto-mark các ô locked với hiệu ứng stagger (mỗi ô cách nhau ~40 ms). SFX lock tick có rate limiting để tránh tràn âm thanh khi nhiều ô locked cùng lúc.
- Sai: ô hiện X đỏ, tim và scorecard nội bộ cập nhật cùng một transaction; scorecard chỉ hiển thị khi vào Result. Phản hồi lỗi khóa input board tối đa 200 ms để tránh một chuỗi chạm tính thành nhiều lần thử; giảm chuyển động dùng dấu tĩnh với cùng thời gian chặn. Save lỗi không bị giới hạn bởi mốc hoạt ảnh: giữ state trước action và hiện thông báo thử lại.
- Ba chạm rất nhanh không tạo hai lần `TryCandy`; chạm thứ ba trong phản hồi đầu bị bỏ qua. Chạm đơn đã nhấc được commit khi app nền; nét đang kéo bị hủy, không tự ghi X lúc quay lại.
- Candy đúng/given, `locked` và `x_error` không thể xóa trong lượt. Hint vẫn dựa trên luật, không dùng X đỏ hoặc locked như sự thật.
