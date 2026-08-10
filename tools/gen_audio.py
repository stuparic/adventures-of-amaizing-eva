#!/usr/bin/env python3
"""Sintetizuje sve zvukove za Adventure of Amazing Eva.

Cist standardni Python (wave + math + struct). Nema pip zavisnosti,
nema preuzimanja, nema licenci - svi zvukovi su generisani.

Stil: blagi chiptune, mekan (bez ostrih square talasa koji zamaraju dete).
"""

import math
import struct
import wave
import os

SR = 44100          # sample rate
OUT = os.environ.get("AUDIO_OUT", ".")


# ---------- osnovni talasi ----------

def sine(t, f):
    return math.sin(2.0 * math.pi * f * t)


def triangle(t, f):
    """Mekši od square - prijatniji za dugo slusanje."""
    p = (t * f) % 1.0
    return 4.0 * abs(p - 0.5) - 1.0


def square_soft(t, f, duty=0.5):
    """Square sa zaobljenim ivicama - chiptune bez ostrine."""
    p = (t * f) % 1.0
    raw = 1.0 if p < duty else -1.0
    # blago zaglađivanje kroz mesanje sa sinusom
    return raw * 0.6 + sine(t, f) * 0.4


def noise(seed=[12345]):
    """Deterministicki LCG sum - za sletanje/udarce."""
    seed[0] = (seed[0] * 1103515245 + 12345) & 0x7FFFFFFF
    return (seed[0] / 0x3FFFFFFF) - 1.0


# ---------- envelope ----------

def env_ad(i, n, attack=0.01, decay_curve=2.0):
    """Attack-decay envelope. attack je u sekundama."""
    t = i / SR
    total = n / SR
    a = min(attack, total * 0.5)
    if t < a:
        return t / a
    rel = (t - a) / max(total - a, 1e-6)
    return max(0.0, (1.0 - rel) ** decay_curve)


def env_adsr(i, n, a=0.01, d=0.05, s=0.7, r=0.2):
    t = i / SR
    total = n / SR
    rt = total - r
    if t < a:
        return t / a
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / d)
    if t < rt:
        return s
    return max(0.0, s * (1.0 - (t - rt) / max(r, 1e-6)))


# ---------- pisanje ----------

def write(name, samples, stereo=False):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            if stereo:
                l, r = s
                frames += struct.pack("<hh",
                                      int(max(-1, min(1, l)) * 30000),
                                      int(max(-1, min(1, r)) * 30000))
            else:
                frames += struct.pack("<h", int(max(-1, min(1, s)) * 30000))
        w.writeframes(bytes(frames))
    kb = os.path.getsize(path) / 1024
    print(f"  {name:24s} {kb:7.1f} KB")


# ---------- muzicka teorija ----------

# C major pentatonika - nema disonantnih intervala, uvek zvuci "lepo".
# Idealno za dete: ne moze da zvuci pogresno.
NOTE = {
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "G3": 196.00, "A3": 220.00,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00,
    "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "A5": 880.00,
    "C6": 1046.50, "E6": 1318.51, "G6": 1567.98,
}


# ================= ZVUCNI EFEKTI =================

def sfx_jump():
    """Kratak 'hop' - frekvencija se penje."""
    n = int(0.16 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 380 + 460 * (i / n) ** 0.6      # glisando gore
        out.append(square_soft(t, f, 0.45) * env_ad(i, n, 0.004, 2.2) * 0.32)
    return out


def sfx_land():
    """Mek 'tup' - kratak sum + nizak ton."""
    n = int(0.11 * SR)
    out = []
    for i in range(n):
        t = i / SR
        e = env_ad(i, n, 0.002, 3.5)
        body = sine(t, 150 - 60 * (i / n))
        out.append((body * 0.7 + noise() * 0.3) * e * 0.28)
    return out


def sfx_star():
    """Svetao 'cin' - dva tona u tercama, kao zvoncic."""
    n = int(0.28 * SR)
    out = []
    for i in range(n):
        t = i / SR
        e = env_ad(i, n, 0.003, 2.8)
        # arpeggio: E5 -> G5 -> C6
        seg = i / n
        if seg < 0.25:
            f = NOTE["E5"]
        elif seg < 0.5:
            f = NOTE["G5"]
        else:
            f = NOTE["C6"]
        v = triangle(t, f) * 0.55 + sine(t, f * 2) * 0.25
        out.append(v * e * 0.3)
    return out


def sfx_heart():
    """Nagrada za +1 srce - topao uzlazni arpeggio."""
    n = int(0.5 * SR)
    out = []
    seq = [NOTE["C5"], NOTE["E5"], NOTE["G5"], NOTE["C6"]]
    for i in range(n):
        t = i / SR
        idx = min(int(i / n * len(seq)), len(seq) - 1)
        f = seq[idx]
        e = env_ad(i, n, 0.01, 1.6)
        v = triangle(t, f) * 0.5 + sine(t, f * 2) * 0.2 + sine(t, f * 0.5) * 0.15
        out.append(v * e * 0.3)
    return out


def sfx_stomp():
    """Skok na zivotinju - 'boing', frekvencija pada."""
    n = int(0.2 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 620 - 360 * (i / n) ** 0.5      # glisando dole
        e = env_ad(i, n, 0.003, 2.0)
        out.append((square_soft(t, f, 0.6) * 0.6 + noise() * 0.15) * e * 0.3)
    return out


def sfx_hurt():
    """Udarac - nizak, kratak, NE strasan. Vise 'ups' nego 'aaa'."""
    n = int(0.3 * SR)
    out = []
    for i in range(n):
        t = i / SR
        # dva tona koja padaju - kao "oh-oh"
        seg = i / n
        f = 330 if seg < 0.45 else 247
        e = env_ad(i, n, 0.008, 1.8)
        out.append(triangle(t, f) * e * 0.28)
    return out


def sfx_checkpoint():
    """Cvet procveta - mek, svetao, kratak."""
    n = int(0.35 * SR)
    out = []
    for i in range(n):
        t = i / SR
        e = env_ad(i, n, 0.02, 1.5)
        v = (sine(t, NOTE["G5"]) * 0.4
             + sine(t, NOTE["B4"]) * 0.3
             + sine(t, NOTE["D5"]) * 0.3)
        out.append(v * e * 0.26)
    return out


def sfx_meow():
    """Mjauk mace - dva formanta, frekvencija ide gore-dole."""
    n = int(0.55 * SR)
    out = []
    for i in range(n):
        t = i / SR
        p = i / n
        # kontura mjauka: gore pa dole
        base = 620 + 300 * math.sin(math.pi * min(p * 1.3, 1.0))
        e = env_adsr(i, n, 0.05, 0.1, 0.75, 0.25)
        # formanti daju "macji" karakter
        v = (triangle(t, base) * 0.45
             + sine(t, base * 2.1) * 0.28
             + sine(t, base * 3.3) * 0.14)
        # blagi vibrato
        v *= 1.0 + 0.12 * sine(t, 22)
        out.append(v * e * 0.3)
    return out


def sfx_win():
    """Fanfara - spasila je macu. Vesela, uzlazna."""
    n = int(1.5 * SR)
    out = []
    # C - E - G - C - (pauza) - G - C6
    seq = [("C5", 0.14), ("E5", 0.14), ("G5", 0.14), ("C6", 0.28),
           ("G5", 0.14), ("C6", 0.5)]
    pos = 0.0
    marks = []
    for name, dur in seq:
        marks.append((pos, pos + dur, NOTE[name]))
        pos += dur

    for i in range(n):
        t = i / SR
        v = 0.0
        for (start, end, f) in marks:
            if start <= t < end:
                local = i - int(start * SR)
                ln = int((end - start) * SR)
                e = env_ad(local, ln, 0.01, 1.3)
                v += (square_soft(t, f, 0.5) * 0.4
                      + triangle(t, f * 2) * 0.2
                      + sine(t, f * 0.5) * 0.15) * e
        out.append(v * 0.3)
    return out


def sfx_gameover():
    """Potrosila srca - blago, ohrabrujuce. NE tuzno-dramaticno."""
    n = int(0.9 * SR)
    out = []
    seq = [("G4", 0.2), ("E4", 0.2), ("D4", 0.2), ("C4", 0.3)]
    pos = 0.0
    marks = []
    for name, dur in seq:
        marks.append((pos, pos + dur, NOTE[name]))
        pos += dur
    for i in range(n):
        t = i / SR
        v = 0.0
        for (start, end, f) in marks:
            if start <= t < end:
                local = i - int(start * SR)
                ln = int((end - start) * SR)
                v += triangle(t, f) * env_ad(local, ln, 0.02, 1.4) * 0.5
        out.append(v * 0.26)
    return out


# ================= POZADINSKA MUZIKA =================

def music_loop():
    """Vesela pentatonska petlja, ~19s, stereo, bešavno se ponavlja.

    Tri sloja: bas (koren), melodija (pentatonika), arpeggio (podloga).
    Sve u C majoru - ne moze da zvuci disonantno.
    """
    bpm = 116
    beat = 60.0 / bpm
    bars = 8
    beats_per_bar = 4
    total_beats = bars * beats_per_bar
    dur = total_beats * beat
    n = int(dur * SR)

    # Akordi po taktu: C - Am - F - G - C - Am - F - G (klasican, veseo)
    chords = [
        ("C3", ["C4", "E4", "G4"]),
        ("A3", ["A3", "C4", "E4"]),
        ("F4", ["F4", "A4", "C5"]),
        ("G3", ["G3", "B4", "D5"]),
        ("C3", ["C4", "E4", "G4"]),
        ("A3", ["A3", "C4", "E4"]),
        ("F4", ["F4", "A4", "C5"]),
        ("G3", ["G3", "B4", "D5"]),
    ]

    # Melodija: (beat_offset, nota, trajanje_u_beatovima)
    melody = [
        (0.0, "G4", 1.0), (1.0, "E5", 0.5), (1.5, "D5", 0.5),
        (2.0, "C5", 1.0), (3.0, "E5", 1.0),
        (4.0, "A4", 1.0), (5.0, "C5", 0.5), (5.5, "E5", 0.5),
        (6.0, "D5", 2.0),
        (8.0, "C5", 1.0), (9.0, "A4", 0.5), (9.5, "C5", 0.5),
        (10.0, "F4", 1.0), (11.0, "A4", 1.0),
        (12.0, "G4", 1.0), (13.0, "D5", 0.5), (13.5, "E5", 0.5),
        (14.0, "G5", 2.0),
        (16.0, "E5", 1.0), (17.0, "G5", 0.5), (17.5, "A5", 0.5),
        (18.0, "G5", 1.0), (19.0, "E5", 1.0),
        (20.0, "C5", 1.0), (21.0, "E5", 0.5), (21.5, "D5", 0.5),
        (22.0, "C5", 2.0),
        (24.0, "A4", 1.0), (25.0, "C5", 1.0),
        (26.0, "D5", 1.0), (27.0, "E5", 1.0),
        (28.0, "G4", 1.0), (29.0, "B4", 0.5), (29.5, "D5", 0.5),
        (30.0, "C5", 2.0),
    ]

    left = [0.0] * n
    right = [0.0] * n

    def add(buf_l, buf_r, start_s, dur_s, f, amp, kind, pan=0.0):
        s0 = int(start_s * SR)
        ln = int(dur_s * SR)
        for k in range(ln):
            idx = (s0 + k) % n            # wrap = besavna petlja
            t = (s0 + k) / SR
            if kind == "bass":
                v = sine(t, f) * 0.7 + triangle(t, f) * 0.3
                e = env_adsr(k, ln, 0.01, 0.06, 0.55, dur_s * 0.35)
            elif kind == "lead":
                v = triangle(t, f) * 0.6 + square_soft(t, f, 0.4) * 0.25
                e = env_adsr(k, ln, 0.015, 0.08, 0.6, dur_s * 0.4)
            else:  # arp
                v = triangle(t, f) * 0.5 + sine(t, f * 2) * 0.2
                e = env_ad(k, ln, 0.006, 2.4)
            s = v * e * amp
            gl = 0.5 * (1.0 - pan)
            gr = 0.5 * (1.0 + pan)
            buf_l[idx] += s * gl * 2.0
            buf_r[idx] += s * gr * 2.0

    for bar in range(bars):
        bar_t = bar * beats_per_bar * beat
        root, triad = chords[bar]

        # BAS: koren na 1 i 3, oktava gore na 2.5 i 4.5
        add(left, right, bar_t, beat * 0.9, NOTE[root], 0.30, "bass", -0.1)
        add(left, right, bar_t + beat * 2, beat * 0.9, NOTE[root], 0.26, "bass", -0.1)
        add(left, right, bar_t + beat * 1.5, beat * 0.4, NOTE[root] * 2, 0.14, "bass", -0.15)
        add(left, right, bar_t + beat * 3.5, beat * 0.4, NOTE[root] * 2, 0.14, "bass", -0.15)

        # ARPEGGIO: osmine kroz triadu, blago desno
        for e8 in range(8):
            f = NOTE[triad[e8 % 3]]
            add(left, right, bar_t + e8 * beat * 0.5, beat * 0.42, f,
                0.075, "arp", 0.35)

    # MELODIJA: centrirana, najglasnija
    for (b, name, blen) in melody:
        add(left, right, b * beat, blen * beat * 0.92, NOTE[name], 0.20, "lead", 0.05)

    # Blagi soft-clip da nema pucanja na sumiranju slojeva
    out = []
    for i in range(n):
        l = math.tanh(left[i] * 1.15) * 0.85
        r = math.tanh(right[i] * 1.15) * 0.85
        out.append((l, r))
    return out


def music_win():
    """Kratka pobednicka tema koja se pusti kad spasi macu (ne loop)."""
    bpm = 128
    beat = 60.0 / bpm
    n = int(beat * 12 * SR)
    left = [0.0] * n
    right = [0.0] * n

    seq = [
        (0.0, "C5", 0.5), (0.5, "E5", 0.5), (1.0, "G5", 0.5), (1.5, "C6", 1.5),
        (3.0, "A5", 0.5), (3.5, "G5", 0.5), (4.0, "E5", 0.5), (4.5, "G5", 1.5),
        (6.0, "C6", 2.0),
        (8.0, "G5", 0.5), (8.5, "C6", 0.5), (9.0, "E6", 2.0),
    ]
    bass = [(0.0, "C3", 2.0), (2.0, "F4", 2.0), (4.0, "G3", 2.0),
            (6.0, "C3", 2.0), (8.0, "G3", 1.0), (9.0, "C3", 2.0)]

    def add(start_s, dur_s, f, amp, kind):
        s0 = int(start_s * SR)
        ln = int(dur_s * SR)
        for k in range(ln):
            idx = s0 + k
            if idx >= n:
                break
            t = idx / SR
            if kind == "bass":
                v = sine(t, f) * 0.75 + triangle(t, f) * 0.25
                e = env_adsr(k, ln, 0.01, 0.06, 0.5, dur_s * 0.3)
            else:
                v = square_soft(t, f, 0.5) * 0.45 + triangle(t, f * 2) * 0.2
                e = env_adsr(k, ln, 0.01, 0.07, 0.65, dur_s * 0.35)
            s = v * e * amp
            left[idx] += s
            right[idx] += s

    for (b, nm, ln) in seq:
        add(b * beat, ln * beat * 0.95, NOTE[nm], 0.26, "lead")
    for (b, nm, ln) in bass:
        add(b * beat, ln * beat * 0.95, NOTE[nm], 0.24, "bass")

    return [(math.tanh(left[i] * 1.2) * 0.85, math.tanh(right[i] * 1.2) * 0.85)
            for i in range(n)]


if __name__ == "__main__":
    print("SFX:")
    write("sfx_jump.wav", sfx_jump())
    write("sfx_land.wav", sfx_land())
    write("sfx_star.wav", sfx_star())
    write("sfx_heart.wav", sfx_heart())
    write("sfx_stomp.wav", sfx_stomp())
    write("sfx_hurt.wav", sfx_hurt())
    write("sfx_checkpoint.wav", sfx_checkpoint())
    write("sfx_meow.wav", sfx_meow())
    write("sfx_win.wav", sfx_win())
    write("sfx_gameover.wav", sfx_gameover())
    print("MUSIC:")
    # music_loop.wav se ne koristi vise - muzika po biomu su CC0 OGG
    # fajlovi (audio/music_<biom>.ogg, vidi CREDITS.md). Funkcija
    # music_loop() je zadrzana kao referenca za sintezu.
    write("music_win.wav", music_win(), stereo=True)
    print("done")
