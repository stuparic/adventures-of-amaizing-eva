#!/usr/bin/env python3
"""Prepravi Godotov service worker da HTML ide sa MREZE, ne iz kesa.

Zasto je ovo potrebno:
    Godotov SW za navigaciju radi "cache first" - vraca index.html iz
    kesa i tek ako fajl fali ide na mrezu. U PWA to znaci da korisnik
    zauvek dobija STARU stranicu: uninstall PWA ne brise Cache Storage,
    pa ni reinstalacija ne pomaze.

    Konkretno je zbog toga popravka zvuka na telefonu (otkljucavanje
    AudioContext-a u shell-u) stizala u browser ali NE u instaliranu PWA.

Sta menja:
    Navigacija (index.html) ide "network first": pokusaj mrezu, pa ako
    nema veze koristi kes. Ostali fajlovi (wasm, pck) ostaju cache-first
    jer su veliki i menjaju se sa CACHE_VERSION.

Pokretanje:  python3 tools/patch_sw.py build/web/index.service.worker.js
"""

import sys
import pathlib

MARKER = "// EVA: network-first za navigaciju"

# Godotov original: kod navigacije prvo gleda kes.
OLD = """			if (isNavigate) {
					// Check if we have full cache during HTML page request.
					/** @type {Response[]} */
					const fullCache = await Promise.all(FULL_CACHE.map((name) => cache.match(name)));
					const missing = fullCache.some((v) => v === undefined);
					if (missing) {"""

NEW = """			if (isNavigate) {
					// EVA: network-first za navigaciju
					//
					// HTML se UVEK trazi sa mreze. Godotov original je isao
					// "cache first", pa je PWA zauvek dobijala staru stranicu
					// (uninstall ne brise Cache Storage). Ako mreze nema,
					// padamo na kes ispod - offline i dalje radi.
					try {
						const fresh = await fetch(event.request);
						if (fresh && fresh.ok) {
							const c2 = await caches.open(CACHE_NAME);
							c2.put(event.request, fresh.clone());
							return ENSURE_CROSSORIGIN_ISOLATION_HEADERS
								? ensureCrossOriginIsolationHeaders(fresh)
								: fresh;
						}
					} catch (e) {
						// Nema mreze - nastavi na kes.
					}
					// Check if we have full cache during HTML page request.
					/** @type {Response[]} */
					const fullCache = await Promise.all(FULL_CACHE.map((name) => cache.match(name)));
					const missing = fullCache.some((v) => v === undefined);
					if (missing) {"""


def main() -> int:
    if len(sys.argv) < 2:
        print("upotreba: patch_sw.py <putanja do index.service.worker.js>")
        return 2

    p = pathlib.Path(sys.argv[1])
    if not p.exists():
        print(f"GRESKA: nema {p}")
        return 1

    s = p.read_text()
    if MARKER in s:
        print("  SW je vec prepravljen")
        return 0
    if OLD not in s:
        # Godot je promenio sablon - bolje pasti nego tiho preskociti.
        print("GRESKA: ne nalazim ocekivani kod u SW-u.")
        print("        Godot je verovatno promenio sablon; proveri rucno.")
        return 1

    p.write_text(s.replace(OLD, NEW, 1))
    print(f"  SW prepravljen: navigacija ide network-first ({p.name})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
