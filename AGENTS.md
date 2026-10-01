# Hướng dẫn làm việc cho agent — CanDoKu Rebuild

## 1. Bối cảnh dự án

CanDoKu là puzzle game trên Godot 4.x/GDScript. Đang trong giai đoạn **rebuild hoàn chỉnh** theo plan tại `docs/superpowers/plans/2026-10-02-rebuild-master.md`. Mục tiêu: bản playtest 30 levels (RST-011).

**Đọc trước khi làm:**
1. Master plan (`docs/superpowers/plans/2026-10-02-rebuild-master.md`) — kiến trúc, interface contracts, parallel map
2. Module plan được giao (`docs/superpowers/plans/rebuild/NN-name.md`) — chi tiết implement
3. File này — quy tắc làm việc

**Tham khảo thêm khi cần:** [STATUS](docs/STATUS.md), [ROADMAP](docs/ROADMAP.md), [DECISIONS](docs/DECISIONS.md), GDD 02 (luật chuẩn).

## 2. Nhận module và bắt đầu

### Preflight

```bash
rtk git branch --show-current                         # phải là dev, trừ khi được chỉ định nền khác
rtk git checkout -b <type>/<scope>-<mo-ta-ngan>       # tạo nhánh theo quy ước bên dưới
rtk git status                                        # ghi nhận existing changes — KHÔNG động vào
```

Tên nhánh dùng chữ thường, số và dấu gạch nối (`kebab-case`), không dùng khoảng trắng hoặc ký tự có dấu. Chọn `type` theo bản chất thay đổi: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `build`, `ci` hoặc `hotfix`. Với module rebuild, ưu tiên scope là mã module, ví dụ `feat/m01-core`, `refactor/m04-touch-input`; với thay đổi tài liệu có thể dùng `docs/history-guide`.

### Quy tắc thực hiện

- **Một agent, một module, một branch.** Không tự mở module khác.
- **Đọc interface contracts trong master plan** cho dependencies. Không cần đọc code module khác — contracts là API chính thức.
- **TDD:** Viết test trước (từ module plan), chạy fail, implement, chạy pass.
- **Chỉ commit files thuộc module:** `game/scripts/<folder>/` + `game/tests/test_<name>.gd`.
- **Hỏi khi:** thiếu quyết định ảnh hưởng luật, schema, tính năng, phạm vi, hoặc quyền. Ghi quyết định sản phẩm vào DECISIONS.
- **Không thêm spec/brief/vòng phê duyệt.** Module plan đã đủ — implement trực tiếp.

### Parallel execution

Modules chạy song song theo wave (xem master plan). Nếu dependency chưa merge:
- Viết tests + implement dùng interface contracts làm stub
- Tests dùng mock data matching contract signatures
- Khi dependency merge vào dev, rebase và chạy lại tests

## 3. Kiểm chứng (Gate)

Mỗi module phải pass gate trước khi merge:

```bash
# 1. Tests pass
godot --headless --script game/tests/test_<module>.gd
# Expected: <MODULE>_PASS

# 2. Clean-room — KHÔNG tên từ reference
grep -rE "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
# Expected: no matches

# 3. Không import từ extracted_reusable
grep -r "extracted_reusable" game/scripts/ game/tests/
# Expected: no matches

# 4. Full verify (trước merge/bàn giao)
rtk python -B tools/verify.py --godot <executable>
```

**Không qua gate = không merge.** Sửa cho đến khi pass.

## 4. Code constraints

- **Nguyên gốc hoàn toàn.** Tham khảo hành vi từ `extracted_reusable/`, KHÔNG sao chép code/tên/enum. Asset, level, câu chữ, mã nguồn phải là tác phẩm gốc; không sao chép tên thương mại, giao diện, âm thanh, nhân vật hoặc cấu trúc level của game thương mại khác.
- **Module ≤ 300 dòng.** Một file, một trách nhiệm.
- **Signals thay EventBus.** Dùng Godot signals native, không global bus.
- **Không autoloads.** Composition root pattern — dependencies injected từ app_shell.
- **Static cho pure logic.** cell_model, candy_rules, board_solver, board_transform — stateless, testable.
- **Dùng asset có sẵn.** Không tạo .ogg/.png/.svg mới ngoài danh sách đã liệt kê trong master plan.
- **Phạm vi:** R1, 30 levels, N=4-6, S1-S3. Không tự mở R2-R4, Endless, IAP, ads, analytics.

## 5. Nhánh và tích hợp

- `dev` là nền tích hợp. Tạo nhánh từ `dev` theo mẫu `<type>/<scope>-<mo-ta-ngan>`; chỉ dùng nền khác khi người dùng chỉ định rõ.
- `type` của nhánh và commit phải phản ánh đúng thay đổi chính: `feat` (tính năng), `fix`/`hotfix` (sửa lỗi), `refactor` (tái cấu trúc không đổi hành vi), `docs`, `test`, `chore`, `perf`, `build` hoặc `ci`.
- Tên nhánh phải ngắn, dễ tìm kiếm, dùng lowercase/kebab-case và không lặp thông tin hiển nhiên. Ví dụ: `feat/m03-bank-reader`, `fix/m04-drag-selection`, `docs/history-guide`.
- `main` giữ mốc hiện có — không push vào main.
- Commit chọn đúng file thuộc module và tuân theo Conventional Commits: `<type>(<scope>): <mô tả>`, ví dụ `feat(m01): add board solver`, `fix(m04): reject invalid drag path`, `docs(workflow): clarify history lookup`. Dùng `!` và footer `BREAKING CHANGE:` khi có thay đổi phá vỡ contract.
- Merge vào dev theo thứ tự wave (Wave 1 trước, Wave 2 sau, ...).
- **Giữ nguyên thay đổi sẵn có.** Không add/reset/dọn files ngoài module. Không xóa tài sản hoặc phát hành ngoài phạm vi được giao.
- Chỉ merge/push/phát hành trong quyền được giao.

## 6. Blocker và báo cáo

- STATUS (`docs/STATUS.md`) là nguồn tiến độ duy nhất.
- Mỗi blocker ghi: tác động, người xử lý, hành động tiếp, điều kiện thử lại.
- Cùng lỗi môi trường: chẩn đoán một lần, không retry vô hạn.
- Không báo hoàn tất module còn bị chặn.
- Evidence phải ghi revision, lệnh, kết quả, giới hạn. Log tại `scratch/verification/`.

## 7. Quick reference — Module map

| Module | Folder | Test file | Wave |
|--------|--------|-----------|------|
| M01 Core | `scripts/core/` | `test_candy_rules.gd`, `test_board_solver.gd` | 1 |
| M02 State | `scripts/state/` | `test_dual_slot_store.gd`, `test_progress_manager.gd` | 2 |
| M03 Content | `scripts/content/` | `test_bank_reader.gd` | 2 |
| M04 Input | `scripts/input/` | `test_play_session.gd`, `test_touch_decoder.gd` | 2 |
| M05 Theme | `scripts/theme/` | (no test — const only) | 1 |
| M06 Feedback | `scripts/feedback/` | `test_feedback.gd` | 3 |
| M07 Campaign | `scripts/campaign/` | `test_campaign_runtime.gd` | 3 |
| M08 Screens | `scripts/screens/` | (manual + integration) | 4 |
| M09 Integration | (all) | (full suite) | 5 |
| M10 Content Gen | `data/banks/`, `data/campaigns/` | (validation scripts) | 6 |

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
