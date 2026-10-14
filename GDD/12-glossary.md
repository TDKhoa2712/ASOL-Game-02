# GDD-12 — Glossary & References

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-12 |
| Phiên bản | 1.0.0 |
| Trạng thái | Approved · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Liên quan | [README](README.md), [GDD-02](02-core-gameplay.md), [GDD-10](10-reasoning-techniques.md) |

> **Tóm tắt:** Chương này là từ điển chung của bộ GDD. Mỗi thuật ngữ có một nghĩa duy nhất, và các chương khác dùng thuật ngữ theo đúng nghĩa đó. Cuối chương là danh sách tài liệu tham khảo và quy định về tính nguyên gốc.

## 1. Thuật ngữ gameplay

| Thuật ngữ | Tên trong code | Định nghĩa |
| --- | --- | --- |
| Bàn (board) | `size`, `regions` | Lưới N×N ô, N = 4–12 |
| Vùng màu (region) | `regions[r][c]` | Tập ô liên thông theo cạnh có cùng nhãn A..L. Mỗi vùng màu chứa đúng một kẹo. Người chơi gọi là "vùng màu" hoặc "vùng". |
| Đơn vị (unit) | — | Một hàng, một cột hoặc một vùng màu |
| Kẹo (candy) | `CellKind.CANDY` | Ô mà người chơi đã tìm đúng; ô này cố định đến hết lượt |
| X | `CellKind.MARK` | Ghi chú "ô này không có kẹo" do người chơi đánh; xóa được |
| X đỏ (error) | `CellKind.ERROR` | Ô người chơi đã thử kẹo sai. Ô bị khóa trong lượt và lần thử sai mất một tim. |
| Thử kẹo (try candy) | `try_candy` | Hành động chạm đôi để xác nhận "kẹo ở đây" |
| Nét kéo (stroke) | `mark_stroke` | Thao tác kéo để đánh hoặc xóa X trên nhiều ô cùng lúc |
| Tim (heart) | `hearts` | Số lần được sai trong một lượt. Mỗi lượt có 3 tim. |
| Lượt (run/session) | `session` | Một lần chơi một level, tính từ lúc bắt đầu hoặc Retry đến khi thắng hoặc thua |
| Nghiệm (solution) | `solution[r] = c` | Vị trí kẹo duy nhất đúng của level |
| Chạm (touching) | — | Hai ô có `max(|Δr|, |Δc|) = 1`, tức kề nhau theo cạnh hoặc theo góc |
| Combo | `combo_tracker` | Chuỗi kẹo đúng liên tiếp do người chơi tự đặt, cấp tối đa 12 |
| Hint | `hint_engine` | Gợi ý một bước suy luận kèm giải thích; xem [GDD-03](03-game-systems.md) |
| Givens | `givens` | Kẹo cho sẵn. Đã bỏ khỏi toàn hệ thống: validator từ chối danh sách không rỗng. |

## 2. Thuật ngữ nội dung

| Thuật ngữ | Định nghĩa |
| --- | --- |
| Bank | File JSON chứa level, nhóm theo kích thước và rank (`bank_6x6.json`) hoặc theo loại (`bank_single_region.json`) |
| Rank | Bậc độ khó 1–5 bên trong một bank |
| Pace | File sidecar `.pace.json` đi kèm bank, chứa `rSeq` và `hintCosts` cho từng level |
| Playlist / Campaign | File trong `game/data/campaigns/` tham chiếu tới level trong bank theo bộ `(size, rank, index)` |
| Active campaign | Campaign được chọn trong `active_campaign.json` |
| Transform ×8 | 8 phép đối xứng (4 phép xoay × 2 phép lật) dùng để tạo biến thể của một level |
| Logic trace | Chuỗi các bước suy luận đã được kiểm chứng, đi từ bàn trống đến khi đủ N kẹo |
| `pidHash` / `puzzleHash` | Hash định danh nội dung puzzle; dùng để chống trùng và kiểm tính hợp lệ của save |
| DDA | Dynamic Difficulty Adjustment: điều chỉnh rank của level kế tiếp theo kết quả chơi gần đây |
| Endless | Chế độ chơi vô hạn chọn level từ nhiều provider; hiện đang **Off** |

## 3. Thuật ngữ suy luận

| Ký hiệu | Tên | Định nghĩa ngắn (chi tiết ở [GDD-10](10-reasoning-techniques.md)) |
| --- | --- | --- |
| S1 | Elimination | Loại các ô xung đột với kẹo đã biết |
| S2 | Single Candidate | Đơn vị chỉ còn một ứng viên thì kẹo phải ở ô đó |
| S3 | Lock Intersection | Ứng viên của một đơn vị nằm gọn trong một đơn vị khác, nên loại phần còn lại của đơn vị kia |
| S4–S6 | Locked Subset (pair/triple/quad) | k đơn vị khóa k đơn vị khác loại |
| S7 | Contradiction Chain | Giả định một ô có kẹo, lan truyền hệ quả, gặp mâu thuẫn thì loại ô đó |
| X1–X4, CASE, EXACT | Mở rộng nghiên cứu | Chưa dùng trong trace hay Hint |

## 4. Viết tắt

| Viết tắt | Đầy đủ |
| --- | --- |
| FTUE | First-Time User Experience |
| HUD | Heads-Up Display |
| SFX / BGM | Sound Effects / Background Music |
| USP | Unique Selling Point |
| KPI | Key Performance Indicator |
| RST-xxx | Mã quyết định trong [DECISIONS](../docs/DECISIONS.md) |

## 5. Tính nguyên gốc và tham khảo

CanDoKu thuộc họ puzzle "một mục tiêu mỗi hàng, cột và vùng, các mục tiêu không chạm nhau". Đây là cơ chế chung của thể loại.

Mọi thành phần sau phải là tác phẩm gốc của dự án: chủ đề tìm kẹo ẩn sau ô màu, level, layout, câu chữ, logo, hình ảnh, âm thanh và mã nguồn. Code được tham khảo hành vi từ `extracted_reusable/`, nhưng không được sao chép code, tên định danh hay enum từ đó. Gate clean-room được mô tả ở [GDD-08](08-technical-design.md) và [AGENTS](../AGENTS.md).

Tài liệu học thuật được dùng làm nền:

- Régin, *A Filtering Algorithm for Constraints of Difference in CSPs*, AAAI 1994 — all-different và matching (S4–S6, X3).
- Espasa et al., *Towards Generic Explanations for Pen and Paper Puzzles with MUSes*, 2021 — phân biệt "giải được" với "giải thích được".
- Pelánek, *Difficulty Rating of Sudoku Puzzles by a Computational Model*, FLAIRS 2011 — mô hình độ khó dựa trên các bước giải.

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Tạo chương thuật ngữ thống nhất từ các bảng thuật ngữ rải rác trong GDD và `docs/GAME_OVERVIEW.md` cũ. |
