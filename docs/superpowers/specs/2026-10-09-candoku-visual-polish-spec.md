# Candoku Visual Polish — Spec

## Mục tiêu

Nâng cấp visual polish cho các màn hình Win, Lose, Title dựa trên candoku prototype (`candoku/`). Game hiện tại đã port hầu hết layout và components — spec này cover các **gaps cụ thể** về animation quality, particle effects, và visual details còn thiếu.

## Nguồn tham khảo

- `candoku/scripts/win.gd` — win screen animations
- `candoku/scripts/lose.gd` — lose screen animations (hearts split, rain)
- `candoku/scripts/home.gd` — home screen entrance animations
- `candoku/scripts/ui_kit.gd` — 3D button style, animation helpers
- `candoku/scripts/candy_character.gd` — character reference (đã port)

## Constraints

- Module ≤ 300 dòng, một file một trách nhiệm
- Không autoloads — composition root pattern
- Signals thay EventBus
- Giữ nguyên signal contracts: `next_pressed`, `retry_pressed`, `home_pressed`, `replay_pressed`, `play_pressed`, `endless_pressed`, `options_pressed`, `debug_level_selected`
- Giữ nguyên `setup()` signatures tương thích với `app_shell.gd`
- Tất cả animations phải respect `LayoutTokens.motion_enabled`
- Font: BeVietnamPro/Nunito (không Baloo 2)
- Target: 390×844 logical, responsive via anchors

## Gap 1: Lose Screen — Hearts Split Animation

**Hiện tại:** `heart_display.gd` dùng `heart_broken.svg` tĩnh cho lose screen.

**Candoku reference:** `candoku/scripts/lose.gd:940-954` — mỗi heart có 2 nửa (L/R), animation:
- Nửa trái xoay -12° và trượt sang trái 5px, rơi xuống 48px, fade out
- Nửa phải xoay +12° và trượt sang phải 5px, rơi xuống 48px, fade out
- Pivot ở đáy heart (bottom center)
- Stagger 0.25s giữa các heart

**Cần:** Thêm method `animate_break()` vào `heart_display.gd` hoặc tạo assets `heart_half_l.svg` + `heart_half_r.svg`, animate tách đôi giống candoku.

## Gap 2: Lose Screen — Rain Particles

**Hiện tại:** `fail_screen.gd` dùng `cloud_rain.svg` tĩnh, không có hiệu ứng mưa.

**Candoku reference:** `candoku/scripts/lose.gd:847-862` — CPUParticles2D:
- 14 hạt, lifetime 0.9s
- Texture: raindrop SVG
- Emission shape: rectangle (42×2 px extent), centered dưới mây
- Direction: (0,1), spread 0, gravity (0,0)
- Velocity: 220-260
- Color ramp: fade in nhanh (0→0.2), giữ (0.2→0.6), fade out (0.6→1.0)

**Cần:** Thêm CPUParticles2D rain vào lose screen, sử dụng hoặc tạo `raindrop.svg`.

## Gap 3: Win Screen — Ribbon Drop + Tilt Animation

**Hiện tại:** `ribbon_banner.gd:animate()` — scale from 0.7 + fade in. Không có drop from top hay tilt.

**Candoku reference:** `candoku/scripts/win.gd:2094-2100`:
- Ribbon bắt đầu ở vị trí cao hơn 140px, alpha 0
- Drop xuống vị trí ban đầu với TRANS_BACK easing (0.7s)
- Fade in 0.15s

`candoku/scripts/lose.gd:933-939` — tương tự nhưng thêm:
- Sau khi drop, ribbon nghiêng -3° (0.4s, TRANS_SINE) — tạo cảm giác rũ buồn

**Cần:** Cập nhật `ribbon_banner.gd:animate()` thành drop-from-top, thêm optional tilt cho lose.

## Gap 4: Confetti — CPUParticles2D Upgrade

**Hiện tại:** `confetti_layer.gd` dùng ColorRect rectangles + tween-based animation. Hoạt động nhưng visual kém hơn particle system.

**Candoku reference:** `candoku/scripts/win.gd:1892-1917` — CPUParticles2D:
- 70 hạt, lifetime 5s, preprocess 1s
- Texture: square.svg
- Emission: rectangle (200×10 extent), centered trên đầu
- Direction: (0,1), spread 25°, gravity (0,160)
- Velocity: 120-260, angular velocity: ±420
- Scale: 1.2-2.6
- Color: 6 màu constant interpolation (sharp, không blend)

**Cần:** Refactor `confetti_layer.gd` sang CPUParticles2D để visual giống candoku hơn. Giữ fallback method cho headless testing.

## Gap 5: Action Buttons — 3D Depth Edge

**Hiện tại:** `action_button.gd` dùng `shadow_offset` + `shadow_size` cho hiệu ứng 3D.

**Candoku reference:** `candoku/scripts/ui_kit.gd:1648-1674` — `style_button_3d()`:
- Dùng `border_width_bottom` để tạo cạnh dưới dày (depth)
- Pressed state: `border_width_bottom = 1`, `expand_margin_top = -(depth-1)`, content_margin_top tăng — button thật sự "lún xuống"
- Hover: bg lightened 6%

**Cần:** Cập nhật `action_button.gd` dùng border_width_bottom thay vì shadow cho hiệu ứng 3D chính xác hơn.

## Gap 6: Title Screen — Entrance Animation Sequence

**Hiện tại:** Title screen có logo SVG tĩnh, mascot wink, progress bar animate, nhưng không có entrance sequence phối hợp.

**Candoku reference:** `candoku/scripts/home.gd:727-771`:
1. Logo rơi + bounce (scale 0.6→1.0, TRANS_BACK, 0.8s)
2. Sau đó logo bob nhẹ (8px amplitude, 3.2s period)
3. Bubble bật ra sau 1.2s (scale 0→1, TRANS_BACK, 0.5s)
4. Candy drop_in sau 0.4s
5. Progress card rise_in sau 0.8s
6. Play button rise_in sau 1.0s, pulse sau 1.9s
7. Floating candy balls bob liên tục

**Cần:** Thêm phối hợp entrance animation vào title_screen.gd, timing stagger giống candoku.

## Gap 7: Tween Helpers — Shared Animation Utilities

**Hiện tại:** Các animation helpers (rise_in, pulse, bob) được implement inline trong từng screen hoặc trong `action_button.gd:add_pulse()`.

**Candoku reference:** `candoku/scripts/ui_kit.gd:1846-1876` — centralized helpers:
- `rise_in(node, delay, dist)` — fade in + slide up
- `pulse(node, delay)` — scale 1.0→1.03→1.0 loop
- `bob(node, amount, period, rot_deg)` — float up/down + optional rotation

**Cần:** Tạo `tween_helpers.gd` để DRY các animation patterns dùng chung giữa screens. Tất cả phải respect `LayoutTokens.motion_enabled`.

## Ngoài phạm vi

- Gameplay logic, board solver, core game
- Font thay đổi (giữ BeVietnamPro/Nunito)
- Logo redesign (giữ SVG hiện tại)
- Puzzle screen layout (đã hoàn thiện)
- CandyCharacter (đã port đầy đủ)
