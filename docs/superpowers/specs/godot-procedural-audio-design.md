#	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: AudioManager.play_jump()
			KEY_2: AudioManager.play_laser()
			KEY_3: AudioManager.play_explosion()
			KEY_4: AudioManager.play_coin()
			KEY_5: AudioManager.play_click()
			KEY_6: AudioManager.play_hurt()
			KEY_7: AudioManager.play_victory()
			KEY_8: AudioManager.play_game_over()
```
---
## 6. CẤU HÌNH PROJECT & TỰ ĐỘNG HÓA (GODOT CONFIGURATION)
Để `AudioManager` trở thành Singleton khả dụng toàn cục, cấu hình file `project.godot`:
Thêm khối sau vào file `project.godot`:
```ini
[autoload]
AudioManager="*res://scripts/audio/audio_manager.gd"
```
*(Hoặc mở **Project Settings $\to$ Globals $\to$ Autoload**, thêm `res://scripts/audio/audio_manager.gd` với tên `AudioManager`).*
---
## 7. HƯỚNG DẪN TÍCH HỢP VÀO GAMEPLAY
### 7.1. Trong Script Nhân Vật (`Player.gd`)
```gdscript
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -400.0
		AudioManager.play_jump() # Gọi âm thanh nhảy
```
### 7.2. Trong Script Nút Giao Diện UI (`Button.gd`)
```gdscript
func _on_pressed() -> void:
	AudioManager.play_click() # Gọi âm thanh click
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
```
### 7.3. Trong Script Kẻ Thù Hoặc Bẫy (`Trap.gd`)
```gdscript
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(20)
		AudioManager.play_hurt() # Gọi âm thanh dính sát thương
```
---
## 8. BẢNG TRA CỨU THAM SỐ ÂM THANH (DSP PRESET CHEATSHEET)
Bảng hướng dẫn pha chế các âm thanh mới vào `sound_library.gd`:
| Loại âm thanh | $f_{\text{start}}$ (Hz) | $f_{\text{end}}$ (Hz) | Thời lượng | Waveform | Noise Mix | Low Pass | Ứng dụng thực tế |
|---|---|---|---|---|---|---|---|
| **Súng tiểu liên** | 1300 | 350 | 0.07s | SAWTOOTH | 0.0 | Không | Tiếng súng retro tốc độ bắn cao |
| **Bước chân cỏ/đất** | 120 | 50 | 0.05s | TRIANGLE | 0.6 | 700 Hz | Bước chân nhân vật êm |
| **Bước chân đá/gạch** | 280 | 120 | 0.04s | SQUARE | 0.2 | 2200 Hz | Bước chân giòn |
| **Đỡ đòn / Khiên chắn** | 220 | 80 | 0.12s | TRIANGLE | 0.45 | 1400 Hz | Khiên va chạm vũ khí |
| **Uống thuốc hồi máu** | 200 | 900 | 0.35s | SINE | 0.0 | Không | Nhặt item hồi HP / Buff |
| **Còi báo động nguy hiểm** | 880 | 880 | 0.40s | SQUARE | 0.0 | Không | Còi hú đếm ngược |
| **Ném bùn / Splat** | 300 | 70 | 0.15s | TRIANGLE | 0.65 | 1200 Hz | Ném vật phẩm trúng đích |
---
## 9. CHẨN ĐOÁN LỖI & TỐI ƯU HÓA (TROUBLESHOOTING & OPTIMIZATION)
1. **Âm thanh bị méo tiếng / rè (Audio Clipping):**
   * *Nguyên nhân:* Tham số `volume` quá lớn hoặc biên độ sau khi cộng `noise_mix` vượt ngưỡng `1.0`.
   * *Khắc phục:* `PcmSynthesizer` đã có lệnh `clamp(final_val, -1.0, 1.0)`. Giữ `volume` trong các preset ở mức `0.25 - 0.45`.
2. **Tiếng click/pop khó chịu khi âm thanh bắt đầu hoặc kết thúc:**
   * *Nguyên nhân:* Tham số `attack` hoặc `release` bằng $0$, làm biên độ nhảy từ $0$ lên giá trị tức thời tạo sóng vuông vi mô.
   * *Khắc phục:* Luôn giữ `attack >= 0.005` và `release >= 0.01` giây để tạo độ dốc mượt.
3. **Bộ nhớ RAM sử dụng cho toàn bộ âm thanh:**
   * Mỗi giây âm thanh 16-bit Mono ở $22,050 \text{ Hz}$ chỉ tiêu tốn:
     $$\text{RAM} = 22,050 \times 2 \text{ bytes} \approx 44.1 \text{ KB / giây}$$
   * Một bộ sưu tập 20 hiệu ứng SFX (trung bình $0.15\text{s}$ mỗi âm thanh) chỉ tốn **dưới 150 KB RAM** trong suốt toàn bộ vòng đời game!
