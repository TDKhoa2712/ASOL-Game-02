# Asset Backlog — Audio

Danh sách audio cần sản xuất cho CanDoKu.
Mọi âm thanh phải là bản thu/tổng hợp gốc — không sao chép từ reference.

9 SFX hiện được tổng hợp PCM khi khởi động bằng [engine âm thanh](../game/scripts/feedback/pcm_synth.gd). BGM vẫn cần tài sản âm thanh riêng; các SFX bổ sung phía dưới là backlog, chưa triển khai.

## Chuẩn kỹ thuật chung

- BGM/tài sản file: `.ogg` Vorbis, 48 kHz
- SFX hiện hành: PCM mono 16-bit, 22050 Hz, sinh bằng `pcm_synth.gd`; sample clamp trước khi encode
- BGM: stereo (44.1 kHz chấp nhận), −14 LUFS integrated, loop seamless (tail khớp head)
- BGM đặt dưới `game/audio/bgm/`; SFX lấy preset từ `game/scripts/feedback/sfx_catalog.gd`
- MARK, CANDY_YES, CANDY_NO và BTN_PRESS có biến thiên pitch 0.94–1.06; MARK giữ giới hạn 100 ms

---

## A. BGM — nhạc nền (`game/audio/bgm/`)

Code yêu cầu: `app_shell.gd` → `main_theme.ogg`

| # | File | Vai trò | Loop | Mood |
|---|------|---------|------|------|
| 1 | `main_theme.ogg` | **Bắt buộc.** Nhạc chủ đạo xuyên title + puzzle | 60–90 s | nhẹ nhàng, thiền puzzle, không drum lớn, melodic đơn giản |
| 2 | `menu_calm.ogg` | *Tùy chọn.* Riêng title/menu, biến thể bớt nhạc cụ của #1 | 40–60 s | tối giản, bass pad + 1–2 nhạc cụ |
| 3 | `focus_rain.ogg` | *Tùy chọn.* Chế độ tập trung cho người chơi lâu | 60–90 s | ambient, không melody rõ |

> Release đầu chỉ cần #1. #2–#3 khi mở "Chọn nhạc" trong Options.

---

## B. SFX hiện hành — procedural PCM

7 preset một âm và 2 melody được prewarm tại `SfxPlayer._ready()`, phát qua pool 8 voice. Không cần các file `.ogg` SFX. Toggle audio tắt cả gameplay và tiếng nút trong composition root.

| Effect | Sự kiện | Thời lượng | Preset |
|---|---|---|---|
| `MARK` | Đánh/bỏ X | 60 ms | triangle sweep lên |
| `CANDY_YES` | Kẹo đúng | 140 ms | sine sweep lên, noise nhẹ |
| `CANDY_NO` | Kẹo sai | 180 ms | square sweep xuống, low-pass |
| `HINT_SHOW` | Gợi ý | 200 ms | sine sweep lên |
| `STAGE_CLEAR` | Thắng | 440 ms | 4 nốt đi lên |
| `STAGE_FAIL` | Thua | 520 ms | 4 nốt đi xuống |
| `BTN_PRESS` | Nút UI | 40 ms | triangle click |
| `BOARD_OPEN` | Vào puzzle | 250 ms | triangle sweep lên |
| `RESTART` | Chơi lại | 150 ms | triangle sweep xuống |

**Chỉnh âm thanh:** mở `game/scenes/sfx_tuner.tscn` trong Godot, nhấn F6; chọn preset, chỉnh control rồi Play/Space. Copy Params ghi dictionary vào clipboard và console. Dán vào `PRESETS`; với thắng/thua, dán vào `MELODY_PRESETS` và giữ chuỗi `freqs`/`note_dur`. Enum pitch dùng `PcmSynth.PitchCurve` để tránh trùng class Godot.

Các preset cần nghe thử trên loa/tai nghe và thiết bị mục tiêu để duyệt âm sắc, độ lớn, click/pop và cảm giác trong gameplay.

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

**Biến thể bổ sung:** pitch variation hiện đã áp dụng cho bốn effect. Nếu cần nhiều âm sắc, thêm preset tổng hợp hoặc thiết kế cơ chế biến thể trong một task polish riêng.

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

## E. Checklist bàn giao BGM hoặc tài sản audio file bổ sung

- [ ] Tên file đúng danh sách, snake_case
- [ ] Không chứa trademark/giọng nói/âm mèo thương mại của reference
- [ ] Peak không clip; SFX ≤ −10 dBFS, BGM đo LUFS meter
- [ ] File `.ogg.import` được Godot tạo lại sau khi copy vào `game/audio/`
- [ ] Chạy thử: event tương ứng phát đúng, không delay > 50 ms
- [ ] Credit/nguồn ghi trong `docs/CREDITS.md` (nếu dùng library royalty-free)
