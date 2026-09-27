# Cải tổ pipeline agent — kế hoạch thực hiện
Cập nhật 2026-09-27 theo yêu cầu rà soát, chỉnh sửa rồi triển khai của chủ dự án.

## Thiết kế và phạm vi
Một agent, một mục tiêu, một checkout; bỏ quản trị cũ, thêm runner nhỏ. Chỉ sửa tài liệu không giải quyết chi phí soạn lệnh/log; hệ thống nhiều agent lại thêm điều phối chưa cần thiết. AGENTS giữ cách làm, ROADMAP giữ thứ tự, STATUS giữ hiện trạng, DECISIONS giữ quyết định, GDD giữ thiết kế. Một plan cho việc nhiều bước, không thêm spec/brief/handoff hoặc vòng duyệt lại công việc đã giao.
Không đổi gameplay, schema, phạm vi 24 level hay tự khởi động R2–R4. Đợt này kết thúc ở pipeline, không tự tiếp tục sửa game.

## Những điểm sửa trong đề xuất
- Tag chỉ bảo toàn file đã commit. Baseline thực tế là dev tại 8f2876d, có sửa sẵn board_view.gd và các file untracked. Không add -A, reset hay dọn untracked.
- STATUS lỗi thời: dev đã chứa R1. Review 05 là khảo sát tại 1600898, nhiều vấn đề đã có bản sửa; không chép thành bug hiện hành.
- Runner thuộc phạm vi lần này, log ở scratch/verification, không tái tạo work/. Giữ log mỗi lần chạy và latest; lưu evidence nghiệm thu có chọn lọc.
- Không chạy cleanup-pipeline.sh vì không có file đó. Chỉ bỏ tracked file đã sạch và bảo toàn trong tag.
- Hai config lạc tên đang untracked: giữ nguyên, không công bố nội dung hoặc giả định tag đã bảo toàn. refactor/AGENTS.md là bản nháp người dùng gửi, giữ nguyên; AGENTS gốc là quy trình vận hành.
- Không thay cấu hình Codex/plugin toàn máy; cải tổ repo không sửa được lỗi khởi tạo sandbox của ứng dụng.

## Các bước
- [x] Khảo sát Git, nguồn hướng dẫn, tham chiếu và suite; tạo codex/pipeline-cleanup từ dev và tag pre-reset-pipeline-2026-09-27 tại 8f2876d.
- [x] Rút gọn AGENTS/README/CONTRIBUTING, cập nhật STATUS/ROADMAP/DECISIONS và đường tra lịch sử.
- [x] Viết tools/verify.py và tools/tests/test_verify.py. Chạy Python game/GDD/tools, hai validator, toàn bộ game/tests/run_*.gd; không chạy capture/export/probe độc lập. Thiếu tool, timeout, exit lỗi, SCRIPT ERROR hoặc không có suite phải FAIL.
- [x] Sau xác nhận tag và diff sạch, bỏ tracked work/, docs/governance/, docs/archive/, bốn review cũ, BRANCH-CONSOLIDATION và pipeline/test cũ. Giữ nội dung luật GDD, sửa link lịch sử còn lại.
- [x] Kiểm runner, full suite, link/diff và bảo toàn file người dùng; lưu bằng chứng mới và commit riêng cải tổ. Không tự merge/push/phát hành.

Runner ghi UTC, revision, dirty state, fingerprint nguồn thực tế, version, command, duration, exit và output. Một suite lỗi vẫn chạy các suite còn lại và tổng kết FAIL. Headless PASS không chứng nhận GUI/thiết bị.

## Agent và chủ dự án phối hợp
| Việc | Agent | Chủ dự án | Điểm hoàn tất |
| --- | --- | --- | --- |
| Nhận mục tiêu | Tóm tắt đầu ra, giới hạn, tiêu chí xong; chia bước khi cần | Nêu kết quả muốn thấy và ưu tiên | Mục tiêu kiểm chứng được |
| Triển khai | Khảo sát có mục tiêu, sửa xuyên module liên quan, test theo thay đổi | Chốt quyết định ảnh hưởng sản phẩm/quyền truy cập còn thiếu | Đạt hành vi đã giao |
| Cuối chặng | Full runner sau sửa cuối; GUI nếu đổi UI/input; báo lỗi | Kiểm trải nghiệm khi cần | Evidence cùng revision/diff |
| R1 Android | Chuẩn bị build và kịch bản fresh/resume/Win/Fail/retry/cuối campaign | Kết nối thiết bị/USB debugging hoặc chạy build, gửi model/OS và kết quả | Đủ hành trình bắt buộc |
| R2/R4 | Chuẩn bị kịch bản thử và danh sách nguồn lực | Tuyển người thử; xác nhận iPhone/Mac/signing | Đủ nguồn lực đúng chặng |
| Bàn giao | STATUS: revision, kết quả, bằng chứng, blocker, bước tiếp | Quyết định tích hợp/phát hành khi cần | Không thay kiểm chứng bằng tuyên bố |

## Nhịp tối ưu
Tài liệu chỉ kiểm diff/link/nhất quán. Code chạy test liên quan trong vòng sửa, full suite trước bàn giao/tích hợp; chỉ chạy lại full khi có sửa mới hoặc thiếu bằng chứng. UI/input quan sát từ entry scene sau cụm thay đổi và ở nghiệm thu. Không bắt người dùng duyệt lại bước kỹ thuật đã giao.
Blocker ghi một hàng: lỗi, tác động, người xử lý, hành động tiếp, điều kiện thử lại. Sau một chẩn đoán có mục tiêu, không retry vô hạn cùng lỗi môi trường; tiếp tục việc độc lập.
Trong ba mục tiêu tiếp theo ghi một dòng ở STATUS: thời gian làm, thời gian chờ, số full run, regression mở lại, hành trình nghiệm thu. Runner đo thời gian thực. Chưa có baseline pipeline cũ nên không tuyên bố tiết kiệm phần trăm. Sau ba mục tiêu, loại bước không hỗ trợ kiểm chứng/quyết định; không giảm QA.

## Khôi phục
Tra lịch sử bằng `rtk git show pre-reset-pipeline-2026-09-27:work/README.md`, thay đường dẫn tương ứng. Tag local chưa phải backup ngoài máy. Kết quả runner không đồng nghĩa R1 đạt hoặc đủ điều kiện phát hành.

## Kết quả thực hiện

Đã triển khai và kiểm chứng trên nhánh `codex/pipeline-cleanup`; xem [STATUS](../docs/STATUS.md) và [evidence](../docs/evidence/pipeline/README.md). Hai config untracked giữ nguyên như điều chỉnh ở trên. R1 chưa nghiệm thu; đợt này không tự tích hợp hoặc tiếp tục gameplay.
