# Đề xuất thay quy trình và lập lại kế hoạch dự án

Ngày: 2026-09-24. Trạng thái: PROPOSED — chưa thay thế quy định đang có hiệu lực.

## 1. Mục tiêu và điểm xuất phát

Theo xác nhận của chủ dự án, bản hiện tại chưa ổn định và mới chơi riêng lẻ, chưa liền mạch. Kết quả package cũ không được dùng để suy ra bản tích hợp đã hoàn thành. Các module, level, test và bằng chứng hiện có là tài sản để tái sử dụng sau khi kiểm tra.

Mục tiêu cải tổ: chủ dự án giao một kết quả sản phẩm, agent chịu trách nhiệm triển khai và tích hợp đến khi chứng minh được kết quả đó. Giảm việc chủ dự án phải tạo gói, chuyển trạng thái hoặc cho phép sửa từng file. Tiến độ đo bằng các hành trình người chơi đã hoạt động trên một bản build xác định.

Đây là thiết kế quy trình và lộ trình sản phẩm, không phải kế hoạch sửa mã chi tiết. Các bước sửa mã của chặng gần nhất được xác định sau khi tái hiện hiện trạng; không đoán trước nguyên nhân kỹ thuật hoặc viết kế hoạch chi tiết cho những chặng còn xa.

## 2. Phương án được đề xuất

| Phương án | Đánh đổi | Kết luận |
| --- | --- | --- |
| Thay cơ chế điều hành, bảo tồn tài sản và lịch sử | Cần một lần chuyển đổi tài liệu thống nhất | Chọn |
| Chỉnh nhẹ pipeline package hiện tại | Ít thay đổi ban đầu nhưng vẫn giữ nút thắt giao từng gói | Không chọn |
| Xóa cả hồ sơ và viết lại game | Mất bằng chứng, lặp lại công việc; chưa có căn cứ kỹ thuật | Không chọn |

Ngừng áp dụng kế hoạch M0/M1/M2/M3 và chuỗi package cũ khi hoàn tất chuyển đổi. Lưu chúng dưới trạng thái lịch sử; các package chưa đóng được ghi là đã chuyển sang kế hoạch mới, không tự đổi thành done. Không xóa code, test, level, asset, quyết định thiết kế hoặc evidence để làm sạch tiến độ.

Phạm vi sản phẩm tiếp tục là GDD hiện hành: game offline, tiếng Việt, Android/iOS, 24 level gốc N=4–6, quy tắc và điểm hiện tại; không thêm meta, quảng cáo, tài khoản hoặc generator vào bản đầu. Thay quy trình không mặc nhiên thay gameplay, schema hoặc tiêu chí chất lượng phát hành.

## 3. Cơ chế làm việc mới

### Vai trò và quyền quyết định

- Chủ dự án quyết định mục tiêu sản phẩm, ưu tiên, thay đổi luật/phạm vi, chi phí và phát hành. Chơi thử và phản hồi tại mốc có build; không phải điều phối từng file.
- Một agent chính chịu trách nhiệm kết quả của chặng được giao: khảo sát, chia bước nội bộ, triển khai, sửa lỗi, kiểm tra tích hợp, cập nhật trạng thái và bàn giao build.
- Agent được tự sửa code, scene và test liên quan trực tiếp đến mục tiêu đã giao. Danh sách file trong kế hoạch là dự kiến, không phải rào cản khiến lỗi liên quan bị bỏ lại.
- Agent không tự nhận mục tiêu sản phẩm khác. Thay luật, schema có ảnh hưởng save, thêm dịch vụ/chi phí, xóa tài sản hoặc phát hành cần quyết định riêng nếu chưa được ủy quyền.
- Mặc định một luồng triển khai chính. Chỉ tách công việc độc lập khi có lý do cụ thể; không tổ chức nhiều agent cùng sửa bootstrap/runtime. Agent chính vẫn chịu trách nhiệm tích hợp.
- Hỏi chủ dự án khi thiếu lựa chọn ảnh hưởng sản phẩm hoặc nguồn lực; việc chọn hàm, file và cách sửa thông thường thuộc trách nhiệm agent.

### Một vòng thực hiện

1. Đọc mục tiêu hiện tại, luật liên quan và trạng thái build. Tái hiện hành vi cần sửa bằng game hoặc kiểm tra phù hợp.
2. Ghi kế hoạch ngắn cho kết quả gần nhất: hành vi mong muốn, phạm vi, rủi ro và cách chứng minh. Không bắt chủ dự án duyệt từng bước kỹ thuật đã được giao.
3. Triển khai xuyên các phần liên quan. Sửa các regression do thay đổi trước khi bàn giao. Vấn đề độc lập được ghi backlog với mức ảnh hưởng rõ ràng.
4. Chạy kiểm tra phù hợp trong quá trình sửa; chạy bộ hồi quy chung tại điểm tích hợp. Chạy app và quan sát trực tiếp khi thay UI, input hoặc điều hướng.
5. Bàn giao một build xác định và báo cáo ngắn: làm được gì, đã kiểm tra gì, còn gì, bước kế tiếp. Nếu chưa đạt thì ghi chưa đạt và tiếp tục phần còn được phép làm.

Chỉ có một kết quả đang làm và tối đa một kết quả kế tiếp đã chuẩn bị. Backlog không cần phân rã hết thành hợp đồng thực thi. Một chặng có thể gồm nhiều commit nhưng không cần một hồ sơ nghiệm thu cho mỗi commit.

Nhánh tích hợp phải là nơi luôn biết build nào gần nhất đã được kiểm tra. Nhánh công việc ngắn theo kết quả; dùng worktree khi cần cô lập công việc đồng thời. Không merge hoặc phát hành chỉ vì test một module qua.

### Định nghĩa hoàn thành

Một kết quả hoàn thành khi:

- Hành vi được thực hiện từ điểm vào thật của game, không cần nút mô phỏng hoặc sửa state bằng tay để thay cho bằng chứng người chơi.
- Test phù hợp và kiểm tra tích hợp qua; lỗi chặn chơi hoặc mất tiến trình không còn trên hành trình bàn giao.
- UI thay đổi đã được xem ở kích thước mục tiêu; kiểm tra headless chỉ chứng minh phần nó quan sát được.
- Có build/revision xác định, lệnh kiểm tra, kết quả và giới hạn nền tảng. Mã nguồn hoặc input kiểm tra đổi thì kết quả cũ không được coi là bằng chứng mới.
- Lỗi còn lại có mức ảnh hưởng, người chịu trách nhiệm và chặng xử lý. Không coi lỗi chặn mục tiêu là đã xử lý vì nằm ngoài danh sách file dự kiến.

Phân biệt: kiểm tra kỹ thuật đạt; bản nội bộ chơi được; bản phát hành đủ điều kiện. Chủ dự án không phải ký lại mọi kiểm tra kỹ thuật; nghiệm thu trải nghiệm ở mốc build và quyết định phát hành vẫn thuộc chủ dự án.

### Kiểm tra và bằng chứng

- Khi sửa: test tập trung vào hành vi và rủi ro liên quan. Bug nên có cách tái hiện trước sửa và kiểm tra ngăn tái phát.
- Khi tích hợp: toàn bộ unit/contract test đang áp dụng, validator dữ liệu đang sử dụng và smoke test luồng chính. Không tự loại test đang fail để lấy kết quả xanh.
- Khi thay UI/input: chạy cửa sổ game, kiểm tra thao tác và hình ảnh. Android kiểm trên máy thật sớm; kiểm iOS theo kế hoạch nền tảng.
- Khi phát hành: toàn bộ QA thuộc phạm vi phát hành trong GDD, gồm nội dung, accessibility, thiết bị và hiệu năng.
- Evidence tự sinh ghi revision, trạng thái thay đổi chưa commit hoặc dấu vết nội dung, phiên bản công cụ, lệnh, exit code và log cả khi lỗi. Báo cáo viết tay chỉ bổ sung kết quả quan sát và quyết định.
- Nếu thiếu thiết bị/công cụ, ghi chưa kiểm chứng; tiếp tục công việc độc lập. Không đánh đồng emulator, desktop và thiết bị thật.

## 4. Bộ tài liệu vận hành tối thiểu

| Tài liệu | Chức năng duy nhất |
| --- | --- |
| `AGENTS.md` | Quyền thực hiện, giới hạn, cách kiểm chứng và báo cáo |
| `README.md` | Chạy game, chạy kiểm tra, đường dẫn build và tài liệu hiện hành |
| `docs/ROADMAP.md` | Các chặng sản phẩm, thứ tự và điều kiện hoàn thành |
| `docs/STATUS.md` | Build hiện tại, kết quả đang làm, lỗi chặn, việc kế tiếp, bằng chứng |
| `docs/DECISIONS.md` | Chỉ ghi quyết định làm thay đổi sản phẩm, kiến trúc lớn hoặc phạm vi phát hành |
| `GDD/` | Luật và hợp đồng sản phẩm; phần kế hoạch cũ được đánh dấu đã thay thế |

Các đường dẫn trên là cấu trúc đích, chưa được tạo hoặc kích hoạt bởi đề xuất này. Backlog gần hạn nằm trong ROADMAP; không lập thêm bảng trạng thái song song. CONTRIBUTING dẫn tới AGENTS và hướng dẫn chạy, không sao chép quy trình. Lịch sử work/evidence/handoffs vẫn tra cứu được nhưng không điều hành việc mới.

Không xây thêm một framework quản lý dự án. Tái sử dụng các script kiểm tra đang có; chỉ cần một điểm chạy bộ kiểm tra tích hợp rõ ràng, không phụ thuộc package cũ. Công cụ này là phần hỗ trợ chặng đầu, không thành dự án riêng.

## 5. Lộ trình mới

### R0 — Chuyển sang cách điều hành mới

Đầu ra: repository chỉ có một bộ quy tắc và một kế hoạch đang điều hành.

- Ghi nhận HEAD và danh sách thay đổi chưa commit; bảo tồn riêng những file chưa được Git theo dõi trước mọi thao tác chuyển hoặc xóa. Không tự đưa các thay đổi không liên quan vào commit.
- Tạo ROADMAP, STATUS và DECISIONS; thay nội dung điều hành trong AGENTS, README và CONTRIBUTING.
- Đánh dấu các kế hoạch/quy trình cũ đã bị thay thế; cập nhật liên kết và document register để không còn hai nguồn chỉ đạo đối nghịch.
- Giữ các phần luật/QA/thiết kế của GDD và các quyết định còn hiệu lực. GDD 08 dẫn tới roadmap mới; phần kế hoạch cũ có bản lưu.
- Ngừng yêu cầu inspect/start/verify/handoff/accept theo package cho việc mới. Pipeline cũ giữ để tra cứu hoặc chạy chức năng độc lập còn hữu ích, không là cổng giao việc.
- Chuyển các vấn đề chưa xử lý từ M0-A03, M1-A08–A12 và gate cũ thành backlog theo hành vi/thiết bị, không chép nguyên từng gói.

Kiểm chứng: đọc đối chiếu các điểm vào tài liệu, rà lệnh/quy định cũ còn được yêu cầu, xác nhận code/data/assets không bị đổi bởi việc chuyển đổi. Không chạy toàn bộ test game chỉ để nghiệm thu sửa tài liệu.

### R1 — Chơi liền mạch bốn level hiện có

Đầu ra: một bản tích hợp từ Home tới kết thúc bốn level, có thắng/thua, Next/Retry/Home và save/resume đúng.

Thứ tự nội bộ:

1. Chạy từ entry scene thật; ghi từng điểm đứt luồng và hiện trạng test, không dựa trên trạng thái done cũ.
2. Hoàn thiện một level từ Home đến thắng và thua, gồm đúng thời điểm xử lý input/chuyển scene.
3. Nối progression tới cả bốn level; xác nhận kết thúc level cuối theo GDD.
4. Kiểm save/resume khi quay Home, đóng/mở app và sau thắng/thua; không bỏ qua level hoặc mất tiến trình đã xác nhận.
5. Nối Hint, Undo, Restart và tutorial vào cùng runtime; sửa bố cục chặn thao tác, nút không hoạt động và text bị cắt.
6. Bổ sung hồi quy cho lỗi đã tái hiện và một điểm chạy bộ kiểm tra tích hợp chung. Xuất build Android nội bộ, kiểm hành trình trên thiết bị có sẵn.

Các vùng cần khảo sát gồm `game/scripts/bootstrap.gd`, `ui_flow_controller.gd`, `mvp_runtime.gd`, `board_screen.gd`, `board_view.gd`, `tutorial_controller.gd`, `save_repository.gd`, các scene và test liên quan. Đây là bản đồ khảo sát, không giới hạn quyền sửa lỗi trực tiếp của chặng.

Nghiệm thu: một lượt từ dữ liệu mới đi qua bốn level; một lượt thua/retry; một lượt đóng/mở giữa level; các hành vi Hint/Undo/Restart đúng luật; không cần điều khiển state từ ngoài game. Lưu bằng chứng kỹ thuật và quan sát trực tiếp của cùng build. Thiếu kiểm thử Android thì ghi riêng desktop đạt, R1 chưa đạt phần Android; iOS không chặn bản nội bộ này.

### R2 — Người mới chơi được mà không cần người hướng dẫn

Đầu ra: tutorial, input và phản hồi dễ hiểu trên bản liền mạch.

- Quan sát sớm 3–5 người mới để tìm điểm kẹt; đây là vòng tìm lỗi, không thay tiêu chí nghiệm thu 8/10 trong GDD.
- Kiểm hiểu X/clear/kéo/chạm đôi, X đỏ, tim, Hint và Undo; quan sát kích thước chữ/vùng chạm, feedback và trở lại sau gián đoạn.
- Sửa dựa trên quan sát; nếu cần đổi luật hoặc ngưỡng đã là hợp đồng thiết kế thì ghi quyết định và đồng bộ test/tài liệu.
- Thực hiện vòng nghiệm thu người mới theo GDD: ít nhất 8/10 hoàn thành hướng dẫn và hiểu X đỏ; ghi build và kết quả từng lượt.

Chủ dự án hỗ trợ người chơi và thiết bị; agent chuẩn bị build, kịch bản, tổng hợp và sửa. Trong lúc chờ người chơi chỉ thực hiện việc độc lập đã nằm trong mục tiêu được giao; không tự mở thêm hệ thống.

### R3 — Hoàn thiện nội dung và hình thức bản đầu

Đầu ra: 24 level gốc đã kiểm và bộ hình/âm thanh đủ cho phát hành.

- Chọn một màn và một bộ asset đại diện, tích hợp vào game để kiểm đọc bàn, nguồn gốc và ngân sách hiệu năng trước khi sản xuất hàng loạt.
- Bổ sung level thành từng nhóm nhỏ, chơi chúng ngay trong campaign. Giữ yêu cầu level 1–18 S1/S2, 19–24 cần S3, mốc 10/20 và nghiệm duy nhất.
- Mỗi level có lượt giải không xem đáp án theo tiêu chí GDD; validator và trace phải đạt. Fixture kỹ thuật không tính vào 24 level.
- Hoàn thiện Help/Settings, âm thanh, phản hồi, reduced motion và accessibility theo phạm vi GDD; không có nút hứa chức năng nhưng không hoạt động.
- Sau mỗi nhóm nội dung/asset, kiểm lại luồng chơi và lưu tiến trình trên build tích hợp.

R3 triển khai đầy đủ sau R2 để hạn chế làm lại nội dung và asset. Nghiên cứu asset đại diện có thể thực hiện sớm nếu được giao, nhưng không lấy mất ưu tiên của R1.

### R4 — Đủ điều kiện phát hành Android/iOS

Đầu ra: build ứng viên cho hai nền tảng cùng hồ sơ QA đúng phạm vi.

- Ngay R0 ghi người phụ trách và khả năng cung cấp iPhone, Mac/Xcode/signing; thử export/install iOS sớm khi có nguồn lực, không chờ R4 mới phát hiện rủi ro nền tảng.
- Đo offline, tải, frame time, bộ nhớ, safe area, chữ/vùng chạm, accessibility và vòng đời app trên thiết bị mục tiêu với workload/asset đại diện bản cuối.
- Kiểm cài mới, cập nhật và tương thích save khi áp dụng; kiểm toàn bộ 24 level và lỗi còn lại.
- Không còn lỗi crash, mất tiến trình, sai luật hoặc chặn hoàn thành campaign. Các lỗi còn lại phải được chủ dự án chấp thuận với ảnh hưởng cụ thể.
- Chủ dự án quyết định phát hành. Nếu chưa có iOS, ghi phần iOS bị chặn; phát hành Android trước chỉ sau quyết định phạm vi rõ ràng.

## 6. Kế hoạch chuyển đổi cụ thể

1. Hoàn thiện và duyệt chính đề xuất này về phạm vi thay thế; không cần tạo thêm một chuỗi package quản trị để xin quyền lập kế hoạch.
2. Thực hiện R0 trong một đợt thay đổi có thể review. Ban đầu giữ hồ sơ cũ tại chỗ và đánh dấu lịch sử để bảo toàn liên kết. Chỉ di chuyển vật lý sau khi xác định đầy đủ đường dẫn tham chiếu; không cần xóa để quy trình mới có hiệu lực.
3. Bàn giao diff quy trình cùng ROADMAP/STATUS, rà mâu thuẫn; chuyển điểm vào của agent sang quy tắc mới trong cùng đợt.
4. Nhận mục tiêu R1 và triển khai xuyên suốt bằng quy trình mới. Không yêu cầu chủ dự án lần lượt giao lại A08, A09, A10, A11, A12.
5. Sau R1 và R2, đánh giá phần thủ tục nào thực sự giúp phát hiện lỗi; bỏ phần ghi chép trùng. Chỉ chi tiết hóa chặng kế tiếp theo bằng chứng vừa có.

Việc áp dụng quy trình khác với soạn đề xuất. Tài liệu này không tự cấp quyền xóa hồ sơ, chuyển trạng thái package hoặc thay gameplay. Không có thay đổi quy trình hiện hành nào đã được thực thi trong lúc viết tài liệu.

## 7. Nhịp báo cáo và đo hiệu quả

Báo cáo mỗi lần bàn giao chỉ trả lời: build nào; người chơi làm được gì mới; kiểm tra nào đã chạy; lỗi nào còn chặn; hành động tiếp theo. Khi công việc kéo dài, cập nhật điểm đã biết và điều đang kiểm tra, không yêu cầu chủ dự án duyệt lặp lại.

Theo dõi bốn chỉ số qua R1/R2: thời gian từ giao mục tiêu tới build chơi được; thời gian chờ quyết định/thiết bị/review; lỗi chặn xuất hiện lại sau tích hợp; số hành trình người chơi đã chứng minh trên build hiện tại. Không suy ra giờ công từ chênh lệch timestamp package và không dùng số commit/package làm thước đo năng suất.

Chưa cam kết số ngày hoàn tất toàn dự án khi chưa có baseline R1 và lịch cung cấp thiết bị/người chơi. Sau bước tái hiện R1, ước lượng phần việc gần nhất bằng khoảng và ghi giả định; cập nhật khi có bằng chứng mới. Các mốc R2–R4 được quản lý bằng đầu ra và dependency cho tới khi đủ dữ liệu để lập lịch đáng tin.

## 8. Căn cứ và kiểm tra tính nhất quán

- `work/packages/M1-A10.md`: regression điều hướng sau thay layout.
- `work/handoffs/M1-A08.md`: kết quả runtime và phần tutorial còn cần nối/kiểm thử thực tế.
- `work/evidence/M1-A12/full-regression.txt`: visual smoke còn fail dù kiểm tra package đạt.
- `work/state/M0-A03.toml`: thiết bị và asset đại diện còn chặn.
- `GDD/01-tam-nhin-va-pham-vi.md`: phạm vi 24 level, nền tảng, luật và cổng người mới.
- `GDD/08-ke-hoach-trien-khai-cho-agent.md`: kế hoạch và gate cũ cần thay thế ở R0.

Đã tự đối chiếu thiết kế: R0 chỉ thay cách điều hành; R1 chứng minh luồng chơi; R2 chứng minh khả năng học; R3 hoàn thiện bản đầu; R4 chứng minh phát hành. Yêu cầu iOS và chất lượng phát hành được giữ nhưng không chặn học hỏi từ bản nội bộ. Không tạo lại hợp đồng theo từng file, không tuyên bố các trạng thái done cũ là bằng chứng cho build mới.
