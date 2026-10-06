# Trạng thái dự án

> Cập nhật: 2026-10-06

## Hiệu ứng vào level mới (working tree hiện tại 2026-10-06)

- Mỗi ô của bàn chơi xuất hiện theo sóng bán kính từ góc dưới trái lên góc trên phải, gồm cả ô kẹo cho sẵn; thời lượng cố định cho mọi kích thước. Lượt mới sau khi thắng level trước có hiệu ứng. Home/Settings/khởi động lại để tiếp tục lượt chưa hoàn thành, và Restart/Retry cùng level, bỏ qua hiệu ứng. Tùy chọn giảm chuyển động hiện bàn ngay.
- TDD RED→GREEN: `game/tests/test_board_entry.gd` kiểm luồng mở mới/tiếp tục, input, giảm chuyển động và bàn 4×4, 5×5, 6×6, 9×9. Ảnh render: `scratch/verification/entry-wave-preview.png`. Review độc lập không thấy lỗi chặn.
- Đã áp dụng vào checkout chính nhánh `feat/candy-sprites`, revision nền `9bbdcc122c9e8c9ae818ffb0cca62f42661c7e67` + working tree đang có. Full gate **PASS**: 3 nhóm Python, content checks, 42 suite Godot; `rtk python -B tools/verify.py --godot <Godot 4.7.2 console executable>`. Evidence: `scratch/verification/20261006T151033.729217Z.txt`. Clean-room/import reference: 0 match. Cấu hình profile thực `reduced_motion=false`. Chưa QA gesture và thiết bị, chưa commit/merge/push.

## Sửa phản hồi X lặp khi commit batch (working tree 2026-10-06)

- Nguyên nhân: TouchDecoder xóa preview và lịch sử ô đã phản hồi trước khi phát swipe commit, khiến commit phát thêm SFX và chạy lại animation X. Giữ lịch sử preview đến hết commit; chỉ animate các ô chưa có phản hồi preview. Nét kéo bỏ qua phản hồi trên ô không đổi trạng thái, giữ preview tức thì và một transaction/Undo cho cả nhóm.
- TDD RED→GREEN tại `game/tests/test_stroke_feedback.gd`: nét đánh/xóa, đi ngược, nhấc sau khi animation đã xong, nhấc khi animation đang chạy, ô X/error có sẵn, hủy nét, batch trực tiếp và reduced motion. Log `scratch/verification/stroke-feedback-red.log` và `stroke-feedback-green.log`. Suite input, screens và SFX gameplay PASS; clean-room/import reference 0 match; các file thuộc task ≤300 dòng.
- **Full gate PASS** trên revision nền `9bbdcc122c9e8c9ae818ffb0cca62f42661c7e67` + working tree nhánh `feat/candy-sprites`: `rtk python -B tools/verify.py --godot <Godot 4.7.2 console executable>`. Evidence `scratch/verification/20261006T105646.785425Z.txt` có revision, lệnh, SHA256 và xác nhận source ổn định trong lượt chạy. Giữ nguyên các thay đổi sẵn có, chưa commit/merge/push; chưa QA nghe/render hoặc gesture trên thiết bị.

## Hiệu ứng tim vỡ và rơi khi đặt sai kẹo (working tree 2026-10-06)

- Dùng nguyên sprite `game/assets/ui/board/heart_sprite.png` do chủ dự án cung cấp: 8 frame nứt → vỡ → rơi, tổng 720 ms. Giữ 3 ô HUD ổn định, thay tim vừa mất bằng nền tim rỗng; refresh khi tìm đúng kẹo không ngắt animation. Reduced motion cập nhật tĩnh.
- Chủ dự án báo không thấy hiệu ứng: xác nhận profile thực tế có `reduced_motion=true`. Đã tắt riêng tùy chọn này qua ConfigStore, giữ các tùy chọn còn lại; backup tại `scratch/verification/heart-motion-config-before.json`. Kiểm tra composition root đọc cấu hình thật, dùng campaign profile riêng và chạm đôi qua TouchDecoder: tim giảm 3→2, animation bắt đầu/kết thúc PASS (`scratch/verification/heart-motion-config-check.log`). Phiên game đã mở trước khi đổi config cần chạy lại để đọc tùy chọn mới; không thay đổi save/progress thật.
- Lần sai cuối chuyển session sang FAILED và lưu ngay, đợi hiệu ứng kết thúc mới mở Result. Restart/rời màn hủy chuyển màn cũ; resume lượt FAILED mở lại Result mà không phát lại animation. Test debug picker dùng profile riêng để không phụ thuộc hoặc ghi vào save thật của người chơi.
- TDD RED→GREEN cho mất tim, refresh giữa animation, tim cuối, restart/rời màn, reduced motion và resume FAILED. Test liên quan và clean-room/import reference PASS; mọi module trong task ≤300 dòng. Render OpenGL thực tế 540×960 đã kiểm tra 8 frame; GIF và contact sheet tại `scratch/verification/heart-feedback-preview/`. Chưa QA Android/iOS.
- **Full gate PASS trên snapshot cố định** của revision nền `9bbdcc122c9e8c9ae818ffb0cca62f42661c7e67` + working tree; các source thuộc task khớp SHA256 với checkout sau gate. Lệnh `rtk python -B scratch/verification/verify_heart_snapshot.py <Godot 4.7.2 console executable>` chạy `tools/verify.py` trong bản sao, dùng Git index riêng. Evidence `scratch/verification/heart-feedback-frozen-gate.txt`; provenance tại `scratch/verification/heart-feedback-snapshot-20261006T101116Z/snapshot-provenance.json`. Lượt gate live `20261006T100901.166042Z.txt` có tất cả checks PASS nhưng kết quả chung FAIL vì source khác thay đổi trong khi chạy. Chưa commit/merge/push.

## Bộ button Settings cắt từ ảnh chủ dự án (working tree 2026-10-06)

- Đã tách 9 PNG RGBA 192×192 từ ảnh chủ dự án cung cấp vào `game/assets/ui/settings/`: audio on/off, music on/off, haptic, reduced motion, large text, colorblind, Undo X. Nền ngoài nút trong suốt; các pixel opaque giữ màu đúng ảnh nguồn. Options screen hiện dùng bộ ảnh này.
- Kiểm tra trực quan trên nền caro và kiểm alpha/pixel nguồn PASS; evidence `scratch/verification/settings-buttons-preview.png` và `scratch/verification/settings-buttons-validation.json`. ZIP bàn giao tại `scratch/exports/candoku-settings-buttons.zip`.

## Tinh chỉnh SFX nút và Settings (working tree 2026-10-06)

- Các hành động bấm nút, Back/Home, Restart, toggle, mở/đóng dialog, dùng Hint và Undo X thành công dùng chung preset và một PCM stream `UI_TICK` 74 ms: triangle trầm, noise ngắn và lọc bớt âm cao để có cảm giác gỗ ấm. Nút mở Settings ở Home và puzzle có cue `SETTINGS_OPEN` riêng: tiếng gậy vụt nhanh 110 ms, phần gió sáng dần và cú “tách” khô ngắn. Tuner cho chỉnh phần gió (`noise_mix`), cú vụt (`snap_mix`), lọc và speed. Tổng cộng 19 effect.
- Test `test_pcm_synth.gd`, `test_feedback.gd`, `test_sfx_tuner.gd`, `test_sfx_player_procedural.gd` PASS; `test_sfx_gameplay.gd` báo PASS cho kiểm cue nhưng Godot còn in lỗi asset candy thiếu. Full gate **FAIL** trên revision `9bbdcc1` cộng working tree: `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>`, evidence `scratch/verification/20261006T083927.696969Z.txt`. Các suite SFX qua gate; các failure khác cùng xuất phát từ sáu SVG candy thiếu trong task sprite song song. Cần task sprite hoàn thiện asset/path rồi chạy lại gate. QA nghe thực tế vẫn chờ chủ dự án.

## SFX procedural mở rộng và tuner (working tree 2026-10-06)

- Chủ dự án chọn giữ SFX tổng hợp bằng code. Catalog hiện có 18 effect; tuner cho chọn, preview và copy tham số của cả 18, gồm `MARK` pencil scratch đúng với runtime. `Copy Params` chưa tự lưu vào catalog.
- Back/Home, toggle, hộp xác nhận, Help, Undo X thành công và mốc nửa số kẹo cần tự tìm đã có cue riêng. `LOCK_TICK` chỉ có để nghe trong tuner vì gameplay hiện không auto-lock. Không gen hoặc tích hợp file SFX bên ngoài.
- TDD: test tuner phát hiện preview `MARK` khác runtime; test PlaySession xác nhận Undo có/không đổi board; test feedback và gameplay kiểm cue mở rộng. Full gate `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>` **PASS** trên revision nền `9bbdcc1` cộng working tree, evidence `scratch/verification/20261006T065506.128594Z.txt`. QA nghe thực tế trên loa/tai nghe và thiết bị mục tiêu vẫn chưa làm.
- Tuner có thanh `speed (pitch)` cho từng cue (0,5–2,0×); `Copy Params` xuất `speed` để player áp dụng trong game. Do dùng `AudioStreamPlayer.pitch_scale`, tốc độ và cao độ thay đổi cùng nhau. `STAGE_FAIL` đang đặt 0,9× làm giá trị khởi điểm. `test_sfx_tuner.gd` và `test_sfx_player_procedural.gd` PASS.
- **Blocker full gate cho lần chỉnh Speed:** `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>` FAIL; evidence `scratch/verification/20261006T071449.287649Z.txt`. Tác động: chưa thể bàn giao dưới nhãn full gate PASS. Nguyên nhân trong working tree của task candy sprite: `candy_renderer.gd` gọi `bonbon.svg`, `lollipop.svg` và bốn SVG khác, nhưng `game/assets/candy/` hiện chỉ có `candy.png`. Người xử lý: task candy sprite. Hành động tiếp: hoàn thiện asset/path renderer theo task đó; chạy lại full gate khi sáu path được giải quyết.

## Procedural SFX và normal play session (đã tích hợp vào `dev`)

- `pcm_synth.gd` sinh PCM mono 16-bit/22050 Hz: bốn waveform, pitch sweep, ADSR fit theo thời lượng, noise và low-pass. Engine bảo toàn attack ≥5 ms/release ≥10 ms, ưu tiên ramp khi envelope quá dài; âm ngắn hơn 15 ms co hai ramp theo tỷ lệ. Mẫu đầu/cuối luôn về 0. Enum pitch là `PitchCurve` vì `Curve` trùng class Godot.
- 9 effect có stream prewarm, gồm 7 âm đơn và 2 melody; pool 8 voice, pitch variation cho bốn effect, MARK giữ giới hạn 100 ms. Mute dừng mọi voice. Nút trong composition root phát BTN_PRESS qua signal native.
- [SFX Tuner](../game/scenes/sfx_tuner.tscn): chạy F6, chọn preset, chỉnh slider/dropdown, Play hoặc Space, Copy Params ra clipboard/console. Melody giữ chuỗi nốt và `note_dur`; output được kiểm tra biên dịch như dictionary GDScript.
- TDD: engine, player, tuner và dispatch gameplay có test tự động; test feedback cũ đã chuyển từ đường dẫn `.ogg`/mock sang playback thật. Tuner đã kiểm tra render Vulkan và clipboard Windows; ảnh tại `scratch/verification/sfx-tuner-mark.png` và `sfx-tuner-melody.png` trong worktree audio.
- Review độc lập đã hoàn thành; sửa lỗi biên envelope gây click/pop bằng test RED→GREEN cho attack/release bằng 0, envelope quá dài, duration 20 ms và melody ngắn. Test cũng kiểm tra saturation đúng dấu/biên độ và exponential sweep với endpoint 0 khớp PCM linear.
- Full gate sau sửa review PASS: 76 Python tests, 32 Godot suites và content checks. Lệnh: `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>`; evidence `scratch/verification/20261005T085734.476968Z.txt`, revision `7a7ac75881e2c703c97fba9d7dcfb0785d93363f`, không có thay đổi tracked; source SHA256 `209e9f7f741ae9f899ee8c216a3961c47ed23f5457480accb25e98e280a271aa`. Clean-room/import reference: 0 match; các module audio ≤300 dòng.
- Tích hợp local: merge `fix/normal-play-session` (`fd2e393`) vào `feat/procedural-sfx` thành `4bbb145`, rồi merge kết quả vào `dev`. Cả hai lượt tự động, không có conflict nguồn; giữ nguyên lịch sử/tác giả của `c8202b5` và `fd2e393`. Chưa push.
- Normal play session: khôi phục session thường, tách save debug, cho phép progress lệch quay lại màn non-final đã hoàn thành rồi advance; boot tự chọn màn chưa hoàn thành khi progress đang trỏ vào màn đã xong; session WON được khôi phục tiếp tục flow hoàn thành. Test progress xác nhận re-advance cập nhật điểm và chuyển màn.
- Gate bản tích hợp trên checkout `dev` trước merge commit PASS: 76 Python tests, 32 Godot suites và content checks; evidence `scratch/verification/20261005T092313.722730Z.txt`, nền `cfbf1bc` + index merge từ `4bbb145`, source SHA256 `ce70798294e077880f6bed4ae5b98dce68e1a36d00f849cd1b01740857aa7259`. Clean-room/import reference: 0 match; các module đã sửa ≤300 dòng.
- Checkout chính: `D:/Work/Alpaca_Solution/ASOL-Game-02`, nhánh `dev`. Worktree audio giữ nguyên. UID tuner sinh cục bộ khác bản tracked được bảo toàn tại `scratch/verification/test_sfx_tuner.pre-merge-fd2e393.gd.uid`; không ghi đè plan hay UID responsive-layout untracked.
- BGM WAV thử nghiệm hiện nằm tại `game/assets/audio/bgm/bgm-candoku-melody.wav`; bản OGG theo chuẩn release vẫn thiếu. QA nghe âm sắc/độ lớn/click-pop trên loa, tai nghe và thiết bị mục tiêu chưa thực hiện; chưa phải nghiệm thu phát hành.

## Bank đầy đủ và campaign 998 level (trên `feat/full-bank-campaign`, chưa merge)

- Đã tạo 36/49/913 level gốc cho 4×4/5×5/6×6, năm rank mỗi kích thước; validator độc lập xác nhận nghiệm duy nhất, trace S2/S3, pace và phủ playlist 998 tham chiếu.
- `full_998.json` giữ L01–L30 của `demo_30.json`; `active_campaign.json` mặc định `full_998`, có thể đổi thành `demo_30` trước khi chạy/export. Hai mode có progress/session riêng; Settings dùng chung.
- Đã giữ vị trí và dữ liệu puzzle của 90 level gốc. Sửa trace/pace của 30 level 5×5 cũ theo quyết định chủ dự án. Ba cặp puzzle 5×5 cũ trùng hệt nhau còn trong cả hai campaign; đây là ngoại lệ cũ được ghi rõ, không mở cho level mới.
- Bộ sinh offline xác định và có checkpoint. Lần tạo 6×6 dùng seed `candoku-full-bank-6-v1`, hoàn thành sau 47.715 lần thử; trung vị rating của rank 1–5 là 9/12/18/28/36. Log baseline và đối chiếu ở `scratch/verification/full_bank_baseline.json`.
- Ngưỡng rating tối đa để xếp vào rank 1–4 khi sinh thêm: 4×4 `10/14/19/26`, 5×5 `10/14/28/34`, 6×6 `10/14/24/31`; điểm cao hơn cần S3 và vào rank 5. Trung vị rank 1–5 sau sinh: 4×4 `8/11/18,5/25/28`, 5×5 `17/25/28,5/32/37`, 6×6 `9/12/18/28/36`. Các ngưỡng này là chỉ báo máy, còn cần playtest mù.
- Review độc lập phát hiện và đã sửa hai lỗi: ghi pace lỗi sau khi ghi bank sẽ khôi phục cặp file gốc; lượt thắng dùng Hint truyền `hints_used` vào DDA nên không tăng streak sạch. Test lỗi boot hiện hộp thoại cũng đã thêm.
- **Full gate PASS** sau review tại revision `9b53cb079a69f5d9a48af99ad3db9d32baa444e2`: `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>` — 76 Python tests, 21 Godot suites và mọi content check. Bằng chứng: `scratch/verification/20261004T200321.405769Z.txt`, source SHA-256 `50778ddba88146e175cb74d3569be8f278f47846bec3949fec8702ca145a20fa`. Clean-room và import `extracted_reusable`: 0 match; module đã sửa ≤300 dòng. QA giao diện/gesture/thiết bị chưa chạy, chưa phải nghiệm thu phát hành.

**Cách đổi mode:** xem [Hướng dẫn campaign](../README.md).

## Mục tiêu hiện tại: QA và chuẩn bị release

### Demo 30 màn N=4–6 (đã triển khai trên `feat/demo-cross-size`, chưa merge)

- Theo RST-018, playlist mặc định `demo_30.json` gồm L01–L10: 4×4, L11–L20: 5×5, L21–L30: 6×6. Mỗi kích thước dùng 5/3/2 màn Rank 1/2/3; L01/L02 giữ tutorial.
- Snapshot của lượt đang chơi giữ puzzle và pace cũ khi cập nhật playlist; màn tiếp theo dùng nội dung mới. Bank/pace hiện có và playlist kiểm thử 45 màn `demo_cross.json` giữ nguyên.
- TDD: kiểm thử xuyên 30 màn thất bại đúng ở kích thước L11–L30 trước khi đổi playlist; kiểm thử save cũ thất bại ở pace trước khi sửa `current_pace()`. Sau sửa, `DEMO_CAMPAIGN_PASS` và `CAMPAIGN_RUNTIME_PASS`.
- Full gate phát hiện test cài đặt cũ còn chờ hai hàng wide dù toggle Undo X đã thêm hàng thứ ba; cập nhật kỳ vọng và kiểm tra toggle Undo X thực sự đổi cấu hình.
- **Kiểm chứng:** `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>` — **PASS**, 60 Python tests và 19 Godot suites. Nền revision `6644d31a2f10fc21111263236dbc618795af87c1` + working tree trên nhánh trên; SHA256 đầu vào và lệnh đầy đủ tại `scratch/verification/20261004T141351.055626Z.txt`. Clean-room và import `extracted_reusable`: 0 match. QA giao diện/gesture/thiết bị chưa chạy.

### Gameplay & UI Realignment (hoàn tất — đã trong `dev`)

Các commit `8181021`–`9edafd4` đã đưa CellKind về 5 trạng thái, bỏ auto-lock, giữ ERROR vĩnh viễn, nối swipe để đánh/xóa X và dựng lại các màn hình. Những thay đổi này đã nằm trong `dev` từ khi system upgrade bắt đầu — nhánh `feat/gameplay-ui-realign` không có commit nào ngoài `dev` (đã xóa 2026-10-04).

**Quyết định RST-017:** Giữ Undo X với toggle cài đặt (`undo_x`) — implemented tại `be587b9`. Toggle wired qua `config_store` → `options_screen` → `app_shell` → `puzzle_screen`.

| Task | Nội dung | Status |
|------|----------|--------|
| T1–T2 | CellKind 5 trạng thái, bỏ auto-lock | Trong `dev` — `8181021` |
| T3, T6 | PlaySession và handler | Trong `dev` — Undo X có toggle per RST-017 |
| T4–T5 | Swipe và board rendering | Trong `dev` — cần QA gesture thiết bị |
| T7–T8 | Layout puzzle và palette | Trong `dev` — cần QA màn hình thiết bị |
| T9–T10 | Test và rà tham chiếu cũ | Full gate PASS `20261003T102902` trên `dev` |
| T11–T12 | Title và result screens | Trong `dev` — cần QA màn hình thiết bị |
| T13 | Final verification — thiết bị | Chưa làm (block Track E) |

### Last-Mile Task 5–6: Content + Accessibility (hoàn tất — merged `d20c2f0`)

- **Task 5:** Bank 6×6 (30 levels: 12/10/8 per rank), pace sidecar, campaign `demo_cross.json` (45 levels: 15×4×4 + 15×5×5 + 15×6×6), DDA cross-size wired trong `campaign_runtime.gd`. Commit `47b152d`.
- **Task 6:** Wire 3 settings còn thiếu: `reduced_motion` → `LayoutTokens.set_motion()`; `high_contrast` → `puzzle_board._high_contrast`; `large_text` → `LayoutTokens.tile_font_size()`. Toàn bộ 7 EDITABLE_KEYS đều có effect. Commit `8414752`. Merge `fix/doubletap-x-preview` → `dev`: commit `d20c2f0` (8 commits, 4449 insertions).

### Sửa nháy X khi chạm đôi (hoàn tất — merged `d20c2f0`)

Bỏ preview X khi chạm xuống; preview chỉ bắt đầu khi kéo và vẫn gồm ô đầu. Chạm đơn commit đúng mốc 350 ms. GDD 02 đồng bộ theo RST-016. Full gate PASS: `scratch/verification/20261003T125135.722105Z.txt`.

**Plan tham chiếu:** [Completion Plan](superpowers/plans/2026-10-03-completion-plan.md) — Track D/E/F còn lại.

## Giai đoạn trước: Rebuild (hoàn tất)

Rebuild 10 modules hoàn tất, tất cả đã merge vào `dev` (PR #1–#10). Đã sinh bank và playlist **30 level 4×4**; chưa có bank 5×5/6×6 và chưa có nghiệm thu playtest mù hoặc thiết bị.

```
Wave 1: M01 + M05           (đã merge)
Wave 2: M02 + M03 + M04     (đã merge)
Wave 3: M06 + M07           (đã merge)
Wave 4: M08                 (đã merge)
Wave 5: M09                 (đã merge)
Wave 6: M10                 (đã merge)
```

## System Upgrade (hoàn tất — merged vào `dev` 2026-10-03)

7 modules nâng cấp từ nhánh `feat/solver-advanced` và 4 follow-up branches đã merge vào `dev`:

| Module | Nội dung | Status |
|--------|----------|--------|
| ShapeFingerprint | Canonical region hash cho snapshot dedup | Merged |
| ProgressManager | recentShapes tracking (tránh lặp) | Merged |
| SessionStore | Snapshot lưu/phục hồi giữa session | Merged |
| CampaignRuntime | Snapshot round-trip + pace_adjuster DDA | Merged |
| BoardSolver S4-S7 | SUBSET_PAIR, SUBSET_TRIPLE, SUBSET_QUAD, CONTRA_CHAIN | Merged |
| RegionPainter | assign_with_overlays(), overlay_tint(), colorblind support | Merged |
| PaceAdjuster (DDA) | Dynamic difficulty, win/loss streaks | Merged |
| BankCodec/BankReader | XOR encode/decode bank files | Merged |
| snapshot_builder.gd | Extracted từ campaign_runtime (F1) | Merged |
| Colorblind rendering | puzzle_board.gd + puzzle_screen.gd wired (F2) | Merged |
| Solver S4+ test | 5×5 pentomino xác nhận SUBSET_PAIR (F3) | Merged |
| Bank generation tooling | argparse + --size cho generate_levels/build_playtest/generate_pace (F4) | Merged |

**Gate trước merge:** 12/12 Godot test suites PASS, clean-room 0 match, tất cả modules ≤ 300 dòng.

**Việc còn mở (deferred):**
- Colorblind overlay: ThemeDB.fallback_font có thể thiếu glyph unicode trên một số thiết bị (cần manual QA)
- Snapshot thiếu fields `rating`/`solve_profile` từ spec (chưa có consumer)
- Bank 5×5 đã có nhưng chưa được đưa vào playlist; bank 6×6 chưa có

### Last-Mile Task 1: DDA rank_offset wired into campaign (đã merge vào `dev` 2026-10-03)

CampaignRuntime đã áp dụng DDA khi chọn rank từ bank và pace, fallback về rank playlist nếu rank/index điều chỉnh thiếu dữ liệu. Puzzle đang chơi được ghim bằng snapshot để restart và resume không đổi level khi streak đổi.

Commit triển khai: `192943b`; merge vào `dev`: `60dda20`. `test_campaign_runtime.gd` xác nhận tăng/hạ rank, fallback và giữ puzzle qua restart/resume.

### Last-Mile Task 2: Colorblind toggle in options screen (đã merge vào `dev` 2026-10-03)

- Thêm toggle "Hỗ trợ phân biệt màu" (`colorblind`) vào `options_screen.gd` thông qua `WIDE_KEYS`.
- `app_shell.gd`: xử lý thiết lập `colorblind` trong `_apply_setting()`, tự động đồng bộ và vẽ lại bàn cờ qua `_refresh_puzzle_colorblind()`.
- Flow options -> puzzle tạo lại màn hình mới và áp dụng `set_colorblind()` trước `configure()`.
- Test suite: `test_screens.gd` (PASS), `test_colorblind.gd` (PASS), `test_config_store.gd` (PASS), `test_integration.gd` (PASS).

### Last-Mile Task 3: Bank 5×5 generated (đã merge vào `dev` 2026-10-03)

- `bank_5x5.json`: 30 levels (12 rank 1, 10 rank 2, 8 rank 3), validated by `validate_content.py`.
- `bank_5x5.pace.json`: pace sidecar generated.
- Campaign `demo_30.json` unchanged — pending product decision on 5×5 placement.

### Last-Mile Task 4: XOR encode pipeline verified (đã merge vào `dev` 2026-10-03)

- `bank_codec.gd` round-trip: BANK_CODEC_PASS (4 tests).
- `tools/encode_banks.py --input/--output`: produces non-JSON encoded output, round-trip matches original.
- `bank_reader.gd`: editor branch reads plaintext, release branch decodes XOR via `BankCodec.xor_transform()`.
- Key consistency: `"candoku-2026-bank-key"` in cả Python và GDScript.
- Pipeline sẵn sàng: chạy `python -B tools/encode_banks.py --input game/data/banks --output <export_dir>` trước khi export release. Không encode files trong repo — editor tests cần plaintext.

## Baseline

- `dev` (HEAD 2026-10-04): rebuild 10 modules + system upgrade 7 modules + last-mile tasks 1–6 + gameplay/UI realignment + accessibility settings
- Reference: `extracted_reusable/` (~224 files)
- Tag bảo toàn: `pre-reset-pipeline-2026-09-27`
- Nhánh đã dọn (2026-10-04): `feat/gameplay-ui-realign`, `fix/doubletap-x-preview`, `fix/region-painter-unique-colors`, `feat/screens-colorblind-toggle`, `feat/campaign-dda-rank-selection`, và các nhánh rebuild `feat/m01`–`feat/m10`, `chore/rebuild-preparation`

## Việc cần chốt và kiểm chứng

- **Full gate Python:** trên `dev` tại `c577210`, ngày 2026-10-03: **PASS**. Log: `scratch/verification/20261003T102902.224427Z.txt`. Working tree còn uncommitted data + `.uid` — chưa thay thế kiểm chứng trên checkout sạch khi phát hành.
- **Full gate Godot** cho last-mile 5–6 (bank 6×6, accessibility): chưa chạy — cần Godot executable.
- **QA UI/thiết bị (Track E):** chưa làm. Cần kiểm gesture (single tap, double tap, swipe), layout màn hình, colorblind mode trên Android. iOS cần môi trường build/signing riêng. Chỉ đánh dấu đạt khi có bằng chứng theo revision.
- **Track D — Assets:** 9 SFX procedural nền đã tích hợp vào `dev`; working tree hiện có 19 effect, BGM WAV thử nghiệm, font, logo và candy sprites. Còn QA nghe, duyệt hình ảnh và chuẩn bị BGM OGG cho release.
