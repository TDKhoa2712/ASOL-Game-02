# Thiết kế: Chuỗi tính theo bàn chơi hoàn thành + lửa "bốc"

- Ngày: 2026-10-14
- Nhánh: `feat/v1.0.1/assist-inventory`
- Sửa: [assist inventory](2026-10-14-assist-inventory-design.md) §2.4 và [streak view](2026-10-14-streak-view-design.md) §3.

## 1. Luật mới

- Một ngày được tính khi có **≥1 bàn chơi kết thúc** (thắng hoặc thua hết tim). Bỏ dở (về Home, chơi lại) không tính.
- Gói 7 ngày, tổng chuỗi, kỷ lục dùng cùng định nghĩa.
- Không tính: level custom/debug, tutorial. Bàn đã kết thúc được khôi phục khi mở lại app không tính trùng trong ngày (luật cùng ngày như cũ).
- API: `AssistInventory.on_level_won` → `on_round_finished(today := "")`; `PuzzleAssistController.on_level_won` → `on_round_finished(session, is_custom)`. `puzzle_screen` gọi ở `_on_level_won` và `_on_level_failed`. Chế độ mới chỉ cần gọi `on_round_finished` khi một bàn kết thúc.
- Câu chữ: các chuỗi "Thắng 1 màn…" đổi thành "Chơi xong 1 màn…" (7 ngôn ngữ): `streak.at_risk`, `streak.start`, `assist.empty_body`.

## 2. `flame_fx.gd` — lửa dùng chung

`extends Control`, tạo bằng `FlameFx.new(side: float, embers: int)`.

- **3 lớp** từ `icon_flame.svg` (trắng, tô `modulate`), cùng tâm đáy:
  - ngoài: `#E8361C`, scale 1.0
  - giữa: `#FF8A1F`, scale 0.78
  - lõi: `#FFD84A`, scale 0.5
- **Flicker** (khi `lit`): mỗi lớp một tween lặp riêng — scale.y 1.0↔1.06–1.12, rotation ±3°, alpha 0.85↔1.0; chu kỳ 0.32–0.55 s, lệch pha (độ trễ khác nhau).
- **Tàn lửa**: `CPUParticles2D` phát từ đáy ngọn lửa, bay lên, nhỏ dần và tắt; màu từ vàng sang đỏ trong suốt; `amount = embers`, `embers == 0` thì không tạo.
- `set_lit(lit: bool)`: `true` → 3 lớp màu + flicker + tàn; `false` → chỉ lớp ngoài màu xám `#B9B4AC`, không flicker, không tàn.
- Giảm chuyển động (`LayoutTokens.motion_enabled == false`): 3 lớp màu tĩnh, không tween, không hạt.
- Truy vấn cho test: `layers: Array[TextureRect]`, `embers_node: CPUParticles2D` (hoặc null), `is_flickering() -> bool`.

Dùng ở:

| Nơi | Kích thước | Tàn |
|---|---|---|
| Viên lửa Home | 52 | 6 |
| Bảng chuỗi | 140 | 18 |
| Burst +1 | 170 | 24 |

## 3. Burst +1

Tổng ~1.2 s, trên bàn chơi khi giữ kết quả (thắng 1.5 s, thua 1.2 s):

1. Quầng sáng tròn mờ sau lửa (vẽ `_draw`, cam alpha 0.35).
2. Lửa 3 lớp bung từ 0.4 lên 1.25 rồi về 1.0.
3. Vòng sáng lan ra (vẽ `_draw`, bán kính 0 → 1.6× kích thước, alpha 0.8 → 0).
4. Nổ tia lửa: `CPUParticles2D` one-shot, `explosiveness = 1`, ~28 hạt bắn tỏa tròn.
5. Số đổi N−1 → N với nảy scale 1.35 → 1.0.
6. Rung nhẹ: `Vibration.pulse(SOFT)` (theo cài đặt rung).
7. Mờ dần, `queue_free`.

Giảm chuyển động: hiển thị tĩnh lửa 3 lớp + số N, không vòng sáng, không hạt; tự xóa sau 1.2 s nếu ở trong cây.

## 4. Kiểm thử

- Luật/flow: thua cũng ghi ngày; thua được khôi phục không tính trùng; custom thua không tính; burst chạy cả khi thua.
- `flame_fx`: 3 lớp; `set_lit(false)` → 1 lớp xám hiện, không flicker, không tàn; giảm chuyển động → không tween/hạt.
- Burst: có vòng sáng, nổ tia lửa (khi có chuyển động), nhãn cuối = N.
- Full gate theo AGENTS.md.
