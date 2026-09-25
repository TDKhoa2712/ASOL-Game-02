# Rà soát thiết kế và tổ chức dự án

Ngày 2026-09-25; baseline `1600898`. Đây là đánh giá tĩnh từ code và GDD, không phải kết quả chạy game. Gameplay vẫn tạm ngưng.

## Kết luận

Giữ Godot và các module hiện có. Ưu tiên sửa trách nhiệm quản lý trạng thái và tích hợp thành hành trình hoàn chỉnh; chưa có căn cứ viết lại game hoặc di chuyển hàng loạt thư mục. Tiến độ phải đo bằng hành vi người chơi đã được kiểm chứng, không bằng số package đóng.

## Phạm vi và quyền quyết định

- GDD 01–07 vẫn quy định bản đầu 24 level gốc, Android/iOS và tiêu chí QA. GDD 02 giữ luật chuẩn.
- GDD 11 là nghiên cứu sau MVP; GDD 12 là đề xuất Endless chờ duyệt văn bản. Không tự đưa generator, economy hoặc meta vào bản đầu.
- Chủ dự án chưa trả lời lựa chọn 24 level hay Endless. Kế hoạch dưới đây bám phạm vi hiện hành, không ghi nhận một phê duyệt mới.
- Bốn level hiện có có kích thước 4/5/6/6 trong `game/data/campaign_m1.json`; chúng phù hợp làm corpus tích hợp nhưng không thay thế yêu cầu bốn level mở đầu 4x4 của GDD. Trước R2 phải chuẩn hóa nội dung theo GDD hoặc có quyết định thay đổi riêng.

## Các điểm cần giải quyết khi hết tạm ngưng

| Bằng chứng tĩnh | Rủi ro / hành động trong R1 |
| --- | --- |
| `ui_flow_controller.gd` tự giữ/tăng chỉ số level; runtime cũng giữ tiến trình. Bootstrap chỉ đồng bộ lúc khởi tạo | Hai nguồn trạng thái có thể lệch khi Win → Home → Play. Runtime là nguồn tiến trình; flow chỉ điều hướng |
| `bootstrap.gd` bỏ qua ID kế tiếp từ tín hiệu thắng, Result hiển thị câu hoàn thành/ID thay cho điểm | Kiểm đường đi thật và hiển thị kết quả từ dữ liệu runtime |
| `mvp_runtime.gd` bỏ qua giá trị trả về của nhiều lệnh save, rồi có thể xóa session và phát tín hiệu thắng | Không công nhận chuyển trạng thái bền vững khi ghi thất bại; kiểm lỗi IO và crash |
| Runtime chỉ nhận session có hearts > 0; snapshot thiếu status; ID cuối campaign có thể là null | Kiểm resume trạng thái thua và kết thúc campaign; không tự reset/đưa về level đầu |
| Tutorial khởi tạo trước khi tải active level; API tutorial được gọi trực tiếp trong test, chưa nối hành vi board tương ứng | Nối milestone từ thao tác thật, target đúng và miễn phạt đúng phạm vi hướng dẫn |
| Help còn câu placeholder và mô tả bốn biểu tượng; Settings chưa có chức năng tương ứng | Đồng bộ UX theo luật hiện hành; không nghiệm thu bằng màn hình placeholder |
| Board toolbar đặt minimum width lớn; hồ sơ A12 từng báo label bị cắt | Tái hiện từ entry scene và đo layout thật; chưa kết luận lỗi cũ còn tồn tại trên build mới |
| Test runtime gọi bootstrap `_ready()` thủ công và `clear_saved_state()` trên runtime dùng đường dẫn mặc định | Cô lập profile test trước khi chạy; dùng scene tree lifecycle thật cho integration |
| Python smoke còn tìm marker bootstrap cũ | Kiểm tính còn phù hợp của assertion, không bỏ test chỉ để xanh |

Các file trên nằm tại `game/scripts/`, test tại `game/tests/`. Đây là các giả thuyết kiểm chứng và sai lệch hợp đồng đọc được, không phải danh sách lỗi đã tái hiện đầy đủ.

## Trách nhiệm kiến trúc đích

| Thành phần | Trách nhiệm |
| --- | --- |
| Runtime | Tiến trình, session hiện tại, kết quả và điều phối lưu; một nguồn sự thật |
| Flow | Màn hình hiện tại và nơi quay về; không tự tính level kế tiếp |
| Bootstrap | Khởi tạo dependency và nối scene/signals; không tính điểm hoặc tiến trình |
| Puzzle/session/input | Luật, thao tác và commit gesture; không tự làm IO |
| Repository | Đọc, kiểm hợp lệ, ghi atomic/backup và trả lỗi rõ ràng |
| Board/tutorial/hint UI | Hiển thị và chuyển thao tác thật tới logic; không giả lập milestone để vượt test |

Không đổi schema hay chữ ký API trong đợt tài liệu này. Khi triển khai, viết regression trước và sửa trong ranh giới nhỏ nhất đáp ứng hành vi.

## Tổ chức làm việc

- Một người phụ trách tích hợp xuyên suốt mục tiêu; không chia ownership cứng theo file/package.
- AGENTS giữ quy tắc; ROADMAP giữ thứ tự; STATUS giữ tiến độ; DECISIONS giữ lựa chọn làm thay đổi phạm vi/hợp đồng. Không chép trạng thái sang nhiều bảng.
- GDD giữ thiết kế sản phẩm. `work/` và governance cũ giữ bằng chứng lịch sử, không cấp quyền chạy package.
- Mỗi chặng có một báo cáo revision/build, hành vi đã kiểm, lỗi chặn và bước tiếp theo. Commit nhỏ theo thay đổi có thể kiểm chứng, không sinh thêm hồ sơ cho từng file.
- Giữ đường dẫn code/data/asset/evidence để tránh làm hỏng tham chiếu. Chỉ tách module khi một trách nhiệm cụ thể cần được tách.

## Nguồn lực và điểm còn chờ

| Nhu cầu | Khi cần / người chịu trách nhiệm |
| --- | --- |
| Chọn phạm vi 24 level hay Endless | Chủ dự án chốt trước khi thay phạm vi; hiện giữ GDD chuẩn |
| Android thật, OS và build mới | Chủ dự án cung cấp thiết bị; agent chuẩn bị kịch bản/evidence R1 |
| iPhone, Mac/Xcode và signing | Xác nhận nguồn lực sớm; thiếu thì ghi chặn QA iOS R4, không tự bỏ nền tảng |
| 3–5 người thử sớm, sau đó 10 người mới | Chủ dự án tuyển người; agent chuẩn bị kịch bản và tổng hợp R2 |
| Art đại diện, tên/logo, motif level 10/20 | Chốt trước sản xuất hàng loạt ở R3; đo atlas/bộ nhớ trên asset thật |
| Accessibility, chữ lớn, grayscale, reduced motion | Kiểm layout ở R1; nghiệm thu tương ứng trên build/thiết bị ở các chặng sau |

Không hứa ngày hoàn thành toàn dự án trước baseline R1 và lịch thiết bị/người thử. Bước kế tiếp là review [kế hoạch R1](../plans/R1-playable-loop.md), rồi tích hợp cải tổ khi được giao; chưa mở lại gameplay.
