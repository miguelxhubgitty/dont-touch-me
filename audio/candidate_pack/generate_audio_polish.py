#!/usr/bin/env python3
"""Deterministic, original short SFX candidates for Don't Touch Me.

Run: python generate_audio_polish.py [output-directory]
Writes original mono 22,050 Hz/16-bit WAVs. No source samples/dependencies.
The game needs updated event paths and a longer tap_miss max_seconds to use them.
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 22050
TAU = 2 * math.pi
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "candidate_sfx"


def pulse(t, center, width):
    return math.exp(-0.5 * ((t - center) / width) ** 2)


def high_cut_noise(n, seed, bright_cut=2300, body_cut=280):
    rng = random.Random(seed)
    bright = 0.0
    body = 0.0
    a = 1 - math.exp(-TAU * bright_cut / SR)
    b = 1 - math.exp(-TAU * body_cut / SR)
    res = []
    for _ in range(n):
        raw = rng.uniform(-1, 1)
        bright += a * (raw - bright)
        body += b * (raw - body)
        res.append((bright - 0.38 * body) * 1.5)
    return res


def write_wav(path, values, peak=0.76):
    path = OUT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    # A deliberate, short fade removes clicks at clip boundaries.
    edge = min(110, len(values) // 5)
    for i in range(edge):
        values[i] *= i / edge
        values[-1-i] *= i / edge
    maximum = max(max(abs(v) for v in values), 1e-8)
    scale = min(1.0, peak / maximum)
    data = [int(max(-1, min(1, v * scale)) * 32767) for v in values]
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(struct.pack('<' + 'h' * len(data), *data))
    return path


def miss_tough_luck():
    """Two rounded, descending 'uh-oh' blips; no tap transients."""
    duration = .265
    out = []
    phases = [0.0, 0.0]
    for i in range(int(SR * duration)):
        t = i / SR
        total = 0.0
        for k, (onset, length, start, end, amp) in enumerate([
            (.020, .095, 515, 348, .43),
            (.118, .142, 390, 226, .70),
        ]):
            x = (t - onset) / length
            if not 0 <= x <= 1:
                continue
            f = start * (end / start) ** x * (1 + .006 * math.sin(TAU * 5 * t))
            phases[k] += TAU * f / SR
            envelope = (1 - math.exp(-34 * x)) * (1 - x) ** 1.05
            total += amp * envelope * (math.sin(phases[k]) + .27 * math.sin(2 * phases[k] + .35) + .10 * math.sin(3 * phases[k]))
        out.append(math.tanh(total * 1.55))
    return out


def miss_little_sigh():
    """Alternative: short, gently sagging 'wah-wah'."""
    duration = .295
    out = []
    phase = 0.0
    for i in range(int(SR * duration)):
        t = i / SR
        x = t / duration
        f = 495 * (240 / 495) ** x * (1 + .011 * math.sin(TAU * 8 * t) * x)
        phase += TAU * f / SR
        swell = (1 - math.exp(-57 * x)) * (1 - x) ** .9
        stagger = .46 + .54 * (pulse(t, .075, .04) + pulse(t, .178, .05))
        harmonic = math.sin(phase) + .31 * math.sin(2 * phase + .5) + .08 * math.sin(3 * phase)
        out.append(math.tanh(.93 * swell * stagger * harmonic))
    return out


def cardboard(raising):
    """Chunky, low-mid folding-board scrape; quiet flexes plus hollow bumps."""
    duration = .295 if raising else .290
    n = int(SR * duration)
    noise = high_cut_noise(n, 4972 if raising else 4973, bright_cut=1550 if raising else 1250, body_cut=180)
    low = high_cut_noise(n, 8652 if raising else 8653, bright_cut=420, body_cut=60)
    crackle = high_cut_noise(n, 359 if raising else 360, bright_cut=3800, body_cut=880)
    shifts = [(0.046, 0.022, .65), (.114, .020, .57), (.202, .027, .55)] if raising else [(.029, .021, .48), (.092, .022, .62), (.195, .025, .88)]
    cracks = [(.053, .0036, .29), (.120, .0038, .31), (.178, .004, .18)] if raising else [(.058, .004, .16), (.187, .004, .32), (.227, .0042, .36)]
    bumps = [(.054, 113, .27), (.197, 87, .32)] if raising else [(.077, 96, .19), (.210, 76, .43)]
    out = []
    bump_phases = [0.0] * len(bumps)
    for i in range(n):
        t = i / SR
        # Sticking and slipping produces a much rougher texture than the thin SIGN swishes.
        rub = .14 + .38 * pulse(t, .110 if raising else .145, .084)
        rub *= .77 + .23 * math.sin(TAU * 23 * t) ** 2
        rough = (noise[i] * rub + low[i] * .22 * pulse(t, .135, .107))
        pop = sum(amp * pulse(t, tm, width) for tm, width, amp in cracks)
        grit = pop * crackle[i]
        creases = sum(amp * pulse(t, tm, width) * (.5 + .5 * math.sin(TAU * 35 * t) ** 2)
                      for tm, width, amp in shifts) * low[i]
        thud = 0.0
        for j, (at, freq, amp) in enumerate(bumps):
            u = t - at
            if 0 <= u < .095:
                current_f = freq * (1 - .34 * u / .095)
                bump_phases[j] += TAU * current_f / SR
                thud += amp * math.exp(-u * 41) * math.sin(bump_phases[j])
        out.append(math.tanh(1.32 * (rough + creases + grit + thud)))
    return out


def main():
    files = [
        ('user/tap_miss_tough_luck_v2.wav', miss_tough_luck(), .73),
        ('user/tap_miss_little_sigh_alt.wav', miss_little_sigh(), .73),
        ('character/box_raise_cardboard_v2.wav', cardboard(True), .75),
        ('character/box_lower_cardboard_v2.wav', cardboard(False), .77),
    ]
    for name, values, peak in files:
        path = write_wav(name, values, peak)
        print(path, len(values) / SR)


if __name__ == '__main__':
    main()
