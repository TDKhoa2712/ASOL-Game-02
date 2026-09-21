# 07 — Kiểm thử và tiêu chí nghiệm thu

Mã QA truy ngược về GR/UX/LV/TECH/ART. Test validator hiện có chỉ xác nhận dữ liệu kỹ thuật; các ca UI/mobile/sprite cần thực hiện khi có game chạy được.

## 1. Level, solver, trace

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-01 | `--release` trên campaign | Đúng 24 ID, `order=1..24`, N=4–6, mỗi level còn ít nhất hai mèo để tìm; không chương |
| QA-02 | 0 hoặc ≥2 nghiệm | Chặn, báo ID/lý do; timeout solver không được xem là độc nhất |
| QA-03 | `solution` khai khác nghiệm độc lập | Chặn |
| QA-04 | Vùng tách rời | Chặn, nêu nhãn vùng |
| QA-05 | Bước S2 sai focus/đích/chứng cứ hoặc S3 sai source/target/tập loại | Chặn tại bước lỗi; S3 thiếu/thừa/no-op/lặp hoặc dựa nghiệm/X/X đỏ đều bị từ chối; trace đủ N mèo |
| QA-06 | Hình vùng lặp trong cửa sổ 8 level sau xoay/lật/đổi nhãn | Cảnh báo fixture, chặn release |
| QA-07 | T01/E01/E02/S301/N12 | Nghiệm/trace hợp lệ; S301 kiểm S3→S2; N12 kiểm nhãn A–L và biên schema |
| QA-49 | Level `order=10,20` bản đầu | Motif/sticker và nhịp suy luận được duyệt người, qua cùng uniqueness/trace/usability; không thêm luật GR; ID/puzzle khóa trước release |
| QA-32 | Schema cũ, thừa/thiếu trường, bool giả int, ID/order trùng, textKey sai | Báo rõ, không chấp nhận âm thầm |
| QA-35 | N=12 và N=13; `--release` với N=12 | N12 được đọc/kiểm kỹ thuật; N13 và release N12 bị từ chối; chưa xem N12 là gameplay đã duyệt |
| QA-57 | Release logic band | Order 1–18 chứa S3 bị chặn; mỗi order 19–24 thiếu S3 hoặc vẫn hoàn tất bằng closure chỉ S2 bị chặn; S4/S5 bị chặn trong MVP |

## 2. Board, cử chỉ, điểm

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-08 | Một chạm trên empty, X, X đỏ, cat/given | empty↔X hiện tức thì; X đỏ/cat/given bất biến; không tim/điểm ảo |
| QA-09 | Hai chạm cùng empty hoặc X vào ô đúng | Một `TryCat`, cat đúng cố định, chỉ báo vùng sáng ở hàng tiến độ; hình mèo mặc định không đổi theo vùng; preview X được hoàn tác, không X lưu trung gian |
| QA-10 | Hai chạm ô sai chưa có xung đột thấy được | X đỏ, -1 tim, +1 lỗi, score theo công thức, lý do trung tính |
| QA-11 | Chạm đơn/đôi/kéo qua X đỏ, rồi Retry hoặc Restart | X đỏ không đổi và không mất tim thêm trong lượt; Retry/Restart reset ô trên cùng level |
| QA-12 | Hai chạm khác ô, chậm hơn cửa sổ, ba chạm nhanh, chạm thứ hai thành kéo, app nền khi đã/chưa nhấc | Không gộp sai cử chỉ/nhân đôi lỗi; chạm đã nhấc được commit, chạm/nét chưa nhấc bị hủy |
| QA-13 | Chạm cat đúng/given sau khi tìm | Không xóa, không thêm điểm/tim |
| QA-14 | Hết 3 tim rồi Retry | Màn thua riêng, cùng level, board/scorecard/tim/Hint/thời gian reset; cấp lại một Hint |
| QA-15 | Đủ N cat khi còn X/X đỏ nơi khác | Thắng ngay, ghi một result, current level tăng đúng 1 |
| QA-16 | Score với given, lỗi trước/sau mèo, Hint và sàn 0 | Giá trị nội bộ bằng `max(0,100×correctPlaced−25×mistakes)` ở mọi thời điểm; chỉ hiển thị tại Result |
| QA-17 | Input board ở Won/Failed/result | Bị chặn; không ghi kết quả hai lần |
| QA-43 | Kéo từ empty qua empty/X/X đỏ/cat, đi nhanh và vòng ngược | Chỉ ô empty trên đường phủ đầy đủ thành X một lần; trạng thái khác giữ nguyên; một batch lưu |
| QA-44 | Kéo từ X qua X/empty/X đỏ/cat, đi nhanh và vòng ngược | Chỉ ô X trên đường thành empty một lần; trạng thái khác giữ nguyên; một batch lưu |
| QA-45 | Ngưỡng 12 điểm logic, hai ngón/lòng bàn tay, bắt đầu ngoài bàn, nhấc ngoài bàn, app nền | Không nhầm tap/drag/double, không nhận ngón phụ; chạm đã nhấc được lưu, nét chưa nhấc bị hủy, nét hợp lệ commit một lần |
| QA-54 | Restart giữa lượt: hủy và xác nhận | Hủy giữ nguyên state; xác nhận tạo lượt mới cùng level, reset board/3 tim/lỗi/scorecard/Hint/thời gian và xóa Undo |
| QA-55 | Undo sau MarkX/ClearX/stroke, sau TryCat và sau lifecycle | Hoàn nguyên đúng một diff X đơn hoặc toàn stroke; không đổi cat/X đỏ/tim/lỗi/scorecard/Hint; không Redo/không nhảy qua TryCat; Back/Home/app đóng xóa khe |

## 3. Hint, tutorial, màn kết quả

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-18 | X che ô nghiệm, X đỏ ở ô sai, xin Hint | Hint bỏ qua ghi chú làm tiền đề, hướng dẫn chạm đôi trên X đúng, không đề nghị xóa X đỏ hay tự đặt cat |
| QA-19 | Đặt cat đúng khác thứ tự trace, xin Hint | S2 hoặc chuỗi S3→S2 hiện tại hợp lệ; giải thích source/target/ô bị loại và mèo nguồn |
| QA-20 | Xin Hint lặp/đóng/NoHint | Evidence hợp lệ tiêu thụ đúng một Hint, không đổi scorecard/tim/board; lần hai bị chặn; `NoHint` không tiêu thụ |
| QA-21 | Tutorial làm đúng khác thứ tự rồi đóng/mở app | Mốc đã đạt không hiện lại/kẹt |
| QA-22 | Thử sai trên ô hướng dẫn và ô khác ở Level 1; thử sai từ Level 2 | Chỉ ô đang sáng tại Level 1 miễn tim/X đỏ; ô khác và mọi level sau theo luật thường |
| QA-33 | Script tutorial trên Level 1 phát hành | T1–T6 theo X→clear→drag→double-tap→bốn luật→Hint, target có chứng cứ thật; Level 2 không hiện tutorial; bản mở lại không đổi campaign |
| QA-36 | Mèo đúng đầu/nửa bàn, thắng, hết tim, giảm chuyển động | “Nice/Great”/sticker đúng mốc; màn thắng/thua khác nhau; nút Next/Retry luôn dùng được; giảm chuyển động giữ thông tin |
| QA-56 | Hint đã dùng rồi reload/Back, hoặc Retry/Restart; `NoHint` | Reload/Back giữ trạng thái đã dùng; Retry/Restart cấp lại đúng một Hint; `NoHint` không tiêu thụ hoặc cấp thêm |

## 4. Save, UX, thiết bị và phát hành

| ID | Ca | Kết quả |
| --- | --- | --- |
| QA-23 | Back To Home/Settings/Help/app nền sau X, X đỏ, cat, Hint | Home Play đúng level và board/tim/scorecard/Hint; Undo bị xóa; không có màn chọn level |
| QA-24 | Hỏng session; hỏng progress chính nhưng bản trước tốt | Session reset cùng level sau báo lỗi; progress lấy bản hợp lệ trước, không mất completed đã lưu ở bản đó |
| QA-25 | Thêm level ở cuối dãy sau khi người chơi hết nội dung; hash/version sai | Bắt đầu level mới đúng; session không hợp lệ không làm tiến level |
| QA-26 | Chơi offline qua các level đầu | Không cần mạng/tài khoản/quảng cáo |
| QA-27 | Bàn 6×6, vùng luật luôn thấy, hàng 6 vị trí tiến độ, chữ lớn, safe area trên máy nhỏ | Bàn/nút đủ vùng chạm, bốn icon + chữ không bị che/cắt và không cần phóng/trượt bàn |
| QA-28 | Thang xám, tắt âm/rung, giảm chuyển động | Vùng/mèo/X đỏ/điểm/tim/kết quả vẫn phân biệt |
| QA-29 | Trình đọc màn hình quét bàn/hàng tiến độ vùng | Đọc tọa độ/vùng/trạng thái; gọi được action X và Thử mèo |
| QA-30 | M0 sprite cat jump/sticker trên Android/iPhone thấp đã chốt | Đo FPS/RAM/VRAM/tải/khựng với atlas thực; tối ưu và đo lại nếu không đạt TECH-19 |
| QA-50 | M0 một bộ atlas mèo mặc định dùng chung trên 6 vùng | Cùng hình/clip mèo trên mọi ô `cat`, gồm given; vùng vẫn phân biệt bằng nền/viền/nhãn/họa tiết, không nhân atlas hoặc tô lông theo màu vùng; đo VRAM thực và khựng trên máy mục tiêu |
| QA-31 | Giả lỗi ghi session/progress, crash giữa progress và dọn session | Không nói đã lưu nếu thất bại; thắng đã hiện thì Home mở level kế một lần |
| QA-34 | Asset/build Android+iOS | Màu/sticker/sprite từ model gốc/audio có nguồn; build offline, không chứa asset tham chiếu |

## 5. Cổng bản đầu và mở rộng N=12

Ít nhất 10 người chưa đọc GDD chơi trên thiết bị thật. Ghi tỷ lệ hiểu chạm/kéo/chạm đôi, số nhầm chạm đôi/kéo, thời gian mỗi level, lỗi, Hint, chỗ họ chỉ nhìn màu không nhận ra vùng và mức thích hoạt ảnh. Từng level phải có một lượt giải thủ công không xem nghiệm, hoàn thành với ít nhất 1 tim và ghi thời gian/lỗi/Hint/điểm kẹt. Nếu tỷ lệ nhầm cử chỉ cao hoặc TryCat vô ý từ 3% trở lên, điều chỉnh cửa sổ/ngưỡng/feedback qua playtest rồi kiểm lại QA-08..12/43..45.

Release đầu chỉ đạt khi 24 level liên tiếp qua QA-01..07/32/49/57, mọi hành vi QA-08..31/33..36/43..45/50/54..56 chạy và lỗi chặn được sửa, asset có quyền rõ, Android+iOS đã đo trên thiết bị mục tiêu. N=12 là hạng mục sau bản đầu: cần 12 cặp màu/họa tiết, kích thước/chạm chính xác **không zoom/pan**, hàng tiến độ cuộn, solver/trace/Hint và đo sprite trên bàn lớn; chỉ khi toàn bộ các ca đó qua mới tăng giới hạn **phát hành**.

## 6. Cổng nghiên cứu S3+ và meta sau MVP

S3 là ACTIVE-MVP cho order 19–24: QA-37/40/41/57 và mọi ca schema/trace liên quan là cổng bắt buộc. [S4–S5](10-nghien-cuu-quy-tac-suy-luan.md) vẫn dùng QA-38/39/40..42 như cổng nghiên cứu riêng và chưa được đóng gói. Kế hoạch meta/sinh level ở [11](11-ke-hoach-meta-va-sinh-level.md) dùng QA tương lai dưới đây, chưa là tính năng release đầu.

| ID | Cổng tương lai | Kết quả bắt buộc trước khi bật |
| --- | --- | --- |
| QA-37 | S3 giao thoa | Fixture dương/âm, tập loại mới đúng, hint không dựa X/X đỏ |
| QA-38 | S4 cặp khóa | Kiểm ghép cặp và phản ví dụ có ứng viên ngoài hai đích |
| QA-39 | S5 phản chứng | Nhánh ≤3 bước chứng minh mâu thuẫn, không rò trạng thái, timeout từ chối |
| QA-40 | Trace trộn S2/S3/S4 | Bước sai thứ tự, no-op, kết luận giả, dùng nghiệm làm chứng cứ đều bị chặn |
| QA-41 | Hint S3+ | Tính lại từ trạng thái hiện tại, đọc được và không tự ghi X/cat |
| QA-42 | N=12 solver/trace/hint | Đạt ngân sách đo thật; timeout là thất bại |
| QA-46 | Vàng từ điểm, thắng lại, crash/retry, backfill dữ liệu cũ | Công thức đúng; một level chỉ cấp một lần theo grant ID; balance và ledger nhất quán, không âm |
| QA-47 | Tim về 0, trả vàng cứu lượt hoặc chọn Retry | Đủ vàng mới trừ một lần; hồi 1 tim, xóa riêng X đỏ cuối, giữ board/lỗi/điểm/hint/thời gian; crash/chạm lặp không cấp/trừ trùng; Retry cùng level luôn miễn phí |
| QA-48 | Sinh ứng viên level mới và mốc tương lai | Seed/version tái tạo được; nghiệm duy nhất, vùng liên thông, trace hợp lệ, lọc trùng, review người và QA N tương ứng; không sửa level đã phát hành |
| QA-51 | Spike render 3D một lần khi đổi giống/phụ kiện | Chân dung tĩnh dùng `UPDATE_ONCE`; animation đủ frame/clip, không giật lúc chọn; đo thời gian bake/readback, RAM/VRAM và khôi phục app; lỗi quay về sprite đóng gói sẵn |
| QA-52 | Mua/chọn mèo trong bộ sưu tập sau MVP | Migration progress, ID ổn định, danh sách Vườn chỉ có mèo đã mua và ban đầu rỗng; mèo mặc định chọn lại bằng nút riêng. Mua một lần, chỉ chọn mặc định hoặc mèo đã mua; đủ clip tương ứng cho mọi mèo bán. Mọi ô `cat`/given và hoạt ảnh theo mèo đang chọn; vùng vẫn đọc qua nền/nhãn/họa tiết. Đổi mèo không đổi nghiệm/board/điểm; fallback lỗi tải và cache đúng |
| QA-53 | Quảng cáo thưởng cứu lượt khi thiếu vàng | Chỉ hiện khi thiếu vàng và quảng cáo sẵn có; xác nhận thưởng hợp lệ cấp đúng một lần như QA-47. Hủy/lỗi/offline/crash không cấp tim hoặc trừ vàng, giữ màn chờ; Retry miễn phí vẫn dùng được |
