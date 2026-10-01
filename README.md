# CanDoKu

Tìm những viên kẹo bị đánh rơi trong vườn bằng suy luận.

CanDoKu là game puzzle 2D: mỗi hàng, cột và luống vườn đều giấu đúng một viên kẹo. Loại trừ những ô không thể có kẹo, rồi tìm đủ kẹo mà không cần đoán. Các viên kẹo không được chạm nhau, kể cả theo đường chéo.

## Trạng thái phát triển

Client Godot hiện có **bốn level kiểm thử R1**, tutorial, ghi chú X, Hint, Undo, kết quả thắng/thua và lưu tiến trình offline. Chủ đề và API hiện hành đã chuyển sang CanDoKu.

Mốc nội dung tiếp theo là **bản playtest trước phát hành gồm 30 level gốc, bàn 4×4 đến 6×6, tiếng Việt, Android và iOS**. Campaign 30 level chưa hoàn tất; đã có [generator pilot offline](docs/level-generation.md), nhưng ứng viên chưa qua playtest/UI để nhập campaign. Sau playtest, phạm vi bản phát hành chính thức mới được quyết định. Endless và hiệu chỉnh độ khó bằng dữ liệu người chơi vẫn để sau. Không có tài khoản, quảng cáo hoặc IAP trong phạm vi playtest.

Đây là bản đang phát triển, **chưa phải bản phát hành đã nghiệm thu**. Test headless đã đạt ở mốc code tích hợp; hành trình gesture đầy đủ và QA thiết bị còn cần thực hiện. Xem kết quả theo revision tại [STATUS](docs/STATUS.md).

## Cách chơi

- Mỗi hàng, mỗi cột và mỗi luống có đúng một viên kẹo.
- Hai viên kẹo không được ở các ô kề nhau, kể cả kề góc.
- Chạm một lần để đánh hoặc xóa X; X chỉ là ghi chú.
- Kéo từ ô trống để đánh nhiều X, hoặc từ ô X để xóa nhiều X.
- Chạm đôi cùng một ô để thử tìm kẹo. Đúng thì hé lộ kẹo; sai mất một tim và tạo X đỏ khóa trong lượt.
- Mỗi lượt có ba tim và một Hint miễn phí. Hint giải thích suy luận, không tự điền đáp án.
- Undo hoàn tác thao tác X gần nhất; Restart cần xác nhận. Hết tim có thể thử lại miễn phí.

Tìm đủ kẹo để hoàn thành màn. Điểm chỉ xuất hiện ở màn kết quả. Xem [luật chuẩn và tình huống mép](GDD/02-luat-choi-va-trang-thai.md).

## Thiết kế và level

- [GDD](GDD/README.md): thiết kế, luật, dữ liệu và tiêu chí QA.
- [Nguyên tắc suy luận](GDD/10-nghien-cuu-quy-tac-suy-luan.md): mô hình, chứng minh, phản ví dụ, trace và nền tảng Hint; phân biệt kỹ thuật hiện hành với mở rộng.
- [Sinh level và đánh giá độ khó](GDD/11-sinh-level-va-danh-gia-do-kho.md): yêu cầu tạo level, profile/seed, nghiệm duy nhất, trace, chống trùng, rating thử nghiệm và playtest.

Level dùng cho playtest phải có nghiệm duy nhất và lời giải suy luận hợp lệ, không yêu cầu đoán. Thang độ khó trong tài liệu chưa được hiệu chỉnh bằng người chơi. Fixture trong `GDD/data/` và campaign bốn level hiện tại không phải campaign playtest 30 level.

## Cấu trúc và tài liệu dự án

- [game](game/project.godot): client, scene, script và test.
- [AGENTS](AGENTS.md): cách làm; [CONTRIBUTING](CONTRIBUTING.md): đóng góp.
- [Tổng quan game](docs/GAME_OVERVIEW.md): trải nghiệm, luật, hiện trạng và mục tiêu playtest.
- [Technical stack](docs/TECH_STACK.md): engine, công cụ, dữ liệu, build và kiểm thử.
- [Architecture](docs/ARCHITECTURE.md): ranh giới module, luồng runtime, persistence và hướng tiến hóa.
- [ROADMAP](docs/ROADMAP.md): thứ tự; [STATUS](docs/STATUS.md): hiện trạng; [DECISIONS](docs/DECISIONS.md): quyết định.
- [Tra lịch sử pipeline cũ](docs/HISTORY.md).

`tools/` chứa runner kiểm chứng; `scratch/` chứa kết quả cục bộ và được Git ignore. `dev` là nhánh tích hợp; `main` giữ mốc lịch sử, không mặc định là bản phát hành đạt QA.

## Chạy game

Godot **4.7.2** là phiên bản đã dùng kiểm dự án. Trong Godot, chọn **Import**, mở `game/project.godot`, rồi nhấn **F5** để chạy từ entry scene. F6 chỉ chạy scene đang mở, không thay cho kiểm luồng Home → Puzzle → Result.

Hoặc chạy terminal tại thư mục gốc repo. Thay `godot` bằng executable trên máy nếu không có trong PATH. Các ví dụ dùng RTK theo hướng dẫn dự án; có thể bỏ tiền tố `rtk` nếu không cài công cụ này.

```text
rtk godot --editor --path game
rtk godot --path game
```

## Kiểm thử

Cần Python **3.11+** và Godot; công cụ Python dùng thư viện chuẩn. Chạy bộ kiểm chứng đầy đủ:

```text
rtk python -B tools/verify.py --godot "<duong-dan-Godot>"
```

Cũng có thể đặt `GODOT_BIN` rồi chạy `rtk python -B tools/verify.py`. Runner kiểm các nhóm test Python, hai bộ dữ liệu level và tất cả suite `game/tests/run_*.gd`. Log theo revision và fingerprint nằm ở `scratch/verification/` (Git ignore). Exit 0 là tất cả kiểm tra headless đạt; exit 1 là lỗi/thiếu công cụ/timeout. Có thể đặt `--timeout 180` (giây mỗi bước). GUI/thiết bị luôn được ghi NOT RUN.

Trong vòng sửa, chỉ chạy suite liên quan; ví dụ:

```text
rtk godot --headless --path game --script res://tests/run_mvp_runtime_tests.gd
rtk python -B -m unittest discover tools/tests -p test_verify.py
rtk python -B -m unittest discover GDD/tools -p "test_*.py"
rtk python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json
rtk python -B GDD/tools/validate_levels.py game/data/campaign_m1.json
```

Không lấy kết quả headless thay QA từ entry scene/thiết bị trong [kế hoạch R1](docs/plans/R1-playable-loop.md). Toàn bộ nội dung và tài sản phải là tác phẩm gốc.

## Đóng góp và sử dụng

Đọc [CONTRIBUTING](CONTRIBUTING.md) trước khi thay đổi. GDD 02 giữ luật chuẩn; DECISIONS ghi quyết định mới có hiệu lực. CanDoKu có bối cảnh, level, câu chữ, giao diện và tài sản riêng; tham khảo cơ chế không cho phép sao chép nội dung của game khác.

Repository chưa có tệp LICENSE. Việc công bố mã nguồn không tự cấp giấy phép sử dụng hoặc phân phối lại.
