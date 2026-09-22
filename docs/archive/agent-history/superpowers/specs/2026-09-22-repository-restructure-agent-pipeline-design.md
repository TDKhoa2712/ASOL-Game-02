> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.

# Thiết kế tái cấu trúc repository và pipeline làm việc cho agent

**Ngày:** 2026-09-22  
**Dự án:** ASOL-Game-02  
**Trạng thái:** Thiết kế hội thoại đã được duyệt; đang chờ duyệt bản đặc tả thành văn  
**Phạm vi:** Tổ chức repository, thẩm quyền tài liệu, pipeline work package cục bộ, baseline Git và đổi tên thư mục an toàn

## 1. Mục đích

Tái cấu trúc dự án hiện chỉ có tài liệu thiết kế thành một repository chuyên nghiệp mà con người hoặc bất kỳ coding agent nào cũng có thể đọc hiểu và vận hành, không phụ thuộc vào skill riêng của Codex, dịch vụ quản lý issue bên ngoài hoặc quy ước không được ghi thành văn.

Thành công có nghĩa là:

- Thiết kế canonical, governance, review hiện hành, hồ sơ lịch sử, hợp đồng công việc và bằng chứng thực thi nằm ở những vị trí có vai trò và thẩm quyền tách biệt rõ ràng.
- Con người giao đúng một mã work package; agent không được tự nhận công việc không liên quan.
- Repository có thể kiểm tra metadata của package, dependency, tham chiếu requirement/QA, link nội bộ, phạm vi đường dẫn, bằng chứng kiểm chứng và mức độ hoàn chỉnh của handoff chỉ bằng Python standard library.
- Các kiểm tra GDD hiện có tiếp tục chạy đạt.
- Tài liệu lịch sử độc nhất vẫn có thể khôi phục, còn cache sinh tự động và artifact trùng được loại bỏ.
- Thư mục dự án cuối cùng là `D:\Work\Alpaca_Solution\ASOL-Game-02`.

## 2. Ràng buộc và ngoài phạm vi

### Ràng buộc

- Giữ ổn định `GDD/` và các đường dẫn canonical bên trong.
- Dùng Markdown với TOML front matter cho work package.
- Pipeline agent chỉ dùng Python 3.11+ standard library; `tomllib` dùng để đọc metadata.
- Workflow phải độc lập nền tảng agent và hoạt động offline.
- Giữ lại tài liệu lịch sử độc nhất trong khu vực archive rõ ràng.
- Không âm thầm thay đổi luật gameplay, schema, tiến trình, điểm hoặc nội dung phát hành.
- Không ghi đè thư mục `ASOL-Game-02` nếu nó đã tồn tại khi đổi tên cuối cùng.

### Ngoài phạm vi

- Tạo project Godot hoặc triển khai game.
- Hoàn tất GDD v1.0 Design Freeze.
- Sản xuất campaign phát hành 24 level.
- Kích hoạt tính năng post-MVP, S4/S5, nội dung phát hành N>6, economy, quảng cáo, bộ sưu tập hoặc sinh level.
- Tích hợp hệ thống quản lý issue có hosting.

## 3. Cấu trúc repository đích

```text
ASOL-Game-02/
├─ README.md
├─ AGENTS.md
├─ CONTRIBUTING.md
├─ .gitignore
│
├─ GDD/
│  ├─ README.md
│  ├─ 01-tam-nhin-va-pham-vi.md
│  ├─ ...
│  ├─ 12-sinh-level-do-kho-va-endless.md
│  ├─ data/
│  └─ tools/
│
├─ docs/
│  ├─ governance/
│  ├─ reviews/
│  ├─ reports/
│  └─ archive/
│     ├─ reviews/
│     └─ agent-history/
│
├─ work/
│  ├─ README.md
│  ├─ packages/
│  ├─ state/
│  ├─ handoffs/
│  ├─ evidence/
│  └─ templates/
│
└─ tools/
   ├─ agent_pipeline.py
   ├─ reports/
   └─ tests/
```

Chủ ý chưa tạo `game/` cho đến khi package bootstrap M0 tạo một project Godot thực. Không tạo thư mục sản phẩm rỗng khiến người đọc hiểu nhầm rằng đã có tiến độ triển khai.

## 4. Thẩm quyền tài liệu

Tài liệu được chia thành sáu lớp thẩm quyền, theo thứ tự giảm dần khi quyết định triển khai:

1. **Thiết kế canonical:** `GDD/`
2. **Governance:** `docs/governance/`
3. **Hợp đồng công việc:** `work/packages/`
4. **Bằng chứng thực thi:** `work/evidence/` và `work/handoffs/`
5. **Review/tham chiếu hiện hành:** `docs/reviews/`
6. **Chỉ mang tính lịch sử:** `docs/archive/`

`docs/governance/document-register.toml` ghi nhận từng tài liệu được quản trị bằng các trường:

- `path`
- `class`
- `status`
- `owner`
- `superseded_by` không bắt buộc

Tài liệu archive là bằng chứng lịch sử bất biến. Chúng phải có thông báo `SUPERSEDED` hoặc `HISTORICAL` dễ thấy và trỏ tới nguồn hiện hành. Agent không được suy diễn requirement triển khai từ nội dung archive.

`GDD/12-sinh-level-do-kho-va-endless.md` tiếp tục nằm trong `GDD/` để ổn định đường dẫn nhưng được đăng ký ở trạng thái `PROPOSED/POST-MVP`. Work package chỉ được dùng tài liệu này khi `read_first` dẫn trực tiếp tới nó và phase hiện tại cho phép công việc post-MVP.

## 5. Entrypoint cho con người và agent

### `README.md`

Bản đồ dự án dành cho con người, giải thích trạng thái hiện tại, các khu vực trong repository, lệnh chính và thực tế rằng chưa có game chạy được.

### `AGENTS.md`

Entrypoint chung cho mọi agent phải ngắn gọn và chỉ chứa hành vi bắt buộc:

- Tuân theo thứ tự thẩm quyền.
- Chỉ làm package ID được giao.
- Chạy `inspect` trước khi sửa file.
- Không bao giờ dùng nội dung archive làm requirement hiện hành.
- Chỉ sửa trong `allowed_paths`.
- Chỉ thay luật, schema, tiến trình hoặc điểm qua package loại `design-change`.
- Chạy `verify` và tạo handoff hợp lệ trước khi báo hoàn tất.
- Tạo asset và level gốc; không sao chép nội dung game thương mại.

Hướng dẫn riêng của từng công cụ có thể bổ sung cho hợp đồng này nhưng không được ghi đè thẩm quyền repository hoặc phạm vi package.

### `CONTRIBUTING.md`

Hướng dẫn đóng góp giải thích cách đặt tên branch, quyền sở hữu trạng thái package, validation, review, quy ước commit và cách con người tạo hoặc phê duyệt package.

## 6. Hợp đồng work package

Mỗi package là một file Markdown có TOML front matter mở đầu và kết thúc bằng `+++`.

Các trường bắt buộc:

```toml
+++
id = "M0-A01"
title = "Godot toolchain and device baseline"
kind = "implementation"
phase = "M0"
status = "ready"
depends_on = []
requirements = ["D-06", "TECH-13", "TECH-19"]
qa = ["QA-26", "QA-30"]
read_first = [
  "GDD/README.md",
  "GDD/02-luat-choi-va-trang-thai.md",
  "GDD/05-kien-truc-va-du-lieu.md",
]
allowed_paths = ["game/**", "work/evidence/M0-A01/**"]
deliverables = ["game/project.godot"]
out_of_scope = ["production content", "wallet", "ads", "S4", "S5"]
+++
```

Phần Markdown mô tả mục tiêu, acceptance criteria, lệnh kiểm chứng chính xác, bằng chứng cần có, rủi ro đã biết và trọng tâm review. Lệnh validation được biểu diễn bằng mảng đối số tiến trình trong TOML thay vì chuỗi lệnh shell.

`status` trong package là trạng thái catalog do coordinator quản lý trước khi thực thi (`draft` hoặc `ready`). Sau khi `start` tạo `work/state/<id>.toml`, file state trở thành nguồn chuẩn cho trạng thái hiệu lực có thể thay đổi (`in_progress`, `blocked`, `review` hoặc `done`), còn hợp đồng package vẫn giữ `ready`. `list` và kiểm tra dependency luôn giải quyết theo quy tắc này; không yêu cầu sửa hai file cùng lúc.

Các giá trị `kind` được hỗ trợ:

- `implementation`
- `content`
- `research`
- `design-change`
- `governance`

Package implementation không được sửa `GDD/`, `docs/governance/`, `AGENTS.md` hoặc mã pipeline trừ khi các đường dẫn đó được một package governance cho phép rõ ràng. Package `design-change` thay luật, schema, tiến trình hoặc điểm phải khai báo đồng bộ các đường dẫn GDD, fixture, validator/test và QA liên quan.

## 7. Trạng thái thay đổi và handoff

Hợp đồng package được giữ ổn định. Trạng thái thực thi thay đổi nằm ở `work/state/<id>.toml` và chứa:

- agent được giao
- trạng thái vòng đời
- tên branch
- base revision
- thời điểm bắt đầu/cập nhật
- nguyên nhân bị chặn khi có

Handoff nằm tại `work/handoffs/<id>.md` và phải gồm:

- package ID và agent
- requirement đã đáp ứng
- QA đã bao phủ
- file đã thay đổi
- lệnh validation và kết quả
- đường dẫn bằng chứng
- rủi ro và giới hạn còn lại
- kết luận của reviewer

Log và số đo được chọn làm bằng chứng nằm trong `work/evidence/<id>/` và được commit khi chúng hỗ trợ nghiệm thu. Output thô tạm thời tiếp tục bị ignore. Pipeline không được thu thập toàn bộ environment, secret, token hoặc thông tin hệ thống không liên quan.

## 8. Vòng đời và quyền sở hữu

```text
con người giao việc
      ↓
inspect dependency, authority, scope và danh sách cần đọc
      ↓
start ghi agent, branch và base revision
      ↓
triển khai trong allowed_paths
      ↓
verify chạy kiểm tra và xem Git diff
      ↓
handoff ghi bằng chứng và rủi ro còn lại
      ↓
reviewer chấp nhận hoặc từ chối
      ↓
done hoặc quay lại in_progress
```

Các chuyển trạng thái hợp lệ:

- `draft → ready`: chỉ owner/coordinator
- `ready → in_progress`: agent được giao sau khi kiểm dependency và Git
- `in_progress → review`: agent được giao sau khi kiểm chứng đạt và handoff đầy đủ
- `review → done`: chỉ reviewer/coordinator
- `review → in_progress`: reviewer từ chối và ghi lý do
- `in_progress → blocked`: agent được giao phải ghi blocker cụ thể và bằng chứng
- `blocked → in_progress`: coordinator sau khi blocker được giải quyết

Không có lệnh chọn hoặc tự nhận package tiếp theo. Con người cung cấp package ID.

Mỗi package dùng branch `work/<package-id>-<slug>`. Bình thường `start` yêu cầu working tree sạch và ghi lại commit hiện tại. Tiến trình Git dùng `-c safe.directory=<resolved-repository-root>` cho đúng repository đó để khác biệt ownership của sandbox không buộc thay cấu hình Git toàn cục. Khi môi trường bị giới hạn không thể tạo branch, handoff phải ghi rõ giới hạn này và coordinator chịu trách nhiệm tích hợp.

## 9. CLI của agent pipeline

Entrypoint zero-dependency là `python tools/agent_pipeline.py`.

Các lệnh:

```text
validate
doctor
list --status <status>
trace <requirement-id>
inspect <package-id>
start <package-id> --agent <name>
verify <package-id>
handoff <package-id>
accept <package-id>
```

Trách nhiệm:

- `validate`: kiểm metadata repository mà không thay đổi file.
- `doctor`: chạy kiểm tra cấu trúc cho tài liệu, package, link, protected path và artifact bị cấm.
- `list`: hiển thị package theo trạng thái vòng đời.
- `trace`: tìm requirement canonical, QA liên quan, quyết định và package đang sử dụng mã đó.
- `inspect`: in phạm vi package, dependency, danh sách cần đọc, deliverable, lệnh kiểm tra và nội dung loại trừ.
- `start`: kiểm assignment/dependency/trạng thái Git và tạo mutable state.
- `verify`: chạy các tiến trình validation đã khai báo, lưu bằng chứng gọn và so diff với `allowed_paths`.
- `handoff`: nếu chưa có thì tạo handoff skeleton và trả mã lỗi; nếu đã hoàn chỉnh thì kiểm tra và chuyển state đủ điều kiện sang review. Lệnh không bao giờ cho handoff chưa hoàn chỉnh đi tiếp.
- `accept`: kiểm điều kiện reviewer và đánh dấu package hoàn tất.

Mọi lệnh đều fail closed. Khi lỗi, chúng trả exit code khác 0 và nêu rõ file, trường cùng cách sửa. Chúng không âm thầm chuẩn hóa contract sai hoặc mở rộng scope.

## 10. Quy tắc validation

Validation repository bao phủ:

- Cú pháp TOML và trường package bắt buộc.
- Package ID duy nhất và enum hợp lệ.
- Dependency tồn tại và đồ thị dependency không có chu trình.
- Dependency đã hoàn tất trước khi `start`.
- Chuyển trạng thái hợp lệ.
- Requirement ID (`D`, `GR`, `UX`, `LV`, `TECH`, `ART`, `DEC`) được định nghĩa bởi tài liệu có thẩm quyền.
- QA ID được định nghĩa bởi `GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md`.
- Link Markdown nội bộ.
- Không còn `file:///`, `ASOL-Game-03` và link tuyệt đối phụ thuộc workspace trong tài liệu hiện hành.
- `allowed_paths` là đường dẫn tương đối đã chuẩn hóa và không thể thoát khỏi repository.
- Git diff chỉ nằm trong `allowed_paths`.
- Quy tắc protected path theo package kind.
- Lệnh validation được biểu diễn bằng mảng đối số.
- Handoff đầy đủ và bằng chứng tồn tại.
- Không có Python cache, Godot cache, Repomix snapshot, báo cáo trùng hoặc artifact sinh tự động chưa được cho phép.

## 11. Backlog ban đầu

Lần tái cấu trúc chỉ seed công việc đã có đủ thẩm quyền để mô tả trung thực:

| ID | Trạng thái sau tái cấu trúc | Mục đích |
| --- | --- | --- |
| `SETUP-001` | `done` sau nghiệm thu | Tái cấu trúc repository và agent pipeline |
| `M0-A01` | `ready` | Baseline phiên bản Godot, renderer, thiết bị, OS và toolchain |
| `M0-A02` | `draft` | Prototype gesture và interaction |
| `M0-A03` | `draft` | Spike sprite, bố cục bàn và hiệu năng mobile |
| `M0-GATE` | `draft` | Review bằng chứng M0 và phê duyệt hoặc từ chối chuyển sang M1 |

Các package tương ứng với công việc GDD/08 về sau vẫn ở mức khái niệm cho đến khi dependency và ownership sẵn sàng. Pipeline không chuyển toàn bộ công việc tương lai sang `ready` chỉ vì chúng xuất hiện trong một kế hoạch.

## 12. Dọn dẹp và migration

### Giữ lại và di chuyển

```text
design-control/          → docs/governance/
design-control/reviews/  → docs/reviews/
design-reviews/          → docs/archive/reviews/
docs/superpowers/        → docs/archive/agent-history/superpowers/
.superpowers/sdd/        → docs/archive/agent-history/superpowers-sdd/
GDD/tools/generate_game_design_report.py
                         → tools/reports/generate_game_design_report.py
docs/Bao_Cao_...docx     → docs/reports/Bao_Cao_...docx
```

### Xóa sau baseline commit

- DOCX trùng ở root.
- `meowdoku-clone.xml`, một Repomix snapshot có thể tái tạo.
- `__pycache__/` và `*.pyc`.
- Thư mục trạng thái công cụ trống sau khi hồ sơ độc nhất đã được archive.

### Ignore về sau

`.gitignore` bao phủ Python cache, `.codegraph/`, Godot `.godot/`, artifact export/build, Repomix snapshot, file tạm và evidence tạm thời chưa được chủ động chọn cho handoff.

Mọi link hiện hành được cập nhật sau khi di chuyển. Tài liệu lịch sử có thể giữ đường dẫn cũ được trích dẫn khi được đánh dấu rõ là lịch sử; chúng không được dùng đường dẫn cũ làm tuyến điều hướng chính.

## 13. Git và đổi tên thư mục

Repository ghi một baseline commit trước tái cấu trúc. Cấu trúc mới và pipeline đã được kiểm chứng nằm trong một commit riêng.

Chỉ đổi tên thư mục sau khi hoàn tất mọi thay đổi repository, kiểm thử và commit:

1. Resolve đường dẫn tuyệt đối của source và target.
2. Xác nhận source chính xác là `D:\Work\Alpaca_Solution\ASOL-Game-03`.
3. Xác nhận target chính xác là `D:\Work\Alpaca_Solution\ASOL-Game-02` và chưa tồn tại.
4. Đổi tên từ thư mục cha chung bằng `Move-Item -LiteralPath` native của PowerShell.
5. Không ghi thêm dữ liệu từ phiên workspace cũ.
6. Mở lại dự án tại đường dẫn mới.

Không bao giờ ghi đè hoặc gộp vào target directory đã tồn tại.

## 14. Chiến lược kiểm thử

`tools/tests/test_agent_pipeline.py` dùng `unittest` và repository tạm để kiểm:

- TOML front matter hợp lệ và sai cú pháp
- thiếu trường bắt buộc và ID trùng
- dependency không tồn tại và dependency cycle
- chuyển trạng thái trái phép
- requirement và QA không tồn tại
- link nội bộ hỏng và đường dẫn tuyệt đối lỗi thời
- path traversal và `allowed_paths` quá rộng
- package implementation thay protected path
- lệnh validation dạng chuỗi shell không hợp lệ
- handoff thiếu nội dung và bằng chứng không tồn tại
- Git dirty, base revision sai và diff ngoài scope

Tập lệnh kiểm chứng cuối cùng:

```text
python GDD/tools/validate_levels.py GDD/data/levels.sample.json
python -m unittest discover GDD/tools -p "test_*.py" -v
python -m unittest discover tools/tests -p "test_*.py" -v
python tools/agent_pipeline.py doctor
python tools/agent_pipeline.py inspect SETUP-001
python tools/agent_pipeline.py inspect M0-A01
```

## 15. Điều kiện hoàn tất

Tái cấu trúc chỉ hoàn tất khi:

- Có baseline commit và commit tái cấu trúc đã kiểm chứng.
- Root chỉ chứa entrypoint rõ ràng và các thư mục phân theo vai trò.
- Không còn báo cáo trùng, cache hoặc Repomix snapshot.
- Link nội bộ hiện hành và document register hợp lệ.
- Validator level và toàn bộ 23 unit test hiện có chạy đạt.
- Test pipeline mới chạy đạt.
- `doctor`, `inspect SETUP-001` và `inspect M0-A01` chạy thành công.
- `SETUP-001` có handoff và bằng chứng đầy đủ.
- Không triển khai game hoặc thay đổi luật gameplay.
- Thư mục dự án được đổi tên an toàn thành `ASOL-Game-02` và workspace được mở lại tại đó trước khi tiếp tục công việc.
