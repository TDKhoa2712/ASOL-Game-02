"""Generate the original, temporary M0 rendering probe atlas."""

from pathlib import Path

from PIL import Image, ImageDraw


FRAME = 128
OUTPUT = Path(__file__).with_name("cat-probe-atlas.png")


def draw_cat(draw: ImageDraw.ImageDraw, frame: int) -> None:
    x0 = frame * FRAME
    bob = (0, -8, -18, -6)[frame]
    fur = "#9B654C"
    shade = "#70442F"
    cream = "#F7D9AE"
    ear_left = [(x0 + 30, 48 + bob), (x0 + 37, 18 + bob), (x0 + 57, 40 + bob)]
    ear_right = [(x0 + 72, 40 + bob), (x0 + 91, 18 + bob), (x0 + 98, 48 + bob)]
    draw.polygon(ear_left, fill=fur)
    draw.polygon(ear_right, fill=fur)
    draw.ellipse((x0 + 27, 35 + bob, x0 + 101, 111 + bob), fill=fur)
    draw.ellipse((x0 + 43, 65 + bob, x0 + 85, 105 + bob), fill=cream)
    draw.ellipse((x0 + 45, 59 + bob, x0 + 52, 67 + bob), fill=shade)
    draw.ellipse((x0 + 76, 59 + bob, x0 + 83, 67 + bob), fill=shade)
    draw.polygon(
        [(x0 + 59, 77 + bob), (x0 + 69, 77 + bob), (x0 + 64, 84 + bob)],
        fill=shade,
    )
    draw.arc((x0 + 52, 77 + bob, x0 + 76, 96 + bob), 10, 170, fill=shade, width=3)
    if frame in (1, 2):
        draw.arc((x0 + 14, 68 + bob, x0 + 39, 103 + bob), 130, 280, fill=shade, width=6)
    if frame == 3:
        draw.ellipse((x0 + 13, 19, x0 + 22, 28), fill="#F8C96A")
        draw.ellipse((x0 + 108, 34, x0 + 116, 42), fill="#F8C96A")


def main() -> None:
    atlas = Image.new("RGBA", (FRAME * 4, FRAME), (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)
    for frame in range(4):
        draw_cat(draw, frame)
    atlas.save(OUTPUT, optimize=True)
    print(f"Generated {OUTPUT.name}: {atlas.width}x{atlas.height} RGBA")


if __name__ == "__main__":
    main()
