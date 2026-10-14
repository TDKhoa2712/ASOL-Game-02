# GDD-10 — Appendix A: Kỹ thuật suy luận

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-10 |
| Phiên bản | 1.0.0 |
| Trạng thái | Draft · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design · Level Design |
| Liên quan | [GDD-02](02-core-gameplay.md), [GDD-03](03-game-systems.md), [GDD-05](05-level-design.md), [GDD-08](08-technical-design.md), [GDD-09](09-qa-acceptance.md), [GDD-11](11-level-generation.md), [GDD-12](12-glossary.md) |

> **Tóm tắt:** Phụ lục này đặc tả mô hình toán của luật CanDoKu, chuẩn của một bước suy luận và bảy kỹ thuật S1–S7 mà solver và Hint Engine đang dùng, kèm điều kiện, chứng minh, phản ví dụ và câu Hint. Các kỹ thuật mở rộng X1–X4, CASE, EXACT là phần nghiên cứu, chưa dùng trong runtime.

## 1. Mục đích và phạm vi

- Là nguồn chuẩn cho: solver (`game/scripts/core/solver_techniques.gd`, `board_solver.gd`), Hint Engine (`hint_engine.gd`), validator trace (`GDD/tools/validate_levels.py`, `level_reasoning.py`) và đánh giá độ khó ([GDD-11](11-level-generation.md)).
- Luật thắng/thua do [GDD-02](02-core-gameplay.md) quy định; chương này chỉ chứng minh hệ quả logic của luật.
- Không khẳng định một danh sách hữu hạn kỹ thuật giải được mọi bàn có nghiệm duy nhất.

### 1.1. Danh mục kỹ thuật

| Mã | Tên | `Technique` enum | Hint strategy | Trạng thái |
| --- | --- | --- | --- | --- |
| S1 | Elimination | `ELIMINATION = 1` | (nền; `MARK_NEIGHBORS` cho mark quanh kẹo đã đặt) | Live |
| S2 | Single Candidate | `SINGLE_CANDIDATE = 2` | `SINGLE_CANDIDATE` → `PLACE_CANDY` | Live |
| S3 | Lock Intersection | `LOCK_INTERSECTION = 3` | `LOCK_INTERSECTION` → `PLACE_MARKS` | Live |
| S4 | Locked Subset k=2 | `SUBSET_PAIR = 4` | `LOCKED_SUBSET` (`hint.subset_pair`) | Live |
| S5 | Locked Subset k=3 | `SUBSET_TRIPLE = 5` | `LOCKED_SUBSET` (`hint.subset_triple`) | Live |
| S6 | Locked Subset k≥4 | `SUBSET_QUAD = 6` | `LOCKED_SUBSET` (`hint.subset_quad`) | Live |
| S7 | Contradiction Chain | `CONTRA_CHAIN = 7` | `CONTRA_CHAIN` (`hint.chain_short`/`hint.chain_long`, nút Detail) | Live |
| X1–X4 | Vùng cấm chung, hỗ trợ, Hall tổng quát, sức chứa | — | — | Research |
| CASE | Xét hết trường hợp | — | — | Research |
| EXACT | Duyệt nghiệm đầy đủ | — | — | Live trong validator Python (oracle), không dùng làm Hint |

## 2. Mô hình toán

### 2.1. Biến và ràng buộc

Bàn N×N (N=4..12), ô q=(r,c), tọa độ JSON/code **0-based**, UI cộng 1. Có đúng N vùng (region, trong code là `zone`; với người chơi gọi là "vùng màu"), mỗi vùng liên thông 4 hướng, nhãn `A`, `B`, ….

Biến x[q] ∈ {0,1}, bằng 1 khi ô chứa kẹo:

1. ∑ x trên mỗi hàng = 1.
2. ∑ x trên mỗi cột = 1.
3. ∑ x trên mỗi vùng = 1.
4. Với hai ô khác nhau có max(|Δr|,|Δc|) = 1: x[a] + x[b] ≤ 1.

Ràng buộc 4 chỉ cấm **kề** (cạnh và góc). Không có luật cấm cả đường chéo: (0,0) và (2,2) không xung đột chỉ vì cùng đường chéo.

**Mô hình hoán vị tương đương:** `solution[r] = c`; mỗi cột dùng đúng một lần; nhãn vùng tại (r, solution[r]) đôi một khác nhau; |solution[r+1] − solution[r]| > 1. Mô hình này dùng cho bộ đếm nghiệm và generator.

### 2.2. Trạng thái tri thức

| Ký hiệu | Nghĩa |
| --- | --- |
| C | Tập N² ô |
| K | Tập kẹo đã biết chắc. Ở đầu level K = ∅ (không có given); trong Hint, K = các kẹo người chơi đã đặt đúng |
| E | Tập ô đã được chứng minh không có kẹo; E ∩ K = ∅ |
| conflict(a,b) | a ≠ b và cùng hàng, cùng cột, cùng vùng hoặc kề nhau |
| F(q) | {t : conflict(q,t)} |
| S1(K) | ⋃ F(q), q ∈ K |
| P | C \ (K ∪ E ∪ S1(K)) — tập ứng viên |
| U | Một đơn vị: hàng, cột hoặc vùng |
| P(U) | P ∩ U |

**Bất biến:** các phần tử của K đôi một không xung đột. Đơn vị đã có kẹo không cần ứng viên. Đơn vị chưa có kẹo mà P(U) = ∅ là **mâu thuẫn**.

**Ghi chú của người chơi (MARK) không phải tri thức.** Solver thuần dựng E chỉ từ chứng minh. Hint Engine dựng work board từ board người chơi nhưng chỉ giữ MARK không trùng ô nghiệm (xem §11); vì vậy Hint không bao giờ suy từ một mark sai.

## 3. Chuẩn của một bước suy luận

Một bước gồm: kỹ thuật, trạng thái trước bước (K, E), tiền đề (đơn vị/ô), kết luận (đặt một ô vào K hoặc thêm ô vào E) và lời giải thích.

| Quy tắc | Nội dung |
| --- | --- |
| Không no-op | Ô bị loại phải đang là ứng viên; ô được đặt phải chưa biết. Bước không đổi tri thức không được đếm vào độ khó |
| Tái dựng được | Checker dựng lại kết luận chỉ từ topology, K, E; không đọc `solution` |
| Ổn định | Tập kết quả loại trùng, sắp thứ tự xác định, tọa độ trong biên |
| Đúng hai lớp | (a) Đúng về đáp án: mọi nghiệm hợp tiền đề thỏa kết luận. (b) Đúng về kỹ thuật: điều kiện cục bộ của kỹ thuật được thỏa. Bước đúng (a) nhưng sai (b) vẫn bị từ chối |
| Không lý do vòng | "Vì chỉ có một nghiệm" không phải lời giải thích hợp lệ |
| Lời giải thích | Ba phần: điều đã biết → luật liên quan → kết luận. Tọa độ UI 1-based |

## 4. S1 — Elimination

| Mục | Nội dung |
| --- | --- |
| Điều kiện | q ∈ K |
| Kết luận | Mọi t ∈ F(q) ∩ P vào E |
| Chứng minh | Đặt kẹo ở t vi phạm trực tiếp ít nhất một ràng buộc 1–4 với q |
| Phản ví dụ | q=(1,3) loại (0,2),(0,4),(2,2),(2,4) do kề góc nhưng **không** loại (3,5) dù cùng đường chéo |
| Câu Hint | "Kẹo ở hàng 2 cột 4 đã chắc; các ô cùng hàng, cùng cột, cùng vùng màu và sát bên nó không thể có kẹo." |
| Triển khai | `_apply_elimination`: mọi ô BLANK mà `CandyRules.can_place` trả false thành MARK trên work board. Tính lại sau mỗi lần K tăng. Hint dùng `MARK_NEIGHBORS` để đề nghị người chơi tự đánh các mark này |

## 5. S2 — Single Candidate

| Mục | Nội dung |
| --- | --- |
| Điều kiện | U chưa có kẹo và P(U) = {q} |
| Kết luận | q vào K |
| Chứng minh | U cần đúng một kẹo; mọi vị trí khác đã bị loại bằng chứng minh, nên q bắt buộc |
| Phản ví dụ | Người chơi đánh MARK mọi ô của U trừ q, nhưng P(U) thực vẫn có hai ô → không được đặt q |
| Biến thể | Ô cuối của hàng, cột hoặc vùng. Vùng một ô là S2 ngay từ đầu. Nếu q là single của nhiều đơn vị, đó là **một** bước |
| Câu Hint | "Vùng màu A chỉ còn ô hàng 2 cột 3 có thể chứa kẹo." (`hint.single_zone` / `hint.single_row` / `hint.single_col`) |
| Triển khai | `_try_single_candidate`: duyệt vùng, rồi hàng, rồi cột; trả `cell`, `unit_type`, `unit_id`. Hint action `PLACE_CANDY` |

## 6. S3 — Lock Intersection

| Mục | Nội dung |
| --- | --- |
| Điều kiện | Source U, target V khác loại đơn vị, cả hai chưa có kẹo; \|P(U)\| ≥ 2 và P(U) ⊆ V |
| Kết luận | P(V) \ U vào E; tập này phải khác rỗng |
| Chứng minh | Kẹo duy nhất của U chắc chắn nằm trong V; V chỉ chứa một kẹo, nên phần V ngoài U không thể có kẹo |
| Mode | `zone_to_row`, `zone_to_col`, `row_to_zone`, `col_to_zone`. Hàng→cột chỉ có một ô giao, đã là S2 |
| Ví dụ | P(A) = {(2,1),(2,3)}, hàng 2 còn (2,5) ngoài A → loại (2,5); chưa biết (2,1) hay (2,3) |
| Phản ví dụ | A còn thêm (3,4) → không khóa A vào hàng 2. P(A) = ∅ là mâu thuẫn, không phải tiền đề S3 |
| Câu Hint | "Kẹo của vùng màu A chỉ có thể nằm ở hàng 3, nên các ô khác trên hàng 3 không có kẹo." |
| Triển khai | `_try_lock_intersection` trả `eliminated`, `mode`, `target_type`, `target_id`. Hint lọc ô đã MARK (`_filter_new_eliminations`) và trả `PLACE_MARKS` |

### 6.1. Ví dụ trọn bàn (fixture S301)

Fixture gốc trong `GDD/data/levels.sample.json`; không phải level phát hành.

```text
    c0 c1 c2 c3
r0   A  A  B  B
r1   C  C  C  B
r2   C  C  D  D
r3   D  D  D  D
```

| Bước | Kỹ thuật | Chứng cứ | Kết luận |
| --- | --- | --- | --- |
| 1 | S3 | P(A) ⊆ hàng 0 | Loại (0,2),(0,3) |
| 2 | S2 | P(B) = {(1,3)} | Đặt (1,3) |
| 3 | S2 | Cột 2: (0,2) đã loại, (1,2) cùng hàng, (2,2) kề (1,3) | Đặt (3,2) |
| 4 | S2 | P(C) = {(2,0)} | Đặt (2,0) |
| 5 | S2 | P(A) = {(0,1)} | Đặt (0,1) |

Nghiệm `[1,3,0,2]`. Ở trạng thái đầu không đơn vị nào có single, nên closure S2-only STUCK: bàn này **cần** S3. Encoding trace bank:

```json
{"rule":"S3","source":{"type":"region","id":"A"},"target":{"type":"row","id":0},"conclusion":{"type":"eliminate","cells":[{"r":0,"c":2},{"r":0,"c":3}]},"textKey":"hint.lock.intersection"}
{"rule":"S2","focus":{"type":"region","id":"B"},"conclusion":{"type":"place","r":1,"c":3},"textKey":"hint.single.region"}
```

## 7. S4–S6 — Locked Subset

Ba kỹ thuật cùng một điều kiện, khác kích thước k.

| Mục | Nội dung |
| --- | --- |
| Điều kiện | Tập Z gồm k vùng chưa có kẹo (2 ≤ k ≤ min(số vùng chưa đặt − 1, 6)); mỗi vùng có P(z) ≠ ∅; hợp các hàng (hoặc cột) chứa ứng viên của Z có đúng k phần tử R |
| Kết luận | Mọi ứng viên trên R thuộc vùng ngoài Z vào E |
| Chứng minh | k vùng rời nhau cần k kẹo khác nhau, mọi kẹo đó nằm trong R. R gồm k hàng, mỗi hàng chứa đúng một kẹo, nên toàn bộ sức chứa của R dành cho Z; ô ngoài Z trên R không thể có kẹo |
| Phản ví dụ | Một vùng trong Z còn ứng viên ở hàng thứ k+1 → không khóa. Chọn nguồn chồng lấn (một hàng và một vùng) rồi giả định cần hai kẹo khác nhau là sai: một kẹo ở giao thỏa cả hai |
| Lưu ý | Kết luận **không** gán vùng nào vào hàng nào. Nếu hợp chỉ có < k hàng, trạng thái mâu thuẫn, không phải tiền đề hợp lệ |
| Câu Hint | "Hai vùng màu A và C chỉ có thể đặt kẹo trong hàng 2 và 4. Vì vậy các ô khác trên hai hàng này không có kẹo." |
| Triển khai | `_try_locked_subsets` dùng bitmask hàng/cột precomputed (`_precompute_zone_masks`) và `_popcount`; duyệt k tăng dần, trả kết quả đầu tiên có loại mới. k=2 → S4, k=3 → S5, k≥4 → S6 (cùng nhãn `SUBSET_QUAD`) |

S3 dạng vùng→hàng là trường hợp k=1 của cùng nguyên lý. Phiên bản đối ngẫu (k hàng có ứng viên nằm gọn trong k vùng) là đúng về toán nhưng **chưa** được triển khai; xếp vào X3.

## 8. S7 — Contradiction Chain

| Mục | Nội dung |
| --- | --- |
| Điều kiện | q ∈ P. Trên bản sao, giả định q ∈ K; lặp {S1; kiểm mâu thuẫn; S2 nếu có} tới khi mâu thuẫn hoặc không còn S2 |
| Mâu thuẫn | Một hàng, cột hoặc vùng chưa có kẹo mà không còn ứng viên (`_check_contradiction`) |
| Kết luận | Nếu nhánh mâu thuẫn: q vào E. Nếu không mâu thuẫn: **không** kết luận gì (UNKNOWN) |
| Chứng minh | Phản chứng: mọi bước trong nhánh là hệ quả đúng của giả định; mâu thuẫn chứng tỏ giả định sai |
| Phản ví dụ | Nhánh dừng do giới hạn độ sâu hoặc hết S2 không mâu thuẫn → không được loại q. Không dùng "nhánh khác dẫn tới nghiệm" làm lý do |
| Chọn bước | Duyệt mọi ứng viên, giữ ô có chuỗi mâu thuẫn **ngắn nhất** (depth = số kẹo đặt trong nhánh) |
| Câu Hint | depth ≤ 2: `hint.chain_short`. depth > 2: `hint.chain_long` kèm tham số depth; nút Detail hiển thị `chain_detail` (ô giả định, các bước, đơn vị mâu thuẫn) |
| Triển khai | `_try_contradiction(max_depth)`; Hint dùng mặc định 99, `replay_solve` giới hạn depth 2. Nhánh chạy trên bản sao, không chạm session/Undo/tim |

## 9. Kỹ thuật mở rộng (Research)

Các mục sau chưa có trong solver, Hint, schema trace hay validator. Chỉ bật khi có encoding, checker, fixture dương/âm, Hint text và QA riêng.

### 9.1. X1 — Vùng cấm chung

U chưa có kẹo, P(U) ≠ ∅:

```text
remove = (P \ U) ∩ ⋂[p ∈ P(U)] F(p)
```

Chứng minh: U phải chọn một p, và mọi lựa chọn đều xung đột với t. Phải lấy **giao**, không phải hợp. S3 là trường hợp riêng theo hàng/cột/vùng; X1 bổ sung quan hệ kề. Ví dụ P(U) = {(2,2),(2,3)} ⇒ (1,2) kề cả hai, bị loại; nếu U còn (4,4) thì mất hiệu lực.

### 9.2. X2 — Ứng viên không có hỗ trợ

support(q,U) = {p ∈ P(U) : ¬conflict(q,p)}, với U chưa có kẹo, q ∉ U. Nếu support = ∅ thì loại q. Đây là X1 nhìn từ ô bị loại; không đếm thành hai kỹ thuật. Mở rộng sang cặp đơn vị cần duyệt hết mọi cặp; timeout là UNKNOWN.

### 9.3. X3 — Hall tổng quát

Tổng quát S4–S6 cho mọi cặp loại đơn vị (vùng↔hàng, vùng↔cột, hàng↔vùng, cột↔vùng): k nguồn rời nhau cùng loại có hợp ứng viên nằm trong k đích rời nhau cùng loại khác, có matching phủ nguồn → loại ứng viên trong đích ngoài nguồn. Kiểm mọi tập con nguồn mới phát hiện đủ vi phạm Hall. Có matching không chứng minh các ô ghép thỏa ràng buộc kề.

### 9.4. X4 — Sức chứa

cap(T) = số kẹo tối đa cùng đặt được trong T. Khối 2×2 có cap = 1 (bốn ô đôi một kề). Nếu k nguồn rời nhau có mọi ứng viên trong T mà cap(T) < k → mâu thuẫn. Chỉ dùng cận trên đã chứng minh. cap(T) = 1 **không** có nghĩa T phải chứa một kẹo.

### 9.5. CASE — Xét hết trường hợp

Nếu P(U) = {a,b}, chứng minh L trong cả nhánh a và nhánh b thì L đúng ở trạng thái cha. Với nhiều hơn hai ứng viên phải xét tất cả. Không ghép kết luận của hai nhánh đối nghịch; nhánh timeout không phải nhánh bị bác. S7 là trường hợp đặc biệt: một nhánh bị bác.

### 9.6. EXACT — Duyệt đầy đủ

Backtracking theo hàng: chọn cột chưa dùng, khác vùng đã dùng, không kề cột hàng trước; dừng khi tìm được nghiệm thứ hai.

| Kết quả | Diễn giải |
| --- | --- |
| Duyệt hết, 0 nghiệm | INVALID |
| Duyệt hết, 1 nghiệm | UNIQUE |
| Tìm được nghiệm thứ hai | MULTIPLE |
| Hết budget trước khi kết luận | UNKNOWN (kể cả khi đã thấy một nghiệm) |

EXACT là oracle kiểm tính đúng, không phải lời giải cho người chơi. Ruleset S1–S7 bị STUCK trên một bàn UNIQUE nghĩa là "chưa giải được bằng ruleset này", không phải "cần đoán". Không nhập chiến thuật của các thể loại puzzle khác khi chưa chứng minh lại cho luật một-kẹo của CanDoKu.

## 10. Vòng lặp solver

### 10.1. `replay_solve` (đánh giá độ khó)

```text
board = rỗng (K = ∅)
lặp tối đa 2N² lần, dừng khi đủ N kẹo:
    S1
    nếu S2: đặt kẹo; continue
    nếu S3: loại; continue
    nếu Locked Subset (k ≤ 6): loại; continue      # S4/S5/S6
    nếu S7 (depth ≤ 2): loại; continue
    STUCK
trả {solved, steps, profile{s1..s7}, max_technique}
```

Thứ tự ưu tiên luôn là kỹ thuật thấp nhất trước. `max_technique` là cận trên của kỹ thuật cần trên **đường ưu tiên thấp**, dùng làm đặc trưng độ khó ([GDD-11](11-level-generation.md)).

### 10.2. Hàm phụ trợ

| Hàm | Mục đích | Ruleset |
| --- | --- | --- |
| `solve_sequence` | Rank từng bước đặt (1 = S2, 2 = sau S3, 3 = fallback) | S1–S3 |
| `compute_cell_ranks` | Rank từng ô nghiệm (4 = không đạt bằng S1–S3) | S1–S3 |
| `next_hint` / `progressive_hint` | API solver cấp thấp (legacy); UI dùng `HintEngine.find_hint` | S2–S3 |

### 10.3. Closure và tính cần thiết

Với luật đơn điệu (chỉ thêm vào K hoặc E), closure của một ruleset là điểm cố định duy nhất. "Level cần S3" được chứng minh khi closure S1/S2 STUCK sau duyệt đủ mọi đơn vị **và** closure S1–S3 SOLVED. Một trace có bước S3 dư không chứng minh S3 bắt buộc. Timeout không được dùng làm bằng chứng STUCK.

## 11. Hint Engine

`HintEngine.find_hint(board, size, regions, solution)` trả kết quả đầu tiên theo thứ tự:

| # | Strategy | Nguồn | Action |
| --- | --- | --- | --- |
| 1 | `WRONG_MARK` | MARK trùng ô nghiệm (đọc `solution`) | `CLEAR_MARK` |
| 2 | `MARK_NEIGHBORS` | S1 quanh một kẹo đã đặt còn ô BLANK | `PLACE_MARKS` |
| 3 | `SINGLE_CANDIDATE` | S2 | `PLACE_CANDY` |
| 4 | `LOCK_INTERSECTION` | S3 | `PLACE_MARKS` |
| 5 | `LOCKED_SUBSET` | S4–S6 | `PLACE_MARKS` |
| 6 | `CONTRA_CHAIN` | S7 | `PLACE_MARKS` |
| 7 | `FALLBACK` | Ô nghiệm đầu tiên chưa đặt | `REVEAL` |

Work board của bước 3–6: giữ kẹo đã đặt, giữ MARK không trùng nghiệm, rồi áp S1. Các bước 3–6 suy luận không đọc `solution`; chỉ bước 1, 7 và bộ lọc mark dùng nó. Kết luận loại chỉ gồm ô người chơi chưa mark. Chi tiết UI (overlay, Apply/Dismiss/Detail, mutex, `hints_used`) ở [GDD-03](03-game-systems.md).

## 12. Kiểm chứng

| Nhóm | Điều kiện | Nơi kiểm |
| --- | --- | --- |
| Dương | Trạng thái có kết luận hợp lệ → kỹ thuật tìm đúng tập | `test_board_solver.gd`, `test_hint_engine.gd` |
| Âm | Thêm ứng viên phá khóa, bỏ tiền đề → không kết luận | `test_board_solver.gd` |
| No-op | Không trả kết luận rỗng hoặc trùng mark sẵn có | `test_hint_engine.gd` |
| Metamorphic | Xoay/lật/đổi nhãn (`board_transform`) giữ tính hợp lệ và độ khó | **Chưa có** test metamorphic |
| Oracle | Trên bàn nhỏ, mọi nghiệm EXACT thỏa kết luận | **Chưa có** test oracle |
| Isolation | S7 chạy trên bản sao; không đổi session/Undo/tim | **Chưa có** test isolation riêng |
| No-answer-leak | Đổi `solution` trong bản sao không đổi kết luận S2–S7 | `level_reasoning.py` (không nhận tham số solution) |
| Trace | Trace bank chỉ S2/S3; bước sai bị chặn | `validate_levels.py`, `validate_content.py` |

QA tương ứng: QA-05, QA-07, QA-18, QA-19, QA-57, QA-66 ([GDD-09](09-qa-acceptance.md)).

## 13. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| R-10-01 | Trace bank (`logicTrace`) chỉ mã hóa S2/S3; level N≥7 dùng S4–S7 có trace fallback | Validator không kiểm được bước nâng cao từng bước | Mở rộng schema trace khi cần chứng cứ S4–S7 |
| R-10-02 | Locked Subset chỉ duyệt vùng→hàng/cột | Bỏ sót bước đối ngẫu, có thể làm S7 xuất hiện sớm hơn cần | Đánh giá X3 trên bank N≥8 |
| R-10-03 | S6 gộp mọi k≥4 dưới một nhãn | Câu Hint cho k=5,6 khó đọc | Cân nhắc giới hạn Hint ở k≤4 |

## 14. Tham khảo

- Régin, *A Filtering Algorithm for Constraints of Difference in CSPs*, AAAI 1994 — nền tảng matching/all-different cho S4–S6, X3.
- Espasa et al., *Towards Generic Explanations for Pen and Paper Puzzles with MUSes*, 2021 — phân biệt giải được và giải thích được.

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất GDD 10 cũ; đồng bộ S4–S7 với `solver_techniques.gd`, ánh xạ strategy Hint Engine, bỏ givens (K bắt đầu rỗng) |
