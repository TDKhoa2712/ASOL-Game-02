# Danh mục Tiến độ và Các vấn đề Tồn đọng — CanDoKu

> **Ngày cập nhật:** 05-10-2026  
> **Nền tích hợp:** Nhánh `dev` (Commit `add0173`)  
> **Mục tiêu hiện tại:** Hoàn thiện tài nguyên (Track D), Kiểm thử thực tế (Track E), và Chuẩn bị phát hành (Track F).

---

## 1. Tổng quan Trạng thái Dự án

| Hạng mục | Trạng thái | Ghi chú |
|---|---|---|
| **Rebuild 10 Modules (M01–M10)** | ✅ Hoàn thành 100% | Độc lập, không phụ thuộc code reference, signals native. |
| **System Upgrade & Tooling** | ✅ Hoàn thành 100% | Solver S4–S7, DDA PaceAdjuster, ShapeFingerprint, XOR Codec. |
| **Nội dung 998 Màn chơi** | ✅ Hoàn thành 100% | 4×4 (36), 5×5 (49), 6×6 (913), hỗ trợ cả `demo_30` và `full_998`. |
| **Hệ thống Procedural SFX** | ✅ Hoàn thành 100% | Tự sinh 9 hiệu ứng âm thanh bằng PCM Synth, kèm bộ tinh chỉnh `sfx_tuner`. |
| **Sửa lỗi Tiến trình & Normal Play** | ✅ Hoàn thành 100% | Khắc phục xung đột debug session, sửa lỗi không lưu tiến trình khi thắng. |
| **Tài nguyên Mỹ thuật & Nhạc nền (Track D)** | ⚠️ **Tồn đọng** | Thiếu BGM, phông chữ tiếng Việt chính thức, Logo và bộ Sprite kẹo. |
| **Kiểm thử Trải nghiệm Thiết bị (Track E)** | ⚠️ **Tồn đọng** | Chưa chạy QA cử chỉ cảm ứng, Safe Area và playtest người dùng thật. |
| **Đóng gói Phát hành (Track F)** | ⚠️ **Tồn đọng** | Cần cấu hình Keystore Android, mã hóa Bank khi build APK. |

---

## 2. Chi tiết các Hạng mục Đã Hoàn thành

1. **Rebuild Kiến trúc & Cốt lõi Gameplay**:
   - Chuẩn hóa 5 trạng thái ô (`BLANK, MARK, CANDY, ERROR, GIVEN`).
   - Bỏ tự động khóa ô (auto-lock); giữ `ERROR` vĩnh viễn không tẩy xóa.
   - Hỗ trợ vuốt kéo (swipe drag) tô/xóa X qua nhiều ô.
   - Sửa triệt để lỗi chớp nháy X khi chạm đúp (RST-016).
   - Giữ nút Undo X có toggle cấu hình trong Cài đặt (RST-017).
   - Đầy đủ luồng màn hình: `TitleScreen` $\leftrightarrow$ `PuzzleScreen` $\leftrightarrow$ `WinScreen` / `FailScreen` $\leftrightarrow$ `OptionsScreen`.

2. **Dữ liệu & Thuật toán sinh màn**:
   - Sinh bộ dữ liệu 998 level gốc có nghiệm duy nhất và pace gợi ý đi kèm.
   - Hỗ trợ hai chế độ playlist: `demo_30.json` (30 màn cross-size) và `full_998.json`.
   - Thuật toán giải đố nâng cao S4–S7 (Subset Pairs, Triples, Quads, Contradiction chains).
   - Hệ thống điều chỉnh độ khó động DDA (`PaceAdjuster`) theo chuỗi thắng/thua.

3. **Âm thanh tự sinh (Procedural SFX Engine)**:
   - Viết mới `pcm_synth.gd` sinh sóng âm thanh 16-bit PCM (Sine, Square, Triangle, Sawtooth, ADSR envelope, filter).
   - 9 effect SFX định nghĩa sẵn trong code, không cần file `.ogg` ngoài.
   - Pool 8 voice đa âm (polyphony), biến thiên cao độ (pitch variation), giới hạn tần suất đánh X.
   - Bộ công cụ trực quan `sfx_tuner.tscn` (nhấn `F6` để thử nghiệm và sao chép cấu hình).

4. **Sửa lỗi Chế độ chơi bình thường & Lưu tiến trình**:
   - Cách ly hoàn toàn dữ liệu session khi chọn màn ở Debug Picker, không ghi đè vào file save chiến dịch.
   - Sửa lỗi bàn cờ rỗng khi `resume_level()` trả về null (bổ sung fallback sang `start_level()`).
   - Sửa hàm `advance_level()` trong `progress_manager.gd`: Cho phép chơi lại màn đã qua vẫn lưu điểm và tiến màn bình thường.
   - Bổ sung cơ chế tự động khôi phục (`auto-recovery` khi `boot()`): Tự động phát hiện và đưa người chơi về màn đầu tiên chưa hoàn thành (Level 22) nếu file lưu bị lệch do debug.

---

## 3. Danh mục các Hạng mục Còn Tồn đọng (Backlog)

### 📌 Track D: Hoàn thiện Tài nguyên (Asset Production)

> *Hiện tại game đang chạy bằng SFX tự sinh và tài nguyên tạm (placeholder).*

- [ ] **D1. Nhạc nền chính — BGM `bgm/main_theme.ogg` (Độ ưu tiên: P0)**:
  - Cần 1 bài nhạc nền loop 60–90 giây, phong cách nhẹ nhàng, thư giãn (cozy puzzle), định dạng OGG Vorbis 48kHz stereo, âm lượng chuẩn hóa khoảng -14 LUFS.
  - Hiện tại code đang kiểm tra nếu không có file sẽ chạy ở chế độ im lặng.
- [ ] **D2. Phông chữ Tiếng Việt chính thức (Độ ưu tiên: P0)**:
  - **Font chính giao diện**: Cần chọn và nhập font chuẩn (Inter, Nunito, hoặc Be Vietnam Pro) hỗ trợ tiếng Việt có dấu đầy đủ, tối ưu hiển thị trên màn hình di động (thay thế font mặc định của Godot).
  - **Font số HUD**: Cần font số cố định độ rộng (Monospace / Tabular figures) cho đồng hồ đếm giờ và bộ đếm để không bị giật bố cục khi số nhảy.
- [ ] **D3. Mỹ thuật 2D & Nhận diện (Độ ưu tiên: P0 / P1)**:
  - **Logo CanDoKu (P0)**: Thiết kế logo chính thức thay thế file vector tạm `candy.svg`.
  - **Bộ Sprite Kẹo (4–6 loại kẹo) (P0)**: Vẽ bộ sprite kẹo kích thước 128×128 pixel bắt mắt, có nhận diện hình học rõ ràng để hỗ trợ người dùng bật chế độ Hỗ trợ mù màu (Colorblind mode).
  - **App Icon (P1)**: Kích thước 1024×1024 PNG phục vụ đóng gói Android/iOS.
  - **Splash Screen (P1)**: Màn hình chờ khởi động game (1080×1920 hoặc vector co giãn).
  - **Banner Thắng / Thua (P1)**: Đồ họa trang trí cho màn hình kết quả (Win/Fail Screen) kèm hiệu ứng sao (Stars).

---

### 📌 Track E: Kiểm thử Thực tế & Trải nghiệm (QA & Playtest)

> *Toàn bộ 38 test suites hiện tại mới chỉ kiểm tra logic không đầu (Headless), chưa kiểm thử trên thiết bị phần cứng thật.*

- [ ] **E1. QA Cử chỉ cảm ứng trên thiết bị thật (Android / iOS)**:
  - Thử nghiệm độ nhạy của thao tác: Chạm đơn (đánh dấu X), chạm đôi (đặt kẹo) và vuốt kéo nhiều ô (swipe) trên màn hình cảm ứng di động.
  - Đảm bảo thời gian giữ và khoảng cách kéo không gây nhận diện nhầm giữa tap và swipe.
- [ ] **E2. QA Bố cục đa màn hình & Vùng an toàn (Safe Area)**:
  - Kiểm thử responsive layout trên các tỉ lệ màn hình phổ biến: 19.5:9, 20:9 (các dòng máy Android hiện đại), 16:9, và màn hình máy tính bảng (4:3, 16:10).
  - Kiểm tra viền màn hình tránh bị che bởi tai thỏ (Notch), Dynamic Island hoặc thanh điều hướng hệ thống (Navigation Bar).
- [ ] **E3. QA Thẩm âm (Audio Listening QA)**:
  - Nghe thử 9 âm thanh tự sinh (Procedural SFX) trên loa ngoài điện thoại tầm trung và tai nghe (Bluetooth/dây) để cân chỉnh âm lượng, độ đanh và đảm bảo không có tiếng lộp bộp (click/pop).
- [ ] **E4. Playtest Mù & Đánh giá Độ khó (DDA Observation)**:
  - Cho người chơi trải nghiệm chuỗi 30 level đầu tiên để đánh giá: Độ dễ hiểu của luật, điểm nghẽn khó chịu, độ hữu dụng của Hint và cảm giác thỏa mãn khi giải đố.
  - Theo dõi thuật toán DDA tự động bù rank (`rank_offset`) có hoạt động tự nhiên hay không.

---

### 📌 Track F: Đóng gói & Phát hành (Release Preparation)

- [ ] **F1. Mã hóa dữ liệu Bank trước khi Export**:
  - Chạy kịch bản `python -B tools/encode_banks.py --input game/data/banks --output <export_dir>` để biến đổi XOR dữ liệu màn chơi, bảo vệ puzzle không bị đọc trộm đáp án từ file APK.
- [ ] **F2. Cấu hình Dự án & Keystore Android**:
  - Thiết lập Android Export Template trong Godot: Package name (`com.alpacasolution.candoku`), Keystore ký số (Release keystore), icon ứng dụng và quyền hạn tối thiểu.
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
└── Thu thập/Soạn BGM `main_theme.ogg`
└── Nhập Font Tiếng Việt chính thức (Inter / Be Vietnam Pro)
└── Thiết kế Logo và bộ Sprite Kẹo phân biệt màu sắc

Giai đoạn 2 (Ưu tiên trung bình - P1):
└── Cài đặt bản build lên thiết bị Android thật
└── QA cử chỉ cảm ứng (Tap, Double-tap, Swipe) & Vùng an toàn Safe Area
└── Playtest 30 màn đầu tiên và thẩm âm loa ngoài

Giai đoạn 3 (Ưu tiên hoàn thiện - P2):
└── Thiết kế App Icon 1024×1024 và Splash Screen
└── Chạy kịch bản mã hóa Bank bằng XOR
└── Đóng gói file APK/AAB hoàn chỉnh
```
