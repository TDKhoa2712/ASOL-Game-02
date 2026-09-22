# M0-A01 — Godot toolchain and device baseline

**Updated:** 2026-09-22 (Asia/Saigon)  
**Package state:** BLOCKED pending iOS host/signing and assigned physical devices; do not hand off as achieved

## Locked project baseline

| Item | Baseline |
| --- | --- |
| Engine | Godot `4.7.2.stable.official.ed1daf0bf`; project feature set `4.7` |
| Language/runtime | GDScript, Godot 2D runtime only |
| Renderer | `mobile` for desktop and mobile overrides |
| Logical viewport | 1080×1920 portrait |
| Stretch | `canvas_items`, aspect `expand` |
| Texture import | ETC2/ASTC enabled for Android export |
| Export templates | Official Godot `4.7.2.stable`, verified against the official SHA-512 manifest |
| Android preset | `Android M0 Debug`, ARM64, package `org.asol.game02`, min SDK 24, target SDK 36 |
| iOS preset | `iOS M0 Debug`, bundle `org.asol.game02`; Team ID intentionally unset until the signing owner supplies it |
| Network/services | No addons, account SDK, analytics SDK, ad SDK, remote asset URL, or runtime network dependency |

The project contains only a local bootstrap scene and local scripts. This is an offline bootstrap/build claim, not a completed QA-26 gameplay run: early levels do not exist in M0-A01.

## Host toolchain observed

| Item | Observation |
| --- | --- |
| Host | Windows x64, `10.0.26200` |
| Godot editor | Installed and executable at version `4.7.2.stable` |
| Export templates | Installed at `%APPDATA%\Godot\export_templates\4.7.2.stable` |
| Template integrity | SHA-512 `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079`, matching official `SHA512-SUMS.txt` |
| Android SDK | `D:\Develop\Android\Sdk`; compile/target SDK 36 and build-tools 36.0.0 used by export |
| Java | Oracle JDK `21.0.10`, configured in Godot editor settings; Godot 4.7 recommends JDK 17 but supports newer versions |
| Android target device | **UNASSIGNED**; `adb devices -l` returned no device |
| Android emulator | Emulator executable exists, but no AVD is configured |
| macOS/Xcode host | **UNAVAILABLE** on this Windows host |
| iPhone target device | **UNASSIGNED** |

## Required device matrix and budgets

No Technical Lead/QA decision currently assigns concrete low-end devices, OS versions, or memory budgets. DQ-003 and DQ-005 remain open, so the following are explicit blockers rather than invented values.

| Target | Device | OS | Load budget | Runtime budget | Status |
| --- | --- | --- | --- | --- | --- |
| Android low-end | UNASSIGNED | UNASSIGNED | TECH-13: first level <2 s after startup | TECH-19: ≥55 FPS, no frame stall >100 ms; RAM/VRAM budget UNASSIGNED | BLOCKED |
| iPhone low-end | UNASSIGNED | UNASSIGNED | TECH-13: first level <2 s after startup | TECH-19: ≥55 FPS, no frame stall >100 ms; RAM/VRAM budget UNASSIGNED | BLOCKED |

The bootstrap has no production sprite atlas, jump animation, sticker, or playable level. Therefore it cannot produce valid TECH-13/19 device measurements; those measurements must not be inferred from desktop headless timings.

## Verification completed on this host

| Check | Result |
| --- | --- |
| Level fixture validator | PASS — 5 fixtures validated, 0 duplicate geometry warnings |
| Godot headless editor import | PASS with Godot 4.7.2 |
| Python/Godot baseline tests | PASS — engine pin, portrait/mobile renderer, ETC2/ASTC, export presets, and runtime bootstrap |
| Runtime bootstrap | PASS — emitted `M0_A01_BOOTSTRAP_READY` and exited cleanly |
| Android debug export | PASS — signed ARM64 APK created; see `android-export-smoke.txt` |
| Android APK identity | PASS — `org.asol.game02`, version code 1, version name `0.0.0-m0`, min SDK 24, target SDK 36 |
| Android APK signature | PASS — APK Signature Scheme v2 and v3 verified; debug certificate only, not a release identity |
| Android offline manifest | PASS for bootstrap — `aapt2 dump permissions` listed the package and no permissions, including no `android.permission.INTERNET` |
| Android install/run | BLOCKED — no physical device or configured AVD |
| iOS export/build smoke | BLOCKED — matching template is installed, but Team ID is intentionally absent and the required macOS/Xcode/signing environment is unavailable; see `ios-export-smoke.txt` |
| TECH-13/19 measurements | BLOCKED — no assigned Android/iPhone devices and no representative gameplay/atlas workload |

Godot emitted a non-fatal warning that no project icon is specified. Production branding/content is out of scope for M0-A01; the debug APK uses the template fallback and must not be treated as a release artifact.

## Unblock requirements

1. Technical Lead + QA Lead assign one low-end Android and one low-end iPhone, exact OS versions, and RAM/VRAM/load budgets.
2. Install and run the debug APK on the assigned Android device; record cold startup and offline launch.
3. Provide a macOS/Xcode host, Apple Team/signing configuration, export/build the iOS preset, and record startup/offline smoke on the assigned iPhone.
4. When the representative level and sprite workload exists, capture FPS, frame stalls, RAM, VRAM, and load time on both devices against TECH-13/19.

Until all items above have evidence, `M0-A01` must remain blocked and must not enter review.

## Authoritative toolchain references

- Godot 4.7 Android export setup: <https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html>
- Godot 4.7 iOS export requirements: <https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html>

