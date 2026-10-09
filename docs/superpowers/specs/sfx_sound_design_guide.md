# CanDoKu — Sound Design & AI SFX Generation Guide

> **Mục tiêu:** Thay thế toàn bộ hệ thống âm thanh tự sinh đơn điệu (`PcmSynth`) bằng bộ SFX chất lượng cao (Tactile, Juicy, Satisfying ASMR, Pastel Aesthetic) phù hợp với phong cách kẹo ngọt của CanDoKu.  
> **Phong cách âm học chủ đạo (Aesthetic):** Ngọt ngào, giòn tan, mọng nước, nảy nở nhẹ nhàng (Juicy, Crunchy Candy, Soft Marshmallow, Playful Percussion, Sparkling Bells). Tuyệt đối tránh âm thanh chói tai, kim loại sắc nhọn hoặc tiếng ồn gây mệt tai (ear fatigue).

---

## 1. Chuẩn Kỹ Thuật Khi Tạo & Xuất File (Technical Specs)

- **Định dạng file:** `.wav` (16-bit / 24-bit PCM, 44.1 kHz hoặc 48 kHz, Mono) cho SFX ngắn; `.ogg` (Vorbis 48 kHz, Stereo) cho đoạn nhạc thắng/thua hoặc BGM.
- **Thời lượng (Duration):** 
  - Âm thao tác lặp lại (Mark, Unmark, Tap, Tick): **50 ms – 120 ms** (Cực ngắn, không có đuôi ngân dài).
  - Âm hành động (Candy Yes, Candy No, Hint): **150 ms – 350 ms**.
  - Âm kết quả (Stage Clear, Stage Fail): **1.5 s – 2.5 s**.
- **Xử lý hậu kỳ (Post-Processing):**
  - **Zero Delay:** Cắt sạch khoảng lặng (trim silence) ở đầu file (đảm bảo độ trễ phản hồi < 5ms).
  - **Loudness & Peak:** Peak tối đa trong khoảng `-6 dBFS` đến `-3 dBFS`. Không để clip vỡ tiếng.
  - **Micro Fade-out:** Fade-out 5ms ở đuôi file để tránh tiếng lộp bộp (click/pop) khi cắt âm thanh.

---

## 2. Bảng Danh Mục SFX & Prompt Tiếng Anh Chuẩn Studio

### Nhóm 1: Tương Tác Bàn Cờ Cốt Lõi (Core Gameplay — Tần Suất Cao)
> *Các âm thanh này phát liên tục theo từng chạm ngón tay. Yêu cầu âm sắc mềm mại, tự nhiên, tạo cảm giác xúc giác (tactile).*

| # | Mã Hiệu / Tên File | Sự Kiện Kích Hoạt | Độ Dài | Mô Tả Âm Học | Prompt Tiếng Anh (Dùng cho AI) |
|---|---|---|---|---|---|
| 01 | `sfx_mark_x.wav` | Chạm đơn / vuốt đánh dấu X | 80–120ms | Tiếng quẹt bút chì/phấn mềm trên giấy nhám mịn, giòn nhẹ, tự nhiên. | `Crisp soft pencil mark on paper, short satisfying tactile sketch sound, dry quick stroke, minimal Foley, game UI, 0.1s` |
| 02 | `sfx_unmark_x.wav` | Chạm / vuốt xóa dấu X | 50–80ms | Tiếng bong bóng nước nổ bụp hoặc kẹo cao su bật ra êm ái, thỏa mãn (bubble pop). | `Soft satisfying bubble pop, cute juicy popping sound, gentle water drop pop, clean UI sound effect, 0.08s` |
| 03 | `sfx_candy_yes.wav` | Chạm đúp đặt kẹo ĐÚNG nghiệm | 200–300ms | Khoảnh khắc thưởng lớn: tiếng kẹo cứng va chạm trong trẻo pha chuông lấp lánh (dopamine chime). | `Sparkling magical chime, sweet candy crystal ding, bright cheerful chime notification, joyful bell chime, cute puzzle game, 0.25s` |
| 04 | `sfx_candy_no.wav` | Chạm đúp đặt kẹo SAI (mất tim) | 200–250ms | Cảnh báo tiếc nuối hoạt hình nhẹ nhàng, không gay gắt; tiếng "uh-oh" hoặc còi mềm trầm. | `Gentle cartoon wrong buzzer, soft sweet error buzz, mild cute mistake sound, muffled negative blip, casual puzzle game, 0.25s` |
| 05 | `sfx_heart_break.wav` | Tim vỡ rơi vụn khi mất mạng | 250–350ms | Tiếng thủy tinh kẹo ngọt/đường giòn rạn nứt vỡ tan nhẹ nhàng. | `Delicate sugar candy heart cracking and shattering softly, glass candy brittle crunch, cute foley, 0.3s` |
| 06 | `sfx_lock_tick.wav` | Hệ thống tự khóa ô (auto-mark) | 30–50ms | Cực ngắn, khô, gõ lách cách như hạt cườm gỗ hoặc quân cờ domino trượt lướt. | `Tiny crisp wooden domino click, micro wood block tap, subtle short percussive tick, minimal foley UI, 0.04s` |
| 07 | `sfx_progress_half.wav` | Đạt mốc 50% số kẹo ("Giỏi lắm!") | 300–450ms | Chuỗi 3 nốt mộc cầm (glockenspiel/xylophone) đi lên vui tươi, khuyến khích. | `Bright cute 3-note ascending xylophone chime, sweet encouraging melody, happy puzzle reward sound, 0.4s` |
| 08 | `sfx_undo.wav` | Bấm nút Hoàn tác (Undo X) | 100–150ms | Tiếng gió lướt ngược êm, cảm giác tua lại thời gian nhẹ nhàng. | `Subtle reverse air whoosh, soft cute rewind swish, gentle vacuum pop, minimal game UI, 0.15s` |

---

### Nhóm 2: Hệ Thống Gợi Ý (Hint System)

| # | Mã Hiệu / Tên File | Sự Kiện Kích Hoạt | Độ Dài | Mô Tả Âm Học | Prompt Tiếng Anh (Dùng cho AI) |
|---|---|---|---|---|---|
| 09 | `sfx_hint_show.wav` | Bấm Hint, spotlight chiếu sáng | 350–500ms | Tiếng bụi phép thuật lấp lánh, tiếng đũa thần lung linh huyền ảo. | `Magical fairy dust twinkle, enchanting shimmer chime sweep, celestial sparkle sound effect, cute casual game, 0.5s` |
| 10 | `sfx_hint_apply.wav` | Bấm Áp dụng (Apply) gợi ý | 250–350ms | Nốt đàn hạc gảy trong trẻo, xác nhận thao tác thành công mỹ mãn. | `Sweet harp pluck chord, bright positive affirmation chime, gentle magic reward ding, 0.3s` |
| 11 | `sfx_hint_dismiss.wav` | Đóng bảng Hint Overlay | 120–180ms | Tiếng lướt gió mềm hạ tone, đóng nhẹ êm tai. | `Soft gentle UI dismiss whoosh, subtle smooth swipe away, quiet casual menu close, 0.15s` |
| 12 | `sfx_hint_wrong_mark.wav` | Cảnh báo đánh X nhầm ô kẹo | 200–250ms | Hai nốt marimba gõ tò mò, nhắc nhở thân thiện không phán xét. | `Curious two-note marimba tap, gentle cute alert plink, non-intrusive friendly puzzle notification, 0.25s` |

---

### Nhóm 3: Giao Diện & Điều Hướng (UI & Menus)

| # | Mã Hiệu / Tên File | Sự Kiện Kích Hoạt | Độ Dài | Mô Tả Âm Học | Prompt Tiếng Anh (Dùng cho AI) |
|---|---|---|---|---|---|
| 13 | `sfx_btn_press.wav` | Bấm nút UI chung (Play, Cards) | 60–90ms | Tiếng bấm kẹo dẻo marshmallow êm ái, nảy nhẹ và ấm áp. | `Satisfying marshmallow button tap, sweet tactile wooden button click, cute UI pop, 0.08s` |
| 14 | `sfx_tap_back.wav` | Bấm Back / Về Home | 70–100ms | Nốt gỗ ấm trầm hơn nốt bấm chính, báo hiệu quay lui. | `Mellow low-pitch wooden tap, soft subtle back button click, casual mobile game UI, 0.08s` |
| 15 | `sfx_toggle_on.wav` | Gạt công tắc BẬT trong Settings | 60–80ms | Tiếng tách công tắc giòn, nốt cao sáng sủa vui mắt. | `Crisp sweet switch toggle on, bright cheerful mechanical click, pleasant UI switch sound, 0.07s` |
| 16 | `sfx_toggle_off.wav` | Gạt công tắc TẮT trong Settings | 60–80ms | Tiếng tách công tắc êm dịu, nốt trầm nhẹ. | `Soft muted switch toggle off, gentle subtle downward click, minimal UI switch sound, 0.07s` |
| 17 | `sfx_dialog_open.wav` | Mở thẻ Luật chơi / Hộp thoại | 120–180ms | Tiếng nảy mở thẻ hoạt hình, bóng khí phồng lên vui tươi. | `Cute springy pop-up sound, soft cartoon bubble opening, gentle paper unfold UI chime, 0.15s` |
| 18 | `sfx_dialog_close.wav` | Đóng thẻ Luật chơi / Hộp thoại | 100–150ms | Tiếng gấp thẻ hoặc đóng cửa sổ nhanh, tinh tế. | `Soft popup closing tap, gentle subtle tuck sound, minimal mobile UI, 0.12s` |
| 19 | `sfx_settings_open.wav` | Mở màn hình Cài đặt | 120–180ms | Tiếng quẹt gió lụa mượt mà, dứt điểm bằng tiếng tách nhẹ. | `Smooth clean UI whoosh, soft ribbon swipe sound, gentle airy transition with tiny subtle snap, 0.15s` |
| 20 | `sfx_restart.wav` | Bấm chơi lại màn chơi | 250–350ms | Tiếng xốc xúc xắc hoặc xáo trộn kẹo vui tai làm mới bàn cờ. | `Playful quick candy rattle shuffle, gentle wooden blocks reset swirl, cute puzzle board refresh, 0.3s` |

---

### Nhóm 4: Bắt Đầu & Kết Thúc Màn (Stage Lifecycle)

| # | Mã Hiệu / Tên File | Sự Kiện Kích Hoạt | Độ Dài | Mô Tả Âm Học | Prompt Tiếng Anh (Dùng cho AI) |
|---|---|---|---|---|---|
| 21 | `sfx_board_open.wav` | Bắt đầu màn / Bàn cờ trượt vào | 350–500ms | Chuỗi lướt đàn hạc (glissando) và chuông gió đón người chơi vào bàn cờ. | `Sweet ascending harp glissando, magical xylophone cascade, gentle welcoming puzzle board entry sound, 0.45s` |
| 22 | `sfx_stage_clear.ogg` | Thắng màn / Hoàn thành bàn cờ | 1.8–2.5s | Đoạn nhạc chiến thắng rực rỡ, kèn đồng đồ chơi + mộc cầm + tiếng sao lấp lánh. | `Joyful cute victory fanfare jingle, celebratory xylophone, brass and chime flourish, cheerful game win melody, 2s` |
| 23 | `sfx_stage_fail.ogg` | Thua màn / Hết tim | 1.2–1.8s | Giai điệu mộc cầm đi xuống dí dỏm, tiếng giọt mưa buồn đáng yêu (không u ám). | `Cute whimsical game over jingle, gentle descending marimba melody, soft cartoon sad trombone feel, lighthearted defeat, 1.5s` |
| 24 | `sfx_confetti.wav` | Pháo giấy bung ở màn thắng (Option) | 200–300ms | Tiếng nổ bụp pháo giấy mini vui nhộn. | `Cute party popper pop, celebration confetti burst sound effect, cheerful mini party cracker, 0.25s` |

---

## 3. Quy Trình Nhập Audio Vào Dự Án CanDoKu

Sau khi bạn tạo xong các file audio:
1. **Lưu trữ file:** Đặt toàn bộ file vào thư mục:
   - SFX: `game/assets/audio/sfx/`
   - BGM: `game/assets/audio/bgm/`
2. **Cấu hình Godot:**
   - Chọn file trong FileSystem của Godot $\rightarrow$ Tab **Import**:
   - Đối với SFX ngắn: định dạng `WAV` giữ nguyên, đặt `Compress: Off` để không delay.
   - Đối với SFX dài / BGM: định dạng `OGG Vorbis`, đặt `Loop: false` cho SFX và `Loop: true` cho BGM.
3. **Cập nhật danh mục:** File `sfx_catalog.gd` sẽ được cập nhật trỏ thẳng vào đường dẫn `res://assets/audio/sfx/<tên_file>.wav` thay cho hàm tính sóng procedural `PcmSynth`.
