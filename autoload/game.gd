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
