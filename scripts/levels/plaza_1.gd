extends MinigameBase
## NIVO 4 — "Oboji školjku" (Sunčana plaža)
##
## Dete bira boju sa palete pa dodiruje polja slike. Kad su sva polja
## obojena, delfin Plisko je slobodan.
##
## Za petogodisnjaka: neobojeno polje je BELO sa isprekidanim obodom, pa
## se vidi sta je ostalo. Nema "pogresne" boje - bilo koja se prima.
## Izabrana boja na paleti je uvecana i ima beli prsten.

## Paleta - sest boja, velike kuglice.
const PALETTE: Array[Color] = [
	Color(0.98, 0.45, 0.55),   # roze
	Color(1, 0.78, 0.28),      # zlatna
	Color(0.45, 0.78, 0.95),   # nebo
	Color(0.5, 0.82, 0.5),     # zelena
	Color(0.78, 0.55, 0.95),   # ljubicasta
	Color(1, 0.62, 0.35),      # narandzasta
]

## Polja skoljke: [tacke poligona]. Skoljka je lepeza sa 7 rebara
## plus telo - dovoljno polja da bojenje traje, ne previse da zamori.
const FIELDS: Array = [
	# Telo skoljke (dno).
	[Vector2(-92, 60), Vector2(92, 60), Vector2(74, 96), Vector2(-74, 96)],
	# Sedam rebara lepeze, od leve ka desnoj.
	[Vector2(-92, 58), Vector2(-104, -24), Vector2(-72, -30), Vector2(-58, 58)],
	[Vector2(-58, 58), Vector2(-72, -32), Vector2(-40, -62), Vector2(-28, 58)],
	[Vector2(-28, 58), Vector2(-40, -64), Vector2(-14, -86), Vector2(-6, 58)],
	[Vector2(-6, 58), Vector2(-14, -88), Vector2(14, -88), Vector2(6, 58)],
	[Vector2(6, 58), Vector2(14, -86), Vector2(40, -64), Vector2(28, 58)],
	[Vector2(28, 58), Vector2(40, -62), Vector2(72, -32), Vector2(58, 58)],
	[Vector2(58, 58), Vector2(72, -30), Vector2(104, -24), Vector2(92, 58)],
]

const ORIGIN := Vector2(40, 30)

var _fields: Array[Polygon2D] = []
var _outlines: Array[Node2D] = []
var _painted: Array[bool] = []
var _chosen := 0
var _swatches: Array[Node2D] = []


func _setup() -> void:
	friend_kind = "delfin"
	biome = "plaza"
	task_text = "Izaberi boju pa oboji školjku!"
	set_total_steps(FIELDS.size())


func _ready() -> void:
	super()
	_build_shell()
	_build_palette()
	_highlight_swatch()


## Klik/dodir se obradjuje OVDE, ne preko Area2D.input_event.
##
## Zasto: Area2D.input_event zavisi od Godotovog physics object picking-a,
## koji ovde nije radio - polja i paleta nisu reagovala ni na desktopu.
## Merenjem je potvrdjeno da su Area2D cvorovi ispravno postavljeni
## (pickable=true, layer=1, handler povezan, tacne pozicije) i da bojenje
## radi kad se handler pozove direktno - ali klik do njega nikad ne dodje.
##
## Geometrijska provera je pouzdanija: uzmi poziciju klika, prevedi je u
## svetske koordinate i vidi u kom je poligonu. Ne zavisi od fizike,
## slojeva kolizije ni pickinga, i radi isto na misu i na dodiru.
func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		pos = mb.position
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			return
		pos = st.position
	else:
		return

	# Ekranska -> svetska koordinata (uzima u obzir kameru i zoom).
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * pos

	# Paleta ima prioritet: kuglice su iznad slike i manje su meta.
	for i in _swatches.size():
		if world.distance_to(_swatches[i].position) <= 44.0:
			_choose(i)
			get_viewport().set_input_as_handled()
			return

	# Pa polja skoljke.
	for i in FIELDS.size():
		var pts := PackedVector2Array()
		for v in FIELDS[i]:
			pts.append(ORIGIN + (v as Vector2))
		if Geometry2D.is_point_in_polygon(world, pts):
			_paint(i)
			get_viewport().set_input_as_handled()
			return


## Skoljka: svako polje je klikabilno, pocinje belo sa isprekidanim obodom.
func _build_shell() -> void:
	# Senka ispod skoljke - lezi na pesku.
	var shadow := Polygon2D.new()
	shadow.color = Color(0.6, 0.52, 0.38, 0.25)
	var sp := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		sp.append(ORIGIN + Vector2(0, 86) + Vector2(cos(a) * 104, sin(a) * 20))
	shadow.polygon = sp
	shadow.z_index = -1
	add_child(shadow)

	for i in FIELDS.size():
		var pts := PackedVector2Array()
		for v in FIELDS[i]:
			pts.append(ORIGIN + (v as Vector2))

		# Polje - pocinje skoro belo.
		var poly := Polygon2D.new()
		poly.color = Color(0.99, 0.98, 0.96)
		poly.polygon = pts
		poly.z_index = 1
		add_child(poly)
		_fields.append(poly)
		_painted.append(false)

		# Isprekidan obod - vidi se sta je jos neobojeno.
		var outline := Node2D.new()
		outline.z_index = 3
		add_child(outline)
		_draw_dashed_outline(outline, pts)
		_outlines.append(outline)

		# Bez Area2D: klik se obradjuje u _input() geometrijski, jer
		# physics object picking ovde nije dostavljao input_event.


## Paleta boja - kuglice dole, dovoljno velike za detinji prst.
func _build_palette() -> void:
	var y := 210.0
	var step := 78.0
	var x0 := ORIGIN.x - step * float(PALETTE.size() - 1) * 0.5

	for i in PALETTE.size():
		var pos := Vector2(x0 + step * float(i), y)

		var sw := Node2D.new()
		sw.position = pos
		sw.z_index = 4
		add_child(sw)
		_swatches.append(sw)

		# Senka, beli prsten, boja, sjaj.
		_circle(sw, Vector2(2, 4), 30.0, Color(0.4, 0.35, 0.3, 0.2))
		_circle(sw, Vector2.ZERO, 30.0, Color(1, 1, 1, 0.95))
		_circle(sw, Vector2.ZERO, 25.0, PALETTE[i])
		_circle(sw, Vector2(-8, -9), 8.0, Color(1, 1, 1, 0.45))

		# Bez klik cvora: _input() proverava rastojanje do centra kuglice
		# (44px = 88px meta, velika za detinji prst).
		#
		# Ranije je ovde bio Button, ali Button je Control - njegova
		# pozicija je u EKRANSKOM prostoru i ne prolazi kroz canvas
		# transform kamere. Kuglica je Node2D u svetu na (79, 210), a
		# dugme je zavrsavalo na ekranskim (38, 169), van kuglice.
		# Zamena Area2D-om nije pomogla jer physics picking nije
		# dostavljao input_event.


func _choose(index: int) -> void:
	_chosen = index
	Audio.play("checkpoint", 0.12)
	_highlight_swatch()


## Izabrana boja je veca - dete vidi cime boji.
func _highlight_swatch() -> void:
	for i in _swatches.size():
		var target := Vector2(1.25, 1.25) if i == _chosen else Vector2(0.92, 0.92)
		var tw := create_tween()
		tw.tween_property(_swatches[i], "scale", target, 0.18) \
			.set_trans(Tween.TRANS_BACK)


func _paint(index: int) -> void:
	if index < 0 or index >= _fields.size():
		return

	var col := PALETTE[_chosen]
	var was_new := not _painted[index]

	# Prebojavanje je dozvoljeno - dete moze da menja boju.
	var tw := create_tween()
	tw.tween_property(_fields[index], "color", col, 0.2)

	# Kratki "pop" da se vidi koje polje je obojeno.
	var pop := create_tween()
	pop.tween_property(_fields[index], "scale", Vector2(1.04, 1.04), 0.08)
	pop.tween_property(_fields[index], "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_ELASTIC)

	if not was_new:
		Audio.play("star", 0.15)
		return

	_painted[index] = true
	# Obod nestaje - polje je "gotovo".
	var fade := create_tween()
	fade.tween_property(_outlines[index], "modulate:a", 0.0, 0.3)

	step_done()

	# Sva polja obojena?
	for done in _painted:
		if not done:
			return
	_finish()


func _finish() -> void:
	# Skoljka poraste i zasija - dete vidi svoj rad.
	var group: Array[Node] = []
	for f in _fields:
		group.append(f)

	for f in _fields:
		var tw := create_tween()
		tw.tween_property(f, "scale", Vector2(1.12, 1.12), 0.4) \
			.set_trans(Tween.TRANS_BACK)

	# Paleta se skloni.
	for sw in _swatches:
		var t := create_tween()
		t.tween_property(sw, "modulate:a", 0.0, 0.35)
		t.parallel().tween_property(sw, "position:y", sw.position.y + 40.0, 0.35)

	await get_tree().create_timer(0.5).timeout

	# Skoljka izblede pa proslava.
	for f in _fields:
		var t := create_tween()
		t.tween_property(f, "modulate:a", 0.0, 0.4)
	for o in _outlines:
		var t := create_tween()
		t.tween_property(o, "modulate:a", 0.0, 0.3)

	win()


## Isprekidan obod oko poligona - pokazuje sta je jos neobojeno.
func _draw_dashed_outline(parent: Node2D, pts: PackedVector2Array) -> void:
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var seg := a.distance_to(b)
		var dir := (b - a).normalized()
		var nrm := Vector2(-dir.y, dir.x) * 2.0
		var d := 0.0
		while d < seg:
			var l := minf(9.0, seg - d)
			if l < 2.0:
				break
			var p1 := a + dir * d
			var p2 := a + dir * (d + l)
			_poly(parent, Color(0.55, 0.5, 0.45, 0.8),
				[p1 + nrm, p2 + nrm, p2 - nrm, p1 - nrm])
			d += 16.0


func _circle(parent: Node2D, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_poly(parent, col, pts)


func _poly(parent: Node, col: Color, pts: Variant) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts if pts is PackedVector2Array else PackedVector2Array(pts)
	parent.add_child(p)
