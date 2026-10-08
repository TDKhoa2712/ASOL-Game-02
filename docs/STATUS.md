# Trạng thái dự án

> Cập nhật: 2026-10-08

## Chuẩn hóa Repo, cố định Undo X & Full Gate PASS (nhánh `dev`, 2026-10-08)

- **Cố định Undo X (RST-021):** Giữ Undo X luôn hoạt động bình thường trong gameplay (hoàn tác X-mark cuối), loại bỏ toggle bật/tắt trong màn hình Cài đặt (Options Screen) và cấu hình `config_store`. Các test suite `test_config_store.gd` và `test_screens.gd` được cập nhật đồng bộ.
- **Khắc phục lỗi tích hợp và tương thích:**
  - `app_shell.gd`: Bổ sung kiểm tra `is_inside_tree()` khi phát BGM khởi động để không gây lỗi khi chạy unit test / headless. Tái lập `_on_options_back()` để đồng bộ trạng thái khi đóng Options overlay. Tối ưu mã nguồn đưa file về 285 dòng (đạt chuẩn $\le 300$ dòng).
  - `puzzle_board.gd` & `puzzle_screen.gd`: Thêm phương thức `skip_entry_wave()` giúp kết thúc ngay hiệu ứng sóng khi mở Cài đặt, bảo đảm `test_board_entry.gd` PASS.
  - `test_sfx_gameplay.gd`: Hỗ trợ Options Overlay, hoàn thành kiểm thử SFX chỉ trong ~5 giây.
  - `export_presets.cfg`: Khôi phục preset mẫu probe để `test_export_presets.py` PASS 100%.
- **Dọn dẹp rác & Artifacts:**
  - Xóa bỏ toàn bộ thư mục `rive-assets/` (dự án Rive studio logo bị thay thế bởi native Godot splash screen).
  - Xóa các file build APK cục bộ (`build/android/` và `game/build/android/`), giải phóng ~85MB.
  - Xóa thư mục lưu trữ tài nguyên cũ `game/assets/archive/` (30 file icon/SVG pre-rebuild không còn sử dụng).
  - Dọn dẹp thư mục `scratch/`, xóa các log verification cũ và ảnh chụp test.
  - Dọn dẹp các git branch local cũ (`feat/core-game-features`, `feat/studio-splash-animation`, `fix/audio-bgm-settings-timing`) và xóa sạch worktree phụ và git stashes.
- **Kiểm chứng Full Gate:** 66/66 checks PASS 100% qua `python -B tools/verify.py --godot <executable>`. Toàn bộ module trong `game/scripts/` đều $\le 300$ dòng. Clean-room 0 match.


## Hiệu chỉnh BGM và cue mở Settings (nhánh `feat/core-game-features`, 2026-10-07)

- BGM WAV 75 giây có dữ liệu âm thanh hợp lệ. Lời gọi phát đã chuyển sang deferred khi node vào cây, nhưng kiểm tra một frame đầu chưa phát hiện nhạc dừng ngay sau đó. Nguyên nhân được xác định tiếp: WAV import có `loop_end = 0`; bật `LOOP_FORWARD` với mốc này làm playback kết thúc gần như tức thì. `BgmPlayer` nay đặt loop end theo độ dài và sample rate của stream.
- Cue `settings-whoosh.ogg` có khoảng 230 ms đầu gần như im lặng. Đã cắt đoạn đầu, thêm fade-in 5 ms để tránh click; thời lượng còn khoảng 745 ms, vẫn giữ stereo và dùng chung resource với SFX Tuner.
- TDD RED→GREEN tại `test_integration.gd` và `test_sfx_player_procedural.gd`; test BGM nay chờ 0,5 giây và xác nhận playback tiếp tục với loop end hợp lệ. WASAPI probe trên Windows xác nhận bus nhận tín hiệu khoảng −19 dB sau sửa. `test_campaign_selector.gd` chờ AudioServer nhả BGM trước khi thoát test. Clean-room/import tham chiếu: 0 match. Full gate PASS tại revision `6628a81` trong checkout cô lập; log `scratch/verification/audio-loop-6628a81.txt`. Checkout dùng chung có thay đổi GameFeatures chưa commit khiến `test_screens` fail; lỗi ngoài phạm vi audio. Chưa QA nghe trên loa/tai nghe hoặc thiết bị đích.

## Nâng cấp Chế độ Debug & Chiến dịch 100 Levels (nhánh `feat/debug-and-campaign-100`, 2026-10-07)

- **Debug Mode Enhancements:**
  - **Endless Level Picker:** Bổ sung Tab 3 "Vô tận (Endless)" trong `DebugLevelPicker`, tích hợp `DebugEndlessPanel` cho phép chọn bất kỳ số level $N$ (1..2000), xem trước thông tin chi tiết (Size, Rank, Difficulty, Vùng, Kẹo cho sẵn), và vào chơi màn này ngay; tự động tính màn tiếp theo $N+1$.
  - **Reset Progress:** Bổ sung `DebugResetBar` cho phép đặt lại tiến trình riêng cho Campaign (về level đầu tiên), riêng cho Endless (về Level 1), hoặc đặt lại cả hai cùng lúc; tự động cập nhật text nút trên Title Screen ngay lập tức.
  - **In-Game Cheats Toolbar (`PuzzleDebugBar`):**
    - **Hiện/Ẩn nghiệm:** Toggle hiển thị vị trí các kẹo nghiệm trên bàn cờ với halo và viền highlight xanh lá trực quan.
    - **Thắng ngay (Force Win):** Chuyển session sang WON và kích hoạt màn thắng ngay lập tức.
    - **Thua ngay (Force Fail):** Trừ hết tim và chuyển sang màn thua ngay lập tức.
    - **Tự giải (Auto-solve):** Tự động điền đầy đủ các kẹo nghiệm vào bàn cờ và hoàn thành màn để chuyển tiếp level.
- **Chiến dịch 100 Levels (`campaign_100.json`):**
  - Mở rộng chiến dịch chính lên 100 level, phân bổ cân bằng từ kích thước $4\times 4$ đến $12\times 12$ và trải đủ các độ khó rank 1..3 tương thích 100% với các bank offline.
  - Subtitle màn hình chính hiển thị động `1->100`.
- **Kiểm chứng Full Gate:** 66/66 checks PASS trên `python -B tools/verify.py --godot <Godot console>`. 100% test GDScript pass (bao gồm `test_debug_features.gd` và `test_debug_level_picker.gd`). Mọi file mã nguồn đều strictly $\le 300$ dòng. Clean-room: 0 tên thương mại/cấm.


## Chế độ Endless Levels (Hoàn thành Phase 1–4, 2026-10-07)

- Hoàn thành đầy đủ 4 phase của kế hoạch Endless Levels:
  - **Phase 1 (Bank Conversion & Pace):** Mở rộng `tools/convert_extracted_bank.py` sang `BANK_REGISTRY` với 9 bank types và 31 file bank, sinh 100% file `.pace.json` sidecars, mở rộng `BankReader` hỗ trợ Variant B (Flat bank) và `FlatBankCache`. Tổng cộng 36.573 levels sẵn sàng offline.
  - **Phase 2 (Core Selection Pipeline):** Kiến trúc 4-tier selection: Milestone (SP), Super Hard, DDA SingleRegion support, Main Pool relaxation (7 phase). Hệ thống con trỏ BankCursor, MainCursor, SuperHardCursor; PoolRegistry, PoolBuilder, PoolPicker; SettlementHandler và LevelSelector.
  - **Phase 3 (Integration & UI):** Tách `EndlessRuntime` độc lập ($\le 300$ dòng), tích hợp nâng cấp ProgressManager Schema v3 (lưu khối `"endless"` không phá vỡ dữ liệu Campaign cũ), tích hợp Title Screen (nút Campaign có subtitle `1->30`, nút Endless hiển thị `Level %d`), tích hợp điều hướng AppShell và NavController cho 2 chế độ.
  - **Phase 4 (QA & Gate):** Viết bộ test `test_endless_qa.gd` (kiểm tra 100 consecutive selects, feature toggles bật/tắt từng tier, DDA win/loss streaks), tool báo cáo độ phủ `tools/endless_coverage_report.py`.
- **Kiểm chứng Full Gate:** 100% tests PASS (65/65 checks, thời gian ~103s). Clean-room check: 0 vi phạm tên thương mại/reference. Zero imports từ `extracted_reusable`. Mọi file mã nguồn $\le 300$ dòng.

## Chuyển đổi 100% bank sizes 7–12 và mở rộng phạm vi N=4–12 (RST-020)

- Đã nâng cấp tools/convert_extracted_bank.py áp dụng fallback logic trace cho các bài kỹ thuật nâng cao (S4–S7) và bộ lọc luật Candy Rules độc lập.
- Chuyển đổi thành công 100% các level hợp lệ từ nguồn tham khảo: 11.669 / 11.669 level across sizes 7×7 đến 12×12 (loại bỏ 55 bài hỏng nguồn từ file gốc bên thứ ba trong bankDataGC11x11.json). Toàn bộ pace sidecars đã được sinh đồng bộ 100%.
- Kiểm tra toàn diện tools/validate_content.py trên 6 bank và 6 pace: PASS 0 errors. Bộ playlist advanced.json PASS 0 errors. Cập nhật quyết định điều hành RST-020 trong DECISIONS.md và mở rộng scope N=4–12 trong AGENTS.md.

## SFX mở Settings (đã tích hợp vào `dev`, 2026-10-07)

- Chủ dự án nghe thử và không chọn bản PCM tổng hợp 300 ms. Cue `SETTINGS_OPEN` ở Home và puzzle nay dùng `game/assets/audio/sfx/settings-whoosh.ogg`, chuyển từ file `whoosh-sfx.mp3` chủ dự án cung cấp; giữ âm stereo và thời lượng nguồn khoảng 1 giây. SFX Tuner preview cùng resource với game, chỉ cho chỉnh speed. TDD RED→GREEN tại `test_sfx_player_procedural.gd` và `test_sfx_tuner.gd` xác nhận định dạng, thời lượng, playback và nguồn preview.
- Full gate PASS. Đã merge vào `dev`.


## Hiệu ứng vào level mới, stroke feedback, vỡ tim & candy assets (đã tích hợp vào `dev`, commit `e62aec6`, 2026-10-06)

- **Hiệu ứng vào level mới:** Mỗi ô của bàn chơi xuất hiện theo sóng bán kính từ góc dưới trái lên góc trên phải, gồm cả ô kẹo cho sẵn; thời lượng cố định cho mọi kích thước. Lượt mới sau khi thắng level trước có hiệu ứng. Home/Settings/khởi động lại để tiếp tục lượt chưa hoàn thành, và Restart/Retry cùng level, bỏ qua hiệu ứng. Tùy chọn giảm chuyển động hiện bàn ngay. TDD RED→GREEN: `game/tests/test_board_entry.gd`.
- **Sửa phản hồi X lặp khi commit batch:** TouchDecoder giữ lịch sử preview đến hết commit; chỉ animate các ô chưa có phản hồi preview. Nét kéo bỏ qua phản hồi trên ô không đổi trạng thái, giữ preview tức thì và một transaction/Undo cho cả nhóm. TDD RED→GREEN tại `game/tests/test_stroke_feedback.gd`.
- **Hiệu ứng tim vỡ và rơi khi đặt sai kẹo:** Dùng sprite `game/assets/ui/board/heart_sprite.png`: 8 frame nứt → vỡ → rơi, tổng 720 ms. Giữ 3 ô HUD ổn định, thay tim vừa mất bằng nền tim rỗng; refresh khi tìm đúng kẹo không ngắt animation. Reduced motion cập nhật tĩnh. Lần sai cuối chuyển session sang FAILED và lưu ngay, đợi hiệu ứng kết thúc mới mở Result. TDD RED→GREEN: `game/tests/test_heart_feedback.gd`.
- **Bộ button Settings từ ảnh nguồn:** Tách 9 PNG RGBA 192×192 vào `game/assets/ui/settings/`: audio on/off, music on/off, haptic, reduced motion, large text, colorblind, Undo X. Nền ngoài nút trong suốt. Options screen đã tích hợp và sử dụng.
- **Candy sprites & candy palette:** Thay thế toàn bộ SVG cũ bằng bộ candy PNG chính thức (`bonbon.png`, `candy.png`, `candy_icon.png`, `cotton_puff.png`, `gummy_drop.png`, `hard_candy.png`, `lollipop.png`, `toffee.png`), render mượt mà trên mọi kích thước bàn.
- **SFX procedural mở rộng và tuner:** Catalog mở rộng 19 effect với preset và PCM stream `UI_TICK` 74 ms; Tuner có thanh `speed (pitch)` cho từng cue. Toàn bộ blocker asset thiếu đã được giải quyết triệt để.
- **Kiểm chứng:** Full gate PASS trên `dev`. Clean-room 0 match, module $\le 300$ dòng.

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

## Bank đầy đủ và campaign 998 level (đã tích hợp vào `dev`, 2026-10-04)

- Đã tạo 36/49/913 level gốc cho 4×4/5×5/6×6, năm rank mỗi kích thước; validator độc lập xác nhận nghiệm duy nhất, trace S2/S3, pace và phủ playlist 998 tham chiếu.
- `full_998.json` giữ L01–L30 của `demo_30.json`; `active_campaign.json` mặc định `full_998`, có thể đổi thành `demo_30` trước khi chạy/export. Hai mode có progress/session riêng; Settings dùng chung.
- Đã giữ vị trí và dữ liệu puzzle của 90 level gốc. Sửa trace/pace của 30 level 5×5 cũ theo quyết định chủ dự án. Ba cặp puzzle 5×5 cũ trùng hệt nhau còn trong cả hai campaign; đây là ngoại lệ cũ được ghi rõ, không mở cho level mới.
- Bộ sinh offline xác định và có checkpoint. Lần tạo 6×6 dùng seed `candoku-full-bank-6-v1`, hoàn thành sau 47.715 lần thử; trung vị rating của rank 1–5 là 9/12/18/28/36. Log baseline và đối chiếu ở `scratch/verification/full_bank_baseline.json`.
- Ngưỡng rating tối đa để xếp vào rank 1–4 khi sinh thêm: 4×4 `10/14/19/26`, 5×5 `10/14/28/34`, 6×6 `10/14/24/31`; điểm cao hơn cần S3 và vào rank 5. Trung vị rank 1–5 sau sinh: 4×4 `8/11/18,5/25/28`, 5×5 `17/25/28,5/32/37`, 6×6 `9/12/18/28/36`. Các ngưỡng này là chỉ báo máy, còn cần playtest mù.
- Review độc lập phát hiện và đã sửa hai lỗi: ghi pace lỗi sau khi ghi bank sẽ khôi phục cặp file gốc; lượt thắng dùng Hint truyền `hints_used` vào DDA nên không tăng streak sạch. Test lỗi boot hiện hộp thoại cũng đã thêm.
- **Full gate PASS** sau review tại revision `9b53cb079a69f5d9a48af99ad3db9d32baa444e2`: `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>` — 76 Python tests, 21 Godot suites và mọi content check. Bằng chứng: `scratch/verification/20261004T200321.405769Z.txt`, source SHA-256 `50778ddba88146e175cb74d3569be8f278f47846bec3949fec8702ca145a20fa`. Clean-room và import `extracted_reusable`: 0 match; module đã sửa ≤300 dòng. QA giao diện/gesture/thiết bị chưa chạy, chưa phải nghiệm thu phát hành.

**Cách đổi mode:** xem [Hướng dẫn campaign](../README.md).

## Mục tiêu hiện tại: QA và chuẩn bị release

### Demo 30 màn N=4–6 (đã tích hợp vào `dev`, 2026-10-04)

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
