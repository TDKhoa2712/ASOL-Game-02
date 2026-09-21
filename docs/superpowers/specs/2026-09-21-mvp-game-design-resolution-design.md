# Đặc tả giải quyết review thiết kế MVP

**Ngày:** 2026-09-21  
**Trạng thái:** Đã duyệt ngày 2026-09-21  
**Nguồn quyết định:** Trao đổi phê duyệt cho `design-control/reviews/01-mvp-game-design-review.md`  
**Phạm vi:** GDD v1.0 Design Freeze cho bản phát hành đầu

## 1. Mục tiêu

Đặc tả này hợp nhất các quyết định xử lý GD-01..15 thành một baseline không
mâu thuẫn cho MVP. Baseline giữ game giải đố tuyến tính, ba tim và `x_error`,
đồng thời bổ sung Restart, Undo giới hạn, một Hint miễn phí mỗi lượt và S3 bắt
buộc ở sáu level cuối. Mọi hệ thống kiếm Hint bằng điểm danh hoặc quảng cáo,
generator và economy vẫn nằm ngoài MVP.

Thay đổi canonical phải được thực hiện đồng bộ trong GDD, dữ liệu mẫu,
validator/test và QA. Không được bật level phát hành dùng S3 khi chỉ một phần
của chuỗi schema → validator → Hint → QA đã hoàn thành.

## 2. Phạm vi campaign và suy luận

- Campaign có đúng 24 level liên tiếp, kích thước N=4–6.
- Level 1 là tutorial duy nhất và nằm trong 24 level; không tạo level thực hành
  thứ 25.
- Level 1–18 phải giải được hoàn toàn bằng S1/S2.
- Mỗi level 19–24 phải có ít nhất một bước S3 hợp lệ và cần thiết trong proof
  trace. Xóa các bước S3 khỏi trace không được vẫn còn một trace S1/S2 hoàn
  chỉnh cho level đó.
- S4/S5 không thuộc MVP. Generator và nội dung N>6 là post-MVP.
- Trần schema/tooling vẫn là N=12; release gate tiếp tục từ chối N>6.

### 2.1 Định nghĩa S3 bắt buộc

S3 dùng định nghĩa “khóa giao thoa hai đơn vị” trong GDD/10. Với hai đơn vị
khác loại chưa có mèo `U` và `V`, bước hợp lệ khi tập ứng viên còn lại của
`U` khác rỗng và nằm hoàn toàn trong `V`. Bước loại toàn bộ ứng viên còn lại
của `V` nằm ngoài `U`, và phải tạo ít nhất một loại trừ mới.

S3 không được dùng `solution`, X hay `x_error` làm tiền đề. Validator tự dựng
tập ứng viên từ given, mèo đúng, S1 và các kết luận loại trừ đã được chứng
minh. Hint runtime cũng tính lại từ trạng thái hiện tại, không đi theo con trỏ
trace lưu sẵn.

### 2.2 Schema và cổng S3

Schema v3 chỉ hỗ trợ S2 nên không được thêm âm thầm `rule: "S3"`. Khi triển
khai phải nâng lên schema v4 và cập nhật đồng thời:

- fixture S3 dương/âm gốc;
- validator tuần tự cho S2/S3;
- unit/property tests và kiểm tra phản ví dụ;
- Hint giải thích S3 trên màn nhỏ và bằng screen reader;
- QA-37, QA-40 và QA-41;
- sáu level phát hành order 19–24.

Trace S3 phải khai báo đơn vị nguồn, đơn vị đích, tập ô bị loại và khóa câu
giải thích. Validator tự tính toàn bộ tập loại trừ rồi so khớp chính xác với
trace; no-op, ô trùng, tiền đề chưa tồn tại và kết luận dựa vào nghiệm đều bị
từ chối.

## 3. Luật lượt chơi

- Mỗi lượt bắt đầu với ba tim.
- `TryCat` đúng đặt mèo cố định và tính điểm theo luật hiện hành.
- `TryCat` sai tạo `x_error` khóa và trừ đúng một tim.
- Người chơi thắng khi đủ N mèo đúng trước khi hết tim. Do tim về 0 chuyển
  ngay sang `Failed`, một lượt thắng luôn còn ít nhất một tim.
- Tim về 0 làm thất bại lượt. Retry bắt đầu lượt mới trên cùng level và reset
  board, tim, điểm, lỗi, Hint, thời gian cùng Undo.
- Restart có thể dùng giữa lượt, yêu cầu xác nhận và có kết quả reset giống
  Retry nhưng không cần đi qua `Failed`.

Ba tim và `x_error` tự phục vụ thử thách trí tuệ của MVP; chúng không được
giải thích hoặc thiết kế như tiền đề cho cứu lượt bằng vàng/quảng cáo.

## 4. Undo một bước

Undo là một khe runtime duy nhất, không phải lịch sử nhiều bước:

- Action có thể Undo: một lần đánh X, một lần xóa X, hoặc một batch kéo đánh/
  xóa X đã commit.
- Undo batch khôi phục đúng trạng thái trước action của mọi ô mà batch thực sự
  thay đổi; các ô bị bỏ qua không nằm trong diff.
- Chỉ action vừa commit mới có thể Undo. Nếu action mới nhất là `TryCat`, Undo
  bị vô hiệu; không được bỏ qua `TryCat` để tìm action X cũ hơn.
- Không Undo mèo đúng, `x_error`, tim, điểm, Hint hoặc mốc tutorial.
- Undo xong thì khe trống; không có Redo.
- Restart, Retry, Won, Failed, Back To Home hoặc đóng ứng dụng đều xóa khe
  Undo. Board vẫn được lưu theo luật session, nhưng khả năng Undo không được
  lưu qua điều hướng hay lần chạy ứng dụng.

Preview chưa commit không tạo khe Undo. Một batch kéo chỉ tạo đúng một action
và một khe Undo khi nhấc ngón.

## 5. Hint

- Mỗi lượt có đúng một Hint miễn phí.
- Một yêu cầu Hint hợp lệ tiêu thụ quyền dùng Hint của lượt; `NoHint` do engine
  không tìm được lời giải thích hợp lệ không tiêu thụ.
- Đóng rồi mở lại cùng session không cấp lại Hint. Retry hoặc Restart tạo lượt
  mới nên cấp lại một Hint.
- Hint không đổi tim, điểm hoặc board và không tự đặt X/mèo.
- Hint ưu tiên S2 trực tiếp; ở level 19–24 có thể giải thích S3 rồi chỉ ra bước
  S2 tiếp theo hoặc một loại trừ S3 hữu ích.
- Nguồn Hint từ điểm danh hoặc quảng cáo chỉ thuộc post-MVP. MVP không có ví
  Hint, SDK quảng cáo, lịch điểm danh hay interface giả chuẩn bị cho chúng.

## 6. Tutorial và UI trong level

Level 1 là tutorial 4×4 duy nhất. Nó hướng dẫn lần lượt:

1. đánh một X;
2. xóa X;
3. kéo để đánh/xóa nhiều X;
4. chạm đôi để đặt mèo;
5. bốn luật hàng, cột, vùng và không chạm;
6. sử dụng một Hint miễn phí.

Tutorial phải dùng chứng cứ thật của level, không ép người chơi thử sai để xem
`x_error`. Từ Level 2, toàn bộ luật ba tim/`x_error` áp dụng bình thường. S3
là kỹ thuật suy luận, không phải luật thắng mới; Hint tại Level 19 chịu trách
nhiệm giải thích bước S3 đầu tiên khi người chơi yêu cầu.

Mỗi màn puzzle dành một vùng hiển thị luật luôn nhìn thấy, dùng biểu tượng kèm
chữ ngắn cho bốn luật. Vùng này phải được tính trong kiểm tra bố cục N=6, safe
area, chữ lớn và vùng chạm 44×44; không được thu nhỏ board dưới cổng usability
đã chốt.

## 7. Cử chỉ, điểm và tiến trình

- Giữ optimistic preview, chạm đôi cùng ô và batch kéo hiện hành.
- `280 ms` và `12 pt logic` là tham số tuneable tại M0; cổng ban đầu là tỷ lệ
  kích hoạt nhầm `TryCat` dưới 3% trên thiết bị mục tiêu.
- Điểm tiếp tục là `max(0, 100 × correctPlacedCount − 25 × mistakeCount)`.
- Điểm không hiển thị trong header lúc chơi; chỉ hiện ở Result như scorecard
  của lượt, không hứa hẹn quy đổi sang tiền tệ.
- Campaign vẫn tuyến tính, không chọn level, replay level cũ hoặc skip level
  trong MVP.
- Generator được thiết kế sau MVP; không dùng generator để thay đổi ID/puzzle
  đã phát hành.

## 8. Nghiệm thu level

Điều kiện thắng runtime và điều kiện nghiệm thu nội dung là hai cổng riêng.

Một level chỉ đạt cổng nội dung khi:

- vùng hợp lệ, nghiệm duy nhất và solution/givens khớp solver độc lập;
- trace đi đến đủ N mèo mà không có bước đoán;
- level 1–18 có trace S1/S2; level 19–24 có trace S1/S2/S3 và đáp ứng yêu cầu
  S3 cần thiết tại §2;
- ít nhất một người không xem đáp án giải hoàn chỉnh với ít nhất một tim còn
  lại, đồng thời ghi thời gian, số lỗi, số Hint và điểm kẹt;
- level tutorial dùng target có chứng cứ thật;
- level 10/20 tiếp tục qua cổng motif và nhịp riêng;
- toàn campaign vẫn qua playtest tối thiểu 10 người và các cổng thiết bị/
  accessibility của GDD/07.

Việc một người tìm đủ mèo không thay thế validator, trace hoặc playtest tổng
thể.

## 9. Cô lập meta và nhận diện sản phẩm

- MVP không có wallet, vàng, cứu lượt, quảng cáo, điểm danh, IAP, account hoặc
  network analytics.
- Điểm chỉ là scorecard; ba tim chỉ là luật thử thách của lượt.
- Tên “Vườn Mèo” vẫn là tên tạm và không tạo nghĩa vụ xây Garden Lobby, album
  sticker hoặc bộ sưu tập mèo trong MVP.
- Art/sprite 2D từ model 3D gốc, một mèo mặc định, offline-first và vùng không
  mã hóa bằng màu lông tiếp tục là quyết định an toàn.

## 10. Phạm vi cập nhật sau khi đặc tả được duyệt

Đợt triển khai tài liệu/kỹ thuật phải bao phủ tối thiểu:

- `GDD/README.md`, GDD/01–05, GDD/07–11;
- `design-control/00-design-status.md`, open questions, decision log, risk,
  assumptions, research backlog và freeze checklist;
- trạng thái GD-01..15 trong review mục tiêu và các review lịch sử liên quan;
- schema v4, `levels.sample.json`, fixture S3 dương/âm;
- validator cùng unit/property tests S2/S3;
- interaction contract/test cho Restart, Undo và một Hint mỗi lượt;
- QA cho Restart/Undo/Hint/tutorial và QA-37/40/41;
- kế hoạch gói việc để S3 không còn là nghiên cứu tùy chọn.

Không được tuyên bố Design Freeze chỉ vì các quyết định đã được ghi. Các cổng
bằng chứng M0 về input, atlas, bố cục và thiết bị vẫn phải hoàn thành theo
checklist; S3 phải qua cổng kỹ thuật trước M2.
