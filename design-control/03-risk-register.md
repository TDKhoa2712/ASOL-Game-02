# Risk Register

Thang định tính: **Low / Medium / High**. `Owner role` là vai trò chịu trách nhiệm
theo dõi/đóng rủi ro, không phải giao việc triển khai trong tài liệu này.

| RISK-ID | Category | Probability | Impact | Affected areas | Mitigation | Validation phase | Owner role |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RISK-001 | Input/UX | High | High | GR-09..14/29/30, UX-09..11 | Prototype trên thiết bị, đo lỗi nhận dạng và tune tham số | M0 | UX Lead + Technical Lead |
| RISK-002 | Game feel | High | High | D-08, GR-16/17/19/31..33 | Playtest 3 tim + Undo X + Restart về công bằng/cảm xúc; mọi đổi luật qua decision change | M1 | Game Design Lead |
| RISK-003 | Puzzle depth | High | High | D-02, LV-03/05/08, 24-level campaign | Hoàn tất validator/runtime Hint S3; biên tập đúng band 18 S2 + 6 S3, solver metrics và blind solve ≥1 tim | M1/M2 | Puzzle Design Lead |
| RISK-004 | Mobile performance | Medium | High | TECH-13/19/21, ART-06..13 | Chốt device baseline và đo atlas thật | M0 | Technical Lead + Art Lead |
| RISK-005 | Small-screen usability | Medium | High | UX-18, QA-27 | Kiểm bố cục N=6, chữ lớn, safe area và vùng chạm trên máy mục tiêu | M0 | UX Lead |
| RISK-006 | Scope governance | Medium | High | Meta, N>6, S4/S5, package K | S3 đã đóng bằng DEC-013; đóng DQ-002 và áp checklist/change-control | NOW | Design Orchestrator |
| RISK-007 | Documentation authority | Medium | High | README, GDD/04, design reviews, GDD/08 | Duy trì v0.5.0/DEC-013..016 và quét status drift tại mỗi change | NOW | Design Orchestrator |
| RISK-008 | Undefined test baseline | High | High | QA-30/50, TECH-19/21 | Chốt Godot/renderer/device/OS/memory budgets | M0 | Technical Lead + QA Lead |
| RISK-009 | Content production | High | High | M1/M2, QA-01/33/49/57 | Áp per-level gate đã chốt, tạo biên bản blind solve ≥1 tim và thay mọi level không đạt | M1/M2 | Puzzle Design Lead + QA Lead |
| RISK-010 | Accessibility | Medium | High | UX-16..21, ART-03/11, QA-27..29 | Xác định protocol và thử prototype với assistive technology | M1 | Accessibility/UX Lead |
| RISK-011 | Save architecture | Medium | Medium | TECH-06/08..15, QA-23..25/31 | Xác nhận failure model trên platform trước khi coi schema/version là frozen | M1 | Technical Lead |
| RISK-012 | Originality/licensing | Low | High | D-07, ART-05, QA-34 | Asset manifest và review nguồn/quyền trước content complete | M1 | Art Lead + Product Owner |
| RISK-013 | iOS toolchain | Medium | High | M0, QA-30/34 | Xác nhận macOS/Xcode và build thử trong baseline M0 | M0 | Technical Lead |
| RISK-014 | Dead score metric | Medium | Medium | GR-18, UX-05/06 | Chỉ hiện Result, không quy đổi; quan sát comprehension/motivation trước khi khóa hệ số | M1 | Game Design Lead |
| RISK-015 | Historical proposal leakage | High | Medium | design-reviews, D-09/10, GDD/11 | Luôn áp canonical priority và phân loại DEFERRED/PARKED | NOW | Design Orchestrator |
