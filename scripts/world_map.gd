extends Node2D
## Mapa sveta - level picker. Tacke po klimatskim predelima, spojene putevima.
##
## Nivoi se citaju iz Game.LEVELS. Nivo koji jos nema scenu prikazuje se kao
## zatvorena tacka sa oznakom "Uskoro" - kad mu upises scenu, sam se otvori.
##
## Kontrole: strelice/A-D birају, SPACE/Enter ulazi. Radi i klik/dodir.

const DOT_R := 30.0            # poluprecnik tacke nivoa
const ROAD_W := 7.0            # sirina puta
const DASH := 15.0             # duzina crtice na putu

const C_ROAD := Color(0.82, 0.72, 0.55)
const C_ROAD_DONE := Color(0.98, 0.85, 0.35)
const C_LOCKED := Color(0.62, 0.62, 0.66)
const C_TEXT := Color(0.22, 0.3, 0.42)

const StarIcon := preload("res://scenes/hud_star.tscn")

@onready var camera: Camera2D = $Camera
@onready var title: Label = $UI/Title
@onready var info: Label = $UI/Info
@onready var eva_marker: Node2D = $EvaMarker

var _selected := 0
var _dots: Array[Node2D] = []
var _t := 0.0
var _entering := false


func _ready() -> void:
	# Startuj na prvom neodigranom nivou - dete odmah vidi gde je stalo.
	_selected = _first_playable()
	_build_map()
	_update_selection()
	Audio.play_music()


func _first_playable() -> int:
	for i in Game.level_count():
		if Game.level_unlocked(i) and Game.level_exists(i) and not Game.level_completed(i):
			return i
	# Sve odigrano (ili nista nije dostupno) - vrati poslednji otkljucan.
	for i in range(Game.level_count() - 1, -1, -1):
		if Game.level_unlocked(i):
			return i
	return 0


## --- Gradnja mape ---

func _build_map() -> void:
	var roads := Node2D.new()
	roads.name = "Roads"
	# z_index umesto move_child: move_child(0) bi gurnuo putevi IZA
	# pozadine (Sea/Land) i ne bi se videli. z_index radi nad terenom.
	roads.z_index = 1
	add_child(roads)

	for i in Game.level_count() - 1:
		_add_road(roads, i)

	for i in Game.level_count():
		_add_dot(i)


## Put izmedju dve tacke - isprekidan, kao na turistickoj mapi.
## Zlatan ako je nivo pre njega zavrsen, inace bez boje.
func _add_road(parent: Node2D, from_index: int) -> void:
	var a: Vector2 = Game.level_data(from_index)["map_pos"]
	var b: Vector2 = Game.level_data(from_index + 1)["map_pos"]

	var dir := (b - a).normalized()
	var dist := a.distance_to(b)
	var done := Game.level_completed(from_index)
	var col := C_ROAD_DONE if done else C_ROAD

	# Pocni i zavrsi izvan tacaka da crtice ne ulaze u krug.
	var start := DOT_R + 8.0
	var d := start
	while d < dist - start:
		var seg := minf(DASH, dist - start - d)
		if seg <= 1.0:
			break
		var p1 := a + dir * d
		var p2 := a + dir * (d + seg)
		var n := Vector2(-dir.y, dir.x) * (ROAD_W * 0.5)

		var poly := Polygon2D.new()
		poly.color = col
		poly.polygon = PackedVector2Array([p1 + n, p2 + n, p2 - n, p1 - n])
		parent.add_child(poly)

		d += DASH * 2.0


## Tacka nivoa: krug u boji klime, broj, i ime ispod.
func _add_dot(index: int) -> void:
	var data := Game.level_data(index)
	var pos: Vector2 = data["map_pos"]
	var exists := Game.level_exists(index)
	var unlocked := Game.level_unlocked(index)
	var done := Game.level_completed(index)

	var dot := Node2D.new()
	dot.name = "Dot%d" % index
	dot.position = pos
	dot.z_index = 2
	add_child(dot)
	_dots.append(dot)

	# Senka pod tackom - daje dubinu.
	var shadow := _circle(DOT_R + 3.0, Color(0.2, 0.25, 0.3, 0.18))
	shadow.position = Vector2(2, 4)
	dot.add_child(shadow)

	# Spoljni prsten: zlatan ako je zavrsen, siv ako je zatvoren.
	var ring_col := C_ROAD_DONE if done else (Color(1, 1, 1, 0.9) if unlocked and exists else C_LOCKED)
	dot.add_child(_circle(DOT_R, ring_col))

	# Unutrasnjost u boji klime. Zatvoreni su sivi.
	var fill: Color = data["color"]
	if not (unlocked and exists):
		fill = Color(0.72, 0.72, 0.75)
	dot.add_child(_circle(DOT_R - 5.0, fill))

	# Sjaj gore levo - da krug ne bude ravan.
	var shine := _circle(DOT_R * 0.42, Color(1, 1, 1, 0.28))
	shine.position = Vector2(-DOT_R * 0.3, -DOT_R * 0.32)
	dot.add_child(shine)

	# Oznaka u tacki. NE koristi emoji (lock, check) - Godotov web font ih
	# nema, prikazuju se kao prazne kockice. Katanac crtam poligonima.
	if not (exists and unlocked):
		_add_lock(dot)
	elif done:
		# ★ kao znak ne postoji u web fontu - crtaj poligon.
		var st := StarIcon.instantiate() as Node2D
		st.scale = Vector2(1.15, 1.15)
		dot.add_child(st)
	else:
		var mark := Label.new()
		mark.text = str(index + 1)
		mark.add_theme_font_size_override("font_size", 26)
		mark.add_theme_color_override("font_color", C_TEXT)
		mark.add_theme_constant_override("outline_size", 5)
		mark.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		mark.size = Vector2(DOT_R * 2, DOT_R * 2)
		mark.position = Vector2(-DOT_R, -DOT_R + 4)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.add_child(mark)

	# Ime predela ispod tacke.
	var name_label := Label.new()
	name_label.text = String(data["name"])
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", C_TEXT if (exists and unlocked) else Color(0.5, 0.5, 0.56))
	name_label.add_theme_constant_override("outline_size", 6)
	name_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.85))
	name_label.size = Vector2(190, 26)
	name_label.position = Vector2(-95, DOT_R + 7)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.add_child(name_label)

	# "Uskoro" za nivoe koji jos ne postoje.
	if not exists:
		var soon := Label.new()
		soon.text = "uskoro"
		soon.add_theme_font_size_override("font_size", 13)
		soon.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
		soon.add_theme_constant_override("outline_size", 5)
		soon.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		soon.size = Vector2(190, 20)
		soon.position = Vector2(-95, DOT_R + 27)
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.add_child(soon)

	# Klik/dodir na tacku.
	var btn := Button.new()
	btn.flat = true
	btn.size = Vector2(DOT_R * 2 + 16, DOT_R * 2 + 16)
	btn.position = Vector2(-DOT_R - 8, -DOT_R - 8)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		if _selected == index:
			_enter_level()
		else:
			_selected = index
			_update_selection()
			Audio.play("checkpoint")
	)
	dot.add_child(btn)



## Katanac od poligona (emoji ne radi u Godotovom web fontu).
func _add_lock(parent: Node2D) -> void:
	var shackle := Polygon2D.new()
	shackle.color = Color(0.48, 0.48, 0.54)
	shackle.polygon = PackedVector2Array([
		Vector2(-5, -2), Vector2(-5, -8), Vector2(-2.5, -11), Vector2(2.5, -11),
		Vector2(5, -8), Vector2(5, -2), Vector2(2.5, -2), Vector2(2.5, -7.5),
		Vector2(1.5, -8.5), Vector2(-1.5, -8.5), Vector2(-2.5, -7.5), Vector2(-2.5, -2),
	])
	parent.add_child(shackle)

	var body := Polygon2D.new()
	body.color = Color(0.58, 0.58, 0.63)
	body.polygon = PackedVector2Array([
		Vector2(-8, -2), Vector2(8, -2), Vector2(8, 11), Vector2(-8, 11),
	])
	parent.add_child(body)

	var hole := Polygon2D.new()
	hole.color = Color(0.34, 0.34, 0.38)
	hole.polygon = PackedVector2Array([
		Vector2(-1.8, 2), Vector2(1.8, 2), Vector2(1.8, 6.5), Vector2(-1.8, 6.5),
	])
	parent.add_child(hole)

## Krug od poligona - Godot nema gotov "circle node" za 2D popunu.
func _circle(r: float, col: Color, segments := 26) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	return p


## --- Izbor nivoa ---

func _process(delta: float) -> void:
	_t += delta

	# Eva na izabranoj tacki, lagano poskakuje.
	if _selected < _dots.size():
		var target: Vector2 = _dots[_selected].position + Vector2(0, -DOT_R - 26.0)
		target.y += sin(_t * 3.0) * 4.0
		eva_marker.position = eva_marker.position.lerp(target, delta * 7.0)

	# Pulsiranje izabrane tacke.
	for i in _dots.size():
		var s := 1.0
		if i == _selected:
			s = 1.0 + sin(_t * 4.0) * 0.06
		_dots[i].scale = _dots[i].scale.lerp(Vector2(s, s), delta * 8.0)


func _unhandled_input(event: InputEvent) -> void:
	if _entering:
		return

	if event.is_action_pressed("move_right"):
		_move_selection(1)
	elif event.is_action_pressed("move_left"):
		_move_selection(-1)
	elif event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_enter_level()


func _move_selection(step: int) -> void:
	var next := clampi(_selected + step, 0, Game.level_count() - 1)
	if next == _selected:
		return
	_selected = next
	_update_selection()
	Audio.play("checkpoint")


func _update_selection() -> void:
	var data := Game.level_data(_selected)
	title.text = String(data.get("name", ""))

	if not Game.level_exists(_selected):
		info.text = "Ovaj predeo se pravi..."
	elif not Game.level_unlocked(_selected):
		info.text = "Zavrsi prethodni nivo"
	else:
		var b := Game.best_for(_selected)
		if b.is_empty():
			info.text = "SPACE ili dodir = igraj"
		else:
			info.text = "Najbolje: %d zvezdica   vreme %d:%02d" % [
				int(b.get("stars", 0)),
				int(b.get("time", 0.0)) / 60,
				int(b.get("time", 0.0)) % 60,
			]

	# Kamera prati izbor po x - mapa je sira od ekrana.
	if _selected < _dots.size():
		camera.position.x = _dots[_selected].position.x


func _enter_level() -> void:
	if _entering:
		return

	if not Game.level_exists(_selected):
		info.text = "Ovaj predeo se pravi..."
		Audio.play("hurt")
		_shake(_dots[_selected])
		return

	if not Game.level_unlocked(_selected):
		info.text = "Zavrsi prethodni nivo"
		Audio.play("hurt")
		_shake(_dots[_selected])
		return

	_entering = true
	Audio.play("star")
	Game.current_level = _selected
	Audio.stop_music()

	var path := String(Game.level_data(_selected)["scene"])
	get_tree().change_scene_to_file(path)


## Zatresi tacku kad je nedostupna - jasan "ne moze" bez teksta.
func _shake(node: Node2D) -> void:
	var base := node.position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(node, "position", base + Vector2(7, 0), 0.05)
		tw.tween_property(node, "position", base - Vector2(7, 0), 0.05)
	tw.tween_property(node, "position", base, 0.05)
