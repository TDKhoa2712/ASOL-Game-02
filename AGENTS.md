# Hướng dẫn làm việc cho agent — CanDoKu

## 1. Bối cảnh dự án

CanDoKu là puzzle game Godot 4/GDScript chạy offline. Rebuild M01–M10 đã merge vào `dev` (PR #1–#10). Bank và playlist playtest hiện có **30 level 4×4**; N=4–6 là phạm vi thiết kế, chưa phải nội dung đã có cho mọi kích thước. Đây chưa phải bản phát hành hay nghiệm thu thiết bị. Nhánh `feat/gameplay-ui-realign` đang chỉnh gameplay và UI sau rebuild.

**Đọc trước khi làm:**
1. [STATUS](docs/STATUS.md) — tiến độ thực tế và vấn đề còn mở
2. [DECISIONS](docs/DECISIONS.md) và [GDD 02](GDD/02-luat-choi-va-trang-thai.md) — quyết định và luật chuẩn
3. [Plan realignment](docs/superpowers/plans/2026-10-02-gameplay-ui-realign.md) — yêu cầu ban đầu; đối chiếu với code trước khi triển khai

**Chênh lệch đang cần chốt:** RST-015/plan yêu cầu bỏ Undo, nhưng nhánh hiện vẫn có Undo giới hạn cho thao tác X. Không mô tả yêu cầu ban đầu như trạng thái đã triển khai.

## 2. Nhận module và bắt đầu

### Preflight

```bash
rtk git branch --show-current
rtk git status --short
# Chỉ khi bắt đầu việc mới trên dev và working tree đã được bảo toàn:
rtk git checkout -b <type>/<scope>-<mo-ta-ngan>
```

Tên nhánh dùng chữ thường, số và dấu gạch nối (`kebab-case`). Nếu đang ở nhánh của cùng việc, tiếp tục trên nhánh đó; không checkout khi có thay đổi chưa được bảo toàn.

### Quy tắc thực hiện

- **Một agent, một task, một branch.** Không tự mở task khác.
- **Đọc code, test và STATUS hiện tại** trước khi sửa; plan ghi ý định ban đầu, không thay trạng thái code.
- **TDD cho feature/bugfix:** viết test trước, chạy fail, implement, chạy pass. Với sửa tài liệu, kiểm liên kết, lệnh và tính nhất quán.
- **Chỉ stage/commit file thuộc phạm vi được giao.** Giữ nguyên sửa đổi có sẵn của người khác.
- **Hỏi khi:** thiếu quyết định ảnh hưởng luật, schema, tính năng, phạm vi, hoặc quyền. Ghi quyết định sản phẩm vào DECISIONS.
- **Không thêm spec/brief/vòng phê duyệt** cho việc đã có quyết định.

Rebuild theo wave đã kết thúc. Không dùng master plan đã dọn khỏi working tree như kế hoạch thực hiện hiện hành.

## 3. Kiểm chứng (Gate)

Chạy suite liên quan trước, rồi full gate trước khi bàn giao thay đổi code hoặc merge:

```bash
# 1. Tests pass
rtk godot --headless --path game --script res://tests/test_<ten>.gd

# 2. Clean-room — KHÔNG tên từ reference
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
# Expected: no matches

# 3. Không import từ extracted_reusable
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/
# Expected: no matches

# 4. Full verify (trước merge/bàn giao)
rtk python -B tools/verify.py --godot <executable>
```

**Không qua gate = không merge.** Headless pass không thay QA giao diện, gesture và thiết bị.

## 4. Code constraints

- **Nguyên gốc hoàn toàn.** Tham khảo hành vi từ `extracted_reusable/`, KHÔNG sao chép code/tên/enum. Asset, level, câu chữ, mã nguồn phải là tác phẩm gốc; không sao chép tên thương mại, giao diện, âm thanh, nhân vật hoặc cấu trúc level của game thương mại khác.
- **Module ≤ 300 dòng.** Một file, một trách nhiệm.
- **Signals thay EventBus.** Dùng Godot signals native, không global bus.
- **Không autoloads.** Composition root pattern — dependencies injected từ app_shell.
- **Static cho pure logic.** cell_model, candy_rules, board_solver, board_transform — stateless, testable.
- **Asset nguyên gốc.** Kiểm tra tài sản hiện có trước khi thêm; không sao chép giao diện hoặc tài sản thương mại.
- **Phạm vi:** R1, 30 levels, N=4-6, S1-S3. Không tự mở R2-R4, Endless, IAP, ads, analytics.

## 5. Nhánh và tích hợp

- `dev` là nền tích hợp. Tạo nhánh từ `dev` theo mẫu `<type>/<scope>-<mo-ta-ngan>`; chỉ dùng nền khác khi người dùng chỉ định rõ.
- `type` của nhánh và commit phải phản ánh đúng thay đổi chính: `feat` (tính năng), `fix`/`hotfix` (sửa lỗi), `refactor` (tái cấu trúc không đổi hành vi), `docs`, `test`, `chore`, `perf`, `build` hoặc `ci`.
- Tên nhánh phải ngắn, dễ tìm kiếm, dùng lowercase/kebab-case và không lặp thông tin hiển nhiên. Ví dụ: `feat/m03-bank-reader`, `fix/m04-drag-selection`, `docs/history-guide`.
- `main` giữ mốc hiện có — không push vào main.
- Commit chọn đúng file thuộc module và tuân theo Conventional Commits: `<type>(<scope>): <mô tả>`, ví dụ `feat(m01): add board solver`, `fix(m04): reject invalid drag path`, `docs(workflow): clarify history lookup`. Dùng `!` và footer `BREAKING CHANGE:` khi có thay đổi phá vỡ contract.
- Rebuild theo wave đã merge; việc hiện tại tích hợp vào `dev` sau khi qua gate và được giao quyền.
- **Giữ nguyên thay đổi sẵn có.** Không add/reset/dọn files ngoài module. Không xóa tài sản hoặc phát hành ngoài phạm vi được giao.
- Chỉ merge/push/phát hành trong quyền được giao.

## 6. Blocker và báo cáo

- STATUS (`docs/STATUS.md`) là nguồn tiến độ duy nhất.
- Mỗi blocker ghi: tác động, người xử lý, hành động tiếp, điều kiện thử lại.
- Cùng lỗi môi trường: chẩn đoán một lần, không retry vô hạn.
- Không báo hoàn tất module còn bị chặn.
- Evidence phải ghi revision, lệnh, kết quả, giới hạn. Log tại `scratch/verification/`.

## 7. Quick reference — Module map đã rebuild

| Khu vực | Vị trí | Kiểm chứng chính |
|---------|--------|-----------------|
| Core và input | `game/scripts/core/`, `game/scripts/input/` | `test_candy_rules.gd`, `test_board_solver.gd`, `test_play_session.gd`, `test_touch_decoder.gd` |
| State, content, campaign | `game/scripts/state/`, `content/`, `campaign/` | các suite tương ứng trong `game/tests/` |
| Feedback và UI | `game/scripts/feedback/`, `screens/`, `theme/` | `test_feedback.gd`, `test_screens.gd`, `test_integration.gd` |
| Nội dung 30 level | `game/data/banks/`, `game/data/campaigns/` | `tools/validate_content.py`, `tools/verify.py` |

## 8. Lịch sử

Hồ sơ vận hành cũ được bảo toàn tại tag `pre-reset-pipeline-2026-09-27`; mục lục và bối cảnh nằm trong [lịch sử](docs/HISTORY.md). Chỉ tra cứu khi cần đối chiếu — không khôi phục hoặc sao chép nguyên trạng vào nhánh hiện tại.

```bash
rtk git show pre-reset-pipeline-2026-09-27 --stat
rtk git log --oneline --decorate pre-reset-pipeline-2026-09-27
rtk git show pre-reset-pipeline-2026-09-27:<duong-dan-file>
rtk git diff pre-reset-pipeline-2026-09-27..dev -- <duong-dan-file>
```

- Dùng `git show <tag>:<path>` để đọc một file tại mốc cũ mà không đổi working tree.
- Dùng `git log <tag> -- <path>` để xem lịch sử riêng của file hoặc thư mục.
- Dùng `git diff <tag>..dev -- <path>` để đối chiếu với nền tích hợp hiện tại.
- Không `checkout`, `reset`, cherry-pick hoặc phục hồi nội dung từ tag nếu chưa được giao rõ; mọi nội dung đưa trở lại phải vẫn tuân thủ quy tắc nguyên gốc và phạm vi module.
