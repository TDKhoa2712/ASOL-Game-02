# CanDoKu

Tìm những viên kẹo bị đánh rơi trong vườn bằng suy luận.

CanDoKu là game puzzle 2D: mỗi hàng, cột và luống vườn đều giấu đúng một viên kẹo. Loại trừ những ô không thể có kẹo, rồi tìm đủ kẹo mà không cần đoán. Các viên kẹo không được chạm nhau, kể cả theo đường chéo.

## Hành trình trong vườn

Vượt qua 30 màn chơi 4×4 theo thứ tự. Mỗi màn là một khu vườn với những luống có hình dạng khác nhau. Một vài viên kẹo có thể được hé lộ từ đầu; hãy dùng chúng cùng các dấu X để suy ra vị trí còn lại. Trò chơi lưu tiến trình để bạn tiếp tục màn đang chơi.

## Cách chơi

- Mỗi hàng, mỗi cột và mỗi luống có đúng một viên kẹo.
- Hai viên kẹo không được ở các ô kề nhau, kể cả kề góc.
- Chạm một lần để đánh hoặc xóa X; X chỉ là ghi chú.
- Kéo từ ô trống để đánh nhiều X, hoặc từ ô X để xóa nhiều X.
- Chạm đôi cùng một ô để thử tìm kẹo. Đúng thì hé lộ kẹo; sai mất một tim và tạo X đỏ khóa trong lượt.
- Mỗi lượt có ba tim và một Hint miễn phí. Hint giải thích suy luận, không tự điền đáp án.
- Undo hoàn tác thao tác X gần nhất; Restart bắt đầu lại màn. Hết tim có thể thử lại.

Tìm đủ kẹo để hoàn thành màn. Điểm xuất hiện ở màn kết quả.

## Thiết kế màn chơi

Các màn được xếp thành một hành trình liên tiếp, từ những bước suy luận đầu tiên đến các thế cờ cần kết hợp nhiều manh mối. Mỗi màn có một lời giải duy nhất. Kẹo cho sẵn, hình dạng luống và các ô đã loại trừ đều có thể giúp bạn tìm bước tiếp theo.

Xem thêm [luật chơi](GDD/02-luat-choi-va-trang-thai.md) và [nguyên tắc suy luận](GDD/10-nghien-cuu-quy-tac-suy-luan.md).

## Mở game

Mở `game/project.godot` bằng Godot 4 rồi nhấn **F5**. Hoặc chạy từ thư mục gốc:

```text
rtk godot --path game
```
