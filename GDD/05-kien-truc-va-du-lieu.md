# 05 — Kiến trúc và hợp đồng dữ liệu

## 1. Công nghệ và tương thích

Giữ Godot 4.x/GDScript và puzzle core thuần dữ liệu. Phiên bản engine thực dùng được ghi theo build trong STATUS/evidence, không lấy một số phiên bản trong GDD làm bằng chứng đã kiểm. Runtime 2D, kẹo và UI gốc theo [06](06-my-thuat-va-am-thanh.md); bỏ phụ thuộc sản xuất model/rig/clip kẹo. Không thay engine hoặc renderer trong đợt sửa tài liệu này.

Token `candy`, action `TryCandy`, hàm `try_candy` và event `CandyFound` là hợp đồng hiện hành cho code, fixture, validator và tài liệu. Session dùng version 3; level schema v4 và progress v2 giữ nguyên. ID level, topology và puzzle hash không đổi.

Python validator và runtime phải dùng cùng vector hành vi CanDoKu. `legacy_session_migration.gd` là biên tương thích duy nhất: đọc session v2, chuyển trạng thái mục tiêu cũ sang `candy` trên bản sao, giữ nguyên tim/Hint/lỗi/thời gian và trường bổ sung, rồi kiểm schema và level/hash. Không sửa file khi chỉ đọc; lần lưu bình thường tiếp theo ghi v3 bằng cơ chế atomic. Session v3 không chấp nhận token cũ. Giữ đường dẫn dữ liệu người dùng cũ dù đổi tên hiển thị ứng dụng.

## 2. Module

| ID | Module | Trách nhiệm |
| --- | --- | --- |
| TECH-01 | Content (M03) | `bank_reader`, `pace_reader`, `board_transform`, `region_painter`, `level_validator` — đọc bank JSON chứa level theo rank, pace sidecar chứa hint economy (hintCosts), transform ×8 nhân nội dung, validate schema v4/trace/nghiệm |
| TECH-02 | Core (M01) | `cell_model`, `candy_rules`, `board_solver` — luật GR-01..08, chấm `TryCandy` dựa trên solution (`solution[row] == col`), auto-mark (S1 lock ô cùng row/col/zone), 5 cell states + given flag |
| TECH-03 | Input (M04) | `touch_decoder`, `play_session`, `action_recorder` — preview X tức thì, chạm đôi/kéo một ngón, commit action tuần tự, grouped undo (candy + auto-marks = 1 undo group), Restart, tim, lỗi, thời gian, trạng thái phiên |
| TECH-04 | Core/board_solver | S1 auto-mark → S2 naked single → S3 lock intersection (4 modes: zone→row, zone→col, row→zone, col→zone); solve loop lặp S1→S2→S3 đến khi đủ candy hoặc STUCK; progressive hint dùng hintCosts từ pace |
| TECH-05 | UI controller (M08) | Action → event/view model; điều hướng Home/Puzzle/Results/Help/Settings; composition root khởi tạo và inject dependencies |
| TECH-06 | State (M02) | `dual_slot_store`, `progress_manager` — session hiện tại + progress độc lập, backup/atomic write |
| TECH-07 | Content pipeline (M10) | Validator, lọc trùng, `--release`, báo cáo biên tập; sinh bank/pace/campaign JSON |
| TECH-18 | Visual presenter (M05/M06) | Nhãn vùng → nền/viền/tiến độ; token `candy` → kẹo mặc định; hiệu ứng 2D/reduced motion; auto-mark animation; không chứa luật |
| TECH-20 | Asset loader | Nạp resource kẹo/UI dùng chung, asset dự phòng khi lỗi; không có bộ chọn ngoại hình hoặc cache bộ sưu tập |

Kiến trúc rebuild dùng **composition root pattern** — không có autoloads. App shell (`app_shell`) khởi tạo tất cả module và inject dependencies. Signals thay thế global event bus. Mỗi module ≤ 300 dòng, một file, một trách nhiệm. Pure logic modules (cell_model, candy_rules, board_solver, board_transform) là stateless static functions.

## 3. Schema level v4

Gốc file là `{ "levels": [...] }`. Mỗi level có đúng các trường sau; tọa độ 0-based, chuỗi UTF-8. Fixture và campaign dùng cùng schema. Bỏ `chapter`; `order` là thứ tự toàn cục.

| Trường | Điều kiện |
| --- | --- |
| `schemaVersion` | Integer `4` |
| `id` | String duy nhất, ổn định, `[A-Z0-9_-]+` |
| `order` | Integer ≥1; campaign playtest đúng 1..30, mỗi slot một level; fixture dùng thứ tự riêng, không đóng gói playtest |
| `size` | Integer 4..12; release 4..6 |
| `regions` | N chuỗi dài N, chỉ dùng đúng N nhãn `A..` liên tiếp, tối đa `L`, mỗi vùng liên thông 4 hướng |
| `givens` | Mảng `{r:int,c:int}`, không trùng hàng, thuộc nghiệm |
| `solution` | N cột, hoán vị `0..N-1`, thỏa bốn luật và nghiệm duy nhất |
| `difficulty` | `tutorial`, `easy`, `medium`, `hard`; release chưa dùng `hard` |
| `tags` | Mảng string không rỗng, không trùng; chỉ là metadata |
| `logicTrace` | Các bước S2/S3 tuần tự từ givens tới đủ N kẹo; campaign order 1–18 chỉ S2, order 19–24 có S3 cần thiết, order 25–30 theo profile được duyệt |

Step S2 vẫn có đúng `rule`, `focus`, `conclusion`, `textKey`, ví dụ:

```json
{"rule":"S2","focus":{"type":"region","id":"A"},"conclusion":{"type":"place","r":0,"c":1},"textKey":"hint.single.region"}
```

Validator tính lại mọi ứng viên và nguồn loại trừ; không lưu `eliminatedCells` tự khai. `textKey` phải khớp focus row/column/region. `countSolutions` duyệt ràng buộc độc lập `solution`, dừng ở nghiệm thứ hai. Với N=12, validator phải có ngân sách thời gian rõ; level vượt ngân sách bị từ chối/biên tập lại, không coi timeout là nghiệm duy nhất.

Step S3 có đúng `rule`, `source`, `target`, `conclusion`, `textKey`; `source`/`target` là hai loại đơn vị khác nhau. `conclusion.cells` là toàn bộ tập ứng viên mới bị loại, dùng object tọa độ 0-based:

```json
{"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"}
```

Validator tự tính `P(source)` và `P(target)` từ candy đã chứng minh cùng tập loại trừ hiện hành; yêu cầu `P(source)` khác rỗng, nằm trọn trong target và `P(target) \ source` khác rỗng. Kết luận phải khớp chính xác tập loại mới theo thứ tự chuẩn, không lặp/no-op và không dùng `solution`, X hoặc `x_error` làm chứng cứ. S2 sau S3 được phép dựa trên tập loại trừ đã chứng minh.

Màu vùng là theme mapping từ A–L, không nằm trong JSON. Mọi ô `candy` dùng cùng asset kẹo mặc định. Nền/viền/nhãn/họa tiết và hàng tiến độ nhận diện vùng. Đổi theme không đổi nghiệm, trạng thái, `puzzleHash` hoặc schema. Không thêm `selectedAppearanceId` vào progress bản đầu.

### 3b. Kiến trúc bank/pace/playlist

Rebuild thay thế cách nạp level đơn file bằng kiến trúc ba lớp:

- **Bank** (`data/banks/`): JSON chứa level nhóm theo rank (easy/medium/hard). Mỗi bank là một bộ sưu tập level cùng kích thước/độ khó. `bank_reader` đọc và lọc level từ bank.
- **Pace** (sidecar): File JSON đi kèm bank, chứa hint economy — `hintCosts` cho từng level/rank, điều chỉnh chi phí hint theo tiến trình. `pace_reader` đọc pace data.
- **Playlist/Campaign** (`data/campaigns/`): Tham chiếu vào bank theo ID level, xác định thứ tự chơi 30 levels cho playtest. Campaign không chứa dữ liệu level, chỉ references.
- **Transform ×8**: `board_transform` áp dụng 8 phép biến đổi đối xứng (rotation + reflection) lên mỗi level, nhân nội dung mà không cần thêm level gốc.

## 4. Progress và session

`progress.json` chứa tiến trình tuyến tính; `session.json` chỉ chứa lượt của `currentLevelId`. Mỗi file ghi qua temp + replace nguyên tử, progress có một bản hợp lệ trước để phục hồi. Khi thắng, ghi progress với level kế và kết quả trước khi hiện màn thắng, rồi xóa session cũ. Sau crash giữa hai bước, `session.levelId` khác `progress.currentLevelId` thì bỏ session cũ. Khi thua, session `failed` được lưu và Home Play trở lại màn thua.

```json
{
  "progressVersion": 2,
  "currentLevelId": "L02",
  "completedLevelIds": ["L01"],
  "results": {"L01": {"score": 375, "mistakes": 1, "hints": 0, "elapsedMs": 84000}},
  "tutorialSeenIds": ["T1", "T2"]
}
```

```json
{
  "sessionVersion": 3,
  "levelId": "L02",
  "puzzleHash": "<sha256 of canonical puzzle data>",
  "status": "playing",
  "cells": ["empty", "x", "x_error", "candy", "locked"],
  "hearts": 2,
  "mistake_count": 1,
  "hints_used": 0,
  "elapsedMs": 84000
}
```

`cells` trên là ví dụ rút gọn; dữ liệu thật có N² ô theo hàng trước, cột sau (NxN cell states). Given lưu `empty` trong session và được ghép từ level data khi render. `locked` cells (auto-mark do hệ thống) lưu `"locked"` trong session. `hints_used` đếm số click progressive hint đã dùng; reload/Back To Home giữ giá trị, còn Retry/Restart tạo session lượt mới với `0`. `correct_count` được suy từ các ô `candy` không phải given; scorecard tính theo GR-18, không lưu hai nguồn điểm có thể lệch nhau. `puzzleHash` là SHA-256 của JSON compact UTF-8 cho `[size,regions,givens sắp theo (r,c),solution]`. Session sai hash/version/cell bất hợp lệ thì báo và tạo lại **cùng level**, không tiến level. `currentLevelId=null` nghĩa là hoàn thành toàn bộ nội dung hiện có. Khi append level mới, quét danh sách completed để xác định successor đầu tiên chưa xong. Không cho chọn ID đã qua trong UI.

| ID | Quy tắc |
| --- | --- |
| TECH-08 | Preview X/kéo và khe Undo chỉ tồn tại trong runtime; sau action đã xác nhận và đổi board/tim/hint, ghi session trước phản hồi bền vững. Preview/khe Undo không lưu. Back To Home/app đóng xóa khe dù session board vẫn được giữ. |
| TECH-09 | Progress tách session; session hỏng không xóa completed/results. Progress chính hỏng thử bản hợp lệ trước, không ghi đè bằng trống. |
| TECH-10 | Kiểm version/hash khi load; hỗ trợ chuyển session v2 sang v3 qua biên tương thích riêng. |
| TECH-11 | Không dữ liệu cá nhân hoặc truyền analytics mạng trong bản đầu. |
| TECH-12 | ID/puzzle đã phát hành bất biến; thêm level ở cuối, không chèn giữa level đã phát hành nếu chưa có migration thứ tự. |

## 5. API và sự kiện

```text
validateLevel(level) -> ValidationResult
countSolutions(regions,givens,limit=2) -> 0 | 1 | 2
createSession(level) -> Session
applyAction(level,session, MarkX(cell) | ClearX(cell) | MarkStroke(mode,cells) | TryCandy(cell) | UndoX | RestartLevel) -> {session,events}
getHint(level,session) -> HintEvidence | NoHint
completeLevel(level,session) -> Progress | Error
```

Gesture layer quyết định một chạm/chạm đôi/nét kéo; core không đo thời gian chạm. UI áp preview từ bản sao trạng thái đã commit, rồi gửi action sau khi rõ cử chỉ. `MarkStroke` nhận danh sách ô đã đi qua theo thứ tự, loại trùng, áp cùng chế độ `mark` hoặc `clear` từ ô đầu; core bỏ qua các ô không hợp lệ và commit toàn bộ trong một transaction. Bắt đầu trên X đỏ/candy/given không mở nét. Một action X lưu đúng diff vào khe Undo runtime; `UndoX` hoàn nguyên toàn diff rồi làm rỗng khe. `TryCandy` xóa khe trước khi chấm, nên không thể Undo xuyên qua. `RestartLevel` chỉ chạy sau xác nhận UI và tạo session mới cùng level. Core trả `XMarked`, `XCleared`, `XUndoApplied`, `SessionRestarted`, `CandyFound(row, col, region)`, `Mistake(row, col, reason)`, `HeartLost(remaining)`, `AutoMarked(cells)`, `LevelWon`, `LevelFailed`. `AutoMarked(cells)` phát ra khi hệ thống tự đánh dấu LOCKED các ô cùng row/col/zone/diagonal với candy vừa đặt hoặc givens khi init board. UI/animation chỉ dùng event; `x_error` là ô bất biến trong lượt. Input bị khóa trong chuyển result. Với action thắng, service commit progress trước `LevelWon`; nếu ghi lỗi, giữ state cũ và báo thử lại. Scorecard được tính từ board/lỗi, nên save và Result có một nguồn chuẩn.

Trình nhận cử chỉ chỉ chấp nhận ngón `event.index == 0` nếu điểm đầu ở trong bàn, rồi giữ ID này đến khi nhấc; bỏ qua mọi ngón phụ và điểm chạm bắt đầu ngoài bàn. Đây là chặn multi-touch/ngón phụ, không phải thuật toán nhận dạng palm đầu tiên trong bàn. Sau khi nhấn, X preview xuất hiện trong khung hình đầu. Chuyển sang kéo khi độ dịch chuyển từ điểm đầu vượt **12 điểm logic** sau quy đổi UI scale; các ô cắt bởi đoạn từ vị trí trước đến vị trí mới được lấy bằng phép quét lưới phủ đủ ô trung gian. Mỗi ô chỉ được ghé một lần. Sau chạm đầu đã nhấc, mở cửa sổ **280 ms đến lần chạm xuống thứ hai**. Nếu lần hai ở cùng ô và cả hai lần không vượt ngưỡng kéo, hoàn tác preview chạm đầu rồi gọi một `TryCandy`. Chạm khác ô commit chạm đầu trước khi mở cử chỉ mới. Chạm thứ hai thành nét kéo cũng commit chạm đầu; nét hai lấy chế độ từ ô đầu **sau commit**, không gọi `TryCandy`. Cửa sổ/ngưỡng là cấu hình cần playtest, không phụ thuộc hoàn toàn vào cờ `double_tap` của hệ điều hành; [Godot cung cấp `index` và `double_tap` trên sự kiện chạm](https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html). App nền/chuyển màn commit chạm đơn đã nhấc nhưng còn chờ; hủy preview của chạm/nét đang giữ. Có thể nhận action ngữ nghĩa riêng từ trình đọc màn hình.

## 6. Ngân sách và cổng kỹ thuật

| ID | Yêu cầu |
| --- | --- |
| TECH-13 | Mở level dưới 2 giây sau startup trên thiết bị mục tiêu được ghi trong evidence |
| TECH-14 | X preview hiện trong khung hình đầu, mục tiêu dưới 50 ms; chạm đôi phản hồi dưới 100 ms sau chạm thứ hai và save thành công. Nét kéo xem được từng X ngay khi đi qua ô. |
| TECH-15 | Action đã báo lưu phải khôi phục sau app bị tắt; thắng đã hiển thị phải mở level kế. |
| TECH-16 | CI chạy validator fixture/test và `--release` trên campaign; N>6 hoặc thiếu order chặn build bản đầu. |
| TECH-17 | Renderer/sprite không chứa luật; đổi asset/animation không đổi core. |
| TECH-19 | Đo asset kẹo/vườn đại diện trên Android/iPhone mục tiêu: FPS ≥55 khi tương tác, không khựng >100 ms khi hé lộ kẹo/Result; ghi peak RAM/VRAM và thời gian nạp. Chốt ngân sách bộ nhớ theo thiết bị trước sản xuất asset hàng loạt |
| TECH-21 | Một bộ asset kẹo dùng chung mọi vùng, thử load lạnh/ấm và resume sau app nền; màu/nhãn/họa tiết vùng vẫn đọc được; asset lỗi có fallback và không đổi session |

Các ngưỡng là tiêu chí đích, không phải số đo đã đạt. Thiết bị thấp mục tiêu và ngân sách RAM/VRAM còn cần chốt khi có thiết bị; ghi người phụ trách và điều kiện thử lại trong STATUS. N=12 giữ ở dữ liệu, chưa phát hành. Không thêm wallet, generator runtime hoặc nguồn Hint ngoài lượt vào schema v4/progress v2.

## 7. Hợp đồng chuyển client sang CanDoKu

| Lớp | Thay đổi cần triển khai | Bất biến cần kiểm |
| --- | --- | --- |
| UI/copy | Tên ứng dụng, Home, Help, tutorial, Result, nhãn accessibility → CanDoKu/kẹo/luống | Điều hướng, chạm và tiến trình |
| Presenter/assets | Hình kẹo/cá → kẹo/tim; vườn, giỏ, âm và hiệu ứng theo GDD 06 | Board topology, bốn trạng thái, nhãn vùng |
| Save/API | Dùng candy/TryCandy/CandyFound; session v3, progress v2 | Save cũ khôi phục đúng; không đổi hash do hình ảnh |
| Nội dung | Biên tập 30 level gốc cho playtest theo dải GDD 01/04; duyệt profile 25–30 trước khi sản xuất | Không lấy fixture hoặc level đã đổi ID làm chứng minh đã duyệt |
| Đóng gói | Tên hiển thị CanDoKu và icon mới | Không đổi app identifier/save path/signing trong task rebrand nếu chưa có quyết định migration |

Build kiểm thử bốn level giữ ngoại lệ replay RST-003; build phát hành tắt nó. Dữ liệu minh họa trong tài liệu không phải campaign hoặc save người dùng. Chưa triển khai các thay đổi client trong lần sửa GDD này.
