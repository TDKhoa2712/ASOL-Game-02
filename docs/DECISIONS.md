# Quyết định điều hành hiện hành

## RST-010 — Cho phép pilot generator offline

Ngày 2026-09-29. Cho phép triển khai bộ generator/rating offline giới hạn N=4–6 để tạo ứng viên pilot và kiểm chứng thiết kế GDD 10/11.

- Công cụ chỉ ghi thư mục đầu ra mới, không sửa campaign hoặc chạy trong client; không mở Endless, runtime generation hay R2–R4.
- `MACHINE_VALIDATED` không đồng nghĩa production-ready. Difficulty chỉ là nhãn tạm đến khi có playtest mù, duyệt UI và hiệu chỉnh bằng người chơi mục tiêu.
- Profile đầu tạo tám ứng viên trải order 2–22, gồm tier B và I; dữ liệu pilot được giữ để tái lập và phục vụ vòng duyệt người, không tự nhập vào 24 level phát hành.

## RST-009 — Dọn tài nguyên thừa và tích hợp CanDoKu

Ngày 2026-09-29. Chủ dự án yêu cầu xóa phần không còn sử dụng và merge về `dev`.

- Bỏ ảnh mèo/cá, logo/avatar cũ, atlas bitmap và ảnh tiền/daily/leaderboard đã không còn tham chiếu; bỏ cặp import tương ứng. Bản nguồn tracked khôi phục được từ Git.
- Gỡ các khối Home tiền/daily/leaderboard đang tắt, nút avatar không có hành động và cấu hình đi kèm. Hai spec UI cũ đã được xóa; GDD 02/03/06 là chỉ dẫn hiện hành.
- Commit chọn file CanDoKu và phần dọn; giữ bảy sửa import icon nút đang dùng ngoài commit. Tích hợp local về `dev` sau kiểm chứng. R1/thiết bị chưa được coi hoàn tất.

## RST-008 — Chuyển đồng bộ CanDoKu trong GDD và mã nguồn

Ngày 2026-09-29. Chủ dự án xác nhận phạm vi **cả GDD và mã nguồn game**; thay phần giữ token cũ của RST-006.

- Hợp đồng hiện hành dùng `candy`, `TryCandy`, `try_candy`, `CandyFound`, `sourceCandy` và `tutorialCandyCell`; đồng bộ solver, Hint, tutorial, vector, validator và test.
- Session v3; hỗ trợ đọc v2 bằng converter cô lập, giữ nguyên dữ liệu lượt và ghi v3 ở lần lưu tiếp theo. Progress v2, level v4, ID, hash và app identifier không đổi. Tên hiển thị CanDoKu nhưng đường dẫn profile cũ được giữ.
- Dùng hình kẹo/tim gốc thay hình chủ đề cũ đang được tham chiếu. Asset cũ có sửa sẵn được bảo toàn, không còn dùng trong client. Không bật daily/tiền/leaderboard ngoài phạm vi.
- Hai spec UI và công cụ xuất báo cáo phải theo GDD hiện hành; lịch sử/evidence không được sửa thành kết quả mới. Đây không phải nghiệm thu R1, mobile hoặc phát hành.


## RST-007 — Tài liệu nền suy luận và sinh level

Ngày 2026-09-28. Chủ dự án yêu cầu một file đầy đủ về nguyên tắc suy luận và một file về sinh level/đánh giá độ khó để làm nền tạo nội dung về sau.

- Mở rộng GDD 10 và tạo GDD 11 mới chuyên về sinh level/độ khó. File 11 mới không khôi phục đề án meta/vàng/bộ sưu tập đã bỏ ở RST-006.
- Bao gồm kỹ thuật nâng cao, hợp đồng generator offline và phương pháp chấm khó để nghiên cứu; giữ riêng trạng thái đã hỗ trợ so với cần phát triển.
- Công thức rating-0/ngưỡng phân loại là đề xuất chưa hiệu chỉnh; không thay công thức điểm gameplay hoặc tự gắn nhãn độ khó là đã đo.
- Không đổi schema v4, luật, campaign 24 màn, quyền mở R2–R4 hoặc triển khai generator/Endless trong đợt tài liệu.

## RST-006 — CanDoKu và tinh gọn GDD

Ngày 2026-09-28. Chủ dự án yêu cầu làm lại GDD, đổi tên thành **CanDoKu**, chủ đề tìm kẹo bị đánh rơi trong vườn, tham khảo Meowdoku; đồng thời cho phép xóa/tinh gọn tài liệu trong GDD không còn nhiệm vụ.

- GDD 0.6.0 dùng sơ đồ luống vườn và kẹo cố định để trình bày nền suy luận hàng/cột/vùng/không chạm. Level, asset, logo, câu chữ và layout phải là tác phẩm gốc.
- Giữ 24 level, phạm vi R1, ba tim, điểm, Hint, cử chỉ và schema hiện hành. Không tự mở R2–R4 hoặc Endless/meta.
- Thiết kế hình ảnh chuyển sang kẹo/giỏ/vườn 2D với hiệu ứng nhỏ; bỏ yêu cầu bắt buộc model/rig/clip nhân vật cũ và bộ sưu tập cũ. GDD 06 là hướng sản xuất mới; chưa phải asset hoặc client đã triển khai.
- **Đã được RST-008 thay thế:** giữ token kỹ thuật cũ, level/schema/save/hash; lớp UI dùng kẹo/tìm kẹo. Không đổi app identifier hoặc đường dẫn save trong đợt này.
- Bỏ GDD 08/11/12 cũ; bản gốc khôi phục được từ `b335b1891d1b9927e3b55f2ec8945dda252c779f`. Giữ fixture, validator và test vì vẫn phục vụ hợp đồng đang dùng. GDD 09 thay review lỗi thời bằng rà soát CanDoKu; ROADMAP giữ kế hoạch, STATUS giữ tiến độ.
- Đây là đợt tài liệu; chưa đổi code/game assets, chưa chứng nhận QA hoặc phát hành. Ngoại lệ replay kiểm thử RST-003 và tutorial RST-004 vẫn áp dụng.

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

- T1/T2 gọi rõ ô `(2,2)` bằng tọa độ hiển thị cho người chơi; T4 gọi rõ tọa độ kẹo suy ra từ level.
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
