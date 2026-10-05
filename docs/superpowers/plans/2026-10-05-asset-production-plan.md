# Plan: Asset Production — CanDoKu (Track D)

> Ngày lập: 2026-10-05. Nền: `dev` HEAD sau merge PR #10–#15.

## Mục tiêu

Thu thập, tạo và tích hợp toàn bộ audio + visual assets cần thiết để đưa game từ trạng thái placeholder sang playtest-ready. Track D nằm song song với QA (Track E) và phải hoàn tất trước khi bắt đầu playtest thiết bị.

## Tổng quan pipeline

```
D1: Audio Production (external)  ──┐
D2: Visual Production (external) ──┤──→ D3: Integration (agent) ──→ Track E
```

---

## D1: Audio Assets — 9 SFX + 1 BGM

**Người thực hiện:** Sound designer / procedural audio (xem `godot-procedural-audio-design.md` cho phương án tự sinh)

| # | File | Vai trò | Spec | Priority |
|---|------|---------|------|----------|
| D1.1 | `bgm/main_theme.ogg` | BGM chủ đạo | OGG Vorbis 48kHz, stereo, 60-90s loop, -14 LUFS | P0 |
| D1.2 | `sfx/mark.ogg` | Đánh/bỏ X | Mono 16-bit, -10 dBFS peak, ≤0.5s | P0 |
| D1.3 | `sfx/candy_found.ogg` | Đặt kẹo đúng | Mono, tonal positive, ≤0.8s | P0 |
| D1.4 | `sfx/candy_wrong.ogg` | Đặt kẹo sai / lỗi | Mono, dissonant short, ≤0.5s | P0 |
| D1.5 | `sfx/hint.ogg` | Hiện gợi ý | Mono, subtle notification, ≤0.6s | P0 |
| D1.6 | `sfx/win.ogg` | Giải xong level | Mono/stereo, celebratory, ≤2s | P0 |
| D1.7 | `sfx/fail.ogg` | Thua level | Mono, deflating, ≤1.5s | P0 |
| D1.8 | `sfx/tap.ogg` | Nhấn nút UI | Mono, click/pop, ≤0.2s | P0 |
| D1.9 | `sfx/enter.ogg` | Vào puzzle | Mono, transition, ≤0.5s | P0 |
| D1.10 | `sfx/restart.ogg` | Chơi lại | Mono, reset feel, ≤0.4s | P0 |

**Format chung SFX:** OGG Vorbis 48kHz, mono 16-bit, peak ≤ -10 dBFS.

**Cấu trúc thư mục đích:**
```
game/audio/
├── bgm/
│   └── main_theme.ogg
└── sfx/
    ├── mark.ogg
    ├── candy_found.ogg
    ├── candy_wrong.ogg
    ├── hint.ogg
    ├── win.ogg
    ├── fail.ogg
    ├── tap.ogg
    ├── enter.ogg
    └── restart.ogg
```

---

## D2: Visual Assets

**Người thực hiện:** Artist / designer

### D2.1: Typography (P0)

| Asset | Spec | Ghi chú |
|-------|------|---------|
| Font chính | Inter / Nunito / Be Vietnam Pro | Regular + Bold, Latin + Vietnamese glyphs |
| Font số HUD | Monospace hoặc tabular figures | Số không nhảy layout khi thay đổi |

**Đích:** `game/assets/fonts/` + tạo `.tres` FontFile resources.

### D2.2: Game Art (P0)

| Asset | Spec | Ghi chú |
|-------|------|---------|
| Logo CanDoKu | SVG + PNG@2x | Thay `candy.svg` placeholder |
| Candy sprites (4-6) | PNG 128×128 @2x, transparent bg | Phân biệt rõ khi colorblind; mỗi loại cần cả normal và colorblind variant |

**Đích:** `game/assets/sprites/`

### D2.3: UI Assets (P1)

| Asset | Spec | Priority |
|-------|------|----------|
| App icon | 1024×1024 PNG, tròn-safe | P1 |
| Splash screen | 1080×1920 hoặc scalable | P1 |
| Win/fail banners | PNG @2x, có stars variant | P1 |
| 9-patch dialog/button frames | NinePatchRect compatible | P1 |

### D2.4: Polish Assets (P2)

| Asset | Spec | Priority |
|-------|------|----------|
| Toast backgrounds | 9-patch hoặc stylebox | P2 |
| Custom switch/toggle | Thay Godot default | P2 |

---

## D3: Tích hợp vào game (agent task)

**Điều kiện:** D1 và/hoặc D2 assets sẵn sàng.

| # | Task | Chi tiết | Gate |
|---|------|----------|------|
| D3.1 | Import fonts | Copy vào `game/assets/fonts/`, tạo `.tres` resources, cập nhật theme | Theme renders đúng |
| D3.2 | Import audio | Copy vào `game/audio/sfx/` và `game/audio/bgm/` | File load không lỗi |
| D3.3 | Wire audio events | Đảm bảo `sound_player.gd` map đúng event → file | Mỗi action phát đúng SFX |
| D3.4 | Import sprites | Copy vào `game/assets/sprites/`, cập nhật references | Hiển thị đúng |
| D3.5 | Test colorblind | Candy sprites + overlay đúng khi colorblind ON | `test_colorblind.gd` PASS |
| D3.6 | Test audio playback | Chạy qua tất cả events, kiểm volume/timing | Manual + headless |
| D3.7 | Test reduced_motion | Animation skip khi reduced_motion ON | Không break |
| D3.8 | Full gate | `python -B tools/verify.py --godot <executable>` | PASS |

---

## Lưu ý

- **Asset gốc:** Tất cả phải là tác phẩm gốc hoặc có license phù hợp. Không sao chép từ reference hoặc game thương mại.
- **Phạm vi R1:** Chỉ assets cho 30 levels, N=4-6. Không chuẩn bị cho Endless, IAP, hoặc features ngoài scope.
- **Procedural audio:** Xem `docs/superpowers/specs/godot-procedural-audio-design.md` cho phương án sinh SFX bằng code thay vì file ngoài — giảm phụ thuộc sound designer.
- **Tham chiếu completion plan:** [Track D](2026-10-03-completion-plan.md) trong Completion Plan.
