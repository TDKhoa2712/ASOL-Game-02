# Quy tắc quản lý Version — Alpaca Solution

> Quy tắc bất di bất dịch, áp dụng chung cho mọi game project.
> Cập nhật lần cuối: 2026-10-09

---

## 1. Mô hình nhánh (Release Branch Model)

```
main (production-ready, chỉ chứa các bản đã release)
│
├── release/v1.0.1  ← nhánh quản lý version 1.0.1
│   ├── feat/v1.0.1/ten-tinh-nang-a
│   ├── feat/v1.0.1/ten-tinh-nang-b
│   └── fix/v1.0.1/ten-loi        ← hotfix sau khi release
│
├── release/v1.0.2  ← nhánh quản lý version 1.0.2
│   ├── feat/v1.0.2/tinh-nang-moi
│   └── ...
│
└── dev  ← sandbox tích hợp, thử nghiệm (tùy chọn)
```

## 2. Quy ước đặt tên

### Nhánh version
```
release/v<major>.<minor>.<patch>
```
Ví dụ: `release/v1.0.1`, `release/v1.0.2`, `release/v2.0.0`

### Nhánh con (làm việc trên một version)
```
<type>/v<version>/<mo-ta-ngan>
```
- `type`: `feat`, `fix`, `hotfix`, `refactor`, `docs`, `test`, `chore`, `perf`
- Ví dụ: `feat/v1.0.1/endless-mode`, `fix/v1.0.1/crash-on-undo`, `hotfix/v1.0.1/save-corruption`

### Tag release
```
v<major>.<minor>.<patch>
```
Ví dụ: `v1.0.1`, `v1.0.1-hotfix.1`, `v1.0.2`

## 3. Semantic Versioning

| Thành phần | Khi nào tăng | Ví dụ |
|-----------|-------------|-------|
| **MAJOR** (v**X**.0.0) | Thay đổi lớn, phá vỡ tương thích save/data | v1 → v2: đổi engine, đổi format save |
| **MINOR** (vX.**Y**.0) | Thêm tính năng mới, tương thích ngược | v1.0 → v1.1: thêm game mode mới |
| **PATCH** (vX.Y.**Z**) | Sửa lỗi, cải thiện nhỏ | v1.0.1 → v1.0.2: fix crash, tweak UI |

## 4. Vòng đời một Version

### Giai đoạn 1: Khởi tạo
```bash
# Tạo nhánh version mới từ main (hoặc từ version trước)
git checkout main
git checkout -b release/v1.0.1
git push -u origin release/v1.0.1
```

### Giai đoạn 2: Phát triển
```bash
# Tạo nhánh con để phát triển tính năng
git checkout release/v1.0.1
git checkout -b feat/v1.0.1/endless-mode

# Làm việc, commit, push
git add <files>
git commit -m "feat(endless): add level sequencing"
git push -u origin feat/v1.0.1/endless-mode

# Xong → merge về nhánh version
git checkout release/v1.0.1
git merge feat/v1.0.1/endless-mode
# Hoặc tạo PR: feat/v1.0.1/endless-mode → release/v1.0.1
```

### Giai đoạn 3: Release
```bash
# Khi mọi tính năng đã hoàn tất và test pass
git checkout release/v1.0.1
git tag v1.0.1
git push origin v1.0.1

# Merge vào main để đánh dấu production
git checkout main
git merge release/v1.0.1
git push origin main
```

### Giai đoạn 4: Hotfix (sau release)
```bash
# Người chơi báo lỗi ở v1.0.1
git checkout release/v1.0.1
git checkout -b hotfix/v1.0.1/save-corruption

# Sửa lỗi, test
git commit -m "hotfix(save): fix data corruption on resume"

# Merge về nhánh version
git checkout release/v1.0.1
git merge hotfix/v1.0.1/save-corruption

# Tag bản hotfix
git tag v1.0.1-hotfix.1
git push origin v1.0.1-hotfix.1

# Merge vào main
git checkout main
git merge release/v1.0.1

# Forward-merge hotfix vào version đang phát triển
git checkout release/v1.0.2
git merge release/v1.0.1
```

## 5. Quy tắc bất di bất dịch

### 5.1 Cách ly version
- **Nhánh con CHỈ được tạo từ nhánh version cha của nó.** Không tạo nhánh con từ version khác.
- **Nhánh con CHỈ merge về nhánh version cha.** Không merge chéo giữa các version.
- **Code mới KHÔNG được leak ngược** vào version cũ. Version cũ chỉ nhận hotfix.

### 5.2 Chiều merge
```
Nhánh con  →  Nhánh version cha  →  main
                    ↓
          Forward-merge xuống version mới hơn (khi có hotfix)
```
- Hotfix ở version cũ phải được **forward-merge** vào tất cả version mới hơn đang phát triển.
- **KHÔNG BAO GIỜ merge ngược** từ version mới về version cũ (trừ hotfix riêng cho version cũ).

### 5.3 Commit và tag
- Mọi commit tuân theo Conventional Commits: `<type>(<scope>): <mô tả>`.
- Mọi bản release phải có tag theo semver.
- Không force-push lên nhánh version hoặc main.
- Không xóa nhánh version đã release (giữ để hotfix).

### 5.4 Release checklist
Trước khi tag release, phải hoàn tất:
1. Tất cả nhánh con đã merge về nhánh version
2. Test suite pass hoàn toàn
3. Build thành công trên target platform
4. Version number cập nhật trong project config
5. Changelog/release notes viết xong

### 5.5 Nhánh version mới
- Tạo từ `main` (sau khi version trước đã merge vào main) hoặc từ nhánh version trước.
- Ngay sau khi tạo, cập nhật version number trong project config.

## 6. Xử lý conflict khi forward-merge hotfix

```bash
# Đang phát triển v1.0.2, cần nhận hotfix từ v1.0.1
git checkout release/v1.0.2
git merge release/v1.0.1

# Nếu conflict:
# - Giữ code mới của v1.0.2 cho các tính năng mới
# - Nhận logic fix từ v1.0.1
# - Test lại sau merge
```

## 7. Sơ đồ tổng quan

```
main ─────●──────────────●──────────────●───────
          │              │              │
          │  tag v1.0.1  │  tag v1.0.2  │
          │              │              │
release/v1.0.1 ──●──●──●──┐──●(hotfix)──┐
                 │  │  │  │             │
          feat/  feat/ fix/│      hotfix/│
                          │             │
release/v1.0.2 ───────────●──●──●──●(merge hotfix)──●
                             │  │  │
                       feat/ feat/ fix/
```

## 8. Áp dụng cho Agent/CI

- Agent làm việc trên nhánh con, KHÔNG trực tiếp trên nhánh version.
- CI/CD trigger build khi có tag `v*`.
- Nhánh `dev` (nếu dùng) là sandbox thử nghiệm, không phải nhánh release.
- Khi chuyển sang mô hình này, `dev` sẽ được thay thế bởi nhánh version hiện hành.

---

> **Lưu ý:** File này là quy tắc nền tảng. Mỗi project có thể bổ sung quy tắc riêng nhưng KHÔNG được vi phạm các quy tắc bất di bất dịch ở mục 5.
