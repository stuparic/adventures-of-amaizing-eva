# Evine Avanture

2D side-scroller platformer. Eva (5 god., plava kosa, plave oci) i njena lutka
Budzumbora (roze haljina, narandzasta kosa) idu kroz nivo da spasu macu iz kaveza.

Godot 4.7 · besplatno · bez ikakvih zavisnosti

## ▶ Igraj u browseru

**https://stuparic.github.io/adventures-of-amaizing-eva/**

Radi na kompjuteru, tabletu i telefonu. Prvo otvaranje ucitava ~44 MB,
posle toga browser kesira pa je odmah tu.

### Na telefonu: dodaj na pocetni ekran

Stranica ne moze sama da sakrije adresnu traku browsera — to je bezbednosno
pravilo. Ali igra je PWA, pa kad je dodas na pocetni ekran otvara se **kao
aplikacija: bez adresne trake, na ceo ekran, zakljucana u landscape**.

- **iPhone (Safari):** Podeli (↑) → "Dodaj na pocetni ekran"
- **Android (Chrome):** Meni (⋮) → "Dodaj na pocetni ekran"

Igra sama prikaze ovo uputstvo posle par sekundi kad je otvoris u browseru
na telefonu. Na Androidu i prvi dodir prebacuje u fullscreen (iOS Safari to
ne podrzava).

Igra se **samo u landscape-u** — u portretu prikaze "Okreni telefon", jer
side-scroller u vertikalnom kadru ne radi.

Web verzija se build-uje automatski na svaki push
([.github/workflows/deploy.yml](.github/workflows/deploy.yml)).

## Pokretanje lokalno

```bash
open -a Godot project.godot
```

Pa pritisni **F5** u editoru. Ili direktno iz terminala bez editora:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## Mapa sveta

Igra pocinje na **mapi sveta** — tacke po klimatskim predelima, spojene
isprekidanim putevima. Za sad postoji **Zelena livada**; ostalih pet
(plaza, dzungla, pustinja, snezne planine, vulkan) su prikazani kao
zatvorene tacke sa oznakom "uskoro".

Nivo se otkljucava kad zavrsis prethodni. Napredak i najbolji rezultat
(zvezdice + vreme) se cuvaju, pa prezive zatvaranje browsera.

Mapa je **arhipelag** sa **14 nivoa na 6 ostrva**. Na jednom ostrvu je
vise nivoa — Eva ide **peske** izmedju njih (zemljana staza), a
**brodicem** kad prelazi na drugo ostrvo (morska brazda).

Bioma ostrva je vizualni identitet nivoa koji su na njemu:

| Ostrvo | Kako izgleda |
|---|---|
| Zelena livada | listopadno drvece, cvetici, jezerce |
| Peščana plaža | palme sa kokosima, skoljke, laguna |
| Zelena džungla | gusto visoko drvece u tri sloja, tamno tlo |
| Vruća pustinja | kaktusi sa cvetovima, dine, stene |
| Snežne planine | jelke pod snegom, smetovi, zaledjeno jezero |
| Vatreni vulkan | krater sa lavom, tokovi lave, mrtvo drvo, pepeo |

Ostrva su **velika i dominiraju kadrom** — okean je vezni prostor, ne
glavni sadrzaj. Izmedju je samo nekoliko malih ostrvaca radi flavora.

Putevi su **morske brazde** — Eva putuje brodicem od ostrva do ostrva.
Tacka nivoa je **bova u vodi** ispred ostrva (sa odsjajem), da ne
zaklanja bioma.

Gustina vegetacije prati povrsinu ostrva, pa veliko ostrvo nije prazno.
Drvece i cvetici izbegavaju jezera.

Art se generise kodom u [scripts/biome_art.gd](scripts/biome_art.gd),
deterministicki (fiksan seed) — mapa je ista pri svakom pokretanju.
Nova ostrva se dodaju upisom `biome`, `island` i `island_size` u LEVELS.

**Kretanje po mapi:**

| Akcija | Kako |
|---|---|
| Izaberi nivo | strelice, ili klik/dodir na tacku |
| Udji u nivo | SPACE, ili ponovni klik na izabranu tacku |
| Zumiraj | dugmad **+** / **−** desno na sredini, skrol misa, pinch |
| Pomeri mapu | prevuci misem ili prstom |
| Vrati kameru | dugme **Eva** desno na sredini |

### Kako da dodas nov nivo

1. Napravi scenu, npr. `scenes/level_plaza.tscn` (kopiraj `main.tscn` i
   promeni tabele u skripti).
2. U [autoload/game.gd](autoload/game.gd) nadji taj nivo u `LEVELS` i
   upisi putanju u `scene`.

Nov nivo na postojecem ostrvu: dodaj unos u `LEVELS` sa `island` = id
ostrva i `pos` na tom ostrvu. Put se sam nacrta kao kopneni.

Novo ostrvo: dodaj unos u `ISLANDS` (id, biome, pos, size), pa nivoe
koji na njega pokazuju.

To je sve — mapa, put, otkljucavanje i statistika rade sami. Nivo bez
`scene` se automatski prikazuje kao "uskoro".

Pozicije tacaka na mapi su `map_pos` u istoj tabeli.

## Pauza kad se prozor sakrije

Kad prebacis aplikaciju, minimizujes prozor ili zakljucas telefon:
igra se **pauzira** i zvuk se **utisa** (meko, 0.12s). Kad se vratis,
nastavlja gde je stala i zvuk se vraca.

Bitno na telefonu — Eva ne moze da padne u rupu dok se ne gleda.

Radi preko dva odvojena signala, jer nijedan sam nije dovoljan:
- `NOTIFICATION_APPLICATION_FOCUS_OUT` — desktop
- `document.visibilitychange` (+ `pagehide`/`blur`) — telefon, gde Godot
  cesto ne dobije focus event pri prebacivanju aplikacije

Kod: [autoload/pause_manager.gd](autoload/pause_manager.gd)

## Kontrole

| Akcija | Tasteri |
|---|---|
| Kretanje | strelice levo/desno, ili A/D, ili gamepad |
| Skok | SPACE, strelica gore, W, ili A na gamepadu |
| Restart nivoa | R |
| Mapa sveta | M ili ESC |
| Zvuk on/off | N |

## Sta je uradjeno za tezinu detetu od 5 godina

Ovo su namerne odluke, ne slucajnosti:

- **5 srca** umesto Mariovih 1-2.
- **Coyote time (0.18s)** — skok radi i kad je vec sisla sa ivice.
- **Jump buffer (0.20s)** — ako pritisne skok malo pre sletanja, skok se pamti.
- **Nema inercije** — pusti taster, Eva odmah stane. Mario klizi; to frustrira dete.
- **Sporije padanje** (gravitacija × 0.72) — vise vremena da reaguje u vazduhu.
- **Pad u rupu nije smrt** — gubi jedno srce i vraca se na poslednji cvet.
- **Mnogo checkpointa** (cvetovi) — nikad se ne vraca daleko.
- **Kad potrosi svih 5 srca** — banner "Probaj ponovo", pa automatski nastavlja
  od poslednjeg cveta sa punim srcima. Nivo se NE resetuje, zvezdice ostaju.
- **2s neranjivosti** posle udarca, sa blinkanjem kao vizualnim signalom.
- **Svakih 10 zvezdica = +1 srce** — nagrada, ne kazna.
- **Zivotinje ne jure Evu** — samo setaju levo-desno, i vidno se okrenu
  (pauza + rotacija) pre promene smera, da dete stigne da vidi sta sledi.
- **Budzumbora magnetom privlaci zvezdice** u krugu od 42px — ne mora precizno.
- **Zvezdice su postavljene kao putokaz** — iznad skokova, pokazuju kuda ici.

## Kako da menjas igru

### Tezina
Sve brojke su na jednom mestu: [autoload/game.gd](autoload/game.gd).
Ako je pretesko — povecaj `PLAYER_JUMP_VELOCITY` (npr. -420), smanji
`PLAYER_GRAVITY_SCALE` (npr. 0.6), ili povecaj `MAX_HEARTS`.

### Nivo
Ceo nivo je u tabelama na vrhu [scripts/main.gd](scripts/main.gd):

- `PLATFORMS` — `Rect2(x, y, sirina, visina)`. Tlo je `y = 0`, negativno je gore.
  **Rupu pravis tako sto ne stavis platformu** — prazan prostor izmedju dva Rect2.
- `STARS` — pozicije zvezdica
- `ANIMALS` — `["puz", Vector2(x, y)]` ili `["kornjaca", ...]`
- `CHECKPOINTS` — pozicije cvetova
- `MACA_POS` — gde je maca (kraj nivoa)

Nivo trenutno ide od x=0 do x=2220, u tri dela sa sve vecim rupama.

### Zvuk

Svi zvukovi su **sinteticki generisani** — nema preuzetih fajlova, nema licenci.
Generator je [tools/gen_audio.py](tools/gen_audio.py) (cist Python, bez pip paketa):

```bash
AUDIO_OUT=audio python3 tools/gen_audio.py
```

Muzika je u C major pentatonici — nema disonantnih intervala, ne moze da zvuci
pogresno. Petlja je 16.5s, akordi C–Am–F–G, tri sloja (bas, melodija, arpeggio).

Glasnost svakog zvuka menjas u `SFX_DB` u [autoload/audio.gd](autoload/audio.gd).
Muzika je na −14 dB da ne nadglasa efekte; `MUSIC_DB` je tamo isto.

| Zvuk | Kada |
|---|---|
| `jump` / `land` | skok i sletanje |
| `star` | zvezdica |
| `heart` | svakih 10 zvezdica = +1 srce (bogatiji arpeggio) |
| `stomp` | skok na zivotinju |
| `hurt` | udarac ili pad u rupu |
| `checkpoint` | cvet procveta |
| `meow` | maca doziva svakih 4.5s kad je Eva blize od 420px |
| `win` + `music_win` | spasila macu |
| `gameover` | potrosila svih 5 srca |

### Rezolucija i izgled

Viewport je 960×540 (bio 640×360) sa linearnim filtriranjem i MSAA 2× —
manje pikselizovano, ivice glatke. Kamera ima `zoom = 1.7` da likovi ostanu
krupni, i `offset.y = 12` da se vidi tlo ispod Eve, ne prazno nebo.

Ako zelis **jos** manje pikselizovano: digni viewport na 1280×720 u
`project.godot` i zoom na ~2.3 u [scenes/eva.tscn](scenes/eva.tscn).
Ako zelis natrag tvrdi pixel-art: `default_texture_filter=0` i `msaa_2d=0`.

### Winning screen

Kad Eva dodirne kavez: Čarli skače od sreće, pa se posle 1.2s pojavi panel sa
**"BRAVO EVA! / Spasila si macu Čarlija"**, brojem zvezdica (`17 / 29`) i
vremenom (`2:35`). Brojač se animirano namotava, konfeti padaju.

- Tekst i naslov: [scenes/win_screen.tscn](scenes/win_screen.tscn)
- Animacija i logika: [scripts/win_screen.gd](scripts/win_screen.gd)
- Konfeti: [scripts/confetti.gd](scripts/confetti.gd) — 110 komada, boje likova
- Merenje vremena: `elapsed_string()` u [autoload/game.gd](autoload/game.gd)

Sat starta u `reset_run()` i staje u `stop_timer()` kad spasi macu. `R` restartuje.

### Snimljeni glas na pobednickom ekranu

Igra sama trazi fajl `audio/voice_win.wav` (radi i `.ogg` / `.mp3`). Ako postoji,
pusta se na pobednickom ekranu i muzika se utisa dok govori. Ako ga nema,
sve radi kao i pre (sinteticka fanfara) — **fajl nije obavezan**.

**Najlaksi nacin (Voice Memos):**

1. Otvori **Voice Memos** (u Launchpadu), pritisni crveni krug, izgovori npr.
   *"Bravo Eva! Spasila si macu Čarlija!"*, pa stop.
2. Desni klik na snimak → **Share** → **Save to Files** → sacuvaj na Desktop.
3. Konvertuj i ubaci u igru:

```bash
ffmpeg -i ~/Desktop/snimak.m4a -ac 1 -ar 44100 -c:a pcm_s16le audio/voice_win.wav
```

**Ili QuickTime Player:** File → New Audio Recording → snimi → sacuvaj, pa ista
`ffmpeg` komanda (samo promeni ime ulaznog fajla).

**Ili direktno iz terminala** (snima 4 sekunde sa ugradjenog mikrofona):

```bash
ffmpeg -f avfoundation -i ":default" -t 4 -ac 1 -ar 44100 -c:a pcm_s16le audio/voice_win.wav
```

Posle toga pokreni igru — u konzoli treba da vidis
`Audio: snimljeni glas ucitan (res://audio/voice_win.wav, 2.4s)`.

**Saveti:**

- Drzi snimak **do ~4 sekunde**. Duze i dete izgubi paznju.
- Snimaj u tihoj sobi, 20-30 cm od mikrofona.
- Ako je preglasan/pretih, promeni `VOICE_DB` u [autoload/audio.gd](autoload/audio.gd)
  (sada `-1.0`; manji broj = tise).
- Da se vrati fanfara: samo obrisi `audio/voice_win.wav` (i `.import` fajl).
- Eva moze i sama da snimi sebe — to je cesto zabavnije od tvog glasa.

### Detalji na assetima

Svi likovi i objekti su prepravljeni sa mnogo vise poligona — sitniji pikseli,
ali isti pixel-art stil (ortogonalne ivice, ravne boje):

| Asset | Bilo | Sada | Sta je dodato |
|---|---|---|---|
| Eva | 13 | 52 | **duga kosa do pojasa** (pada iza haljine), mašna, zenice sa odsjajem, obrve, karneri, čarape, prsti. Lice bez rumenih obraza — usta i nos u neutralnim tonovima |
| Budžumbora | 12 | 57 | **modelovana po pravoj lutki sa fotografije**: narandžasta kosa kao kapa sa čupercima na vrhu i rolnama sa strane, velike bež uši, roze haljina bez rukava sa bretelama, krupne cipele sa svetloroze pertlama, petlja za kačenje, obrve i trepavice, rumeni obrazi, usta kao tanka bordo J-linija |
| Čarli (maca) | 16 | 58 | pruge na telu i repu, brkovi, šape sa prstima, ogrlica sa privezkom, katanac na kavezu |
| Puž | 5 | 25 | spiralna školjka sa slojevima, oči na stabljikama, sluzav trag |
| Kornjača | 7 | 32 | šestougaone ploče oklopa, kljun, kandže, kapak |
| Zvezdica | 3 | 10 | tri sloja sjaja, jezgro, tri iskrice |
| Cvet | 7 | 24 | 8 latica u dva sloja, žilice na listovima, prašnici |

Platforme se generišu kodom u [scripts/main.gd](scripts/main.gd) (`_add_platform`) —
trava u tri sloja sa vlatima koje vire, zemlja u tri sloja, kamenčići i korenje.
Detalji su deterministicki (seed iz pozicije platforme), pa svaka izgleda
drugacije ali isto pri svakom pokretanju. Boje su konstante `C_SOIL`, `C_GRASS`…
na vrhu funkcije.

### Izgled likova
Likovi su `Polygon2D` oblici u scenama, ne slike — menjas boju jednim klikom:

- Evina kosa: `HairBack` + `HairFringe` u [scenes/eva.tscn](scenes/eva.tscn)
- Evine oci: `EyeL` / `EyeR`, sada `Color(0.25, 0.55, 0.9)` = plava
- Budzumborina haljina: `Dress` u [scenes/budzumbora.tscn](scenes/budzumbora.tscn)

Ako kasnije zelis prave sprite-ove: [kenney.nl](https://kenney.nl) ima besplatne
CC0 platformer pakete (bez atribucije, bez licence).

## Struktura

```
autoload/game.gd      globalno stanje + SVA podesavanja tezine
scripts/
  main.gd             gradi nivo iz tabela, vodi tok igre
  eva.gd              kontroler igraca (coyote time, jump buffer, squash)
  budzumbora.gd       lutka pratilac + magnet za zvezdice
  animal.gd           zivotinje (deljeno za puza i kornjacu)
  star.gd  checkpoint.gd  maca.gd  hud.gd
scenes/               .tscn scene za svaki objekat
```

## Sledeci koraci (ideje)

- Zvuk: skok, zvezdica, mjaukanje mace (Godot: `AudioStreamPlayer`)
- Vise nivoa: kopiraj tabele iz `main.gd` u `levels/level2.gd`
- Web export: Godot → Project → Export → Web. Dobijes HTML koji Eva
  otvori u browseru na tabletu, bez instalacije.
- Eva da sama crta nivoe: prebaci `PLATFORMS` u TileMap i pusti je da slika misem.
