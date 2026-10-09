"""Offline tool: bakes the combo word art into one atlas PNG for the game.

Run: python -B tools/build_combo_atlas.py [--check]
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "game/assets/fonts/Nunito-Bold.ttf"
OUT_DIR = ROOT / "game/assets/ui/combo"
OUT_PNG = OUT_DIR / "combo_atlas.png"
OUT_JSON = OUT_DIR / "combo_atlas.json"
WORDS = ["NICE!", "GREAT!", "SWEET!", "AWESOME!", "EXCELLENT!", "AMAZING!",
         "DELICIOUS!", "INCREDIBLE!", "FANTASTIC!", "DIVINE!", "UNSTOPPABLE!", "LEGENDARY!"]
FRAME = (512, 128)
COLS = 2
ATLAS_SIZE = (FRAME[0] * COLS, FRAME[1] * (len(WORDS) // COLS))
MAX_TEXT_W = 470
MAX_FONT = 92
STROKE = 9
OUTLINE = (74, 32, 22, 255)
SHADOW = (40, 14, 10, 150)
# (top, bottom) fill per tier: 1–4 candy pink, 5–8 orange sherbet, 9–12 gold.
TIERS = [((255, 226, 238), (255, 110, 170)),
         ((255, 236, 140), (255, 120, 60)),
         ((255, 250, 190), (240, 170, 0))]


def frame_rect(level):
    index = level - 1
    return ((index % COLS) * FRAME[0], (index // COLS) * FRAME[1], FRAME[0], FRAME[1])


def _font_for(word):
    size = MAX_FONT
    while size > 24:
        font = ImageFont.truetype(str(FONT), size)
        left, _, right, _ = font.getbbox(word, stroke_width=STROKE)
        if right - left <= MAX_TEXT_W:
            return font
        size -= 2
    return ImageFont.truetype(str(FONT), size)


def _gradient(top, bottom):
    strip = Image.new("RGBA", (1, FRAME[1]))
    for y in range(FRAME[1]):
        t = y / (FRAME[1] - 1)
        strip.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return strip.resize(FRAME)


def render_word(level):
    word = WORDS[level - 1]
    font = _font_for(word)
    center = (FRAME[0] // 2, FRAME[1] // 2 - 4)
    frame = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    shadow = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((center[0], center[1] + 6), word, font=font, anchor="mm",
                                fill=SHADOW, stroke_width=STROKE, stroke_fill=SHADOW)
    frame.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(2)))
    ImageDraw.Draw(frame).text(center, word, font=font, anchor="mm", fill=OUTLINE,
                               stroke_width=STROKE, stroke_fill=OUTLINE)
    mask = Image.new("L", FRAME, 0)
    ImageDraw.Draw(mask).text(center, word, font=font, anchor="mm", fill=255)
    top, bottom = TIERS[(level - 1) // 4]
    frame.paste(_gradient(top, bottom), (0, 0), mask)
    return frame


def render():
    image = Image.new("RGBA", ATLAS_SIZE, (0, 0, 0, 0))
    for level in range(1, len(WORDS) + 1):
        x, y, _, _ = frame_rect(level)
        image.alpha_composite(render_word(level), (x, y))
    return image


def manifest():
    return {"frame": list(FRAME), "cols": COLS,
            "words": {str(i + 1): word for i, word in enumerate(WORDS)}}


def check():
    errors = []
    if not OUT_PNG.exists() or not OUT_JSON.exists():
        return ["combo atlas missing; run tools/build_combo_atlas.py"]
    with Image.open(OUT_PNG) as image:
        if image.size != ATLAS_SIZE:
            errors.append(f"atlas size {image.size} != {ATLAS_SIZE}")
    if json.loads(OUT_JSON.read_text(encoding="utf-8")) != manifest():
        errors.append("combo_atlas.json out of date")
    return errors


def main():
    if "--check" in sys.argv:
        errors = check()
        for error in errors:
            print(error, file=sys.stderr)
        return 1 if errors else 0
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    render().save(OUT_PNG, optimize=True)
    OUT_JSON.write_text(json.dumps(manifest(), indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT_PNG.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
