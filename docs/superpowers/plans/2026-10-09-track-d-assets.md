# Track D Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn tất Track D — thay font heading bằng Be Vietnam Pro (hỗ trợ Vietnamese), tạo brief SFX studio cho 21 effects, và đề xuất concept + spec App Icon 1024×1024.

**Architecture:** 3 task độc lập. Task 1 thay file font + cập nhật font_tokens.gd + chạy Vietnamese test. Task 2 là tài liệu brief SFX (không code) để owner tạo audio. Task 3 là tài liệu concept + spec icon (không code). Task 2 & 3 chỉ tạo deliverable khi owner cung cấp file thực tế.

**Tech Stack:** Godot 4 / GDScript, Google Fonts (Be Vietnam Pro), OGG Vorbis 48kHz

**Spec:** `docs/STATUS.md` line 70 — Track D (Assets)

## Global Constraints

- Module ≤ 300 dòng
- Nguyên gốc hoàn toàn — không sao chép tên/asset thương mại
- Font phải pass Vietnamese test (`_test_all_support_vietnamese` trong `game/tests/test_font_tokens.gd`)
- Audio OGG Vorbis, 48kHz sample rate, mono, ≤ 200KB/file cho SFX, ≤ 5MB cho BGM
- App icon 1024×1024 PNG, RGBA, no rounded corners (platform tự bo)

## Review Focus

1. **Vietnamese diacritics rendering** — font mới phải render đúng tất cả tổ hợp dấu (ĂẮẦẪƠỜƯỪỮỰàáảãạ). Test `_test_all_support_vietnamese` phải PASS.
2. **Font file size** — Be Vietnam Pro Regular+Bold không nên > 500KB tổng để tránh ảnh hưởng load time mobile.
3. **SFX loudness consistency** — tất cả SFX file phải cùng normalized loudness (-14 LUFS ± 1dB) để không bị chênh khi play xen kẽ.
4. **Icon safe zone** — logo/biểu tượng chính phải nằm trong vùng safe 66% giữa (Android adaptive icon crop circle/squircle).
5. **Font cache invalidation** — static var `_heading`/`_heading_regular` giữ tham chiếu cũ nếu hot-reload; đây không phải vấn đề runtime nhưng cần lưu ý khi dev.

---

### Task 1: Thay Baloo2 bằng Be Vietnam Pro cho heading ✅ DONE

**Files:**
- Remove: `game/assets/fonts/Baloo2-Bold.ttf`, `game/assets/fonts/Baloo2-Regular.ttf`
- Add: `game/assets/fonts/BeVietnamPro-Bold.ttf`, `game/assets/fonts/BeVietnamPro-Regular.ttf`
- Modify: `game/scripts/theme/font_tokens.gd:10-16`
- Test: `game/tests/test_font_tokens.gd` (existing, no changes needed)

**Interfaces:**
- Consumes: Google Fonts — Be Vietnam Pro Regular 400, Bold 700
- Produces: `FontTokens.heading()` → Be Vietnam Pro Bold, `FontTokens.heading_regular()` → Be Vietnam Pro Regular

- [x] **Step 1: Download Be Vietnam Pro từ Google Fonts**

Tải 2 file từ https://fonts.google.com/specimen/Be+Vietnam+Pro:
- `BeVietnamPro-Regular.ttf` (weight 400)
- `BeVietnamPro-Bold.ttf` (weight 700)

Đặt vào `game/assets/fonts/`.

- [x] **Step 2: Xóa file Baloo2 cũ**

```bash
rm game/assets/fonts/Baloo2-Bold.ttf
rm game/assets/fonts/Baloo2-Regular.ttf
```

- [x] **Step 3: Cập nhật font_tokens.gd**

Sửa 2 dòng trong `game/scripts/theme/font_tokens.gd`:

```gdscript
# Line 11: đổi path heading
_heading = _load_font("res://assets/fonts/BeVietnamPro-Bold.ttf")

# Line 15: đổi path heading_regular
_heading_regular = _load_font("res://assets/fonts/BeVietnamPro-Regular.ttf")
```

- [ ] **Step 4: Chạy font test để verify Vietnamese support** ⏳ Cần Godot editor

```bash
rtk godot --headless --path game --script res://tests/test_font_tokens.gd
```

Expected: `FONT_TOKENS_PASS` — tất cả 5 token load thành công, Vietnamese chars (ĂẮẦẪƠỜƯỪỮỰàáảãạ) có mặt trong cả 5 font.

- [ ] **Step 5: Kiểm tra thủ công (nếu có Godot editor)** ⏳

Mở project, vào puzzle screen, kiểm tra heading text hiển thị đúng tiếng Việt có dấu. Đặc biệt kiểm tra:
- Title bar (tên level)
- Dialog headings
- Settings headings

- [ ] **Step 6: Commit**

```bash
git add game/assets/fonts/BeVietnamPro-Bold.ttf game/assets/fonts/BeVietnamPro-Regular.ttf
git add game/scripts/theme/font_tokens.gd
git rm game/assets/fonts/Baloo2-Bold.ttf game/assets/fonts/Baloo2-Regular.ttf
git commit -m "feat(theme): replace Baloo2 with Be Vietnam Pro for Vietnamese heading support"
```

---

### Task 2: SFX Audio Brief — Danh sách chi tiết 21 effects cần file OGG studio

**Files:**
- Create: `docs/briefs/sfx-audio-brief.md`

**Interfaces:**
- Consumes: `game/scripts/feedback/sfx_catalog.gd` — 21 Effect enum values
- Produces: tài liệu brief để owner/sound designer tạo file OGG

Đây là task tài liệu, không có code thay đổi. Khi owner cung cấp file OGG, sẽ cần task riêng để integrate vào `sfx_catalog.gd` và `sfx_player.gd`.

- [ ] **Step 1: Tạo brief document**

Tạo file `docs/briefs/sfx-audio-brief.md` với nội dung sau:

```markdown
# CanDoKu — SFX Audio Brief

> Tài liệu mô tả chi tiết 21 hiệu ứng âm thanh cần tạo file OGG studio
> để thay thế hệ thống procedural synth hiện tại.

## Thông số kỹ thuật chung

| Thông số | Giá trị |
|----------|---------|
| Format | OGG Vorbis |
| Sample rate | 48 kHz |
| Channels | Mono |
| Bit depth | 16-bit (trước khi encode OGG) |
| Loudness | -14 LUFS ± 1dB (normalized) |
| Max file size | 200 KB / file |
| Silence trim | Cắt silence đầu/cuối, giữ ≤ 20ms fade-out tự nhiên |

## Quy tắc đặt tên file

`sfx_<tên_effect>.ogg` — ví dụ: `sfx_mark.ogg`, `sfx_candy_yes.ogg`

Đặt tất cả trong: `game/assets/audio/sfx/`

---

## Danh sách 21 Effects

### Nhóm 1: Hành động trên bàn chơi (Gameplay Core)

#### 1. MARK — Đánh dấu X vào ô
- **Ngữ cảnh:** Player tap vào ô trống để đánh X, loại ô không có kẹo
- **Tần suất:** Rất cao — hàng chục lần/level, có thể liên tiếp nhanh (swipe)
- **Cảm xúc:** Nhẹ, sắc, tự tin — "tích" nhỏ gọn
- **Tham chiếu âm thanh:** Tiếng bút chì/bút bi tick nhẹ, hoặc soft click
- **Thời lượng:** 50–80ms
- **Lưu ý:** Cần pitch variation nhẹ (±5%) khi play liên tiếp để tránh monotone. File gốc ở pitch chuẩn, code sẽ random pitch runtime.

#### 2. UNMARK — Bỏ dấu X (bubble pop)
- **Ngữ cảnh:** Player tap vào ô đã đánh X để bỏ dấu
- **Tần suất:** Trung bình
- **Cảm xúc:** Nhẹ nhàng, hơi vui — "bong" nhỏ
- **Tham chiếu âm thanh:** Bubble pop nhẹ, hoặc soft "boop" ascending
- **Thời lượng:** 50–70ms
- **Lưu ý:** Pitch variation tương tự MARK

#### 3. CANDY_YES — Tìm đúng kẹo
- **Ngữ cảnh:** Player đặt kẹo đúng vị trí, xác nhận lời giải đúng cho ô đó
- **Tần suất:** Trung bình — vài lần/level
- **Cảm xúc:** Vui, khẳng định, thưởng — "ding" sáng
- **Tham chiếu âm thanh:** Chime ascending ngắn, xylophone tap, hoặc bell ting
- **Thời lượng:** 100–150ms
- **Lưu ý:** Pitch variation nhẹ. Phải rõ ràng khác biệt với MARK.

#### 4. CANDY_NO — Đặt sai kẹo
- **Ngữ cảnh:** Player thử đặt kẹo nhưng vị trí sai, hệ thống từ chối
- **Tần suất:** Thấp-trung bình
- **Cảm xúc:** Nhẹ nhàng phủ nhận, không khắc nghiệt — "không phải đây"
- **Tham chiếu âm thanh:** Buzz thấp mềm, dull thud, hoặc descending 2-note
- **Thời lượng:** 120–180ms
- **Lưu ý:** Không quá harsh — player sẽ nghe nhiều lần, không nên gây khó chịu

### Nhóm 2: Tiến trình và kết quả (Progress)

#### 5. STAGE_CLEAR — Thắng level 🎉
- **Ngữ cảnh:** Player hoàn thành level thành công
- **Tần suất:** 1 lần/level
- **Cảm xúc:** Phấn khích, thưởng lớn, thành tựu
- **Tham chiếu âm thanh:** Melody ascending 3–4 notes (C-E-G-C'), fanfare mini, hoặc sparkle cascade
- **Thời lượng:** 300–500ms
- **Lưu ý:** Đây là reward sound quan trọng nhất. Phải memorable và satisfying. Melody gợi ý: C5→E5→G5→C6 (triangle wave feel)

#### 6. STAGE_FAIL — Thua level
- **Ngữ cảnh:** Player hết mạng hoặc hết thời gian
- **Tần suất:** Thỉnh thoảng
- **Cảm xúc:** Thất vọng nhẹ nhàng, khuyến khích thử lại — không dramatic
- **Tham chiếu âm thanh:** Melody descending 3–4 notes (G-E-D-C), soft brass, hoặc muted trombone
- **Thời lượng:** 350–500ms
- **Lưu ý:** Melody gợi ý: G4→E4→D4→C4. Tốc độ hơi chậm hơn STAGE_CLEAR (0.9×)

#### 7. PROGRESS_COMPLETE — Đạt mốc tiến trình (halfway milestone)
- **Ngữ cảnh:** Player đạt 50% hoặc mốc đặc biệt trong level
- **Tần suất:** 0–1 lần/level
- **Cảm xúc:** Khích lệ nhẹ, momentum — "đang đúng đường"
- **Tham chiếu âm thanh:** Gentle ascending chime, softer & shorter hơn STAGE_CLEAR
- **Thời lượng:** 200–300ms

### Nhóm 3: UI Navigation

#### 8. BTN_PRESS — Nhấn nút UI chung
- **Ngữ cảnh:** Player tap bất kỳ button nào (Play, Menu items, etc.)
- **Tần suất:** Rất cao
- **Cảm xúc:** Xác nhận nhẹ, không gây chú ý — tactile feedback
- **Tham chiếu âm thanh:** Soft tick, subtle click, keyboard tap
- **Thời lượng:** 40–80ms
- **Lưu ý:** Rất nhẹ nhàng. Dùng chung cho 9 UI effects (xem bên dưới). Có thể tạo 1 file dùng chung, hoặc 1 file + variations.

#### 9. HINT_SHOW — Hiện gợi ý
- **Dùng chung file với:** BTN_PRESS (cùng UI tick sound)

#### 10. RESTART — Restart level
- **Dùng chung file với:** BTN_PRESS

#### 11. TAP_BACK — Back/Home navigation
- **Dùng chung file với:** BTN_PRESS

#### 12. TOGGLE_ON — Settings switch bật
- **Dùng chung file với:** BTN_PRESS

#### 13. TOGGLE_OFF — Settings switch tắt
- **Dùng chung file với:** BTN_PRESS

#### 14. DIALOG_OPEN — Mở confirmation/help dialog
- **Dùng chung file với:** BTN_PRESS

#### 15. DIALOG_CLOSE — Đóng dialog
- **Dùng chung file với:** BTN_PRESS

#### 16. UNDO_X — Undo thành công
- **Dùng chung file với:** BTN_PRESS

> **Lưu ý nhóm UI:** 9 effects trên (8–16) hiện dùng chung 1 preset procedural
> (UI_TICK). Có thể tạo 1 file `sfx_ui_tick.ogg` dùng chung, hoặc nếu muốn
> phong phú hơn, tạo 2–3 variations: `sfx_ui_tick.ogg` (mặc định),
> `sfx_ui_tick_back.ogg` (cho TAP_BACK, nhẹ hơn), `sfx_ui_tick_toggle.ogg`
> (cho TOGGLE_ON/OFF, có feedback rõ hơn).

#### 17. BOARD_OPEN — Mở board (vào level)
- **Ngữ cảnh:** Transition từ menu/campaign vào puzzle board
- **Tần suất:** 1 lần/level
- **Cảm xúc:** Mở ra, khám phá, sẵn sàng
- **Tham chiếu âm thanh:** Whoosh nhẹ ascending + chime cuối, unfold sound, page turn
- **Thời lượng:** 200–300ms

#### 18. SETTINGS_OPEN — Mở settings (whoosh)
- **Ngữ cảnh:** Player mở panel settings
- **Tần suất:** Thỉnh thoảng
- **Cảm xúc:** Trượt mở, không gian mới
- **Tham chiếu âm thanh:** Đã có file `settings-whoosh.ogg` — tạo version studio chất lượng cao hơn nếu cần, hoặc giữ nguyên file hiện tại
- **Thời lượng:** 200–400ms
- **Lưu ý:** File hiện tại (`game/assets/audio/sfx/settings-whoosh.ogg`) có thể giữ nếu đạt chất lượng. Chỉ thay khi cần nâng cấp.

### Nhóm 4: Hint Engine

#### 19. HINT_APPLY — Áp dụng gợi ý (positive chime)
- **Ngữ cảnh:** Player nhấn Apply trên hint overlay, hệ thống áp dụng bước giải
- **Tần suất:** Thấp — vài lần/level nếu dùng hint
- **Cảm xúc:** Xác nhận tích cực, "đã giúp xong"
- **Tham chiếu âm thanh:** Chime ascending nhẹ, magic sparkle ngắn, confirmation ding
- **Thời lượng:** 80–130ms
- **Lưu ý:** Nhẹ hơn CANDY_YES, vì đây là hint chứ không phải player tự tìm ra

#### 20. HINT_DISMISS — Đóng hint (soft close)
- **Ngữ cảnh:** Player đóng hint overlay mà không áp dụng
- **Tần suất:** Thấp
- **Cảm xúc:** Nhẹ nhàng đóng, trung lập
- **Tham chiếu âm thanh:** Soft descending note, gentle swoosh down, paper fold
- **Thời lượng:** 60–100ms

#### 21. HINT_WRONG_MARK — Phát hiện đánh sai (warning tone)
- **Ngữ cảnh:** Hint system phát hiện player đã đánh X sai vị trí
- **Tần suất:** Thấp
- **Cảm xúc:** Cảnh báo nhẹ, "hmm có gì sai" — nhẹ hơn CANDY_NO
- **Tham chiếu âm thanh:** 2-note descending, muted buzz, subtle alert
- **Thời lượng:** 100–160ms

### Nhóm 5: Hệ thống

#### 22. LOCK_TICK — System auto-mark tick
- **Ngữ cảnh:** Hệ thống tự động đánh X khi logic xác định chắc chắn (auto-eliminate)
- **Tần suất:** Nhiều — có thể hàng chục lần/level
- **Cảm xúc:** Rất nhẹ, nền, mechanical — player nghe nhưng không chú ý
- **Tham chiếu âm thanh:** Tiny tick, softer & lower pitch hơn MARK, typewriter micro-click
- **Thời lượng:** 40–60ms
- **Lưu ý:** Volume thấp nhất trong tất cả effects. Không nên gây phân tâm.

---

## Tóm tắt deliverables

| # | Tên file | Effect(s) | Ưu tiên |
|---|----------|-----------|---------|
| 1 | `sfx_mark.ogg` | MARK | Cao |
| 2 | `sfx_unmark.ogg` | UNMARK | Cao |
| 3 | `sfx_candy_yes.ogg` | CANDY_YES | Cao |
| 4 | `sfx_candy_no.ogg` | CANDY_NO | Cao |
| 5 | `sfx_stage_clear.ogg` | STAGE_CLEAR | Cao |
| 6 | `sfx_stage_fail.ogg` | STAGE_FAIL | Trung bình |
| 7 | `sfx_progress_complete.ogg` | PROGRESS_COMPLETE | Trung bình |
| 8 | `sfx_ui_tick.ogg` | BTN_PRESS + 8 shared | Cao |
| 9 | `sfx_board_open.ogg` | BOARD_OPEN | Trung bình |
| 10 | `sfx_settings_whoosh.ogg` | SETTINGS_OPEN | Thấp (có sẵn) |
| 11 | `sfx_hint_apply.ogg` | HINT_APPLY | Trung bình |
| 12 | `sfx_hint_dismiss.ogg` | HINT_DISMISS | Thấp |
| 13 | `sfx_hint_wrong_mark.ogg` | HINT_WRONG_MARK | Trung bình |
| 14 | `sfx_lock_tick.ogg` | LOCK_TICK | Thấp |

**Tổng: 14 file OGG** (21 effects, 9 UI dùng chung 1 file)

## Phong cách âm thanh tổng thể (Sound Direction)

- **Tone:** Vui vẻ, nhẹ nhàng, candy/casual — phù hợp puzzle game dành cho mọi lứa tuổi
- **Palette:** Chime, bell, xylophone, marimba, soft synth — tránh harsh/electronic
- **Consistency:** Tất cả effects phải nghe như cùng một "thế giới âm thanh"
- **Không dùng:** Tiếng người, tiếng động vật, âm thanh thực tế nặng (explosion, glass break)
```

- [ ] **Step 2: Commit**

```bash
git add docs/briefs/sfx-audio-brief.md
git commit -m "docs(audio): add SFX studio brief with 21 effect descriptions"
```

---

### Task 3: App Icon — Concept + Technical Spec

**Files:**
- Create: `docs/briefs/app-icon-brief.md`

**Interfaces:**
- Consumes: current `game/assets/candy/candy_icon.png` (512×512), brand identity
- Produces: tài liệu brief để owner/designer tạo icon

Đây là task tài liệu, không có code thay đổi. Khi owner cung cấp file icon, sẽ cần task riêng để integrate.

- [ ] **Step 1: Tạo icon brief document**

Tạo file `docs/briefs/app-icon-brief.md` với nội dung sau:

```markdown
# CanDoKu — App Icon Brief

> Concept và spec kỹ thuật cho app icon 1024×1024

## Thông tin sản phẩm

| Thông số | Giá trị |
|----------|---------|
| Tên app | CanDoKu |
| Thể loại | Puzzle / Candy Logic |
| Đối tượng | Mọi lứa tuổi, casual gamers |
| Tone | Vui vẻ, sáng sủa, đầy màu sắc |
| Package | `org.asol.game02` |

## Icon hiện tại

- File: `game/assets/candy/candy_icon.png`
- Kích thước: 512×512 RGBA
- Vai trò: placeholder, cần nâng cấp cho store listing

---

## Gợi ý concept (3 hướng)

### Concept A: "Candy Grid"
- **Mô tả:** Lưới 3×3 mini với các viên kẹo nhiều màu, một ô có dấu X nhỏ
- **Background:** Gradient pastel (hồng → cam nhạt)
- **Focal point:** Viên kẹo lớn ở giữa nổi bật, các ô xung quanh nhỏ hơn
- **Ưu điểm:** Truyền tải trực tiếp gameplay (grid + candy + logic)
- **Phong cách:** Flat design với subtle shadow, rounded corners trên từng ô

### Concept B: "Single Candy Hero"
- **Mô tả:** Một viên kẹo lớn, cách điệu, chiếm phần lớn icon
- **Background:** Solid color tươi sáng (tím hoặc xanh dương đậm)
- **Focal point:** Viên kẹo với expression vui vẻ hoặc sparkle effect
- **Ưu điểm:** Đơn giản, nhận diện ngay, hiển thị tốt ở mọi kích thước
- **Phong cách:** 3D-ish với gradient và highlight, hoặc flat bold

### Concept C: "Logic Candy"
- **Mô tả:** Chữ "C" cách điệu từ viên kẹo, kết hợp grid pattern làm nền
- **Background:** Gradient đa sắc (warm tones: vàng → cam → hồng)
- **Focal point:** Letterform "C" dạng candy
- **Ưu điểm:** Kết hợp brand name + game theme, unique
- **Phong cách:** Modern flat với depth, clean lines

---

## Spec kỹ thuật

### File gốc (Master)

| Thông số | Giá trị |
|----------|---------|
| Kích thước | 1024 × 1024 px |
| Format | PNG |
| Color mode | RGBA (32-bit) |
| Background | Opaque (không transparent) |
| Corners | Vuông góc — KHÔNG bo góc (platform tự bo) |
| Safe zone | Nội dung quan trọng trong vùng 66% giữa (680×680px centered) |

### Tại sao cần Safe Zone 66%?

Android Adaptive Icon có thể crop icon thành các hình dạng khác nhau
(circle, squircle, rounded square, teardrop). Chỉ vùng trung tâm 66%
được đảm bảo hiển thị trên mọi thiết bị.

```
+---------------------------+  1024×1024
|                           |
|     +-----------------+   |
|     |                 |   |
|     |   SAFE ZONE     |   |
|     |   680×680       |   |
|     |   (66%)         |   |
|     |                 |   |
|     +-----------------+   |
|                           |
+---------------------------+
```

### Các kích thước cần xuất

#### Android (bắt buộc)

| Tên | Kích thước | Dùng cho |
|-----|-----------|----------|
| `icon_48.png` | 48×48 | mdpi launcher |
| `icon_72.png` | 72×72 | hdpi launcher |
| `icon_96.png` | 96×96 | xhdpi launcher |
| `icon_144.png` | 144×144 | xxhdpi launcher |
| `icon_192.png` | 192×192 | xxxhdpi launcher |
| `icon_512.png` | 512×512 | Google Play listing |
| `icon_1024.png` | 1024×1024 | Hi-res (Godot default) |

#### Android Adaptive Icon (nếu dùng Gradle build)

| Tên | Kích thước | Dùng cho |
|-----|-----------|----------|
| `icon_foreground.png` | 432×432 | Foreground layer (nội dung) |
| `icon_background.png` | 432×432 | Background layer (solid color/gradient) |

#### Store Listing

| Tên | Kích thước | Dùng cho |
|-----|-----------|----------|
| `feature_graphic.png` | 1024×500 | Google Play feature graphic |
| `icon_1024.png` | 1024×1024 | Reuse cho store |

### Tích hợp vào Godot

Sau khi có icon 1024×1024, đặt tại:
```
game/assets/icons/app_icon.png
```

Cập nhật `game/project.godot`:
```
config/icon="res://assets/icons/app_icon.png"
```

Cập nhật `game/export_presets.cfg` nếu cần icon path riêng cho Android.

### Palette gợi ý (dựa trên candy theme hiện tại)

| Vai trò | Hex | Mô tả |
|---------|-----|-------|
| Primary | #FF6B9D | Hồng candy |
| Secondary | #FFB347 | Cam pastel |
| Accent | #7EC8E3 | Xanh dương nhạt |
| Dark | #2D1B4E | Tím đậm (background option) |
| Light | #FFF5E6 | Kem nhạt (background option) |

> Palette chỉ là gợi ý — designer tự do chọn màu phù hợp với brand.

### Checklist trước khi nộp

- [ ] File 1024×1024 PNG, RGBA
- [ ] Không bo góc (corners vuông)
- [ ] Nội dung chính trong safe zone 66%
- [ ] Đọc được ở 48×48 (test bằng cách thu nhỏ)
- [ ] Không chứa text nhỏ (unreadable ở small sizes)
- [ ] Contrast đủ trên cả nền sáng và tối
- [ ] Không sử dụng logo/nhân vật/tài sản thương mại của game khác
```

- [ ] **Step 2: Commit**

```bash
git add docs/briefs/app-icon-brief.md
git commit -m "docs(assets): add app icon concept and technical spec brief"
```

---

### Task 4 (sau khi nhận file): Integrate SFX OGG files

> **Task này chỉ thực hiện khi owner cung cấp đủ file OGG.**

**Files:**
- Add: `game/assets/audio/sfx/sfx_*.ogg` (14 files)
- Modify: `game/scripts/feedback/sfx_catalog.gd` — chuyển tất cả PRESETS sang `{"type": "file", "path": "res://..."}` format
- Modify: `game/scripts/feedback/sfx_player.gd` — đảm bảo file-based loading hoạt động cho tất cả effects
- Test: chạy game, nghe từng effect

**Interfaces:**
- Consumes: 14 file OGG từ brief Task 2
- Produces: `sfx_catalog.gd` với tất cả effects load từ file thay vì procedural

- [ ] **Step 1: Đặt file OGG vào đúng thư mục**

Copy 14 file vào `game/assets/audio/sfx/`. Verify tên file đúng theo brief.

- [ ] **Step 2: Cập nhật sfx_catalog.gd — chuyển PRESETS sang file-based**

Với mỗi effect trong `PRESETS`, thay preset dictionary bằng format file:

```gdscript
Effect.MARK: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_mark.ogg", "speed": 1.0,
},
Effect.UNMARK: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_unmark.ogg", "speed": 1.0,
},
Effect.CANDY_YES: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_candy_yes.ogg", "speed": 1.0,
},
Effect.CANDY_NO: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_candy_no.ogg", "speed": 1.0,
},
Effect.HINT_SHOW: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.BTN_PRESS: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.BOARD_OPEN: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_board_open.ogg", "speed": 1.0,
},
Effect.RESTART: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.TAP_BACK: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.TOGGLE_ON: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.TOGGLE_OFF: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.DIALOG_OPEN: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.DIALOG_CLOSE: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.UNDO_X: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_ui_tick.ogg", "speed": 1.0,
},
Effect.SETTINGS_OPEN: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_settings_whoosh.ogg", "speed": 1.0,
},
Effect.PROGRESS_COMPLETE: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_progress_complete.ogg", "speed": 1.0,
},
Effect.LOCK_TICK: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_lock_tick.ogg", "speed": 1.0,
},
Effect.HINT_APPLY: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_hint_apply.ogg", "speed": 1.0,
},
Effect.HINT_DISMISS: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_hint_dismiss.ogg", "speed": 1.0,
},
Effect.HINT_WRONG_MARK: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_hint_wrong_mark.ogg", "speed": 1.0,
},
```

- [ ] **Step 3: Cập nhật MELODY_PRESETS sang file-based**

```gdscript
Effect.STAGE_CLEAR: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_stage_clear.ogg", "speed": 1.0,
},
Effect.STAGE_FAIL: {
    "type": "file", "path": "res://assets/audio/sfx/sfx_stage_fail.ogg", "speed": 1.0,
},
```

Di chuyển STAGE_CLEAR và STAGE_FAIL từ `MELODY_PRESETS` sang `PRESETS`. Xóa `MELODY_PRESETS` nếu rỗng.

- [ ] **Step 4: Cập nhật PENCIL_PRESETS**

Xóa `PENCIL_PRESETS` — MARK giờ dùng file-based. Xóa `SHARED_UI_EFFECTS` constant vì mỗi effect giờ có path riêng (dù nhiều cái trỏ cùng file).

- [ ] **Step 5: Simplify sfx_player.gd**

Trong `_ready()`, simplify loading logic — tất cả effects giờ đều là file-based:

```gdscript
for effect in SfxCatalog.Effect.values():
    if SfxCatalog.PRESETS.has(effect):
        var preset: Dictionary = SfxCatalog.PRESETS[effect]
        _streams[effect] = load(str(preset.path))
```

Xóa các nhánh `SHARED_UI_EFFECTS`, `PENCIL_PRESETS`, `MELODY_PRESETS`, `PcmSynth.generate()`.

- [ ] **Step 6: Giữ lại PITCH_RANDOMIZE và MIN_INTERVAL_MS**

Các constant này vẫn cần thiết cho runtime pitch variation và rate limiting. Không xóa.

- [ ] **Step 7: Test thủ công**

Chạy game, trigger từng effect:
- Tap ô trống → MARK
- Tap ô đã X → UNMARK
- Đặt kẹo đúng → CANDY_YES
- Đặt kẹo sai → CANDY_NO
- Thắng level → STAGE_CLEAR
- Mở settings → SETTINGS_OPEN
- Nhấn các button → BTN_PRESS
- Dùng hint → HINT_APPLY, HINT_DISMISS

- [ ] **Step 8: Commit**

```bash
git add game/assets/audio/sfx/sfx_*.ogg
git add game/scripts/feedback/sfx_catalog.gd game/scripts/feedback/sfx_player.gd
git commit -m "feat(audio): replace procedural SFX with studio OGG files (21 effects)"
```

---

### Task 5 (sau khi nhận file): Integrate App Icon

> **Task này chỉ thực hiện khi owner cung cấp file icon 1024×1024.**

**Files:**
- Add: `game/assets/icons/app_icon.png`
- Modify: `game/project.godot` — line `config/icon`
- Possibly remove: `game/assets/candy/candy_icon.png` (nếu không dùng elsewhere)

- [ ] **Step 1: Đặt file icon**

Copy `app_icon.png` (1024×1024) vào `game/assets/icons/`.

```bash
mkdir -p game/assets/icons
cp <source>/app_icon.png game/assets/icons/app_icon.png
```

- [ ] **Step 2: Verify kích thước**

```bash
python -c "from PIL import Image; img = Image.open('game/assets/icons/app_icon.png'); assert img.size == (1024, 1024), f'Wrong size: {img.size}'; print('OK: 1024x1024')"
```

- [ ] **Step 3: Cập nhật project.godot**

Sửa `game/project.godot` line 20:

```ini
config/icon="res://assets/icons/app_icon.png"
```

- [ ] **Step 4: Kiểm tra candy_icon.png còn dùng ở đâu không**

```bash
rg -n "candy_icon" game/
```

Nếu chỉ dùng trong `project.godot` (đã đổi), có thể giữ hoặc xóa file cũ.

- [ ] **Step 5: Commit**

```bash
git add game/assets/icons/app_icon.png game/project.godot
git commit -m "feat(assets): add 1024x1024 app icon for store submission"
```
