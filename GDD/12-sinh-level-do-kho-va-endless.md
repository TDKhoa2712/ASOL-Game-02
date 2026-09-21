# 12 — Sinh level, độ khó có kiểm soát và Endless Garden

**Trạng thái:** đặc tả ứng viên đã được duyệt về hướng trong phiên thiết kế ngày 2026-09-21; chờ duyệt văn bản trước khi thay đổi luật chuẩn, schema save, fixture, validator và kế hoạch triển khai hiện hành.

Tài liệu này giữ nguyên GR-01..04 và thiết kế thao tác hiện hành. Nó mở rộng hệ thống nội dung theo ba mục tiêu: sinh level đúng độ khó yêu cầu, duy trì nhịp ba level trung bình rồi một đến hai level khó, và cung cấp nội dung thực tế không cạn sau 24 level dẫn nhập. Khi tài liệu này được hợp nhất, nó thay quyết định “generator chỉ sau MVP” trong D-09/DEC-012; các thay đổi liên quan phải được cập nhật đồng bộ theo §14.

## 1. Quyết định và ranh giới

### 1.1. Quyết định

1. Giữ nguyên bốn luật nền GR-01..04: đúng một mèo mỗi hàng, cột và vùng; mèo không chạm nhau kể cả góc.
2. Giữ 24 level đầu làm dãy dẫn nhập được duyệt thủ công. Level 1–18 chỉ dùng S1/S2; level 19–24 bắt buộc cần S3 theo LV-08.
3. Sau level 24, mở `Endless Garden`. Level được sinh cục bộ, offline và kiểm chứng trước khi đưa vào hàng đợi chơi.
4. Generator nhận một `GenerationProfile`, không chỉ một nhãn `easy/medium/hard`. Profile khóa dải điểm, tập quy tắc, chiều sâu proof, givens, độ đọc hình và mức mới lạ.
5. Cùng lõi generator GDScript chạy trong game và bằng Godot headless cho content designer. Python validator tiếp tục là oracle độc lập.
6. Generator không thay thế duyệt người cho 24 level đầu, level mốc hoặc các batch phát hành được quảng bá riêng.

### 1.2. Không thuộc phạm vi

- Không sinh level từ dữ liệu, screenshot hoặc level của game khác.
- Không dùng S4/S5 cho tới khi các cổng ở GDD 10 được mở bằng quyết định riêng.
- Không dùng mạng, tài khoản, quảng cáo hoặc server để sinh level.
- Không tăng độ khó vô hạn. Endless dùng một đường khó dạng sóng trong các envelope đã kiểm chứng.
- Không cam kết “vô hạn toán học”. Không gian trạng thái là hữu hạn; mục tiêu là nội dung thực tế không cạn đối với một vòng đời chơi bình thường.

## 2. Thành phần và luồng dữ liệu

```text
GenerationProfile + seed + generatorVersion
                    │
                    ▼
          sinh nghiệm và vùng
                    │
                    ▼
     kiểm GR/liên thông/nghiệm duy nhất
                    │
                    ▼
       proof search S2/S3 tối thiểu
                    │
                    ▼
       DifficultyVector + VisualVector
                    │
                    ▼
 profile gate + novelty gate + budgets
          │ đạt                    │ trượt
          ▼                        └── mutate/reject
 GeneratedLevelRecord
          │
          ├── Godot headless: batch ứng viên + báo cáo biên tập
          └── Runtime: hàng đợi Endless đã kiểm chứng
```

Các đơn vị phải tách trách nhiệm:

| Thành phần | Trách nhiệm |
| --- | --- |
| `SolutionGenerator` | Sinh hoán vị mèo thỏa GR-01/02/04 |
| `RegionGenerator` | Tạo N vùng liên thông, mỗi vùng chứa đúng một mèo nghiệm |
| `CandidateMutator` | Dịch biên, tái sinh cục bộ, đổi nghiệm hoặc givens mà vẫn kiểm lại toàn bộ ràng buộc |
| `IndependentSolver` | Đếm 0/1/2 nghiệm, độc lập với nghiệm gốc |
| `ProofSearcher` | Liệt kê S2/S3, tìm đường chứng minh có chi phí thấp nhất và kiểm closure S2 |
| `DifficultyRater` | Tạo vector thô và điểm `0..100` theo model có version |
| `NoveltyFilter` | Loại trùng hoặc quá giống lịch sử/corpus |
| `GenerationSearch` | Tìm kiếm có ngân sách để đạt profile và giữ nhiều họ ứng viên |
| `EndlessScheduler` | Chọn profile cho slot tiếp theo từ chu kỳ và kết quả chơi cục bộ |
| `GeneratedQueue` | Sinh trước, lưu bền vững và cấp level đã kiểm chứng cho gameplay |

## 3. Hợp đồng profile và đầu ra

`GenerationProfile` là dữ liệu authoring có version; không nằm trong level schema v4:

```json
{
  "profileVersion": 1,
  "id": "ENDLESS_HARD_A_N6",
  "sizeOptions": [6],
  "logicScoreRange": [58, 68],
  "allowedRules": ["S2", "S3"],
  "requiredRules": ["S3"],
  "s2ClosureMustFail": true,
  "proofStepsRange": [8, 14],
  "s3StepsRange": [1, 2],
  "dependencyDepthRange": [6, 10],
  "givensRange": [0, 1],
  "maxVisualScore": 45,
  "minNovelty": 0.70,
  "candidateBudget": 800,
  "mutationBudget": 2400,
  "fallbackProfileId": "ENDLESS_RECOVERY_N5"
}
```

Ràng buộc GR, liên thông, nghiệm duy nhất và proof hợp lệ là **ràng buộc cứng**. Các trường range cũng là cổng cứng đối với level được ghi nhận dưới profile đó. `fallbackProfileId` chỉ cho scheduler đổi slot một cách công khai khi không còn level cùng profile trong pool; nó không cho phép gắn nhãn Hard lên level Recovery.

Level đầu ra vẫn dùng schema v4. Dữ liệu biên tập đi kèm nằm trong `GeneratedLevelRecord`:

```json
{
  "recordVersion": 1,
  "id": "GEN-1-HA6-00CM3B7Q",
  "generatorVersion": 1,
  "difficultyModelVersion": 1,
  "schedulerVersion": 1,
  "seed": 264219031,
  "profileId": "ENDLESS_HARD_A_N6",
  "puzzleHash": "<sha256>",
  "regionFingerprint": "<canonical-shape-hash>",
  "proofFingerprint": "<canonical-proof-hash>",
  "difficultyVector": {},
  "visualVector": {},
  "level": {}
}
```

`level` là object schema v4 hoàn chỉnh và chứa `logicTrace` chuẩn. Runtime Hint vẫn tính lại evidence từ trạng thái hiện tại theo GR-21..24; không chạy theo con trỏ trace.

## 4. Thuật toán sinh map

### 4.1. Sinh nghiệm

Sinh hoán vị `solution[0..N-1]` bằng randomized backtracking có forward checking:

1. Chọn cột chưa dùng cho hàng kế tiếp.
2. Từ chối nếu `abs(solution[r] - solution[r-1]) <= 1`.
3. Ưu tiên cột có ít lựa chọn hợp lệ cho hàng sau để giảm backtrack.
4. Phá hòa bằng PRNG xác định từ `seed`.
5. Hết ngân sách mà chưa có nghiệm thì đổi nhánh seed nội bộ; không trả nghiệm thiếu.

GR-01/02/04 đúng theo xây dựng. GR-03 được tạo ở bước phân vùng.

### 4.2. Sinh vùng liên thông

Mỗi ô nghiệm là một seed vùng cố định. Dùng multi-source growth trên lân cận bốn hướng:

1. Khởi tạo N vùng, mỗi vùng chứa một ô nghiệm riêng.
2. Tạo frontier gồm các ô chưa gán kề cạnh từng vùng.
3. Chọn cặp `(vùng, ô)` có chi phí hình thấp nhất, có nhiễu xác định từ seed.
4. Gán ô vào vùng; tính lại frontier.
5. Lặp đến khi mọi ô có nhãn.

Vì vùng chỉ lớn lên qua cạnh chung nên luôn liên thông. Ô nghiệm của vùng khác không nằm trong frontier có thể nhận, nên mỗi vùng chứa đúng một mèo nghiệm.

Chi phí hình ban đầu:

```text
shapeCost =
    0.30 × areaImbalance
  + 0.25 × perimeterGrowth
  + 0.20 × oneCellNeckPenalty
  + 0.15 × thinRunPenalty
  + 0.10 × motifDeviation
```

Trong implementation, các hệ số trên được biểu diễn fixed-point nguyên `30/25/20/15/10`, không dùng thứ tự so sánh float. Các hệ số thuộc `generatorVersion`; thay hệ số phải tăng version và chạy lại cổng QA. Đối xứng/xoay/lật chỉ là motif, không được tính là level mới khi fingerprint trùng.

### 4.3. Mutation hợp lệ

`CandidateMutator` dùng các phép sau:

- Chuyển một ô biên sang vùng kề nếu bỏ ô không làm vùng nguồn đứt và thêm ô giữ vùng đích liên thông.
- Tái sinh một cửa sổ chữ nhật nhỏ, khóa mọi ô nghiệm và biên ngoài cửa sổ.
- Sinh nghiệm mới rồi phân vùng lại với cùng motif.
- Thêm, bỏ hoặc chuyển given trong `givensRange`; sau mỗi thay đổi phải đếm lại nghiệm và tìm lại proof.

Không sửa trực tiếp `solution` để cứu một map đã khai báo. Mỗi mutation tạo một ứng viên mới và chạy lại toàn bộ validator liên quan.

## 5. Nghiệm duy nhất và proof search

`IndependentSolver` đếm nghiệm với giới hạn 2, không tin nghiệm đã dùng để sinh. Kết quả hợp lệ phải là đúng một nghiệm và trùng `solution` khai báo.

`ProofSearcher` dùng trạng thái `(K,E)` của GDD 10:

- `K`: given và mèo đã chứng minh.
- `E`: loại trừ S3 đã chứng minh.
- S1 được dựng lại từ `K`.
- Action là mọi S2/S3 hợp lệ ở trạng thái hiện tại.

Tìm đường proof ít chi phí nhất bằng Dijkstra có phá hòa ổn định. Hai trạng thái có cùng `K,E` được gộp; action được sắp theo loại rule, unit ID và tọa độ trước khi đưa vào frontier. Khi đủ N mèo, trả trace tối thiểu và fingerprint của đồ thị phụ thuộc.

Chạy thêm closure chỉ-S2:

- Profile S2 yêu cầu closure hoàn tất và trace không chứa S3.
- Profile yêu cầu S3 phải có `s2ClosureMustFail=true`, trace hoàn tất bằng S2/S3 và có số bước S3 trong range.

Timeout, frontier vượt ngân sách hoặc không có proof đều là kết quả từ chối, không phải “khó”.

## 6. Mô hình độ khó

### 6.1. Tách bốn khái niệm

| Lớp | Ý nghĩa | Có dùng để gắn nhãn khó? |
| --- | --- | --- |
| Hợp lệ | GR, liên thông, nghiệm duy nhất, proof | Cổng bắt buộc, không phải difficulty |
| Logic | Chi phí và cấu trúc đường suy luận người-mô-phỏng | Có |
| Thị giác | Map khó đọc, vùng ngoằn ngoèo, phụ thuộc màu | Chỉ là cổng readability; không được nâng nhãn |
| Quan sát | Thời gian, Hint, lỗi, Restart và đánh giá người chơi | Dùng hiệu chỉnh model |

Không dùng riêng N, số given, số node brute-force hoặc thời gian solver làm độ khó người chơi.

### 6.2. DifficultyVector

Mỗi ứng viên lưu vector thô:

| Trường | Định nghĩa |
| --- | --- |
| `proofSteps` | Tổng số action S2/S3 của proof tối thiểu |
| `s2Steps`, `s3Steps` | Số bước theo rule |
| `dependencyDepth` | Đường phụ thuộc dài nhất trong proof DAG |
| `choiceScarcity` | `sum(1 / max(1, validDeductionsAtState))` trên trace |
| `scanLoad` | Tổng số ô/đơn vị cần hiển thị để giải thích các bước |
| `unitTransitions` | Số lần focus chuyển giữa row/column/region |
| `maxEvidenceCells` | Số ô tô sáng lớn nhất trong một bước |
| `alternateProofSpread` | Chênh lệch chi phí giữa proof tốt nhất và các proof hợp lệ kế tiếp trong ngân sách |

`proofCost` được tính từ model artifact, không hard-code vào generator:

```text
stepCost = ruleWeight
         + evidenceCellWeight × highlightedCells
         + transitionWeight × changedUnitType
proofCost = sum(stepCost)
```

Bootstrap model v1 dùng `ruleWeight(S2)=1`, `ruleWeight(S3)=4`; các trọng số còn lại và tham số chuẩn hóa nằm trong `difficulty-model.v1.json`. Model artifact chứa version, coefficients, feature medians và IQR của corpus hiệu chỉnh nên cùng level luôn nhận cùng điểm với cùng model.

Điểm logic `0..100`:

```text
logicScore = clamp(0, 100,
    0.40 × normalizedProofCost
  + 0.25 × normalizedDependencyDepth
  + 0.20 × normalizedChoiceScarcity
  + 0.15 × normalizedScanLoad)
```

Đây là bootstrap có version, không phải chân lý thiết kế. Khi thay coefficients sau playtest phải tạo model version mới; không thay puzzle đã phát hành hoặc level hiện tại.

### 6.3. VisualVector

`VisualVector` gồm chênh lệch diện tích vùng, chu vi/diện tích, số góc, số cổ chai một ô, thin-run dài nhất, số cặp vùng gần giống và kết quả kiểm thang xám. `visualScore` càng cao càng khó đọc. Level vượt `maxVisualScore` bị sửa hoặc loại; không được gọi là Hard để hợp thức hóa map xấu.

### 6.4. Hiệu chỉnh bằng playtest

CSV playtest chứa `levelId`, participant ẩn danh cục bộ, hoàn thành, elapsed, Hint, lỗi, Restart, bước kẹt lâu nhất và difficulty tự đánh giá 1–5. Công cụ calibration:

1. Giữ raw features.
2. Fit model thứ tự/robust regression dự đoán difficulty chủ quan và median solve time.
3. So thứ hạng với bootstrap.
4. Xuất model artifact mới cùng báo cáo sai lệch.
5. Designer duyệt trước khi model được dùng để sinh level mới.

Lỗi thao tác được ghi riêng và không dùng như bằng chứng rằng logic khó.

## 7. Tìm kiếm có kiểm soát

`GenerationSearch` dùng bounded quality-diversity beam search:

1. Sinh tập ứng viên ban đầu.
2. Loại ứng viên vi phạm ràng buộc cứng.
3. Tính loss đối với profile:

```text
loss = distanceToDifficultyRanges
     + profileViolationPenalty
     + visualPenalty
     + similarityPenalty
```

4. Giữ beam tốt nhất, nhưng chia archive theo bucket `logicScore`, `dependencyDepth`, `s3Steps`, motif và givens để không hội tụ về một họ map.
5. Mutation ứng viên gần đích cho tới khi đạt `mutationBudget`.
6. Chấp nhận khi mọi range đạt và novelty qua ngưỡng.
7. Phá hòa bằng fingerprint để cùng seed/profile/version cho cùng kết quả bất kể máy.

Tính tái tạo xuyên nền tảng dùng `StableRng` PCG32 được đóng trong module generator, fixed-point cho mọi score/ranking, sort ổn định và một worker sinh tuần tự. Không phụ thuộc implementation RNG mặc định, iteration order của dictionary, số core hay timing thread của Godot. `generatorVersion` đồng thời khóa Godot minor, thuật toán RNG, thứ tự mutation và canonical serialization.

Profile không đạt đủ `count` trong ngân sách phải trả lỗi có cấu trúc:

```json
{
  "status": "insufficient_candidates",
  "requested": 20,
  "accepted": 13,
  "dominantRejections": ["s2_closure_completed", "visual_score", "near_duplicate"]
}
```

Không tự nới range, tăng givens, bỏ S3 hoặc hạ novelty.

## 8. Profile chuẩn và nhịp Endless

Các dải bootstrap cho N=4–6:

| Profile | Score | Rule | Proof/dependency | Vai trò |
| --- | ---: | --- | --- | --- |
| `RECOVERY` | 25–34 | S2 | proof ngắn, ≥2 suy luận khả dụng ở đa số state | Hạ nhịp sau khó |
| `MEDIUM_A` | 35–44 | S2 | depth 3–6 | Vào chu kỳ |
| `MEDIUM_B` | 42–51 | S2 | depth 4–7, choice ít hơn | Tăng nhẹ |
| `MEDIUM_C` | 48–57 | S2/S3 | depth 5–8, tối đa 1 S3 dễ nhìn | Chuẩn bị đỉnh |
| `HARD_A` | 58–68 | S2/S3 | cần 1–2 S3, depth 6–10 | Đỉnh bắt buộc |
| `HARD_B` | 66–78 | S2/S3 | cần S3, proof dài hoặc choice hiếm | Đỉnh thứ hai có điều kiện |

Dải có thể chồng nhau vì score không phải điều kiện duy nhất; rule, depth, visual và novelty vẫn phải đạt profile. `hard` tiếp tục bị chặn trong 24 level đầu nhưng được dùng cho level Endless đã kiểm chứng.

### 8.1. Chu kỳ năm slot

```text
1 MEDIUM_A
2 MEDIUM_B
3 MEDIUM_C
4 HARD_A
5 HARD_B nếu ready; nếu không thì RECOVERY
```

`ready` không dùng thời gian. Slot 5 là `HARD_B` khi bốn level trước đều thắng trong lượt đầu, tổng Hint ≤1, tổng lỗi ≤2 và không Restart. Nếu không, slot 5 là `RECOVERY`. Sau slot 5 bắt đầu chu kỳ mới.

Scheduler chỉ chọn profile; không thay luật, nghiệm, tim hoặc điểm trong một level đã sinh. Mọi quyết định dựa trên dữ liệu local và có `schedulerVersion`.

### 8.2. Không leo thang vô hạn

Sau khi người chơi đã vào Endless, score envelope không tăng mãi. Variation đến từ map, proof, motif và đường suy luận. Model/profile mới chỉ được thêm qua update có version và QA riêng.

## 9. Runtime và công cụ biên tập

### 9.1. Một lõi GDScript

Generator chuẩn là module logic thuần GDScript, không import scene, asset hoặc audio. Nó chạy:

- trên worker thread trong game;
- bằng Godot headless để sinh batch;
- trong unit/property tests.

CLI authoring dự kiến:

```text
godot --headless --path game --script res://tools/generate_levels.gd -- \
  --profile GDD/data/profiles/endless-hard-a-n6.json \
  --seed 42001 --count 20 --out build/level-candidates
```

Python `validate_levels.py` kiểm chéo các batch xuất ra. Hai implementation chia sẻ fixture, không chia sẻ code solver, để cùng một lỗi không tự xác nhận chính nó.

### 9.2. Hàng đợi sinh trước

- Mục tiêu 10 level đã kiểm chứng; ngưỡng thấp là 5.
- Sinh nền chỉ bắt đầu sau khi gameplay/UI đã có tài nguyên cần thiết.
- Không chặn main thread chờ generator.
- Mỗi profile active có ít nhất 20 level fallback được đóng gói từ pipeline headless và kiểm bằng Python.
- Khi queue dưới 5, worker ưu tiên profile của các slot kế tiếp.

Mục tiêu thiết bị M1: p95 sinh một level được chấp nhận ≤3 giây trên worker của thiết bị thấp đã chốt, không tạo main-thread spike >5 ms, và soak test 30 phút không để người chơi chạm đáy queue. Đây là cổng đo thật; nếu không đạt, tăng pool đóng gói hoặc giảm budget runtime, không bỏ validator.

## 10. ID, save và version

ID level sinh tự động:

```text
GEN-<generatorVersion>-<profileShortId>-<base32(seed)>
```

`profileShortId` là mã bất biến, duy nhất trong `profileVersion`; vì vậy cùng seed dùng ở hai profile không thể tạo hai puzzle khác nhau có chung ID.

`progressVersion` mới phải lưu:

- trạng thái campaign 1–24;
- `mode=campaign|endless`;
- ordinal Endless tiếp theo;
- cycle/slot và `schedulerVersion`;
- summaries dùng tính `ready`;
- current record và queue record **đầy đủ**, không chỉ seed;
- version của generator/model/profile;
- tham chiếu tới lịch sử hash đã chơi.

Level hiện tại và queue được lưu đầy đủ để update generator không đổi puzzle. `puzzleHash` vẫn là SHA-256 canonical puzzle data. Lịch sử exact hash dùng file binary append-only gồm prefix SHA-256 128 bit cùng CRC từng block; recent window 256 record giữ thêm region/proof fingerprints để lọc near-duplicate. Compaction phải nguyên tử và có bản trước hợp lệ.

Nếu update generator khi đang chơi:

1. Giữ current và queue cũ đã lưu.
2. Level sinh mới dùng version mới sau khi queue cũ cạn hoặc bị invalid rõ ràng.
3. Không tái dùng cùng ID cho puzzle khác.
4. Save hỏng phục hồi bản atomic trước; không “tái sinh gần giống” level hiện tại.

## 11. Đa dạng và chống lặp

Fingerprint gồm:

- canonical region shape dưới tám phép D4 và đổi nhãn;
- nghiệm canonical;
- vector diện tích, chu vi, góc, cổ chai;
- motif;
- proof DAG canonical và chuỗi rule;
- difficulty/visual vector đã lượng tử hóa.

Exact `puzzleHash` đã chơi bị loại vĩnh viễn trên profile người dùng đó. Near-duplicate so với recent window bị loại nếu novelty dưới profile. Với corpus offline, không cho hai level cùng canonical region fingerprint trong cùng batch và áp cửa sổ tối thiểu tám level như LV-04.

Motif là metadata trình bày/biên tập, không phải luật ẩn. Bộ motif ban đầu: `luống-bậc-thang`, `lối-suối`, `tán-cây`, `vòng-sân`, `góc-hiên`. Motif chỉ điều khiển shape objective và trang trí gốc; người chơi không phải suy ra motif để thắng.

## 12. Bản sắc và clean-room

Giữ GR-01..04 làm rủi ro so sánh còn lại. Generator không tự tạo khác biệt nhìn thấy, nên sản phẩm phải có các dấu hiệu riêng:

1. `Proof Replay` ở Result cho xem từng bước S2/S3 bằng evidence do engine dựng lại. Replay được ghi rõ là “Một cách giải hợp lệ”, tái dựng từ givens ban đầu và không tuyên bố phản ánh đường suy nghĩ thật của người chơi.
2. Endless hiển thị “Nhịp Vườn” theo trạng thái Dạo vườn/Suy ngẫm/Thử thách, không chỉ một số level vô tận.
3. Vùng dùng ngôn ngữ luống vườn, nhãn và họa tiết gốc; accessibility không phụ thuộc màu.
4. Tên, icon, HUD, font, copy, mèo, animation, âm thanh, sticker và store screenshot đều được tạo độc lập.
5. Mỗi asset có tác giả, ngày, file nguồn và quyền; mỗi level có seed/version hoặc biên bản thủ công.

Clean-room cấm:

- nhập hoặc trace screenshot/level đối thủ;
- dùng level đối thủ làm corpus, seed, training set hoặc benchmark novelty;
- sao chép tên thương mại, mô tả store, câu Hint, icon hoặc bố cục màn;
- quảng bá như phiên bản/thay thế/chuyển thể của game khác khi không có quyền.

Luật chơi trừu tượng không đồng nghĩa với bảo đảm qua store review. Apple Guideline 4.1 có thể từ chối ứng dụng chỉ thay đổi nhỏ tên/UI; Google Play yêu cầu nội dung hoặc quyền sử dụng hợp lệ. Trước submission cần similarity review riêng cho icon, listing, onboarding, HUD, board, Result và animation.

## 13. Mã yêu cầu và QA mới

### 13.1. Yêu cầu

| ID | Yêu cầu |
| --- | --- |
| LV-09 | Mỗi level sinh có DifficultyVector/VisualVector, model version và profile; runtime JSON vẫn schema v4 |
| LV-10 | Cùng seed/profile/generator/model version tái tạo cùng kết quả và thứ tự ứng viên |
| LV-11 | Exact duplicate bị chặn; near-duplicate đạt novelty; provenance đầy đủ |
| LV-12 | Endless dùng chu kỳ 3 Medium + Hard + Hard/Recovery, không tăng khó vô hạn |
| TECH-22 | Lõi generator GDScript thuần dùng chung runtime/headless; Python validator là oracle độc lập |
| TECH-23 | Worker queue sinh trước, fallback cùng profile và không chặn main thread |
| TECH-24 | Save current/queue đầy đủ, lịch sử hash append-only và migration progress atomic |
| UX-26 | Proof Replay dựng từ evidence hợp lệ, đóng được, giảm chuyển động và screen reader đọc được |
| UX-27 | Nhịp Vườn báo slot difficulty sắp tới nhưng không lộ nghiệm hoặc rule bí mật |
| ORIG-01 | Asset, level, copy, tên và UI có provenance gốc; clean-room và similarity review trước submission |

### 13.2. QA

| ID | Ca | Kết quả bắt buộc |
| --- | --- | --- |
| QA-58 | Chạy lại cùng seed/profile/version trên headless và device | Cùng accepted IDs, puzzleHash và trace |
| QA-59 | Sinh batch theo từng profile | 100% level accepted nằm trong mọi range; không chỉ đúng nhãn |
| QA-60 | Profile hiếm không đạt count | Lỗi `insufficient_candidates`; không nới range/givens/rule/novelty |
| QA-61 | Corpus nhiều motif/profile | Không exact canonical duplicate; near-duplicate dưới ngưỡng đã công bố |
| QA-62 | Property test generator | PR: ≥100 seed/profile; nightly: ≥10.000 seed/profile; không level sai GR/liên thông/nghiệm/proof |
| QA-63 | Queue thấp, worker chậm hoặc lỗi | Gameplay dùng fallback đúng profile hoặc scheduler ghi Recovery; không chờ foreground |
| QA-64 | Crash/update/save hỏng khi ở Endless | Current puzzle không đổi; queue/progress phục hồi atomic; ID không tái nghĩa |
| QA-65 | Proof Replay sau khi người chơi hoàn tất theo thứ tự khác trace | Tái dựng một proof hợp lệ từ givens, ghi đúng nhãn “Một cách giải hợp lệ”, không dùng solution/X/X đỏ làm tiền đề; accessibility đạt |
| QA-66 | Audit provenance | Mỗi level/asset/copy có nguồn; không có dữ liệu đối thủ trong corpus |
| QA-67 | Similarity review trước store submission | Icon/listing/onboarding/HUD/board/Result/animation có biên bản và action cho điểm quá giống |

## 14. Kế hoạch hợp nhất nếu văn bản được duyệt

Tài liệu này thay đổi tiến trình và phạm vi nên không được cập nhật một phần. Cùng một thay đổi phải:

1. Sửa GDD README: D-01/D-09 và thêm quyết định generator/Endless.
2. Sửa GDD 01 về phạm vi 24 level dẫn nhập + Endless.
3. Sửa GDD 02: GR-26..28 và state sau level 24; thêm luật scheduler/queue không ảnh hưởng board.
4. Sửa GDD 03: màn/entry Endless, Nhịp Vườn và Proof Replay.
5. Sửa GDD 04: LV-09..12, profile, difficulty và pipeline sinh.
6. Sửa GDD 05: TECH-22..24, progress/session version, interfaces và worker.
7. Sửa GDD 07: QA-58..67 và cổng batch/device/provenance.
8. Sửa GDD 08: tách generator foundation trước M2, Endless runtime sau core/save ổn định.
9. Sửa GDD 09 và decision log bằng quyết định mới thay phần generator của REV-GD-03/DEC-012.
10. Sửa GDD 11 để bỏ mô tả generator là nghiên cứu post-MVP; meta economy vẫn post-MVP.
11. Thêm profile/model/fixture mẫu và test migration/progress/generator; chạy validator fixture hiện có.

Cho tới khi các mục trên được triển khai đồng bộ, luật chạy vẫn là GDD v0.5.0 và app kết thúc nội dung sau level 24.

## 15. Nguồn nghiên cứu

- [Procedural Puzzle Generation: A Survey](https://www.scss.tcd.ie/Mads.Haahr/papers/de-kegel-2020-transactions.pdf) — các họ phương pháp sinh puzzle, ràng buộc solvability và rủi ro nội dung lặp.
- [Difficulty Rating of Sudoku Puzzles by a Computational Model](https://cdn.aaai.org/ocs/2517/2517-11201-1-PB.pdf) — độ phức tạp bước và cấu trúc phụ thuộc là hai nguồn difficulty quan trọng.
- [Procedurally Puzzling: On Algorithmic Difficulty and Player Experience](https://ojs.aaai.org/index.php/AIIDE/article/view/31873) — constrained quality-diversity và giới hạn của difficulty proxy từ solver.
- [U.S. Copyright Office — Games](https://www.copyright.gov/register/tx-games.html) và [Circular 33](https://www.copyright.gov/circs/circ33.pdf) — phân biệt phương pháp chơi với biểu đạt chữ/hình.
- [Apple App Review Guideline 4.1](https://developer.apple.com/app-store/review/guidelines/) và [Google Play Intellectual Property policy](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en) — cổng copycat/IP của nền tảng.
