"""Runner for convert_extracted_bank tests."""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tests"))

from test_convert_extracted_bank import TestConvertExtractedBank  # noqa: F401, E402

if __name__ == "__main__":
    unittest.main()
