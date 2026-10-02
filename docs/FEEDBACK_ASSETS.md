# Kế hoạch & Danh mục Bổ sung Tài nguyên Âm thanh & Xúc giác (Feedback Assets)

> **Mã module:** M06 — Feedback (Audio & Haptic)  
> **Tài liệu liên quan:** [Master Plan](superpowers/plans/2026-10-02-rebuild-master.md), [Module 06 Plan](superpowers/plans/rebuild/06-feedback.md), [STATUS](STATUS.md)  
> **Trạng thái logic code:** Đã hoàn tất và tích hợp cơ chế nạp an toàn (fallback không crash khi thiếu file).

---

## 1. Danh mục Tệp Âm thanh Hiệu ứng (SFX) — Định dạng `.ogg`

Thư mục lưu trữ trong dự án: `game/audio/sfx/` (tương ứng đường dẫn tài nguyên `res://audio/sfx/`).

| Tệp âm thanh (`.ogg`) | Hiệu ứng (`Effect`) | Mức ưu tiên | Mô tả ngữ cảnh & Hành vi |
| :--- | :--- | :---: | :--- |
| `mark.ogg` | `Effect.MARK` | **P1** | Âm thanh gõ nhẹ/đánh dấu khi người chơi bấm vào ô trống để đặt dấu `X`. Đã cấu hình giới hạn tần suất tối thiểu `100ms` chống nổ âm thanh khi lướt tay nhanh. |
| `undo.ogg` | `Effect.UNDO` | **P1** | Âm thanh hoàn tác khi bấm nút Undo (rút lại bước đi). |
| `candy_found.ogg` | `Effect.CANDY_YES` | **P1** | Âm thanh vui tươi, tích cực khi người chơi đặt đúng vị trí viên kẹo trên bàn cờ. |
| `candy_wrong.ogg` | `Effect.CANDY_NO` | **P1** | Âm thanh cảnh báo lỗi khi người chơi đặt sai vị trí kẹo (bị trừ tim). |
| `lock_tick.ogg` | `Effect.LOCK_CELL` | **P2** | Âm thanh tick rất nhẹ và êm tai khi hệ thống tự động khóa ô (Auto-mark cascade sau khi đặt kẹo đúng). Đã cấu hình rate limit `60ms` để không gây chói tai khi khóa liên tiếp 4–8 ô. |
| `hint.ogg` | `Effect.HINT_SHOW` | **P2** | Âm thanh phát khi người chơi sử dụng gợi ý bước đi (Progressive Hint). |
| `win.ogg` | `Effect.STAGE_CLEAR` | **P1** | Giai điệu chúc mừng chiến thắng khi giải xong bàn cờ. |
| `fail.ogg` | `Effect.STAGE_FAIL` | **P1** | Âm thanh thông báo khi người chơi hết mạng (hết 3 tim) và thua màn chơi. |
| `tap.ogg` | `Effect.BTN_PRESS` | **P2** | Âm thanh phản hồi ngắn khi bấm các nút bấm trên giao diện (UI buttons). |
| `enter.ogg` | `Effect.BOARD_OPEN` | **P3** | Hiệu ứng âm thanh khi bắt đầu tải và mở một màn chơi mới. |
| `restart.ogg` | `Effect.RESTART` | **P3** | Hiệu ứng âm thanh khi người chơi xác nhận chơi lại màn hiện tại. |

---

## 2. Danh mục Tệp Nhạc nền (BGM) — Định dạng `.ogg`

Thư mục lưu trữ trong dự án: `game/audio/bgm/` (tương ứng đường dẫn tài nguyên `res://audio/bgm/`).

| Tệp âm thanh (`.ogg`) | Mức ưu tiên | Mô tả & Thiết lập kỹ thuật |
| :--- | :---: | :--- |
| `theme.ogg` | **P2** | Bản nhạc nền phong cách thư giãn, nhẹ nhàng, hỗ trợ người chơi tập trung suy nghĩ giải đố. `BgmPlayer` tự động thiết lập loop vô tận. |

---

## 3. Tiêu chuẩn Bản quyền & Định dạng Âm thanh

- **Định dạng chuẩn:** Ogg Vorbis (`.ogg`), sample rate 44.1 kHz, nén tối ưu dung lượng cho di động.
- **Quy tắc Clean-Room & Bản quyền:**
  - Tuyệt đối **không** trích xuất hoặc sao chép từ phiên bản cũ (`extracted_reusable`) hay từ các tựa game thương mại khác.
  - Toàn bộ âm thanh phải là sản phẩm sáng tác gốc hoặc sử dụng từ nguồn miễn phí bản quyền thương mại (giấy phép CC0 hoặc Royalty-Free có thể phân phối thương mại).

---

## 4. Kế hoạch Kiểm thử & Tích hợp Tiếp theo

### A. Kiểm thử Rung trên Thiết bị Thật (On-device Haptic Acceptance)
Mã nguồn tại [`vibration.gd`](../game/scripts/feedback/vibration.gd) đã sẵn sàng với 3 mức độ:
- `SOFT` (15ms): Dùng cho Auto-mark / Tick nhẹ.
- `NORMAL` (30ms): Dùng cho đánh dấu `X`, đặt kẹo, tap nút.
- `FIRM` (60ms): Dùng cho đặt sai, mất tim, thắng/thua.

*Nhiệm vụ cần thực hiện:* Khi xuất bản build thử nghiệm trên thiết bị di động Android và iOS, kiểm tra thực tế cường độ rung trên tay người dùng để điều chỉnh lại độ trễ ms nếu cần.

### B. Kết nối Tín hiệu Giao diện (Wave 4 — Screens Wiring)
Tại `app_shell.gd` và `puzzle_screen.gd`, chỉ cần lắng nghe các tín hiệu từ `play_session.gd`:
```gdscript
# Ví dụ kết nối trong PuzzleScreen hoặc AppShell:
session.candy_found.connect(func(_r, _c, _reg):
    sfx.play(SfxCatalog.Effect.CANDY_YES)
    Vibration.pulse(Vibration.Strength.NORMAL)
)

session.mistake_made.connect(func(_r, _c, _reason):
    sfx.play(SfxCatalog.Effect.CANDY_NO)
    Vibration.pulse(Vibration.Strength.FIRM)
)

session.auto_marked.connect(func(_cells):
    sfx.play(SfxCatalog.Effect.LOCK_CELL)
    Vibration.pulse(Vibration.Strength.SOFT)
)

session.level_won.connect(func():
    sfx.play(SfxCatalog.Effect.STAGE_CLEAR)
)

session.level_failed.connect(func():
    sfx.play(SfxCatalog.Effect.STAGE_FAIL)
)
```
