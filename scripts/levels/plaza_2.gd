extends LevelBase
## NIVO 5 — "Palmin gaj" (Sunčana plaža)
##
## Eva dobija PLIVANJE. Voda vise nije opasna nego PUT - preko dubokih
## zaliva se ne moze skokom, samo plivanjem.
##
## Peščane platforme, palme u pozadini, more koje se prostire ispod.
## Eva spasava pticu Cvrkuta.


func _setup() -> void:
	biome = "plaza"
	start = Vector2(40, -40)
	fall_limit = 420.0
	power = "swim"
	set_friend(Vector2(2560, -44), "ptica")

	set_decor(_draw_beach)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Eva ume da pliva!\nDrži SPACE u vodi"


func _build_terrain() -> void:
	# --- Deo 1: pesak, uci se da voda nije opasna ---
	add_ground(Rect2(0, 0, 280, 60), "sand")
	add_ground(Rect2(200, -60, 60, 16), "wood")

	# Prvi zaliv - plitak, moze i skokom, ali plivanje je lakse.
	add_water(Rect2(280, 0, 160, 70))
	add_ground(Rect2(440, 0, 220, 60), "sand")
	add_ground(Rect2(500, -68, 56, 16), "wood")

	# --- Deo 2: DUBOK zaliv - samo plivanjem ---
	add_water(Rect2(660, 0, 320, 130))
	# Ostrvce u sredini zaliva - odmor.
	add_ground(Rect2(790, -20, 70, 20), "sand")
	add_ground(Rect2(980, 0, 200, 60), "sand")

	# --- Deo 3: stepenice uz palme ---
	add_ground(Rect2(1180, -50, 70, 16), "wood")
	add_ground(Rect2(1310, -96, 70, 16), "wood")
	add_ground(Rect2(1450, -50, 70, 16), "wood")
	add_ground(Rect2(1580, 0, 180, 60), "sand")

	# --- Deo 4: plivanje ispod platforme ---
	add_water(Rect2(1760, 0, 300, 120))
	add_ground(Rect2(1860, -90, 90, 16), "wood")
	add_ground(Rect2(2060, 0, 180, 60), "sand")

	# --- Deo 5: finale ---
	add_water(Rect2(2240, 0, 140, 80))
	add_ground(Rect2(2380, 0, 320, 60), "sand")
	add_ground(Rect2(2460, -76, 60, 16), "wood")


func _build_stars() -> void:
	add_star(Vector2(120, -34))
	add_star(Vector2(228, -92))
	# Zvezdice U VODI - vode dete da pliva.
	add_star_line(Vector2(320, 20), Vector2(410, 20), 3)
	add_star(Vector2(528, -100))
	# Duboki zaliv: zvezdice po dubini.
	add_star_line(Vector2(700, 30), Vector2(770, 60), 3)
	add_star(Vector2(824, -52))
	add_star_line(Vector2(880, 60), Vector2(950, 24), 3)
	add_star(Vector2(1060, -34))
	add_star(Vector2(1214, -82))
	add_star(Vector2(1344, -128))
	add_star(Vector2(1344, -160))
	add_star(Vector2(1484, -82))
	add_star(Vector2(1660, -34))
	add_star_line(Vector2(1800, 30), Vector2(1900, 50), 3)
	add_star(Vector2(1904, -122))
	add_star_line(Vector2(1960, 40), Vector2(2030, 20), 3)
	add_star(Vector2(2140, -34))
	add_star_line(Vector2(2270, 24), Vector2(2350, 24), 2)
	add_star(Vector2(2490, -108))
	add_star(Vector2(2540, -140))


func _build_animals() -> void:
	add_animal("puz", Vector2(500, -32))
	add_animal("kornjaca", Vector2(1040, -32))
	add_animal("puz", Vector2(1640, -32))
	add_animal("kornjaca", Vector2(2120, -32))
	add_animal("puz", Vector2(2440, -32))


func _build_checkpoints() -> void:
	for p in [Vector2(60, -36), Vector2(470, -36), Vector2(1010, -36),
			Vector2(1610, -36), Vector2(2090, -36), Vector2(2410, -36)]:
		add_checkpoint(p)


## Plaza: palme u pozadini, more na horizontu, sunce.
func _draw_beach(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5205

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# More na horizontu - visoko iza, uzak pojas da ne pokrije nebo.
	_poly(bg, Color(0.5, 0.75, 0.9, 0.45), [
		Vector2(-100, -300), Vector2(2800, -300),
		Vector2(2800, -250), Vector2(-100, -250)])
	_poly(bg, Color(0.78, 0.92, 0.99, 0.45), [
		Vector2(-100, -302), Vector2(2800, -302),
		Vector2(2800, -295), Vector2(-100, -295)])

	# Sunce - visoko na nebu.
	_circle(bg, Vector2(360, -400), 42.0, Color(1, 0.92, 0.55, 0.45))
	_circle(bg, Vector2(360, -400), 30.0, Color(1, 0.96, 0.7, 0.75))

	# Palme u dva sloja.
	for i in 26:
		var x := rng.randf_range(-40.0, 2760.0)
		var h := rng.randf_range(80.0, 150.0)
		var far := rng.randf() > 0.5
		var alpha := 0.45 if far else 0.8
		var s := 0.7 if far else 1.0

		var lean := rng.randf_range(-8.0, 8.0)
		# Stablo.
		_poly(bg, Color(0.62, 0.46, 0.28, maxf(alpha, 0.7)), [
			Vector2(x - 5 * s, 20), Vector2(x + 5 * s, 20),
			Vector2(x + lean + 3 * s, -h), Vector2(x + lean - 3 * s, -h)])
		# Krosnja: prvo puna masa (da se vidi izdaleka), pa listovi preko.
		var top := Vector2(x + lean, -h)
		var leaf := Color(0.26, 0.58, 0.32, maxf(alpha, 0.8))
		var leaf2 := Color(0.34, 0.68, 0.38, maxf(alpha, 0.8))
		_circle(bg, top + Vector2(0, -6 * s), 26.0 * s, leaf)

		for k in 7:
			var a := TAU * float(k) / 7.0 + rng.randf_range(-0.15, 0.15)
			var tip := top + Vector2(cos(a) * 46 * s, sin(a) * 26 * s - 10 * s)
			var mid := top + Vector2(cos(a) * 24 * s, sin(a) * 13 * s - 14 * s)
			# Sirok list - vidi se i na malom ekranu.
			_poly(bg, leaf if k % 2 == 0 else leaf2, [
				top + Vector2(-7 * s, 0), mid + Vector2(0, -6 * s), tip,
				mid + Vector2(0, 12 * s), top + Vector2(7 * s, 3 * s)])
		# Kokosi.
		for k in 2:
			_circle(bg, top + Vector2(rng.randf_range(-9, 9) * s, 6 * s),
				5.0 * s, Color(0.45, 0.32, 0.2, alpha))


func _circle(parent: Node2D, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)


func _poly(parent: Node, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)
