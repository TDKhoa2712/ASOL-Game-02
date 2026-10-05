# Trạng thái dự án

> Cập nhật: 2026-10-05

## Procedural SFX (trên `feat/procedural-sfx`, chưa merge)

- `pcm_synth.gd` sinh PCM mono 16-bit/22050 Hz: bốn waveform, pitch sweep, ADSR fit theo thời lượng, noise và low-pass. Engine bảo toàn attack ≥5 ms/release ≥10 ms, ưu tiên ramp khi envelope quá dài; âm ngắn hơn 15 ms co hai ramp theo tỷ lệ. Mẫu đầu/cuối luôn về 0. Enum pitch là `PitchCurve` vì `Curve` trùng class Godot.
- 9 effect có stream prewarm, gồm 7 âm đơn và 2 melody; pool 8 voice, pitch variation cho bốn effect, MARK giữ giới hạn 100 ms. Mute dừng mọi voice. Nút trong composition root phát BTN_PRESS qua signal native.
- [SFX Tuner](../game/scenes/sfx_tuner.tscn): chạy F6, chọn preset, chỉnh slider/dropdown, Play hoặc Space, Copy Params ra clipboard/console. Melody giữ chuỗi nốt và `note_dur`; output được kiểm tra biên dịch như dictionary GDScript.
- TDD: engine, player, tuner và dispatch gameplay có test tự động; test feedback cũ đã chuyển từ đường dẫn `.ogg`/mock sang playback thật. Tuner đã kiểm tra render Vulkan và clipboard Windows; ảnh tại `scratch/verification/sfx-tuner-mark.png` và `sfx-tuner-melody.png` trong worktree audio.
- Review độc lập đã hoàn thành; sửa lỗi biên envelope gây click/pop bằng test RED→GREEN cho attack/release bằng 0, envelope quá dài, duration 20 ms và melody ngắn. Test cũng kiểm tra saturation đúng dấu/biên độ và exponential sweep với endpoint 0 khớp PCM linear.
- Full gate sau sửa review PASS: 76 Python tests, 32 Godot suites và content checks. Lệnh: `rtk python -B tools/verify.py --godot <Godot 4.7.2 executable>`; evidence `scratch/verification/20261005T085734.476968Z.txt`, revision `7a7ac75881e2c703c97fba9d7dcfb0785d93363f`, không có thay đổi tracked; source SHA256 `209e9f7f741ae9f899ee8c216a3961c47ed23f5457480accb25e98e280a271aa`. Clean-room/import reference: 0 match; các module audio ≤300 dòng.
- Worktree bàn giao: `D:/Work/Alpaca_Solution/ASOL-Game-02-sfx`, nhánh `feat/procedural-sfx`; chưa merge/push. Lịch sử giữ nguyên commit session/debug `c8202b5` do phiên khác thực hiện, không nhận là thay đổi audio.
- BGM `main_theme.ogg` vẫn thiếu. QA nghe âm sắc/độ lớn/click-pop trên loa, tai nghe và thiết bị mục tiêu chưa thực hiện; chưa phải nghiệm thu phát hành.

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
- **Track D — Assets:** 9 SFX đã có bản procedural trên nhánh audio, còn QA nghe và tích hợp; BGM, font, logo và candy sprites vẫn cần sản xuất/duyệt.
