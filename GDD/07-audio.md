# GDD-07 — Audio

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-07 |
| Phiên bản | 1.0.0 |
| Trạng thái | Approved · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Liên quan | [GDD-02](02-core-gameplay.md), [GDD-03](03-game-systems.md), [GDD-04](04-ux-ui.md), [GDD-06](06-art-direction.md), [GDD-08](08-technical-design.md) |

> **Tóm tắt:** CanDoKu dùng mô hình âm thanh lai: phần lớn SFX được tổng hợp procedural (PCM) lúc khởi động để chỉnh nhanh bằng tuner, còn melody thắng/thua, tiếng mở Settings, 12 combo voice và BGM là file OGG. Chương này chốt catalogue 34 effect, BGM, quy cách mix, haptics, tương tác với Settings và quy trình bàn giao asset audio.

## 1. Mục đích và phạm vi

- Định nghĩa audio direction và vai trò của âm thanh trong feedback loop.
- Liệt kê mọi effect trong `game/scripts/feedback/sfx_catalog.gd`, sự kiện kích hoạt và cách tạo âm.
- Chuẩn hóa mix, loudness, haptics và quy trình chỉnh/bàn giao.
- Ngoài phạm vi: logic combo ([GDD-03](03-game-systems.md)), animation đi kèm ([GDD-06 §8](06-art-direction.md#8-animation-và-vfx)), UI Settings ([GDD-04](04-ux-ui.md)).

## 2. Audio direction

**Design intent.** Âm thanh xác nhận mỗi thao tác trong vài chục mili giây, mềm và "ngọt" theo chủ đề kẹo (không có ambience cảnh vật hay bối cảnh câu chuyện), không gây mệt khi người chơi đánh hàng trăm X trong một phiên. Âm thanh **không bao giờ là kênh thông tin duy nhất**: mọi sự kiện đều có phản hồi hình ảnh tương ứng, nên tắt âm vẫn chơi đầy đủ.

| Nguyên tắc | Diễn giải |
| --- | --- |
| Nhẹ cho thao tác lặp | X là tiếng bút chì cào ngắn, có biến thiên pitch để không đơn điệu khi vuốt |
| Rõ cho kết quả | Kẹo đúng đi lên (sine sweep, voice combo), kẹo sai đi xuống (square, low-pass) |
| Một tiếng UI chung | Mọi nút, toggle, dialog, back, undo, restart dùng chung `UI_TICK` — tiếng gỗ ấm "tíc ky" |
| Thưởng tăng dần | Combo voice 12 cấp, từ "Nice" tới "Legendary" |
| Không trừng phạt | Melody thua đi xuống nhưng mềm, không còi báo lỗi gắt |

## 3. SFX catalogue

Tổng cộng 34 effect: 22 effect chức năng + `COMBO_1..COMBO_12`. Effect procedural được sinh một lần tại `SfxPlayer._ready()` (PCM mono 16-bit, 22.050 Hz, `pcm_synth.gd`); effect file được `load()` từ `game/assets/audio/sfx/`.

| Effect | Sự kiện kích hoạt | Mô tả âm | Nguồn tạo | Thời lượng |
| --- | --- | --- | --- | --- |
| `MARK` | Đặt X (tap hoặc từng ô khi vuốt) | Bút chì cào hai nét, band-pass 1070–1480 Hz, speed 0,88 | Procedural `PENCIL_PRESETS` | 176 ms |
| `UNMARK` | Xóa X | Pop mềm đi lên 654→1376 Hz | Procedural sine | 55 ms |
| `CANDY_YES` | Kẹo do Hint đặt (kẹo người chơi đặt phát combo voice) | Sine sweep 520→1040 Hz, noise nhẹ | Procedural | 140 ms |
| `CANDY_NO` | Đặt kẹo sai | Square sweep 300→150 Hz, low-pass 1800 Hz | Procedural | 180 ms |
| `HINT_SHOW` | Nhấn Hint | `UI_TICK` | Procedural (dùng chung) | 74 ms |
| `HINT_APPLY` | Áp dụng gợi ý | Triangle 523→784 Hz (C5→G5) | Procedural | 120 ms |
| `HINT_DISMISS` | Đóng gợi ý | Sine 440→350 Hz nhẹ | Procedural | 80 ms |
| `HINT_WRONG_MARK` | Hint phát hiện X sai | Square 300→200 Hz | Procedural | 150 ms |
| `STAGE_CLEAR` | Vào màn thắng; hoàn tất tutorial | Melody thắng | File `sfx/win-melody.ogg` | theo file |
| `STAGE_FAIL` | Vào màn thua | Melody thua | File `sfx/lose-melody.ogg` | theo file |
| `BTN_PRESS` | Mọi nút (auto-bind) | `UI_TICK`: triangle 410→275 Hz, noise 20%, low-pass 1350 Hz | Procedural | 74 ms |
| `BOARD_OPEN` | Mở bàn chơi | Triangle sweep 350→700 Hz | Procedural | 250 ms |
| `RESTART`, `TAP_BACK`, `TOGGLE_ON`, `TOGGLE_OFF`, `DIALOG_OPEN`, `DIALOG_CLOSE`, `UNDO_X` | Restart, Back/Home, công tắc Settings, mở/đóng dialog, Undo thành công | `UI_TICK` | Procedural (dùng chung) | 74 ms |
| `SETTINGS_OPEN` | Mở Settings từ Home hoặc bàn chơi | Gậy vụt qua không khí + tiếng "tách" | File `sfx/settings-whoosh.ogg` | theo file |
| `PROGRESS_COMPLETE` | Đạt ⌈N/2⌉ kẹo (một lần mỗi level, không phát nếu đó là kẹo cuối) | Sine 660→990 Hz, nhỏ hơn melody thắng | Procedural | 260 ms |
| `LOCK_TICK` | Không có trigger gameplay (dự phòng, chỉ nghe trong tuner) | Triangle tick ngắn | Procedural | 55 ms |
| `COMBO_1..12` | Mỗi kẹo đúng do người chơi đặt, theo cấp combo | Voice word-art (xem §4) | File `sfx/sfx-combo/*.ogg` | theo file |

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| AUD-01 | `MARK`, `UNMARK`, `CANDY_YES`, `CANDY_NO` có pitch ngẫu nhiên 0,94–1,06× nhân với `speed` của preset; effect khác giữ pitch cố định | `test_sfx_player_procedural.gd` |
| AUD-02 | Rate limit cùng effect: `MARK` 100 ms, `LOCK_TICK` 90 ms; bước vuốt gọi `play(..., force=true)` để mỗi ô vẫn có âm | `test_stroke_feedback.gd`, `test_sfx_gameplay.gd` |
| AUD-03 | Pool 8 voice `AudioStreamPlayer` trên bus `Master`, xoay vòng; effect mới cắt voice cũ nhất | `test_sfx_player_procedural.gd` |
| AUD-04 | Envelope có attack ≥ 5 ms, release ≥ 10 ms; mẫu đầu/cuối bằng 0 để không click | `test_pcm_synth.gd` |
| AUD-05 | Nút tạo động trong màn hình được tự bind `BTN_PRESS` qua `node_added`; công tắc phát `TOGGLE_ON/OFF`; dialog phát `DIALOG_OPEN/CLOSE` | `test_audio_channels.gd`, `test_feedback.gd` |

## 4. Combo voices

Combo đếm số kẹo đúng liên tiếp do người chơi đặt, cap cấp 12 (`combo_tracker.gd`, [RST-026](../docs/DECISIONS.md)). Quy tắc reset: xem [GDD-03](03-game-systems.md). Mỗi cấp phát voice tương ứng đồng thời với word-art popup trên ô.

| Cấp | Voice | File |
| --- | --- | --- |
| 1 | Nice | `1-nice.ogg` |
| 2 | Great | `2-great.ogg` |
| 3 | Sweet | `3-sweet.ogg` |
| 4 | Awesome | `4-awesome.ogg` |
| 5 | Excellent | `5-excellent.ogg` |
| 6 | Amazing | `6-amazing.ogg` |
| 7 | Delicious | `7-delicious.ogg` |
| 8 | Incredible | `8-incredible.ogg` |
| 9 | Fantastic | `9-fantastic.ogg` |
| 10 | Divine | `10-devine.ogg` (tên file viết sai chính tả, giữ để không vỡ đường dẫn) |
| 11 | Unstoppable | `11-unstoppable.ogg` |
| 12 | Legendary | `12-legendary.ogg` |

Bàn N×N có tối đa N kẹo, nên campaign 4×4–6×6 chỉ đạt tới cấp 6; cấp 7–12 xuất hiện ở bàn ≥ 7×7. Kẹo do Hint đặt reset combo và phát `CANDY_YES` thay voice.

## 5. BGM

| Hạng mục | Giá trị |
| --- | --- |
| Track | `game/assets/audio/bgm/bgm-candoku-melody.ogg` (`app_shell.gd`, `BGM_TRACK`) |
| Phạm vi | Một track xuyên suốt Home, bàn chơi, kết quả |
| Loop | OGG đặt `loop = true`; WAV (nếu dùng) được ép `LOOP_FORWARD` toàn file (`bgm_player.gd`) |
| Mood | Nhẹ, melodic, không drum nặng, phù hợp tập trung suy luận |
| Trạng thái | Live |

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| AUD-06 | BGM bắt đầu khi app khởi động nếu `music = true`; tắt `music` dừng ngay, bật lại phát lại track hiện hành | `test_settings_apply.gd`, `test_audio_channels.gd` |
| AUD-07 | Điểm nối loop không có click hoặc khoảng lặng nghe thấy | Nghe trên tai nghe và loa thiết bị |

Backlog: biến thể menu tối giản và track ambient cho phiên dài; chỉ làm khi có tính năng chọn nhạc.

## 6. Mix và loudness

| Hạng mục | Spec |
| --- | --- |
| SFX procedural | Mono, 16-bit, 22.050 Hz; volume preset 0,11–0,30 (tuyến tính trước encode); sample clamp trước encode |
| SFX/voice file | OGG Vorbis, mono hoặc stereo, 44,1 hoặc 48 kHz |
| BGM | OGG Vorbis stereo, 44,1 kHz trở lên, mục tiêu −14 LUFS integrated, true peak ≤ −1 dBTP |
| Đỉnh SFX | ≤ −10 dBFS; không clipping khi 8 voice chồng nhau |
| Cân bằng | Combo voice và melody thắng/thua nổi hơn BGM rõ ràng; `MARK` là âm nhỏ nhất trong nhóm gameplay |
| Bus | Toàn bộ qua `Master`; chưa tách bus SFX/Music (mute bằng cờ trong player) |

## 7. Haptics

Rung qua `vibration.gd` (`Input.vibrate_handheld`), chỉ trên thiết bị có feature `mobile/android/ios/web_android/web_ios`.

| Sự kiện | Cường độ | Thời lượng | Nguồn |
| --- | --- | --- | --- |
| Đặt/xóa X (tap) | SOFT | 15 ms | `puzzle_screen.gd` |
| Mỗi ô trong nét vuốt | SOFT | 15 ms | `puzzle_screen.gd` |
| Áp dụng Hint | SOFT | 15 ms | `puzzle_hint_coordinator.gd` |
| Kẹo đúng | NORMAL | 30 ms | `puzzle_screen.gd` |
| Kẹo sai | FIRM | 60 ms | `puzzle_screen.gd` |

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| AUD-08 | Tắt `haptic` dừng mọi rung và tắt cả hiệu ứng rung bàn khi sai (rung bàn được coi là phản hồi rung) | `test_settings_apply.gd`, `test_heart_feedback.gd` |

## 8. Tương tác với Settings

Hai công tắc tách biệt ([RST-025](../docs/DECISIONS.md)), lưu trong `config.json` ([GDD-08 §6](08-technical-design.md#6-data-schemas)).

| Key | Mặc định | Tác động |
| --- | --- | --- |
| `audio` | `true` | Mute `SfxPlayer`: mọi SFX gameplay, UI tick, combo voice, melody thắng/thua; dừng ngay voice đang phát |
| `music` | `true` | Mute `BgmPlayer`: dừng BGM; bật lại phát lại track |
| `haptic` | `true` | Bật/tắt rung và rung bàn |

Khi tắt `audio`, tiếng `TOGGLE_OFF` của chính công tắc đó có thể không phát vì mute áp dụng trước. Đây là hành vi chấp nhận được.

## 9. Quy trình chỉnh âm (SFX tuner)

Công cụ `game/scenes/sfx_tuner.tscn` (`game/scripts/feedback/sfx_tuner.gd`), chạy trong editor bằng F6.

1. Chọn effect trong danh sách (procedural, pencil hoặc file).
2. Chỉnh slider: tần số đầu/cuối, duration, volume, wave, ADSR, noise, low/high-pass, duty, `speed (pitch)` 0,5–2,0×. Effect file chỉ chỉnh `speed`.
3. Nhấn **Play** hoặc phím Space để nghe.
4. Nhấn **Copy Params**: dictionary tham số được ghi vào clipboard và console. Tuner **không** tự lưu vào game.
5. Dán vào `sfx_catalog.gd`: tiếng UI chung vào `UI_TICK`; `MARK` vào `PENCIL_PRESETS`; effect khác vào `PRESETS`.
6. Chạy `test_sfx_tuner.gd`, `test_sfx_player_procedural.gd`, rồi nghe lại trên thiết bị mục tiêu.

## 10. Backlog asset audio

| ID | Hạng mục | Trạng thái |
| --- | --- | --- |
| AUD-A01 | BGM chính `bgm-candoku-melody.ogg` | Done |
| AUD-A02 | Melody thắng/thua `win-melody.ogg`, `lose-melody.ogg` | Done |
| AUD-A03 | `settings-whoosh.ogg` | Done |
| AUD-A04 | 12 combo voice | Done |
| AUD-A05 | Đo loudness BGM/voice và cân mix trên thiết bị thật | Needed |
| AUD-A06 | SFX cho assist inventory (dùng place-candy, hết lượt) | Planned |
| AUD-A07 | Biến thể BGM menu / ambient | Backlog |
| AUD-A08 | Tách bus `SFX`/`Music` trong `default_bus_layout` để chỉnh âm lượng theo nhóm | Backlog |

### Checklist bàn giao audio file

- [ ] Tên file `kebab-case` hoặc theo mẫu thư mục hiện có, đặt dưới `game/assets/audio/{bgm,sfx}/`.
- [ ] Bản thu/tổng hợp gốc; không giọng, nhạc hay âm thanh thương mại.
- [ ] Đạt spec §6: không clipping, đỉnh SFX ≤ −10 dBFS, BGM đo LUFS.
- [ ] BGM loop liền mạch (tail khớp head).
- [ ] Godot tạo lại `.ogg.import`; preset trong `sfx_catalog.gd` trỏ đúng đường dẫn.
- [ ] Event phát đúng, độ trễ cảm nhận < 50 ms trên thiết bị.
- [ ] Ghi nguồn/giấy phép vào `docs/CREDITS.md`.

## 11. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| AUD-Q1 | Chưa có số đo loudness thực cho BGM và combo voice | Mix có thể lệch giữa thiết bị | Đo trong Track E (QA thiết bị) |
| AUD-Q2 | Không có slider âm lượng, chỉ bật/tắt | Người chơi không giảm BGM riêng được | Cân nhắc cùng AUD-A08 sau v1 |

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất GDD 06 (phần âm thanh), ASSET_BACKLOG_AUDIO và sound design guide, cập nhật theo code hiện hành |
