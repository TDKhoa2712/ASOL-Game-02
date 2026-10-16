"""Offline tool: synthesizes the streak screen sounds (original, procedural) as OGG files.

Each sound is one timeline matched to its screen's animation, so the screen plays a single
effect when it opens. Run: python -B tools/build_streak_sfx.py [--check]
"""
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "game/assets/audio/sfx/streak"
RATE = 44100
SEED = 2026
ARP = [523.25, 659.25, 783.99, 1046.5]


class Track:
    def __init__(self, seconds):
        self.buf = np.zeros(int(seconds * RATE))
        self.rng = np.random.default_rng(SEED)

    def _env(self, n, attack, peak):
        env = np.empty(n)
        a = max(1, min(n - 1, int(attack * RATE)))
        env[:a] = np.geomspace(1e-4, 1.0, a)
        env[a:] = np.geomspace(1.0, 1e-4, n - a)
        return env * peak

    def _put(self, t, sig):
        start = int(t * RATE)
        end = min(len(self.buf), start + len(sig))
        self.buf[start:end] += sig[: end - start]

    def tone(self, t, freq, dur, vol, wave="sine", to=None):
        n = int(dur * RATE)
        f = np.geomspace(freq, to, n) if to else np.full(n, freq)
        phase = 2 * np.pi * np.cumsum(f) / RATE
        if wave == "triangle":
            sig = 2 / np.pi * np.arcsin(np.sin(phase))
        elif wave == "square":
            sig = np.sign(np.sin(phase)) * 0.6
        else:
            sig = np.sin(phase)
        self._put(t, sig * self._env(n, 0.012, vol))

    def noise(self, t, dur, vol, lo, hi=None, attack_frac=0.25):
        """Band of noise whose centre sweeps from lo to hi (one-pole filters, cheap and smooth)."""
        n = int(dur * RATE)
        white = self.rng.uniform(-1, 1, n)
        centre = np.geomspace(lo, hi or lo, n)
        out = np.empty(n)
        low = high = 0.0
        for i in range(n):
            a = 1 - np.exp(-2 * np.pi * centre[i] * 1.6 / RATE)
            b = 1 - np.exp(-2 * np.pi * centre[i] * 0.6 / RATE)
            low += a * (white[i] - low)
            high += b * (low - high)
            out[i] = low - high
        out /= max(1e-6, np.abs(out).max())
        self._put(t, out * self._env(n, dur * attack_frac, vol))

    def crackle(self, start, end, count):
        for _ in range(count):
            t = self.rng.uniform(start, end)
            self.noise(t, self.rng.uniform(0.015, 0.04), self.rng.uniform(0.12, 0.3), 2600, attack_frac=0.1)

    def fanfare(self, t, notes, step, chord_at):
        for i, f in enumerate(notes):
            self.tone(t + i * step, f, 0.24, 0.3, "triangle")
        for f in ARP:
            self.tone(chord_at, f, 1.0, 0.13, "triangle")

    def samples(self):
        peak = np.abs(self.buf).max()
        return (self.buf / peak * 0.89 if peak > 0 else self.buf).astype(np.float32)


def activate():
    tr = Track(4.2)
    tr.noise(0.25, 0.6, 0.55, 250, 3200)          # ignition whoosh
    tr.tone(0.55, 110, 0.35, 0.6, to=40)           # thump as the flame lands
    tr.noise(0.5, 2.6, 0.1, 500, 380, 0.1)         # low fire bed
    tr.crackle(0.6, 3.4, 40)
    tr.tone(1.38, 520, 0.14, 0.35, "triangle", to=880)  # count pop
    tr.tone(1.42, 1320, 0.4, 0.18)
    tr.tone(2.05, 1568, 0.25, 0.22)                # today's cell chime
    tr.tone(2.09, 2093, 0.35, 0.12)
    tr.fanfare(2.2, ARP, 0.09, 2.6)
    tr.noise(2.65, 0.35, 0.2, 900, 2600)           # continue swoosh
    return tr.samples()


def gift():
    tr = Track(5.0)
    tr.noise(0.05, 0.45, 0.25, 2400, 500)          # falling whistle
    tr.tone(0.5, 140, 0.25, 0.6, to=55)            # landing thud
    tr.noise(0.5, 0.12, 0.3, 900, attack_frac=0.1)
    for i in range(8):                              # rattles grow with the shake
        t = 1.2 + i * 0.0775
        tr.noise(t, 0.06, 0.2 + i * 0.05, 1400 + i * 120, attack_frac=0.1)
        tr.tone(t, 300 + i * 40, 0.05, 0.05 + i * 0.01, "square")
    tr.tone(1.9, 180, 0.3, 0.7, to=60)             # lid pop
    tr.noise(1.9, 0.35, 0.6, 600, 4000, 0.1)
    tr.tone(1.92, 700, 0.12, 0.3, "triangle", to=1400)
    for i, f in enumerate([2093, 2637, 3136, 2349, 2794, 3520]):
        tr.tone(1.97 + i * 0.06, f, 0.3, 0.1)       # sparkles
    tr.fanfare(2.45, [392, 523.25, 659.25, 783.99], 0.1, 2.85)
    tr.tone(2.97, 1318.5, 0.35, 0.22)              # reward dings
    tr.tone(3.42, 1568, 0.4, 0.22)
    tr.noise(4.4, 0.35, 0.2, 900, 2600)
    return tr.samples()


SOUNDS = {"streak-activate.ogg": activate, "streak-gift.ogg": gift}


def check():
    return [f"missing {name}; run tools/build_streak_sfx.py" for name in SOUNDS if not (OUT_DIR / name).exists()]


def main():
    if "--check" in sys.argv:
        errors = check()
        for error in errors:
            print(error, file=sys.stderr)
        return 1 if errors else 0
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, build in SOUNDS.items():
        sf.write(OUT_DIR / name, build(), RATE, format="OGG", subtype="VORBIS")
        print(f"wrote {(OUT_DIR / name).relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
