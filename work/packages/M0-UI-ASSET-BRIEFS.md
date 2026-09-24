+++
id = "M0-UI-ASSET-BRIEFS"
title = "MVP UI and asset creation briefs"
kind = "content"
phase = "M0"
status = "ready"
depends_on = ["M0-PREFLIGHT"]
requirements = []
qa = []
read_first = [
  "GDD/README.md",
  "GDD/01-tam-nhin-va-pham-vi.md",
  "GDD/03-luong-man-hinh-va-ux.md",
  "GDD/06-my-thuat-va-am-thanh.md",
  "GDD/08-ke-hoach-trien-khai-cho-agent.md",
  "docs/governance/00-design-status.md"
]
allowed_paths = [
  "work/packages/M0-UI-ASSET-BRIEFS.md",
  "work/asset-briefs/M0-UI-ASSET-BRIEFS.md",
  "work/evidence/M0-UI-ASSET-BRIEFS/**",
  "work/handoffs/M0-UI-ASSET-BRIEFS.md"
]
deliverables = ["work/asset-briefs/M0-UI-ASSET-BRIEFS.md"]
out_of_scope = [
  "production asset creation or approval",
  "Godot UI or gameplay implementation",
  "changes to canonical GDD, gameplay rules, or level schema",
  "M0 device and performance acceptance",
  "final product name, logo, or brand identity before O-01"
]
[[checks]]
id = "pipeline_validate"
command = ["python", "tools/agent_pipeline.py", "validate"]
[[checks]]
id = "pipeline_tests"
command = ["python", "-B", "-m", "unittest", "discover", "tools/tests", "-p", "test_*.py"]
[[checks]]
id = "gdd_tests"
command = ["python", "-B", "-m", "unittest", "discover", "GDD/tools", "-p", "test_*.py"]
[[checks]]
id = "level_validator"
command = ["python", "-B", "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"]
+++

# M0-UI-ASSET-BRIEFS: MVP UI and asset creation briefs

## Mục tiêu

Lập danh mục màn hình, thành phần UI và asset cần tạo cho MVP theo GDD hiện hành. Với từng đối tượng cần người làm asset, bàn giao cấu tạo, quy cách xuất, prompt gốc và tiêu chí tiếp nhận để chủ dự án có thể tạo bằng công cụ riêng. Công việc diễn ra song song với M0-A02/M0-A03 và không chặn các prototype dùng hình tạm.

## Tiêu chí nghiệm thu

- [ ] Bao phủ Home, Puzzle, Tutorial, Result thắng, Result thua, Trợ giúp/Luật và Settings; chỉ rõ thành phần dùng chung và nội dung động do Godot hiển thị.
- [ ] Phân biệt asset cần tạo với UI có thể dựng bằng Godot; ưu tiên những đối tượng giúp thay hình tạm theo từng đợt.
- [ ] Mỗi asset cần tạo có ID ổn định, cấu tạo/lớp, trạng thái, quy cách nguồn và bản xuất, prompt tạo hình, tiêu chí tiếp nhận và vị trí sử dụng.
- [ ] Gói mèo mặc định nêu rõ model/rig/clip 3D gốc rồi xuất một bộ sprite 2D dùng chung cho mọi vùng; không sinh biến thể mèo theo màu vùng.
- [ ] Vùng A–F có màu, nhãn và họa tiết; X đỏ có dấu cảnh báo ngoài màu; brief giữ vùng chạm, khả năng đọc chữ lớn, safe area và giảm chuyển động theo GDD.
- [ ] Danh mục có trạng thái nhận từng phần để asset đến trước được tích hợp trước; nêu quy trình bàn giao và package tích hợp sau này mà không sửa phạm vi M0-A02/M0-A03.
- [ ] Không chốt tên/logo cuối, không thêm meta hoặc generator hậu MVP vào UI bản đầu.
- [ ] Toàn bộ unit test hiện có, level validator và pipeline validate qua; báo cáo handoff đầy đủ.

## Trọng tâm review

Brief là hợp đồng tạo asset cho người dùng và chuẩn đầu vào cho package tích hợp sau này, chưa phải bằng chứng asset hoặc UI đã được tạo. Prompt cần đủ cụ thể để tạo tác phẩm gốc, nhưng mọi thông số atlas/nén cuối phải được điều chỉnh theo kết quả đo M0-A03 trên thiết bị.
