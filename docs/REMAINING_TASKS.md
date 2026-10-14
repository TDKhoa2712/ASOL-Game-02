# Danh mục Tiến độ và Các vấn đề Tồn đọng — CanDoKu

> **Ngày cập nhật:** 2026-10-14  
> **Nền tích hợp:** Nhánh version `release/vX.Y.Z` (xem [VERSIONING](VERSIONING.md))  
> **Mục tiêu hiện tại:** v1.0.1 (`release/v1.0.1`) — Kiểm thử thực tế (Track E) và Chuẩn bị phát hành (Track F).

---

## 1. Tổng quan Trạng thái Dự án

| Hạng mục | Trạng thái | Ghi chú |
|---|---|---|
| **Rebuild 10 Modules (M01–M10)** | ✅ Hoàn thành 100% | Độc lập, không phụ thuộc code reference, signals native. |
| **System Upgrade & Tooling** | ✅ Hoàn thành 100% | Solver S4–S7, DDA PaceAdjuster, ShapeFingerprint, XOR Codec. |
| **Kho nội dung 36.500+ Màn (N=4–12)** | ✅ Hoàn thành 100% | 31 bank offline, hỗ trợ Campaign 30, 100, 998 và Endless Mode. |
| **Hệ thống Endless Levels (Phases 1–4)** | ✅ Hoàn thành 100% | 4-tier selection, EndlessRuntime, Title Screen integration. |
| **Hệ thống Procedural SFX & Tuner** | ✅ Hoàn thành 100% | `Effect` có 34 mục: 19 tổng hợp PCM Synth, 15 file `.ogg` (whoosh, thắng, thua, 12 voice combo); công cụ `sfx_tuner.tscn`. |
| **Tài nguyên Mỹ thuật & Nhận diện (Track D)** | ✅ Cơ bản hoàn thành | Đã có Logo, 6 Sprite kẹo chính thức, 8 nút Settings, Splash Screen, Heart Sprite, BGM OGG, font Be Vietnam Pro, app icon. Còn banner Thắng/Thua. |
| **Kiểm thử Trải nghiệm Thiết bị (Track E)** | ⚠️ **Tồn đọng** | Chưa chạy QA cử chỉ cảm ứng, Safe Area và playtest người dùng thật. |
| **Đóng gói Phát hành (Track F)** | ⚠️ **Một phần** | Đã có export preset 1.0.1 (`ee5a0ba`) và CI deploy Web; keystore Android chưa xác minh, chưa mã hóa Bank khi build APK. |

---

## 2. Chi tiết các Hạng mục Đã Hoàn thành

1. **Rebuild Kiến trúc & Cốt lõi Gameplay**:
   - Chuẩn hóa 4 trạng thái ô (`BLANK, MARK, CANDY, ERROR`; GIVEN bỏ 2026-10-14).
   - Bỏ tự động khóa ô (auto-lock); giữ `ERROR` vĩnh viễn không tẩy xóa.
   - Hỗ trợ vuốt kéo (swipe drag) tô/xóa X qua nhiều ô.
   - Sửa triệt để lỗi chớp nháy X khi chạm đúp (RST-016).
   - Undo X luôn hoạt động cố định trong gameplay (RST-021).
   - Đầy đủ luồng màn hình: `SplashScreen` $\rightarrow$ `TitleScreen` $\leftrightarrow$ `PuzzleScreen` $\leftrightarrow$ `WinScreen` / `FailScreen`, Options Overlay.

2. **Dữ liệu & Thuật toán sinh màn**:
   - Sinh bộ dữ liệu 36.500+ level offline có nghiệm duy nhất và pace gợi ý đi kèm cho N=4–12.
   - Hỗ trợ các chế độ: `demo_30.json`, `campaign_100.json`, `full_998.json`, `advanced.json`.
   - Thuật toán giải đố nâng cao S4–S7 (Subset Pairs, Triples, Quads, Contradiction chains).
   - Hệ thống điều chỉnh độ khó động DDA (`PaceAdjuster`) theo chuỗi thắng/thua.
   - Chế độ Endless Levels với 4-tier selection pipeline và con trỏ cursor độc lập.

3. **Âm thanh & Hiệu ứng tương tác**:
   - Viết mới `pcm_synth.gd` sinh sóng âm thanh 16-bit PCM (19 hiệu ứng tổng hợp; tổng 34 mục `Effect`).
   - BGM `bgm-candoku-melody.ogg` (chuyển OGG tại `693a941`), SFX whoosh mở Settings.
   - Hiệu ứng vỡ tim rơi (`heart_sprite.png`) và hiệu ứng sóng vào bàn cờ (`board_entry`).
   - Bộ công cụ trực quan `sfx_tuner.tscn` (nhấn `F6` để thử nghiệm và sao chép cấu hình).

4. **Tài nguyên Mỹ thuật & Nhận diện**:
   - Bộ Sprite kẹo PNG 2D hoàn chỉnh: `bonbon.png`, `cotton_puff.png`, `gummy_drop.png`, `hard_candy.png`, `lollipop.png`, `toffee.png`.
   - Bộ 8 nút cài đặt PNG trong `game/assets/ui/settings/`.
   - Logo CanDoKu chính thức `logo_candoku.png`.
   - Studio Logo Splash Screen native Godot (`splash_screen.gd`).

---

## 3. Danh mục các Hạng mục Còn Tồn đọng (Backlog)

### 📌 Track D: Hoàn thiện Tài nguyên Còn Thiếu

- [x] **D1. BGM OGG**: đã chuyển sang `game/assets/audio/bgm/bgm-candoku-melody.ogg` (`693a941`, 2026-10-09). Tần số lấy mẫu 48 kHz stereo (đo bằng ffprobe).
- [x] **D2. Phông chữ Tiếng Việt**: `game/assets/fonts/` có Be Vietnam Pro và Nunito (OFL); heading chuyển sang Be Vietnam Pro tại `7385ddb`.
  - Font số HUD dạng tabular: chưa xác định.
- [ ] **D3. App Icon & Banner Đồ họa (Độ ưu tiên: P1)**:
  - [x] **App Icon**: logo CanDoKu làm app icon (`94b4525`, 2026-10-14; `game/assets/icons/candoku-logo-1024.png`).
  - **Banner Thắng / Thua (P2)**: Đồ họa trang trí cho màn hình kết quả (Win/Fail Screen) kèm hiệu ứng sao (Stars).

---

### 📌 Track E: Kiểm thử Thực tế & Trải nghiệm (QA & Playtest)

> *Toàn bộ 88 test suites (`game/tests/test_*.gd`) hiện tại mới chỉ kiểm tra logic không đầu (Headless), chưa kiểm thử trên thiết bị phần cứng thật.*

- [ ] **E1. QA Cử chỉ cảm ứng trên thiết bị thật (Android / iOS)**:
  - Thử nghiệm độ nhạy của thao tác: Chạm đơn (đánh dấu X), chạm đôi (đặt kẹo) và vuốt kéo nhiều ô (swipe) trên màn hình cảm ứng di động.
  - Đảm bảo thời gian giữ và khoảng cách kéo không gây nhận diện nhầm giữa tap và swipe.
- [ ] **E2. QA Bố cục đa màn hình & Vùng an toàn (Safe Area)**:
  - Kiểm thử responsive layout trên các tỉ lệ màn hình phổ biến: 19.5:9, 20:9 (các dòng máy Android hiện đại), 16:9, và màn hình máy tính bảng (4:3, 16:10).
  - Kiểm tra viền màn hình tránh bị che bởi tai thỏ (Notch), Dynamic Island hoặc thanh điều hướng hệ thống (Navigation Bar).
- [ ] **E3. QA Thẩm âm (Audio Listening QA)**:
  - Nghe thử 19 hiệu ứng tổng hợp (Procedural SFX) và 15 file `.ogg` trên loa ngoài điện thoại tầm trung và tai nghe (Bluetooth/dây) để cân chỉnh âm lượng, độ đanh và đảm bảo không có tiếng lộp bộp (click/pop).
- [ ] **E4. Playtest Mù & Đánh giá Độ khó (DDA Observation)**:
  - Cho người chơi trải nghiệm chuỗi 30 level đầu tiên để đánh giá: Độ dễ hiểu của luật, điểm nghẽn khó chịu, độ hữu dụng của Hint và cảm giác thỏa mãn khi giải đố.
  - Theo dõi thuật toán DDA tự động bù rank (`rank_offset`) có hoạt động tự nhiên hay không.

---

### 📌 Track F: Đóng gói & Phát hành (Release Preparation)

- [ ] **F1. Mã hóa dữ liệu Bank trước khi Export**:
  - Chạy kịch bản `python -B tools/encode_banks.py --input game/data/banks --output <export_dir>` để biến đổi XOR dữ liệu màn chơi, bảo vệ puzzle không bị đọc trộm đáp án từ file APK.
- [ ] **F2. Cấu hình Dự án & Keystore Android**:
  - Thiết lập Android Export Template trong Godot: Package name hiện là `org.asol.game02` (preset `Android Release`, version 1.0.1, `ee5a0ba`); còn Keystore ký số (chưa xác minh) và quyền hạn tối thiểu.
- [ ] **F3. Ẩn công cụ Debug trong bản Release**:
  - Đảm bảo trong bản xuất xưởng (Release export), nút `🛠 Debug` và màn hình `sfx_tuner.tscn` được vô hiệu hóa hoặc loại bỏ hoàn toàn.
- [ ] **F4. Chuẩn bị iOS (Nếu có kế hoạch phát hành App Store)**:
  - Cần môi trường macOS, Xcode và tài khoản Apple Developer để tạo hồ sơ chứng chỉ (Provisioning Profile) và thử nghiệm TestFlight.

---

### 📌 Vấn đề Kỹ thuật nhỏ cần theo dõi (Technical Deferred)

- [ ] **Glyph Unicode Hỗ trợ mù màu**:
  - Trong `puzzle_board.gd`, các ký hiệu hỗ trợ mù màu phụ thuộc vào font chữ fallback. Cần kiểm tra xem trên một số thiết bị Android đời cũ có bị lỗi hiển thị ô vuông trống (tofu `□`) hay không.
- [ ] **Dữ liệu Snapshot mở rộng**:
  - Các trường `rating` và `solve_profile` đã có trong cấu trúc dữ liệu snapshot nhưng hiện chưa có module nào sử dụng (có thể bổ sung khi làm màn thống kê chi tiết).

---

## 4. Thứ tự Ưu tiên Thực hiện Tiếp theo

```text
Giai đoạn 1 (Ưu tiên cao nhất - P0):
└── (Đã xong: BGM OGG, font Be Vietnam Pro, logo, sprite kẹo)

Giai đoạn 2 (Ưu tiên trung bình - P1):
└── Cài đặt bản build lên thiết bị Android thật
└── QA cử chỉ cảm ứng (Tap, Double-tap, Swipe) & Vùng an toàn Safe Area
└── Playtest 30 màn đầu tiên và thẩm âm loa ngoài

Giai đoạn 3 (Ưu tiên hoàn thiện - P2):
└── Banner Thắng/Thua (app icon đã có `94b4525`)
└── Chạy kịch bản mã hóa Bank bằng XOR
└── Đóng gói file APK/AAB hoàn chỉnh
```
