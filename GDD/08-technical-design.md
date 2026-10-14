# GDD-08 — Technical Design

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-08 |
| Phiên bản | 1.0.0 |
| Trạng thái | Draft · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Liên quan | [GDD-02](02-core-gameplay.md), [GDD-03](03-game-systems.md), [GDD-05](05-level-design.md), [GDD-07](07-audio.md), [GDD-09](09-qa-acceptance.md), [GDD-11](11-level-generation.md) |

> **Tóm tắt:** CanDoKu là ứng dụng Godot 4.7/GDScript offline, không dependency ngoài, kiến trúc composition root không autoload. Chương này chốt module map thực tế, luồng runtime, schema dữ liệu (bank, pace, playlist, progress, session, config), lưu trữ dual-slot, pipeline input, ngân sách hiệu năng TECH-xx, cấu hình build và cổng kiểm chứng `tools/verify.py`.

## 1. Mục đích và phạm vi

- Mô tả kiến trúc và hợp đồng dữ liệu để kỹ sư mới có thể sửa code mà không phá luật hay save.
- Định nghĩa các yêu cầu kỹ thuật kiểm được (TECH-xx).
- Ngoài phạm vi: luật chơi ([GDD-02](02-core-gameplay.md)), thuật toán suy luận ([GDD-10](10-reasoning-techniques.md)), pipeline sinh level ([GDD-11](11-level-generation.md)), chiến lược test ([GDD-09](09-qa-acceptance.md)). Quy tắc nhánh/release: [`docs/VERSIONING.md`](../docs/VERSIONING.md).

## 2. Tech stack

| Thành phần | Công nghệ | Ghi chú |
| --- | --- | --- |
| Engine | Godot 4.7 (`config/features`) | Renderer `mobile`, nén texture ETC2/ASTC |
| Ngôn ngữ | GDScript | Static typing khi khả thi |
| Dữ liệu | JSON (bank, pace, playlist, save); bank release có thể XOR-encode | `bank_codec.gd` |
| Lưu trữ | File cục bộ `user://`, ghi nguyên tử, A/B slot | `dual_slot_store.gd` |
| Audio | PCM procedural (`pcm_synth.gd`) + OGG Vorbis | [GDD-07](07-audio.md) |
| Haptic | `Input.vibrate_handheld()` | `vibration.gd` |
| Localization | `game/locale/strings.csv` → `.translation`, 7 ngôn ngữ | en, ja, vi, id, pt_BR, es, ko |
| Tooling | Python 3 (validator, generator, verify) | `tools/`, `GDD/tools/` |
| Dependency ngoài | Không có — không plugin, addon, SDK, mạng, backend, analytics, IAP, ads | |

## 3. Nguyên tắc kiến trúc

| ID | Nguyên tắc | Tiêu chí kiểm |
| --- | --- | --- |
| TECH-25 | Không autoload. `app_shell.gd` là composition root duy nhất: tạo store, reader, runtime, player; inject vào màn hình qua `setup()` | `project.godot` không có mục `[autoload]` |
| TECH-26 | Giao tiếp bằng Godot signal native; không event bus toàn cục | Gate clean-room (§11) không có match |
| TECH-27 | Logic thuần là static, stateless, test được headless: `cell_model`, `candy_rules`, `board_solver`, `solver_techniques`, `board_transform`, `region_painter` | Có suite headless tương ứng |
| TECH-28 | Mỗi module ≤ 300 dòng, một file một trách nhiệm | `wc -l game/scripts/*/*.gd` |
| TECH-17 | Renderer/sprite không chứa luật; đổi asset hay animation không đổi core | Review + `test_candy_rules.gd` độc lập UI |
| TECH-11 | Không thu thập dữ liệu cá nhân, không truyền mạng | Không có API mạng trong `game/scripts/` |

## 4. Module map

Đường dẫn dưới `game/scripts/`.

| ID | Khu vực | File chính | Trách nhiệm | Test chính |
| --- | --- | --- | --- | --- |
| TECH-02 | `core/` | `cell_model`, `candy_rules`, `board_solver`, `solver_techniques`, `hint_engine`, `candy_renderer`, `game_features`, `locale_resolver` | Trạng thái ô (BLANK/MARK/CANDY/ERROR), chấm `try_candy` theo solution, solver S1–S7 bitmask, hint engine, chọn texture kẹo, feature flag | `test_candy_rules`, `test_board_solver`, `test_hint_engine`, `test_game_features` |
| TECH-03 | `input/` | `touch_decoder`, `touch_guard`, `board_pointer_router`, `play_session` | Giải mã tap/double-tap/vuốt, bảo vệ vuốt 3 lớp, phiên chơi (tim, lỗi, undo một slot, thời gian, phase) | `test_touch_decoder`, `test_touch_guard`, `test_play_session`, `test_board_input_blocking` |
| TECH-06 | `state/` | `dual_slot_store`, `session_store`, `progress_manager`, `config_store` | Lưu nguyên tử A/B, session v3, progress v3 (migrate v1/v2), config v1 | `test_dual_slot_store`, `test_session_store`, `test_progress_manager`, `test_config_store` |
| TECH-01 | `content/` | `bank_reader`, `bank_codec`, `flat_bank_cache`, `pace_reader`, `board_transform`, `region_painter`, `level_validator`, `shape_fingerprint` | Đọc bank (size/typed, XOR), cache phẳng, pace sidecar, transform ×8, tô màu vùng, validate level, fingerprint hình vùng | `test_bank_reader`, `test_bank_codec`, `test_shape_fingerprint`, `test_region_contrast` |
| TECH-22 | `campaign/` | `campaign_runtime`, `campaign_selector`, `nav_controller`, `pace_adjuster`, `snapshot_builder`, `bank_cursor`, `tutorial_flow`, `tutorial_guide`, `tutorial_tips`, `tutorial_targets` | Playlist, boot bank/pace, DDA rank, snapshot save/resume, FSM màn hình, tutorial/tips | `test_campaign_runtime`, `test_pace_adjuster`, `test_tutorial_*` |
| TECH-23 | `endless/` | `endless_runtime`, `endless_config`, `endless_progress`, `level_selector` | Endless mode (tắt bằng `ENABLE_ENDLESS=false`): provider, tier, pool, size schedule, settlement | `test_endless_*`, `test_level_selector`, `test_providers` |
| TECH-20 | `feedback/` | `sfx_catalog`, `sfx_player`, `pcm_synth`, `bgm_player`, `combo_tracker`, `tween_fx`, `vibration`, `sfx_tuner` | Âm thanh, combo, tween, rung | `test_pcm_synth`, `test_sfx_*`, `test_combo_tracker`, `test_tween_fx` |
| TECH-18 | `screens/` | `app_shell`, `puzzle_screen`, `puzzle_board`, `puzzle_board_painter`, `cell_animator`, `board_entry_wave`, `puzzle_layout`, `puzzle_hint_coordinator`, `hint_overlay`, `hint_highlight_layer`, `hint_mutex`, `title/win/fail/help/options/tutorial_screen`, debug panels | Composition root, màn hình, presenter bàn chơi, UI hint, combo popup | `test_screens`, `test_integration`, `test_hint_*`, `test_win_screen` |
| TECH-24 | `theme/` | `palette`, `candy_palette`, `layout_tokens`, `font_tokens`, `text_scaler`, `overlay_style` | Token màu, kẹo, layout/timing, font, cỡ chữ | `test_font_tokens`, `test_colorblind`, `test_large_text` |
| TECH-29 | `ui/` | `action_button`, `ribbon_banner`, `stat_card`, `confetti_layer`, `gradient_bg`, `progress_bar`, mascot/logo widgets | Widget UI tái sử dụng | `test_ui_widgets`, `test_mascot_motion` |
| TECH-30 | `game/splash/` | `splash_screen.gd` + `logo_shine.gdshader` | Main scene, splash rồi chuyển sang `app_shell` | `test_runtime_smoke.py` |

`TECH-04` (solver S1–S7) và `TECH-04b` (hint engine) nằm trong `core/`; chi tiết thuật toán ở [GDD-10](10-reasoning-techniques.md), hành vi hint ở [GDD-03](03-game-systems.md). `TECH-05` (UI controller/nav FSM) nằm trong `campaign/nav_controller.gd` + `screens/app_shell.gd`. `TECH-07` (content pipeline) nằm ngoài runtime, xem §10.

Feature flag (`core/game_features.gd`): `ENABLE_CAMPAIGN = true`, `ENABLE_ENDLESS = false`.

## 5. Luồng runtime

1. **Boot**: main scene `splash/splash_screen.tscn` (nền `#FFFDF5`) → nạp `app_shell`.
2. **Composition**: `app_shell` tạo `ConfigStore`, `ProgressManager`, `SessionStore`, `BankReader`, `PaceReader`, `CampaignRuntime` (+ `EndlessRuntime`), `SfxPlayer`, `BgmPlayer`, `NavController`; áp config (audio, music, haptic, motion, contrast, colorblind, language); phát BGM.
3. **Campaign boot**: `campaign_selector` đọc `data/campaigns/active_campaign.json` (hiện `campaign_100`), nạp playlist; `bank_cursor` + `board_transform` dựng level cụ thể.
4. **Điều hướng**: `NavController` FSM `TITLE → PUZZLE → WIN | FAIL`; Help, Options, Tutorial là overlay/màn phụ. Lần đầu chơi đi qua tutorial bắt buộc.
5. **Chơi**: `puzzle_screen` nhận input qua `board_pointer_router` → `play_session` (mark_x, mark_stroke, try_candy, undo) → signal → presenter/feedback. Mỗi action đã commit lưu session.
6. **Kết thúc**: thắng → `progress_manager.advance_level` ghi progress trước, xóa session, rồi vào WIN; thua → lưu session `failed`, vào FAIL; Retry tạo session mới cùng level.

## 6. Data schemas

### 6.1 Level (trong bank)

| Field | Kiểu | Ghi chú |
| --- | --- | --- |
| `seed` | int/string | Seed sinh |
| `regions` | `string[N]` | N chuỗi dài N, nhãn vùng `A..L` |
| `solution` | `int[N]` | Cột kẹo của từng hàng |
| `givens` | array | **Phải rỗng**; validator từ chối nếu khác rỗng |
| `steps`, `profile`, `rating` | — | Metadata độ khó ([GDD-11](11-level-generation.md)) |
| `pidHash` | string | Hash nhận diện puzzle |
| `logicTrace` | array | Chuỗi bước suy luận |
| Typed extras | — | `id`, `label`, `size`, `rank`, `colorMap`, `pattern`, `spRegion`, `shapeCategory`, `maxRegionFrac` |

### 6.2 Bank, pace, playlist

| Schema | Cấu trúc |
| --- | --- |
| Size bank | `{bankVersion, size, ranks: {"1".."5": [level]}}` — 25 file (`bank_4x4..12x12`, `bank_gc_*`, `bank_lkstyle_*`, `bank_onefish_*`) |
| Typed bank | `{bankVersion, type, levels: [level]}` — `lk`, `lk_modified`, `single_region`, `sp`, `sp_tt`, `super_hard` |
| Pace sidecar | `{bankVersion, size, pacing: {rank: [{rSeq, hintCosts}]}}` hoặc typed `{bankVersion, type, levels: [{rSeq, hintCosts}]}`; `hintCosts` chỉ được validate, runtime không trừ |
| Playlist | `{campaignVersion: 1, id, playlist: [{label, size, rank, index, difficulty}]}` |
| Endless config | `data/endless_config.json`: tiers, pools, size schedule |

31 bank + 31 pace, tổng 36.573 level. Chi tiết nội dung: [GDD-05](05-level-design.md).

### 6.3 Progress v3 (`progress`)

| Field | Ghi chú |
| --- | --- |
| `progressVersion` | `3`; v1/v2 có `currentLevelId` được migrate, giữ các key đã có |
| `currentLevelId` | Level kế tiếp |
| `completedLevelIds` | Danh sách đã thắng |
| `results` | `{levelId: {time_ms, mistakes, hints_used}}` |
| `tutorialSeenIds` | Tutorial/tip đã xem |
| `recentShapes` | Fingerprint hình vùng gần đây (cap 50) |
| `endless` | Dữ liệu Endless (level_num, strategy, streaks, totals, best_by_size, cursors, recent_hashes) |

### 6.4 Session v3 (`session`)

| Field | Ghi chú |
| --- | --- |
| `sessionVersion` | `3` |
| `levelId`, `puzzleHash`, `boardSize` | `puzzleHash` = SHA-256 của JSON `[size, regions, givens, solution]` |
| `cells` | N² giá trị theo hàng; chấp nhận `empty`, `x`, `candy`, `error`, `wrong`, `locked` (`locked` đọc thành BLANK) |
| `hearts`, `mistake_count`, `hints_used`, `elapsedMs` | Trạng thái lượt |
| `status` | `playing` / `failed` |

### 6.5 Config v1 (`config.json`)

`{version: 1, options: {audio, music, haptic, reduced_motion, high_contrast, large_text, colorblind, language}}`. Mặc định: `audio/music/haptic = true`, còn lại `false`, `language = ""` (tự nhận). `language` ∈ `"", en, ja, vi, id, pt_BR, es, ko`.

## 7. Save và persistence

Thư mục `user://profile` (custom user dir `ASOL Game 02`, giữ nguyên để không mất save khi đổi tên hiển thị).

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| TECH-31 | Progress và session dùng `DualSlotStore`: `<name>.a.json`/`.b.json` + `<name>.flag` chỉ slot hợp lệ; ghi slot không hoạt động qua `.tmp` rồi đổi tên, sau đó lật flag; đọc lỗi thì phục hồi từ slot kia; đọc được file legacy `<name>.json` | `test_dual_slot_store.gd` (gồm inject corrupt) |
| TECH-32 | Config ghi một file `config.json` qua `.tmp` + replace; version sai thì về mặc định | `test_config_store.gd` |
| TECH-08 | Slot Undo chỉ ở runtime, không lưu; mỗi action đã commit (board/tim/hint) ghi session trước phản hồi bền vững | `test_play_session.gd`, `test_session_store.gd` |
| TECH-09 | Progress tách session; session hỏng không ảnh hưởng completed/results; progress hỏng không bị ghi đè bằng trống | `test_progress_manager.gd` |
| TECH-10 | Khi load session kiểm version = 3, `levelId`, `puzzleHash` và hình dạng `cells`; sai thì tạo session mới cùng level, không tiến level | `test_session_store.gd` |
| TECH-15 | Action đã lưu khôi phục sau khi app bị tắt; thắng đã hiển thị mở level kế | `test_integration.gd`, QA thiết bị |
| TECH-12 | ID và nội dung level đã phát hành bất biến; thêm level ở cuối playlist | `validate_full_content.py` |

## 8. Pipeline input

| Lớp | File | Hành vi |
| --- | --- | --- |
| Guard | `touch_guard.gd` | Ngưỡng kéo 12 px; velocity gate bỏ chuyển động > 6000 px/s; không khóa trục, cho phép chéo; nội suy span tối đa 12 ô ([RST-022](../docs/DECISIONS.md)) |
| Decoder | `touch_decoder.gd` | Tap đơn commit sau cửa sổ 350 ms hoặc khi có chạm mới; tap thứ hai cùng ô trong 350 ms → double-tap; vuốt → stroke |
| Router | `board_pointer_router.gd` | Nối guard + decoder + tra ô; chỉ nhận ngón đầu bắt đầu trong bàn |
| Session | `play_session.gd` | `mark_x` (BLANK↔MARK), `mark_stroke` (chế độ theo ô đầu), `try_candy`, `undo` (một slot) |

Hành vi người chơi thấy: [GDD-02](02-core-gameplay.md). Input bị chặn ngoài phase ACTIVE (`test_board_input_blocking.gd`).

## 9. Ngân sách hiệu năng

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| TECH-13 | Mở level < 2 s sau startup trên thiết bị mục tiêu | Đo trong evidence QA thiết bị |
| TECH-14 | X hiện trong khung hình đầu (< 50 ms); double-tap phản hồi < 100 ms sau chạm thứ hai; khi vuốt, mỗi X hiện ngay khi đi qua ô | QA thiết bị, `test_stroke_feedback.gd` |
| TECH-19 | ≥ 55 FPS khi tương tác trên Android/iPhone mục tiêu; không khựng > 100 ms khi pop kẹo hoặc vào Result; ghi peak RAM/VRAM | Profiler trên thiết bị |
| TECH-33 | Render bàn lớn (N=7–12): X tĩnh vẽ từ texture pre-baked theo batch, tra preview/highlight bằng hash set O(1), solver dùng bitmask precompute ([RST-023](../docs/DECISIONS.md)) | `test_cell_animator.gd`, `test_board_solver.gd`; vuốt 12×12 không giật |
| TECH-21 | Texture kẹo dùng chung và cache theo loại; asset lỗi có fallback và không đổi session | `test_candy_renderer.gd` |

Các ngưỡng là mục tiêu, **chưa đo**; số đo thực ghi trong evidence QA (Track E), không ghi ở đây.

## 10. Build và platform

| Hạng mục | Giá trị |
| --- | --- |
| Tên app | CanDoKu |
| Package / Bundle ID | `org.asol.game02` (Android và iOS) |
| Hướng màn hình | Portrait; viewport 1080×1920, stretch `canvas_items` / `expand` |
| Icon | `res://assets/icons/candoku-logo-1024.png` |

| Export preset | Platform | Phiên bản | Output |
| --- | --- | --- | --- |
| Android M0 Debug | Android | 0.0.0-m0 (code 1) | `build/android/asol-game-02-debug.apk` |
| iOS M0 Debug | iOS | — | `build/ios/asol-game-02` |
| Android Release | Android | 1.0.1 (code 2) | `build/android/candoku-v1.0.1.apk` |
| iOS Release | iOS | 1.0.1 | `build/ios/candoku-v1.0.1` |
| Web | Web | — | `build/web/index.html` |

Android là nền tảng chính; iOS cần máy Mac và signing; Web dùng cho xem thử. Kiểm cấu hình bằng `test_export_presets.py`, `test_android_export_settings.py`, `test_mobile_settings.py`.

## 11. Toolchain và verification

| Công cụ | Vai trò |
| --- | --- |
| `tools/verify.py --godot <exe>` | Full gate; ghi log evidence |
| `tools/validate_content.py` | Validate bank + pace + playlist (4×4–6×6, `demo_30`, `demo_cross`) |
| `tools/validate_full_content.py` | Validate toàn bộ bank với `full_998` |
| `tools/playlist_checks.py` | Kiểm playlist |
| `tools/convert_extracted_bank.py`, `tools/encode_banks.py` | Chuyển bank nguồn, XOR-encode bản release |
| `tools/endless_coverage_report.py` | Báo cáo độ phủ Endless |
| `tools/build_combo_atlas.py` | Đóng gói atlas word-art combo |
| `GDD/tools/*` | Sinh level, rating, pace, campaign ([GDD-11](11-level-generation.md)) |

`verify.py` chạy theo thứ tự: `unittest` Python trong `game/tests`, `GDD/tools`, `tools/tests` → `validate_levels.py` trên sample → `validate_content.py` cho bank 4/5/6 và `demo_30`/`demo_cross` → `validate_full_content.py` cho `full_998` → mọi suite `game/tests/test_*.gd` headless. Một check fail nếu exit ≠ 0 hoặc output có `SCRIPT ERROR`, `ERROR:`, test bị skip hay 0 test.

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| TECH-16 | Không merge khi `verify.py` chưa pass toàn bộ | Log evidence tại `scratch/verification/` ghi revision, lệnh, kết quả |
| TECH-07 | Mọi nội dung đưa vào `game/data/` phải qua validator (givens rỗng, nghiệm duy nhất, trace hợp lệ) | `validate_content.py`, `validate_full_content.py` |

### Clean-room

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| TECH-34 | Không dùng tên, enum, class hay chuỗi từ code tham khảo trong `game/scripts/` | `tools/clean_room.py` không có match |
| TECH-35 | Gate clean-room chạy tự động trong full verify | `tools/verify.py` gọi `tools/clean_room.py` (check `clean-room`) |

## 12. ID đã hủy

| ID | Lý do |
| --- | --- |
| — | TECH-10 giữ ID nhưng bỏ phần migrate session v2 (code chỉ chấp nhận session v3). Các TECH khác được giữ và cập nhật nội dung theo code; không ID nào bị hủy hoàn toàn. |

## 13. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| TECH-Q2 | Chưa chốt thiết bị Android/iPhone mức thấp để đo TECH-13/14/19 | Không có số đo hiệu năng | Chốt trong Track E |
| TECH-Q3 | Hằng `AUTO_MARK_STAGGER_MS`, `LOCK_FADE_MS`, `MAX_UNDO_DEPTH` còn trong `layout_tokens.gd` nhưng không dùng | Gây hiểu nhầm về auto-mark và undo stack | Dọn trong task refactor |
| TECH-Q4 | Assist inventory (stock, place-candy, play streak) đang phát triển và sẽ mở rộng progress | Schema progress có thể đổi | Planned; cập nhật §6.3 khi merge |

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất GDD 05, ARCHITECTURE và TECH_STACK, cập nhật theo code hiện hành |
