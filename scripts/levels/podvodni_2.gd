extends MinigamePick
## NIVO — "Uklopi oblike" (Podvodni grad)
##
## Na dnu su tri otvora razlicitog oblika (krug, kvadrat, trougao). Gore je
## jedan oblik. Dete dodirne otvor u koji taj oblik ulazi.
##
## Za petogodisnjaka: oblik je VELIK i obojen isto kao pravi otvor bi bio
## previse lako - zato su svi otvori iste boje, a razlikuje se samo OBLIK.
## Pogresan izbor samo zatrese otvor, bez kazne.

## Koliko oblika treba uklopiti da se prijatelj oslobodi.
##
## `var`, ne `const`: mocvara_2 nasledjuje ovaj nivo i dize broj rundi.
## GDScript ne dozvoljava da se const prepise u nasledniku.
var rounds := 5

## Oblici koji se koriste. Redosled u nizu = redosled otvora na ekranu.
const SHAPES: Array[String] = ["krug", "kvadrat", "trougao", "zvezda"]

const SLOT_Y := 150.0
const SLOT_STEP := 240.0
const SHAPE_R := 74.0

var _round := 0
## Koji oblik se trazi u ovoj rundi (indeks u SHAPES).
var _want := 0
## Redosled oblika za sve runde - randomizovan pri svakom pokretanju.
var _order: Array[int] = []
var _stage: Node2D
var _slots: Array[Node2D] = []
var _piece: Node2D


func _setup() -> void:
	friend_kind = "morskikonj"
	biome = "podvodni"
	task_text = "Gde ide ovaj oblik?"
	set_total_steps(rounds)

	# Randomizuj redosled: dete ne sme da nauci "prvo krug, pa kvadrat".
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_order.clear()
	var last := -1
	for i in rounds:
		var pick := rng.randi_range(0, SHAPES.size() - 1)
		# Ne dva ista zaredom - inace dete dva puta dodirne isto mesto.
		while pick == last:
			pick = rng.randi_range(0, SHAPES.size() - 1)
		last = pick
		_order.append(pick)


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)
	_build_slots()
	_next_round()
	_fit()
	get_viewport().size_changed.connect(_fit)


func _fit() -> void:
	# Sadrzaj: cetiri otvora u redu + oblik gore.
	fit_stage(_stage, Vector2(SLOT_STEP * float(SHAPES.size()) + 120.0, 620.0))


## Otvori na dnu - svi iste boje, razlikuje se samo oblik.
func _build_slots() -> void:
	var x0 := -SLOT_STEP * float(SHAPES.size() - 1) * 0.5
	for i in SHAPES.size():
		var slot := Node2D.new()
		slot.position = Vector2(x0 + float(i) * SLOT_STEP, SLOT_Y)
		_stage.add_child(slot)
		_slots.append(slot)

		# Ram oko otvora - da se vidi da je to "kutija".
		Draw2D.poly(slot, Color(0.3, 0.5, 0.56), [
			Vector2(-100, -100), Vector2(100, -100),
			Vector2(100, 100), Vector2(-100, 100)])
		Draw2D.poly(slot, Color(0.42, 0.66, 0.7), [
			Vector2(-94, -94), Vector2(94, -94),
			Vector2(94, 94), Vector2(-94, 94)])
		# Sam otvor - tamna "praznina" u obliku.
		_draw_shape(slot, SHAPES[i], SHAPE_R, Color(0.16, 0.28, 0.34))

		# Zona za dodir je cela kutija (100px), znatno veca od crteza.
		add_target(slot, 118.0)


## Nacrtaj oblik. Isti kod crta i otvor i komad koji pada - tako se
## garantuje da se poklapaju.
func _draw_shape(parent: Node2D, kind: String, r: float, col: Color) -> void:
	match kind:
		"krug":
			Draw2D.circle(parent, Vector2.ZERO, r, col, 18)
		"kvadrat":
			Draw2D.poly(parent, col, [
				Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)])
		"trougao":
			Draw2D.poly(parent, col, [
				Vector2(0, -r), Vector2(r, r * 0.8), Vector2(-r, r * 0.8)])
		"zvezda":
			var pts := PackedVector2Array()
			for k in 10:
				var a := TAU * float(k) / 10.0 - PI * 0.5
				var rr: float = r if k % 2 == 0 else r * 0.45
				pts.append(Vector2(cos(a), sin(a)) * rr)
			Draw2D.poly(parent, col, pts)


## Sledeca runda: prikazi novi oblik gore.
func _next_round() -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.queue_free()

	_want = _order[_round]
	_piece = Node2D.new()
	_piece.position = Vector2(0, -190.0)
	_stage.add_child(_piece)

	# Komad je JARKE boje - vidi se da je to "on", a otvori su tamni.
	_draw_shape(_piece, SHAPES[_want], SHAPE_R * 0.86, Color(0.98, 0.78, 0.3))
	_draw_shape(_piece, SHAPES[_want], SHAPE_R * 0.55, Color(1, 0.9, 0.55))

	# Lagano se njise - privlaci pogled na to sta treba uklopiti.
	# set_loops() ide POSLE tween_property, inace Godot prijavljuje
	# "Infinite loop detected" (naucili smo na pahuljama u sneg_2).
	var tw := create_tween()
	tw.tween_property(_piece, "position:y", -206.0, 0.9) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_piece, "position:y", -190.0, 0.9) \
		.set_trans(Tween.TRANS_SINE)
	tw.set_loops()


func _on_pick(index: int) -> void:
	if index != _want:
		shake(_slots[index])
		return

	busy = true
	pop(_slots[index])
	mark_ok(_slots[index], Vector2(0, -128.0))

	# Komad "upadne" u otvor.
	var target: Vector2 = _slots[index].position
	var tw := create_tween()
	tw.tween_property(_piece, "position", target, 0.32) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_piece, "modulate:a", 0.0, 0.18)
	await tw.finished

	step_done()
	_round += 1
	if _round >= rounds:
		win()
		return

	busy = false
	_next_round()
