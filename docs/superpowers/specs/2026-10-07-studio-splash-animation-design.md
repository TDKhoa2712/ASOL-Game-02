# Studio Splash Animation — Alpaca Solutions Logo

**Date:** 2026-10-07
**Status:** Design approved, pending implementation
**Asset location:** `rive-assets/logo-studio/`
**Output:** `.riv` file for Godot integration

---

## 1. Overview

A 3-second "Origami Unfold" splash screen animation for the Alpaca Solutions studio logo. Eight geometric triangles unfold sequentially into the logo mark, followed by a glow pulse across the yellow pieces and a text reveal. The animation conveys premium quality with an elegant, restrained aesthetic.

**Target feel:** Elegant reveal — smooth, deliberate, premium indie studio quality.
**Duration:** ~3.0 seconds (90 frames at 30fps).
**Approach:** Pure RML keyframe animations — no Luau scripting required. Lightweight `.riv` output.

---

## 2. Source Logo Analysis

The logo is an SVG with 8 polygon triangles forming an abstract geometric alpaca shape. Three colors:

| Color | Hex | Role |
|---|---|---|
| Dark purple | `#3B2779` | Structural pieces (wing, left body) |
| Mid purple | `#523D94` | Connective pieces (small center, right body, bottom) |
| Yellow/gold | `#FEB801` | Accent pieces (top, sliver, big center) |

### Polygon vertices (from SVG source)

| ID | Points | Color |
|---|---|---|
| `dark-wing` | 570,25 → 769,140 → 766,362 | `#3B2779` |
| `dark-left` | 681,221 → 577,433 → 484,487 → 341,403 | `#3B2779` |
| `yellow-top` | 681,221 → 410,287 → 341,403 | `#FEB801` |
| `yellow-sliver` | 681,221 → 766,362 → 670,526 | `#FEB801` |
| `mid-small` | 681,221 → 670,526 → 577,433 | `#523D94` |
| `mid-right` | 766,362 → 936,661 → 670,526 | `#523D94` |
| `yellow-big` | 670,526 → 936,661 → 503,817 | `#FEB801` |
| `mid-bottom` | 936,661 → 503,817 → 612,1226 | `#523D94` |

The SVG viewBox is 1254×1254. The logo's bounding box spans approximately x:341–936, y:25–1226. Center of mass is roughly (640, 550).

---

## 3. Canvas & Layout

### Artboard
- **Reference size:** 1920×1080 (landscape)
- **Background color:** `#0D0B1A` — deep navy-black with purple undertone

### Responsive layout
The artboard uses Rive's `LayoutComponentStyle` with flex layout:
- A root flex container centers content both horizontally and vertically
- Content group is a vertical flex column containing:
  1. Logo mark group (the 8 triangles)
  2. Spacer (~60px at reference size)
  3. Text element "ALPACA SOLUTIONS"
- The content group scales proportionally to the shorter viewport dimension, ensuring it never clips on any aspect ratio (portrait phones to ultrawide monitors)

### Logo scaling
- The original SVG is 1254×1254. Within the artboard, the logo group is scaled so it occupies approximately 280×320px of visual space at the 1920×1080 reference size (roughly 30% of viewport height).
- All polygon coordinates are translated so the logo's visual center sits at the group's origin.

### Text
- Font: Clean sans-serif (bundled as a font asset — specific font TBD based on available assets or a freely-licensed option like Inter or Montserrat)
- Size: ~28px at reference scale
- Color: `#F0EDF5` (warm white)
- Letter-spacing: slightly tracked out (final tracking ~0.12em)

---

## 4. Animation Design

### Timeline: 90 frames at 30fps = 3.0 seconds

### Phase 1 — Anticipation (frames 0–9, 0.0–0.3s)

**Purpose:** Build subtle tension before the reveal.

- All 8 triangle shapes start with:
  - `opacity = 0`
  - `scaleY = 0` (collapsed to a thin line along their fold edge)
  - `rotation` aligned so the collapsed edge matches a natural fold line for that piece
- A soft **ambient glow** element (large ellipse, radial gradient from `#3B2779` at 15% opacity → transparent) fades in at the center over 0.3s
- The glow gives the dark screen a warm, anticipatory presence

### Phase 2 — Unfold Cascade (frames 9–54, 0.3–1.8s)

**Purpose:** The main event — triangles unfold one by one into the logo.

Each triangle's unfold animation lasts **~8 frames (0.25s)** with **3 frames (0.1s) overlap** between consecutive starts, creating a flowing cascade.

**Unfold order** (top-down, following visual construction logic):

| Step | Shape | Start frame | End frame | Rationale |
|---|---|---|---|---|
| 1 | DarkWing | 9 | 17 | Top piece appears first — anchors the eye |
| 2 | YellowTop | 12 | 20 | Left accent follows wing |
| 3 | YellowSliver | 15 | 23 | Right connector bridges wing to body |
| 4 | DarkLeft | 18 | 26 | Left body fills in |
| 5 | MidSmall | 21 | 29 | Center connector ties top to bottom |
| 6 | MidRight | 24 | 32 | Right body extends |
| 7 | YellowBig | 30 | 40 | Hero piece — slightly longer (10 frames) and 6-frame gap before it for dramatic pause |
| 8 | MidBottom | 38 | 48 | Bottom tail completes the form |

**Per-triangle animation properties:**

1. **scaleY:** 0 → 1 with cubic-bezier(0.34, 1.56, 0.64, 1) — slight overshoot then settle, like paper snapping into a fold
2. **opacity:** 0 → 1, linear, over the first 4 frames of each unfold
3. **rotation:** Each piece has a unique starting rotation offset (~15–30°) toward its fold edge. Animates to final rotation (0°) with the same overshoot easing.

**The YellowBig piece (step 7)** gets special treatment as the visual hero:
- 10 frames instead of 8 (slightly slower unfold)
- A 6-frame gap before it starts (after MidRight ends at frame 32, YellowBig starts at frame 30 — slight overlap but the gap from MidRight's visual start creates breathing room)
- Slightly more pronounced overshoot

**Settle buffer:** Frames 48–54 (0.2s) — all pieces are in final position, subtle micro-settling (±0.5° rotation damping) on the last 2–3 pieces to feel organic.

### Phase 3 — Glow Pulse (frames 54–72, 1.8–2.4s)

**Purpose:** A moment of "completion" — the logo comes alive.

- Three **glow overlay shapes** (white-filled duplicates of the three yellow triangles) animate their opacity:
  - 0 → 0.25 → 0 over 8 frames each
  - Staggered by 4 frames: YellowTop overlay first, YellowSliver second, YellowBig third
  - Creates a diagonal light-sweep effect across the yellow pieces

- **Schedule:**
  - YellowTop glow: frames 54–62
  - YellowSliver glow: frames 58–66
  - YellowBig glow: frames 62–70

- The purple pieces get a simultaneous subtle brightness bump: their fill color animates to a slightly lighter variant and back:
  - Dark purple: `#3B2779` → `#4A3690` → `#3B2779` over frames 56–68
  - Mid purple: `#523D94` → `#6350A8` → `#523D94` over frames 56–68

- The ambient glow ellipse from Phase 1 fades out during this phase (opacity → 0 by frame 72).

### Phase 4 — Text Reveal (frames 66–90, 2.2–3.0s)

**Purpose:** Studio name appears and the composition settles.

- **Opacity:** 0 → 1 over frames 66–78 (0.4s), ease-out cubic
- **translateY:** +15px → 0 over frames 66–82 (0.5s), ease-out cubic — text slides gently upward into its final position
- **Letter-spacing:** Animates from 0.18em → 0.12em over frames 66–82 — text "settles" from slightly wider to final tracking

### Hold State

After frame 90, the animation holds at its final composed state indefinitely. The game controls when to transition away.

---

## 5. Unfold Axis Reference

Each triangle needs a "fold edge" — the axis along which it appears to unfold. These are chosen to create a natural top-down paper-folding feel:

| Shape | Fold edge (the edge that stays fixed) | Unfold direction |
|---|---|---|
| DarkWing | Top edge (570,25 → 769,140) | Unfolds downward |
| YellowTop | Top-right edge (681,221 → 410,287) | Unfolds down-left |
| YellowSliver | Top-left edge (681,221 → 766,362) | Unfolds downward |
| DarkLeft | Top edge (681,221 → 341,403) | Unfolds downward |
| MidSmall | Top edge (681,221 → 670,526) | Unfolds left |
| MidRight | Top-left edge (766,362 → 670,526) | Unfolds down-right |
| YellowBig | Top edge (670,526 → 936,661) | Unfolds downward |
| MidBottom | Top edge (936,661 → 503,817) | Unfolds downward |

The fold edge determines the `transformOrigin` for each shape's scaleY animation. The shape's pivot point is set at the midpoint of its fold edge.

---

## 6. Technical Implementation — Rive CLI

### Project structure

```
rive-assets/logo-studio/
  rive.yaml          # name: alpaca-logo, main artboard reference
  scene.rml          # complete scene: artboard, shapes, animations, state machine
  fonts/             # font asset (Inter or Montserrat .ttf)
```

### RML architecture

```xml
<Rive version="1" kind="fragment">
  <Artboard defaultStateMachineId="SM" styleId="RootStyle"
            width="1920" height="1080" name="SplashScreen" id="0:2">

    <!-- Flex layout for responsive centering -->
    <LayoutComponentStyle flexDirection="column"
                          alignItems="center" justifyContent="center"
                          name="RootStyle" id="0:5"/>

    <!-- Background fill -->
    <Fill><SolidColor colorValue="FF0D0B1A"/></Fill>

    <!-- Ambient glow (behind logo) -->
    <Shape name="AmbientGlow" id="0:10">...</Shape>

    <!-- 8 logo triangles (each a Shape with custom Path vertices) -->
    <Shape name="DarkWing" id="0:20">...</Shape>
    <Shape name="YellowTop" id="0:21">...</Shape>
    <!-- ... etc -->

    <!-- 3 glow overlays (white fills matching yellow triangle paths) -->
    <Shape name="GlowYellowTop" id="0:30">...</Shape>
    <!-- ... etc -->

    <!-- Text -->
    <Text name="StudioName" id="0:40">ALPACA SOLUTIONS</Text>

    <!-- State Machine (auto-play) -->
    <StateMachine name="SM" id="0:50">
      <StateMachineLayer name="Main" id="0:51">
        <EntryState>
          <StateTransition stateToId="0:53"/>
        </EntryState>
        <AnyState/><ExitState/>
        <AnimationState animationId="0:60" id="0:53"/>
      </StateMachineLayer>
    </StateMachine>

    <!-- Single LinearAnimation containing all keyframes -->
    <LinearAnimation duration="90" fps="30" name="Unfold" id="0:60">
      <!-- KeyedObject for each animated element -->
    </LinearAnimation>

  </Artboard>
</Rive>
```

### Keyframe property mapping

For each triangle, the animation keys these properties:

| Property | Rive property key | Notes |
|---|---|---|
| opacity | `opacity` | 0 → 1 |
| scaleY | `scaleY` | 0 → 1 with overshoot easing |
| rotation | `rotation` | offset → 0 with overshoot easing |

For glow overlays:
| Property | Notes |
|---|---|
| opacity | 0 → 0.25 → 0 |

For text:
| Property | Notes |
|---|---|
| opacity | 0 → 1 |
| y offset | +15 → 0 |

For purple color animation during glow phase:
| Property | Notes |
|---|---|
| `colorValue` on SolidColor | Animate to lighter variant and back |

### Easing

Rive RML supports `interpolationType` on keyframes:
- **Overshoot unfold:** Use `cubic` interpolation with appropriate control points. If custom cubic-bezier isn't available in RML keyframes, approximate with `hold` → `cubic` two-keyframe sequences.
- **Text fade:** Use `cubic` with ease-out curve.
- **Glow pulse:** Use `cubic` symmetric (ease-in-out).

### Build & verify

```bash
cd rive-assets/logo-studio
rive . --once                    # build .riv
rive . --screenshot --advance=90 # capture final frame
rive .                           # preview (interactive window)
```

---

## 7. Integration with Godot (post-review)

After the `.riv` is reviewed and approved:

1. Copy the built `.riv` to `game/assets/animation/` (or appropriate asset path)
2. Create a `SplashScreen` scene in Godot that:
   - Loads and plays the Rive animation
   - Waits for the animation to complete (~3s)
   - Optionally layers SFX (a subtle whoosh or chime) from Godot's audio system
   - Transitions to the title/home screen with a fade

This integration is a separate task — this spec covers only the Rive asset creation.

---

## 8. Acceptance Criteria

1. `rive . --once` builds without errors
2. `rive . --screenshot --advance=90` produces a PNG showing the complete logo with text
3. `rive .` preview shows smooth 30fps animation matching the phase timing described above
4. All 8 triangles match the original SVG polygon positions and colors exactly
5. The animation holds at its final state after frame 90
6. The `.riv` file is under 100KB (no scripts, no heavy assets beyond one font)
7. The layout centers correctly at 1920×1080 and scales proportionally at other aspect ratios

---

## 9. Open Questions

- **Font choice:** Inter, Montserrat, or another freely-licensed sans-serif? Decision deferred to implementation — agent should propose 2–3 options with screenshots.
- **Sound design:** Handled separately in Godot. No audio in the `.riv`.
- **Custom path vertices in RML:** Need to verify that Rive CLI RML supports custom polygon paths (not just parametric shapes). If not, may need to use a Luau `Node<T>` protocol to draw the polygons. This is a spike to resolve at implementation start.
