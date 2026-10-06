# Asset Backlog — Audio

Danh mục âm thanh và hướng chỉnh SFX hiện hành cho CanDoKu.
Mọi âm thanh phải là bản thu/tổng hợp gốc — không sao chép từ reference.

19 SFX hiện được tổng hợp PCM khi khởi động bằng [engine âm thanh](../game/scripts/feedback/pcm_synth.gd). Chủ dự án chọn tiếp tục dùng âm thanh bằng code để nghe và chỉnh qua tuner; không cần gen file SFX bên ngoài. BGM là hạng mục riêng.

## Chuẩn kỹ thuật chung

- BGM release: `.ogg` Vorbis, 48 kHz; bản WAV hiện có dùng để nghe thử trong game
- SFX hiện hành: PCM mono 16-bit, 22050 Hz, sinh bằng `pcm_synth.gd`; sample clamp trước khi encode
- BGM: stereo (44.1 kHz chấp nhận), −14 LUFS integrated, loop seamless (tail khớp head)
- BGM đặt dưới `game/assets/audio/bgm/`; SFX lấy preset từ `game/scripts/feedback/sfx_catalog.gd`
- MARK, UNMARK, CANDY_YES và CANDY_NO có biến thiên pitch 0.94–1.06; tiếng bấm UI dùng cùng một pitch để giữ nhất quán. MARK giữ giới hạn 100 ms trừ bước vuốt phát theo từng ô

---

## A. BGM — nhạc nền (`game/assets/audio/bgm/`)

Code hiện dùng `bgm-candoku-melody.wav` để nghe thử; bản `main_theme.ogg` theo chuẩn release vẫn cần hoàn thiện và nối vào app.

| # | File | Vai trò | Loop | Mood |
|---|------|---------|------|------|
| 1 | `main_theme.ogg` | **Bắt buộc.** Nhạc chủ đạo xuyên title + puzzle | 60–90 s | nhẹ nhàng, thiền puzzle, không drum lớn, melodic đơn giản |
| 2 | `menu_calm.ogg` | *Tùy chọn.* Riêng title/menu, biến thể bớt nhạc cụ của #1 | 40–60 s | tối giản, bass pad + 1–2 nhạc cụ |
| 3 | `focus_rain.ogg` | *Tùy chọn.* Chế độ tập trung cho người chơi lâu | 60–90 s | ambient, không melody rõ |

> Release đầu chỉ cần #1. #2–#3 khi mở "Chọn nhạc" trong Options.

---

## B. SFX hiện hành — procedural PCM

15 preset tone, 2 melody, 1 preset pencil scratch và 1 tiếng quỵt Settings được prewarm tại `SfxPlayer._ready()`, phát qua pool 8 voice. `MARK` có cả preset tone cũ trong `PRESETS` nhưng runtime và tuner ưu tiên `PENCIL_PRESETS`; tổng cộng là **19 effect**. Không cần các file `.ogg` SFX. Toggle audio tắt cả gameplay và tiếng nút trong composition root.

| Effect | Sự kiện | Thời lượng | Preset |
|---|---|---|---|
| `MARK` | Đánh X | 176 ms trước speed | pencil scratch hai nét; preset tone 60 ms không dùng |
| `UNMARK` | Xóa X | 55 ms | pop mềm đi lên |
| `CANDY_YES` | Kẹo đúng | 140 ms | sine sweep lên, noise nhẹ |
| `CANDY_NO` | Kẹo sai | 180 ms | square sweep xuống, low-pass |
| `HINT_SHOW` | Dùng gợi ý | 74 ms | tiếng bấm chung `UI_TICK` |
| `STAGE_CLEAR` | Thắng | 440 ms | 4 nốt đi lên |
| `STAGE_FAIL` | Thua | 520 ms | 4 nốt đi xuống |
| `BTN_PRESS` | Nút UI | 74 ms | tiếng gỗ ấm “tíc ky”: triangle trầm, chút noise đầu âm, low-pass |
| `BOARD_OPEN` | Vào puzzle | 250 ms | triangle sweep lên |
| `RESTART`, `TAP_BACK`, `TOGGLE_ON` / `TOGGLE_OFF`, `DIALOG_OPEN` / `DIALOG_CLOSE`, `UNDO_X` | Chơi lại, Back/Home, cài đặt, dialog, Undo thành công | 74 ms | dùng chung `UI_TICK`; khi tắt Audio, mute có thể chặn cue tắt |
| `SETTINGS_OPEN` | Mở Settings từ Home hoặc puzzle | 110 ms | tiếng gậy vụt nhanh qua không khí, kết bằng cú “tách” khô ngắn |
| `PROGRESS_COMPLETE` | Đạt nửa số kẹo cần tự tìm, một lần mỗi màn | 260 ms | nốt thưởng nhỏ hơn thắng màn |
| `LOCK_TICK` | Chỉ nghe trong tuner | 55 ms | dành cho auto-lock nếu cơ chế này được đưa trở lại; hiện không có trigger gameplay |

**Chỉnh âm thanh:** mở `game/scenes/sfx_tuner.tscn` trong Godot, nhấn F6; chọn một trong 19 effect, chỉnh control rồi Play/Space. Chọn `BTN_PRESS` để nghe tiếng bấm chung; chỉnh một lần tại `UI_TICK` trong `sfx_catalog.gd` sẽ áp dụng cho mọi hành động dùng chung. Chọn `SETTINGS_OPEN` để chỉnh riêng tiếng vụt gậy; `noise_mix` điều khiển phần gió, `snap_mix` điều khiển cú “tách” ngắn, `high_pass`/`low_pass` điều chỉnh độ sáng của tiếng vụt. Thanh `speed (pitch)` cho phép nghe ở 0,5–2,0×; đổi tốc độ phát cũng đổi cao độ và thời lượng nghe. `Copy Params` ghi dictionary, gồm `speed`, vào clipboard và console; tuner chỉ preview, **không tự lưu preset vào game**. Dán cấu hình nút vào `UI_TICK`, các âm khác vào `PRESETS`; riêng `MARK` dán vào `PENCIL_PRESETS`, thắng/thua dán vào `MELODY_PRESETS` và giữ chuỗi `freqs`/`note_dur`. Player dùng `speed` từ preset và nhân với biến thiên pitch nếu effect đó có random pitch. Enum pitch dùng `PcmSynth.PitchCurve` để tránh trùng class Godot.

Engine tự giữ attack tối thiểu 5 ms và release tối thiểu 10 ms, kể cả khi slider đặt 0 hoặc tổng ADSR vượt duration. Âm dưới 15 ms co hai ramp theo tỷ lệ; mỗi âm/nốt có mẫu đầu/cuối bằng 0 để tránh bước nhảy từ/về silence. Các giá trị xuất ra vẫn là tham số bạn chọn, không phải envelope đã fit.

Các preset cần nghe thử trên loa/tai nghe và thiết bị mục tiêu để duyệt âm sắc, độ lớn, click/pop và cảm giác trong gameplay.

---

## C. Ý tưởng SFX chưa dùng trong gameplay

Các mục dưới đây là ý tưởng lịch sử, **không cần gen hoặc thêm effect** trong phạm vi hiện tại. Back, toggle, dialog và Undo đã có effect riêng ở mục B. `LOCK_TICK` có preset để nghe nhưng chưa phát trong game.

| Ý tưởng | Lý do chưa dùng |
|---|---|
| Toast riêng | Thông báo hiện tại chưa có cue/trigger riêng. |
| Hoàn tất vùng hoặc hàng/cột | Mỗi kẹo đúng đã hoàn tất một hàng, cột, vùng; sẽ trùng `CANDY_YES`. Cue `PROGRESS_COMPLETE` dùng mốc nửa màn rõ hơn. |
| Chọn ô hoặc pulse xung đột | Gameplay hiện không có trạng thái chọn ô riêng. |

**Biến thể bổ sung:** pitch variation hiện áp dụng cho năm effect. Nếu cần nhiều âm sắc, chỉnh preset hoặc mở rộng bộ tổng hợp trong một task polish riêng.

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
- [ ] File `.ogg.import` được Godot tạo lại sau khi copy vào `game/assets/audio/bgm/`
- [ ] Chạy thử: event tương ứng phát đúng, không delay > 50 ms
- [ ] Credit/nguồn ghi trong `docs/CREDITS.md` (nếu dùng library royalty-free)
