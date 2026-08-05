extends Node
## Globalno stanje igre + sva podesavanja tezine na jednom mestu.
## Ovo je autoload, dostupan svuda kao `Game`.

# --- TEZINA: ovo su brojke koje menjas kad Eva igra ---
# Sve je namerno "lako": veliki skok, sporo padanje, puno vremena za gresku.

const PLAYER_SPEED := 150.0          # brzina hodanja (px/s)
const PLAYER_JUMP_VELOCITY := -370.0 # jacina skoka (negativno = gore)
const PLAYER_GRAVITY_SCALE := 0.72   # <1 = sporije padanje, vise vremena u vazduhu

## Coyote time: koliko dugo posle silaska sa platforme skok jos radi.
## Dete cesto pritisne skok tek kad je vec palo sa ivice - ovo to prasta.
const COYOTE_TIME := 0.18

## Jump buffer: ako pritisne skok malo pre sletanja, skok se pamti i odradi.
const JUMP_BUFFER_TIME := 0.20

## Neranjivost posle udarca - dovoljno duga da dete stigne da se izmakne.
const INVULN_TIME := 2.0

const MAX_HEARTS := 5                # broj zivota (Mario ima 1-2, mi dajemo 5)

## Kad padne u rupu ili je pogodjena: vraca se na poslednji checkpoint,
## NE na pocetak nivoa. Ovo je najvaznija stvar za dete.
const RESPAWN_DELAY := 0.6

## Ukupan broj zvezdica u nivou - postavlja main.gd pri gradnji,
## da winning screen moze da prikaze "12 / 29".
var total_stars: int = 0

# --- NIVOI I MAPA SVETA ---

## Definicija svih nivoa. `scene` je prazan za nivoe koji jos ne postoje -
## na mapi se prikazuju kao zatvorene tacke ("Uskoro").
##
## Kad napravis nov nivo: napisi scenu i upisi putanju u `scene`.
## Sve ostalo (mapa, putevi, otkljucavanje) radi samo.
## OSTRVA - definisana odvojeno od nivoa, jer na jednom ostrvu moze da
## bude vise nivoa. `biome` odredjuje kako ostrvo izgleda.
const ISLANDS: Array[Dictionary] = [
	{"id": "livada",   "name": "Zelena livada",   "biome": "livada",
	 "pos": Vector2(340, 700),   "size": Vector2(760, 520)},
	{"id": "plaza",    "name": "Sunčana plaža",   "biome": "plaza",
	 "pos": Vector2(1180, 300),  "size": Vector2(700, 470)},
	{"id": "dzungla",  "name": "Divlja džungla",  "biome": "dzungla",
	 "pos": Vector2(1900, 880),  "size": Vector2(800, 540)},
	{"id": "pustinja", "name": "Zlatna pustinja", "biome": "pustinja",
	 "pos": Vector2(2760, 300),  "size": Vector2(740, 490)},
	{"id": "sneg",     "name": "Ledeni vrhovi",   "biome": "sneg",
	 "pos": Vector2(3560, 880),  "size": Vector2(760, 510)},
	{"id": "vulkan",   "name": "Vatrena gora",    "biome": "vulkan",
	 "pos": Vector2(4400, 340),  "size": Vector2(720, 500)},
]

## NIVOI. `island` je id ostrva; `pos` je pozicija tacke.
## Nivoi na ISTOM ostrvu spajaju se KOPNENIM putem (Eva ide peske).
## Nivoi na RAZLICITIM ostrvima spajaju se MORSKIM putem (brodicem).
##
## Kad napravis nov nivo: upisi `scene`. Prazan `scene` = "uskoro".
const LEVELS: Array[Dictionary] = [
	# --- Zelena livada: 3 nivoa ---
	{"id": "livada_1", "name": "Prvi koraci", "scene": "res://scenes/main.tscn",
	 "island": "livada", "pos": Vector2(140, 640)},
	{"id": "livada_2", "name": "Preko potoka", "scene": "",
	 "island": "livada", "pos": Vector2(380, 810)},
	{"id": "livada_3", "name": "Kroz šumu", "scene": "",
	 "island": "livada", "pos": Vector2(600, 620)},

	# --- Sunčana plaža: 2 nivoa ---
	{"id": "plaza_1", "name": "Peščana staza", "scene": "",
	 "island": "plaza", "pos": Vector2(990, 260)},
	{"id": "plaza_2", "name": "Palmin gaj", "scene": "",
	 "island": "plaza", "pos": Vector2(1340, 380)},

	# --- Divlja džungla: 3 nivoa ---
	{"id": "dzungla_1", "name": "Gusto lišće", "scene": "",
	 "island": "dzungla", "pos": Vector2(1660, 800)},
	{"id": "dzungla_2", "name": "Skrivena reka", "scene": "",
	 "island": "dzungla", "pos": Vector2(1930, 990)},
	{"id": "dzungla_3", "name": "Visoke krošnje", "scene": "",
	 "island": "dzungla", "pos": Vector2(2180, 790)},

	# --- Zlatna pustinja: 2 nivoa ---
	{"id": "pustinja_1", "name": "Vruće dine", "scene": "",
	 "island": "pustinja", "pos": Vector2(2560, 260)},
	{"id": "pustinja_2", "name": "Kaktus polje", "scene": "",
	 "island": "pustinja", "pos": Vector2(2950, 380)},

	# --- Ledeni vrhovi: 2 nivoa ---
	{"id": "sneg_1", "name": "Snežna staza", "scene": "",
	 "island": "sneg", "pos": Vector2(3360, 830)},
	{"id": "sneg_2", "name": "Ledena pećina", "scene": "",
	 "island": "sneg", "pos": Vector2(3750, 950)},

	# --- Vatrena gora: 2 nivoa ---
	{"id": "vulkan_1", "name": "Crna staza", "scene": "",
	 "island": "vulkan", "pos": Vector2(4210, 300)},
	{"id": "vulkan_2", "name": "Vrh vulkana", "scene": "",
	 "island": "vulkan", "pos": Vector2(4580, 420)},
]

## Koji su nivoi zavrseni - kljuc je `id` iz LEVELS.
var completed: Dictionary = {}

## Najbolji rezultat po nivou: { id: {"stars": int, "time": float} }
var best: Dictionary = {}

## Koji nivo se trenutno igra (indeks u LEVELS).
var current_level: int = 0


func level_count() -> int:
	return LEVELS.size()


func island_count() -> int:
	return ISLANDS.size()


func island_data(index: int) -> Dictionary:
	if index < 0 or index >= ISLANDS.size():
		return {}
	return ISLANDS[index]


## Ostrvo na kome je dati nivo.
func island_of(level_index: int) -> Dictionary:
	var d := level_data(level_index)
	if not d.has("island"):
		return {}
	for isl in ISLANDS:
		if isl["id"] == d["island"]:
			return isl
	return {}


## Da li su dva nivoa na istom ostrvu? Ako jesu, put je KOPNENI.
func same_island(a: int, b: int) -> bool:
	var da := level_data(a)
	var db := level_data(b)
	return da.has("island") and db.has("island") and da["island"] == db["island"]


func level_data(index: int) -> Dictionary:
	if index < 0 or index >= LEVELS.size():
		return {}
	return LEVELS[index]


## Nivo postoji ako ima scenu. Ostali su "uskoro".
func level_exists(index: int) -> bool:
	var d := level_data(index)
	return d.has("scene") and String(d["scene"]) != ""


## Nivo je otkljucan ako je prvi, ili ako je prethodni zavrsen.
func level_unlocked(index: int) -> bool:
	if index <= 0:
		return true
	var prev := level_data(index - 1)
	return prev.has("id") and completed.has(prev["id"])


func level_completed(index: int) -> bool:
	var d := level_data(index)
	return d.has("id") and completed.has(d["id"])


## Upisi rezultat i zapamti najbolji (najvise zvezdica, pa najkrace vreme).
func mark_completed(index: int, stars: int, seconds: float) -> void:
	var d := level_data(index)
	if not d.has("id"):
		return
	var id: String = d["id"]
	completed[id] = true

	var prev: Dictionary = best.get(id, {})
	var better := prev.is_empty() \
		or stars > int(prev.get("stars", -1)) \
		or (stars == int(prev.get("stars", -1)) and seconds < float(prev.get("time", 1e9)))
	if better:
		best[id] = {"stars": stars, "time": seconds}


func best_for(index: int) -> Dictionary:
	var d := level_data(index)
	if not d.has("id"):
		return {}
	return best.get(d["id"], {})


# --- CUVANJE NAPRETKA ---
# Na webu ide u IndexedDB (Godot to radi sam za user://), pa napredak
# prezivi zatvaranje browsera.

const SAVE_PATH := "user://progress.json"


func _ready() -> void:
	load_progress()


func save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"completed": completed, "best": best}))
	f.close()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d: Dictionary = data
	if d.has("completed") and typeof(d["completed"]) == TYPE_DICTIONARY:
		completed = d["completed"]
	if d.has("best") and typeof(d["best"]) == TYPE_DICTIONARY:
		best = d["best"]


## Za testiranje: obrisi napredak.
func reset_progress() -> void:
	completed.clear()
	best.clear()
	save_progress()

# --- Stanje tokom igre ---
var hearts: int = MAX_HEARTS
var stars_collected: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false

# --- Merenje vremena ---
var _run_started_ms: int = 0
var _run_finished_ms: int = 0
var _timing := false

signal hearts_changed(value: int)
signal stars_changed(value: int)
signal level_won
signal player_died   # potroseni svi zivoti


func reset_run() -> void:
	hearts = MAX_HEARTS
	stars_collected = 0
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
	_run_started_ms = Time.get_ticks_msec()
	_run_finished_ms = 0
	_timing = true
	hearts_changed.emit(hearts)
	stars_changed.emit(stars_collected)


## Zaustavi sat - zove se kad spasi macu.
func stop_timer() -> void:
	if _timing:
		_run_finished_ms = Time.get_ticks_msec()
		_timing = false


## Proteklo vreme u sekundama. Posle zavrsetka vraca fiksno vreme.
func elapsed_seconds() -> float:
	var end_ms := _run_finished_ms if not _timing else Time.get_ticks_msec()
	return float(end_ms - _run_started_ms) / 1000.0


## Vreme kao "2:35" - format koji dete moze da procita.
func elapsed_string() -> String:
	var total := int(elapsed_seconds())
	return "%d:%02d" % [total / 60, total % 60]


func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	has_checkpoint = true


func add_star() -> void:
	stars_collected += 1
	stars_changed.emit(stars_collected)


func take_damage() -> void:
	hearts -= 1
	hearts_changed.emit(hearts)
	if hearts <= 0:
		player_died.emit()


## Nagrada umesto kazne: skupljanje zvezdica vraca srce.
func maybe_reward_heart() -> void:
	if stars_collected > 0 and stars_collected % 10 == 0 and hearts < MAX_HEARTS:
		hearts += 1
		hearts_changed.emit(hearts)
