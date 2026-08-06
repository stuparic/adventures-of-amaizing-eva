extends MinigameBase
## NIVO 2 — "Spoji zvezdice" (Zelena livada)
##
## Dete dodiruje zvezdice po redu (1, 2, 3...). Linija se crta izmedju
## njih i otkriva oblik. Kad spoji sve, zeka Baki je slobodan.
##
## Za petogodisnjaka: brojevi su veliki, sledeca zvezdica pulsira i
## svetli, a pogresna se samo zatrese (nema kazne).

## Tacke crteza - oblik zeka. Redosled je redosled spajanja.
const SCALE := 1.9
const SHAPE: Array[Vector2] = [
	Vector2(-30, 60),    # 1  stopalo levo
	Vector2(30, 60),     # 2  stopalo desno
	Vector2(46, 10),     # 3  bok desno
	Vector2(34, -34),    # 4  rame desno
	Vector2(52, -74),    # 5  uvo desno gore
	Vector2(30, -108),   # 6  vrh uva desno
	Vector2(14, -66),    # 7  glava desno
	Vector2(-14, -66),   # 8  glava levo
	Vector2(-30, -108),  # 9  vrh uva levo
	Vector2(-52, -74),   # 10 uvo levo gore
	Vector2(-34, -34),   # 11 rame levo
	Vector2(-46, 10),    # 12 bok levo
]

const DOT_R := 19.0

var _dots: Array[Node2D] = []
var _next := 0
var _lines: Node2D


func _setup() -> void:
	friend_kind = "zeka"
	task_text = "Dodirni zvezdice po redu: 1, 2, 3..."
	set_total_steps(SHAPE.size())


func _ready() -> void:
	super()
	_lines = Node2D.new()
	_lines.z_index = 1
	add_child(_lines)
	_build_dots()
	_highlight_next()


## Zvezdica sa brojem. Klik proverava da li je na redu.
func _build_dots() -> void:
	# Crtez je u centru ekrana, malo nize od prijatelja.
	var origin := Vector2(0, 60)

	for i in SHAPE.size():
		var pos: Vector2 = origin + SHAPE[i] * SCALE

		var dot := Node2D.new()
		dot.position = pos
		dot.z_index = 2
		add_child(dot)
		_dots.append(dot)

		# Zvezdica: obod, ispuna, sjaj.
		_star_poly(dot, DOT_R, Color(0.85, 0.68, 0.15))
		_star_poly(dot, DOT_R - 4.0, Color(1, 0.88, 0.35))
		_star_poly(dot, DOT_R - 12.0, Color(1, 0.97, 0.75))

		# Broj u sredini.
		var lbl := Label.new()
		lbl.text = str(i + 1)
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.35, 0.26, 0.1))
		lbl.size = Vector2(DOT_R * 2, DOT_R * 2)
		lbl.position = Vector2(-DOT_R, -DOT_R + 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(lbl)

		# Dugme za klik/dodir - velika zona, dete ne mora precizno.
		var btn := Button.new()
		btn.flat = true
		# Klik zona je NAMERNO mnogo veca od zvezdice - detinji prst
		# je neprecizan. 78px pokriva i promasaj od 2cm.
		btn.size = Vector2(78, 78)
		btn.position = Vector2(-39, -39)
		btn.focus_mode = Control.FOCUS_NONE
		var idx := i
		btn.pressed.connect(func() -> void: _on_dot(idx))
		dot.add_child(btn)


func _on_dot(index: int) -> void:
	if index != _next:
		# Pogresna - samo zatresi, bez kazne.
		_shake(_dots[index])
		Audio.play("land", 0.15)
		return

	# Tacna: povuci liniju od prethodne.
	if _next > 0:
		_draw_line(_dots[_next - 1].position, _dots[_next].position)

	_mark_done(_dots[index])
	step_done()
	_next += 1

	if _next >= SHAPE.size():
		# Zatvori oblik i pokazi zeku.
		_draw_line(_dots[_dots.size() - 1].position, _dots[0].position)
		_fill_shape()
		win()
	else:
		_highlight_next()


## Sledeca zvezdica pulsira - dete zna gde da dodirne.
func _highlight_next() -> void:
	if _next >= _dots.size():
		return
	var d := _dots[_next]
	var tw := create_tween().set_loops()
	tw.tween_property(d, "scale", Vector2(1.22, 1.22), 0.45) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(d, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
	d.set_meta("tween", tw)


func _mark_done(d: Node2D) -> void:
	var tw: Variant = d.get_meta("tween", null)
	if tw != null and tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	d.scale = Vector2.ONE
	# Spojena zvezdica postaje zelena - vidljiv napredak.
	for child in d.get_children():
		if child is Polygon2D:
			(child as Polygon2D).color = (child as Polygon2D).color.lerp(
				Color(0.4, 0.8, 0.45), 0.65)
	var pop := create_tween()
	pop.tween_property(d, "scale", Vector2(1.4, 1.4), 0.12)
	pop.tween_property(d, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC)


func _draw_line(a: Vector2, b: Vector2) -> void:
	var dir := (b - a).normalized()
	var n := Vector2(-dir.y, dir.x) * 4.0
	# Obod pa ispuna - linija se vidi na svakoj podlozi.
	_poly(_lines, Color(1, 1, 1, 0.9), [a + n * 1.7, b + n * 1.7, b - n * 1.7, a - n * 1.7])
	_poly(_lines, Color(0.95, 0.45, 0.6), [a + n, b + n, b - n, a - n])


## Kad je oblik zatvoren, oboji ga - dete vidi sta je nacrtalo.
func _fill_shape() -> void:
	var pts := PackedVector2Array()
	for d in _dots:
		pts.append(d.position)
	var fill := Polygon2D.new()
	fill.color = Color(0.98, 0.85, 0.9, 0.0)
	fill.polygon = pts
	fill.z_index = -1
	add_child(fill)

	# Ispuna kratko zasija (dete vidi sta je nacrtalo), pa se sve skloni
	# da zeka ima cist ekran za proslavu.
	var tw := create_tween()
	tw.tween_property(fill, "color", Color(0.99, 0.86, 0.92, 0.9), 0.5)
	tw.tween_interval(0.5)
	tw.tween_property(fill, "color", Color(0.99, 0.86, 0.92, 0.0), 0.5)
	tw.parallel().tween_property(_lines, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_callback(_fade_dots)


## Skloni zvezdice - proslava treba cist ekran.
func _fade_dots() -> void:
	for d in _dots:
		var t := create_tween()
		t.tween_property(d, "modulate:a", 0.0, 0.45)
		t.parallel().tween_property(d, "scale", Vector2(0.4, 0.4), 0.45)


func _shake(d: Node2D) -> void:
	var base := d.position
	var tw := create_tween()
	for i in 2:
		tw.tween_property(d, "position", base + Vector2(6, 0), 0.05)
		tw.tween_property(d, "position", base - Vector2(6, 0), 0.05)
	tw.tween_property(d, "position", base, 0.05)


## --- Helperi ---

func _star_poly(parent: Node2D, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0 - PI * 0.5
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cos(a), sin(a)) * rr)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)


func _poly(parent: Node, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)
