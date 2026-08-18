extends MinigamePick
## NIVO — "Nađi različito" (Kristalna pećina)
##
## Cetiri kristala; tri su ista, jedan je drugaciji. Dete dodirne onaj koji
## ne pripada.
##
## Za petogodisnjaka razlika je UVEK jedna i JASNA - ili boja, ili velicina,
## ili oblik. Nikad kombinacija ("manji I druge boje"), jer se onda ne zna
## sta je zapravo trazeno.

var rounds := 5
## Koliko kristala je u redu. Cetiri: sa vise se meta smanjuje ispod granice
## za detinji prst.
var slots := 4

const SLOT_STEP := 230.0
const BASE_R := 78.0

## Po cemu se razlikuje "uljez" u ovoj rundi.
enum Diff {BOJA, VELICINA, OBLIK}

var _round := 0
var _odd := 0
var _stage: Node2D
var _items: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()


func _setup() -> void:
	friend_kind = "slepimis"
	biome = "pecina"
	task_text = "Koji je različit?"
	set_total_steps(rounds)
	_rng.randomize()


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)
	_fit()
	get_viewport().size_changed.connect(_fit)
	_next_round()


func _fit() -> void:
	fit_stage(_stage, Vector2(SLOT_STEP * float(slots) + 120.0, 420.0))


func _next_round() -> void:
	for it in _items:
		if is_instance_valid(it):
			it.queue_free()
	_items.clear()
	clear_targets()

	_odd = _rng.randi_range(0, slots - 1)
	var mode: int = _rng.randi_range(0, 2)

	# Osnovna boja/oblik za "iste" kristale.
	var base_col := Color(0.6, 0.82, 0.96)
	var odd_col := Color(0.98, 0.6, 0.4)
	var base_shape := _rng.randi_range(0, 2)
	var odd_shape := (base_shape + 1 + _rng.randi_range(0, 1)) % 3

	var x0 := -SLOT_STEP * float(slots - 1) * 0.5
	for i in slots:
		var it := Node2D.new()
		it.position = Vector2(x0 + float(i) * SLOT_STEP, 30.0)
		_stage.add_child(it)
		_items.append(it)

		var is_odd := i == _odd
		var col := base_col
		var r := BASE_R
		var shape := base_shape
		if is_odd:
			match mode:
				Diff.BOJA:     col = odd_col
				Diff.VELICINA: r = BASE_R * 0.58
				Diff.OBLIK:    shape = odd_shape

		_draw_crystal(it, shape, r, col)
		# Zona za dodir je uvek ista, i za mali kristal - inace bi "manji"
		# bio i teze pogodiv, sto nije poenta zadatka.
		add_target(it, SLOT_STEP * 0.46)


## Kristal u tri oblika: siljat, sestougao, kupola.
func _draw_crystal(parent: Node2D, shape: int, r: float, col: Color) -> void:
	var dark := col.darkened(0.28)
	match shape:
		0:
			# Siljat - prizma.
			Draw2D.poly(parent, dark, [
				Vector2(-r * 0.7, r), Vector2(0, -r * 1.25),
				Vector2(r * 0.7, r)])
			Draw2D.poly(parent, col, [
				Vector2(-r * 0.45, r * 0.85), Vector2(0, -r * 1.1),
				Vector2(r * 0.45, r * 0.85)])
			Draw2D.poly(parent, Color(1, 1, 1, 0.4), [
				Vector2(-r * 0.16, r * 0.8), Vector2(0, -r * 1.05),
				Vector2(r * 0.08, r * 0.8)])
		1:
			# Sestougao.
			var pts := PackedVector2Array()
			for k in 6:
				var a := TAU * float(k) / 6.0 - PI * 0.5
				pts.append(Vector2(cos(a), sin(a)) * r)
			Draw2D.poly(parent, dark, pts)
			var pts2 := PackedVector2Array()
			for k in 6:
				var a := TAU * float(k) / 6.0 - PI * 0.5
				pts2.append(Vector2(cos(a), sin(a)) * (r - 9.0))
			Draw2D.poly(parent, col, pts2)
			Draw2D.circle(parent, Vector2(-r * 0.28, -r * 0.3), r * 0.2,
				Color(1, 1, 1, 0.45), 10)
		_:
			# Kupola - zaobljena gore, ravna dole.
			var pts3 := PackedVector2Array()
			for k in 11:
				var a: float = PI + PI * float(k) / 10.0
				pts3.append(Vector2(cos(a) * r, sin(a) * r))
			pts3.append(Vector2(r, r * 0.5))
			pts3.append(Vector2(-r, r * 0.5))
			Draw2D.poly(parent, dark, pts3)
			Draw2D.circle(parent, Vector2(0, -r * 0.1), r * 0.7, col, 16)
			Draw2D.circle(parent, Vector2(-r * 0.25, -r * 0.35), r * 0.22,
				Color(1, 1, 1, 0.45), 10)


func _on_pick(index: int) -> void:
	if index != _odd:
		shake(_items[index])
		return

	busy = true
	pop(_items[index])
	mark_ok(_items[index], Vector2(0, -BASE_R - 40.0))
	step_done()
	_round += 1
	if _round >= rounds:
		await get_tree().create_timer(0.6).timeout
		win()
		return
	await get_tree().create_timer(0.75).timeout
	busy = false
	_next_round()
