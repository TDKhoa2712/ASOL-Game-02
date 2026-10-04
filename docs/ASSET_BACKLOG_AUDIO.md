# Asset Backlog — Audio

Danh sách audio cần sản xuất cho CanDoKu.
Mọi âm thanh phải là bản thu/tổng hợp gốc — không sao chép từ reference.

## Chuẩn kỹ thuật chung

- Định dạng: `.ogg` Vorbis, 48 kHz
- SFX: mono, 16-bit, −10 dBFS peak, không fade dài, không reverb nặng
- BGM: stereo (44.1 kHz chấp nhận), −14 LUFS integrated, loop seamless (tail khớp head)
- Đặt dưới `game/audio/bgm/` và `game/audio/sfx/`
- SFX bắn liên tục (MARK, TAP, CANDY_YES) nên có 2–3 biến thể chống nhàm

---

## A. BGM — nhạc nền (`game/audio/bgm/`)

Code yêu cầu: `app_shell.gd:72` → `main_theme.ogg`

| # | File | Vai trò | Loop | Mood |
|---|------|---------|------|------|
| 1 | `main_theme.ogg` | **Bắt buộc.** Nhạc chủ đạo xuyên title + puzzle | 60–90 s | nhẹ nhàng, thiền puzzle, không drum lớn, melodic đơn giản |
| 2 | `menu_calm.ogg` | *Tùy chọn.* Riêng title/menu, biến thể bớt nhạc cụ của #1 | 40–60 s | tối giản, bass pad + 1–2 nhạc cụ |
| 3 | `focus_rain.ogg` | *Tùy chọn.* Chế độ tập trung cho người chơi lâu | 60–90 s | ambient, không melody rõ |

> Release đầu chỉ cần #1. #2–#3 khi mở "Chọn nhạc" trong Options.

---

## B. SFX bắt buộc — đã nối trong code (`game/audio/sfx/`)

9 file khớp key trong `sfx_catalog.gd:17-25`. Thiếu file = im lặng khi chơi.

| # | File | Sự kiện | Thời lượng | Mô tả âm sắc |
|---|------|---------|------------|---------------|
| 1 | `mark.ogg` | Đánh/bỏ dấu X một ô | 80–150 ms | tick ngắn, high-mid, không ngân |
| 2 | `candy_found.ogg` | Đặt kẹo **đúng** | 150–300 ms | chord nhẹ đi lên, "pleasant" |
| 3 | `candy_wrong.ogg` | Đặt kẹo **sai** / vi phạm luật | 150–300 ms | thud mềm/buzz ngắn, không gắt |
| 4 | `hint.ogg` | Hiện gợi ý | 300–500 ms | shimmer/sparkle, 2 nốt lên |
| 5 | `win.ogg` | Giải xong level | 1.2–2.0 s | fanfare ngắn, tươi sáng |
| 6 | `fail.ogg` | Hết lượt/thua | 0.8–1.2 s | descending, không bi lụy |
| 7 | `tap.ogg` | Nhấn nút UI chung | 60–120 ms | click nhẹ, neutral |
| 8 | `enter.ogg` | Mở bàn chơi (vào puzzle) | 300–500 ms | whoosh + chime ngắn |
| 9 | `restart.ogg` | Chơi lại từ đầu | 200–400 ms | rewind nhẹ, "reset" cảm giác |

---

## C. SFX nên bổ sung — cần mở thêm enum trong `sfx_catalog.gd`

Backlog cho sprint polish.

| # | File | Trigger | Thời lượng | Ghi chú |
|---|------|---------|------------|---------|
| 10 | `tap_back.ogg` | Nhấn nút Back | 80–120 ms | pitch thấp hơn `tap` 1 bậc |
| 11 | `toggle_on.ogg` | Bật switch Options | 100–150 ms | pitch lên |
| 12 | `toggle_off.ogg` | Tắt switch Options | 100–150 ms | pitch xuống |
| 13 | `dialog_open.ogg` | Mở dialog/popup | 200–350 ms | air swell nhẹ |
| 14 | `dialog_close.ogg` | Đóng dialog | 150–250 ms | ngược lại #13 |
| 15 | `toast_show.ogg` | Hiện toast/notification | 150–250 ms | soft pop |
| 16 | `undo.ogg` | Hoàn tác (Undo X) | 150–250 ms | reverse swish ngắn |
| 17 | `region_complete.ogg` | Giải xong một vùng | 300–500 ms | nhỏ hơn `win`, hint reward |
| 18 | `row_complete.ogg` | Giải xong 1 hàng/cột | 250–400 ms | tương tự #17, pitch khác |
| 19 | `select_cell.ogg` | Chọn ô (feedback focus) | 50–100 ms | cực ngắn, rất nhẹ |
| 20 | `conflict_pulse.ogg` | Highlight xung đột | 200–300 ms | wobble/low thud |

**Biến thể chống nhàm:** làm 2–3 bản `mark_a/b/c.ogg`, `tap_a/b.ogg`, `candy_found_a/b.ogg`, `select_cell_a/b.ogg`. Cần mở rộng `sfx_player.gd` để random chọn biến thể.

---

## D. Nice-to-have — chỉ khi có bandwidth

| # | File | Dùng khi |
|---|------|----------|
| 21 | `countdown_tick.ogg` | Chế độ timed |
| 22 | `countdown_final.ogg` | 3 giây cuối countdown |
| 23 | `star_award.ogg` | Trao sao trong result screen |
| 24 | `score_count.ogg` | Nhảy số điểm (loopable tick ngắn) |
| 25 | `combo_small.ogg` → `combo_big.ogg` | Hệ combo (3 cấp, tên gốc — KHÔNG dùng tên reference) |

---

## E. Checklist bàn giao mỗi file audio

- [ ] Tên file đúng danh sách, snake_case
- [ ] Không chứa trademark/giọng nói/âm mèo thương mại của reference
- [ ] Peak không clip; SFX ≤ −10 dBFS, BGM đo LUFS meter
- [ ] File `.ogg.import` được Godot tạo lại sau khi copy vào `game/audio/`
- [ ] Chạy thử: event tương ứng phát đúng, không delay > 50 ms
- [ ] Credit/nguồn ghi trong `docs/CREDITS.md` (nếu dùng library royalty-free)
