# Quyết định điều hành hiện hành

> Quản lý version: [VERSIONING](VERSIONING.md)

## RST-024 — Màn chơi theo mockup `screen/screenshot/board.png`, màu vùng tương phản và hint đồng bộ giao diện

Ngày 2026-10-10.

- **Bố cục theo mockup, nội dung theo dữ liệu thật:** header (Back, “Màn n”, Trợ giúp, Restart, Settings), hàng kẹo vùng + 3 tim, 3 thẻ luật, bàn ô kẹo 3D không viền vùng, dock Undo/Hint. Số màn, vùng, màu, tim lấy từ session; không hiển thị số liệu giả.
- **Phân phối màu vùng — tô màu đồ thị tham lam (greedy graph coloring) theo CIELAB:** vùng là đỉnh, biên chung là cạnh; xếp vùng theo bậc giảm dần; màu chỉ hợp lệ khi ΔE76 tới mọi vùng kề đã tô ≥ `MIN_ADJACENT_CONTRAST` = 20; trong các màu hợp lệ chọn màu tối đa hóa ΔE nhỏ nhất tới láng giềng (ưu tiên màu chưa dùng). Bàn ≤ 9 vùng chỉ dùng `PRIMARY_COLOR_COUNT` = 9 màu chủ đạo của mockup; 3 màu dự phòng chỉ dùng khi thiếu. Kiểm bằng `test_region_contrast.gd` trên mẫu mọi bank 4×4–12×12.
- **Ô màu trơn:** mặc định ô chỉ có màu, không họa tiết. Chế độ hỗ trợ mù màu giữ nguyên màu và chỉ phủ thêm họa tiết lên nửa số vùng tối hơn (vùng kề không trùng họa tiết).
- **Thẻ luật:** icon 96, chữ 21 (`RULE_ICON_SIZE`, `RULE_FONT_SIZE` trong `puzzle_layout.gd`).
- **Hint:** engine giữ nguyên; phần hiển thị đổi theo giao diện mới: thẻ trắng viền vàng, nút 3D (Áp dụng vàng, Chi tiết/Đóng trắng), scrim spotlight tông nâu ấm. Badge số lượt trên nút Hint ẩn vì hint không giới hạn; chỉ hiện khi có quota thật.
- **Thanh Cheats** chỉ có trong bản debug (`OS.is_debug_build()`).

## RST-023 — Tối ưu hóa hiệu năng render và đánh dấu X trên bàn cờ lớn (Batched GPU Mark Texture & O(1) Sets)

Ngày 2026-10-08. Khắc phục triệt để hiện tượng giật lag khi đánh dấu X trên thiết bị di động ở các bàn cờ kích thước lớn ($N=7 \to 12$, lên tới 144 ô):

- **Pre-baked Vector Texture:** Tạo và lưu cache vĩnh viễn các texture X mark (`normal`, `high_contrast`, `error`) bằng ThorVG SVG rasterizer ngay trong bộ nhớ (`CellAnimator.get_mark_texture()`).
- **Batched 2D Rendering:** Các ô X tĩnh trên bàn cờ được vẽ thông qua `draw_texture_rect()`, cho phép 2D Canvas Batcher của Godot gom toàn bộ hàng chục tới hàng trăm ô X vào 1 Draw Call duy nhất, giảm $99\%$ số lượng vector draw calls (`draw_polyline`, `draw_circle`) và triệt tiêu hàng nghìn heap allocations mỗi giây.
- **Bảo toàn hoạt ảnh vẽ tay sống động:** Các ô X đang trong quá trình chuyển động (`_mark_anims.has(cell)`) vẫn duy trì hoạt ảnh vẽ tay uốn lượn progressive bằng `CellAnimator.draw_hand_drawn_x()`. Khi tween kết thúc, ô tự động chuyển sang chế độ batched texture.
- **O(1) Hash Set tra cứu:** Chuyển đổi tra cứu mảng tạm `_preview_cells.has([r, c])` và `_highlight_cells.has([r, c])` sang tra cứu từ điển `_preview_set.has(Vector2i(r, c))` và `_highlight_set.has(Vector2i(r, c))`, loại bỏ hoàn toàn việc cấp phát 288 mảng tạm thời trên heap mỗi frame.

## RST-022 — Tích hợp Swipe Guards 3 lớp bảo vệ cảm ứng (Velocity, Multi-Axis Freedom, Neighbor Guard)

Ngày 2026-10-08. Triển khai bộ bảo vệ cử chỉ vuốt 3 lớp vào `touch_guard.gd` và tích hợp qua `board_pointer_router.gd`:

- **Layer 1 (Velocity Gate):** Chặn các cú flick/cuộn vô ý quá nhanh vượt `MAX_VELOCITY_PX_PER_SEC = 6000.0 px/s`. Người chơi có thể lướt nhanh hàng loạt (3000–4500 px/s) qua các ô trên bàn cờ mà không bị chặn nhầm. Bỏ qua frame đầu tiên và frame cùng timestamp (dt=0).
- **Layer 2 (Multi-Axis Freedom — theo MeowDoku gốc):** Không snap cứng trục tọa độ. Người chơi hoàn toàn tự do di chuyển theo mọi hướng (ngang, dọc, chéo 8 hướng), không bị khóa trục nhầm khi bắt đầu nét vuốt.
- **Layer 3 (Neighbor Guard):** Kiểm tra ô kề hợp lệ 8 hướng (kể cả ô chéo kề cạnh theo Chebyshev <= 1). Cho phép cơ chế nội suy (`_interpolate_cells`) tự động nối liền mạch khi kéo nhanh qua các ô trên bàn cờ; chỉ chặn các bước nhảy bất thường vượt quá phạm vi bàn cờ (span > 12) hoặc tọa độ âm.
- **Tích hợp:** `board_pointer_router.gd` kiểm tra `verdict.allow`, truyền tọa độ thực tế của ngón tay, và kiểm tra ô cờ qua `filter_cell` trước khi chuyển tiếp sang `touch_decoder.gd`. Giữ nguyên tính độc lập của `touch_decoder.gd`.

## RST-021 — Giữ Undo X mặc định cố định, loại bỏ toggle cài đặt

Ngày 2026-10-08. Chủ dự án chốt: Undo X vẫn hoạt động bình thường trong gameplay (hoàn tác thao tác đánh dấu X gần nhất), nhưng không còn là tùy chọn bật/tắt trong màn hình Cài đặt (Options Screen):

- `puzzle_screen.gd`: Nút Undo X luôn hiển thị và hoạt động khi có session đánh dấu X.
- `options_screen.gd`: Loại bỏ tile "Hoàn tác X" khỏi danh sách `WIDE_KEYS`.
- `config_store.gd`: Loại bỏ key `"undo_x"` khỏi `DEFAULTS` và `EDITABLE_KEYS`.
- Cập nhật các test suite liên quan (`test_config_store.gd`, `test_screens.gd`) đồng bộ theo hành vi mới.

## RST-020 — Chuyển đổi 100% bank levels sizes 7–12 và mở rộng phạm vi N=4–12

Ngày 2026-10-07. Chủ dự án yêu cầu xử lý triệt để việc chuyển đổi bank, bảo toàn 100% level từ nguồn tham khảo, không bỏ sót các bài ở rank cao/kỹ thuật nâng cao:

- **Chính sách chuyển đổi 100%:** Thay thế ràng buộc chỉ chấp nhận bài giải được bằng S2/S3 offline. Đối với các bài yêu cầu kỹ thuật giải nâng cao (S4–S7), bổ sung cơ chế Fallback Logic Trace để hoàn thiện trace nghiệm, giữ nguyên phân loại kỹ thuật gốc (`r1..r5`), điểm `rating` và mã `pidHash`.
- **Phạm vi kích thước N=4–12:** Dự án hỗ trợ trọn vẹn toàn bộ các bank từ 4×4 đến 12×12. Tổng số 11.669 levels từ các bank chính 7×7–12×12 được đưa vào game (`game/data/banks/bank_*x*.json`), đi kèm file `.pace.json` tương ứng sinh 100%.
- **Chất lượng và kiểm định:** 55 bài bị hỏng mảng nghiệm từ dữ liệu nguồn bên thứ 3 (trong `bankDataGC11x11.json`) được phát hiện và loại bỏ thông qua kiểm định hình học Candy Rules. Toàn bộ các level còn lại đạt 100% chuẩn hợp lệ qua `tools/validate_content.py` và `level_validator.gd`.
- **Campaign & Endless:** Hỗ trợ chiến dịch mở rộng `advanced.json` (sizes 7–12) và chuẩn bị hạ tầng cấp level liên tục (Endless levels) sử dụng toàn bộ kho bank đồ sộ này.

## RST-019 — Bank đầy đủ và campaign chọn bằng file phát triển

Ngày 2026-10-05. Chủ dự án yêu cầu mở rộng theo quy mô tham khảo thành 998 level gốc, năm rank, đưa toàn bộ vào playlist và cho người phát triển đổi giữa chiến dịch đầy đủ với demo 30 màn qua file cấu hình.

- Ba bank v1 có lần lượt 36 level 4×4 (`12/10/8/3/3`), 49 level 5×5 (`12/10/8/9/10`) và 913 level 6×6 (`199/196/193/167/158`). Dùng luật S1–S3 và hình vùng, nghiệm, trace do CanDoKu sinh/kiểm độc lập.
- `full_998.json` giữ nguyên L01–L30 của `demo_30.json`, rồi phủ từng tham chiếu bank còn lại một lần. `active_campaign.json` có giá trị `full_998` mặc định hoặc `demo_30`; thay đổi có hiệu lực khi khởi động lại.
- Giữ hình vùng, nghiệm, ô cho sẵn và index của 90 puzzle cũ. Ba cặp puzzle 5×5 cũ trùng hệt nhau được giữ vì yêu cầu giữ puzzle gốc.

## RST-018 — Demo 30 màn tăng từ 4×4 đến 6×6

Ngày 2026-10-04. Chủ dự án chốt demo có 30 màn, chia đều ba kích thước:

- Playlist mặc định `game/data/campaigns/demo_30.json`: L01–L10 là 4×4, L11–L20 là 5×5, L21–L30 là 6×6.
- Mỗi nhóm gồm 5 màn Rank 1, 3 màn Rank 2, 2 màn Rank 3; giữ tutorial tại L01/L02.
- Dùng bank và pace gốc hiện có; playlist `demo_cross.json` 45 màn tiếp tục phục vụ kiểm thử riêng.

---

## Lưu trữ — Quyết định giai đoạn rebuild (RST-001 → RST-017)

Các quyết định RST-001 đến RST-017 thuộc giai đoạn rebuild và realignment đã hoàn tất. Nội dung gốc được bảo toàn trong Git history (xem commit trước `2026-10-09`).

| ID | Ngày | Nội dung | Trạng thái |
|----|------|----------|------------|
| RST-017 | 2026-10-04 | Undo X có toggle cài đặt | **Thay bởi RST-021** |
| RST-016 | 2026-10-03 | Bỏ preview X khi chạm xuống | Đã implement |
| RST-015 | 2026-10-02 | Chỉnh lại gameplay/UI theo tham khảo | Đã implement |
| RST-014 | 2026-10-02 | Module 10 — Content Generation 30 levels | Đã implement |
| RST-013 | 2026-10-02 | Module 9 — Integration & lưu trữ mã cũ | Đã implement |
| RST-012 | 2026-10-02 | Rebuild 10 modules clean-room | Đã implement |
| RST-011 | 2026-10-01 | Playtest 30 level trước phát hành | **Đã mở rộng**: 36.500+ levels, N=4–12 |
| RST-010 | 2026-09-29 | Pilot generator offline | Đã implement |
| RST-009 | 2026-09-29 | Dọn tài nguyên thừa | Đã implement |
| RST-008 | 2026-09-29 | Chuyển đồng bộ CanDoKu GDD + code | Đã implement |
| RST-007 | 2026-09-28 | Tài liệu suy luận và sinh level | Đã implement |
| RST-006 | 2026-09-28 | CanDoKu và tinh gọn GDD | **Thay bởi RST-008** |
| RST-005 | 2026-09-27 | Pipeline gọn theo mục tiêu | Đã implement |
| RST-004 | 2026-09-25 | Bỏ ô sáng tutorial | Đã implement |
| RST-003 | 2026-09-25 | Replay campaign trong MVP | Đã implement |
| RST-002 | 2026-09-25 | Duyệt cải tổ và mở R1 | Đã implement |
| RST-001 | 2026-09-24 | Tạm ngưng, hợp nhất dev | Đã implement |
