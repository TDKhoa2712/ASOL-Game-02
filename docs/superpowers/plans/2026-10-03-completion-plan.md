# CanDoKu Completion Plan

> Ngày lập: 2026-10-03. Cập nhật: 2026-10-09.
> Quản lý version: [VERSIONING](../../VERSIONING.md).

## Tổng quan

Rebuild, system upgrade, content, endless mode và tối ưu hiệu năng đã hoàn tất. Còn 3 track để đưa game về trạng thái release-ready.

## Track Map

```
Track A: Content Completion ──────────── ✅ Hoàn tất
Track B: Branch Integration ──────────── ✅ Hoàn tất
Track C: Gameplay Decision — Undo X ──── ✅ Hoàn tất (RST-021: giữ Undo X cố định)
Track D: Asset Production ────────────── ⚠️ Tồn đọng (BGM OGG, Font, App Icon)
Track E: QA & Playtest ──────────────── ⚠️ Tồn đọng
Track F: Release Prep ───────────────── ⚠️ Tồn đọng
```

---

## Track D: Asset Production (tồn đọng)

Chi tiết: [REMAINING_TASKS](../../REMAINING_TASKS.md) mục Track D, [ASSET_BACKLOG_VISUAL](../../ASSET_BACKLOG_VISUAL.md), [ASSET_BACKLOG_AUDIO](../../ASSET_BACKLOG_AUDIO.md).

| # | Task | Trạng thái |
|---|------|------------|
| D1 | BGM OGG 48kHz | Tồn đọng — hiện dùng WAV thử nghiệm |
| D2 | Font tiếng Việt (Inter/Be Vietnam Pro) + font số HUD | Tồn đọng |
| D3 | App Icon 1024×1024 | Tồn đọng |

---

## Track E: QA & Playtest (tồn đọng)

| # | Task | Trạng thái |
|---|------|------------|
| E1 | QA gesture trên thiết bị Android | Tồn đọng |
| E2 | QA safe area / responsive layout | Tồn đọng |
| E3 | QA thẩm âm SFX/BGM | Tồn đọng |
| E4 | Playtest mù 30 levels | Tồn đọng |

---

## Track F: Release Prep (tồn đọng)

| # | Task | Trạng thái |
|---|------|------------|
| F1 | Encode banks XOR | Sẵn sàng chạy |
| F2 | Cấu hình Android export + keystore | Tồn đọng |
| F3 | Ẩn debug tools trong release build | Tồn đọng |
| F4 | Build APK/AAB + smoke test | Tồn đọng |

---

## Dependencies

```
D (assets) ──→ E (QA) ──→ F (release)
```

## Scope Guardrails

- N=4–12 đã hỗ trợ đầy đủ
- Campaign 30/100/998 + Endless mode đã có
- Không mở: IAP, ads, analytics, runtime generation
- Asset gốc: không sao chép từ reference hoặc game thương mại
