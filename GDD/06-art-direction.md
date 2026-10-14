# GDD-06 — Art Direction

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-06 |
| Phiên bản | 1.0.0 |
| Trạng thái | Approved · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Liên quan | [GDD-02](02-core-gameplay.md), [GDD-04](04-ux-ui.md), [GDD-07](07-audio.md), [GDD-08](08-technical-design.md), [GDD-09](09-qa-acceptance.md) |

> **Tóm tắt:** Chương này chốt ngôn ngữ hình ảnh của CanDoKu: tông kẹo ngọt ấm, bàn chơi đọc rõ ở mọi kích thước 4×4–12×12, hệ màu 12 vùng có kiểm tương phản tự động, sáu loại kẹo, quy cách animation/VFX kèm thời lượng thật trong code, và danh mục asset với trạng thái Done/Needed cùng checklist bàn giao.

## 1. Mục đích và phạm vi

- Định nghĩa art direction, mood và nguyên tắc nguyên gốc cho toàn bộ hình ảnh trong game.
- Chuẩn hóa token màu, typography, UI component và motion để art, design và code dùng chung một nguồn.
- Liệt kê asset hiện có và asset còn thiếu, kèm quy cách bàn giao.
- Ngoài phạm vi: luật chơi ([GDD-02](02-core-gameplay.md)), bố cục màn hình và flow ([GDD-04](04-ux-ui.md)), âm thanh và haptics ([GDD-07](07-audio.md)), ngân sách hiệu năng ([GDD-08 §9](08-technical-design.md#9-ngân-sách-hiệu-năng)).

Nguồn sự thật của token là code: `game/scripts/theme/palette.gd`, `candy_palette.gd`, `layout_tokens.gd`, `font_tokens.gd`. Khi tài liệu và code lệch nhau, theo code và cập nhật tài liệu.

## 2. Visual direction và mood

**Design intent.** CanDoKu là puzzle logic thư giãn. Hình ảnh phải *ấm, ngọt, sạch*: bàn chơi là một lưới ô màu sạch sẽ chia thành các vùng màu, mỗi lần suy luận đúng là một lần lật ô để lộ viên kẹo giấu bên dưới. Không có backdrop cảnh vật hay câu chuyện bối cảnh; tất cả tập trung vào bàn ô màu và kẹo. Mọi trang trí phục vụ khả năng đọc bàn chơi; bàn chơi luôn là thứ rõ nhất trên màn hình.

| Trụ cột | Diễn giải | Hệ quả thiết kế |
| --- | --- | --- |
| Ngọt và ấm | Nền kem, viền gỗ nâu, điểm nhấn cam/vàng mật | Nền `BG_CREAM #FFFDF5`, bảng `BOARD_BG #FFF8DC`, viền `BOARD_BORDER #5A3410` |
| Đọc rõ trước, đẹp sau | Vùng phân biệt bằng màu có tương phản đo được; X và kẹo nổi trên mọi màu vùng | Region painter kiểm ΔE76; X có nền trắng mờ và nét đậm |
| Xúc giác (tactile) | Ô, nút và thẻ có độ dày như vật thật | Ô có `CELL_DEPTH_RATIO 0.065`; nút 3D có bóng đổ dưới |
| Thưởng nhỏ, thường xuyên | Mỗi kẹo đúng có pop, combo có word-art và voice | Animation ngắn ≤ 0,9 s, không chặn input |
| Không trừng phạt | Thua là "suýt nữa", không u ám | Màn thua tông lavender, mây mưa nhẹ, mascot buồn dễ thương |

**Không làm:** backdrop vườn/cảnh vật hoặc motif lá, hoa, giỏ; phối cảnh làm méo ô; trang trí che lưới, tim hoặc nút; hiệu ứng tiết lộ đáp án; texture photo-real; nhân vật hoặc giao diện mô phỏng sản phẩm thương mại khác.

### 2.1 Tham chiếu phong cách (nguyên gốc)

Tham chiếu chỉ là các mockup nội bộ của dự án: `game/assets/ui/source/board.png`, `avatar-game.png`, `logo_candoku_full.png` và quyết định [RST-024](../docs/DECISIONS.md). Không dùng ảnh chụp, asset, tên hay bố cục từ game thương mại làm reference sản xuất. Mascot kẹo cánh nhỏ, logo chữ từng ký tự và word-art combo là thiết kế gốc của dự án.

## 3. Hệ màu

### 3.1 Màu vùng (zone colors)

Mười hai màu vùng trong `palette.gd` (`ZONE_COLORS`). Chín màu đầu là màu chủ đạo theo mockup; ba màu cuối là màu dự phòng, chỉ dùng khi bàn có nhiều vùng hoặc không màu chủ đạo nào giữ được tương phản.

| # | Tên | Hex | Nhóm | Shape colorblind |
| --- | --- | --- | --- | --- |
| 1 | Pink | `#F5B0D2` | Chủ đạo | Circle |
| 2 | Green | `#93DB7F` | Chủ đạo | Square |
| 3 | Lavender | `#C9A9F0` | Chủ đạo | Triangle |
| 4 | Mint | `#A2E8D5` | Chủ đạo | Diamond |
| 5 | Yellow | `#FFD54A` | Chủ đạo | Star |
| 6 | Orange | `#FFB06E` | Chủ đạo | Heart |
| 7 | Blue | `#70C7E8` | Chủ đạo | Plus |
| 8 | Violet | `#9D8BE6` | Chủ đạo | Drop |
| 9 | Rose | `#E98BA8` | Chủ đạo | Ring |
| 10 | Lime | `#D9E86A` | Dự phòng | Crescent |
| 11 | Coral | `#F08A7E` | Dự phòng | Hexagon |
| 12 | Sand | `#C9A27E` | Dự phòng | Triangle-down |

Màu là theme mapping, không nằm trong level JSON. Đổi màu không đổi nghiệm, session hay `puzzleHash`.

### 3.2 Quy tắc region painter

`game/scripts/content/region_painter.gd` gán màu cho từng vùng khi mở bàn ([RST-024](../docs/DECISIONS.md)).

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-16 | Hai vùng kề nhau (chung cạnh) có khoảng cách màu CIELAB ΔE76 ≥ 20 (`MIN_ADJACENT_CONTRAST`) | `test_region_contrast.gd` pass trên toàn bộ bank 4×4–12×12 |
| ART-17 | Gán màu theo thứ tự bậc kề giảm dần (degree order), ưu tiên 9 màu chủ đạo, sau đó toàn palette; nếu greedy không đạt tương phản thì backtracking DFS với ngân sách 20.000 bước tìm tập màu duy nhất | Bàn N ≤ 12 không có hai vùng kề trùng màu |
| ART-18 | Mỗi vùng có một màu riêng khi số vùng ≤ 12; không dùng lại màu đã gán trừ khi hết lựa chọn | Kiểm bằng `test_colorblind.gd`/`test_region_contrast.gd` |
| ART-19 | Chế độ colorblind vẽ thêm một shape (12 loại, `OverlayIcon`) lên mọi ô của vùng; shape gắn cố định với màu (màu → shape không đổi giữa các màn); shape tô bằng màu vùng tối 60% với alpha thấp | Bật/tắt trong Settings đổi ngay trên bàn đang chơi |

### 3.3 Màu UI chính

| Vai trò | Token | Hex |
| --- | --- | --- |
| Nền app | `BG_CREAM` | `#FFFDF5` (trùng màu boot splash) |
| Nền bàn | `BOARD_BG` | `#FFF8DC` |
| Viền bàn / icon hint | `BOARD_BORDER` | `#5A3410` |
| Viền vàng bàn | `BOARD_GOLD_EDGE` | `#EFD27E` |
| Chữ chính (navy) | `BOARD_NAVY` | `#23365E` |
| Nút xanh (Help/Settings) | `BOARD_BLUE` / `BOARD_BLUE_EDGE` | `#3D8BEB` / `#2463B0` |
| Nút Hint | `BOARD_HINT_BG` / `BOARD_HINT_EDGE` | `#FFC93C` / `#A9700A` |
| Nút Play (Home) | `HOME_BUTTON_BG` / shadow | `#D9620F` / `#9A3A08` |
| Tim đầy | `HEART_FILLED` / dark / stroke | `#F5414F` / `#C9212F` / `#7A1018` |
| Tim rỗng | `HEART_EMPTY` / stroke | `#F1ECE0` / `#A89E88` |
| Nét X | `MARK_STROKE` | `#344054` trên nền `MARK_WHITE` (trắng 88%) |
| Lỗi | `ERROR_X` (`candy_palette.gd`) | `#D94040` |
| Hint highlight | `hint_highlight_layer.gd` | `#F59E0B`, scrim nâu ấm 32% |
| Contradiction chain | giả thiết / bước / mâu thuẫn | `#EF4444` / `#F59E0B` / `#DC2626` |
| Màn thắng | ribbon / nút | `#FF9533` / `#1F9A4B`, nền vàng tỏa `#FFE08A` |
| Màn thua | ribbon / nút | `#7466D1` / `#D9620F`, nền lavender `#D3C6EC` |
| Độ khó (pill) | easy / medium / hard / expert | `#22894C` / `#B05F0A` / `#C02C52` / `#6A2CC0` |

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-20 | Chữ thân đạt tương phản ≥ 4.5:1 trên nền; dấu X, viền vùng và icon trạng thái ≥ 3:1 | Đo bằng công cụ contrast trên screenshot thật; ghi vào evidence QA |
| ART-21 | Chế độ high contrast tăng nét X (`X_STROKE_RATIO_HC 0.12` thay `0.09`) và dùng texture X riêng | Bật high contrast, X dày hơn rõ trên mọi màu vùng |

## 4. Kẹo (candy visuals)

**Design intent.** Kẹo là phần thưởng thị giác của mỗi suy luận đúng. Một level dùng **một loại kẹo** cho mọi ô để không tạo nhiễu thông tin; loại kẹo đổi theo tiến trình để tạo cảm giác mới.

| Loại | File | Màu chủ đạo (`candy_palette.gd`) |
| --- | --- | --- |
| `bonbon` | `assets/candy/bonbon.png` | thân `#E8847A`, giấy gói `#FFD18A` |
| `lollipop` | `lollipop.png` | xoắn `#D94F4F`/`#FFF5F0`, que `#C4A882` |
| `gummy_drop` | `gummy_drop.png` | `#5DC9A8` |
| `hard_candy` | `hard_candy.png` | `#9B7ED8` |
| `toffee` | `toffee.png` | thân `#A06E2E`, giấy bạc `#E8C34A` |
| `cotton_puff` | `cotton_puff.png` | `#F4B8C1` |

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-02 | Kẹo chiếm `CANDY_TEX_RATIO` = 74% cạnh ô, căn giữa; không che viền vùng | Screenshot N=4 và N=12 |
| ART-13 | Một level dùng một loại kẹo cho mọi ô; texture dùng chung, cache theo loại; alpha và pivot nhất quán giữa sáu loại | `test_candy_renderer.gd` |
| ART-22 | Loại kẹo theo nhãn level: L01–L05 `bonbon`, L06–L10 `lollipop`, L11–L15 `gummy_drop`, L16–L20 `hard_candy`, L21–L25 `toffee`, L26–L30 `cotton_puff`; nhãn khác hoặc ngoài 1–30 dùng `bonbon` (`candy_renderer.gd`) | `test_candy_renderer.gd` |
| ART-23 | Fallback tải texture: `<type>.png` → `<type>.svg` → `candy_icon.png` → `assets/ui/board/candy.svg`; lỗi asset không làm hỏng session | Xóa thử một PNG trong build debug, bàn vẫn hiển thị |

Màu kẹo không mang ý nghĩa luật và không phụ thuộc màu vùng. Kẹo đã đặt luôn ở lại ô đến hết level; trên bàn có idle animation nhẹ (tối đa 6 kẹo idle đồng thời, `candy_anim_state.gd`).

## 5. Hiển thị trạng thái ô

Bốn trạng thái ô theo `CellKind` ([GDD-02](02-core-gameplay.md)). Không có ô given và không có ô locked.

| Trạng thái | Hiển thị | Ghi chú |
| --- | --- | --- |
| `BLANK` | Ô màu vùng, bo góc `CELL_CORNER_RATIO 0.20`, có độ dày dưới | Nền vùng là kênh nhận diện chính |
| `MARK` | X vẽ tay (hand-drawn), padding 28% ô, nét 9% ô (tối thiểu 4 px), cong nhẹ `X_BOW_RATIO`; nét `#344054` trên lót trắng | Texture pre-baked cho X tĩnh ([RST-023](../docs/DECISIONS.md)) |
| `CANDY` | Sprite kẹo 74% ô | Pop khi đặt |
| `ERROR` | X đỏ `#D94040` + badge cảnh báo tròn ở góc trên phải (bán kính 9%/7% ô) | Phân biệt với X thường bằng màu **và** badge, đọc được ở thang xám |

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-03 | X thường và X lỗi phân biệt được khi chuyển ảnh sang thang xám | Kiểm screenshot grayscale |
| ART-24 | Bàn N ≥ 7 phóng nội dung ô theo `cell_content_scale = 1 + (N−6)·0.06` để X/kẹo vẫn đọc được trên ô nhỏ | Screenshot 12×12 trên màn 360 dp |
| ART-01 | Viền vùng là đường dày liên tục giữa hai vùng khác nhau; khe ô `cell_gap_ratio` ≤ 10% bước ô | `test_board_fit.gd`, `test_responsive_layout.gd` |

## 6. Typography

| Vai trò | Font | Weight | File |
| --- | --- | --- | --- |
| Heading, ribbon, số lớn | Be Vietnam Pro | Bold, Regular | `assets/fonts/BeVietnamPro-*.ttf` |
| Body, nút, caption | Nunito | Regular, SemiBold, Bold | `assets/fonts/Nunito-*.ttf` |
| Fallback CJK (ja, ko) | Noto Sans CJK (subset) | — | `assets/fonts/NotoSansCJK-subset.ttf` |

Thang cỡ (`layout_tokens.gd`): Title 32, Heading 24, Body 16, Caption 12, chữ trong ô 30. Large text hiện luôn bật toàn cục (`LARGE_TEXT_TOGGLE = false`, `text_scaler.gd`), ô Large Text trong Settings bị ẩn. Giấy phép: SIL OFL (`assets/fonts/LICENSE-OFL.txt`).

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-25 | Mọi chuỗi trong 7 ngôn ngữ (en, ja, vi, id, pt_BR, es, ko) hiển thị đủ glyph, không ô vuông thiếu ký tự | `test_font_cjk_fallback.gd`, `test_web_glyphs.gd` |

## 7. Phong cách UI

| Thành phần | Quy cách | Nguồn |
| --- | --- | --- |
| Nút 3D | Thân màu đặc + bóng đổ cùng tông tối hơn ngay dưới (ví dụ Play `#D9620F` / `#9A3A08`); chữ trắng có text-shadow; nhấn thì thân dịch xuống che bóng | `ui/action_button.gd` |
| Nút tròn trên cùng | Nền trắng hoặc xanh `#3D8BEB`, viền `#2463B0`, icon SVG | `assets/ui/home/`, `assets/ui/board/` |
| Thẻ (card) | Bo `CARD_CORNER 24` (bàn chơi 32), bóng mềm nâu 15%, nền kem | `ui/stat_card.gd` |
| Pill | Bo 28, nền `#FFF6E2` | `screens/pill_toggle.gd` |
| Ribbon | Băng màu có đuôi gấp, chữ Be Vietnam Pro Bold | `ui/ribbon_banner.gd` |
| Nền | Gradient tỏa tâm trắng → kem → vàng (Home/Win) hoặc lavender (Fail) | `ui/gradient_bg.gd` |
| Spacing | Gutter 16, stack 12, section 24 | `layout_tokens.gd` |

Vùng chạm tối thiểu và bố cục từng màn: xem [GDD-04](04-ux-ui.md).

## 8. Animation và VFX

**Design intent.** Motion xác nhận hành động ngay lập tức, kết thúc nhanh và không bao giờ chặn input hoặc quyết định kết quả. Hiệu ứng không tự cộng điểm, trừ tim, lưu game hay xác định thắng.

| ID | Sự kiện | Hiệu ứng | Thời lượng | Nguồn |
| --- | --- | --- | --- | --- |
| ART-06 | Đặt X | X vẽ hai nét tuần tự | 150 ms (100 ms khi N ≥ 10) | `puzzle_board.gd`, `cell_animator.gd` |
| ART-07 | Kẹo đúng | Scale pop 1,15× rồi về 1× | 250 ms | `tween_fx.scale_pop` |
| ART-26 | Combo | Word-art (atlas 512×128) bật 0,3→1,15→1×, giữ, bay lên 40 px và mờ; sparkle từ cấp 9 | ~1,1 s (0,14 + 0,08 + 0,33 + 0,35) | `combo_popup.gd`, [RST-026](../docs/DECISIONS.md) |
| ART-08 | Kẹo sai | Rung bàn biên độ 4 px; X đỏ + badge hiện ở 80% tiến trình vẽ | 250 ms | `cell_animator.gd`; rung bàn theo cả công tắc haptic và motion |
| ART-27 | Mở bàn | Board entry wave: sweep 500 ms + pop ô 340 ms | 840 ms | `board_entry_wave.gd` |
| ART-28 | Hint | Spotlight scrim + glow nhấp nháy (bobbing pulse) trên ô mục tiêu | Lặp tới khi Apply/Dismiss | `hint_highlight_layer.gd` |
| ART-09 | Thắng | Ribbon rơi 800 ms; tim pop 600 ms, cách nhau 250 ms; thẻ trồi 700 ms, cách 200 ms; confetti rơi 3,2–6,2 s; tia sáng xoay chu kỳ 22 s; nút Next nhịp 1,4 s; kẹo trên bàn nhảy "win" | Nút thao tác được ngay | `win_screen.gd`, `layout_tokens.gd` |
| ART-10 | Thua | Ribbon lavender, tim nứt xám, mây mưa, mascot buồn trồi 700 ms | Nút Retry dùng ngay | `fail_screen.gd` |
| ART-29 | Home | Logo vào 900 ms (shader shine ở splash), nút Play nhịp, mascot chuyển động nhẹ | — | `title_screen.gd`, `splash/logo_shine.gdshader` |
| — | Chuyển cảnh / fade | Transition 200 ms, fade 150 ms | — | `layout_tokens.gd` |

Hằng `AUTO_MARK_STAGGER_MS` và `LOCK_FADE_MS` vẫn có trong `layout_tokens.gd` nhưng không còn được dùng (không có auto-mark).

### 8.1 Reduced motion

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-11 | Khi bật `reduced_motion`, mọi tween qua `tween_fx` chạy với speed scale 1000× (về trạng thái cuối ngay), giữ đủ tín hiệu và thông tin; rung bàn khi sai bị tắt | `test_tween_fx.gd`; bật reduced motion, chơi thắng/thua không có chuyển động dài |

## 9. Danh mục asset

Trạng thái: **Done** = có trong `game/assets/` và đang dùng; **Needed** = còn thiếu cho release; **Backlog** = tùy chọn.

### 9.1 Nhận diện và nền tảng

| ID asset | File | Trạng thái |
| --- | --- | --- |
| ART-A01 | App icon `assets/icons/candoku-logo-{1024,512,192}.png` + `.svg` | Done |
| ART-A02 | Logo chữ Home `assets/ui/home/logo/letter_*.png`, `sparkle.svg`, `swirl_candy.svg` | Done |
| ART-A03 | Splash (`splash/splash_screen.tscn`, nền `#FFFDF5`, shader shine) | Done |
| ART-A04 | Adaptive icon Android (foreground/background tách lớp) và bộ icon iOS đủ cỡ | Needed |
| ART-A05 | Store assets: screenshot 5–8 tấm/ngôn ngữ chính, feature graphic 1024×500 | Needed |

### 9.2 Gameplay

| ID asset | File | Trạng thái |
| --- | --- | --- |
| ART-A10 | Sáu sprite kẹo `assets/candy/{bonbon,lollipop,gummy_drop,hard_candy,toffee,cotton_puff}.png` + `candy_icon.png` | Done |
| ART-A11 | X mark `assets/ui/board/x_mark.svg` (+ X vẽ tay procedural) | Done |
| ART-A12 | Tim: `heart.svg`, `heart_off.svg`, `heart_small.svg`, `heart_icon*.png`, mảnh nứt `heart_grey_*` | Done |
| ART-A13 | Icon bàn chơi: back, help, hint, restart, settings, undo (`assets/ui/board/icon_*.svg`) | Done |
| ART-A14 | Combo word-art atlas 12 cấp `assets/ui/combo/combo_atlas.png/.json` (build bằng `tools/build_combo_atlas.py`) | Done |
| ART-A15 | Shape colorblind: vẽ procedural (`zone_shape.gd`) | Done |
| ART-A16 | Icon assist inventory (place-candy, badge số lượng, popup hết lượt) | Planned |

### 9.3 Mascot và trang trí

| ID asset | File | Trạng thái |
| --- | --- | --- |
| ART-A20 | Mascot kẹo cánh: thân, mặt (8 biểu cảm), cánh, chân, tay, fx, bóng `assets/candy/*.svg` | Done |
| ART-A21 | Atlas animation mascot `assets/candy/anim/mascot_atlas.png/.json` | Done |
| ART-A22 | Confetti, sunburst, twinkle, mưa, mây (procedural trong `game/scripts/ui/` + `assets/ui/result/*.svg`) | Done |

### 9.4 Màn hình và Settings

| ID asset | File | Trạng thái |
| --- | --- | --- |
| ART-A30 | Icon Home: play, help, settings (`assets/ui/home/`) | Done |
| ART-A31 | Icon Result: home, next, replay; confetti vuông; mưa (`assets/ui/result/`) | Done |
| ART-A32 | Tile Settings: audio on/off, music on/off, haptic, reduced motion, large text, colorblind (`assets/ui/settings/*.png`) | Done |
| ART-A33 | Icon tile high contrast riêng | Needed |
| ART-A34 | Icon on/off riêng cho haptic, reduced motion, colorblind (hiện một ảnh, trạng thái thể hiện bằng màu) | Backlog |
| ART-A35 | Khung dialog/toast 9-patch dùng chung (hiện vẽ bằng StyleBox) | Backlog |

### 9.5 File nguồn

`assets/ui/source/` giữ mockup gốc (`board.png`, `avatar-game.png`, `logo_candoku_full.png`, `studio.svg`) và `extraction.json`. Không xuất trong build release nếu không được tham chiếu.

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| ART-05 | Mọi asset có nguồn gốc, tác giả/công cụ, giấy phép và file nguồn truy được | Có dòng trong `docs/CREDITS.md` hoặc README của thư mục nguồn |
| ART-04 | Trang trí (mascot, confetti, sparkle) không che lưới, tim, nút hay luật | Screenshot review mỗi màn |
| ART-12 | Không có skin bán, bộ sưu tập ngoại hình hoặc `appearanceId` trong v1 | Không có field liên quan trong save |

## 10. Quy cách bàn giao asset

| Hạng mục | Quy cách |
| --- | --- |
| Raster | PNG RGBA, sRGB, cạnh lề trong suốt đồng nhất; kẹo xuất ≥ 256×256 |
| Vector | SVG phẳng (không filter, không font nhúng) cho icon và shape đơn giản |
| Atlas | PNG + JSON khung; build bằng script trong `tools/` khi có |
| Nén GPU | Project bật ETC2/ASTC (`textures/vram_compression/import_etc2_astc`) |
| Đặt tên | `snake_case`, theo thư mục `assets/<nhóm>/` hiện có |
| Viewport | Thiết kế ở 1080×1920 portrait, stretch `canvas_items`/`expand` |

### Checklist bàn giao

- [ ] Tên file đúng danh mục, `snake_case`, đặt đúng thư mục.
- [ ] Tác phẩm gốc; không sao chép giao diện, nhân vật, tên hay asset thương mại.
- [ ] Màu khớp token trong `palette.gd`/`candy_palette.gd`; thêm token mới nếu cần, không hard-code.
- [ ] Đọc được ở bàn 12×12 trên màn 360 dp và ở thang xám.
- [ ] Godot tạo lại file `.import`; build không cảnh báo thiếu resource.
- [ ] Chạy `test_candy_renderer.gd`, `test_colorblind.gd`, `test_region_contrast.gd`, `test_screens.gd`.
- [ ] Ghi credit/giấy phép vào `docs/CREDITS.md`.

## 11. ID đã hủy

| ID | Lý do |
| --- | --- |
| ART-14 | Không có trạng thái ô LOCKED (bỏ auto-mark) |
| ART-15 | Không có kẹo given (givens bị loại toàn hệ thống) |

## 12. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| ART-Q1 | Chưa đo tương phản chữ/X trên thiết bị thật cho cả 12 màu vùng | Có thể không đạt ART-20 ở Yellow/Lime | Đo trong đợt QA thiết bị (Track E) |
| ART-Q2 | Loại kẹo chỉ đổi cho nhãn L01–L30; campaign_100 từ L31 trở đi luôn `bonbon` | Giảm cảm giác mới ở campaign dài | Quyết định mapping loại kẹo cho L31+ |

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất GDD 06 (phần mỹ thuật) và ASSET_BACKLOG_VISUAL, cập nhật theo code hiện hành |
