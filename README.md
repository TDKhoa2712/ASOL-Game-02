# Vườn Mèo — thiết kế game giải đố

Repository hiện chứa [GDD v0.5.0](GDD/README.md), fixture và validator, chưa có game chạy được. Thiết kế hiện hành: **một dãy 24 level**, bàn 4×4–6×6; Level 1 là tutorial duy nhất; level 1–18 dùng S1/S2 và 19–24 bắt buộc cần S3. Một chạm hiện/ẩn X tức thì, kéo đánh/xóa X theo ô đầu, hai chạm nhanh cùng ô thử mèo. Ô có `empty`, `x`, `x_error`, `cat`; X đỏ khóa, giữ 3 tim, có Restart và Undo một action X gần nhất nhưng không Undo qua `TryCat`. Mỗi lượt có một Hint miễn phí; scorecard chỉ hiện ở Result. Thắng đi tới level kế, không có chương hoặc màn chọn level. Schema v4/validator chuẩn bị bàn tới N=12 cho tooling, còn release vẫn N≤6 và không dùng zoom/pan.

Luật chuẩn: [GDD/02-luat-choi-va-trang-thai.md](GDD/02-luat-choi-va-trang-thai.md). Hướng Godot 2D với sprite từ model 3D, màu/nhãn/họa tiết vùng độc lập và cache mèo: [GDD/05-kien-truc-va-du-lieu.md](GDD/05-kien-truc-va-du-lieu.md). Lộ trình: [GDD/08-ke-hoach-trien-khai-cho-agent.md](GDD/08-ke-hoach-trien-khai-cho-agent.md). S3 MVP cùng nghiên cứu S4/S5 ở [GDD/10](GDD/10-nghien-cuu-quy-tac-suy-luan.md); mọi meta/sinh level trong [GDD/11](GDD/11-ke-hoach-meta-va-sinh-level.md) đều là nghiên cứu post-MVP, không có interface trong bản đầu.

Từ thư mục gốc, kiểm fixture và test validator:

```text
python GDD/tools/validate_levels.py GDD/data/levels.sample.json
python -m unittest discover GDD/tools -p "test_*.py"
```

Cờ `--release` chỉ dùng cho bộ 24 level phát hành gốc; năm fixture hiện tại không thuộc bộ đó. Tên “Vườn Mèo” là tên tạm; Godot 4.x/GDScript và pipeline sprite 2D cần được xác nhận bằng prototype và đo trên thiết bị thật ở M0.
