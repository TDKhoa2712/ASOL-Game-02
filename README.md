# ASOL-Game-02 — CanDoKu

Game suy luận tìm kẹo bị đánh rơi trong vườn, Godot. GDD CanDoKu 0.6.0 là thiết kế đích; client R1 bốn level đã chuyển thuật ngữ sang CanDoKu; vẫn cần nghiệm thu đầy đủ GUI/thiết bị. Bản đầu 24 level, Endless để sau. Xem [STATUS](docs/STATUS.md).

## Nguồn chính

- [GDD](GDD/README.md): thiết kế, luật, dữ liệu và tiêu chí QA.
- [game](game/project.godot): client, scene, script và test.
- [AGENTS](AGENTS.md): cách làm; [CONTRIBUTING](CONTRIBUTING.md): đóng góp.
- [ROADMAP](docs/ROADMAP.md): thứ tự; [STATUS](docs/STATUS.md): hiện trạng; [DECISIONS](docs/DECISIONS.md): quyết định.
- [Tra lịch sử pipeline cũ](docs/HISTORY.md).

## Chạy và kiểm chứng

Godot 4.7.2 là phiên bản đã dùng kiểm dự án. Thay `godot` bằng executable trên máy nếu không có trong PATH.

```text
rtk godot --editor --path game
rtk godot --path game
rtk godot --headless --path game --script res://tests/run_mvp_runtime_tests.gd
```

Kiểm đầy đủ cuối chặng (Python 3.11+, Godot):

```text
rtk python -B tools/verify.py --godot <duong-dan-Godot>
```

Cũng có thể đặt `GODOT_BIN` rồi chạy `rtk python -B tools/verify.py`. Runner tự truyền biến đó cho Python smoke. Log từng lần chạy và `latest.txt` nằm ở `scratch/verification/` (Git ignore), ghi command, version, revision, trạng thái dirty, fingerprint, exit code và thời gian. Exit 0 là tất cả kiểm tra headless đạt; exit 1 là lỗi/thiếu công cụ/timeout. Có thể đặt `--timeout 180` (giây mỗi bước). GUI/thiết bị luôn được ghi NOT RUN.

Trong vòng sửa, chỉ chạy suite liên quan; ví dụ:

```text
rtk python -B -m unittest discover tools/tests -p test_verify.py
rtk python -B -m unittest discover GDD/tools -p test_*.py
rtk python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json
rtk python -B GDD/tools/validate_levels.py game/data/campaign_m1.json
```

Không lấy kết quả headless thay QA từ entry scene/thiết bị trong [kế hoạch R1](docs/plans/R1-playable-loop.md). Toàn bộ nội dung và tài sản phải là tác phẩm gốc.
