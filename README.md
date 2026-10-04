# CanDoKu

Tìm những viên kẹo bị đánh rơi trong vườn bằng suy luận.

CanDoKu là game puzzle 2D: mỗi hàng, cột và luống vườn đều giấu đúng một viên kẹo. Loại trừ những ô không thể có kẹo, rồi tìm đủ kẹo mà không cần đoán. Các viên kẹo không được chạm nhau, kể cả theo đường chéo.

## Hành trình trong vườn

Chiến dịch mặc định có 998 màn trên bàn 4×4, 5×5 và 6×6. Ba mươi màn đầu đi từ 4×4 (L01–L10) qua 5×5 (L11–L20) đến 6×6 (L21–L30). Mỗi màn là một khu vườn với những luống có hình dạng khác nhau. Một vài viên kẹo có thể được hé lộ từ đầu; hãy dùng chúng cùng các dấu X để suy ra vị trí còn lại. Trò chơi lưu tiến trình để bạn tiếp tục màn đang chơi.

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

## Chọn campaign để kiểm thử

Trước khi chạy hoặc export, sửa [active_campaign.json](game/data/campaigns/active_campaign.json):

```json
{"campaign": "full_998"}
```

Giá trị `full_998` chơi toàn bộ 998 màn và là mặc định; đổi thành `demo_30` để kiểm thử 30 màn đầu. Khởi động lại game sau khi sửa file. Nếu cấu hình sai hoặc playlist được chọn bị thiếu, game hiện lỗi khởi động.

Demo giữ progress và lượt đang chơi trong `user://profile`; chiến dịch đầy đủ dùng `user://profile/full_998`. Cài đặt chung nằm ở `user://profile/config.json`. Đổi mode không xóa save của mode kia. `demo_cross.json` chỉ dành cho test.

Người phát triển có thể tái tạo playlist từ bank bằng `rtk python -B GDD/tools/build_full_campaign.py --demo game/data/campaigns/demo_30.json --banks game/data/banks --output game/data/campaigns/full_998.json`. Dữ liệu được kiểm bằng `rtk python -B tools/validate_full_content.py --banks game/data/banks --playlist game/data/campaigns/full_998.json --demo game/data/campaigns/demo_30.json`.

Để mở rộng lại một bank từ bản gốc 30 level, chạy `rtk python -B GDD/tools/expand_bank.py --size 6 --bank PATH_TO_ORIGINAL_BANK --pace PATH_TO_ORIGINAL_PACE --checkpoint scratch/content_gen/full_bank/size6.json --seed candoku-full-bank-6-v1 --max-attempts 50000`. Thay hai đường dẫn bằng file bank/pace gốc; đổi `--size` và seed tương ứng cho 4×4/5×5. Ngân sách là tổng số lần thử nên có thể tăng và chạy tiếp với cùng checkpoint. Công cụ chỉ ghi bank/pace khi đủ số level và đã qua kiểm chứng. Giữ bản gốc 30 level riêng để tái tạo; bank trong game hiện đã đầy đủ. Ngưỡng rating và quy tắc xếp rank nằm trong [bank_expansion_rules.py](GDD/tools/bank_expansion_rules.py).
