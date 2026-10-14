# Trạng thái dự án

> Cập nhật: 2026-10-09
> Quản lý version: [VERSIONING](VERSIONING.md). Nền tích hợp: nhánh version `release/vX.Y.Z`.

## Mục tiêu hiện tại: Chuẩn bị release v1.0.0

| Hạng mục | Trạng thái |
|----------|------------|
| Rebuild 10 Modules (M01–M10) | ✅ Hoàn tất |
| System Upgrade & Tooling (Solver S4–S7, DDA, XOR Codec) | ✅ Hoàn tất |
| Gameplay & UI Realignment | ✅ Hoàn tất |
| Kho nội dung 36.500+ Màn (N=4–12) | ✅ Hoàn tất |
| Endless Levels (4-tier selection) | ✅ Hoàn tất |
| Procedural SFX & Tuner (19 effects) | ✅ Hoàn tất |
| Tối ưu hiệu năng (RST-022, RST-023) | ✅ Hoàn tất |
| Tài nguyên (Logo, Candy sprites, Settings buttons) | ✅ Cơ bản |
| **Track D: BGM OGG, Font tiếng Việt, App Icon** | ⚠️ **Tồn đọng** |
| **Track E: QA thiết bị, Playtest** | ⚠️ **Tồn đọng** |
| **Track F: Đóng gói phát hành** | ⚠️ **Tồn đọng** |

Chi tiết Track D/E/F: [REMAINING_TASKS](REMAINING_TASKS.md)

---

## Bỏ given toàn hệ thống (2026-10-14, `feat/v1.0.1/tutorial`)

- Theo [plan](superpowers/plans/2026-10-14-remove-givens-system-wide.md): `CellKind` còn 4 trạng thái (bỏ GIVEN), xóa `pre_candy_decider` (DDA prefill), solver/session không còn đặt kẹo sẵn, bỏ halo và token GIVEN, bỏ gợi ý C-given (`tutorial.tip_given`) và target `excluded_by_given`.
- Bank: `bank_4x4` rank 1 index 1 (L02 trong demo_30) bỏ given, trace 4 bước S2, pidHash `7948b573`, pace tái tạo. Validator GDScript/Python coi `givens` là tùy chọn và **từ chối danh sách không rỗng**; `GDD/tools/bank_expansion_rules.py` đặt trần given = 0.
- Full verify rev `1ef16ee`: 99 PASS, 1 FAIL `test_settings_apply` do sửa đổi chưa commit có sẵn (`_test_reduced_motion_live` khai báo trùng); bản đã commit PASS. Evidence `scratch/verification/20261014T051607.600700Z.txt`.
- Còn lại: GDD 03 (bảng gợi ý C-given) và DECISIONS (dòng L02 nhắc C-given) cần cập nhật câu chữ; tiến độ đã lưu của L02 (fingerprint gồm `givens`) sẽ không khớp bản cũ.

## Tutorial bắt buộc (2026-10-14, `feat/v1.0.1/tutorial`)

- RST-028: màn tutorial riêng phủ Home cho tới khi xong (`tutorial_flow.gd`, `tutorial_screen.gd`), 7 bước theo luồng tham khảo `scratch/img-tutor`; Trợ giúp chơi lại dạng thực hành. L01/L02 về bàn bank. Suite `test_tutorial_flow`, `test_tutorial_screen`, `test_tutorial_campaign` PASS; đã chụp màn chạy thật 540×960.
- Còn lại: QA thiết bị (độ to chữ, nhịp tay, rung) và duyệt bản dịch.

## Tutorial L01/L02 + gợi ý ngữ cảnh (2026-10-14, `feat/v1.0.1/tutorial`) — thay bởi mục trên, giữ phần gợi ý ngữ cảnh

- RST-027 / GDD 03 §4: bàn viết tay `game/data/tutorial/tutorial.json` (L01 `ABCC/AACC/AADD/DDDD`, L02 `ADDD/ADDD/CDBB/CCBB`), guide suy bước từ bàn, miễn phạt ô được gọi tọa độ, Bỏ qua, gợi ý C-err/heart1/undo/given/size5/s3/idle, Trợ giúp → Chơi lại hướng dẫn. Chuỗi 7 ngôn ngữ.
- Suite mới PASS: `test_tutorial_targets`, `test_tutorial_guide`, `test_tutorial_tips`, `test_tutorial_campaign`, `test_tutorial_screen`; cập nhật `test_play_session`, `test_campaign_runtime`, `test_integration`.
- Full verify: 98 PASS, 1 FAIL `test_settings_apply` do sửa đổi chưa commit có sẵn trong working tree (hàm `_test_reduced_motion_live` khai báo trùng); bản đã commit của file PASS. Evidence `scratch/verification/20261013T172356.416515Z.txt`.
- Còn lại: auto-mark GR-34 chưa có trong code (L1-2 chỉ minh họa); QA thiết bị/playtest 10 người theo chỉ tiêu GDD 03 §4 chưa làm; bản dịch ja/id/pt_BR/es/ko cần người bản ngữ duyệt.

## Combo feedback (2026-10-10, `feat/v1.0.1/combo-feedback`)

- RST-026: voice 12 cấp + chữ nghệ thuật cho chuỗi đặt kẹo đúng. Headless suites combo/feedback/screens/integration PASS.
- Còn lại: QA trên thiết bị (nghe voice, nhìn popup, đo khung hình) chưa thực hiện.

## Mascot sprite animation (2026-10-10)

Kẹo trên board là linh vật động từ atlas `game/assets/candy/anim/mascot_atlas.png` (sinh bằng `game/tools/build_mascot_atlas.gd`): appear/idle/error/sad/win; tối đa 6 ô idle đồng thời, chỉ redraw khi khung đổi. Headless verify pass (`scratch/verification/20261009T191635.275269Z.txt`); chưa QA thiết bị.

## Tách Nhạc nền / Âm thanh (2026-10-10, `feat/v1.0.1/music-setting`)

- RST-025: hai công tắc độc lập trong Settings; profile cũ được giữ trạng thái tắt. Headless gate PASS; QA trên thiết bị chưa thực hiện.

---

## Tối ưu hiệu năng gần nhất (2026-10-08)

### RST-023 — Mark X GPU Batching & O(1) Sets
- Pre-baked vector texture cho X marks, batched `draw_texture_rect()` thay 480+ vector calls/frame
- O(1) Hash Set tra cứu preview/highlight, loại bỏ 17.000+ heap allocations/giây
- Full gate 66/66 PASS. Clean-room 0 match. Modules ≤ 300 dòng.

### RST-022 — Swipe Guards 3 lớp
- Velocity Gate, Multi-Axis Freedom, Neighbor Guard
- Tích hợp qua `board_pointer_router.gd` → `touch_decoder.gd`

### RST-021 — Undo X cố định
- Loại bỏ toggle cài đặt, Undo X luôn hoạt động

---

## Các mốc đã hoàn tất (tóm tắt)

| Mốc | Ngày | Nội dung chính |
|-----|------|---------------|
| Hint Engine v2 | 2026-10-09 | 5 chiến lược gợi ý, spotlight scrim, 3D bobbing pulse, giải thích tọa độ, PreCandyDecider |
| Repo cleanup & Undo X fix | 2026-10-08 | Dọn artifacts, cố định RST-021, full gate 66/66 PASS |
| BGM & SFX Settings | 2026-10-07 | BGM WAV loop fix, settings-whoosh.ogg, SFX 19 effects |
| Debug Mode & Campaign 100 | 2026-10-07 | Endless picker, reset progress, cheats toolbar, campaign_100.json |
| Endless Levels Phases 1–4 | 2026-10-07 | 4-tier selection, 36.573 levels, EndlessRuntime, Title Screen |
| Bank N=7–12 (RST-020) | 2026-10-07 | 11.669 levels, fallback logic trace, 100% conversion |
| Heart feedback & Board entry | 2026-10-06 | Heart break animation, entry wave, stroke feedback fix |
| Procedural SFX | 2026-10-05 | pcm_synth.gd, 19 effects, SFX Tuner, normal play session |
| Bank 998 levels (RST-019) | 2026-10-04 | 36/49/913 levels 4×4/5×5/6×6, full_998.json |
| Demo 30 (RST-018) | 2026-10-04 | demo_30.json cross-size 4×4–6×6 |
| Last-mile 1–6 | 2026-10-03 | DDA wired, colorblind toggle, bank 5×5/6×6, XOR encode |
| System Upgrade | 2026-10-03 | Solver S4–S7, DDA, ShapeFingerprint, BankCodec |
| Rebuild M01–M10 | 2026-10-02 | 10 modules clean-room, PR #1–#10 |

---

## Baseline

- `dev` chứa toàn bộ rebuild + system upgrade + last-mile + realignment + endless + tối ưu hiệu năng
- Từ đây chuyển sang Release Branch model: xem [VERSIONING](VERSIONING.md)
- Reference: `extracted_reusable/` (~224 files)
- Tag bảo toàn: `pre-reset-pipeline-2026-09-27`

## Việc cần chốt

- **Track D (Assets):** BGM OGG 48kHz, font tiếng Việt, app icon 1024×1024
- **Track E (QA):** Gesture thiết bị, safe area, playtest mù, thẩm âm SFX
- **Track F (Release):** Encode banks XOR, Android keystore, ẩn debug, build APK/AAB
