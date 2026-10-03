#!/usr/bin/env python3
"""Encode bank JSON files with XOR for release builds."""
import argparse
import pathlib

KEY = b"candoku-2026-bank-key"

def xor_transform(data: bytes) -> bytes:
    key_len = len(KEY)
    return bytes(b ^ KEY[i % key_len] for i, b in enumerate(data))

def main():
    parser = argparse.ArgumentParser(description="Encode bank files for release")
    parser.add_argument("--input", required=True, help="Directory with plain bank JSON files")
    parser.add_argument("--output", required=True, help="Directory for encoded files")
    args = parser.parse_args()
    src = pathlib.Path(args.input)
    dst = pathlib.Path(args.output)
    dst.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.glob("*.json")):
        encoded = xor_transform(f.read_bytes())
        (dst / f.name).write_bytes(encoded)
        print(f"Encoded {f.name} -> {dst / f.name}")

if __name__ == "__main__":
    main()
