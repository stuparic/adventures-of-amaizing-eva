extends MinigameBase
## NIVO — "Lavirint do rakete" (Zvezdana stanica)
##
## Dete VUCE prstom astronauta kroz lavirint do rakete. Ne bira jednu od
## meta, pa ovo ne nasledjuje MinigamePick.
##
## Za petogodisnjaka:
##   - lavirint je MALI (5x5) i put je uvek jednostavan, bez slepih uglova
##     koji vracaju na pocetak
##   - prevlacenje se prati po CELIJAMA, ne po pikselima: prst mora samo da
##     dodje blizu sledece celije, ne da prati tanku liniju
##   - u zid se ne moze uci - prst prosto ne pomera astronauta
##   - nema greske i nema kazne; ne moze se "izgubiti"
##   - svaka nova celija je jedan korak (zvezdica), pa se napredak vidi

## Lavirint: 1 = zid, 0 = prolaz. S = start, E = izlaz.
## Tri mape - jedna se bira slucajno, da drugi put nije isti put.
const MAZES: Array = [
	[
		"S0011",
		"11001",
		"10001",
		"10111",
		"1000E",
	],
	[
		"S1111",
		"00001",
		"11101",
		"10101",
		"1010E",
	],
	[
		"S0001",
		"11101",
		"10001",
		"10111",
		"1000E",
	],
]

const CELL := 116.0

var _grid: Array[String] = []
var _stage: Node2D
var _hero: Node2D
var _at := Vector2i.ZERO
var _exit := Vector2i.ZERO
var _visited: Dictionary = {}
var _dragging := false


func _setup() -> void:
	friend_kind = "robot"
	biome = "svemir"
	task_text = "Vuci prstom do rakete!"
	# Koraci se racunaju po posecenim celijama; tacan broj se zna posle
	# izbora lavirinta, pa se postavlja u _ready().
	set_total_steps(1)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pick: Array = MAZES[rng.randi_range(0, MAZES.size() - 1)]
	for row in pick:
		_grid.append(String(row))

	# Ukupno koraka = broj DOSTUPNIH celija bez starta.
	#
	# Mora dostupnih, ne svih prohodnih: lavirint 1 ima dva prolaza koja su
	# zatvorena zidovima, pa bi sa "svih prohodnih" HUD zauvek pokazivao
	# 9/11 i dete nikad ne bi videlo pun rezultat. Provereno BFS-om.
	set_total_steps(maxi(_reachable_count() - 1, 1))

	super()

	_stage = Node2D.new()
	add_child(_stage)
	_build_maze()
	_build_hero()
	_fit()
	get_viewport().size_changed.connect(_fit)


## Koliko celija se moze DOCI od starta (BFS).
##
## Koristi se za broj koraka - vidi komentar u _ready().
func _reachable_count() -> int:
	var start := Vector2i(-1, -1)
	for y in _grid.size():
		for x in _grid[y].length():
			if _grid[y][x] == "S":
				start = Vector2i(x, y)
	if start.x < 0:
		return 1

	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if _walkable(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen.size()


func _fit() -> void:
	if _stage == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var w := CELL * float(_grid[0].length())
	var h := CELL * float(_grid.size())
	var s := minf((vp.x - 80.0) / w, (vp.y - 150.0) / h)
	_stage.scale = Vector2(minf(s, 1.0), minf(s, 1.0))


func _cell_pos(c: Vector2i) -> Vector2:
	var w := float(_grid[0].length())
	var h := float(_grid.size())
	return Vector2(
		(float(c.x) - (w - 1.0) * 0.5) * CELL,
		(float(c.y) - (h - 1.0) * 0.5) * CELL)


func _build_maze() -> void:
	for y in _grid.size():
		for x in _grid[y].length():
			var ch: String = _grid[y][x]
			var p := _cell_pos(Vector2i(x, y))
			if ch == "1":
				# Zid - metalni blok stanice.
				Draw2D.poly(_stage, Color(0.3, 0.3, 0.42), [
					p + Vector2(-CELL * 0.5, -CELL * 0.5),
					p + Vector2(CELL * 0.5, -CELL * 0.5),
					p + Vector2(CELL * 0.5, CELL * 0.5),
					p + Vector2(-CELL * 0.5, CELL * 0.5)])
				Draw2D.poly(_stage, Color(0.42, 0.42, 0.56), [
					p + Vector2(-CELL * 0.5 + 6, -CELL * 0.5 + 6),
					p + Vector2(CELL * 0.5 - 6, -CELL * 0.5 + 6),
					p + Vector2(CELL * 0.5 - 6, CELL * 0.5 - 6),
					p + Vector2(-CELL * 0.5 + 6, CELL * 0.5 - 6)])
				# Zakivci - da zid izgleda kao metal.
				for k in 4:
					var dx: float = -CELL * 0.28 + float(k % 2) * CELL * 0.56
					var dy: float = -CELL * 0.28 + float(k / 2) * CELL * 0.56
					Draw2D.circle(_stage, p + Vector2(dx, dy), 4.0,
						Color(0.28, 0.28, 0.38), 8)
			else:
				# Prolaz - tamni pod sa svetlim obodom.
				Draw2D.poly(_stage, Color(0.16, 0.17, 0.26), [
					p + Vector2(-CELL * 0.5, -CELL * 0.5),
					p + Vector2(CELL * 0.5, -CELL * 0.5),
					p + Vector2(CELL * 0.5, CELL * 0.5),
					p + Vector2(-CELL * 0.5, CELL * 0.5)])
				if ch == "S":
					_at = Vector2i(x, y)
					_visited[_at] = true
				elif ch == "E":
					_exit = Vector2i(x, y)
					_draw_rocket(p)


## Raketa na izlazu - cilj koji dete odmah prepozna.
func _draw_rocket(p: Vector2) -> void:
	Draw2D.poly(_stage, Color(0.95, 0.96, 0.99), [
		p + Vector2(-16, 18), p + Vector2(16, 18),
		p + Vector2(13, -14), p + Vector2(-13, -14)])
	Draw2D.poly(_stage, Color(0.9, 0.35, 0.4), [
		p + Vector2(-13, -14), p + Vector2(13, -14), p + Vector2(0, -40)])
	Draw2D.poly(_stage, Color(0.72, 0.75, 0.86), [
		p + Vector2(-16, 18), p + Vector2(-27, 30), p + Vector2(-16, 6)])
	Draw2D.poly(_stage, Color(0.72, 0.75, 0.86), [
		p + Vector2(16, 18), p + Vector2(27, 30), p + Vector2(16, 6)])
	Draw2D.circle(_stage, p + Vector2(0, -4), 7.0, Color(0.5, 0.85, 0.98), 12)
	# Plamen - pulsira, privlaci pogled na cilj.
	var fire := Node2D.new()
	fire.position = p + Vector2(0, 24)
	_stage.add_child(fire)
	Draw2D.poly(fire, Color(0.99, 0.7, 0.25), [
		Vector2(-9, 0), Vector2(9, 0), Vector2(0, 22)])
	Draw2D.poly(fire, Color(0.98, 0.9, 0.5), [
		Vector2(-5, 0), Vector2(5, 0), Vector2(0, 13)])
	var tw := create_tween()
	tw.tween_property(fire, "scale", Vector2(1.0, 1.35), 0.35) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(fire, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_SINE)
	tw.set_loops()


func _build_hero() -> void:
	_hero = Node2D.new()
	_hero.position = _cell_pos(_at)
	_hero.z_index = 5
	_stage.add_child(_hero)
	# Astronaut: kaciga, vizir, telo.
	Draw2D.circle(_hero, Vector2(0, 0), 34.0, Color(0.95, 0.96, 0.99), 16)
	Draw2D.circle(_hero, Vector2(0, -2), 25.0, Color(0.3, 0.55, 0.8), 14)
	Draw2D.circle(_hero, Vector2(-8, -10), 8.0, Color(1, 1, 1, 0.55), 10)
	Draw2D.poly(_hero, Color(0.88, 0.9, 0.95), [
		Vector2(-20, 26), Vector2(20, 26), Vector2(16, 40), Vector2(-16, 40)])
	# Pulsira da dete vidi "ovo se pomera".
	var tw := create_tween()
	tw.tween_property(_hero, "scale", Vector2(1.08, 1.08), 0.6) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_hero, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_SINE)
	tw.set_loops()


func _walkable(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= _grid.size():
		return false
	if c.x < 0 or c.x >= _grid[c.y].length():
		return false
	return _grid[c.y][c.x] != "1"


## Prevlacenje: prati se CELIJA pod prstom, ne piksel.
##
## Dete ne moze da prati tanku liniju, pa se astronaut pomera kad prst
## dodje blizu susedne prohodne celije. Pomera se po jednom koraku
## (gore/dole/levo/desno), nikad dijagonalno kroz ugao zida.
func _input(event: InputEvent) -> void:
	if _done:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			if mb.pressed:
				_try_move_to(mb.position)
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_dragging = st.pressed
		if st.pressed:
			_try_move_to(st.position)
		return
	if event is InputEventMouseMotion and _dragging:
		_try_move_to((event as InputEventMouseMotion).position)
		return
	if event is InputEventScreenDrag:
		_try_move_to((event as InputEventScreenDrag).position)


func _try_move_to(screen_pos: Vector2) -> void:
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var local: Vector2 = _stage.to_local(world)

	# Koja je celija najbliza prstu?
	var w := float(_grid[0].length())
	var h := float(_grid.size())
	var cx := int(round(local.x / CELL + (w - 1.0) * 0.5))
	var cy := int(round(local.y / CELL + (h - 1.0) * 0.5))
	var target := Vector2i(cx, cy)
	if target == _at:
		return

	# Samo jedan korak, samo pravo - ne dijagonalno.
	var d := target - _at
	if absi(d.x) + absi(d.y) != 1:
		return
	if not _walkable(target):
		return

	_at = target
	var tw := create_tween()
	tw.tween_property(_hero, "position", _cell_pos(_at), 0.11)

	# Nova celija = jedan korak napretka. Vracanje unazad se ne racuna
	# ponovo, inace dete "farmira" zvezdice sara-tamo-nazad.
	if not _visited.has(_at):
		_visited[_at] = true
		# Trag - dete vidi kuda je proslo.
		Draw2D.circle(_stage, _cell_pos(_at), 9.0, Color(0.6, 0.85, 0.6, 0.5), 10)
		step_done()

	if _at == _exit:
		_finish()


func _finish() -> void:
	_dragging = false
	var tw := create_tween()
	tw.tween_property(_hero, "scale", Vector2(1.4, 1.4), 0.2) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_hero, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.5).timeout
	win()
