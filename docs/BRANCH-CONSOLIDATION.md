# Biên bản hợp nhất nhánh — 2026-09-24

Baseline trước cải tổ: `dev` tại `008f0d962d291ca6d5614f6613e8129b64673f41`. Toàn bộ tip nhánh dưới đây là ancestor của dev. Dev được fast-forward từ `28f2698`; không giải quyết conflict hoặc sửa gameplay.

Commit baseline bảo toàn 15 file Godot UID, asset prompt brief và đề xuất cải tổ trước đó. `main` giữ tại `8a332c7e8714556473ae8e4f3e7b31c54358c920`. Nhánh mới: `refactor/project-reset`.

## Nhánh công việc đã dọn

| Nhánh | Tip đã bảo toàn |
| --- | --- |
| work/m0-a01 | 8a332c7e8714556473ae8e4f3e7b31c54358c920 |
| work/m0-a01-godot-toolchain-and-device-baseline | b9e5484af01a583ec5a8c73e24574213f202729d |
| work/m0-a01-godot-toolchain-and-editor-baseline | 365eaab7e56c9acff7244efe2f59f4a6f06b0413 |
| work/m0-a02-gesture-and-input-interaction-prototype | ce17b3801395e979b2f3308551943d0b2e339e24 |
| work/m0-a03-mobile-device-rendering-and-performance-validation | bdf8e8b92d718435da71a2c7a23dc685ce4d94a2 |
| work/m0-defer-defer-device-validation-for-m1-build | a72fc60cfd02bf81224c23a6dcbc73fa08336585 |
| work/m0-replan-re-sequence-m0-for-editor-first-playable-prototype | 48b89e9767029d2a9ad078c0d5fa55b0e4682943 |
| work/m0-ui-asset-briefs-mvp-ui-and-asset-creation-briefs | 705632077af3cfd8f0a619adcda98de59bdceaaf |
| work/m1-a03-atomic-save-session-recovery-and-linear-progress | 90c816143a3138d53b52e813e9087bdbf64ca1de |
| work/m1-a04-runtime-s2-and-s3-hint-evidence | 0b4a2780b5b998ff79a799feca080cc66ba275c9 |
| work/m1-a05-five-screen-ui-shell-and-accessible-board | 48353dfa0cc6e5bc79e1247442851c3f7529f816 |
| work/m1-a06-level-1-tutorial-and-resumed-milestones | 72f97244bf2cfa84637343452d2047fac7b6391f |
| work/m1-a07-mvp-ui-flow-shell | c61690b4e9d321213530e02a14be5cd092a7fe86 |
| work/m1-a08-mvp-runtime-integration | 6f8466c010493831139fd3b63f20f568d0630884 |
| work/m1-a09-home-screen-layout-correction | bb6c14526380153af9b2584582286dbc6b973eff |
| work/m1-a10-home-navigation-wiring-correction | 395c4c3f4f2c7d0f09e3d9c9f55b1d8604216cb8 |
| work/m1-a11-gameplay-result-screen-routing-correction | 13dd53a7dc72de488f7b943d816ade48de42c3ef |
| work/m1-a12-defer-gameplay-result-transition-until-input-completes | 008f0d962d291ca6d5614f6613e8129b64673f41 |
| work/m1-c01-four-original-release-order-levels-for-vertical-slice | 51342a1d450f44a2f581119714b11421ffa339b7 |
| work/m1-plan-plan-and-register-m1-mvp-work-packages | 73b6d46d860186a3cf8fa5aa7f136905e8e60a02 |

Xóa bằng `git branch -d`, không dùng force. Khôi phục tên nhánh bằng `git branch` với tên và hash trong bảng. Không mất commit vì các tip vẫn nằm trong lịch sử dev.

## Worktree, stash và remote

- Gỡ worktree `C:/Users/khoat/AppData/Local/Temp/asol-m0-ui-asset-briefs-20260924` sau khi `status --short --ignored` rỗng và tip đã có trong dev. Không dùng force. Nội dung tracked có thể dựng lại từ tip trong bảng.
- Giữ hai stash `preserve user files before M1-A08` và `preserve user files before M1-A07`. Hai cây untracked trùng nhau; hash của cả 12 file khớp bản đã bảo toàn. Stash A08 có thêm ảnh chụp trạng thái M1-A07 cũ; không áp dụng đè timestamp nghiệm thu về sau.
- Không có remote, không fetch/push hoặc xóa nhánh server.

Thao tác này chứng minh bảo toàn lịch sử và gom nhánh; không chứng minh chất lượng hoặc khả năng chơi liền mạch của game.
