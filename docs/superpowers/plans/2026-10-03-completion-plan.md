# CanDoKu Completion Plan

> Ngày lập: 2026-10-03. Nền: `dev` HEAD + nhánh `fix/doubletap-x-preview` + `feat/gameplay-ui-realign`.

## Tổng quan

Dự án đã hoàn tất rebuild 10 modules, system upgrade 7 modules, và 4 last-mile tasks. Còn lại 6 track song song để đưa game về trạng thái playtest-ready.

## Track Map

```
Track A: Content Completion ──────────── (agent, ~2h)
Track B: Branch Integration ──────────── (agent, ~1h)  
Track C: Gameplay Decision — Undo X ──── (owner decision)
Track D: Asset Production ────────────── (manual/external)
Track E: QA & Playtest ──────────────── (manual + agent)
Track F: Release Prep ───────────────── (agent, sau E)
```

---

## Track A: Content Completion

**Mục tiêu:** Hoàn tất bank 6×6, validate toàn bộ content, commit.

**Nhánh:** `fix/doubletap-x-preview` (tiếp tục)

**Điều kiện tiên quyết:** Bank 6×6 generation hoàn tất (đang chạy nền).

| # | Task | Chi tiết | Gate |
|---|------|----------|------|
| A1 | Validate bank_6x6 | `python -B tools/validate_content.py game/data/banks/bank_6x6.json --pace game/data/banks/bank_6x6.pace.json` | VALID |
| A2 | Validate demo_cross với 3 banks | `python -B tools/validate_content.py game/data/campaigns/demo_cross.json --bank game/data/banks/bank_4x4.json --bank game/data/banks/bank_5x5.json --bank game/data/banks/bank_6x6.json` | VALID |
| A3 | Clean-room grep | `rg -n "(EventBus\|EventName\|GameState\|...)" game/scripts/` — 0 match | 0 match |
| A4 | Chạy Godot test suite | `godot --headless --path game --script res://tests/test_campaign_runtime.gd` (gồm `_test_dda_cross_size`) | PASS |
| A5 | Full verify gate | `python -B tools/verify.py --godot <executable>` | PASS |
| A6 | Commit content + tool changes | Stage: bank_6x6.json, bank_6x6.pace.json, demo_cross.json, validate_content.py, verify.py, campaign_runtime.gd, test_campaign_runtime.gd | Conventional commit |
| A7 | Cập nhật STATUS.md | Ghi nhận bank 6×6, demo_cross 45 levels, DDA cross-size | — |

**Output:** Commit trên `fix/doubletap-x-preview` với bank 6×6 + demo_cross + DDA cross-size wired.

---

## Track B: Branch Integration

**Mục tiêu:** Merge các nhánh feature/fix về `dev`.

**Điều kiện tiên quyết:** Track A hoàn tất; Track C có quyết định.

| # | Task | Chi tiết | Gate |
|---|------|----------|------|
| B1 | Merge `fix/doubletap-x-preview` → `dev` | 3 commits fix + content commits từ Track A. Fast-forward hoặc merge commit. | Full gate PASS trên dev |
| B2 | Resolve Undo X trên `feat/gameplay-ui-realign` | Theo quyết định Track C: giữ hoặc bỏ Undo X. Sửa code + test + docs. | Test PASS |
| B3 | Merge `feat/gameplay-ui-realign` → `dev` | Sau khi B2 xong và gate PASS. Có thể cần resolve conflicts với content mới. | Full gate PASS trên dev |
| B4 | Full gate trên `dev` sau merge | `python -B tools/verify.py --godot <executable>` | PASS |

**Lưu ý:** B2–B3 bị block bởi Track C (quyết định sản phẩm về Undo).

---

## Track C: Quyết định sản phẩm — Undo X

**Người quyết định:** Chủ dự án

**Bối cảnh:**
- RST-015 yêu cầu **bỏ Undo** (tham khảo không có undo)
- Nhánh `feat/gameplay-ui-realign` hiện **giữ Undo giới hạn** cho thao tác X
- Đây là chênh lệch code vs spec, cần quyết định rõ

**Lựa chọn:**

| Option | Ưu điểm | Nhược điểm |
|--------|---------|------------|
| **A: Bỏ Undo** (đúng RST-015) | Đúng spec, đơn giản hơn, ít code hơn | Có thể khó chơi hơn cho người mới |
| **B: Giữ Undo X giới hạn** | UX thân thiện hơn | Khác spec, cần cập nhật RST-015/DECISIONS |

**Action sau quyết định:** Ghi vào DECISIONS.md, sửa code nếu cần, chạy gate lại.

---

## Track D: Asset Production

**Mục tiêu:** Tạo/thu thập tất cả audio và visual assets cần thiết.

**Người thực hiện:** Sound designer / artist (bên ngoài agent)

**Tham chiếu:** `docs/ASSET_BACKLOG_AUDIO.md`, `docs/ASSET_BACKLOG_VISUAL.md`

### D1: Audio — Bắt buộc cho release (9 SFX + 1 BGM)

| Priority | File | Vai trò |
|----------|------|---------|
| **P0** | `main_theme.ogg` | BGM chủ đạo, 60-90s loop |
| **P0** | `mark.ogg` | Đánh/bỏ X |
| **P0** | `candy_found.ogg` | Đặt kẹo đúng |
| **P0** | `candy_wrong.ogg` | Đặt kẹo sai |
| **P0** | `hint.ogg` | Hiện gợi ý |
| **P0** | `win.ogg` | Giải xong level |
| **P0** | `fail.ogg` | Thua |
| **P0** | `tap.ogg` | Nhấn nút UI |
| **P0** | `enter.ogg` | Vào puzzle |
| **P0** | `restart.ogg` | Chơi lại |

**Spec:** OGG Vorbis 48kHz, mono 16-bit, -10 dBFS peak. Xem backlog cho chi tiết.

### D2: Visual — Bắt buộc cho release

| Priority | Asset | Ghi chú |
|----------|-------|---------|
| **P0** | Font chính (Inter/Nunito/Be Vietnam Pro) | Regular + Bold, Latin + Vietnamese |
| **P0** | Font số HUD | Monospace/tabular figures |
| **P0** | Logo CanDoKu gốc | Thay candy.svg tạm |
| **P0** | Bộ candy sprites (4-6 hình) | Phân biệt được khi colorblind |
| **P1** | App icon 1024×1024 | Cho export |
| **P1** | Splash screen | Boot splash |
| **P1** | Win/fail banners + stars | Result screen |
| **P1** | 9-patch dialog/button frames | UI polish |
| **P2** | Toast backgrounds | Feedback polish |
| **P2** | Custom switch controls | Options screen |

### D3: Tích hợp assets vào game (agent task)

| # | Task | Chi tiết |
|---|------|----------|
| D3.1 | Copy fonts vào `game/assets/fonts/`, tạo `.tres` | Sau khi D2 fonts sẵn sàng |
| D3.2 | Copy audio vào `game/audio/sfx/` và `game/audio/bgm/` | Sau khi D1 xong |
| D3.3 | Cập nhật theme resources nếu đổi font | `game/theme/` |
| D3.4 | Test audio playback — mọi event phát đúng | Headless + device |
| D3.5 | Test colorblind với candy sprites mới | `test_colorblind.gd` PASS |

---

## Track E: QA & Playtest

**Mục tiêu:** Kiểm chứng toàn bộ trải nghiệm trước khi release.

**Điều kiện tiên quyết:** Track A + B + D hoàn tất.

| # | Task | Người | Chi tiết |
|---|------|-------|----------|
| E1 | QA gesture trên thiết bị | Dev/QA | Single tap, double tap, swipe trên Android. Kiểm X preview, candy placement, error state |
| E2 | QA UI screens | Dev/QA | Title → Puzzle → Win → Next / Fail → Retry / Options. Kiểm layout, alignment, animation |
| E3 | QA colorblind mode | Dev/QA | Bật colorblind toggle, kiểm overlay trên tất cả sizes (4/5/6) |
| E4 | Playtest mù 30 levels 4×4 | Người chơi mục tiêu | Ghi feedback: độ khó, clarity, stuck points |
| E5 | Playtest 5×5 và 6×6 | Người chơi mục tiêu | Ghi feedback progression cross-size |
| E6 | DDA observation | Dev | Theo dõi rank_offset thay đổi tự nhiên qua 45 levels |
| E7 | Performance check | Dev | FPS ổn trên thiết bị Android tầm trung |
| E8 | Regression test | Agent | Full gate `tools/verify.py` trên `dev` sạch |

**Output:** Báo cáo QA + feedback playtest → quyết định có cần điều chỉnh trước release.

---

## Track F: Release Prep

**Mục tiêu:** Chuẩn bị export cho Android (và iOS nếu có signing).

**Điều kiện tiên quyết:** Track E hoàn tất, QA PASS.

| # | Task | Chi tiết |
|---|------|----------|
| F1 | Encode banks cho release | `python -B tools/encode_banks.py --input game/data/banks --output <export_dir>` |
| F2 | Cập nhật project.godot | App name, version, icon path |
| F3 | Cấu hình Android export | Keystore, package name, permissions |
| F4 | Build APK/AAB test | Export từ Godot, cài lên thiết bị |
| F5 | Smoke test trên APK | Chơi qua 5+ levels, kiểm save/resume/audio |
| F6 | Tắt MVP_ALLOW_CAMPAIGN_REPLAY | Nếu không còn cần replay cho test (RST-003) |
| F7 | iOS prep (nếu có) | Xcode project, signing, TestFlight |

---

## Thứ tự thực hiện đề xuất

```
Tuần 1:
  Track A (agent) ─── hoàn tất content ──┐
  Track C (owner) ─── quyết định Undo ───┤
  Track D1/D2 (external) ── assets ──────┤
                                         ▼
Tuần 2:
  Track B (agent) ─── merge branches ────┐
  Track D3 (agent) ── integrate assets ──┤
                                         ▼
Tuần 3:
  Track E (manual + agent) ── QA ────────┐
                                         ▼
Tuần 4:
  Track F (agent + manual) ── release ───┘
```

## Dependencies Graph

```
A ──→ B1 ──→ B4
C ──→ B2 ──→ B3 ──→ B4
D1/D2 ──→ D3 ──→ E
A + B4 + D3 ──→ E ──→ F
```

## Scope Guardrails

- **R1 only**: 30 levels/size, N=4-6, S1-S3
- **Không mở**: R2-R4, Endless, IAP, ads, analytics, runtime generation
- **Playtest ≠ release**: Đây là bản playtest trước phát hành (RST-011)
- **Asset gốc**: Không sao chép từ reference hoặc game thương mại
