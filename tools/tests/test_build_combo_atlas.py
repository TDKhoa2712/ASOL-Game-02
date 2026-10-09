import importlib.util
import unittest
from pathlib import Path

# Load by path: putting tools/ on sys.path shadows tools/tests modules of the same name.
_SPEC = importlib.util.spec_from_file_location(
    "build_combo_atlas", Path(__file__).resolve().parents[1] / "build_combo_atlas.py")
atlas = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(atlas)


class TestComboAtlas(unittest.TestCase):
    def test_twelve_words(self):
        self.assertEqual(len(atlas.WORDS), 12)
        self.assertEqual(atlas.WORDS[0], "NICE!")
        self.assertEqual(atlas.WORDS[11], "LEGENDARY!")

    def test_frame_rects_in_bounds_and_distinct(self):
        rects = [atlas.frame_rect(n) for n in range(1, 13)]
        self.assertEqual(len(set(rects)), 12)
        for x, y, w, h in rects:
            self.assertLessEqual(x + w, atlas.ATLAS_SIZE[0])
            self.assertLessEqual(y + h, atlas.ATLAS_SIZE[1])

    def test_render_has_ink_in_every_frame(self):
        image = atlas.render()
        self.assertEqual(image.size, atlas.ATLAS_SIZE)
        for n in range(1, 13):
            x, y, w, h = atlas.frame_rect(n)
            self.assertIsNotNone(image.crop((x, y, x + w, y + h)).getbbox(), f"frame {n} empty")

    def test_committed_atlas_matches_layout(self):
        self.assertEqual(atlas.check(), [])


if __name__ == "__main__":
    unittest.main()
