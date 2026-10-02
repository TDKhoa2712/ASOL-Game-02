# 07 — Kiểm thử và tiêu chí nghiệm thu

Mã QA truy ngược về GR/UX/LV/TECH/ART. Test validator hiện có chỉ xác nhận dữ liệu kỹ thuật; các ca UI/mobile/sprite cần thực hiện khi có game chạy được.

## 1. Level, solver, trace

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-01 | Gate campaign playtest 30 level (cần triển khai; không dùng `--release` legacy) | Đúng 30 ID, `order=1..30`, N=4–6, mỗi level còn ít nhất hai kẹo để tìm; không chương |
| QA-02 | 0 hoặc ≥2 nghiệm | Chặn, báo ID/lý do; timeout solver không được xem là độc nhất |
| QA-03 | `solution` khai khác nghiệm độc lập | Chặn |
| QA-04 | Vùng tách rời | Chặn, nêu nhãn vùng |
| QA-05 | Bước S2 sai focus/đích/chứng cứ hoặc S3 sai source/target/tập loại | Chặn tại bước lỗi; S3 thiếu/thừa/no-op/lặp hoặc dựa nghiệm/X/X đỏ đều bị từ chối; trace đủ N kẹo |
| QA-06 | Hình vùng lặp trong cửa sổ 8 level sau xoay/lật/đổi nhãn | Cảnh báo fixture, chặn release |
| QA-07 | T01/E01/E02/S301/N12 | Nghiệm/trace hợp lệ; S301 kiểm S3→S2; N12 kiểm nhãn A–L và biên schema |
| QA-49 | Level `order=10,20` bản đầu | Motif/sticker và nhịp suy luận được duyệt người, qua cùng uniqueness/trace/usability; không thêm luật GR; ID/puzzle khóa trước release |
| QA-32 | Schema cũ, thừa/thiếu trường, bool giả int, ID/order trùng, textKey sai | Báo rõ, không chấp nhận âm thầm |
| QA-35 | N=12 và N=13; `--release` với N=12 | N12 được đọc/kiểm kỹ thuật; N13 và release N12 bị từ chối; chưa xem N12 là gameplay đã duyệt |
| QA-57 | Playtest logic band | Order 1–18 chứa S3 bị chặn; mỗi order 19–24 thiếu S3 hoặc vẫn hoàn tất bằng closure chỉ S2 bị chặn; order 25–30 phải khớp profile được duyệt; S4/S5 bị chặn trong playtest |

## 2. Board, cử chỉ, điểm

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-08 | Một chạm trên empty, X, X đỏ, candy/given | empty↔X hiện tức thì; X đỏ/candy/given bất biến; không tim/điểm ảo |
| QA-09 | Hai chạm cùng empty hoặc X vào ô đúng | Một `TryCandy`, candy đúng cố định, chỉ báo vùng sáng ở hàng tiến độ; hình kẹo mặc định không đổi theo vùng; preview X được hoàn tác, không X lưu trung gian |
| QA-10 | Hai chạm ô sai chưa có xung đột thấy được | X đỏ, -1 tim, +1 lỗi, score theo công thức, lý do trung tính |
| QA-11 | Chạm đơn/đôi/kéo qua X đỏ, rồi Retry hoặc Restart | X đỏ không đổi và không mất tim thêm trong lượt; Retry/Restart reset ô trên cùng level |
| QA-12 | Hai chạm khác ô, chậm hơn cửa sổ, ba chạm nhanh, chạm thứ hai thành kéo, app nền khi đã/chưa nhấc | Không gộp sai cử chỉ/nhân đôi lỗi; chạm đã nhấc được commit, chạm/nét chưa nhấc bị hủy |
| QA-13 | Chạm candy đúng/given sau khi tìm | Không xóa, không thêm điểm/tim |
| QA-14 | Hết 3 tim rồi Retry | Màn thua riêng, cùng level, board/scorecard/tim/Hint/thời gian reset; cấp lại một Hint |
| QA-15 | Đủ N candy khi còn X/X đỏ nơi khác | Thắng ngay, ghi một result, current level tăng đúng 1 |
| QA-16 | Score với given, lỗi trước/sau kẹo, Hint và sàn 0 | Giá trị nội bộ bằng `max(0,100×correctPlaced−25×mistakes)` ở mọi thời điểm; chỉ hiển thị tại Result |
| QA-17 | Input board ở Won/Failed/result | Bị chặn; không ghi kết quả hai lần |
| QA-43 | Kéo từ empty qua empty/X/X đỏ/candy, đi nhanh và vòng ngược | Chỉ ô empty trên đường phủ đầy đủ thành X một lần; trạng thái khác giữ nguyên; một batch lưu |
| QA-44 | Kéo từ X qua X/empty/X đỏ/candy, đi nhanh và vòng ngược | Chỉ ô X trên đường thành empty một lần; trạng thái khác giữ nguyên; một batch lưu |
| QA-45 | Ngưỡng 12 điểm logic, hai ngón/lòng bàn tay, bắt đầu ngoài bàn, nhấc ngoài bàn, app nền | Không nhầm tap/drag/double, không nhận ngón phụ; chạm đã nhấc được lưu, nét chưa nhấc bị hủy, nét hợp lệ commit một lần |
| QA-54 | Restart giữa lượt: hủy và xác nhận | Hủy giữ nguyên state; xác nhận tạo lượt mới cùng level, reset board/3 tim/lỗi/scorecard/Hint/thời gian và xóa Undo |
| QA-55 | Undo sau MarkX/ClearX/stroke, sau TryCandy và sau lifecycle | Hoàn nguyên đúng một diff X đơn hoặc toàn stroke; không đổi candy/X đỏ/tim/lỗi/scorecard/Hint; không Redo/không nhảy qua TryCandy; Back/Home/app đóng xóa khe |
| QA-58 | Auto-mark: đặt candy đúng trên bàn có ô trống cùng hàng/cột/luống/chéo | Các ô BLANK cùng hàng/cột/luống/chéo với candy chuyển thành LOCKED; locked cells hiện X mờ, player không xóa được; tập locked khớp với tập expected từ quy tắc loại trừ |
| QA-59 | Grouped undo: Undo ngay sau khi đặt candy có auto-marks | Candy bị hoàn nguyên về BLANK và tất cả locked cells trong cùng nhóm cũng trở về trạng thái trước; một lần nhấn Undo cho cả nhóm |
| QA-60 | Progressive hint: click Hint nhiều lần trên cùng lượt | Click đầu tiên highlight unit (zone/row/col); click tiếp thu hẹp về ô cụ thể; mỗi click tiêu đúng 1 unit từ budget; không tiêu thêm khi đã reveal đến ô |
| QA-61 | Clean-room gate cho rebuild modules | `grep -rE` các tên từ reference (EventBus, EventName, GameState, SaveStore, SoundManager, v.v.) trong `game/scripts/` không có kết quả; không import từ `extracted_reusable`; verify bằng `tools/verify.py` |

## 3. Hint, tutorial, màn kết quả

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-18 | X che ô nghiệm, X đỏ ở ô sai, xin Hint | Hint bỏ qua ghi chú làm tiền đề, hướng dẫn chạm đôi trên X đúng, không đề nghị xóa X đỏ hay tự đặt candy |
| QA-19 | Đặt candy đúng khác thứ tự trace, xin Hint | S2 hoặc chuỗi S3→S2 hiện tại hợp lệ; giải thích source/target/ô bị loại và kẹo nguồn |
| QA-20 | Xin Hint lặp/đóng/NoHint | Evidence hợp lệ tiêu thụ đúng một Hint, không đổi scorecard/tim/board; lần hai bị chặn; `NoHint` không tiêu thụ |
| QA-21 | Tutorial làm đúng khác thứ tự rồi đóng/mở app | Mốc đã đạt không hiện lại/kẹt |
| QA-22 | Thử sai trên ô hướng dẫn được gọi bằng tọa độ và ô khác ở Level 1; thử sai từ Level 2 | Chỉ ô tutorial được chỉ định tại Level 1 miễn tim/X đỏ; không tô sáng ô; ô khác và mọi level sau theo luật thường |
| QA-33 | Script tutorial trên Level 1 phát hành | T1–T6 theo X→clear→drag→double-tap→bốn luật→Hint, target có chứng cứ thật; Level 2 không hiện tutorial; bản mở lại không đổi campaign |
| QA-36 | Kẹo đúng đầu/nửa bàn, thắng, hết tim, giảm chuyển động | “Tìm thấy rồi!/Giỏi lắm!”/sticker đúng mốc; màn thắng/thua khác nhau; nút Next/Retry luôn dùng được; giảm chuyển động giữ thông tin |
| QA-56 | Hint đã dùng rồi reload/Back, hoặc Retry/Restart; `NoHint` | Reload/Back giữ trạng thái đã dùng; Retry/Restart cấp lại đúng một Hint; `NoHint` không tiêu thụ hoặc cấp thêm |

## 4. Save, UX, thiết bị và phát hành

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-23 | Back To Home/Settings/Help/app nền sau X, X đỏ, candy, Hint | Home Play đúng level và board/tim/scorecard/Hint; Undo bị xóa; không có màn chọn level |
| QA-24 | Hỏng session; hỏng progress chính nhưng bản trước tốt | Session reset cùng level sau báo lỗi; progress lấy bản hợp lệ trước, không mất completed đã lưu ở bản đó |
| QA-25 | Thêm level ở cuối dãy sau khi người chơi hết nội dung; hash/version sai | Bắt đầu level mới đúng; session không hợp lệ không làm tiến level |
| QA-26 | Chơi offline qua các level đầu | Không cần mạng/tài khoản/quảng cáo |
| QA-27 | Bàn 6×6, vùng luật luôn thấy, hàng 6 vị trí tiến độ, chữ lớn, safe area trên máy nhỏ | Bàn/nút đủ vùng chạm, bốn icon + chữ không bị che/cắt và không cần phóng/trượt bàn |
| QA-28 | Thang xám, tắt âm/rung, giảm chuyển động | Vùng/kẹo/X đỏ/điểm/tim/kết quả vẫn phân biệt |
| QA-29 | Trình đọc màn hình quét bàn/hàng tiến độ vùng | Đọc tọa độ/vùng/trạng thái; gọi được action X và Tìm kẹo |
| QA-30 | Hiệu ứng hé lộ kẹo/sticker trên Android/iPhone thấp đã chốt | Đo FPS/RAM/VRAM/tải/khựng với atlas thực; tối ưu và đo lại nếu không đạt TECH-19 |
| QA-50 | Một bộ asset kẹo mặc định dùng chung trên 6 vùng | Cùng hình/hiệu ứng kẹo trên mọi ô `candy`, gồm given; vùng vẫn phân biệt bằng nền/viền/nhãn/họa tiết, không nhân asset theo màu vùng; đo VRAM thực và khựng trên máy mục tiêu |
| QA-31 | Giả lỗi ghi session/progress, crash giữa progress và dọn session | Không nói đã lưu nếu thất bại; thắng đã hiện thì Home mở level kế một lần |
| QA-34 | Asset/build Android+iOS | Màu/sticker/sprite kẹo gốc/audio có nguồn; build offline, không chứa asset tham chiếu |

## 5. Cổng bản đầu và mở rộng N=12

Ít nhất 10 người chưa đọc GDD chơi trên thiết bị thật. Ghi tỷ lệ hiểu chạm/kéo/chạm đôi, số nhầm chạm đôi/kéo, thời gian mỗi level, lỗi, Hint, chỗ họ chỉ nhìn màu không nhận ra vùng và mức thích hoạt ảnh. Từng level phải có một lượt giải thủ công không xem nghiệm, hoàn thành với ít nhất 1 tim và ghi thời gian/lỗi/Hint/điểm kẹt. Nếu tỷ lệ nhầm cử chỉ cao hoặc TryCandy vô ý từ 3% trở lên, điều chỉnh cửa sổ/ngưỡng/feedback qua playtest rồi kiểm lại QA-08..12/43..45.

Bản playtest trước phát hành chỉ đạt khi 30 level liên tiếp qua QA-01..07/32/49/57, mọi hành vi QA-08..31/33..36/43..45/50/54..56 chạy và lỗi chặn được sửa, asset có quyền rõ, Android+iOS đã đo trên thiết bị mục tiêu hoặc có quyết định phạm vi nền tảng riêng. Đây chưa phải chứng nhận phát hành chính thức; release gate sẽ được chốt sau dữ liệu playtest. N=12 là hạng mục sau playtest: cần 12 cặp màu/họa tiết, kích thước/chạm chính xác **không zoom/pan**, hàng tiến độ cuộn, solver/trace/Hint và đo sprite trên bàn lớn; chỉ khi toàn bộ các ca đó qua mới tăng giới hạn sản phẩm.

## 6. S3 hiện hành và nghiên cứu để sau

S3 thuộc bản đầu: QA-37/40/41/57 là bắt buộc cho sáu màn cuối. S4/S5 và N>6 chỉ nghiên cứu khi được giao, không được lẫn vào trace schema v4.

| ID | Ca | Điều kiện |
| --- | --- | --- |
| QA-37 | S3 giao thoa | Fixture dương/âm; tập loại đúng và đầy đủ; không dựa X/X đỏ |
| QA-40 | Trace S2/S3 | Bước sai thứ tự, no-op, kết luận giả hoặc dùng nghiệm làm chứng cứ bị chặn; S4/S5 bị từ chối ở schema v4 |
| QA-41 | Hint S3 | Tính lại từ trạng thái hiện tại, giải thích đọc được, không tự ghi X/kẹo |
| QA-38/39/42 | S4/S5/N12 | Mã nghiên cứu bảo lưu; không mở nội dung khi chưa có hợp đồng và QA riêng |

QA-46/47/48/51/52/53 của đề án kinh tế, bộ sưu tập và generator cũ ngừng áp dụng cho phạm vi CanDoKu hiện tại. Lịch sử ở revision nêu trong [09](09-ra-soat-thiet-ke.md). Không tái sử dụng các ID này cho yêu cầu mới khác nghĩa.

## 7. Nghiệm thu chuyển chủ đề CanDoKu

| ID | Ca | Kết quả bắt buộc |
| --- | --- | --- |
| QA-CD-01 | Home → Puzzle → Help/Settings → Win/Fail → Home, tutorial và trình đọc màn hình | Tên CanDoKu, lời hướng dẫn kẹo/luống; không còn tên, hình ảnh hoặc âm thanh chủ đề cũ; không dùng câu “tìm kẹo” trong UI phát hành |
| QA-CD-02 | Ô trống/X/X đỏ/kẹo/given trên sáu vùng; thang xám và chữ lớn | Không lộ nghiệm qua trang trí; một hình kẹo chung; vùng và dấu lỗi nhận diện không chỉ bằng màu; viền vùng không đứt bởi kẹo |
| QA-CD-03 | Save trước đổi chủ đề có X, X đỏ, candy, Hint đã dùng, đang thua hoặc hoàn tất | Load giữ nguyên board/tim/điểm/Hint/order; token candy hiển thị kẹo; không reset save/hash/ID do đổi hình ảnh |
| QA-CD-04 | Tìm đúng liên tiếp, sai, lần tìm cuối, app nền trong hiệu ứng | Hiệu ứng không đổi luật hoặc làm mất kẹo khỏi ô; giảm chuyển động vẫn đủ thông tin; action chỉ commit một lần |
| QA-CD-05 | Bản playtest 30 màn và bản kiểm R1 bốn màn | Playtest không replay L01; R1 replay đúng RST-003; không lẫn fixture với campaign hoặc tuyên bố đủ 30 khi chỉ có bốn màn |
| QA-CD-06 | Asset và thông điệp ngoài bàn | Logo/kẹo/giỏ/cây/SFX có nguồn; không có Shop, vàng, daily hoặc Endless như tính năng đã bật |

Các ca mới bổ sung cho QA hiện có; không thay thế đo thiết bị, cổng 10 người hoặc validator. Chuyển chủ đề trong tài liệu chưa phải PASS cho bất kỳ ca runtime mới nào.
