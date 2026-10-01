# Công cụ sinh level offline

Bộ công cụ trong `GDD/tools/` chỉ tạo và đánh giá **ứng viên pilot offline** cho CanDoKu. Kết quả không tự thay campaign, không chạy trong game và không được coi là nội dung phát hành trước khi qua duyệt người, UI và playtest.

## Chạy kiểm thử

```powershell
python -B GDD/tools/test_generate_levels.py
```

Test bao phủ tính tất định, budget không đủ, lọc trùng, uniqueness, logic band S2/S3, rating và phiếu playtest không lộ đáp án.

## Sinh một batch pilot

Chọn thư mục đầu ra mới; công cụ không ghi đè thư mục đã tồn tại:

```powershell
python -B GDD/tools/generate_levels.py `
  --out scratch/level-pilot `
  --exclude GDD/data/levels.sample.json `
  --exclude game/data/campaign_m1.json
```

Có thể truyền `--profile <file.json>`; nếu bỏ qua, công cụ dùng profile pilot tám slot ở order 2, 4, 7, 10, 14, 18, 19 và 22. Exit code `0` nghĩa là đủ slot đã yêu cầu; exit code `2` nghĩa là hết budget hoặc còn slot chưa đạt. Cả hai trường hợp đều phải đọc `report.json`, không suy luận từ việc thư mục đầu ra tồn tại.

Mỗi batch gồm:

- `levels.json`: ứng viên level schema v4;
- `report.json`: provenance, hash, uniqueness, trace, vector/rating và lý do loại;
- `profile.json`: profile thực tế đã chạy;
- `report.md`: báo cáo biên tập có lời giải, chỉ dành cho người điều phối;
- `blind-playtest.md`: phiếu giải không chứa đáp án;
- `playtests.csv`: mẫu dữ liệu người–màn–lượt, ban đầu chỉ có header.

## Thí nghiệm nhiều seed

```powershell
python -B GDD/tools/run_generation_experiment.py `
  --seeds 20 `
  --out scratch/level-generation-experiment.json `
  --exclude game/data/campaign_m1.json
```

Thí nghiệm dùng để đo tỷ lệ hoàn thành profile, số lần thử, lý do loại và độ phân tán policy. Không dùng kết quả nhiều seed để chọn riêng batch đẹp nhất rồi gọi đó là bằng chứng độ khó.

## Cổng biên tập

`MACHINE_VALIDATED` chỉ xác nhận các cổng máy đã chạy: schema, nghiệm duy nhất, logic band, trace và chống trùng theo cấu hình. Trước khi đưa vào campaign, ứng viên vẫn cần:

1. duyệt hình vùng và khả năng đọc trên UI thật;
2. playtest mù, ghi cả bỏ cuộc/trợ giúp/lỗi;
3. hiệu chỉnh difficulty bằng người chơi mục tiêu;
4. kiểm campaign, thiết bị và toàn bộ cổng R3/R4 đang áp dụng.

Batch tham chiếu hiện tại nằm tại `GDD/data/pilot-20260929/`: máy đạt 8/8, nhưng player evidence và UI review vẫn là `NOT_RUN`.
