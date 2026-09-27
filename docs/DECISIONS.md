# Quyết định điều hành hiện hành

## RST-005 — Pipeline gọn theo mục tiêu

Ngày 2026-09-27, chủ dự án yêu cầu rà soát/chỉnh kế hoạch rồi triển khai cải tổ pipeline. Chọn một agent chính, một plan khi cần, một STATUS hiện hành; tự thực hiện bước kỹ thuật đã giao, không thêm vòng duyệt/hồ sơ lặp từ workflow. Thay pipeline quản trị bằng `tools/verify.py`; kiểm tra liên quan trong vòng sửa và đầy đủ cuối chặng, giữ nguyên yêu cầu GUI/thiết bị.

Hồ sơ tracked cũ bảo toàn tại `pre-reset-pipeline-2026-09-27` (`8f2876d`) trước khi bỏ khỏi checkout; cách tra ở [HISTORY](HISTORY.md). Giữ nguyên file untracked và sửa sẵn của người dùng. Không thay luật/schema/phạm vi phát hành; không tự sửa cấu hình agent toàn máy. Quyết định này thay yêu cầu giữ hồ sơ cũ trong working tree của RST-001; không sửa trạng thái lịch sử.


## RST-003 — Cho phép replay campaign trong MVP

Ngày 2026-09-25. Chủ dự án xác nhận: sau khi hoàn thành level hiện có, bản MVP phải cho quay về Home và chơi lại từ L01 để kiểm chứng; bản chính thức sau này không cho replay từ L01.

- Home giữ nút chính hoạt động sau khi campaign hoàn tất và đổi nhãn thành `Chơi lại từ L01`.
- Kết quả L01–L03 giữ nút chính `Tiếp tục` để sang level kế tiếp. Chỉ sau khi thắng L04, nút chính trên Result đổi thành `Chơi lại từ L01` và mở lượt L01 mới trực tiếp; nút Home vẫn còn.
- Replay tạo session mới từ L01 nhưng không ghi đè `currentLevelId` hoàn thành hoặc danh sách level đã hoàn thành. Trong vòng replay, thắng L01–L03 vẫn tiếp tục tuần tự; chỉ kết quả L04 mới quay lại L01.
- Cờ `MVP_ALLOW_CAMPAIGN_REPLAY` trong bootstrap hiện bật để kiểm thử; trước bản chính thức phải tắt cờ và kiểm lại màn hoàn tất.
- Quyết định này chỉ mở đường kiểm chứng MVP, không thay đổi luật, save schema, phạm vi 24 level hoặc Endless.

## RST-004 — Bỏ ô sáng trong tutorial MVP

Ngày 2026-09-25. Chủ dự án chốt bỏ hoàn toàn viền sáng chỉ ô trên bàn tutorial.

- T1/T2 gọi rõ ô `(2,2)` bằng tọa độ hiển thị cho người chơi; T4 gọi rõ tọa độ mèo suy ra từ level.
- Ô tutorial được chỉ định vẫn giữ cơ chế miễn phạt ở các bước áp dụng, nhưng không còn hiệu ứng sáng.
- Quyết định không đổi luật, save schema hoặc dữ liệu level.

## RST-002 — Duyệt cải tổ và mở R1

Ngày 2026-09-25. Chủ dự án xác nhận: giữ 24 level cho bản đầu, Endless để sau; tích hợp cải tổ về dev và kết thúc tạm ngưng để bắt đầu R1.

- Tích hợp nhánh refactor/project-reset vào dev bằng fast-forward sau kiểm chứng tài liệu.
- Triển khai R1 trên nhánh ngắn từ dev theo kế hoạch đã duyệt; một agent chính, không khởi động lại package cũ.
- Không thay luật, schema, tiêu chí QA hoặc loại iOS. Endless/meta/generator không thuộc bản đầu.
- RST-002 thay hiệu lực tạm ngưng của RST-001; nhận định lịch sử trong review vẫn giữ thời điểm khảo sát.

## RST-001 — Tạm ngưng, hợp nhất dev và cải tổ trên nhánh riêng

Ngày: 2026-09-24. Căn cứ: chủ dự án yêu cầu tạm ngưng công việc, gom code/nhánh về dev, cải tổ trên nhánh từ dev và xóa nhánh không cần thiết.

- Bảo toàn công việc tại dev `008f0d962d291ca6d5614f6613e8129b64673f41`. Nhánh `refactor/project-reset` dành cho cấu trúc, tổ chức, quy trình, rà thiết kế và kế hoạch.
- Tạm ngưng triển khai game/content/asset; không tự tiếp tục package cũ. Các state cũ giữ nguyên để bảo toàn lịch sử, không phải trạng thái điều hành hiện tại.
- Giao việc mới theo kết quả và phạm vi đã được giao, không bắt buộc ID package hay vòng start/verify/handoff/accept. Quy tắc hiện hành ở [AGENTS](../AGENTS.md).
- Kế hoạch cũ GDD 08 và quy định quy trình trong governance/work được thay thế bởi [ROADMAP](ROADMAP.md). Quyết định này chỉ có trên nhánh cải tổ cho đến khi tích hợp về dev.
- Các yêu cầu sản phẩm/QA của GDD vẫn giữ. Việc bỏ gate M0/M1 không tuyên bố QA thiết bị đã đạt và không giảm tiêu chí phát hành.
- Giữ main, dev và nhánh cải tổ; xóa tên các nhánh work đã được bảo toàn. Giữ stash và hồ sơ lịch sử; chưa cần xóa hoặc di chuyển hàng loạt tài liệu.

Những thay đổi luật, UX contract, schema và phạm vi sản phẩm sẽ được rà riêng trong R0. Chưa có quyết định thay đổi nào thuộc các phần này trong đợt hợp nhất nhánh.
