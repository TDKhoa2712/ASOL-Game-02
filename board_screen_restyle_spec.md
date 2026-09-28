# SPEC: Restyle màn chơi `BoardScreen` (Mèo Logic – "VƯỜN MÈO")

> **Loại việc:** chỉ đổi giao diện (UI/visual). **KHÔNG đổi luật chơi, logic sinh màn, logic kiểm tra thắng/thua.**
> **Độ giống reference:** ~80–90% là đủ. Assets (icon mèo, icon nút, cá/tim…) sẽ được chủ dự án thay sau → dùng **placeholder** và đặt tên/đường dẫn dễ thay (mục 9).
> **Engine:** Godot 4.x (`format=3`), portrait.

---

## 0. Đọc trước khi làm

| File | Vai trò |
|---|---|
| `scenes/board.tscn` | Scene chỉ có **1 node root `BoardScreen` (Control, full rect) + script `res://scripts/board_screen.gd`**. Toàn bộ UI hiện tại được **dựng bằng code trong `board_screen.gd`**. |
| `scripts/board_screen.gd` | **File chính cần sửa.** Đọc kỹ toàn bộ trước khi sửa: tìm hàm dựng UI, hàm xử lý input (tap / double-tap / drag), hàm cập nhật lượt sai, hàm undo/hint/restart. |
| `pastel_backdrop.gd` (nếu có) | Nền trang trí hiện tại (các khối bo tròn ở mép màn hình). |
| Ảnh **REF** (game tham chiếu) | Giao diện đích. |
| Ảnh **CUR** (game hiện tại) | Giao diện cần thay đổi. |

**Quy tắc bảo toàn:** giữ nguyên tên hàm/signal/biến công khai mà scene khác hoặc logic đang gọi. Nếu buộc phải đổi tên → ghi vào phần "Ghi chú bàn giao" cuối file.

---

## 1. Phân tích nhanh: REF vs CUR

### REF (đích) – bố cục từ trên xuống
1. **Top bar:** nút Back tròn trắng (trái) · 2 chỉ số ở giữa ("Màn 116", "Điểm 0": nhãn nhỏ + số to đậm) · nút Settings (bánh răng) tròn trắng (phải).
2. **Hàng trạng thái:** pill trắng bo tròn dài chứa **N icon đầu mèo, mỗi icon 1 màu = 1 vùng** (tiến độ theo vùng) + pill trắng nhỏ bên phải chứa **3 icon** (dạng bánh cá vàng – hiểu là số lượt/mạng còn lại).
3. **Card luật chơi:** 1 card trắng bo góc lớn, bên trong 3 ô luật nằm ngang; mỗi ô = **icon lưới 3×3 minh hoạ + chữ**.
4. **Bảng chơi:** card trắng **gần full chiều ngang**, bên trong lưới N×N (10×10), **ô bo góc, có khe hở, tô màu phẳng theo vùng, KHÔNG có viền đậm phân vùng**.
5. **Thanh công cụ dưới:** 3 nút tròn trắng lớn, có shadow mềm, mỗi nút có **badge tròn ở góc trên phải** (số lượng màu đỏ / badge xanh có icon ▶ = xem quảng cáo để nhận).
6. Nền: **kem phẳng**, không hoa văn. (Banner quảng cáo dưới cùng của REF: **bỏ qua**.)

### CUR (hiện tại) – khác biệt chính
| Hạng mục | CUR | Cần chuyển thành |
|---|---|---|
| Header | Card lớn chứa tiêu đề "VƯỜN MÈO", phụ đề, "Lượt sai còn lại 3/3", "Sẵn sàng" | Top bar kiểu REF (Back · chỉ số · Settings) |
| Tiến độ vùng | Chip chữ A/B/C/D dạng radio bên dưới bảng | Pill icon đầu mèo màu theo vùng, **phía trên** bảng |
| Lượt sai | Chữ đỏ "Lượt sai còn lại: 3 / 3" | 3 icon trong pill nhỏ bên phải (mờ đi khi mất lượt) |
| Luật | Lưới chữ 2×2 với ký hiệu ↔ ↕ ▧ ◇ | Card luật, mỗi luật có **icon 3×3 + chữ** |
| Bảng | Nhỏ, có **viền navy đậm** giữa các vùng, chữ A/B/C/D trong ô, hiệu ứng "kính" (chấm + gạch chéo) | To gần full ngang, ô bo góc + khe hở, màu phẳng, bỏ viền đậm |
| Nút dưới | 6 nút chữ chữ nhật (Hoàn tác, Gợi ý, Chơi lại, Về Home, Trợ giúp, Cài đặt) | 3 nút tròn icon có badge; Home/Settings chuyển lên top bar; Trợ giúp → mục 6.4 |
| Dòng hướng dẫn cử chỉ | "Chạm: đánh / xóa X · Chạm đôi: thử đặt mèo · Kéo: đánh dấu nhiều ô" | Bỏ khỏi màn chính, đưa vào popup Trợ giúp (mục 6.4) |
| Nền | Kem + các khối bo tròn ở mép | Kem phẳng (backdrop để mờ ≤10% hoặc tắt) |

---

## 2. Layout tổng (portrait)

Thiết kế theo **tỉ lệ % chiều rộng màn hình (W)** để chạy được mọi độ phân giải. Giá trị px bên cạnh quy đổi cho **W = 540** (kích thước cửa sổ hiện tại của game).

Cấu trúc node đề xuất (dựng bằng code, thay cho các panel cũ):

```
BoardScreen (Control, full rect)
├─ Background (ColorRect, full rect, màu BG)            ← + backdrop cũ nếu giữ (opacity thấp)
└─ Safe (MarginContainer, full rect, margin trái/phải = 3.5% W, top = safe-area + 2% W, bottom = safe-area + 3% W)
   └─ Root (VBoxContainer, separation ≈ 3% W)
      ├─ TopBar          (HBoxContainer)
      ├─ StatusRow       (HBoxContainer)    ← progress pill + lives pill
      ├─ RulesCard       (PanelContainer)
      ├─ BoardArea       (Control, size_flags_vertical = EXPAND_FILL)
      │   └─ BoardCard   (PanelContainer, vuông, canh giữa theo cả 2 chiều)
      │       └─ Grid    (GridContainer / hoặc Control tự đặt vị trí ô)
      └─ BottomBar       (HBoxContainer, canh giữa, separation ≈ 9% W)
```

Nguyên tắc:
- **BoardArea chiếm hết khoảng trống còn lại**; `BoardCard` là hình vuông có cạnh = `min(rộng BoardArea, cao BoardArea)`, canh giữa. Bảng luôn to nhất có thể (màn 4×4 cũng phải to gần full ngang, không còn nhỏ như CUR).
- Mọi kích thước ô tính động: `cell = (board_inner − gap*(N−1)) / N` với N = 4…10.
- Màn hình cao hơn 9:16 (REF là ~9:20): khoảng trống dư nằm giữa các khối, không kéo giãn các thành phần.
- Tôn trọng safe-area (`DisplayServer.get_display_safe_area()`).

---

## 3. Design tokens (đặt thành hằng số/`Theme` MỘT chỗ, không hard-code rải rác)

Màu **xấp xỉ** lấy từ ảnh REF; chỉnh nhẹ được.

### 3.1 Màu giao diện
| Token | Hex | Dùng cho |
|---|---|---|
| `BG` | `#F8F1EC` | Nền màn hình |
| `CARD` | `#FFFFFF` | Card, pill, nút tròn |
| `TILE` | `#FAF3EE` | Nền ô luật bên trong card luật |
| `TEXT_STAT` | `#9B5A52` | Nhãn/số ở top bar (nâu-hồng đất) |
| `TEXT_RULE` | `#A0655C` | Chữ luật chơi |
| `ICON_BROWN` | `#9B5A52` | Icon Back/Settings, viền ô X trong icon luật |
| `RULE_CELL_EMPTY` | `#E0BFAA` | Ô trống trong icon 3×3 |
| `BADGE_COUNT` | `#E53935` | Badge số lượng (chữ trắng đậm) |
| `BADGE_AD` | `#12B84B` | Badge quảng cáo/video (icon ▶ trắng) |
| `SHADOW` | `#8B5A4A` @ alpha 0.18 | Shadow mềm cho nút tròn/card |

### 3.2 Bảng màu 10 vùng (thứ tự dùng cho vùng 0…9)
| # | Tên | Hex (board) | Hex icon mèo ở pill tiến độ (≈ pha trắng 45%) |
|---|---|---|---|
| 0 | Xanh lá nhạt | `#8BD87B` | `#C6EBC0` |
| 1 | Tím | `#8B7BD8` | `#C5B9E8` |
| 2 | Vàng đậm | `#CDA800` | `#E3CF7C` |
| 3 | Vàng kem | `#F9D882` | `#FCEFC9` |
| 4 | Hồng | `#F59DE0` | `#F8CCF0` |
| 5 | Hồng đất | `#D17190` | `#E8B4CB` |
| 6 | Cam | `#F79C5D` | `#FAD4B5` |
| 7 | Nâu | `#AB6F4B` | `#D4B5A0` |
| 8 | Xanh lá đậm | `#2B9155` | `#95C4A9` |
| 9 | Xanh lơ | `#37A9C6` | `#9DD5DE` |

- Màn có ít vùng (vd 4×4 → 4 vùng) thì **dùng 4 màu đầu tiên trong danh sách này** (hoặc bộ 4 màu tương phản nhất: 0, 1, 6, 9). Ưu tiên **các màu cạnh nhau khác biệt rõ**.
- Icon ở pill tiến độ = `region_color.lerp(Color.WHITE, 0.45)` (tự sinh, không cần hard-code cột cuối).

### 3.3 Kích thước & bo góc
| Thành phần | % W | px @540 | Bo góc |
|---|---|---|---|
| Lề trái/phải toàn màn | 3.5% | ~18 | – |
| Nút tròn Back/Settings | 9% | ~49 | tròn |
| Pill hàng trạng thái (cao) | 7.6% | ~41 | full (radius = cao/2) |
| Icon đầu mèo trong pill | ~5.5% | ~30 | – |
| Card luật (cao) | ~14.5% | ~78 | ~20 px |
| Ô luật (tile) | – | – | ~14 px |
| Card bảng | tối đa ≈ 97% | tối đa ≈ 524 | ~22 px |
| Padding trong card bảng | 1.6% | ~9 | – |
| **Khe hở giữa ô (gap)** | 0.8% | **~4** | – |
| **Bo góc ô** | ≈ 14% cạnh ô | ~6–8 | – |
| Nút tròn dưới | 14.8% | ~80 | tròn |
| Badge tròn | 6.5% | ~35 | tròn, chồng lên góc trên-phải nút ~ 30% |

Shadow: `StyleBoxFlat.shadow_size = 8`, `shadow_offset = (0, 3)`, màu `SHADOW` — dùng cho nút tròn và card. Không viền (border) cho card.

### 3.4 Font
- Dùng font hiện có của dự án. Nhãn "Màn/Điểm": cỡ ≈ 3.8% W (~20px), màu `TEXT_STAT`, đậm vừa. Số: ≈ 7% W (~38px), **Bold**.
- Chữ luật: ≈ 3.2% W (~17px), tối đa 2 dòng, `autowrap`.
- Bắt buộc hiển thị đúng tiếng Việt có dấu.

---

## 4. Chi tiết từng khối

### 4.1 TopBar
`[BackButton] ─ spacer ─ [Stat "Màn"] [Stat "Điểm"] ─ spacer ─ [SettingsButton]`
- Nút tròn trắng có shadow; icon: mũi tên trái / bánh răng, màu `ICON_BROWN`.
- **Back = thay nút "Về Home"** (giữ nguyên hành vi cũ, gọi đúng hàm điều hướng đang dùng).
- **Settings = thay nút "Cài đặt"** (mở đúng popup/scene cũ).
- Stat: 2 dòng (nhãn nhỏ trên, số to dưới), canh giữa. Cột 1: **Màn** → giá trị hiện có, vd `L01`/`1`. Cột 2: **Điểm** → chỉ hiện **nếu game đã có hệ thống điểm**. Nếu chưa có: **ẩn cột này** và canh giữa cột "Màn" (không tự bịa hệ thống điểm mới).
- Bỏ tiêu đề "VƯỜN MÈO" và chữ phụ đề "tìm một mèo trong mỗi vùng" khỏi màn này (luật đã có ở card luật).
- Bỏ chữ "Sẵn sàng"; nếu cần báo trạng thái (thắng/thua/gợi ý) → dùng toast nổi ngắn phía trên bảng (mục 7).

### 4.2 StatusRow
**a) Pill tiến độ vùng (trái, chiếm phần lớn chiều ngang):**
- Pill trắng bo full; bên trong HBox chứa **đúng N icon đầu mèo = số vùng của màn hiện tại**, khoảng cách đều, canh giữa; icon tự co để vừa pill (N từ 4 đến 10).
- Icon i tô màu tint của vùng i (mục 3.2).
- Trạng thái (REF chỉ thấy trạng thái ban đầu, phần sau là **quyết định thiết kế**):
  - *Chưa có mèo trong vùng*: màu tint đầy đủ, alpha 0.55.
  - *Đã đặt mèo hợp lệ trong vùng*: alpha 1.0 + dấu ✓ nhỏ trắng ở góc icon, tween scale 1.0→1.2→1.0 (0.2s).
- Có thể **thay** cho chip chữ A/B/C/D cũ. Nếu người chơi cần biết chữ vùng (hỗ trợ mù màu) → giữ chữ nhỏ trong ô, xem mục 4.4.

**b) Pill lượt sai (phải, rộng vừa đủ 3 icon):**
- Số icon = **số lượt sai tối đa** hiện có (đang là 3). Placeholder: icon bánh cá/trái tim/dấu chân mèo.
- Mất 1 lượt: icon tương ứng chuyển xám nhạt (alpha 0.25) + rung nhẹ.
- **Bỏ chữ** "Lượt sai còn lại: 3 / 3" (thông tin chuyển sang icon). Nếu số lượt tối đa > 5 thì hiển thị dạng `♥ ×n` thay vì nhiều icon.
- *Giả định:* icon cá ở REF là mạng/lượt. Nếu chủ dự án muốn nghĩa khác → chỉ đổi nguồn dữ liệu, giữ layout.

### 4.3 RulesCard
- 1 card trắng bo ~20px, padding ~2% W, bên trong các ô luật (`TILE`, bo ~14px).
- CUR có **4 luật** (REF có 3) → dùng lưới **2×2** (mỗi ô luật chiếm ½ chiều ngang) để chữ không bị nhỏ. Nếu chủ dự án sau này rút còn 3 luật thì đổi sang 1×3 như REF.
- Mỗi ô luật: `HBox [Icon 3×3] [Label]`. Icon rộng ≈ 9% W; label autowrap.
- Icon 3×3 vẽ bằng 9 ô vuông nhỏ bo góc (`Panel`/`draw_rect`), 3 loại ô: `.` ô trống (`RULE_CELL_EMPTY`), `X` ô có dấu ✕ trắng trên nền `ICON_BROWN`, `C` ô có icon mèo nhỏ. Mẫu:

| Luật (giữ nguyên chữ hiện tại) | Mẫu 3×3 (hàng 1→3) |
|---|---|
| 1 mèo mỗi hàng | `... / XCX / ...` |
| 1 mèo mỗi cột | `.X. / .C. / .X.` |
| 1 mèo mỗi vùng | `XXX / XC. / X..` (như luật "mỗi màu" ở REF) |
| Mèo không chạm góc | `XXX / XCX / XXX` (như luật "không chạm nhau" ở REF) |

- Thay các ký tự `↔ ↕ ▧ ◇` bằng icon 3×3 ở trên.
- Icon mèo nhỏ dùng chung texture `cat_face_small` (mục 9); nếu chưa có → ký tự/emoji 🐱 hoặc hình tròn + 2 tam giác vẽ bằng code.

### 4.4 Board (quan trọng nhất)
- **Card:** trắng, bo ~22px, shadow rất nhẹ, vuông, canh giữa trong BoardArea.
- **Ô:**
  - Hình vuông bo góc ≈ 14% cạnh, **gap ≈ 0.8% W** giữa các ô, **màu phẳng theo vùng** (mục 3.2).
  - **Bỏ hoàn toàn viền navy đậm giữa các vùng** và **bỏ hiệu ứng "kính"** (chấm sáng + gạch chéo) ở từng ô.
  - Vùng vẫn nhận ra nhờ màu; các ô cùng vùng vẫn tách khe như REF.
- **Chữ cái vùng (A/B/C/D):** mặc định **ẩn**. Thêm hằng số/tuỳ chọn `SHOW_REGION_LETTERS` (mặc định `false`, có thể bật trong Settings sau này) để hỗ trợ người khó phân biệt màu; khi bật: chữ nhỏ, góc dưới-trái ô, alpha 0.5, màu trắng/đen tự chọn theo độ sáng nền.
- **Trạng thái ô** (giữ nguyên logic, chỉ đổi cách vẽ):
  | Trạng thái | Cách vẽ |
  |---|---|
  | Trống | Chỉ màu vùng |
  | Đánh dấu X | Dấu ✕ trắng, alpha ~0.8, dày, canh giữa ô (~45% cạnh ô) |
  | Có mèo | Icon mèo (mặt đen-trắng, ~70% cạnh ô) canh giữa; animation "pop" scale 0→1.1→1.0 (0.15s) |
  | Ô đặt sai / vi phạm | Flash viền đỏ `#E53935` 0.3s + rung ngang nhẹ (±3px, 0.2s) |
  | Được gợi ý (Hint) | Viền trắng dày + nhấp nháy alpha 2 lần |
  | Ô bị khoá/kết thúc | Không đổi giao diện, chỉ chặn input |
- **Input giữ nguyên hoàn toàn:** chạm = đánh/xoá X · chạm đôi = thử đặt mèo · kéo = đánh dấu nhiều ô. Chú ý: khi đổi kích thước/khe hở, **hit-test phải tính đúng theo vị trí ô mới** (kéo ngang khe hở vẫn phải nhận ô liền kề gần nhất).
- Ô rất nhỏ (N=10 trên màn 540): cạnh ô ≈ 46px — vẫn ≥ 44px chạm tốt; không được nhỏ hơn.

### 4.5 BottomBar – 3 nút tròn
Nút tròn trắng ~14.8% W, shadow mềm, icon ở giữa, badge góc trên-phải.

| Vị trí | Chức năng (map từ nút cũ) | Icon placeholder | Badge |
|---|---|---|---|
| Trái | **Hoàn tác** (Undo) | mũi tên quay lại ↶ | Không, hoặc số bước có thể hoàn tác nếu logic có sẵn |
| Giữa | **Gợi ý** (Hint) | bóng đèn 💡 | Nếu game có số lượt gợi ý → badge đỏ có số; nếu hết và có quảng cáo → badge xanh ▶. Nếu chưa có kinh tế gợi ý: **không hiện badge** |
| Phải | **Chơi lại** (Restart) | mũi tên xoay ↻ | Không |

- Trạng thái **disabled** (vd Hoàn tác khi chưa có bước nào): alpha 0.4, không nhận input.
- Press feedback: scale 0.94 trong 0.08s rồi trả về.
- Nút thứ 3 ở REF (chuột, badge "1") là một power-up riêng của game đó → **không tạo tính năng mới**; nếu sau này có power-up thứ 4 thì thêm cùng kiểu (mở rộng BottomBar, không đổi style).
- **Nút "Chơi lại":** nếu logic cũ có xác nhận thì giữ xác nhận.

### 4.6 Trợ giúp (thay cho nút "Trợ giúp" + dòng hướng dẫn cử chỉ)
- Thêm nút nhỏ **"?"** (tròn ~7% W, kiểu giống Back/Settings) ở **góc phải card luật** hoặc trong TopBar bên cạnh Settings.
- Bấm mở **đúng popup Trợ giúp hiện có**; thêm vào nội dung popup 3 dòng cử chỉ (chữ giữ nguyên như CUR): *Chạm: đánh / xóa X · Chạm đôi: thử đặt mèo · Kéo: đánh dấu nhiều ô*.
- Nếu popup Trợ giúp chưa tồn tại dưới dạng tái sử dụng được → tạo popup đơn giản (card trắng bo góc, tiêu đề, 3 dòng, nút Đóng).

---

## 5. Nền
- `ColorRect` phẳng màu `BG`.
- Các khối trang trí bo tròn ở mép (CUR): tắt, hoặc để alpha ≤ 0.10 và **không được che UI / không nhận input**.

---

## 6. Trạng thái toàn màn hình
- **Thắng / Thua / Hết lượt:** giữ nguyên popup hiện có; nếu popup dùng style cũ (navy/đậm) → đổi sang card trắng bo góc + nút bo tròn theo tokens mục 3 (ưu tiên thấp, làm sau cùng).
- **Toast** ngắn (vd khi hint/không thể hoàn tác): pill trắng, chữ `TEXT_STAT`, hiện 1.2s phía trên card bảng, không đẩy layout.

---

## 7. Animation tối thiểu (nhẹ, tween 0.1–0.3s)
1. Vào màn: card bảng fade + scale 0.96→1.0 (0.25s).
2. Đặt mèo: pop (mục 4.4).
3. Vùng hoàn thành: icon ở pill tiến độ bounce.
4. Mất lượt: icon lượt rung + xám.
5. Nút bấm: scale press.
Không dùng shader/particle nặng.

---

## 8. Kế hoạch thực hiện đề xuất (chia task cho agent)

| # | Task | Phụ thuộc | Ghi chú |
|---|---|---|---|
| T1 | Tạo `ui_theme.gd` (hoặc block const) chứa tokens mục 3 + helper tạo `StyleBoxFlat` (card, pill, nút tròn, shadow) | – | Mọi task sau dùng chung |
| T2 | Dựng khung `Safe/Root` + `Background`, gỡ các panel cũ ra khỏi cây node (nhưng **giữ lại các hàm/logic** chúng gọi) | T1 | |
| T3 | TopBar (Back, Màn/Điểm, Settings) | T2 | Nối lại hành vi Home/Settings cũ |
| T4 | StatusRow: pill tiến độ vùng + pill lượt sai | T2 | Cần hook cập nhật khi đặt mèo / mất lượt |
| T5 | RulesCard + icon 3×3 | T2 | |
| T6 | Board: card vuông, ô bo góc, gap, bỏ viền đậm & hiệu ứng kính, trạng thái ô, hit-test | T2 | **Rủi ro cao nhất** – test input kỹ |
| T7 | BottomBar 3 nút tròn + badge; nút "?" và popup Trợ giúp | T2 | |
| T8 | Popup thắng/thua, toast, animation | T3–T7 | Ưu tiên thấp |
| T9 | QA theo mục 10 | tất cả | |

---

## 9. Assets (placeholder → thay sau)

Đặt trong `res://assets/ui/board/`. Nếu file chưa tồn tại thì **fallback vẽ bằng code / emoji**, không để lỗi thiếu resource.

| Tên file | Dùng cho | Kích thước gợi ý |
|---|---|---|
| `icon_back.png` | Nút Back | 96×96 |
| `icon_settings.png` | Nút Settings | 96×96 |
| `icon_help.png` | Nút "?" | 96×96 |
| `cat_head_progress.png` (trắng/xám, **tô màu bằng `modulate`**) | Pill tiến độ vùng | 96×96 |
| `life_icon.png` | Pill lượt sai | 96×96 |
| `cat_face_cell.png` | Mèo đặt trên ô | 128×128 |
| `cat_face_small.png` | Icon luật 3×3 | 64×64 |
| `icon_undo.png`, `icon_hint.png`, `icon_restart.png` | 3 nút dưới | 128×128 |
| `icon_play_badge.png` | Badge quảng cáo | 48×48 |

Mọi đường dẫn khai báo ở **một chỗ** (const) để đổi asset không phải sửa logic.

---

## 10. Tiêu chí nghiệm thu (Definition of Done)

**Giao diện**
- [ ] Bố cục từ trên xuống đúng thứ tự: TopBar → StatusRow → RulesCard → Board → BottomBar.
- [ ] Không còn: card tiêu đề "VƯỜN MÈO", chữ "Lượt sai còn lại…", chữ "Sẵn sàng", chip A/B/C/D, dòng hướng dẫn cử chỉ, 6 nút chữ nhật, viền navy đậm giữa vùng, hiệu ứng "kính" trên ô.
- [ ] Bảng gần full chiều ngang, vuông, canh giữa, cho cả màn 4×4 lẫn 10×10.
- [ ] Ô bo góc, có khe hở, màu phẳng theo vùng; các vùng phân biệt rõ.
- [ ] Pill tiến độ hiển thị đúng số vùng của màn; cập nhật khi đặt/xoá mèo.
- [ ] Lượt sai hiển thị bằng icon và giảm đúng khi đặt sai.
- [ ] 3 nút tròn dưới có shadow, badge (nếu có dữ liệu), trạng thái disabled đúng.
- [ ] Chữ tiếng Việt hiển thị đúng dấu, không bị cắt ở màn 540×960 và 720×1600.

**Chức năng (không được hỏng)**
- [ ] Chạm / chạm đôi / kéo hoạt động y như trước, kể cả ở 10×10.
- [ ] Undo, Hint, Restart, Home (Back), Settings, Trợ giúp vẫn gọi đúng hành vi cũ.
- [ ] Thắng / thua / hết lượt vẫn kích hoạt đúng.
- [ ] Không có lỗi/warning mới trong Output khi mở màn, chơi, thoát.
- [ ] Không đổi kết quả sinh màn / kiểm tra luật (so sánh cùng seed trước & sau).

**Kiểm thử thủ công (người chơi kiểm tra)**
- Màn 4×4 (L01) và một màn lớn (8×8 hoặc 10×10 nếu có).
- Xoay/đổi cỡ cửa sổ 540×960, 720×1600, 1080×1920.
- Bấm nhanh liên tiếp các nút dưới; kéo đánh dấu ngang qua nhiều vùng.

---

## 11. Ngoài phạm vi (KHÔNG làm)
- Không đổi luật, thuật toán sinh màn, hệ thống tiến trình/lưu game.
- Không tạo hệ thống điểm, tiền tệ, quảng cáo, power-up mới.
- Không sao chép asset của game tham chiếu (icon, hình mèo…); chỉ mô phỏng bố cục & phong cách.
- Không làm banner quảng cáo dưới cùng như REF.
- Không restyle màn Home (đã có spec riêng).

---

## 12. Ghi chú bàn giao (agent điền khi xong)
- File đã sửa / tạo:
  - `game/scripts/board_screen.gd`: Tái cấu trúc toàn diện theo REF (TopBar với Back tròn, Màn canh giữa, Help '?' và Settings; StatusRow với pill đầu mèo màu theo vùng và pill 3 cá vàng mạng; RulesCard 2x2 với icon lưới 3x3; BoardCard to cân đối; BottomBar 3 nút tròn có shadow & badge).
  - `game/scripts/board_view.gd`: Render ô vuông bo góc mềm (~14% cạnh), có khe hở (gap ~4-8px), màu phẳng theo bảng 10 vùng, bỏ viền navy đậm và hoa văn kính; vẽ mặt mèo texture/procedural và dấu X trắng đậm.
  - `game/scripts/ui_tokens.gd`: Bổ sung các token `BOARD_BG`, `BOARD_CARD`, `BOARD_TILE`, `TEXT_STAT`, `TEXT_RULE`, `ICON_BROWN`, `REGION_PALETTE` (10 màu), và helper `make_card_style()`, `make_circle_button_style()`.
  - `game/tests/run_board_scene_smoke.gd`: Cập nhật assertion vị trí `RegionProgress` nằm trước `BoardView` theo layout mới.
  - `game/assets/ui/board/`: Bộ asset placeholder PNG crisp (`icon_back.png`, `icon_settings.png`, `icon_help.png`, `icon_undo.png`, `icon_hint.png`, `icon_restart.png`, `cat_head_progress.png`, `life_fish.png`, `cat_face_cell.png`, `cat_face_small.png`, `icon_play_badge.png`).
- Hàm/biến bị đổi tên (nếu có): Không đổi tên bất kỳ hàm, biến, hay signal công khai nào (`configure()`, `get_session()`, `undo_last_x()`, `request_restart()`, `confirm_restart()`, `cancel_restart()`, v.v. được giữ nguyên vẹn).
- Giả định đã áp dụng:
  - Điểm số: Ẩn cột điểm do game chưa có hệ thống điểm, canh giữa cột "Màn".
  - Lượt sai: Hiển thị bằng 3 icon bánh cá vàng (mờ xám khi mất lượt), `hearts_label` được giữ ngầm cho accessibility và test regression.
  - Badge nút Gợi ý: Hiển thị badge tròn xanh lá có icon ▶ quảng cáo. Nút Hoàn tác hiển thị mờ khi không có bước hoàn tác.
  - Trợ giúp: Nút tròn "?" đặt trên TopBar cạnh nút Settings.
- Việc còn tồn đọng / đề xuất:
  - Có thể thay thế các ảnh placeholder tại `res://assets/ui/board/` bằng asset mỹ thuật vector/3D chính thức bất cứ lúc nào mà không cần sửa code logic.
