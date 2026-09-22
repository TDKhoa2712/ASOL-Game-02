> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.

# SDD ledger — plan: docs/archive/agent-history/superpowers/plans/2026-09-22-repository-restructure-agent-pipeline.md

Pre-flight: Task 1 → Task 2 — `Package`, TOML parser và chuẩn hóa đường dẫn được catalog/dependency/document register tiêu thụ — giao diện khớp theo spec.
Pre-flight: Task 2 → Task 3 — catalog, document register, link validation và trace được CLI chỉ-đọc tiêu thụ — giao diện khớp theo spec.
Pre-flight: Task 1–3 → Task 4 — mô hình package, repo root và CLI được lifecycle Git tiêu thụ — giao diện khớp theo spec.
Pre-flight: Task 4 → Task 5 — `State` và `changed_paths` được verify/scope/evidence/handoff/accept tiêu thụ — giao diện khớp theo spec.
Pre-flight: Task 1–5 → Task 6 — schema và CLI được entrypoint, governance, template và seed packages tiêu thụ — giao diện khớp theo spec.
Pre-flight: Task 1–6 → Task 7 — doctor/authority checks và cấu trúc đích được migration tiêu thụ — giao diện khớp theo spec.
Pre-flight: Task 1–7 → Task 8 — toàn bộ pipeline và cấu trúc kho được kiểm chứng end-to-end — giao diện khớp theo spec.
Task 9: Ruling: người dùng đã đổi tên workspace thủ công thành `ASOL-Game-02` trước Task 1 — bỏ qua thao tác đổi tên lần hai và giữ các tham chiếu `ASOL-Game-03` chỉ như lịch sử migration cho tới Task 7 — nếu sai, tài liệu lịch sử có thể cần chỉnh lại một lần.
Task 1: complete (commits 495f32b..fb8a435, tests: rtk python -m unittest tools.tests.test_agent_pipeline.PackageParsingTests -v → OK)
Task 2: complete (commits fb8a435..cd58f77, tests: rtk python -m unittest tools.tests.test_agent_pipeline.CatalogValidationTests -v → OK)
Task 3: complete (commits cd58f77..0f46d3a, tests: rtk python -m unittest tools.tests.test_agent_pipeline.ReadOnlyCliTests -v → OK)
Task 4: complete (commits 0f46d3a..9e9ddbb, tests: rtk python -m unittest tools.tests.test_agent_pipeline.LifecycleTests -v → OK)
Task 5: complete (commits 9e9ddbb..2f91fbb, tests: rtk python -m unittest tools.tests.test_agent_pipeline.VerificationTests -v → OK)
Task 6: complete (commits 2f91fbb..46d8ee4, tests: rtk python -m unittest tools.tests.test_agent_pipeline.RepositoryContractTests -v → OK)
Task 7: complete (commits 46d8ee4..e8dee6f, tests: rtk python -m unittest tools.tests.test_agent_pipeline.RepositoryContractTests.test_real_repository_passes_doctor -v → OK)
Task 8: complete (commits e8dee6f..HEAD, tests: all verifications PASS → OK)
