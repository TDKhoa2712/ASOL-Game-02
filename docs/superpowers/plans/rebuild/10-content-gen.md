# Module 10: Content Generation — Level Banks & Campaign Playlist

> **Phụ thuộc:** Module 3 (Content) cho bank schema + validator
> **Mục tiêu:** Tạo level data thực tế để game chơi được. Sau module này, game có đủ 30 levels cho playtest.

## Tổng quan

Module 9 modules trước tạo code hoàn chỉnh nhưng game cần DATA để chạy: level banks, pace sidecars, và campaign playlist. Module này dùng tools có sẵn (`GDD/tools/generate_levels.py`, `GDD/tools/validate_levels.py`) để sinh và validate level data theo bank schema mới.

---

## Bước 1: Sinh levels cho bank 4×4

**Tool:** `GDD/tools/generate_levels.py`

```bash
# Sinh levels 4×4, rank 1 (dễ), 15 levels
python -B GDD/tools/generate_levels.py --size 4 --rank 1 --count 15 --output game/data/banks/bank_4x4_r1_raw.json

# Sinh levels 4×4, rank 2 (trung bình), 10 levels
python -B GDD/tools/generate_levels.py --size 4 --rank 2 --count 10 --output game/data/banks/bank_4x4_r2_raw.json

# Sinh levels 4×4, rank 3 (khó), 5 levels
python -B GDD/tools/generate_levels.py --size 4 --rank 3 --count 5 --output game/data/banks/bank_4x4_r3_raw.json
```

**Lưu ý:** Nếu generator hiện tại chưa output bank schema mới, cần adapter script chuyển đổi. Xem bước 3.

---

## Bước 2: Sinh levels cho bank 5×5 và 6×6 (nếu cần)

Playtest demo-30 có thể chỉ dùng 4×4. Nếu playlist cần 5×5/6×6:

```bash
python -B GDD/tools/generate_levels.py --size 5 --rank 1 --count 5 --output game/data/banks/bank_5x5_r1_raw.json
python -B GDD/tools/generate_levels.py --size 6 --rank 1 --count 5 --output game/data/banks/bank_6x6_r1_raw.json
```

---

## Bước 3: Chuyển đổi sang bank schema

Generator hiện tại output format cũ (campaign_m1.json style). Cần script chuyển sang bank schema:

### `GDD/tools/convert_to_bank.py`

```python
"""Convert raw generated levels to bank schema v1."""
import json
import sys
from pathlib import Path

def convert_level(raw: dict, rank: int) -> dict:
    """Convert single level from generator format to bank format."""
    return {
        "seed": raw.get("seed", 0),
        "regions": raw["regions"],          # already string format
        "solution": raw["solution"],
        "givens": raw.get("givens", []),
        "steps": raw.get("steps", len(raw["solution"])),
        "profile": raw.get("profile", [0, 0, 0]),  # [s2_count, s3_count, 0]
        "rating": raw.get("rating", rank * 100),
        "pidHash": raw.get("pidHash", ""),
        "logicTrace": raw.get("logicTrace", []),
    }

def convert_to_bank(raw_files: list[tuple[int, str]], size: int, output: str):
    """Merge raw files into single bank file."""
    bank = {
        "bankVersion": 1,
        "size": size,
        "ranks": {}
    }
    for rank, path in raw_files:
        with open(path) as f:
            raw_levels = json.load(f)
        bank["ranks"][str(rank)] = [convert_level(lv, rank) for lv in raw_levels]
    
    with open(output, "w") as f:
        json.dump(bank, f, indent=2)
    print(f"Bank written: {output} ({sum(len(v) for v in bank['ranks'].values())} levels)")

if __name__ == "__main__":
    # Usage: python convert_to_bank.py --size 4 --output game/data/banks/bank_4x4.json \
    #        --rank 1 bank_4x4_r1_raw.json --rank 2 bank_4x4_r2_raw.json ...
    pass  # argparse implementation
```

---

## Bước 4: Sinh pace sidecars

### `GDD/tools/generate_pace.py`

```python
"""Generate pace sidecar from bank file."""
import json

def generate_pace(bank_path: str, output_path: str):
    with open(bank_path) as f:
        bank = json.load(f)
    
    pace = {
        "bankVersion": 1,
        "size": bank["size"],
        "pacing": {}
    }
    
    for rank_key, levels in bank["ranks"].items():
        pace["pacing"][rank_key] = []
        for level in levels:
            steps = level.get("steps", len(level["solution"]))
            # rSeq: reasoning sequence (1 = single-step, 2 = two-step, etc.)
            r_seq = level.get("logicTrace", [1] * steps)
            if not r_seq:
                r_seq = [1] * steps
            # hintCosts: progressive hint clicks needed per step
            hint_costs = [max(1, r) for r in r_seq]
            pace["pacing"][rank_key].append({
                "rSeq": r_seq[:steps],
                "hintCosts": hint_costs[:steps],
            })
    
    with open(output_path, "w") as f:
        json.dump(pace, f, indent=2)
    print(f"Pace written: {output_path}")
```

---

## Bước 5: Tạo campaign playlist

### `game/data/campaigns/demo_30.json`

```json
{
    "campaignVersion": 1,
    "id": "demo-30",
    "playlist": [
        {"label": "L01", "size": 4, "rank": 1, "index": 0, "difficulty": "easy"},
        {"label": "L02", "size": 4, "rank": 1, "index": 1, "difficulty": "easy"},
        {"label": "L03", "size": 4, "rank": 1, "index": 2, "difficulty": "easy"},
        {"label": "L04", "size": 4, "rank": 1, "index": 3, "difficulty": "easy"},
        {"label": "L05", "size": 4, "rank": 1, "index": 4, "difficulty": "easy"},
        {"label": "L06", "size": 4, "rank": 1, "index": 5, "difficulty": "easy"},
        {"label": "L07", "size": 4, "rank": 1, "index": 6, "difficulty": "easy"},
        {"label": "L08", "size": 4, "rank": 1, "index": 7, "difficulty": "easy"},
        {"label": "L09", "size": 4, "rank": 1, "index": 8, "difficulty": "easy"},
        {"label": "L10", "size": 4, "rank": 1, "index": 9, "difficulty": "easy"},
        {"label": "L11", "size": 4, "rank": 1, "index": 10, "difficulty": "easy"},
        {"label": "L12", "size": 4, "rank": 1, "index": 11, "difficulty": "easy"},
        {"label": "L13", "size": 4, "rank": 2, "index": 0, "difficulty": "medium"},
        {"label": "L14", "size": 4, "rank": 2, "index": 1, "difficulty": "medium"},
        {"label": "L15", "size": 4, "rank": 2, "index": 2, "difficulty": "medium"},
        {"label": "L16", "size": 4, "rank": 2, "index": 3, "difficulty": "medium"},
        {"label": "L17", "size": 4, "rank": 2, "index": 4, "difficulty": "medium"},
        {"label": "L18", "size": 4, "rank": 2, "index": 5, "difficulty": "medium"},
        {"label": "L19", "size": 4, "rank": 2, "index": 6, "difficulty": "medium"},
        {"label": "L20", "size": 4, "rank": 2, "index": 7, "difficulty": "medium"},
        {"label": "L21", "size": 4, "rank": 2, "index": 8, "difficulty": "medium"},
        {"label": "L22", "size": 4, "rank": 2, "index": 9, "difficulty": "medium"},
        {"label": "L23", "size": 4, "rank": 3, "index": 0, "difficulty": "hard"},
        {"label": "L24", "size": 4, "rank": 3, "index": 1, "difficulty": "hard"},
        {"label": "L25", "size": 4, "rank": 3, "index": 2, "difficulty": "hard"},
        {"label": "L26", "size": 4, "rank": 3, "index": 3, "difficulty": "hard"},
        {"label": "L27", "size": 4, "rank": 3, "index": 4, "difficulty": "hard"},
        {"label": "L28", "size": 4, "rank": 3, "index": 5, "difficulty": "hard" },
        {"label": "L29", "size": 4, "rank": 3, "index": 6, "difficulty": "hard"},
        {"label": "L30", "size": 4, "rank": 3, "index": 7, "difficulty": "hard"}
    ]
}
```

**Phân bổ:** 12 easy (rank 1) → 10 medium (rank 2) → 8 hard (rank 3) = 30 levels.

---

## Bước 6: Validate toàn bộ

```bash
# Validate bank schema
python -B GDD/tools/validate_levels.py game/data/banks/bank_4x4.json

# Validate pace vs bank consistency
python -B GDD/tools/validate_levels.py game/data/banks/bank_4x4.json --pace game/data/banks/bank_4x4.pace.json

# Validate playlist references exist in bank
python -B GDD/tools/validate_levels.py game/data/campaigns/demo_30.json --bank game/data/banks/bank_4x4.json
```

---

## Bước 7: Placeholder audio (optional)

Nếu chưa có audio assets, tạo silent .ogg placeholders để game không crash:

```bash
# Tạo silent 0.1s OGG files cho mỗi SFX
# Dùng ffmpeg hoặc tool tương tự
for f in mark undo candy_found candy_wrong lock_tick hint win fail tap restart enter; do
    ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 0.1 -c:a libvorbis game/audio/sfx/$f.ogg
done
```

---

## Checklist thực hiện

- [ ] Kiểm tra generator hiện tại output format
- [ ] Viết `convert_to_bank.py` nếu cần adapter
- [ ] Viết `generate_pace.py`
- [ ] Sinh 30 levels (12 rank1 + 10 rank2 + 8 rank3)
- [ ] Convert sang `bank_4x4.json`
- [ ] Sinh `bank_4x4.pace.json`
- [ ] Tạo `demo_30.json` playlist
- [ ] Validate tất cả data files
- [ ] Tạo placeholder audio (nếu thiếu)
- [ ] Commit: `feat(content): generate 30-level playtest bank and campaign`

---

## Sau module này

Game có đủ code + data để:
1. Boot → Title screen → chọn Play
2. Chơi 30 levels tuần tự L01-L30
3. Auto-mark, undo, progressive hints hoạt động
4. Save/load session, progress persist
5. Thắng L30 → replay campaign

**Thiếu cho production (ngoài scope playtest):**
- Audio assets thật (cần sound designer)
- 5×5 và 6×6 bank data
- Endless mode UI
- Visual polish, animations nâng cao
- IAP, ads, analytics
