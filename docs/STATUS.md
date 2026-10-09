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
