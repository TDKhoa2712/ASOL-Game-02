# M07 Campaign và hướng mở rộng nội dung

> Ghi nhận ngày 2026-10-02 cho M07 khởi tạo tại commit `44e5e76` trên nhánh `feat/m07-campaign`.
> Đây là ghi chú bàn giao và phương án thiết kế cho giai đoạn sau, không phải quyết định mở phạm vi Endless. [STATUS](STATUS.md) là nguồn tiến độ hiện hành; [DECISIONS](DECISIONS.md) là nguồn quyết định sản phẩm.

## Đã thực hiện trong M07

- `game/scripts/campaign/bank_cursor.gd`: lưu `(size, rank, index, transform)`, duyệt bank và vòng qua 8 transform, hỗ trợ chuyển đổi từ/đến Dictionary. Khi bank rỗng, cursor giữ nguyên vị trí.
- `game/scripts/campaign/campaign_runtime.gd`: nhận BankReader, PaceReader, ProgressManager và SessionStore qua constructor; nạp playlist, bank và pace; khởi tạo hoặc khôi phục session; chỉ ghi tiến độ khi session đã thắng; giữ kết quả trong session để thử lưu lại sau lỗi ghi tiến độ, kể cả sau khi mở lại ứng dụng; xử lý thua, chơi lại level và replay campaign sau khi hoàn tất.
- `game/scripts/campaign/nav_controller.gd`: kiểm tra đường chuyển màn và phát signal khi chuyển hợp lệ.
- `game/scripts/campaign/tutorial_guide.gd`: theo dõi T1–T6 qua `tutorialSeenIds`, lưu milestone vào tiến độ và phát signal hướng dẫn.
- `game/tests/test_campaign_runtime.gd`: kiểm tra boot, lưu/khôi phục session, từ chối thắng khi chưa giải, thắng/thua, lỗi lưu và retry sau restart, hoàn tất và replay, transform, cursor, điều hướng và tutorial.

Kết quả thắng chờ ghi tiến độ được lưu trong snapshot session qua trường tùy chọn `pendingScoreData`. Các trường bắt buộc của session v3 giữ nguyên; dữ liệu chờ này được xóa cùng session sau khi ghi tiến độ thành công.

Godot 4.7.2 chạy `CAMPAIGN_RUNTIME_PASS`; full `tools/verify.py` đạt PASS sau sửa lỗi khôi phục thắng. Clean-room check không thấy tên cấm hoặc import từ `extracted_reusable` trong code kiểm tra. Log mới nhất: `scratch/verification/20261002T103420.821413Z.txt` (thư mục scratch không được commit). M07 đã commit trên nhánh riêng, chưa merge vào `dev`.

## Giới hạn và việc cần bổ sung trong phạm vi playtest

1. `demo_30.json` hiện chỉ có L01; bank 4×4 và pace sidecar cũng chỉ có một entry. Test chuyển L01→L02 dùng playlist giả lập trong test. Đây chưa phải campaign 30 level có thể chơi liên tiếp.
2. M10 cần tạo 30 level gốc, bank và pace tương ứng, playlist đầy đủ theo [plan M10](superpowers/plans/rebuild/10-content-gen.md). Từng tham chiếu `(size, rank, index)` phải tồn tại; bank và pace phải khớp vị trí.
3. M08/M09 cần nối runtime với màn hình, thao tác chơi và lưu/khôi phục thực tế; kiểm tra luồng thắng, thua, retry, replay, lỗi ghi và khởi động lại ứng dụng trên thiết bị.
4. M07 dùng `effective_plays() = bank_count × 8` để đếm lượt biến thể theo cursor. Con số này là giới hạn lượt duyệt, không bảo đảm từng biến thể là puzzle khác nhau nếu level có đối xứng.
5. Playtest 30 level vẫn cần gate nội dung, lượt giải mù, UI và thiết bị theo RST-011. Full verify của M07 không chứng nhận mốc playtest hoặc bản phát hành.

## Thiết kế đề xuất sau playtest: Endless

### Chọn nguồn nội dung

**Bước mở rộng ít rủi ro:** tạo và duyệt thêm level *offline*, đóng gói thành bank + pace như M10. Endless chọn entry đã duyệt theo rank, rồi chọn transform hợp lệ. Cách này dùng được `BankReader`, `PaceReader`, `BoardTransform` và `BankCursor` hiện có; số puzzle hữu hạn nên cần chính sách khi cạn nguồn.

**Nếu cần level mới vô hạn thực sự:** thiết kế bộ sinh khi chạy và ngân sách thời gian/bộ nhớ riêng. Mỗi level phải qua cùng validator, kiểm nghiệm và kiểm tra trùng lặp trước khi hiển thị. Đây là một tính năng khác với cursor hiện tại; chưa nằm trong R1 và chưa được phê duyệt.

### Ranh giới module và dữ liệu

- Giữ playlist `demo-30` và progress campaign độc lập với Endless. Tạo bộ chọn nguồn cho Endless, không lồng vòng lặp vô hạn vào `CampaignRuntime` đang quản lý playlist.
- Định nghĩa riêng trạng thái Endless: phiên bản dữ liệu, nguồn bank, `(size, rank, index, transform)`, thứ tự lượt đã chơi và định danh puzzle. Quy định cách khôi phục khi bank được cập nhật hoặc entry bị loại; không đổi progress v2/session v3 khi chưa có quyết định migration.
- Tạo định danh puzzle ổn định từ nội dung đã chuẩn hóa. Kiểm tra trùng lặp theo đối xứng để không tính 8 transform là 8 level mới khi chúng cho cùng puzzle.
- Xác định nhịp tăng rank, lựa chọn N=4–6, hint economy và cách xử lý khi bank/rank cạn. Dùng dữ liệu playtest để hiệu chỉnh; không suy difficulty chỉ từ `rank` hay transform.
- Thêm kiểm thử cho chuỗi nhiều bank/rank, khôi phục sau restart, thay đổi phiên bản dữ liệu, lỗi lưu, cạn bank, trùng puzzle và hiệu năng trên thiết bị mục tiêu.

### Dùng bản tham khảo đúng phạm vi

Có thể nghiên cứu *hành vi và dạng suy luận* của bản tham khảo để xác định mục tiêu độ khó, ví dụ nhịp giới thiệu S1–S3. Level đưa vào game phải được tạo mới theo luật và schema CanDoKu: không chép vùng, lời giải, givens, thứ tự level, seed, tên hoặc asset cụ thể. Công cụ generator offline hiện có trong `GDD/tools/` có thể tạo ứng viên; validator, kiểm tra nghiệm, proof và lượt duyệt người quyết định level nào được nhập bank. `MACHINE_VALIDATED` chưa đủ để coi là nội dung đạt chuẩn.

## Điều kiện để bắt đầu giai đoạn sau

Sau khi rebuild và playtest 30 level hoàn tất, chủ dự án quyết định Endless có cần thiết hay không, chọn giữa bank duyệt sẵn và sinh level khi chạy, đặt tiêu chí số lượng/độ khó/chống lặp và duyệt thay đổi lưu trữ nếu cần. Cho đến lúc đó, mục tiêu được giao vẫn là campaign 30 level, N=4–6, S1–S3, offline.
