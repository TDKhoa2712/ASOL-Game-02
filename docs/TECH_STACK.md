# CanDoKu — Technical stack

> Mô tả công nghệ đang dùng, công nghệ mục tiêu và cổng kỹ thuật của dự án. Cập nhật: 2026-10-01.

## 1. Quy ước trạng thái

| Nhãn | Ý nghĩa |
| --- | --- |
| Hiện hành | Có trong repository và đang được runtime/tool sử dụng |
| Đã kiểm | Có bằng chứng kiểm tra ở revision cụ thể trong [STATUS](STATUS.md) |
| Mục tiêu | Được thiết kế cho bản playtest hoặc bản chính thức nhưng chưa đủ bằng chứng |
| Chưa cấu hình | Có khung/preset nhưng thiếu thông tin hoặc môi trường để dùng |

Sự tồn tại của file cấu hình không chứng minh build thiết bị đã thành công. Số phiên bản và kết quả mới nhất luôn lấy từ STATUS/evidence.

## 2. Bảng công nghệ

| Lớp | Công nghệ | Trạng thái | Vai trò |
| --- | --- | --- | --- |
| Game engine | Godot 4.x; đã kiểm với 4.7.2 | Hiện hành, đã kiểm headless | Scene tree, input, UI, render 2D, export mobile |
| Ngôn ngữ runtime | GDScript | Hiện hành | Flow, domain state, save, settings, UI, test Godot |
| Ngôn ngữ tooling | Python 3.11+ | Hiện hành | Validator, generator offline, test contract, verification runner |
| Định dạng dữ liệu | JSON UTF-8 | Hiện hành | Campaign, level, interaction vectors, save/session, cấu hình Home |
| UI | Godot `Control`, scene `.tscn`, vẽ `_draw()` | Hiện hành | Layout responsive, board, modal và result screens |
| Renderer | Godot Mobile renderer | Hiện hành | Render 2D cho desktop kiểm thử và mobile mục tiêu |
| Asset | SVG/PNG gốc, Godot import metadata | Hiện hành | Kẹo, tim, icon và probe kỹ thuật |
| Version control | Git; `dev` là nền tích hợp | Hiện hành | Lịch sử, branch ngắn, evidence theo revision |
| Build target | Android arm64, iOS | Preset debug có sẵn; QA thiết bị chưa đủ | Bản playtest và bản chính thức sau khi đạt cổng |
| Hosted services | Không có | Chủ ý | Game offline; không account, backend hoặc analytics mạng |

## 3. Runtime Godot

### 3.1 Project configuration

Nguồn: [`game/project.godot`](../game/project.godot).

| Thuộc tính | Giá trị hiện hành |
| --- | --- |
| Tên hiển thị | `CanDoKu` |
| Entry scene | `res://scenes/bootstrap.tscn` |
| Logical viewport | 1080×1920 |
| Window kiểm desktop | 540×960 |
| Stretch | `canvas_items`, aspect `expand` |
| Orientation | Portrait |
| Renderer | `mobile` |
| Mobile texture compression | ETC2/ASTC import bật |
| Custom user directory | `Godot/app_userdata/ASOL Game 02` |
| App icon hiện tại | Asset kẹo SVG |

Đường dẫn user data cũ được giữ có chủ đích để không làm mất save khi đổi tên hiển thị sang CanDoKu.

### 3.2 Scene và resource

- `.tscn` giữ cây node, layout và resource link.
- `.gd` giữ logic runtime và test Godot.
- `.uid` được commit để resource identity ổn định.
- `.import` được commit cho asset đang dùng; thư mục `game/.godot/` là cache local và bị ignore.
- UI đích dùng tọa độ logic và `Control`, không buộc kích thước vật lý cụ thể.

### 3.3 GDScript conventions

- Module domain được khởi tạo bằng `.new()` và truyền dependency rõ tại bootstrap/runtime.
- Signal truyền thay đổi lên coordinator; view không sở hữu progress toàn cục.
- Dữ liệu level/session dùng `Dictionary`/`Array` để tương thích JSON.
- Các validator từ chối field thiếu hoặc thừa thay vì bỏ qua im lặng.
- Script test chạy độc lập bằng `godot --headless --path game --script res://tests/run_*.gd`.

## 4. Python tooling

Python tooling chủ yếu dùng standard library; không có dependency runtime của game.

| Thành phần | File chính | Chức năng |
| --- | --- | --- |
| Level validator | `GDD/tools/validate_levels.py` | Schema v4, vùng, nghiệm duy nhất, trace, logic band và campaign gate hiện hành |
| Offline generator | `GDD/tools/generate_levels.py` | Sinh ứng viên N=4–6 theo seed/profile và budget |
| Reasoning/rating | `GDD/tools/level_reasoning.py` | S2/S3, evidence graph, rating-0 và canonical puzzle key |
| Pilot report | `GDD/tools/pilot_report.py` | Report biên tập, phiếu mù và CSV playtest |
| Multi-seed experiment | `GDD/tools/run_generation_experiment.py` | Đo feasibility qua nhiều seed; không hiệu chỉnh difficulty người chơi |
| Verification runner | `tools/verify.py` | Chạy Python, validator và toàn bộ `run_*.gd`; ghi evidence |
| GDD Word exporter | `tools/reports/generate_game_design_report.py` | Tùy chọn; cần `python-docx`, Markdown vẫn là nguồn chuẩn |

`python-docx` chỉ cần khi xuất Word, không cần để chạy game, validator, generator hoặc full verification.

## 5. Dữ liệu và schema

### 5.1 Level schema v4

Một level gồm đúng các field:

```json
{
  "schemaVersion": 4,
  "id": "L01",
  "order": 1,
  "size": 4,
  "regions": ["AABB", "ACCB", "ADDB", "CCDD"],
  "givens": [{"r": 0, "c": 1}],
  "solution": [1, 3, 0, 2],
  "difficulty": "tutorial",
  "tags": [],
  "logicTrace": []
}
```

Ví dụ trên chỉ minh họa shape của schema; level thực phải qua validator. Trần schema là N=12, nhưng playtest 30 level chỉ dùng N=4–6.

### 5.2 Campaign

Runtime hiện đọc [`game/data/campaign_m1.json`](../game/data/campaign_m1.json), chứa bốn level R1. `MvpRuntime` có thể nhận đường dẫn campaign khác qua constructor, vì vậy bản playtest có thể dùng file campaign riêng mà không đổi schema level.

Validator `--release` hiện áp cổng legacy 24 level. Đây là trạng thái hiện tại, không phải cổng đúng cho playtest 30 level. Trước khi nghiệm thu campaign mới cần một profile/gate 30 level rõ ràng; không sửa số 24 thành 30 mà bỏ qua logic band và QA.

### 5.3 Persistence

| Dữ liệu | Phiên bản | Mục đích |
| --- | ---: | --- |
| Progress | 2 | Level hiện tại, level hoàn thành và kết quả |
| Session | 3 | Trạng thái lượt, hash puzzle, tim, lỗi, Hint, thời gian và tutorial |
| Settings | 1 | Audio, haptic, reduced motion, high contrast, large text |

Session v2 được đọc qua `legacy_session_migration.gd`; lần lưu bình thường tiếp theo ghi session v3. Progress/level ID và puzzle hash phải ổn định khi mở rộng campaign.

## 6. Asset pipeline

- Asset sản phẩm phải là tác phẩm gốc.
- SVG là nguồn vector chỉnh trực tiếp cho kẹo, tim và icon phù hợp.
- PNG dùng cho icon raster hiện hành.
- Godot tạo texture import trong `.godot/imported`; cache này không commit.
- `game/assets/spike/` là tài sản probe kỹ thuật, không phải bằng chứng mỹ thuật cuối.
- Không dùng model 3D, rig hoặc animation middleware trong scope hiện tại.

Trước khi sản xuất asset hàng loạt cho 30 level, phải đo atlas/texture đại diện trên thiết bị mục tiêu theo TECH-19 của GDD 05.

## 7. Build và nền tảng

Nguồn: [`game/export_presets.cfg`](../game/export_presets.cfg).

### Android

- Preset: `Android M0 Debug`.
- Package ID: `org.asol.game02`.
- Tên package: `CanDoKu`.
- Kiến trúc bật: `arm64-v8a`.
- Đường dẫn output mặc định: `game/build/android/asol-game-02-debug.apk`.
- Thư mục build bị ignore.

Preset không chứng minh Android SDK/JDK/export template hoặc thiết bị đã sẵn sàng. STATUS ghi lần QA thiết bị gần nhất.

### iOS

- Preset: `iOS M0 Debug`.
- Bundle ID: `org.asol.game02`.
- Team ID đang trống.
- Preset chưa runnable trong môi trường hiện tại.

Cần Mac, Xcode, signing và thiết bị iOS trước khi tuyên bố hỗ trợ phát hành.

## 8. Kiểm thử và quality gate

Lệnh chuẩn:

```powershell
rtk python -B tools/verify.py --godot "<duong-dan-Godot>"
```

Runner thực hiện:

1. kiểm phiên bản/executable Godot;
2. test Python trong `game/tests`;
3. test Python trong `GDD/tools`;
4. test chính runner trong `tools/tests`;
5. validate campaign hiện hành và fixture level;
6. discovery và chạy mọi `game/tests/run_*.gd`;
7. ghi revision, working diff và source fingerprint vào `scratch/verification/`.

Exit `0` chỉ chứng nhận các bước headless đã chạy đều đạt. Nó không chứng nhận layout, gesture cửa sổ thật, Android/iOS, playtest hoặc release readiness.

### Test layers

| Lớp | Ví dụ | Mục tiêu |
| --- | --- | --- |
| Pure/domain | Puzzle core, session, hint, tutorial | Luật và transition xác định |
| Contract | Python/Godot interaction vectors | Hai implementation hiểu input/state giống nhau |
| Data validation | Level/campaign validators | Chặn schema, nghiệm hoặc trace sai |
| Scene smoke | Board, bootstrap, UI shell | Node path, wiring và startup |
| Flow/integration | Playable flow, save failure | Hành trình qua module và recovery |
| Visual/device | Capture, thao tác thật, Android/iOS | Layout, gesture, safe area và hiệu năng; không thay bằng headless |

Repository hiện chưa có workflow CI hosted được commit. Full runner là cổng local bắt buộc trước bàn giao/tích hợp code.

## 9. Dependency policy

- Không thêm package runtime nếu standard library hoặc Godot core đáp ứng đủ.
- Dependency mới phải có lý do, version, license và tác động Android/iOS.
- Không đưa token, credential, keystore hoặc signing secret vào Git.
- Build/evidence phải ghi revision thực tế; không dùng log của source khác.
- Công cụ optional không được biến thành điều kiện để chạy game.

## 10. Offline, privacy và security

CanDoKu hiện không có network client, backend, login hoặc analytics SDK. Save và playtest data ở local. Với bản playtest:

- không thu PII không cần thiết;
- mã người chơi dùng định danh ẩn danh;
- chia sẻ build/log phải loại đường dẫn hoặc thông tin nhạy cảm nếu có;
- crash reporting hoặc analytics mạng là thay đổi phạm vi, cần quyết định và consent riêng;
- file JSON từ bên ngoài phải qua validator trước khi đóng gói.

## 11. Tác động kỹ thuật của mốc 30 level

Các hạng mục cần làm trước bản playtest, chưa được coi là đã triển khai:

1. tạo profile nội dung order 1–30 và chốt band 25–30;
2. tạo campaign riêng, giữ ID/hash ổn định sau khi bắt đầu playtest;
3. thay cổng validator 24-level bằng gate có tên/phạm vi rõ cho playtest 30 level;
4. kiểm save/resume và kết thúc campaign với 30 ID;
5. đo thời gian load, RAM/VRAM và atlas trên thiết bị;
6. hoàn thiện audio/haptic hoặc ghi rõ vô hiệu hóa trong build;
7. chốt replay/terminal behavior cho cuối campaign;
8. cấu hình signing/export và kiểm build thật cho từng nền tảng;
9. giữ bản chính thức tách khỏi playtest cho đến khi có quyết định sau dữ liệu người chơi.

## 12. Thiết lập môi trường phát triển

Yêu cầu tối thiểu:

- Git;
- Godot 4.7.2 hoặc bản được dự án chốt thay thế;
- Python 3.11+;
- Android SDK/JDK/export templates nếu làm Android;
- macOS/Xcode/signing nếu làm iOS.

Khởi động local:

1. import [`game/project.godot`](../game/project.godot) trong Godot;
2. chạy F5 từ entry scene, không dùng F6 để thay kiểm full flow;
3. chạy full verification trước khi bàn giao code;
4. đọc [STATUS](STATUS.md) để biết giới hạn thiết bị và evidence mới nhất.
