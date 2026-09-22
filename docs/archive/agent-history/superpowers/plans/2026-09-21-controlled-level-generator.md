> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.

# Controlled Level Generator and Endless Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Biến thiết kế generator đã duyệt thành một công cụ sinh level có độ khó được kiểm soát, có thể chạy headless và trong game, rồi cấp nội dung Endless theo nhịp 3 Medium + 1 Hard + Hard/Recovery mà không làm thay đổi GR-01..04.

**Architecture:** GDScript thuần là implementation chuẩn cho sinh nghiệm/vùng, proof search, chấm độ khó, novelty và bounded search; cùng module chạy trong Godot headless và một worker tuần tự trên thiết bị. Python chỉ kiểm chéo record/level như một oracle độc lập. Scheduler, queue, save và UI chỉ nhận `GeneratedLevelRecord` đã qua mọi hard gate; không tự sửa nhãn, proof hoặc puzzle.

**Tech Stack:** Markdown và JSON UTF-8; Python 3 standard library `unittest`; Godot 4.x/GDScript sau khi Gói A khóa minor version; SHA-256; PCG32 tự cài đặt với số nguyên xác định; không thêm dependency mạng.

**Spec:** `GDD/12-sinh-level-do-kho-va-endless.md`

## Global Constraints

- Giữ nguyên GR-01..04 và schema level v4; level Endless dùng `level.order = 25` như sentinel nội dung sau campaign, còn thứ tự thật nằm ở `endlessOrdinal` của progress.
- Campaign vẫn có đúng 24 level gốc. `--release` tiếp tục chặn `hard`; validator record Endless là cổng riêng và được phép dùng `hard`.
- GDScript generator không gọi scene, asset, audio, RNG mặc định, thời gian hệ thống hoặc iteration order của `Dictionary` để quyết định kết quả.
- Mọi score/ranking trong generator dùng fixed-point integer. Không dùng float làm tie-break hoặc ghi vào fingerprint.
- `IndependentSolver` không nhận nghiệm gốc. Python validator không dùng code solver/proof của GDScript.
- Profile range, rule, S2 closure, readability và novelty đều là hard gate. Hết budget trả `insufficient_candidates`; không nới profile ngầm.
- Current record và queue record được lưu đầy đủ. Update generator/model không được đổi level đang chơi hoặc queue đã lưu.
- Proof Replay luôn dựng lại từ givens và evidence hợp lệ, mang nhãn “Một cách giải hợp lệ”; không dùng thao tác người chơi, `solution`, X hay X đỏ làm tiền đề.
- Corpus, asset, copy và UI phải là nội dung gốc; không nhập level/screenshot/tên/câu chữ của đối thủ.
- Workspace hiện không có `.git`; mỗi task kết thúc bằng checkpoint và lệnh kiểm tra, không có bước commit.
- Task 1 có thể chạy ngay. Task 2–7 chỉ chạy sau Gói A khóa Godot minor và Gói B/C cung cấp project/core/schema v4. Task 8–10 còn cần Gói D/F cung cấp save và UI shell. Nếu dependency chưa có, dừng ở checkpoint tương ứng; không dựng core/UI song song.

## Review Focus

- Determinism có thể hỏng do overflow 64-bit, right shift có dấu, sort không ổn định hoặc thứ tự `Dictionary`; golden PCG/canonical record và replay chéo headless/device phải bắt được.
- Generator và solver có thể cùng chia sẻ một lỗi; test phải ép GDScript record qua Python oracle và có negative fixtures độc lập.
- Level có thể được gắn đúng chữ `hard` nhưng sai range/rule/closure; record validator phải kiểm từng feature và profile gate, không tin nhãn.
- Worker có thể làm cạn queue hoặc cấp fallback sai profile; fake slow/failing worker phải chứng minh foreground không chờ và scheduler ghi rõ Recovery khi đổi slot.
- Migration/update có thể tái sinh level hiện tại; crash matrix phải so toàn bộ current record/puzzleHash trước và sau recovery.
- Replay có thể vô tình tiết lộ nghiệm hoặc mô tả đường chơi không có thật; replay test bắt đầu lại từ givens và chỉ dùng evidence được proof engine xác nhận.
- Sản phẩm có thể vẫn bị xem là bản sao dù level được sinh; provenance và similarity review là release gate, không phải checklist trang trí.

---

### Task 1: Hợp nhất GDD và khóa hợp đồng dữ liệu generator

**GDD/QA:** LV-09..12, TECH-22..24, UX-26/27, ORIG-01; QA-58..67.

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
- Modify: `GDD/11-ke-hoach-meta-va-sinh-level.md`
- Modify: `GDD/12-sinh-level-do-kho-va-endless.md`
- Modify: `design-control/00-design-status.md`
- Modify: `design-control/02-decision-log.md`
- Modify: `design-control/03-risk-register.md`
- Create: `GDD/data/generation/generation-profiles.v1.json`
- Create: `GDD/data/generation/difficulty-model.v1.json`
- Create: `GDD/data/generation/generated-records.sample.json`
- Create: `GDD/tools/generation_contracts.py`
- Create: `GDD/tools/test_generation_contracts.py`
- Modify: `GDD/tools/validate_levels.py`
- Modify: `GDD/tools/test_validate_levels.py`

**Interfaces:**
- Produces `load_profiles(path) -> dict[str, dict]`.
- Produces `load_difficulty_model(path) -> dict`.
- Produces `validate_generated_record(record, profiles, model, validate_level_fn) -> str`; callback giữ module contract độc lập, tránh circular import với CLI hiện có.
- Produces `recompute_difficulty_vector(level, model) -> dict` và `recompute_visual_vector(level, model) -> dict` bằng Python, không tin vector tự khai từ GDScript.
- Produces CLI mode `validate_levels.py --generated RECORDS PROFILE_SET MODEL` without changing semantics of `--release`.

- [ ] **Step 1: Viết test thất bại cho profile, model và record**

Tạo `test_generation_contracts.py` với các ca tối thiểu sau:

```python
class GenerationContractTests(unittest.TestCase):
    def test_all_six_profiles_are_valid(self):
        profiles = load_profiles(PROFILES)
        self.assertEqual(
            set(profiles),
            {
                "ENDLESS_RECOVERY_N5", "ENDLESS_MEDIUM_A_N5", "ENDLESS_MEDIUM_B_N5",
                "ENDLESS_MEDIUM_C_N6", "ENDLESS_HARD_A_N6", "ENDLESS_HARD_B_N6",
            },
        )

    def test_hard_record_must_fail_s2_closure(self):
        record = sample_record("ENDLESS_HARD_A_N6")
        record["difficultyVector"]["s2ClosureCompleted"] = True
        with self.assertRaisesRegex(ValueError, "s2 closure"):
            validate_generated_record(record, self.profiles, self.model, validate_level)

    def test_record_cannot_claim_score_outside_profile(self):
        record = sample_record("ENDLESS_MEDIUM_A_N5")
        record["difficultyVector"]["logicScore"] = 58
        with self.assertRaisesRegex(ValueError, "logicScoreRange"):
            validate_generated_record(record, self.profiles, self.model, validate_level)

    def test_endless_order_is_reserved_sentinel(self):
        record = sample_record("ENDLESS_MEDIUM_A_N5")
        record["level"]["order"] = 26
        with self.assertRaisesRegex(ValueError, "order 25"):
            validate_generated_record(record, self.profiles, self.model, validate_level)

    def test_level_and_record_ids_must_match(self):
        record = sample_record("ENDLESS_MEDIUM_A_N5")
        record["level"]["id"] = "GEN-OTHER"
        with self.assertRaisesRegex(ValueError, "record id"):
            validate_generated_record(record, self.profiles, self.model, validate_level)
```

Run:

```powershell
rtk python -m unittest GDD.tools.test_generation_contracts -v
```

Expected: FAIL vì module/hợp đồng mới chưa tồn tại.

- [ ] **Step 2: Ghi profile set v1 bằng số nguyên và mã ngắn bất biến**

`generation-profiles.v1.json` có top-level `profileVersion`, `profiles`; mỗi profile chứa đầy đủ trường trong GDD 12 và thêm `shortId`, `runtimeDifficulty`, `sizeOptions`. Dùng mapping:

```json
{
  "ENDLESS_RECOVERY_N5": [5, 25, 34, "R5", "easy"],
  "ENDLESS_MEDIUM_A_N5": [5, 35, 44, "MA5", "medium"],
  "ENDLESS_MEDIUM_B_N5": [5, 42, 51, "MB5", "medium"],
  "ENDLESS_MEDIUM_C_N6": [6, 48, 57, "MC6", "medium"],
  "ENDLESS_HARD_A_N6": [6, 58, 68, "HA6", "hard"],
  "ENDLESS_HARD_B_N6": [6, 66, 78, "HB6", "hard"]
}
```

Phần tử đầu tiên trong từng mảng trên là N duy nhất của `sizeOptions`. Các profile S2 có `allowedRules:["S2"]`, `requiredRules:[]`, `s2ClosureMustFail:false`; MEDIUM_C cho S2/S3 nhưng không bắt buộc S3 và giới hạn `s3StepsRange:[0,1]`; HARD_A/B yêu cầu S3 và `s2ClosureMustFail:true`. Mọi budget/range còn lại chép nguyên các dải đã duyệt trong GDD 12, không suy từ tên profile ở runtime. `fallbackProfileId` của Recovery trỏ chính nó; năm profile còn lại trỏ `ENDLESS_RECOVERY_N5`, nhưng chỉ scheduler được phép dùng trường này.

- [ ] **Step 3: Ghi difficulty model v1 fixed-point**

`difficulty-model.v1.json` dùng thang `1000` cho cost và `10000` cho hệ số:

```json
{
  "difficultyModelVersion": 1,
  "calibrationStatus": "bootstrap",
  "costScale": 1000,
  "coefficientScale": 10000,
  "ruleWeights": {"S2": 1000, "S3": 4000},
  "evidenceCellWeight": 100,
  "transitionWeight": 250,
  "featureCoefficients": {
    "proofCost": 4000,
    "dependencyDepth": 2500,
    "choiceScarcity": 2000,
    "scanLoad": 1500
  },
  "featureStats": {
    "proofCost": {"median": 8000, "iqr": 5000},
    "dependencyDepth": {"median": 5, "iqr": 4},
    "choiceScarcity": {"median": 2500, "iqr": 1500},
    "scanLoad": {"median": 40, "iqr": 24}
  },
  "visualWeights": {
    "areaVariance": 1500,
    "perimeterArea": 2000,
    "corners": 1500,
    "bottlenecks": 2000,
    "thinRun": 1500,
    "similarRegionPairs": 1000,
    "grayscaleFailure": 500
  },
  "grayscaleEvidenceVersion": 1
}
```

Document rõ đây là bootstrap phải được thay bằng model version mới sau playtest; không sửa file v1 tại chỗ sau khi đã phát hành record.

- [ ] **Step 4: Cài manual contract validator bằng Python standard library**

Trong `generation_contracts.py`, định nghĩa exact key sets và các hàm:

```python
PROFILE_KEYS = {
    "id", "shortId", "sizeOptions", "runtimeDifficulty", "logicScoreRange",
    "allowedRules", "requiredRules", "s2ClosureMustFail", "proofStepsRange",
    "s3StepsRange", "dependencyDepthRange", "givensRange", "maxVisualScore",
    "minNovelty", "candidateBudget", "mutationBudget", "fallbackProfileId",
}
RECORD_KEYS = {
    "recordVersion", "id", "generatorVersion", "difficultyModelVersion",
    "schedulerVersion", "seed", "profileId", "puzzleHash",
    "regionFingerprint", "proofFingerprint", "difficultyVector",
    "visualVector", "level",
}

def validate_generated_record(record, profiles, model, validate_level_fn):
    require_exact_keys(record, RECORD_KEYS, "generated record")
    profile = profiles[record["profileId"]]
    validate_level_fn(record["level"])
    require(record["level"]["order"] == 25, "generated level order must be 25")
    require(record["level"]["id"] == record["id"], "level id must match record id")
    require(record["level"]["difficulty"] == profile["runtimeDifficulty"], "difficulty/profile mismatch")
    require(record["difficultyModelVersion"] == model["difficultyModelVersion"], "model version mismatch")
    validate_profile_gates(record, profile)
    return f'{record["id"]}: generated record valid'
```

`validate_profile_gates` phải kiểm range inclusive cho logic score, proof steps, S3 steps, dependency depth, givens; tập rule used là subset/contains theo allowed/required. Profile chỉ-S2 bắt buộc closure hoàn tất; profile có `s2ClosureMustFail:true` bắt buộc closure thất bại; profile hỗn hợp không có cờ này chấp nhận cả hai kết quả nếu trace/range vẫn hợp lệ. Kiểm `visualScore <= maxVisualScore`, `novelty >= minNovelty`, SHA/fingerprint là lowercase hex 64 ký tự và ID khớp regex `GEN-[1-9][0-9]*-[A-Z0-9]+-[0-9A-HJKMNP-TV-Z]+`.

Python phải tự tính lại `puzzleHash`, canonical region/proof fingerprint, DifficultyVector và VisualVector từ level/trace/model rồi so chính xác với record. Hàm contract không được chỉ kiểm kiểu/range của vector do GDScript khai báo.

Oracle Python có `analyze_proofs(level, model, frontier_budget)` riêng: enumerate S2/S3 từ `(K,E)`, Dijkstra bằng integer cost, tính closure S2, proof DAG và alternate proof spread. Nó không gọi GDScript và không nhận `solution` để quyết định action; `solution` chỉ dùng để kiểm kết quả sau khi proof kết thúc. Visual oracle chuẩn hóa shape metrics theo integer bounds trong model và lấy grayscale pass/fail từ evidence version đã khóa.

- [ ] **Step 5: Thêm sample records dương/âm và CLI độc lập với release campaign**

`generated-records.sample.json` chứa ít nhất một record S2 và một record S3 đã được kiểm bằng solver Python. Không sao chép region từ campaign/đối thủ. Trong `validate_levels.py`, thêm sub-mode:

```text
validate_levels.py --generated RECORDS_JSON PROFILES_JSON MODEL_JSON
```

Mode này gọi `validate_generated_record(record, profiles, model, validate_level)`, rồi tự chạy `count_solutions(level["regions"], level["givens"], limit=2)` và xác nhận nghiệm duy nhất trùng `level.solution`. Nó không gọi `validate_document(data, release=True)` nên không đụng cổng 24 level.

- [ ] **Step 6: Hợp nhất tài liệu canonical trong cùng thay đổi**

Nâng snapshot lên GDD v0.6.0 và thực hiện đủ 11 mục ở GDD 12 §14. Chốt thêm ba chi tiết triển khai:

1. `level.order=25` là sentinel của mọi record Endless; `endlessOrdinal` là thứ tự hiển thị/lưu tiến trình.
2. Profile map sang enum v4: Recovery→easy, Medium→medium, Hard→hard.
3. `--release` chỉ kiểm campaign; `--generated` kiểm record Endless.

Trong GDD 08, tách Gói K thành `K1 — Generator foundation` trước M2 và `K2 — Endless runtime` sau Core/Save; economy/ads/cat collection vẫn post-MVP và không trở thành dependency generator. Ghi decision log mới, cập nhật risk về store similarity và đổi trạng thái GDD 12 từ candidate sang canonical appendix.

- [ ] **Step 7: Chạy toàn bộ cổng contract**

Run:

```powershell
rtk python -m unittest discover GDD/tools -p "test_*.py" -v
rtk python GDD/tools/validate_levels.py GDD/data/levels.sample.json
rtk python GDD/tools/validate_levels.py --generated GDD/data/generation/generated-records.sample.json GDD/data/generation/generation-profiles.v1.json GDD/data/generation/difficulty-model.v1.json
rtk rg -n "generator.*post-MVP|Endless.*post-MVP|kết thúc.*level 24" GDD design-control
```

Expected: test/validator PASS; lệnh consistency chỉ còn lịch sử hoặc economy post-MVP được gắn nhãn rõ. Checkpoint: canonical contract tồn tại trước khi viết GDScript.

---

### Task 2: Cài deterministic primitives và canonical serialization

**GDD/QA:** LV-10, TECH-22; QA-58.

**Dependency:** Gói A đã tạo `game/project.godot` và khóa Godot minor; nếu chưa có, thực hiện Gói A trước Task này.

**Files:**
- Create: `game/src/generation/u64.gd`
- Create: `game/src/generation/stable_rng.gd`
- Create: `game/src/generation/canonical_json.gd`
- Create: `game/src/generation/generation_ids.gd`
- Create: `game/data/generation/generator-manifest.v1.json`
- Create: `game/tests/generation/test_determinism.gd`
- Create: `game/tests/generation/test_runner.gd`

**Interfaces:**
- `StableRng.new(seed:int, stream:int).next_u32() -> int`
- `StableRng.next_bounded(bound:int) -> int` dùng rejection sampling.
- `CanonicalJson.encode(value:Variant) -> PackedByteArray`
- `GenerationIds.puzzle_hash(level:Dictionary) -> String`
- `GenerationIds.generated_id(generator_version:int, short_id:String, seed:int) -> String`

- [ ] **Step 1: Viết golden test trước implementation**

```gdscript
func test_pcg32_reference_sequence() -> void:
    var rng := StableRng.new(42, 54)
    assert_eq(
        [rng.next_u32(), rng.next_u32(), rng.next_u32(), rng.next_u32(), rng.next_u32()],
        [0xA15C02B7, 0x7B47F409, 0xBA1D3330, 0x83D2F293, 0xBFA4784B]
    )

func test_canonical_json_ignores_dictionary_insertion_order() -> void:
    assert_eq(CanonicalJson.encode({"b": 2, "a": 1}), CanonicalJson.encode({"a": 1, "b": 2}))
```

Run `rtk godot --headless --path game --script res://tests/generation/test_runner.gd`; expected FAIL.

- [ ] **Step 2: Cài PCG32 không dựa vào signed overflow**

`u64.gd` biểu diễn unsigned 64-bit bằng hai limb `hi`/`lo` 32-bit và cung cấp `add`, `mul`, `xor`, `shr`, `rotr32`. `stable_rng.gd` dùng PCG-XSH-RR multiplier `6364136223846793005`, odd increment `(stream << 1) | 1`, và quy trình seed reference: state 0 → step → add seed → step. `next_bounded` tính threshold bằng arithmetic u32 để loại modulo bias. Không thay bằng `RandomNumberGenerator`.

- [ ] **Step 3: Cài canonical JSON và ID**

Encoder chỉ nhận null/bool/int/string/array/dictionary; key dictionary phải là string và được sort bytewise UTF-8. Escape JSON đúng chuẩn, không thêm whitespace, từ chối float. `puzzle_hash` encode đúng array `[size, regions, givens sorted by (r,c), solution]`. Base32 dùng alphabet Crockford bỏ I/L/O/U như regex ở Task 1.

Manifest v1 ghi `generatorVersion:1`, Godot minor đã khóa ở Gói A, `rngAlgorithm:"pcg32-xsh-rr-v1"`, `canonicalSerialization:"json-int-v1"` và mutation order của Task 3. Test startup so Godot minor hiện hành với manifest; mismatch phải từ chối sinh record thay vì tiếp tục dưới cùng generatorVersion.

- [ ] **Step 4: Chạy golden test hai lần trong process riêng**

```powershell
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- determinism
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- determinism
```

Expected: hai run PASS và in cùng digest suite. Checkpoint: mọi task sau chỉ dùng `StableRng` và `CanonicalJson`.

---

### Task 3: Sinh nghiệm và vùng liên thông bằng property tests

**GDD/QA:** GR-01..04, LV-09/10, TECH-22; QA-58/62.

**Files:**
- Create: `game/src/generation/solution_generator.gd`
- Create: `game/src/generation/region_generator.gd`
- Create: `game/src/generation/candidate_mutator.gd`
- Create: `game/src/generation/generation_constraints.gd`
- Create: `game/tests/generation/test_map_generation.gd`

**Interfaces:**
- `SolutionGenerator.generate(size:int, rng:StableRng) -> PackedInt32Array`
- `RegionGenerator.generate(size:int, solution:PackedInt32Array, rng:StableRng, motif:String) -> PackedStringArray`
- `CandidateMutator.mutate(candidate:Dictionary, mutation_index:int, rng:StableRng) -> Dictionary`
- `GenerationConstraints.validate_geometry(candidate:Dictionary) -> Array[String]`

- [ ] **Step 1: Viết property test 100 seed cho mỗi N=4..6**

Mỗi solution phải là hoán vị cột, không có hai mèo kề chéo. Mỗi map phải có đúng N label, mỗi vùng liên thông 4-neighbor, phủ N² ô và chứa đúng một mèo nghiệm. Cùng seed/motif phải cho cùng bytes; seed khác phải tạo ít nhất hai fingerprint trong batch 100.

- [ ] **Step 2: Cài solution backtracking với ordering xác định**

Tại mỗi row, tạo danh sách cột chưa dùng và không kề chéo mèo hàng trước, shuffle bằng Fisher–Yates dùng `StableRng`, rồi backtrack. Khi hết nhánh, tiếp tục theo thứ tự đã shuffle; không dùng hash set iteration để chọn cột.

- [ ] **Step 3: Cài multi-source region growth**

Đặt một seed vùng tại từng ô nghiệm. Frontier chứa tuple `(shape_cost, region_id, r, c)` và được stable-sort; tie-break bằng một khóa RNG lấy đúng một lần khi node vào frontier. Shape cost fixed-point là `30*area_balance + 25*perimeter + 20*corner + 15*bottleneck + 10*motif`, đúng trọng số GDD 12. Chỉ nhận ô nếu không làm vùng mất khả năng liên thông hoặc khóa một seed khác.

- [ ] **Step 4: Cài mutation hợp lệ và kiểm lại từ đầu**

Mutation types có enum/order cố định: boundary shift, two-cell boundary swap, local region regrow, solution swap-and-regrow, given add/remove. Mỗi mutation tạo candidate mới, rồi chạy `validate_geometry`; không sửa in-place candidate đã archive. Givens chỉ lấy từ solution, unique row, và nằm trong profile range.

- [ ] **Step 5: Chạy property suite**

```powershell
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- map_generation --seeds 100
```

Expected: 300 seed PASS, không invalid geometry và deterministic digest ổn định.

---

### Task 4: Xây solver độc lập và proof search S2/S3 tối thiểu

**GDD/QA:** LV-09, TECH-22, GR-21..24; QA-58/59/62/65.

**Files:**
- Create: `game/src/generation/independent_solver.gd`
- Create: `game/src/generation/proof_state.gd`
- Create: `game/src/generation/proof_searcher.gd`
- Create: `game/src/generation/proof_fingerprint.gd`
- Create: `game/tests/generation/fixtures/proof_cases.json`
- Create: `game/tests/generation/test_solver_and_proof.gd`

**Interfaces:**
- `IndependentSolver.count_solutions(regions, givens, limit:=2, node_budget:=2000000) -> Dictionary`
- `ProofSearcher.search(level, model, frontier_budget:int) -> Dictionary`
- `ProofSearcher.s2_closure(level) -> Dictionary`
- Search result: `{status, logicTrace, proofCost, dependencyDag, metrics}`.

- [ ] **Step 1: Viết negative/positive fixtures độc lập**

Fixtures phải có: 0 nghiệm, 2 nghiệm, 1 nghiệm S2, 1 nghiệm cần S3, S3 no-op, proof timeout/frontier budget. Test không truyền `level.solution` vào solver; sau solver mới so nghiệm tìm được với khai báo.

- [ ] **Step 2: Cài exact-cover style DFS đếm tối đa hai nghiệm**

State theo row/column/region và diagonal adjacency; chọn row chưa gán có ít candidate nhất, tie-break row index. Trả `status:"budget_exceeded"` riêng, không coi là unique. Module không import `SolutionGenerator` hoặc đọc field `solution`.

- [ ] **Step 3: Cài state `(K,E)` và action enumeration**

`K` là PackedInt32Array cột theo row với `-1` chưa biết; `E` là bitset N². Liệt kê toàn bộ S2 row/column/region và S3 source→target hợp lệ. Action canonical key là `(rule_rank, source_type, source_id, target_type, target_id, conclusion_cells)`; luôn sort key trước khi đưa vào frontier.

- [ ] **Step 4: Cài Dijkstra và S2 closure**

Cost mỗi action lấy từ model fixed-point. State key encode `K` rồi `E`; nếu cost mới không thấp hơn cost đã biết thì bỏ. Khi đủ N mèo, reconstruct trace schema v4, DAG phụ thuộc và metrics. `s2_closure` chỉ enumerate S2, trả `completed`, `steps`, `stalledState`; profile cần S3 chỉ đạt nếu closure không completed nhưng search S2/S3 completed.

- [ ] **Step 5: Kiểm chéo mọi fixture qua Python**

Export các level schema v4 chứa trace fixture sang `build/test-output/proof-levels.json`, rồi chạy:

```powershell
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- solver_proof
rtk python GDD/tools/validate_levels.py build/test-output/proof-levels.json
```

Expected: solver/proof tests PASS; Python nhận mọi trace dương và từ chối fixtures âm tương ứng.

---

### Task 5: Chấm DifficultyVector, VisualVector và model version

**GDD/QA:** LV-09, TECH-22; QA-59/62.

**Files:**
- Create: `game/src/generation/difficulty_model.gd`
- Create: `game/src/generation/difficulty_rater.gd`
- Create: `game/src/generation/visual_rater.gd`
- Create: `game/tests/generation/test_difficulty_rating.gd`
- Create: `GDD/tools/calibrate_difficulty.py`
- Create: `GDD/tools/test_calibrate_difficulty.py`

**Interfaces:**
- `DifficultyModel.load(path) -> DifficultyModel`
- `DifficultyRater.rate(proof_result, model) -> Dictionary`
- `VisualRater.rate(regions) -> Dictionary`
- `calibrate_difficulty.py INPUT_CSV --out-model OUTPUT_MODEL_JSON --out-report OUTPUT_REPORT_MD`

- [ ] **Step 1: Viết exact-vector tests**

Dùng proof fixture cố định để assert đủ `proofSteps`, `s2Steps`, `s3Steps`, `dependencyDepth`, `choiceScarcity`, `scanLoad`, `unitTransitions`, `maxEvidenceCells`, `alternateProofSpread`, `proofCost`, `logicScore`, `s2ClosureCompleted`. Test thay model version phải thay score nhưng không thay raw vector/trace.

- [ ] **Step 2: Cài fixed-point normalization và score**

Chuẩn hóa robust bằng `normalized = clamp(0,100000, 50000 + 25000*(x-median)/iqr)` với integer division half-away-from-zero. Tính logic score bằng coefficients 4000/2500/2000/1500 rồi round về 0..100. `choiceScarcity` cộng `costScale / max(1, validDeductionsAtState)`.

- [ ] **Step 3: Cài visual metrics và cổng readability**

Tính area variance, perimeter/area, corners, one-cell bottlenecks, thin-run, similar-region pairs và grayscale channel result. `visualScore` dùng integer weights có version trong model; nếu chưa có ảnh/theme, grayscale result là `not_measured` và record chỉ được dùng trong authoring, không được đóng fallback/runtime.

- [ ] **Step 4: Cài calibration tool không ghi đè model**

Tool đọc CSV đúng field GDD 12 §6.4, xuất file model có version mới và báo cáo Markdown; từ chối `--out-model` trùng file model hiện hữu. Bootstrap v1 không tự đổi khi chạy calibration.

- [ ] **Step 5: Chạy tests**

```powershell
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- difficulty
rtk python -m unittest GDD.tools.test_calibrate_difficulty -v
```

Expected: raw vector ổn định, score đúng golden và model cũ không bị sửa.

---

### Task 6: Novelty filter và bounded quality-diversity search

**GDD/QA:** LV-10/11, TECH-22; QA-58..62.

**Files:**
- Create: `game/src/generation/fingerprints.gd`
- Create: `game/src/generation/novelty_filter.gd`
- Create: `game/src/generation/generation_search.gd`
- Create: `game/src/generation/generated_record_builder.gd`
- Create: `game/tests/generation/test_novelty_and_search.gd`

**Interfaces:**
- `Fingerprints.region(regions)`, `solution(solution)`, `proof(dag)`.
- `NoveltyFilter.evaluate(candidate, exact_hashes, recent_fingerprints, corpus) -> {accepted, novelty, reason}`.
- `GenerationSearch.generate(profile, seed, count, context) -> {status, records, dominantRejections}`.

- [ ] **Step 1: Viết D4 and near-duplicate tests**

Tám phép quay/đối xứng cộng đổi nhãn vùng phải cho cùng canonical region fingerprint. Hai puzzle khác solution phải khác puzzleHash. Exact hash history luôn reject. Near duplicate dưới `minNovelty` reject; level cùng score nhưng shape/proof khác rõ phải pass.

- [ ] **Step 2: Cài canonical fingerprints**

Với mỗi D4 transform: normalize label theo lần xuất hiện row-major, encode region+solution đã transform, chọn byte string nhỏ nhất. Proof fingerprint canonical hóa node/action theo key Task 4, không theo thứ tự object trong memory.

- [ ] **Step 3: Cài novelty fixed-point**

Novelty là weighted distance 0..10000 của region, solution, shape vector, motif, proof DAG/rule string và quantized difficulty/visual vector. Mọi weight lưu trong profile/model version. `minNovelty:0.70` trong JSON được contract loader chuyển chính xác thành integer 7000 trước search; GDScript không so float.

- [ ] **Step 4: Cài bounded quality-diversity beam search**

Archive key là `(logic_bucket, depth_bucket, s3_steps, motif, givens_count)`. Loss gồm khoảng cách tới range + hard violation sentinel + visual penalty + similarity penalty; hard violation không bao giờ được accepted dù loss thấp. Candidate/mutation counter tăng theo thứ tự cố định. Khi đủ count, stable-sort accepted theo `(loss, regionFingerprint, proofFingerprint, puzzleHash)`.

- [ ] **Step 5: Trả lỗi có cấu trúc khi hết budget**

Kết quả failure phải đúng:

```json
{"status":"insufficient_candidates","requested":20,"accepted":13,"dominantRejections":["s2_closure_completed","visual_score","near_duplicate"]}
```

`dominantRejections` sort theo count giảm dần rồi reason tăng dần. Không gọi fallback bên trong search; scheduler/queue sở hữu quyết định fallback.

- [ ] **Step 6: Chạy property/budget tests**

```powershell
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- novelty_search --seeds 100
```

Expected: deterministic; profile impossible trả lỗi, không có accepted record ngoài hard gates.

---

### Task 7: Đóng gói công cụ Godot headless và oracle report

**GDD/QA:** LV-09..11, TECH-22; QA-58..62/66.

**Files:**
- Create: `game/tools/generate_levels.gd`
- Create: `game/tools/generation_cli_args.gd`
- Create: `GDD/tools/compare_generation_runs.py`
- Create: `GDD/tools/test_compare_generation_runs.py`
- Create: `design-control/originality/generated-level-provenance.csv`
- Create: `game/data/endless_fallback/README.md`

**Interfaces:**
- CLI nhận `--profiles`, `--profile`, `--model`, `--seed`, `--count`, `--out`, `--corpus`.
- Mỗi run xuất `records.json`, `report.json`, `provenance.csv`; exit 0 chỉ khi đủ count và Python oracle pass ở pipeline gọi ngoài.

- [ ] **Step 1: Viết CLI argument/error tests**

Thiếu version/profile, output đã tồn tại, seed ngoài u32 hoặc count <=0 phải exit non-zero và không ghi partial records. `--out` luôn là thư mục mới; không overwrite candidate cũ.

- [ ] **Step 2: Cài headless CLI bằng cùng `GenerationSearch`**

CLI không có bản thuật toán riêng. Nó load JSON contract, gọi search, ghi file qua temp+rename. Provenance row chứa record ID, seed, generator/model/profile versions, UTC generation timestamp chỉ làm metadata, puzzleHash, fingerprints và `source=original-generator`; timestamp không tham gia kết quả.

- [ ] **Step 3: Cài comparator và golden capture**

`compare_generation_runs.py` so thứ tự ID, puzzleHash, trace canonical và vectors giữa hai thư mục; bỏ qua timestamp/path. Sau khi implementation pass, chạy seed `42001`, count `5` cho từng profile hai lần và lưu digest thật vào `game/tests/generation/fixtures/golden-run-digests.json`. Đây là capture output thực tế, không điền hash giả.

- [ ] **Step 4: Chạy batch nhỏ và kiểm chéo Python**

```powershell
rtk godot --headless --path game --script res://tools/generate_levels.gd -- --profiles ../GDD/data/generation/generation-profiles.v1.json --profile ENDLESS_MEDIUM_A_N5 --model ../GDD/data/generation/difficulty-model.v1.json --seed 42001 --count 5 --out ../build/run-a
rtk godot --headless --path game --script res://tools/generate_levels.gd -- --profiles ../GDD/data/generation/generation-profiles.v1.json --profile ENDLESS_MEDIUM_A_N5 --model ../GDD/data/generation/difficulty-model.v1.json --seed 42001 --count 5 --out ../build/run-b
rtk python GDD/tools/compare_generation_runs.py build/run-a build/run-b
rtk python GDD/tools/validate_levels.py --generated build/run-a/records.json GDD/data/generation/generation-profiles.v1.json GDD/data/generation/difficulty-model.v1.json
```

Expected: comparator và oracle PASS; hai run giống trừ metadata timestamp.

- [ ] **Step 5: Sinh fallback corpus có provenance**

Sau khi 100-seed property suite pass, sinh ít nhất 20 record cho mỗi profile vào `game/data/endless_fallback/v1/{profile_id}/records.json`; chạy Python oracle, exact/near duplicate audit và append manifest provenance. Không hand-edit record đã sinh.

Checkpoint: đây là công cụ authoring hoàn chỉnh có thể dùng trước khi Endless runtime tồn tại.

---

### Task 8: Cài scheduler, worker queue và fallback không chặn foreground

**GDD/QA:** LV-12, TECH-23, UX-27; QA-63.

**Dependency:** Gói D cung cấp progress service và Gói F có UI shell/event bus.

**Files:**
- Create: `game/src/endless/endless_scheduler.gd`
- Create: `game/src/endless/generated_queue.gd`
- Create: `game/src/endless/generation_worker.gd`
- Create: `game/src/endless/fallback_repository.gd`
- Create: `game/tests/endless/test_endless_scheduler.gd`
- Create: `game/tests/endless/test_generated_queue.gd`

**Interfaces:**
- `EndlessScheduler.profile_for(cycle:int, slot:int, prior:Array, availability:Dictionary) -> Dictionary`.
- `GeneratedQueue.take_next(decision) -> GeneratedLevelRecord`.
- `GenerationWorker.request(profile_id, seed_start, count)`; kết quả chỉ được publish về main thread qua mutex-protected mailbox.

- [ ] **Step 1: Viết scheduler table tests**

Khóa mapping role→profile: MA=`ENDLESS_MEDIUM_A_N5`, MB=`ENDLESS_MEDIUM_B_N5`, MC=`ENDLESS_MEDIUM_C_N6`, HA=`ENDLESS_HARD_A_N6`, HB=`ENDLESS_HARD_B_N6`, Recovery=`ENDLESS_RECOVERY_N5`. Slots 1..4 luôn MA/MB/MC/HA. Slot 5 là HB khi bốn summary đều first-attempt win, tổng hints <=1, mistakes <=2, không Restart; chỉ một điều kiện sai thì Recovery. Không đọc elapsed time. Cycle mới quay lại MA.

- [ ] **Step 2: Viết slow/failing worker tests**

Fake worker không trả kết quả trong 10 giây mô phỏng: `take_next` phải trả record fallback đúng profile ngay, không wait. Nếu profile target hết cả queue và fallback, scheduler phải trả decision `{requested:HARD_B, delivered:RECOVERY, reason:"profile_unavailable"}` và lấy Recovery; không gắn nhãn Recovery thành Hard.

- [ ] **Step 3: Cài scheduler version 1**

Decision lưu `schedulerVersion`, cycle, slot, requested/delivered profile, reason. Summary input chỉ có win/attempt/hints/mistakes/restarted; reject field thời gian khỏi readiness function để tránh vô tình dùng.

- [ ] **Step 4: Cài queue target 10/min 5**

Queue index theo profile, reject duplicate puzzleHash/history trước enqueue. Khi tổng compatible record dưới 5, request worker theo các slot sắp tới. Worker chỉ chạy một search tuần tự; không tạo nhiều worker theo core count. Main thread poll mailbox theo budget, không join thread trong gameplay.

- [ ] **Step 5: Tích hợp fallback repository**

Load corpus đã Python-verified ở Task 7; kiểm record version/profile/model khi load. Exact hash đã chơi thì bỏ và thử record tiếp; nếu cạn profile, báo availability về scheduler.

- [ ] **Step 6: Chạy queue tests và profiler smoke**

```powershell
rtk godot --headless --path game --script res://tests/endless/test_runner.gd -- scheduler queue
```

Expected: không test nào chờ worker; mọi fallback đúng delivered profile. Device p95/main-thread/30-minute soak được ghi ở Task 11, không giả lập thành pass ở đây.

---

### Task 9: Nâng progress/session, lịch sử hash và crash recovery

**GDD/QA:** TECH-24, LV-10/11; QA-64.

**Files:**
- Modify: `game/src/persistence/progress_store.gd`
- Modify: `game/src/persistence/session_store.gd`
- Create: `game/src/persistence/progress_v3_migrator.gd`
- Create: `game/src/endless/generation_history_store.gd`
- Create: `game/src/endless/crc32.gd`
- Create: `game/tests/endless/fixtures/progress_v2.json`
- Create: `game/tests/endless/test_endless_persistence.gd`
- Modify: `GDD/data/interactions.sample.json`
- Modify: `GDD/tools/test_interaction_contract.py`

**Interfaces:**
- Progress v3 thêm `mode`, `endlessOrdinal`, `cycle`, `slot`, `schedulerVersion`, `readinessSummaries`, `currentGeneratedRecord`, `generatedQueue`, `generationVersions`, `historyRef`.
- History binary: magic `EGH1`, tiếp theo các record 20 byte = 16 byte prefix SHA-256 + CRC32 little-endian của 16 byte đó.

- [ ] **Step 1: Viết migration/crash matrix trước**

Test v2→v3 giữ nguyên campaign current/session/results. Test v3 reload giữ exact current/queue bytes. Với mỗi điểm lỗi temp write, backup replace, progress replace, history append và compaction, recovery phải chọn bản hợp lệ gần nhất; không gọi generator để dựng lại current.

- [ ] **Step 2: Cài migration idempotent**

v2 campaign trở thành v3 với `mode:"campaign"`, `endlessOrdinal:1`, `cycle:1`, `slot:1`, queue rỗng. Chạy migrator lần hai không đổi bytes canonical. Chuyển sang Endless chỉ sau khi campaign completed đủ 24 ID canonical.

- [ ] **Step 3: Cài atomic save đầy đủ record**

Ghi canonical JSON vào `.tmp`, flush/close, validate lại, rotate file hiện hành sang `.bak`, rename temp. Khi load, ưu tiên main hợp lệ, rồi backup; không ghi file rỗng lên cả hai. Session của generated level tham chiếu record ID+puzzleHash nhưng progress giữ full record.

- [ ] **Step 4: Cài append-only history và recent window**

`crc32.gd` dùng polynomial `0xEDB88320`. Khi đọc gặp CRC sai/truncated tail, bỏ tail sau record hợp lệ cuối và báo recovery event. Recent 256 entries trong progress giữ region/proof fingerprints; compaction ghi file mới, validate, rồi atomic replace.

- [ ] **Step 5: Đồng bộ Python interaction fixture**

Thêm vector hoàn tất L24 chuyển mode Endless, app restart giữa queue save, corrupt current progress dùng backup và update generator giữ full record cũ. Python reference model không cần sinh level; nó chỉ kiểm state transition/persistence contract.

- [ ] **Step 6: Chạy persistence tests**

```powershell
rtk godot --headless --path game --script res://tests/endless/test_runner.gd -- persistence
rtk python -m unittest GDD.tools.test_interaction_contract -v
```

Expected: crash matrix PASS và puzzleHash current không đổi ở mọi recovery case.

---

### Task 10: Proof Replay, Nhịp Vườn và cổng originality

**GDD/QA:** UX-26/27, ORIG-01; QA-65..67.

**Files:**
- Create: `game/src/endless/proof_replay_builder.gd`
- Create: `game/src/ui/proof_replay_controller.gd`
- Create: `game/scenes/ui/proof_replay.tscn`
- Create: `game/src/ui/garden_rhythm_presenter.gd`
- Create: `game/tests/endless/test_proof_replay.gd`
- Create: `design-control/originality/provenance-register.csv`
- Create: `design-control/originality/clean-room-checklist.md`
- Create: `design-control/originality/similarity-review-template.md`

**Interfaces:**
- `ProofReplayBuilder.build(level, proof_searcher) -> Array[HintEvidence]`.
- `GardenRhythmPresenter.state_for(decision) -> stroll|reflect|challenge`.

- [ ] **Step 1: Viết replay tests từ givens**

Cho cùng level nhưng hai session người chơi khác nhau, replay output phải giống nhau. Xóa `solution` khỏi bản sao input trước khi builder chạy; mỗi evidence được revalidate ở state trước đó. Assert label exact “Một cách giải hợp lệ”, close action, reduced-motion path và accessible description cho từng evidence.

- [ ] **Step 2: Cài builder không dùng player path**

Builder tạo state mới từ givens, gọi proof search với model/version record, chuyển từng S2/S3 thành HintEvidence hiện hành và apply conclusion. Nếu proof/version thiếu hoặc invalid, ẩn nút replay và log structured reason; không fallback sang việc tô nghiệm.

- [ ] **Step 3: Cài UI và Nhịp Vườn**

Replay có Previous/Next/Close, focus order, screen-reader text, pattern/label không phụ thuộc màu và chế độ reduced motion bỏ tween. Rhythm map Recovery/MA→`stroll`, MB/MC→`reflect`, HA/HB→`challenge`; chỉ báo nhịp, không lộ rule hoặc ô tiếp theo.

- [ ] **Step 4: Tạo hồ sơ clean-room có owner/evidence**

Provenance register có cột `itemId,type,author,createdDate,sourceFile,licenseOrOwnership,generatorSeed,versions,reviewer,status`. Checklist cấm dữ liệu đối thủ như GDD 12. Similarity review chấm riêng icon, listing, onboarding, HUD, board, Result, animation; mọi mục `too_similar` phải có action/owner và chặn submission.

- [ ] **Step 5: Chạy replay/accessibility tests**

```powershell
rtk godot --headless --path game --script res://tests/endless/test_runner.gd -- proof_replay
```

Expected: replay independent với player path; mọi step có evidence hợp lệ. Device screen reader/visual review vẫn là cổng thủ công ở Task 11.

---

### Task 11: Chạy cổng tích hợp, hiệu năng và bàn giao công cụ

**GDD/QA:** LV-09..12, TECH-22..24, UX-26/27, ORIG-01; QA-58..67.

**Files:**
- Create: `game/tests/generation/run_property_suite.gd`
- Create: `game/tests/endless/run_soak_test.gd`
- Create: `design-control/reviews/02-controlled-generator-review.md`
- Modify: `GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md`
- Modify: `design-control/00-design-status.md`

- [ ] **Step 1: Chạy regression của repository**

```powershell
rtk python -m unittest discover GDD/tools -p "test_*.py" -v
rtk python GDD/tools/validate_levels.py GDD/data/levels.sample.json
rtk godot --headless --path game --script res://tests/generation/test_runner.gd -- all
rtk godot --headless --path game --script res://tests/endless/test_runner.gd -- all
```

Expected: mọi suite PASS; không giảm coverage MVP cũ.

- [ ] **Step 2: Chạy QA-62 ở hai cấp**

PR/local gate dùng ≥100 seed/profile. Nightly/release gate dùng ≥10.000 seed/profile và xuất report rejection distribution, max frontier, generation latency. Bất kỳ invalid GR/connectivity/uniqueness/proof/profile nào là fail, không chỉ warning.

- [ ] **Step 3: Chạy cross-platform determinism QA-58**

Chạy cùng golden inputs trên desktop headless và thiết bị mục tiêu đã chốt; dùng comparator Task 7. Chỉ đạt khi accepted ID order, puzzleHash, trace và vectors giống tuyệt đối. Nếu Godot minor khác, coi là generatorVersion mới thay vì sửa golden cũ.

- [ ] **Step 4: Đo runtime thật QA-63**

Trên thiết bị thấp M1: p95 accepted level ≤3 giây trên worker, main-thread spike <5 ms, soak 30 phút không chạm đáy queue. Ghi thiết bị/build/profile/count/raw percentile vào review. Nếu fail, tăng fallback hoặc giảm runtime budget có version; không bỏ validation/range.

- [ ] **Step 5: Chạy crash/update và replay/originality gates**

Thực hiện QA-64 trên build thật bằng kill app ở từng điểm save; QA-65 với screen reader/reduced motion; QA-66 audit 100% manifest; QA-67 review có người ký. Không đánh dấu release-ready nếu còn mục provenance trống hoặc similarity action chưa đóng.

- [ ] **Step 6: Ghi báo cáo và trạng thái thực tế**

`02-controlled-generator-review.md` phải liệt kê từng QA-58..67, command/build/device, kết quả, evidence path và rủi ro còn lại. Chỉ đổi design status sang implemented khi toàn bộ cổng tương ứng có bằng chứng; nếu chỉ Task 1–7 xong, ghi rõ “authoring tool complete; Endless runtime pending”.

## Spec Coverage Matrix

| Spec area | Owning task |
| --- | --- |
| Canonical GDD, profiles, model, record contract | Task 1 |
| PCG32, canonical serialization, IDs | Task 2 |
| Solution/region/mutation | Task 3 |
| Independent uniqueness and S2/S3 proof | Task 4 |
| Difficulty/visual vectors and calibration | Task 5 |
| Novelty and bounded search | Task 6 |
| Headless authoring tool and fallback corpus | Task 7 |
| 3 Medium + Hard + Hard/Recovery, queue | Task 8 |
| Full-record save, history, migration | Task 9 |
| Proof Replay, Garden Rhythm, clean-room | Task 10 |
| Property/device/soak/release evidence | Task 11 |
