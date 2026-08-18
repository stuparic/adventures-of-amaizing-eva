extends MinigamePick
## NIVO — "Ponovi redosled" (Ostrvo u oblacima)
##
## Cetiri obojena zvona zasvetle jedno po jedno; dete ih onda dodirne u
## istom redosledu. Duzina niza raste: 2, 3, 4...
##
## Za petogodisnjaka:
##   - zvono i SVETLI i PORASTE kad je na redu, pa se prati i bez pamcenja boja
##   - svako zvono ima svoj ton, pa se niz pamti i po zvuku
##   - greska NE vraca na pocetak igre, samo ponavlja isti niz
##   - posle greske se niz ponovo odsvira, dete ne mora da pogadja

## Boje zvona. Cetiri su granica za petogodisnjaka - sa vise se niz ne pamti.
const BELLS: Array[Color] = [
	Color(0.95, 0.45, 0.5),
	Color(0.45, 0.72, 0.95),
	Color(0.98, 0.82, 0.35),
	Color(0.5, 0.82, 0.55),
]

## Zvuci po zvonu - razlicita visina daje "melodiju" koja pomaze pamcenju.
const PITCH: Array[float] = [0.8, 1.0, 1.2, 1.45]

## Koliko nizova treba pogoditi. Prvi ima 2 clana, svaki sledeci +1.
var rounds := 4
var first_len := 2

const BELL_R := 92.0
const BELL_STEP := 230.0

var _round := 0
var _seq: Array[int] = []
var _at := 0
var _stage: Node2D
var _bells: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()


func _setup() -> void:
	friend_kind = "zmaj"
	biome = "oblaci"
	task_text = "Gledaj pa ponovi!"
	set_total_steps(rounds)
	_rng.randomize()


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)
	_build_bells()
	_fit()
	get_viewport().size_changed.connect(_fit)
	_next_round()


func _fit() -> void:
	fit_stage(_stage, Vector2(BELL_STEP * float(BELLS.size()) + 120.0, 460.0))


func _build_bells() -> void:
	var x0 := -BELL_STEP * float(BELLS.size() - 1) * 0.5
	for i in BELLS.size():
		var b := Node2D.new()
		b.position = Vector2(x0 + float(i) * BELL_STEP, 40.0)
		_stage.add_child(b)
		_bells.append(b)

		# Zvono: senka, telo, sjaj. Poligoni, ne slika.
		Draw2D.circle(b, Vector2(4, 6), BELL_R, Color(0.3, 0.35, 0.45, 0.25), 18)
		Draw2D.circle(b, Vector2.ZERO, BELL_R, BELLS[i].darkened(0.25), 18)
		var face := Draw2D.circle(b, Vector2.ZERO, BELL_R - 9.0, BELLS[i], 18)
		face.name = "Face"
		Draw2D.circle(b, Vector2(-28, -32), 22.0, Color(1, 1, 1, 0.4), 14)

		add_target(b, BELL_R + 26.0)


## Novi niz: prethodni ostaje, dodaje se jedan clan - kao pravi Simon.
func _next_round() -> void:
	_seq.clear()
	var want := first_len + _round
	var last := -1
	for i in want:
		var pick := _rng.randi_range(0, BELLS.size() - 1)
		# Ne dva ista zaredom: dva dodira na isto mesto dete cita kao jedan.
		while pick == last:
			pick = _rng.randi_range(0, BELLS.size() - 1)
		last = pick
		_seq.append(pick)
	_at = 0
	await _play_sequence()


## Odsviraj niz - zvono svetli, raste i zvoni.
func _play_sequence() -> void:
	busy = true
	await get_tree().create_timer(0.5).timeout
	for idx in _seq:
		await _flash(idx)
		await get_tree().create_timer(0.22).timeout
	busy = false


func _flash(index: int) -> void:
	var b := _bells[index]
	Audio.play("star", 0.0)
	# Pitch se ne moze podesiti kroz Audio.play (prima samo varijaciju),
	# pa se "melodija" pravi razlicitim rastom - vizuelni ritam je ovde
	# vazniji od tona za dete koje jos ne razlikuje visine.
	var face := b.get_node_or_null("Face") as Polygon2D
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.24, 1.24), 0.16) \
		.set_trans(Tween.TRANS_BACK)
	if face != null:
		tw.parallel().tween_property(face, "color",
			BELLS[index].lightened(0.55), 0.16)
	tw.tween_property(b, "scale", Vector2.ONE, 0.24)
	if face != null:
		tw.parallel().tween_property(face, "color", BELLS[index], 0.24)
	await tw.finished


func _on_pick(index: int) -> void:
	if index != _seq[_at]:
		# Greska: zatresi, pa PONOVO odsviraj isti niz. Bez vracanja na
		# pocetak - petogodisnjak bi to primio kao kaznu i odustao.
		shake(_bells[index])
		_at = 0
		await get_tree().create_timer(0.5).timeout
		await _play_sequence()
		return

	pop(_bells[index])
	Audio.play("checkpoint", 0.1)
	_at += 1
	if _at < _seq.size():
		return

	# Ceo niz pogodjen.
	busy = true
	mark_ok(_bells[index], Vector2(0, -BELL_R - 18.0))
	step_done()
	_round += 1
	if _round >= rounds:
		await get_tree().create_timer(0.5).timeout
		win()
		return
	await get_tree().create_timer(0.7).timeout
	_next_round()
