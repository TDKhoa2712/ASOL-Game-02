# M0-A02 — Kết quả prototype tương tác runtime

## Phạm vi đã kiểm chứng

- Engine: Godot 4.7.2 stable, project `game/project.godot`.
- Runtime: Godot Editor/desktop, viewport logic 1080×1920, cửa sổ test 540×960.
- Level: T01 4×4 từ mirror canonical `game/data/t01.json`.
- Đường chạy gesture: replay trực tiếp `GestureEngine.begin_pointer`, `move_pointer`, `end_pointer`, `tick`, `flush_pending`, `cancel_active`; không chỉ chạy adapter mô phỏng.
- UI: `board.tscn` tự vẽ vector nguyên gốc, có hearts/status, Undo và Restart có xác nhận.

Không có claim APK, thiết bị thật, input latency, FPS, asset sản xuất, audio hay SFX trong package này.

## Kết quả tự động

| Kiểm tra | Kết quả |
|---|---|
| Canonical Python interaction oracle | PASS — 3/3 |
| Godot gesture contract v2 | PASS — 16/16 canonical + 2/2 exact-boundary + 4/4 live guards |
| Godot session contract | PASS — 14/14 |
| Board scene smoke | PASS — node UI, mouse/touch/drag/outside/focus, Undo, Restart cancel/confirm |
| Game Python tests | PASS — 8/8 |
| GDD tests | PASS — 23/23 |
| Pipeline tests | PASS — 22/22 |
| Level validator | PASS — 5/5, 0 duplicate warning |
| Pipeline validate / doctor | PASS / PASS |
| `agent_pipeline verify M0-A02` | PASS |

Marker runtime cuối cùng:

```text
M0_A02_INTERACTION_CONTRACT_PASS gestures=16 boundaries=2 segmented=1 ownership=1 terminals=2 sessions=14
M0_A02_BOARD_SCENE_PASS
M0_A01_BOOTSTRAP_READY
```

Ảnh render đã kiểm tra trực quan: `work/evidence/M0-A02/editor-prototype.png`.

## Raw input trace chuẩn hóa

Các trace dưới đây là sự kiện logic xác định được replay vào API pointer runtime. Tọa độ là logical px với tâm ô đầu `[0,0] = (50,50)` và kích thước ô 100 px.

| Trace | Sự kiện theo thứ tự | Kết quả |
|---|---|---|
| Single tap | `down#0 (50,50) t=0`; preview `x`; `up#0 t=10`; `tick t=291` | Một `MarkX`, ô `0,0=x` |
| Double đúng tại biên | `down/up t=0/10`; lần hai `down/up t=290/300` trên `[0,1]` | Một `TryCat`, ô `0,1=cat`; không lưu X trung gian |
| Slow double ngoài biên | `down/up t=0/10`; lần hai `down/up t=291/301`; `tick t=582` | `MarkX`, rồi `ClearX`; không có `TryCat` |
| Jitter đúng 12 px | `down (50,50)`; `move (62,50)`; `up`; hết pending | Vẫn là một `MarkX` |
| Motion 13 px | `down (50,50)`; `move (63,50)`; `up` | Một `MarkStroke`; Undo phục hồi state ban đầu |
| Fast drag + return | `down [0,0]`; `move [0,3]`; `move [0,0]`; `up` | Nội suy đủ ô, mỗi ô xử lý một lần, bỏ qua cat/X/X đỏ |
| Segmented elbow drag | `down [0,0]`; `move [0,3]`; `move [3,3]`; `up` | Nối từng sample: đủ hàng 0 rồi cột 3, không vẽ đường chéo từ origin |
| Secondary pointer | primary `down [2,0]`; secondary `down [3,0]`, kéo `[3,3]`; primary `up` | Ngón phụ bị bỏ qua; chỉ primary tạo `MarkX` |
| Locked primary owner | primary giữ `x_error [0,0]`; secondary chạm empty `[0,1]` | Primary vẫn sở hữu contact; secondary không tạo preview/action |
| Background after release | `down/up [0,0]`; `flush_pending` | Tap đã nhấc được commit |
| Background while active | `down [0,0]`; `cancel_active` | Preview chưa nhấc bị hủy; không action |
| Released tap + active second | tap đầu đã `up`; contact thứ hai còn giữ; focus loss | Hủy contact thứ hai và commit tap đầu trong cùng notification |
| Terminal attempts | 3 lỗi liên tiếp hoặc đặt đủ 4 mèo đúng | Chuyển `Failed`/`Won`, xóa Undo và từ chối input board mới |

## Ngưỡng và accidental TryCat

- Cửa sổ double-tap: `<= 280 ms` gọi đúng một `TryCat`; `281 ms` tạo hai single tap độc lập.
- Touch slop: chuyển động `<= 12 logical px` vẫn là tap; `13 px` chuyển sang stroke.
- Trong 14 trace canonical không có chủ đích TryCat, số `TryCat` ngoài ý muốn là `0/14 = 0%`.
- Hai trace có chủ đích TryCat đều phát đúng một action: `2/2`.

Tỷ lệ 0% trên là tỷ lệ của corpus tự động xác định, không phải tỷ lệ người chơi trên thiết bị. Ngưỡng 3% trong GDD vẫn cần playtest người thật ở package/gate sau; 280 ms và 12 px có thể tinh chỉnh sau mà không đổi kiến trúc session.

## Cách chạy trong Godot Editor

1. Mở Godot 4.7.2, chọn **Import**, trỏ tới `game/project.godot`.
2. Nhấn **F5** để chạy main scene `bootstrap.tscn`; prototype T01 hiện ngay trong cửa sổ 540×960.
3. Nếu chỉ muốn chạy board, mở `game/scenes/board.tscn` rồi nhấn **F6**.
4. Chạm/click một ô trống để đánh hoặc xóa X; preview xuất hiện ngay, action commit sau cửa sổ 280 ms.
5. Double-click cùng ô: `[0,1]` là đáp án đúng và đặt mèo; `[0,0]` là sai, tạo X đỏ khóa và giảm một tim.
6. Giữ rồi kéo qua nhiều ô để đánh/xóa một stroke; bấm **Hoàn tác** để hoàn nguyên action X gần nhất.
7. Bấm **Chơi lại**; **Giữ nguyên** phải bảo toàn bàn, còn xác nhận **Chơi lại** reset board và 3 tim.

Đáp án T01 để test đúng mèo theo từng hàng là `[0,1]`, `[1,3]`, `[2,0]`, `[3,2]`.

## Giới hạn prototype

- Chỉ có T01 và màn puzzle; chưa có Home, progression, kết quả thắng/thua hay lưu game.
- Hình mèo, màu vùng và họa tiết đều là vector placeholder nguyên gốc; chưa phải asset sản xuất.
- Chưa có âm thanh, SFX, animation sản xuất, telemetry hay accessibility screen-reader hoàn chỉnh.
- Chưa đo cảm giác chạm, accidental gesture, latency hoặc hiệu năng trên Android/iOS thật.
