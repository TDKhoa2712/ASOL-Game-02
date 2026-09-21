# MVP Game Design Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đồng bộ GDD, schema v4, fixture, validator/tests và hồ sơ design-control với các quyết định MVP đã duyệt về S3, Restart, Undo, Hint và tutorial.

**Architecture:** Giữ puzzle core tách khỏi gesture/UI. Schema v4 mở rộng proof trace bằng bước loại trừ S3 có máy kiểm; reference interaction reducer v2 mô hình hóa action đã commit, khe Undo runtime và hạn mức một Hint. GDD/QA là nguồn hợp đồng, Python chỉ là validator và mô hình tham chiếu cho runtime Godot tương lai.

**Tech Stack:** Markdown, JSON UTF-8, Python 3 standard library `unittest`; Godot 4.x/GDScript vẫn là runtime mục tiêu nhưng chưa có project runtime trong workspace.

**Spec:** `docs/superpowers/specs/2026-09-21-mvp-game-design-resolution-design.md`

## Global Constraints

- Campaign MVP có đúng 24 level N=4–6; Level 1 là tutorial duy nhất.
- Level 1–18 chỉ S1/S2; mỗi Level 19–24 phải cần ít nhất một bước S3.
- Schema mới là v4; không nhét S3 vào JSON v3.
- Ba tim và `x_error` khóa được giữ; Retry/Restart bắt đầu lại cùng level.
- Undo chỉ áp dụng action X gần nhất, không qua `TryCat`, không Redo và không lưu qua điều hướng/app restart.
- Mỗi lượt có một Hint miễn phí; `NoHint` không tiêu thụ; Restart/Retry cấp lượt mới.
- Điểm chỉ là scorecard tại Result; không có wallet, ads, điểm danh hoặc interface meta trong MVP.
- Mọi level, asset và câu chữ phải là nội dung gốc, không sao chép Meowdoku.
- Workspace hiện không có `.git`; mỗi task kết thúc bằng verification checkpoint thay vì commit.

## Review Focus

- S3 lặp/no-op hoặc khai thiếu ô loại phải bị validator từ chối, không âm thầm nhận trace.
- S2 sau S3 phải chấp nhận ô bị loại bởi tập `E` dù không có S1 witness trực tiếp.
- `TryCat` phải xóa khe Undo; Undo không được nhảy qua nó để hoàn tác X cũ.
- Back To Home giữ board nhưng xóa Undo; đóng/mở session không cấp lại Hint.
- `NoHint` không tiêu thụ lượt Hint, còn Hint có evidence tiêu thụ đúng một lần.

---

### Task 1: Cập nhật nguồn luật canonical và version GDD

**Files:**
- Modify: `GDD/README.md`
- Modify: `GDD/01-tam-nhin-va-pham-vi.md`
- Modify: `GDD/02-luat-choi-va-trang-thai.md`
- Modify: `GDD/03-luong-man-hinh-va-ux.md`
- Modify: `GDD/04-thiet-ke-level.md`
- Modify: `GDD/05-kien-truc-va-du-lieu.md`
- Modify: `GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md`
- Modify: `GDD/08-ke-hoach-trien-khai-cho-agent.md`
- Modify: `GDD/09-ra-soat-thiet-ke.md`
- Modify: `GDD/10-nghien-cuu-quy-tac-suy-luan.md`
- Modify: `GDD/11-ke-hoach-meta-va-sinh-level.md`

**Interfaces:**
- Consumes: quyết định trong spec đã duyệt.
- Produces: baseline GDD v0.5.0 nhất quán; mã GR/LV/TECH/QA cho code và fixture ở các task sau.

- [ ] **Step 1: Nâng snapshot lên GDD v0.5.0 nhưng không tuyên bố Design Freeze**

Trong `GDD/README.md`, đổi phiên bản thành `0.5.0`, ngày `2026-09-21`, trạng thái “đặc tả ứng viên cho GDD v1.0; còn cổng bằng chứng M0/M2”. Cập nhật bảng quyết định:

- D-02: Level 1–18 S1/S2; Level 19–24 bắt buộc S3; S4/S5 parked.
- D-04: bổ sung Restart và Undo X một bước.
- D-05: điểm chỉ hiện Result; mỗi lượt có một Hint miễn phí.
- D-08: giữ ba tim, `x_error` khóa và Retry reset toàn bộ.
- D-09/D-10: meta, ads, điểm danh, generator và collection vẫn post-MVP.

- [ ] **Step 2: Sửa tầm nhìn và phạm vi**

Trong `GDD/01-tam-nhin-va-pham-vi.md`:

- thay mô tả “S1/S2 toàn campaign” bằng band S1/S2 và S3 order 19–24;
- nêu Level 1 là tutorial duy nhất;
- nêu Restart/Undo giới hạn trong vòng lặp;
- bỏ điểm khỏi header và mô tả scorecard Result-only;
- đổi Hint miễn phí vô hạn thành một Hint mỗi lượt;
- giữ generator và nguồn Hint điểm danh/quảng cáo ngoài MVP.

- [ ] **Step 3: Thêm luật GR mới và chỉnh luật hiện hành**

Trong `GDD/02-luat-choi-va-trang-thai.md`:

- sửa GR-07 để trace release chấp nhận S2 ở order 1–18 và bắt buộc S3 ở order 19–24;
- giữ GR-13/16/17/19 cho `x_error`, ba tim và thất bại;
- sửa GR-21..24 thành một Hint hợp lệ mỗi lượt, `NoHint` không tiêu thụ;
- giữ GR-25 là đủ N mèo khi chưa chuyển `Failed`;
- thêm GR-31 `RestartLevel`: xác nhận rồi reset như Retry trên cùng level;
- thêm GR-32 `UndoX`: chỉ action X đơn/batch vừa commit, hoàn nguyên toàn bộ diff;
- thêm GR-33: `TryCat`, Restart, Retry, Won, Failed, Back To Home và đóng app xóa khe Undo; không Redo, không lưu khe Undo;
- ghi rõ Restart/Retry cấp lượt mới nên `hintCount=0`.

- [ ] **Step 4: Cập nhật UX, tutorial và vùng luật**

Trong `GDD/03-luong-man-hinh-va-ux.md`:

- thêm Undo và Restart có xác nhận vào UX-03;
- bỏ điểm khỏi header, giữ điểm ở UX-05/06;
- rút tutorial T1–T6 vào Level 1, theo thứ tự X → clear → drag → double-tap → bốn luật → Hint;
- từ Level 2 áp dụng phạt bình thường;
- thêm vùng luật bốn icon + chữ luôn nhìn thấy và đưa nó vào cổng N=6/safe-area/chữ lớn;
- mô tả trạng thái nút Hint đã dùng và Undo bị vô hiệu sau `TryCat`.

- [ ] **Step 5: Cập nhật level design và kiến trúc dữ liệu**

Trong `GDD/04-thiet-ke-level.md` và `GDD/05-kien-truc-va-du-lieu.md`:

- đổi schema v3 thành v4;
- định nghĩa S3 dùng `source`, `target`, `conclusion.cells`, `textKey`;
- yêu cầu mỗi order 19–24 có ít nhất một S3 cần thiết;
- cập nhật TECH-01/04 cho schema v4 và Hint S2/S3;
- API action thành `MarkX | ClearX | MarkStroke | TryCat | UndoX | RestartLevel`;
- giữ `hintCount` trong session, giới hạn `0..1`; khe Undo là runtime-only và không thêm vào `session.json`;
- ghi rõ Restart tạo session mới cùng level, còn Back To Home giữ session nhưng bỏ Undo.

Schema S3 được ghi chính xác như sau:

```json
{"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"}
```

- [ ] **Step 6: Cập nhật QA, package và tài liệu S3/meta**

Trong GDD/07–11:

- QA-18..20: một Hint/lượt, `NoHint` không tiêu thụ, S3 được giải thích lại từ state;
- QA-22/33: tutorial chỉ Level 1;
- thêm QA-54 Restart reset đầy đủ;
- thêm QA-55 Undo action X đơn/batch và chặn qua `TryCat`;
- thêm QA-56 Hint dùng một lần, reload không cấp lại, Retry/Restart cấp lại;
- thêm QA-57 release gate order 1–18 không S3 và 19–24 có S3 cần thiết;
- GDD/08 chuyển S3 từ gói nghiên cứu tùy chọn thành dependency bắt buộc của content 19–24 trước M2;
- GDD/09 ghi resolution của review;
- GDD/10 chuyển S3 thành ACTIVE-MVP, chỉ S4/S5 còn research/parked;
- GDD/11 ghi điểm danh/quảng cáo cấp thêm Hint là post-MVP, không tạo interface trong MVP.

- [ ] **Step 7: Chạy kiểm tra consistency tài liệu**

Run:

```powershell
rtk rg -n "schema v3|S3.*nếu|Hint miễn phí vô hạn|không Undo|không Restart|tutorial.*1–4|điểm.*header" GDD
```

Expected: chỉ còn các đoạn lịch sử được gắn nhãn rõ; không còn câu nào trình bày các giá trị cũ như luật hiện hành.

Checkpoint: lưu danh sách file đã đổi; không commit vì workspace không có `.git`.

### Task 2: Nâng validator và fixture lên schema v4/S3

**Files:**
- Modify: `GDD/data/levels.sample.json`
- Modify: `GDD/tools/test_validate_levels.py`
- Modify: `GDD/tools/validate_levels.py`

**Interfaces:**
- Consumes: S3 JSON contract từ Task 1.
- Produces: `possible_cells(rows, cats, eliminated)`, `validate_s3_step(...)`, validator schema v4 và fixture `S301`.

- [ ] **Step 1: Thêm fixture dương S301 và nâng toàn bộ fixture lên schema v4**

Đổi `schemaVersion` của T01/E01/E02/N12 thành `4`. Thêm level:

```json
{
  "schemaVersion": 4,
  "id": "S301",
  "order": 5,
  "size": 4,
  "regions": ["AABB", "CCCB", "CCDD", "DDDD"],
  "givens": [],
  "solution": [1, 3, 0, 2],
  "difficulty": "medium",
  "tags": ["s3-intersection", "required-s3"],
  "logicTrace": [
    {"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"},
    {"rule":"S2","focus":{"type":"region","id":"B"},"conclusion":{"type":"place","r":1,"c":3},"textKey":"hint.single.region"},
    {"rule":"S2","focus":{"type":"column","id":2},"conclusion":{"type":"place","r":3,"c":2},"textKey":"hint.single.column"},
    {"rule":"S2","focus":{"type":"region","id":"C"},"conclusion":{"type":"place","r":2,"c":0},"textKey":"hint.single.region"},
    {"rule":"S2","focus":{"type":"region","id":"A"},"conclusion":{"type":"place","r":0,"c":1},"textKey":"hint.single.region"}
  ]
}
```

- [ ] **Step 2: Viết test thất bại cho schema v4 và S3**

Trong `test_validate_levels.py`, cập nhật danh sách fixture mong đợi và thêm:

```python
def s3_level(self):
    return copy.deepcopy(next(level for level in self.levels if level["id"] == "S301"))

def test_s3_fixture_is_machine_checked(self):
    self.assertIsInstance(validate_level(self.s3_level()), str)

def test_s3_rejects_source_not_contained_in_target(self):
    level = self.s3_level()
    level["logicTrace"][0]["target"] = {"type": "row", "id": 1}
    with self.assertRaisesRegex(ValueError, "source candidates.*contained"):
        validate_level(level)

def test_s3_rejects_incomplete_conclusion_and_noop(self):
    level = self.s3_level()
    level["logicTrace"][0]["conclusion"]["cells"].pop()
    with self.assertRaisesRegex(ValueError, "conclusion cells"):
        validate_level(level)
    level = self.s3_level()
    level["logicTrace"].insert(1, copy.deepcopy(level["logicTrace"][0]))
    with self.assertRaisesRegex(ValueError, "new candidate"):
        validate_level(level)

def test_release_logic_bands(self):
    early = self.s3_level()
    early["order"] = 18
    with self.assertRaisesRegex(ValueError, "orders 1..18"):
        validate_release_logic_band(early)
    late = self.level()
    late["order"] = 19
    with self.assertRaisesRegex(ValueError, "orders 19..24"):
        validate_release_logic_band(late)
    required = self.s3_level()
    required["order"] = 19
    self.assertFalse(s2_only_reaches_solution(required))
    validate_release_logic_band(required)
```

Import `validate_release_logic_band` và `s2_only_reaches_solution` từ validator.

- [ ] **Step 3: Chạy test và xác nhận thất bại đúng lý do**

Run:

```powershell
rtk python GDD/tools/test_validate_levels.py -v
```

Expected: FAIL vì validator còn yêu cầu schemaVersion 3, chưa export `validate_release_logic_band` và chưa hỗ trợ S3.

- [ ] **Step 4: Triển khai state ứng viên S2/S3 tối thiểu**

Trong `validate_levels.py`:

```python
S2_STEP_KEYS = {"rule", "focus", "conclusion", "textKey"}
S3_STEP_KEYS = {"rule", "source", "target", "conclusion", "textKey"}
UNIT_KEYS = {"type", "id"}

def possible_cells(rows, cats, eliminated=frozenset()):
    n = len(rows)
    return {
        (r, c)
        for r in range(n) if r not in cats
        for c in range(n)
        if (r, c) not in eliminated
        and exclusion_reason(rows, cats, (r, c)) is None
    }

def parse_conclusion_cells(value, n):
    require_object(value, {"type", "cells"}, "conclusion")
    if value["type"] != "eliminate" or not isinstance(value["cells"], list):
        raise ValueError("S3 conclusion must eliminate cells")
    cells = []
    for item in value["cells"]:
        require_object(item, CELL_KEYS, "eliminated cell")
        cell = (item["r"], item["c"])
        if not all(is_int(part) and 0 <= part < n for part in cell):
            raise ValueError("eliminated cell out of bounds")
        cells.append(cell)
    if len(cells) != len(set(cells)):
        raise ValueError("duplicate S3 conclusion cell")
    return set(cells)

def validate_s3_step(rows, cats, eliminated, step):
    require_object(step, S3_STEP_KEYS, "S3 step")
    source, target = step["source"], step["target"]
    require_object(source, UNIT_KEYS, "S3 source")
    require_object(target, UNIT_KEYS, "S3 target")
    if source["type"] == target["type"]:
        raise ValueError("S3 source and target must have different unit types")
    source_unit = focus_cells(rows, source)
    target_unit = focus_cells(rows, target)
    if any(cell in source_unit or cell in target_unit for cell in cats.items()):
        raise ValueError("S3 units must not already contain a cat")
    candidates = possible_cells(rows, cats, eliminated)
    source_candidates = candidates & source_unit
    if not source_candidates or not source_candidates <= target_unit:
        raise ValueError("S3 source candidates must be nonempty and contained in target")
    expected = (candidates & target_unit) - source_unit
    if not expected:
        raise ValueError("S3 must eliminate at least one new candidate")
    declared = parse_conclusion_cells(step["conclusion"], len(rows))
    if declared != expected:
        raise ValueError(f"S3 conclusion cells {sorted(declared)}, expected {sorted(expected)}")
    if step["textKey"] != "hint.lock.intersection":
        raise ValueError("S3 textKey must be hint.lock.intersection")
    eliminated.update(expected)
```

Dispatch trong `validate_trace`: khởi tạo `eliminated=set()`, gọi S3 ở bước
`rule == "S3"`; S2 dùng `possible_cells(rows, cats, eliminated)`. Với ô bị
loại khỏi focus S2, chấp nhận khi có S1 witness **hoặc** nằm trong
`eliminated`. Đổi schema bắt buộc thành `4`.

- [ ] **Step 5: Thêm release band gate**

```python
def s2_only_reaches_solution(level):
    rows, n = level["regions"], level["size"]
    cats = {given["r"]: given["c"] for given in level["givens"]}
    units = (
        [{"type": "row", "id": i} for i in range(n)]
        + [{"type": "column", "id": i} for i in range(n)]
        + [{"type": "region", "id": label} for label in "ABCDEFGHIJKL"[:n]]
    )
    while len(cats) < n:
        placements = set()
        candidates = possible_cells(rows, cats)
        for unit_spec in units:
            unit = focus_cells(rows, unit_spec)
            if any(cell in unit for cell in cats.items()):
                continue
            remaining = unit & candidates
            if len(remaining) == 1:
                placements.update(remaining)
        fresh = sorted((r, c) for r, c in placements if r not in cats)
        if not fresh:
            return False
        for r, c in fresh:
            if r not in cats:
                cats[r] = c
    return True

def validate_release_logic_band(level):
    rules = [step.get("rule") for step in level["logicTrace"]]
    if 1 <= level["order"] <= 18 and "S3" in rules:
        raise ValueError("release orders 1..18 must use only S2 trace steps")
    if 19 <= level["order"] <= 24:
        if "S3" not in rules:
            raise ValueError("release orders 19..24 require at least one S3 trace step")
        if s2_only_reaches_solution(level):
            raise ValueError("release orders 19..24 must require S3, not merely contain it")
```

Gọi hàm này trong nhánh `release=True`. Đổi CLI output từ “S2 trace” thành
chuỗi rule thực tế, ví dụ `S2/S3 trace`.

- [ ] **Step 6: Chạy validator tests và fixture**

Run:

```powershell
rtk python GDD/tools/test_validate_levels.py -v
rtk python GDD/tools/validate_levels.py GDD/data/levels.sample.json
```

Expected: toàn bộ test PASS; T01/E01/E02/N12/S301 đều `OK`; không có duplicate geometry warning.

Checkpoint: schema v4/S3 độc lập chạy được; không commit vì workspace không có `.git`.

### Task 3: Mở rộng interaction contract cho Restart, Undo và Hint

**Files:**
- Modify: `GDD/data/interactions.sample.json`
- Modify: `GDD/tools/test_interaction_contract.py`

**Interfaces:**
- Consumes: action contract từ GR-31..33 và Hint một lần/lượt.
- Produces: `contractVersion: 2`, `apply_session_action(level, session, action)` và vector session mới.

- [ ] **Step 1: Thêm session vectors và nâng contractVersion lên 2**

Thêm top-level `sessionCases` với các case sau:

- `undo_single_mark`: MarkX rồi Undo trả board rỗng.
- `undo_clear`: ClearX rồi Undo trả lại X.
- `undo_stroke_batch`: MarkStroke đổi nhiều ô, Undo khôi phục cả batch một lần.
- `trycat_clears_undo`: MarkX rồi TryCat; Undo trả `UndoUnavailable` và không đổi board/tim.
- `back_home_clears_undo`: MarkX rồi BackToHome; board giữ X, Undo không còn.
- `restart_resets_attempt`: sau X, lỗi và Hint đã dùng, Restart đưa board rỗng, ba tim, `mistakeCount=0`, `hintCount=0`.
- `hint_once`: Hint có evidence tăng `hintCount` lên 1; Hint thứ hai trả `HintUnavailable`.
- `no_hint_does_not_consume`: kết quả `NoHint` giữ `hintCount=0`.

Mỗi case dùng action object có `type` và dữ liệu tối thiểu, ví dụ:

```json
{"type":"MarkX","cell":[0,0]}
{"type":"MarkStroke","mode":"mark","cells":[[0,0],[0,1],[0,2]]}
{"type":"Hint","result":"evidence"}
{"type":"UndoX"}
{"type":"RestartLevel"}
```

- [ ] **Step 2: Viết test session vectors trước reducer**

```python
def test_session_vectors(self):
    self.assertEqual(DATA["contractVersion"], 2)
    seen = set()
    for case in DATA["sessionCases"]:
        with self.subTest(case=case["id"]):
            self.assertNotIn(case["id"], seen)
            seen.add(case["id"])
            self.assertEqual(run_session_case(case), case["expected"])
```

Run:

```powershell
rtk python GDD/tools/test_interaction_contract.py -v
```

Expected: FAIL vì contract còn version 1 và `run_session_case` chưa tồn tại.

- [ ] **Step 3: Triển khai reducer session tham chiếu**

Tạo session runtime nội bộ:

```python
def new_reference_session(initial=None):
    initial = initial or {}
    return {
        "cells": dict(initial.get("cells", {})),
        "hearts": initial.get("hearts", 3),
        "mistakeCount": initial.get("mistakeCount", 0),
        "hintCount": initial.get("hintCount", 0),
        "undoDiff": None,
        "events": [],
    }

def public_session(session):
    return {
        "cells": session["cells"],
        "hearts": session["hearts"],
        "mistakeCount": session["mistakeCount"],
        "hintCount": session["hintCount"],
        "undoAvailable": session["undoDiff"] is not None,
        "events": session["events"],
    }

def write_cell(cells, cell_key, value):
    if value == "empty":
        cells.pop(cell_key, None)
    else:
        cells[cell_key] = value

def apply_session_action(level, session, action):
    action_type = action["type"]
    if action_type in ("MarkX", "ClearX"):
        cell = tuple(action["cell"])
        cell_key = key(cell)
        before = state(session["cells"], cell)
        required = "empty" if action_type == "MarkX" else "x"
        if before != required:
            session["events"].append("NoOp")
            return session
        after = "x" if action_type == "MarkX" else "empty"
        write_cell(session["cells"], cell_key, after)
        session["undoDiff"] = {cell_key: before}
        session["events"].append(action_type)
    elif action_type == "MarkStroke":
        mode = action["mode"]
        required, after = ("empty", "x") if mode == "mark" else ("x", "empty")
        diff = {}
        for raw_cell in action["cells"]:
            cell = tuple(raw_cell)
            cell_key = key(cell)
            before = state(session["cells"], cell)
            if before == required and cell_key not in diff:
                diff[cell_key] = before
                write_cell(session["cells"], cell_key, after)
        session["undoDiff"] = diff or None
        session["events"].append("MarkStroke" if diff else "NoOp")
    elif action_type == "UndoX":
        if session["undoDiff"] is None:
            session["events"].append("UndoUnavailable")
            return session
        for cell_key, previous in session["undoDiff"].items():
            write_cell(session["cells"], cell_key, previous)
        session["undoDiff"] = None
        session["events"].append("UndoApplied")
    elif action_type == "TryCat":
        session["undoDiff"] = None
        cell = tuple(action["cell"])
        if state(session["cells"], cell) not in ("empty", "x"):
            session["events"].append("NoOp")
        elif level["solution"][cell[0]] == cell[1]:
            write_cell(session["cells"], key(cell), "cat")
            session["events"].append("CatPlaced")
        else:
            write_cell(session["cells"], key(cell), "x_error")
            session["hearts"] -= 1
            session["mistakeCount"] += 1
            session["events"].append("Mistake")
    elif action_type == "Hint":
        if action["result"] == "none":
            session["events"].append("NoHint")
        elif session["hintCount"] == 0:
            session["hintCount"] = 1
            session["events"].append("HintShown")
        else:
            session["events"].append("HintUnavailable")
    elif action_type == "BackToHome":
        session["undoDiff"] = None
        session["events"].append("ReturnedHome")
    elif action_type == "RestartLevel":
        restarted = new_reference_session()
        restarted["events"].append("Restarted")
        return restarted
    else:
        raise AssertionError(f"unknown session action: {action_type}")
    return session

def run_session_case(case):
    session = new_reference_session(case.get("initial"))
    for action in case["actions"]:
        session = apply_session_action(LEVEL, session, action)
    return public_session(session)
```

`apply_session_action` phải:

- lưu diff `{cellKey: previousState}` cho MarkX/ClearX/MarkStroke;
- Undo khôi phục toàn bộ diff rồi xóa `undoDiff`;
- TryCat xóa `undoDiff` trước khi chấm đúng/sai;
- BackToHome chỉ xóa `undoDiff`;
- Restart trả state lượt mới;
- Hint evidence chỉ hợp lệ khi `hintCount == 0`, rồi đặt thành 1;
- `NoHint` không tăng count;
- Hint/`NoHint` không đổi board nên giữ nguyên khe Undo; action X mới thay khe
  cũ, còn `TryCat` và các lifecycle event trong GR-33 xóa khe Undo.

- [ ] **Step 4: Chạy interaction tests**

Run:

```powershell
rtk python GDD/tools/test_interaction_contract.py -v
```

Expected: các vector gesture cũ và session vector mới đều PASS.

Checkpoint: reference contract v2 chứng minh Undo/Restart/Hint; không commit vì workspace không có `.git`.

### Task 4: Đồng bộ design-control và trạng thái review

**Files:**
- Modify: `design-control/00-design-status.md`
- Modify: `design-control/01-open-questions.md`
- Modify: `design-control/02-decision-log.md`
- Modify: `design-control/03-risk-register.md`
- Modify: `design-control/04-assumptions.md`
- Modify: `design-control/05-research-backlog.md`
- Modify: `design-control/06-design-freeze-checklist.md`
- Modify: `design-control/reviews/01-mvp-game-design-review.md`
- Modify: `design-reviews/README.md`

**Interfaces:**
- Consumes: canonical GDD v0.5.0 và bằng chứng test Tasks 2–3.
- Produces: truy vết quyết định và blocker status đúng thực tế.

- [ ] **Step 1: Ghi bốn quyết định mới**

Thêm vào decision log:

- DEC-013: S3 bắt buộc cho order 19–24, schema v4, QA-37/40/41/57.
- DEC-014: Restart và Undo X một bước; Undo runtime-only.
- DEC-015: một Hint miễn phí mỗi lượt; Level 1 là tutorial duy nhất.
- DEC-016: điểm Result-only, ba tim/`x_error` độc lập meta, nghiệm thu runtime tách content acceptance.

Mỗi DEC ghi alternatives đã xét, rationale, affected IDs và trạng thái ACTIVE-MVP.

- [ ] **Step 2: Đóng hoặc chuyển trạng thái câu hỏi/rủi ro**

- DQ-001 CLOSED bằng DEC-013.
- DQ-006 đóng phần vai trò/hiển thị điểm; hệ số 100/25 vẫn tuneable M1.
- DQ-007 đóng baseline luật, giữ cảm giác công bằng là research M1.
- DQ-009 CLOSED bằng content gate mới.
- DQ-008 chuyển từ “S1/S2 đủ không” thành kiểm chất lượng band S1/S2 + S3.
- RISK-003 mitigation đổi sang validator/hint S3 bắt buộc.
- RISK-006 bỏ S3 khỏi scope ambiguity nhưng giữ blocker governance DQ-002.
- ASM-010 thay bằng giả định chất lượng campaign mới; không trình bày S3 như tùy chọn.

- [ ] **Step 3: Cập nhật backlog/checklist và review target**

- RES-NOW-02 chuyển CLOSED; research S3 chuyển thành implementation evidence trước M2.
- Freeze checklist ghi schema v4/S3 đã có quyết định nhưng chỉ tick bằng chứng sau khi tests qua.
- Trong review mục tiêu, thêm bảng Resolution cho GD-01..15, dẫn DEC-013..016 và đánh dấu resolved/deferred/validation-pending chính xác.
- `design-reviews/README.md` nêu review mới là quyết định kế tiếp, còn review lịch sử không tự tạo luật.

- [ ] **Step 4: Kiểm tra không có status drift**

Run:

```powershell
rtk rg -n "DQ-001.*OPEN|DQ-009.*OPEN|S3.*tùy chọn|S3.*nếu kịp|schema v3" design-control design-reviews GDD
```

Expected: không còn blocker S3/DQ-009 mở hoặc mô tả schema v3 là current; mọi kết quả lịch sử còn lại được gắn nhãn historical/superseded.

Checkpoint: governance register khớp canonical GDD; không commit vì workspace không có `.git`.

### Task 5: Verification toàn bộ thay đổi

**Files:**
- Verify: toàn bộ file ở Tasks 1–4

**Interfaces:**
- Consumes: GDD v0.5.0, schema v4, contract v2.
- Produces: báo cáo kiểm chứng và danh sách cổng M0/M2 còn mở.

- [ ] **Step 1: Chạy validator fixture theo yêu cầu AGENTS.md**

```powershell
rtk python GDD/tools/validate_levels.py GDD/data/levels.sample.json
```

Expected: năm fixture T01/E01/E02/N12/S301 đều OK; S301 báo S2/S3 trace.

- [ ] **Step 2: Chạy toàn bộ unit tests**

```powershell
rtk python -m unittest discover GDD/tools -p "test_*.py" -v
```

Expected: tất cả test pass, gồm negative S3, release band, Undo, Restart và Hint allowance.

- [ ] **Step 3: Xác nhận release fixture vẫn bị chặn đúng lý do**

```powershell
rtk python GDD/tools/validate_levels.py --release GDD/data/levels.sample.json
```

Expected: FAIL vì fixture không phải campaign 24 level và có N12; không được fail vì schema/trace S301 sai.

- [ ] **Step 4: Quét placeholder và drift cuối**

```powershell
rtk rg -n "T[B]D|T[O]DO|F[I]XME|schema v3|Hint miễn phí vô hạn|không Undo|không Restart|S3.*nếu kịp" GDD design-control design-reviews
```

Expected: không có placeholder; cụm cũ chỉ xuất hiện trong lịch sử được đánh dấu superseded hoặc trong test lỗi có chủ ý.

- [ ] **Step 5: Báo cáo cổng chưa hoàn thành**

Bàn giao phải nêu rõ thiết kế/tài liệu và Python reference đã đồng bộ nhưng
Design Freeze vẫn chưa hoàn tất cho đến khi có bằng chứng M0 về thiết bị,
input, atlas, bố cục và bằng chứng M2 cho sáu level release 19–24 thật.

Checkpoint cuối: liệt kê file thay đổi, lệnh/kết quả test, mã GDD/QA đáp ứng và rủi ro còn lại; không commit vì workspace không có `.git`.
