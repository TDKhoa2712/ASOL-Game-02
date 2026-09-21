# 05 — Kiến trúc và hợp đồng dữ liệu

## 1. Chọn công nghệ

| Lựa chọn | Phù hợp | Chi phí/rủi ro với thiết kế này |
| --- | --- | --- |
| Phaser | Prototype web nhanh cho bàn 2D, cử chỉ, điểm, hint | [Phaser chính thức là framework 2D/web](https://docs.phaser.io/); [Mesh](https://docs.phaser.io/phaser/concepts/gameobjects/mesh) chủ yếu cho hiệu ứng/sprite phức tạp, không là pipeline nhân vật 3D đầy đủ. Cần tích hợp thư viện 3D và lớp đóng gói mobile riêng. |
| Godot 4.x + GDScript | UI/bàn 2D, sprite sheet nhân vật và export Android/iOS trong một project | Cần kiểm atlas, RAM/VRAM, tải asset và tương tác trên thiết bị thấp; iOS cần macOS/Xcode. |

**Quyết định sản xuất (REV-TECH-01/05):** Godot 4.x/GDScript, khóa minor version ở M0. Mèo gốc được tạo/rig/animate trong Blender hoặc công cụ 3D tương đương, rồi **render sẵn thành sprite sheet 2D** cho `idle`, `jump`, `celebrate`, `sad`. Một mèo dùng **một bộ clip**, không nhân atlas theo 6/12 màu vùng; Godot phát bằng [AnimatedSprite2D/SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html). Màu/nhãn/họa tiết vùng vẽ ở bàn và hàng tiến độ, không tô lên mèo. File model/rig vẫn giữ làm nguồn để bổ sung clip, góc máy và mèo mới sau này. Runtime bản đầu không dựng mèo 3D bằng SubViewport. Cách này giảm độ phức tạp renderer nhưng **không tự bảo đảm 60 FPS hay mức tiết kiệm VRAM cố định**: M0 phải đo FPS, RAM/VRAM, thời gian tải và khựng trên Android/iPhone cấu hình thấp. Theo [tài liệu export iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html), cần macOS với Xcode.

Puzzle core là module dữ liệu thuần, không import scene/asset/audio. Python chuẩn dùng content validator; logic runtime và Python phải qua cùng [vector hành vi mẫu](data/interactions.sample.json) ở M0/M1. Bài test Python là mô hình tham chiếu cho đặc tả, chưa phải bằng chứng Godot đã xử lý đúng trên thiết bị.

## 2. Module

| ID | Module | Trách nhiệm |
| --- | --- | --- |
| TECH-01 | Level loader/validator | Schema v4, N≤12, vùng A–L, nghiệm, givens, trace S2/S3, release band theo order |
| TECH-02 | Puzzle core | Luật GR-01..08, chấm `TryCat`, trạng thái thắng/điểm |
| TECH-03 | Gesture/session | Preview X tức thì, nhận chạm đôi/kéo một ngón, commit action tuần tự, khe Undo X một bước, Restart, tim, lỗi, thời gian, trạng thái phiên |
| TECH-04 | Hint engine | Một Hint/lượt; S2 hoặc chuỗi S3→S2 từ mèo đúng hiện tại; dựng bằng chứng, bỏ qua X/X đỏ |
| TECH-05 | UI controller | Action → event/view model; điều hướng Home/Puzzle/Results/Help/Settings |
| TECH-06 | Save repository | Một session hiện tại + progress độc lập, backup/atomic write |
| TECH-07 | Content pipeline | Validator, lọc trùng, `--release`, báo cáo biên tập |
| TECH-18 | Visual presenter | Ánh xạ nhãn vùng sang nền/viền/hàng tiến độ và `selectedAppearanceId` sang hình mèo/clip cho mọi ô `cat`, kể cả given; phát sprite sheet 2D, reduced motion; không chứa luật |
| TECH-20 | Cat asset manager | Nạp một bộ clip của giống đang chọn khi cần, dùng chung texture giữa các mèo, đổi bộ clip an toàn, giới hạn cache theo ngân sách RAM/VRAM |

## 3. Schema level v4

Gốc file là `{ "levels": [...] }`. Mỗi level có đúng các trường sau; tọa độ 0-based, chuỗi UTF-8. Fixture và campaign dùng cùng schema. Bỏ `chapter`; `order` là thứ tự toàn cục.

| Trường | Điều kiện |
| --- | --- |
| `schemaVersion` | Integer `4` |
| `id` | String duy nhất, ổn định, `[A-Z0-9_-]+` |
| `order` | Integer ≥1; release đúng 1..24, mỗi slot một level; fixture dùng thứ tự riêng, không đóng gói release |
| `size` | Integer 4..12; release 4..6 |
| `regions` | N chuỗi dài N, chỉ dùng đúng N nhãn `A..` liên tiếp, tối đa `L`, mỗi vùng liên thông 4 hướng |
| `givens` | Mảng `{r:int,c:int}`, không trùng hàng, thuộc nghiệm |
| `solution` | N cột, hoán vị `0..N-1`, thỏa bốn luật và nghiệm duy nhất |
| `difficulty` | `tutorial`, `easy`, `medium`, `hard`; release chưa dùng `hard` |
| `tags` | Mảng string không rỗng, không trùng; chỉ là metadata |
| `logicTrace` | Các bước S2/S3 tuần tự từ givens tới đủ N mèo; release order 1–18 chỉ S2, order 19–24 có S3 cần thiết |

Step S2 vẫn có đúng `rule`, `focus`, `conclusion`, `textKey`, ví dụ:

```json
{"rule":"S2","focus":{"type":"region","id":"A"},"conclusion":{"type":"place","r":0,"c":1},"textKey":"hint.single.region"}
```

Validator tính lại mọi ứng viên và nguồn loại trừ; không lưu `eliminatedCells` tự khai. `textKey` phải khớp focus row/column/region. `countSolutions` duyệt ràng buộc độc lập `solution`, dừng ở nghiệm thứ hai. Với N=12, validator phải có ngân sách thời gian rõ; level vượt ngân sách bị từ chối/biên tập lại, không coi timeout là nghiệm duy nhất.

Step S3 có đúng `rule`, `source`, `target`, `conclusion`, `textKey`; `source`/`target` là hai loại đơn vị khác nhau. `conclusion.cells` là toàn bộ tập ứng viên mới bị loại, dùng object tọa độ 0-based:

```json
{"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"}
```

Validator tự tính `P(source)` và `P(target)` từ cat đã chứng minh cùng tập loại trừ hiện hành; yêu cầu `P(source)` khác rỗng, nằm trọn trong target và `P(target) \ source` khác rỗng. Kết luận phải khớp chính xác tập loại mới theo thứ tự chuẩn, không lặp/no-op và không dùng `solution`, X hoặc `x_error` làm chứng cứ. S2 sau S3 được phép dựa trên tập loại trừ đã chứng minh.

Màu vùng là **theme mapping** từ nhãn A–L, không nằm trong level JSON. `cat` ở ô dùng `selectedAppearanceId` (mặc định ở bản đầu) để chọn hình mèo và clip, **không dùng nhãn vùng để chọn màu lông/giống mèo**. Nền/viền ô và hàng N vị trí tiến độ theo A–(N), có màu/nhãn/họa tiết vùng. Đổi palette hoặc mèo đang chọn không đổi nghiệm, trạng thái ô hoặc hash puzzle. Nhãn/họa tiết là kênh thông tin song song với màu.

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
  "sessionVersion": 2,
  "levelId": "L02",
  "puzzleHash": "<sha256 of canonical puzzle data>",
  "status": "playing",
  "cells": ["empty", "x", "x_error", "cat"],
  "hearts": 2,
  "mistakeCount": 1,
  "hintCount": 0,
  "elapsedMs": 84000
}
```

`cells` trên là ví dụ rút gọn; dữ liệu thật có N² ô theo hàng trước, cột sau. Given lưu `empty` trong session và được ghép từ level khi render. `hintCount` chỉ nhận `0` hoặc `1`; reload/Back To Home giữ giá trị, còn Retry/Restart tạo session lượt mới với `0`. `correctPlacedCount` được suy từ các ô `cat` không phải given; scorecard tính theo GR-18, không lưu hai nguồn điểm có thể lệch nhau. `puzzleHash` là SHA-256 của JSON compact UTF-8 cho `[size,regions,givens sắp theo (r,c),solution]`. Session sai hash/version/cell bất hợp lệ thì báo và tạo lại **cùng level**, không tiến level. `currentLevelId=null` nghĩa là hoàn thành toàn bộ nội dung hiện có. Khi append level mới, quét danh sách completed để xác định successor đầu tiên chưa xong. Không cho chọn ID đã qua trong UI.

| ID | Quy tắc |
| --- | --- |
| TECH-08 | Preview X/kéo và khe Undo chỉ tồn tại trong runtime; sau action đã xác nhận và đổi board/tim/hint, ghi session trước phản hồi bền vững. Preview/khe Undo không lưu. Back To Home/app đóng xóa khe dù session board vẫn được giữ. |
| TECH-09 | Progress tách session; session hỏng không xóa completed/results. Progress chính hỏng thử bản hợp lệ trước, không ghi đè bằng trống. |
| TECH-10 | Kiểm version/hash khi load; chỉ cần migration save cũ sau khi có bản game đã phát hành. |
| TECH-11 | Không dữ liệu cá nhân hoặc truyền analytics mạng trong bản đầu. |
| TECH-12 | ID/puzzle đã phát hành bất biến; thêm level ở cuối, không chèn giữa level đã phát hành nếu chưa có migration thứ tự. |

## 5. API và sự kiện

```text
validateLevel(level) -> ValidationResult
countSolutions(regions,givens,limit=2) -> 0 | 1 | 2
createSession(level) -> Session
applyAction(level,session, MarkX(cell) | ClearX(cell) | MarkStroke(mode,cells) | TryCat(cell) | UndoX | RestartLevel) -> {session,events}
getHint(level,session) -> HintEvidence | NoHint
completeLevel(level,session) -> Progress | Error
```

Gesture layer quyết định một chạm/chạm đôi/nét kéo; core không đo thời gian chạm. UI áp preview từ bản sao trạng thái đã commit, rồi gửi action sau khi rõ cử chỉ. `MarkStroke` nhận danh sách ô đã đi qua theo thứ tự, loại trùng, áp cùng chế độ `mark` hoặc `clear` từ ô đầu; core bỏ qua các ô không hợp lệ và commit toàn bộ trong một transaction. Bắt đầu trên X đỏ/cat/given không mở nét. Một action X lưu đúng diff vào khe Undo runtime; `UndoX` hoàn nguyên toàn diff rồi làm rỗng khe. `TryCat` xóa khe trước khi chấm, nên không thể Undo xuyên qua. `RestartLevel` chỉ chạy sau xác nhận UI và tạo session mới cùng level. Core trả `XMarked`, `XCleared`, `XUndoApplied`, `SessionRestarted`, `CatPlaced(region)`, `Mistake(reason)`, `HeartLost`, `ScoreChanged`, `LevelWon`, `LevelFailed`. UI/animation chỉ dùng event; `x_error` là ô bất biến trong lượt. Input bị khóa trong chuyển result. Với action thắng, service commit progress trước `LevelWon`; nếu ghi lỗi, giữ state cũ và báo thử lại. Scorecard được tính từ board/lỗi, nên save và Result có một nguồn chuẩn.

Trình nhận cử chỉ chỉ chấp nhận ngón `event.index == 0` nếu điểm đầu ở trong bàn, rồi giữ ID này đến khi nhấc; bỏ qua mọi ngón phụ và điểm chạm bắt đầu ngoài bàn. Đây là chặn multi-touch/ngón phụ, không phải thuật toán nhận dạng palm đầu tiên trong bàn. Sau khi nhấn, X preview xuất hiện trong khung hình đầu. Chuyển sang kéo khi độ dịch chuyển từ điểm đầu vượt **12 điểm logic** sau quy đổi UI scale; các ô cắt bởi đoạn từ vị trí trước đến vị trí mới được lấy bằng phép quét lưới phủ đủ ô trung gian. Mỗi ô chỉ được ghé một lần. Sau chạm đầu đã nhấc, mở cửa sổ **280 ms đến lần chạm xuống thứ hai**. Nếu lần hai ở cùng ô và cả hai lần không vượt ngưỡng kéo, hoàn tác preview chạm đầu rồi gọi một `TryCat`. Chạm khác ô commit chạm đầu trước khi mở cử chỉ mới. Chạm thứ hai thành nét kéo cũng commit chạm đầu; nét hai lấy chế độ từ ô đầu **sau commit**, không gọi `TryCat`. Cửa sổ/ngưỡng là cấu hình cần playtest, không phụ thuộc hoàn toàn vào cờ `double_tap` của hệ điều hành; [Godot cung cấp `index` và `double_tap` trên sự kiện chạm](https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html). App nền/chuyển màn commit chạm đơn đã nhấc nhưng còn chờ; hủy preview của chạm/nét đang giữ. Có thể nhận action ngữ nghĩa riêng từ trình đọc màn hình.

## 6. Ngân sách và cổng kỹ thuật

| ID | Yêu cầu |
| --- | --- |
| TECH-13 | Mở level dưới 2 giây sau startup trên thiết bị mục tiêu M0. |
| TECH-14 | X preview hiện trong khung hình đầu, mục tiêu dưới 50 ms; chạm đôi phản hồi dưới 100 ms sau chạm thứ hai và save thành công. Nét kéo xem được từng X ngay khi đi qua ô. |
| TECH-15 | Action đã báo lưu phải khôi phục sau app bị tắt; thắng đã hiển thị phải mở level kế. |
| TECH-16 | CI chạy validator fixture/test và `--release` trên campaign; N>6 hoặc thiếu order chặn build bản đầu. |
| TECH-17 | Renderer/sprite không chứa luật; đổi asset/animation không đổi core. |
| TECH-19 | M0 đo bản sprite sheet trên Android/iPhone mục tiêu: FPS ≥55 khi tương tác, không có khựng hình >100 ms khi mèo nhảy/sticker xuất hiện, RAM/VRAM và thời gian tải nằm trong ngân sách thiết bị đã chọn. Nếu không đạt, giảm khung hình/kích thước atlas/hiệu ứng rồi đo lại. |
| TECH-21 | M0 đo một bộ clip mèo mặc định dùng trên mọi vùng; kiểm vùng vẫn phân biệt qua nền/nhãn/họa tiết, dung lượng texture thực và khựng khi nạp. Về sau đo đổi mèo, thu hồi gói cũ và khôi phục sau app nền trước khi mở bộ sưu tập. |

Ngưỡng M0 là mục tiêu thiết kế, cần ghi thiết bị cụ thể và số đo thật trước khi chốt. N=12 là trần dữ liệu, không được phát hành trước QA kích thước chạm **không zoom/pan**, màu/họa tiết, trace và hiệu năng. Kế hoạch meta và sinh level sau MVP ở [11](11-ke-hoach-meta-va-sinh-level.md); chưa thêm trường wallet/generator/nguồn Hint ngoài lượt vào schema v4 hoặc progress v2.

## 7. REV-TECH-05 — render một lần và quản lý bộ mèo

Ý tưởng render một lần trong Godot **khả thi cho ảnh tĩnh**: `SubViewport.UPDATE_ONCE` cập nhật render target một lần rồi dừng. Một ảnh tĩnh không chứa được động tác nhảy/ngủ; muốn cache cả animation phải render **từng frame của từng clip** rồi giữ nhiều texture. `ViewportTexture` còn cần viewport sống và texture vẫn chiếm bộ nhớ; việc lấy frame bằng `Texture2D.get_image()` đọc dữ liệu từ GPU có thể gây chậm. Vì vậy runtime bake toàn bộ clip 3D lúc mở app hoặc mỗi lần đổi giống chỉ là nhánh thử nghiệm sau này, không là pipeline đã chốt. [Godot SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html), [Texture2D.get_image](https://docs.godotengine.org/en/stable/classes/class_texture2d.html).

Pipeline đã chốt cho bản đầu và nền tảng bộ sưu tập mèo về sau:

1. Render offline **một bộ clip cho mỗi mèo thực sự khác hình dáng/động tác**. Màu/nhãn/họa tiết vùng là lớp UI riêng; không tạo atlas mèo riêng cho A–L hoặc dùng shader vùng trên lông mèo. Mặt nạ chỉ dùng nếu một biến thể ngoại hình của chính mèo đó cần đổi màu.
2. M0 chỉ có mèo mặc định. Tải bộ clip khi vào màn cần hoạt ảnh, dùng chung một resource giữa các ô và màn; icon nhỏ có bản gọn. Không nạp trước mọi clip độ phân giải cao nếu chưa hiển thị.
3. Khi mở bộ sưu tập, `selectedAppearanceId` trỏ tới gói asset của mèo đã sở hữu. Nạp gói mới bằng [ResourceLoader.load_threaded_request](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html); chỉ gọi `load_threaded_get` sau khi trạng thái báo đã tải xong để tránh chặn luồng chính. Giữ hình cũ cho đến khi gói mới sẵn sàng, rồi đổi tất cả presenter tại một điểm chuyển an toàn. Gói đang chọn được dùng lại trong phiên. Gói cũ được thả tham chiếu khi vượt ngân sách; không hứa giữ mọi mèo đến lúc tắt app. [Resource của Godot được cache khi còn tham chiếu và có thể được giải phóng khi không còn dùng](https://docs.godotengine.org/en/stable/classes/class_resource.html).
4. Nếu thiếu asset, lỗi nạp hoặc app khôi phục sau khi hệ điều hành thu hồi tài nguyên đồ họa, dùng mèo mặc định và báo nhẹ ở màn chọn; không làm hỏng level/session. Cache chỉ là tối ưu trong RAM/VRAM, không là nguồn dữ liệu tiến trình.

Khóa cache đề xuất là `(appearanceId, assetVersion, clip, resolutionTier)`; **màu vùng không nằm trong khóa** vì vùng là lớp UI độc lập. `appearanceId` và danh sách mèo đã mua thuộc phiên bản **progress tương lai**, không thêm vào level schema v4/session v2 hiện tại. Việc chọn mèo không thay bốn luật, tim, điểm hoặc màu nhận diện vùng. Với atlas RGBA8, 2048² pixel chiếm khoảng 16 MiB và 4096² khoảng 64 MiB trước mipmap/buffer khác; dung lượng file nén không phải dung lượng VRAM thực. M0 phải chọn thiết bị thấp mục tiêu và công bố ngân sách/đo thật, không dùng tỷ lệ tiết kiệm 85% trong review như kết quả đã chứng minh. [Tài liệu import texture của Godot](https://docs.godotengine.org/en/stable/classes/class_resourceimportertexture.html) phân biệt kích thước file với bộ nhớ texture và khuyến nghị chế độ VRAM Compressed cho 3D, nên M0 cần thử các chế độ phù hợp cho sprite 2D thay vì mặc định chọn một chế độ nén.

Meta sau MVP thêm `purchasedAppearanceIds`/`selectedAppearanceId` vào progress, wallet/ledger và trạng thái session chờ cứu lượt theo [11](11-ke-hoach-meta-va-sinh-level.md). Những trường này không thuộc level schema v4. Giao dịch cứu lượt phải khôi phục nguyên tử cả chi vàng hoặc xác nhận thưởng quảng cáo và tim/ô sai cuối; không được có trạng thái trừ tiền mà vẫn thua, hoặc cấp tim hai lần. Adapter quảng cáo chỉ báo đã thưởng sau xác nhận thành công, và không ảnh hưởng luồng Retry offline.

Nếu về sau có nhiều phụ kiện tạo số tổ hợp quá lớn để render offline, làm spike riêng cho **một avatar/sticker được chọn**: render tĩnh một lần bằng `SubViewport.UPDATE_ONCE` hoặc bake các frame cần thiết khi đổi tổ hợp, đo thời gian đổi, readback, RAM/VRAM và khôi phục app. Chỉ chuyển pipeline khi nhánh đó qua QA-51 trên thiết bị thật; gameplay luôn có bộ sprite đóng gói sẵn để dùng nếu bake không hoàn tất.
