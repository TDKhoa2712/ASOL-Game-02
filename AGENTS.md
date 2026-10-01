# Hướng dẫn làm việc cho agent

## 1. Nguồn hướng dẫn và phạm vi

Đọc [STATUS](docs/STATUS.md) và phần mục tiêu đang giao trong [ROADMAP](docs/ROADMAP.md). Chỉ đọc thêm GDD/code liên quan; không đọc lại toàn bộ hồ sơ mỗi lượt. GDD 02 giữ luật chuẩn; [DECISIONS](docs/DECISIONS.md) ghi quyết định mới có hiệu lực. R1 đã được mở; client hiện có campaign bốn level. Mốc nội dung tiếp theo là bản playtest trước phát hành gồm 30 level theo RST-011; phạm vi phát hành chính thức chỉ chốt sau playtest, Endless để sau. Không tự mở R2–R4.

## 2. Nhận và thực hiện mục tiêu

- Một agent chính, một mục tiêu, một checkout. Không tự thêm agent/worktree trừ khi người dùng yêu cầu rõ.
- Tóm tắt đầu ra, phạm vi và tiêu chí xong. Việc nhiều bước dùng một plan ngắn; việc nhỏ làm trực tiếp. Khi người dùng đã giao thực hiện, tự xử lý bước kỹ thuật và sửa mọi file liên quan trực tiếp, không yêu cầu duyệt lại cùng phạm vi.
- Không bắt buộc tạo thêm spec, brief, bảng giao nhận hoặc vòng phê duyệt từ workflow/skill. Dùng skill đúng nhu cầu; không để nghi thức thay việc triển khai. Hướng dẫn dự án này ưu tiên khi skill đề xuất thêm thủ tục.
- Hỏi khi thiếu quyết định ảnh hưởng luật, schema, tính năng, phạm vi phát hành hoặc quyền hành động; ghi quyết định sản phẩm vào DECISIONS. Trong khi chờ, tiếp tục phần độc lập đã được giao.
- Giữ nguyên thay đổi sẵn có, không add/reset/dọn toàn repo. Không xóa tài sản hoặc phát hành ngoài phạm vi được giao.

## 3. Kiểm chứng theo thay đổi

- Tài liệu: kiểm diff, link, nhất quán và phạm vi; không chạy game để chứng minh sửa văn bản.
- Code: tái hiện bug, thêm regression có giá trị, chạy test liên quan sau cụm sửa. Trước bàn giao/tích hợp chạy `rtk python -B tools/verify.py --godot <executable>` (hoặc đặt GODOT_BIN). Runner chạy Python, hai validator và tất cả `game/tests/run_*.gd`; thiếu tool/test, lỗi hoặc timeout không được coi PASS.
- Chỉ lặp full suite khi có sửa mới, test fail hoặc bằng chứng chưa đủ. Không thêm test chỉ kiểm lại nội dung tĩnh của thay đổi nhỏ.
- UI/input/điều hướng: quan sát từ entry scene thật sau cụm thay đổi và tại nghiệm thu. Headless không thay GUI/thiết bị. Thiếu thiết bị ghi chưa kiểm chứng, không báo đạt R1.
- Evidence phải ghi revision và diff/fingerprint thực tế, lệnh, kết quả, giới hạn. Log tự động ở `scratch/verification/`; chỉ lưu bản cần nghiệm thu vào `docs/evidence/`. Không dùng log cũ cho build mới.

## 4. Blocker và bàn giao

STATUS là nguồn tiến độ duy nhất: mục tiêu, revision, kết quả, bằng chứng, lỗi chặn, bước kế tiếp. Plan giữ checklist thực hiện; nhật ký/evidence giữ dữ kiện lịch sử, không phải bảng trạng thái song song.

Mỗi blocker ghi tác động, người xử lý, hành động tiếp và điều kiện thử lại. Cùng lỗi môi trường: chẩn đoán có mục tiêu một lần, không retry vô hạn khi chưa có điều kiện mới. Regression tái diễn ghi tên/hành trình cụ thể, không bỏ test fail. Báo cáo khi có kết quả hoặc thay đổi đáng kể; không lặp thông báo blocker không đổi. Không báo hoàn tất mục tiêu còn bị chặn.

Trong ba mục tiêu đầu sau cải tổ, ghi ngắn thời gian thực hiện/chờ, số full run, regression mở lại và hành trình đã kiểm; dùng số liệu để điều chỉnh nhịp, không giảm QA.

## 5. Nhánh và tích hợp

`dev` là nền tích hợp, không tự coi đã nghiệm thu. Bắt đầu từ dev bằng nhánh ngắn `codex/<muc-tieu>` trừ khi người dùng chỉ định khác. `main` giữ mốc hiện có, không mặc định là bản phát hành đạt QA. Commit chọn đúng file thuộc mục tiêu; chỉ merge/push/phát hành trong quyền được giao. Chỉ dọn nhánh khi công việc đã bảo toàn và checkout đã kiểm tra.

## 6. Nội dung gốc và lịch sử

Asset, level, câu chữ, mã nguồn phải là tác phẩm gốc; không sao chép tên thương mại, giao diện, âm thanh, nhân vật hoặc cấu trúc level của game thương mại khác.

Hồ sơ vận hành cũ được bảo toàn tại tag `pre-reset-pipeline-2026-09-27`. Cách tra: [lịch sử](docs/HISTORY.md).
