# Design Specification: System-wide Removal of Givens

**Date:** 2026-10-14  
**Status:** Draft  
**Branch:** `feat/v1.0.1/tutorial` (or dedicated refactor branch)  

---

## 1. Mục tiêu và bối cảnh (Context & Goals)

### 1.1. Bối cảnh
Trước đây, puzzle game hỗ trợ khái niệm `GIVEN` (kẹo cho sẵn trên bàn cờ khi bắt đầu màn) nhằm hỗ trợ người chơi ở các màn nhập môn hoặc kích hoạt cơ chế DDA (Dynamic Difficulty Adjustment) khi thua liên tiếp.
Hiện tại, dự án CanDoKu đã có màn Tutorial độc lập hoàn chỉnh (`tutorial_flow.gd` / RST-028) dạy đầy đủ mọi luật chơi cơ bản. Khái niệm `GIVEN` không còn cần thiết, chỉ còn sót lại ở đúng 1 level duy nhất (`bank_4x4.json` Rank 1 Index 1 / L02) và làm phức tạp hóa mô hình trạng thái ô cờ (`CellModel`), bộ giải (`BoardSolver`), renderer và bộ sinh gợi ý.

### 1.2. Mục tiêu
- Loại bỏ hoàn toàn khái niệm và trạng thái `GIVEN` (`CellModel.CellKind.GIVEN = 4`) khỏi toàn bộ codebase.
- Giảm số trạng thái ô (`CellKind`) từ 5 xuống 4: `BLANK (0)`, `MARK (1)`, `CANDY (2)`, `ERROR (3)`.
- Xóa bỏ cơ chế prefill DDA (`pre_candy_decider.gd`).
- Đưa tất cả các màn chơi về mô hình bàn cờ tự giải 100%: người chơi tự suy luận dựa trên các bước giải (logic trace) từ đầu.
- Cập nhật level duy nhất còn given (`bank_4x4.json` Rank 1 Index 1) thành 4 bước giải S2 tự nhiên và cập nhật `.pace.json`.
- Tinh gọn các validator, tutorial tips (`C-given`), render pipeline và cập nhật toàn bộ test suite liên quan.

---

## 2. Chi tiết thay đổi các thành phần (Detailed Architecture & Changes)

### 2.1. Core Data Model (`game/scripts/core/cell_model.gd`)
- **Enum `CellKind`:**
  ```gdscript
  enum CellKind {
      BLANK = 0,      # Ô trống, chưa đánh dấu
      MARK = 1,       # Player đánh X (xóa được)
      CANDY = 2,      # Candy đặt đúng
      ERROR = 3,      # Candy đặt sai (hiện X đỏ, không xóa được)
  }
  ```
  Xóa `GIVEN = 4`.
- **Hàm tiện ích:**
  - `is_placed(kind: int) -> bool`: trả về `kind == CellKind.CANDY`.
  - `is_candy(kind: int) -> bool`: trả về `kind == CellKind.CANDY`.
  - `is_locked(kind: int) -> bool`: trả về `false` (không còn ô nào bị khóa bất biến từ đầu).
  - `label(kind: int) -> String`: xóa trường hợp `CellKind.GIVEN`.

### 2.2. Xóa bỏ Dynamic Prefill (`pre_candy_decider.gd`)
- Xóa file [game/scripts/core/pre_candy_decider.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/core/pre_candy_decider.gd).
- Xóa test tương ứng [game/tests/test_pre_candy_decider.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/tests/test_pre_candy_decider.gd).
- Trong [game/scripts/endless/endless_runtime.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/endless/endless_runtime.gd):
  - Xóa hằng số `PreCandyDeciderClass`.
  - Xóa đoạn code gọi `PreCandyDeciderClass.should_prefill(...)` và `apply_prefill(...)`.

### 2.3. Logic Solver (`game/scripts/core/board_solver.gd`)
- `compute_cell_ranks(size, regions, solution, givens = [])`: loại bỏ xử lý `givens`. Toàn bộ ô ban đầu đều là ô trống.
- `replay_solve(size, regions, solution, givens = [])`: loại bỏ đặt trước `GIVEN` lên bàn cờ; `placed_count` bắt đầu từ 0.

### 2.4. Play Session & Input (`game/scripts/input/play_session.gd`)
- Trong `_build_board` và `restore`: xóa vòng lặp duyệt `level.get("givens", [])` và gán `CellModel.CellKind.GIVEN`.
- `is_preset(row, col) -> bool`: trả về `false`.
- Trong `try_candy` và `clear_cell`: loại bỏ xử lý trường hợp `CellKind.GIVEN`.
- `get_progress()`: số kẹo cần đặt `required` luôn bằng `size`.

### 2.5. Rendering & Theme
- [game/scripts/screens/candy_cell_drawer.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/screens/candy_cell_drawer.gd): Xóa tham số `is_given: bool` và xóa lệnh vẽ vòng hào quang `draw_circle` (halo).
- [game/scripts/screens/puzzle_board.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/screens/puzzle_board.gd): Xóa tham số `is_given` trong `_draw_cell_candy`.
- [game/scripts/screens/puzzle_board_painter.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/screens/puzzle_board_painter.gd): Pass 4a static candy chỉ kiểm tra `k == CellModel.CellKind.CANDY`.
- [game/scripts/screens/candy_anim_state.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/screens/candy_anim_state.gd): Chỉ kiểm tra `k == CellModel.CellKind.CANDY`.
- [game/scripts/theme/layout_tokens.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/theme/layout_tokens.gd), [candy_palette.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/theme/candy_palette.gd), [palette.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/theme/palette.gd): Gỡ bỏ token liên quan đến `GIVEN_HALO`, `GIVEN_CANDY`, `GIVEN_BG_TINT`.

### 2.6. Tutorial & Tips
- [game/scripts/campaign/tutorial_tips.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/campaign/tutorial_tips.gd): Xóa nhánh gợi ý `C-given` khi `givens > 0`.
- [game/scripts/campaign/tutorial_targets.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/campaign/tutorial_targets.gd): Xóa nhánh `"excluded_by_given"`.
- [game/scripts/screens/puzzle_tutorial.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/screens/puzzle_tutorial.gd): Xóa trường `"givens"` khỏi context gửi vào `TutorialTips`.

### 2.7. Dữ liệu Level Bank (`bank_4x4.json` & `bank_4x4.pace.json`)
- Cập nhật level duy nhất có given trong toàn bộ game:
  - File: `game/data/banks/bank_4x4.json`, Rank 1, Index 1.
  - Xóa given `[{"r": 2, "c": 0}]` -> `"givens": []`.
  - Cập nhật `steps: 4`, `profile: [4, 0, 0]`.
  - Cập nhật `logicTrace` gồm 4 bước S2 thuần:
    1. Region `D`: đặt tại `(3, 2)`
    2. Row `2`: đặt tại `(2, 0)`
    3. Column `1`: đặt tại `(0, 1)`
    4. Row `1`: đặt tại `(1, 3)`
  - Chạy lại generator tạo pace: `game/data/banks/bank_4x4.pace.json`.

### 2.8. Validators & Content Tools
- [game/scripts/content/level_validator.gd](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/game/scripts/content/level_validator.gd):
  - `_check_schema`: `"givens"` chuyển thành không bắt buộc (optional, nếu có thì là array).
  - `_check_geometry`: gỡ bỏ kiểm tra tọa độ givens.
- [tools/validate_content.py](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/tools/validate_content.py):
  - Xóa bỏ việc kiểm tra mảng givens trong bank levels.
- [tools/validate_full_content.py](file:///D:/Work/Alpaca_Solution/ASOL-Game-02/tools/validate_full_content.py):
  - Điều chỉnh tương tự.

### 2.9. Cập nhật Test Suites
Cập nhật tất cả các test case đang gán hoặc kiểm tra `CellModel.CellKind.GIVEN`:
- `test_candy_rules.gd`: cập nhật assert `CellModel` (không còn `GIVEN`).
- `test_play_session.gd`: xóa test case `_test_given_without_generated_marks` và cập nhật các session khởi tạo không cần given.
- `test_board_solver.gd`: cập nhật test solver không truyền givens.
- `test_hint_engine.gd`: cập nhật `_test_given_not_wrong_mark` hoặc thay bằng test ô candy chuẩn.
- `test_screens.gd`, `test_board_entry.gd`, `test_session_store.gd`, `test_tutorial_tips.gd`, `test_tutorial_targets.gd`, `test_candy_counter_animator.gd`, `test_touch_guard_integration.gd`, `test_integration.gd`, `test_endless_integration.gd`, `test_endless_runtime.gd`, `test_sfx_gameplay.gd`, `test_snapshot_builder.gd`, `test_debug_features.gd`.

---

## 3. Kế hoạch xác thực (Verification Plan)

1. **Python Unittests & Content Validation:**
   ```powershell
   python -B -m unittest discover tools/tests -p "test_*.py"
   python -B tools/validate_content.py game/data/banks/bank_4x4.json --pace game/data/banks/bank_4x4.pace.json
   python -B tools/validate_content.py game/data/campaigns/demo_30.json --bank game/data/banks/bank_4x4.json --bank game/data/banks/bank_5x5.json --bank game/data/banks/bank_6x6.json
   ```
2. **Godot Headless Test Suites:**
   Chạy toàn bộ các test suites Godot liên quan và đảm bảo PASS 100%:
   ```powershell
   & "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_candy_rules.gd
   & "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_play_session.gd
   & "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_board_solver.gd
   & "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/test_screens.gd
   ```
3. **Full Gate Verification:**
   ```powershell
   python -B tools/verify.py --godot "C:/Users/khoat/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
   ```
   Tất cả các suite phải trả về PASS mà không còn bất kỳ lỗi nào.
