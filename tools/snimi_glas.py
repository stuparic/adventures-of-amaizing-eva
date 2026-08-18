#!/usr/bin/env python3
"""Snimi glasovna obavestenja za Evine avanture.

Pokretanje:
    python3 tools/snimi_glas.py

Skripta ti ispisuje recenicu po recenicu, ti pritisnes ENTER i govoris.
Posle svake mozes da poslusas i ponovis ako nisi zadovoljan.

Snimci idu u audio/voice/ i NE commituju se u repo (licni su, kao
voice_win.wav). Igra radi i bez njih - ako fajla nema, pusta se fanfara.

Zavisnosti: samo macOS alati (`sox` ili `ffmpeg` za snimanje, `afplay` za
reprodukciju). Ako nemas `sox`, instaliraj: brew install sox
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "audio" / "voice"

# Koliko sekundi najduze snima jedan klip. Recenice su ~3s, 6 je rezerva.
MAX_SECONDS = 6

# Format MORA da odgovara ostatku projekta: 44100 Hz mono.
# Mereno ranije: web build je imao muziku 14x prebrzo jer je mix_rate bio
# 48000 a fajlovi 44100. Ne menjaj bez potrebe.
RATE = 44100


def read_friend_names() -> dict:
    """Procitaj imena prijatelja iz scripts/friend.gd."""
    src = (ROOT / "scripts" / "friend.gd").read_text()
    start = src.index('"maca": "macu')
    end = src.index("}", start)
    return dict(re.findall(r'"(\w+)": "([^"]+)"', src[start:end]))


def read_friend_order() -> list:
    """Procitaj prijatelje u redu u kom se pojavljuju u igri."""
    src = (ROOT / "autoload" / "game.gd").read_text()
    return re.findall(r'"friend": "(\w+)"', src)


def find_recorder() -> tuple:
    """Nadji alat za snimanje. Vraca (ime, funkcija-koja-gradi-komandu)."""
    if shutil.which("sox"):
        return "sox", lambda out: [
            "sox", "-d", "-r", str(RATE), "-c", "1", "-b", "16", str(out),
            "trim", "0", str(MAX_SECONDS),
        ]
    if shutil.which("ffmpeg"):
        return "ffmpeg", lambda out: [
            "ffmpeg", "-y", "-loglevel", "error",
            "-f", "avfoundation", "-i", ":0",
            "-ac", "1", "-ar", str(RATE),
            "-t", str(MAX_SECONDS), str(out),
        ]
    return "", None


def trim_silence(path: Path) -> None:
    """Skini tisinu s pocetka i kraja - inace glas "kasni" u igri."""
    if not shutil.which("sox"):
        return
    tmp = path.with_suffix(".trim.wav")
    try:
        subprocess.run(
            ["sox", str(path), str(tmp),
             "silence", "1", "0.1", "1%", "reverse",
             "silence", "1", "0.1", "1%", "reverse"],
            check=True, capture_output=True)
        tmp.replace(path)
    except subprocess.CalledProcessError:
        if tmp.exists():
            tmp.unlink()


def main() -> int:
    if sys.platform != "darwin":
        print("Ova skripta je pisana za macOS.")
        return 1

    tool, build_cmd = find_recorder()
    if not tool:
        print("Nema alata za snimanje.\n"
              "Instaliraj sox:  brew install sox")
        return 1
    if tool == "ffmpeg":
        print("NAPOMENA: koristi se ffmpeg. Radi, ali sox je bolji jer ume")
        print("da skine tisinu s pocetka i kraja (glas onda ne 'kasni').")
        print("  brew install sox\n")

    names = read_friend_names()
    order = read_friend_order()
    missing = [k for k in order if k not in names]
    if missing:
        print(f"GRESKA: prijatelji bez imena u friend.gd: {missing}")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Probni snimak od pola sekunde: ako mikrofon nije dostupan (nema
    # dozvole u System Settings > Privacy > Microphone), bolje da to
    # saznamo sad nego na 20. recenici.
    probe = OUT_DIR / "_proba.wav"
    try:
        cmd = build_cmd(probe)
        # Skrati probu na 1s.
        cmd = [("1" if a == str(MAX_SECONDS) else a) for a in cmd]
        subprocess.run(cmd, check=True, capture_output=True, timeout=20)
    except Exception as e:
        print(f"Mikrofon ne radi ({type(e).__name__}).")
        print("Na macOS-u dozvoli pristup mikrofonu:")
        print("  System Settings > Privacy & Security > Microphone")
        print("  pa ukljuci Terminal (ili aplikaciju iz koje pokreces).")
        return 1
    ok = probe.exists() and probe.stat().st_size > 1000
    if probe.exists():
        probe.unlink()
    if not ok:
        print("Mikrofon je otvoren ali snimak je prazan.")
        print("Proveri da li je ulaz izabran u System Settings > Sound > Input.")
        return 1
    print("Mikrofon radi.\n")

    # Sve recenice: prvo opsta (fallback), pa po prijatelju.
    items = [("_opste", "Bravo Eva! Oslobodila si novog drugara!")]
    for key in order:
        items.append((key, f"Bravo Eva! Oslobodila si {names[key]}!"))

    print("=" * 64)
    print(f"SNIMANJE GLASA  ({len(items)} recenica, alat: {tool})")
    print("=" * 64)
    print("Za svaku recenicu:")
    print("  ENTER      - snimi (govori pa cekaj da stane)")
    print("  p          - poslusaj poslednji snimak")
    print("  r          - snimi ponovo")
    print("  d          - dalje (preskoci ovu)")
    print("  q          - izlaz (sto je snimljeno ostaje)")
    print()
    print("Savet: govori VESELO i malo preglasno. Ovo cuje petogodisnjak")
    print("kad uspe - treba da zvuci kao pravo slavlje.")
    print()

    done = 0
    for idx, (key, text) in enumerate(items, 1):
        out = OUT_DIR / f"{key}.wav"
        status = " (vec snimljeno)" if out.exists() else ""
        while True:
            print(f"[{idx}/{len(items)}]{status}")
            print(f'  "{text}"')
            ans = input("  > ").strip().lower()

            if ans == "q":
                print(f"\nPrekinuto. Snimljeno: {done}")
                return 0
            if ans == "d":
                break
            if ans == "p":
                if out.exists():
                    subprocess.run(["afplay", str(out)])
                else:
                    print("  (nema snimka)")
                continue
            if ans in ("", "r"):
                print(f"  SNIMAM {MAX_SECONDS}s - govori sad...")
                try:
                    subprocess.run(build_cmd(out), check=True,
                                   capture_output=(tool == "ffmpeg"))
                except subprocess.CalledProcessError as e:
                    print(f"  greska pri snimanju: {e}")
                    continue
                trim_silence(out)
                size_kb = out.stat().st_size / 1024 if out.exists() else 0
                print(f"  snimljeno ({size_kb:.0f} KB) - 'p' za slusanje, "
                      f"'r' za ponovo, ENTER za dalje")
                status = " (snimljeno)"
                # Posle snimanja: ENTER ide dalje.
                nxt = input("  > ").strip().lower()
                if nxt == "p":
                    subprocess.run(["afplay", str(out)])
                    nxt = input("  ENTER dalje, 'r' ponovo > ").strip().lower()
                if nxt == "r":
                    continue
                done += 1
                break
            print("  ne razumem - ENTER/p/r/d/q")
        print()

    print("=" * 64)
    print(f"GOTOVO. Snimljeno {done} od {len(items)}.")
    print(f"Fajlovi: {OUT_DIR}")
    print()
    print("Sada pokreni igru - glas se ucitava sam.")
    print("Fajlovi se NE commituju (licni su, kao voice_win.wav).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
