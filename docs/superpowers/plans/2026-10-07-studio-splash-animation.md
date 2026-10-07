# Studio Splash Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an "Origami Unfold" splash screen animation for the Alpaca Solutions studio logo as a Rive CLI project, producing a `.riv` file for Godot integration.

**Architecture:** A single Rive CLI project at `rive-assets/logo-studio/` containing `rive.yaml` + `scene.rml` + a font file. The 8 SVG polygon triangles are converted to `PointsPath` shapes in RML with scaled coordinates. One 90-frame `LinearAnimation` at 30fps drives all keyframes. A single-layer `StateMachine` auto-plays the animation. No Luau scripting.

**Tech Stack:** Rive CLI 1.3.0, RML (XML scene format), Nunito-SemiBold font

**Spec:** `docs/superpowers/specs/2026-10-07-studio-splash-animation-design.md`

## Global Constraints

- All source files live under `rive-assets/logo-studio/`
- The `.riv` output goes to `rive-assets/logo-studio/build/` (Rive CLI default)
- Font: copy `game/assets/fonts/Nunito-SemiBold.ttf` into the project — do NOT reference `extracted_reusable/`
- Logo colors: dark purple `FF3B2779`, mid purple `FF523D94`, yellow `FFFEB801`
- Background: `FF0D0B1A`
- Text color: `FFF0EDF5`
- Artboard: 1920×1080, 30fps, 90-frame animation
- Build command: `rive rive-assets/logo-studio --once`
- Verify command: `rive rive-assets/logo-studio --screenshot --advance=90`
- Preview command: `rive rive-assets/logo-studio`

## Review Focus

1. **Vertex winding direction** — All polygons must have `isClosed="true"` and `isClockwise` matching the actual vertex order. Wrong winding with a fill = invisible shape. Verify each polygon is visible in screenshot.
2. **Keyframe interpolationType on the FIRST keyframe** — Rive applies easing from the start keyframe to the next. Putting `interpolationType="cubic"` on the last keyframe does nothing. Every animated segment must have easing on its start keyframe.
3. **Missing colorValue on SolidColor** — A `Fill` without a `SolidColor` child, or a `SolidColor` without `colorValue`, renders nothing. Every fill must have an explicit color.
4. **State machine not linked** — `defaultStateMachineId` on the `Artboard` must point at the `StateMachine` id, or the animation never plays and no data binds run.
5. **Font asset file path** — `FontAsset` `file` must match the actual filename on disk. A mismatch fails the build.

---

### Task 1: Scaffold the Rive project

**Files:**
- Create: `rive-assets/logo-studio/rive.yaml`
- Create: `rive-assets/logo-studio/.gitignore`
- Copy: `game/assets/fonts/Nunito-SemiBold.ttf` → `rive-assets/logo-studio/Nunito-SemiBold.ttf`

**Interfaces:**
- Consumes: nothing
- Produces: A valid Rive project directory that `rive . --once` can scan (even though it will fail without an `.rml` file)

- [ ] **Step 1: Create `rive.yaml`**

```yaml
name: alpaca-logo
```

Write this file to `rive-assets/logo-studio/rive.yaml`.

- [ ] **Step 2: Create `.gitignore`**

```
build/
```

Write this file to `rive-assets/logo-studio/.gitignore`.

- [ ] **Step 3: Copy font file**

```bash
cp game/assets/fonts/Nunito-SemiBold.ttf rive-assets/logo-studio/Nunito-SemiBold.ttf
```

- [ ] **Step 4: Verify project structure**

```bash
ls rive-assets/logo-studio/
```

Expected: `rive.yaml`, `.gitignore`, `Nunito-SemiBold.ttf`

- [ ] **Step 5: Commit**

```bash
git add rive-assets/logo-studio/rive.yaml rive-assets/logo-studio/.gitignore rive-assets/logo-studio/Nunito-SemiBold.ttf
git commit -m "chore(splash): scaffold Rive project for studio logo animation"
```

---

### Task 2: Build the static logo scene (all 8 triangles + background)

**Files:**
- Create: `rive-assets/logo-studio/scene.rml`

**Interfaces:**
- Consumes: `rive.yaml` from Task 1, `Nunito-SemiBold.ttf` font
- Produces: A buildable `.rml` that renders the complete static logo with text. `rive . --once` succeeds and `--screenshot` shows the logo.

The SVG logo (1254×1254 viewBox) is scaled to fit ~320px height in the 1080px artboard. All vertex coordinates are pre-computed relative to the logo group's origin (center of the logo's bounding box). The logo group is placed at artboard center (960, 440 — slightly above vertical midpoint for visual balance).

**Coordinate reference** (logo-local space, origin at bounding-box center):

| Shape | Vertices (x, y) | Color hex |
|---|---|---|
| DarkWing | (-18.3, -160.0), (34.8, -129.4), (34.0, -70.2) | FF3B2779 |
| YellowTop | (11.3, -107.8), (-60.9, -90.2), (-79.3, -59.3) | FFFEB801 |
| YellowSliver | (11.3, -107.8), (34.0, -70.2), (8.4, -26.5) | FFFEB801 |
| DarkLeft | (11.3, -107.8), (-16.4, -51.3), (-41.2, -36.9), (-79.3, -59.3) | FF3B2779 |
| MidSmall | (11.3, -107.8), (8.4, -26.5), (-16.4, -51.3) | FF523D94 |
| MidRight | (34.0, -70.2), (79.3, 9.5), (8.4, -26.5) | FF523D94 |
| YellowBig | (8.4, -26.5), (79.3, 9.5), (-36.1, 51.0) | FFFEB801 |
| MidBottom | (79.3, 9.5), (-36.1, 51.0), (-7.1, 160.0) | FF523D94 |

- [ ] **Step 1: Write the complete static scene.rml**

Write the following to `rive-assets/logo-studio/scene.rml`:

```xml
<Rive version="1" kind="fragment">
  <Artboard defaultStateMachineId="0:50" width="1920" height="1080" name="SplashScreen" id="0:2">

    <!-- Background -->
    <Fill name="BgFill">
      <SolidColor colorValue="FF0D0B1A" name="BgColor"/>
    </Fill>

    <!-- Ambient glow (soft purple ellipse behind logo) -->
    <Shape x="960" y="440" opacity="0" name="AmbientGlow" id="0:10">
      <Ellipse originX="0.5" originY="0.5" width="500" height="500" name="GlowPath"/>
      <Fill name="GlowFill">
        <SolidColor colorValue="143B2779" name="GlowColor"/>
      </Fill>
    </Shape>

    <!-- Logo group: Node at artboard visual center -->
    <Node x="960" y="440" name="LogoGroup" id="0:15">

      <!-- 1. DarkWing (top-right wing) -->
      <Shape name="DarkWing" id="0:20">
        <PointsPath isClosed="true" isClockwise="true" name="DarkWingPath">
          <StraightVertex x="-18.3" y="-160.0"/>
          <StraightVertex x="34.8" y="-129.4"/>
          <StraightVertex x="34.0" y="-70.2"/>
        </PointsPath>
        <Fill name="DarkWingFill">
          <SolidColor colorValue="FF3B2779" name="DarkWingColor"/>
        </Fill>
      </Shape>

      <!-- 2. YellowTop (left yellow accent) -->
      <Shape name="YellowTop" id="0:21">
        <PointsPath isClosed="true" isClockwise="false" name="YellowTopPath">
          <StraightVertex x="11.3" y="-107.8"/>
          <StraightVertex x="-60.9" y="-90.2"/>
          <StraightVertex x="-79.3" y="-59.3"/>
        </PointsPath>
        <Fill name="YellowTopFill">
          <SolidColor colorValue="FFFEB801" name="YellowTopColor"/>
        </Fill>
      </Shape>

      <!-- 3. YellowSliver (right yellow connector) -->
      <Shape name="YellowSliver" id="0:22">
        <PointsPath isClosed="true" isClockwise="true" name="YellowSliverPath">
          <StraightVertex x="11.3" y="-107.8"/>
          <StraightVertex x="34.0" y="-70.2"/>
          <StraightVertex x="8.4" y="-26.5"/>
        </PointsPath>
        <Fill name="YellowSliverFill">
          <SolidColor colorValue="FFFEB801" name="YellowSliverColor"/>
        </Fill>
      </Shape>

      <!-- 4. DarkLeft (left body, 4 vertices) -->
      <Shape name="DarkLeft" id="0:23">
        <PointsPath isClosed="true" isClockwise="false" name="DarkLeftPath">
          <StraightVertex x="11.3" y="-107.8"/>
          <StraightVertex x="-16.4" y="-51.3"/>
          <StraightVertex x="-41.2" y="-36.9"/>
          <StraightVertex x="-79.3" y="-59.3"/>
        </PointsPath>
        <Fill name="DarkLeftFill">
          <SolidColor colorValue="FF3B2779" name="DarkLeftColor"/>
        </Fill>
      </Shape>

      <!-- 5. MidSmall (center connector) -->
      <Shape name="MidSmall" id="0:24">
        <PointsPath isClosed="true" isClockwise="false" name="MidSmallPath">
          <StraightVertex x="11.3" y="-107.8"/>
          <StraightVertex x="8.4" y="-26.5"/>
          <StraightVertex x="-16.4" y="-51.3"/>
        </PointsPath>
        <Fill name="MidSmallFill">
          <SolidColor colorValue="FF523D94" name="MidSmallColor"/>
        </Fill>
      </Shape>

      <!-- 6. MidRight (right body) -->
      <Shape name="MidRight" id="0:25">
        <PointsPath isClosed="true" isClockwise="true" name="MidRightPath">
          <StraightVertex x="34.0" y="-70.2"/>
          <StraightVertex x="79.3" y="9.5"/>
          <StraightVertex x="8.4" y="-26.5"/>
        </PointsPath>
        <Fill name="MidRightFill">
          <SolidColor colorValue="FF523D94" name="MidRightColor"/>
        </Fill>
      </Shape>

      <!-- 7. YellowBig (large center, hero piece) -->
      <Shape name="YellowBig" id="0:26">
        <PointsPath isClosed="true" isClockwise="false" name="YellowBigPath">
          <StraightVertex x="8.4" y="-26.5"/>
          <StraightVertex x="79.3" y="9.5"/>
          <StraightVertex x="-36.1" y="51.0"/>
        </PointsPath>
        <Fill name="YellowBigFill">
          <SolidColor colorValue="FFFEB801" name="YellowBigColor"/>
        </Fill>
      </Shape>

      <!-- 8. MidBottom (bottom tail) -->
      <Shape name="MidBottom" id="0:27">
        <PointsPath isClosed="true" isClockwise="true" name="MidBottomPath">
          <StraightVertex x="79.3" y="9.5"/>
          <StraightVertex x="-36.1" y="51.0"/>
          <StraightVertex x="-7.1" y="160.0"/>
        </PointsPath>
        <Fill name="MidBottomFill">
          <SolidColor colorValue="FF523D94" name="MidBottomColor"/>
        </Fill>
      </Shape>

    </Node>

    <!-- Glow overlays (white fills matching yellow triangle positions, initially invisible) -->
    <Node x="960" y="440" name="GlowOverlays" id="0:28">
      <Shape opacity="0" name="GlowYellowTop" id="0:30">
        <PointsPath isClosed="true" isClockwise="false" name="GYTPath">
          <StraightVertex x="11.3" y="-107.8"/>
          <StraightVertex x="-60.9" y="-90.2"/>
          <StraightVertex x="-79.3" y="-59.3"/>
        </PointsPath>
        <Fill name="GYTFill">
          <SolidColor colorValue="FFFFFFFF" name="GYTColor"/>
        </Fill>
      </Shape>
      <Shape opacity="0" name="GlowYellowSliver" id="0:31">
        <PointsPath isClosed="true" isClockwise="true" name="GYSPath">
          <StraightVertex x="11.3" y="-107.8"/>
          <StraightVertex x="34.0" y="-70.2"/>
          <StraightVertex x="8.4" y="-26.5"/>
        </PointsPath>
        <Fill name="GYSFill">
          <SolidColor colorValue="FFFFFFFF" name="GYSColor"/>
        </Fill>
      </Shape>
      <Shape opacity="0" name="GlowYellowBig" id="0:32">
        <PointsPath isClosed="true" isClockwise="false" name="GYBPath">
          <StraightVertex x="8.4" y="-26.5"/>
          <StraightVertex x="79.3" y="9.5"/>
          <StraightVertex x="-36.1" y="51.0"/>
        </PointsPath>
        <Fill name="GYBFill">
          <SolidColor colorValue="FFFFFFFF" name="GYBColor"/>
        </Fill>
      </Shape>
    </Node>

    <!-- Studio name text -->
    <Text x="960" y="530" originX="0.5" originY="0" sizingValue="autoWidth"
          alignValue="center" opacity="0" name="StudioName" id="0:40">
      <TextStylePaint fontSize="28" fontAssetId="0:45" letterSpacing="18"
                      name="StudioStyle" id="0:41">
        <Fill name="TextFill">
          <SolidColor colorValue="FFF0EDF5" name="TextColor"/>
        </Fill>
      </TextStylePaint>
      <TextValueRun styleId="0:41" text="ALPACA SOLUTIONS" name="StudioRun"/>
    </Text>

    <!-- State machine (auto-play, single layer) -->
    <StateMachine name="MainSM" id="0:50">
      <StateMachineLayer name="MainLayer" id="0:51">
        <AnyState x="200" y="-120"/>
        <ExitState x="400" y="-120"/>
        <EntryState>
          <StateTransition stateToId="0:53"/>
        </EntryState>
        <AnimationState animationId="0:60" id="0:53"/>
      </StateMachineLayer>
    </StateMachine>

    <!-- Placeholder animation (empty, to be filled in Task 3) -->
    <LinearAnimation fps="30" duration="90" loopValue="oneShot" name="Unfold" id="0:60"/>

  </Artboard>

  <!-- Font asset (root element) -->
  <FontAsset file="Nunito-SemiBold.ttf" name="Nunito" id="0:45"/>
</Rive>
```

- [ ] **Step 2: Build and verify static scene**

```bash
rive rive-assets/logo-studio --once
```

Expected: Build succeeds, produces `build/alpaca-logo.riv`. Check the `inspect` output for any problems.

```bash
rive rive-assets/logo-studio --screenshot --advance=1
```

Expected: `build/alpaca-logo.png` shows the dark background with all 8 colored triangles forming the logo mark. If any triangle is invisible, check its `isClockwise` value — the vertex winding may be wrong. Flip `isClockwise` for any missing shape and rebuild.

- [ ] **Step 3: Verify shape colors and positions match the original SVG**

Open the screenshot and compare against the original SVG at `game/assets/ui/source/studio.svg`. All 8 pieces should be present, correctly colored, and positioned to form the same geometric shape. The text should not be visible (opacity=0 at frame 1).

- [ ] **Step 4: Fix winding issues if any**

If any triangle is invisible in the screenshot:
1. Identify which shape is missing
2. Toggle its `isClockwise` attribute (true↔false)
3. Rebuild with `rive rive-assets/logo-studio --once` and re-screenshot

Repeat until all 8 triangles are visible.

- [ ] **Step 5: Commit**

```bash
git add rive-assets/logo-studio/scene.rml
git commit -m "feat(splash): add static logo scene with 8 polygon shapes and text"
```

---

### Task 3: Add the unfold animation keyframes

**Files:**
- Modify: `rive-assets/logo-studio/scene.rml` — replace the empty `<LinearAnimation>` with full keyframes

**Interfaces:**
- Consumes: Shape ids from Task 2 (`0:10` AmbientGlow, `0:20`–`0:27` triangles, `0:30`–`0:32` glow overlays, `0:40` text, `0:41` text style)
- Produces: A complete animated `.riv` where `rive . --screenshot --advance=90` shows the final composed state, and `rive .` plays the full 3-second animation

**Animation property keys** (from `rive schema`):
- `opacity` = key 18
- `rotation` = key 15
- `scaleX` = key 16
- `scaleY` = key 17
- `x` = key 13
- `y` = key 14
- `colorValue` = key 37
- `letterSpacing` = key 390

**Easing curve for unfold overshoot:** `cubic` with `CubicEaseInterpolator x1="0.22" y1="1" x2="0.36" y2="1"` — this is a custom ease-out with overshoot (y values >1 create overshoot, then Rive clamps the bezier naturally).

Actually, looking at the Rive easing docs more carefully: the bezier controls are time→progress, not value offsets. To get overshoot, we need `y1` or `y2` values exceeding 1.0. The curve `x1="0.0" y1="0.7" x2="0.3" y2="1.5"` gives a fast start with overshoot past the target, then settling.

- [ ] **Step 1: Replace the empty LinearAnimation with full keyframes**

In `rive-assets/logo-studio/scene.rml`, replace the line:
```xml
    <LinearAnimation fps="30" duration="90" loopValue="oneShot" name="Unfold" id="0:60"/>
```

With the complete animation block below. This is the core of the splash screen.

```xml
    <LinearAnimation fps="30" duration="90" loopValue="oneShot" name="Unfold" id="0:60">

      <!-- ============================================ -->
      <!-- Phase 1: Ambient Glow fade in (frames 0-9)   -->
      <!-- ============================================ -->

      <!-- AmbientGlow opacity: 0 → 0.6 -->
      <KeyedObject objectId="0:10">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0.6" frame="9"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- ============================================ -->
      <!-- Phase 2: Triangle unfold cascade (frames 9-48) -->
      <!-- Each triangle: opacity 0→1, scaleY 0→1      -->
      <!-- ============================================ -->

      <!-- 1. DarkWing: frames 9-17 -->
      <KeyedObject objectId="0:20">
        <!-- opacity -->
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="9" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="13"/>
        </KeyedProperty>
        <!-- scaleY -->
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="9" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="17"/>
        </KeyedProperty>
        <!-- rotation (slight tilt → 0) -->
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="-0.25" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="-0.25" frame="9" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="17"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 2. YellowTop: frames 12-20 -->
      <KeyedObject objectId="0:21">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="12" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="16"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="12" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="20"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="0.3" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0.3" frame="12" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="20"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 3. YellowSliver: frames 15-23 -->
      <KeyedObject objectId="0:22">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="15" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="19"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="15" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="23"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="-0.2" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="-0.2" frame="15" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="23"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 4. DarkLeft: frames 18-26 -->
      <KeyedObject objectId="0:23">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="18" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="22"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="18" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="26"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="0.35" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0.35" frame="18" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="26"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 5. MidSmall: frames 21-29 -->
      <KeyedObject objectId="0:24">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="21" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="25"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="21" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="29"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="-0.2" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="-0.2" frame="21" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="29"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 6. MidRight: frames 24-32 -->
      <KeyedObject objectId="0:25">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="24" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="28"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="24" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="32"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="0.25" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0.25" frame="24" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="32"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 7. YellowBig (HERO): frames 30-40 (10 frames, extra dramatic) -->
      <KeyedObject objectId="0:26">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="30" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="34"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="30" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.6" x2="0.2" y2="1.6"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="40"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="-0.35" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="-0.35" frame="30" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.6" x2="0.2" y2="1.6"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="40"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- 8. MidBottom: frames 38-48 -->
      <KeyedObject objectId="0:27">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="38" interpolationType="linear"/>
          <KeyFrameDouble value="1" frame="42"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="17">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="38" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="48"/>
        </KeyedProperty>
        <KeyedProperty propertyKey="15">
          <KeyFrameDouble value="0.3" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0.3" frame="38" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.7" x2="0.3" y2="1.5"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="48"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- ============================================ -->
      <!-- Phase 3: Glow pulse (frames 54-72)           -->
      <!-- ============================================ -->

      <!-- GlowYellowTop: opacity 0 → 0.25 → 0 (frames 54-62) -->
      <KeyedObject objectId="0:30">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="54" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0.25" frame="58" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="62"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- GlowYellowSliver: opacity 0 → 0.25 → 0 (frames 58-66) -->
      <KeyedObject objectId="0:31">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="58" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0.25" frame="62" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="66"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- GlowYellowBig: opacity 0 → 0.25 → 0 (frames 62-70) -->
      <KeyedObject objectId="0:32">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="62" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0.25" frame="66" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="70"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- Note: Purple brightness effect is achieved via the AmbientGlow
           opacity change. The AmbientGlow KeyedObject must be merged into
           a single entry (see merge instruction below). -->

      <!-- ============================================ -->
      <!-- Phase 4: Text reveal (frames 66-90)          -->
      <!-- ============================================ -->

      <!-- StudioName text: opacity 0 → 1, y slides up -->
      <KeyedObject objectId="0:40">
        <!-- opacity -->
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="0" frame="66" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.0" x2="0.2" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="1" frame="78"/>
        </KeyedProperty>
        <!-- y: slide up from +15 to final position -->
        <KeyedProperty propertyKey="14">
          <KeyFrameDouble value="545" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="545" frame="66" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.0" x2="0.2" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="530" frame="82"/>
        </KeyedProperty>
      </KeyedObject>

      <!-- TextStylePaint letterSpacing: 24 → 18 (settle) -->
      <KeyedObject objectId="0:41">
        <KeyedProperty propertyKey="390">
          <KeyFrameDouble value="24" frame="0" interpolationType="hold"/>
          <KeyFrameDouble value="24" frame="66" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.0" y1="0.0" x2="0.2" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="18" frame="82"/>
        </KeyedProperty>
      </KeyedObject>

    </LinearAnimation>
```

**Important:** The AmbientGlow `KeyedObject` at `0:10` from earlier in the animation needs to be a SINGLE entry containing ALL its keyframes across all phases. Merge the Phase 1 and Phase 3 keyframes:

Replace the AmbientGlow `KeyedObject` with:

```xml
      <!-- AmbientGlow: fade in (0-9), hold (9-54), fade out (54-72) -->
      <KeyedObject objectId="0:10">
        <KeyedProperty propertyKey="18">
          <KeyFrameDouble value="0" frame="0" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0.6" frame="9" interpolationType="hold"/>
          <KeyFrameDouble value="0.6" frame="54" interpolationType="cubic">
            <CubicEaseInterpolator x1="0.25" y1="0.1" x2="0.25" y2="1"/>
          </KeyFrameDouble>
          <KeyFrameDouble value="0" frame="72"/>
        </KeyedProperty>
      </KeyedObject>
```

Also remove the duplicate/empty `KeyedObject objectId="0:20"` in the glow phase section (the one with the comment about purple color pulse). DarkWing's keyframes are already fully defined in Phase 2.

- [ ] **Step 2: Build and test**

```bash
rive rive-assets/logo-studio --once
```

Expected: Build succeeds with no errors. Check the build output for any `problems` warnings.

- [ ] **Step 3: Screenshot at final frame**

```bash
rive rive-assets/logo-studio --screenshot --advance=90
```

Expected: Screenshot shows complete logo with all 8 triangles at full opacity, "ALPACA SOLUTIONS" text visible below, no glow overlays visible (they've faded back to 0).

- [ ] **Step 4: Screenshot at mid-animation**

```bash
rive rive-assets/logo-studio --screenshot --advance=30
```

Expected: Some triangles visible (the first ~5 should be fully unfolded), later ones still partially visible or invisible. This confirms the cascade timing works.

- [ ] **Step 5: Preview the full animation**

```bash
rive rive-assets/logo-studio
```

Expected: A window opens showing the full 3-second animation. Verify:
- Dark screen → ambient glow fades in
- Triangles unfold one by one from top to bottom with overshoot
- Yellow pieces glow briefly after assembly
- "ALPACA SOLUTIONS" fades in and slides up
- Animation holds at final state

Close the preview window when satisfied.

- [ ] **Step 6: Commit**

```bash
git add rive-assets/logo-studio/scene.rml
git commit -m "feat(splash): add origami unfold animation keyframes (90 frames, 30fps)"
```

---

### Task 4: Polish and verify

**Files:**
- Modify: `rive-assets/logo-studio/scene.rml` (if adjustments needed)

**Interfaces:**
- Consumes: Complete animated scene from Task 3
- Produces: Final verified `.riv` file ready for Godot integration review

- [ ] **Step 1: Run full verification suite**

```bash
rive rive-assets/logo-studio --verify
```

Expected: No errors, no warnings.

- [ ] **Step 2: Build the signed .riv**

```bash
rive rive-assets/logo-studio --once
```

- [ ] **Step 3: Check file size**

```bash
ls -la rive-assets/logo-studio/build/
```

Expected: `alpaca-logo.riv` should be under 100KB.

- [ ] **Step 4: Capture final screenshot for review**

```bash
rive rive-assets/logo-studio --screenshot --advance=90
```

Save or note the path to `build/alpaca-logo.png` — this is the reference image for review.

- [ ] **Step 5: Run preview one more time, checking for visual issues**

```bash
rive rive-assets/logo-studio
```

Look for:
- Any triangle that appears to "pop" rather than smoothly unfold
- Glow pulse that's too bright or too dim
- Text appearing too early or too late
- Any visual glitch at the transition between phases

If any issue is found, adjust the relevant keyframe values in `scene.rml` and rebuild.

- [ ] **Step 6: Final commit**

```bash
git add rive-assets/logo-studio/
git commit -m "feat(splash): finalize studio logo splash animation (.riv verified)"
```
