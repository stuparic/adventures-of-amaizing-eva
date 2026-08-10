extends LevelBase
## NIVO 13 — "Vrh vulkana" (Vulkan) — POSLEDNJI NIVO
##
## Finale: nivo ide NAGORE, ne u stranu. Eva se uspinje do vrha vulkana
## gde je kuca Roki, kroz sve sto je nauceno kroz igru:
##   lebdenje    - sa visokih stena preko provalija (moc ovog nivoa)
##   krhki kamen - ploce koje puknu, ne moze da se ceka
##   lava        - reke koje se preskacu
##
## Moc je LEBDENJE, ne dupli skok: eva.gd nosi jednu moc po nivou, a
## lebdenje je ono sto uspon nagore zaista trazi.
##
## Eva spasava kucu Rokija.


func _setup() -> void:
	biome = "vulkan"
	start = Vector2(40, -40)
	# Nivo ide visoko nagore, pa je granica pada duboko.
	fall_limit = 620.0
	power = "glide"
	set_friend(Vector2(2660, -820), "kuca")

	set_decor(_draw_summit)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Vrh vulkana!\nDrži SPACE da lebdiš"


func _build_terrain() -> void:
	# ============ PODNOZJE ============
	add_ground(Rect2(0, 0, 320, 60), "lava_rock")
	add_hazard(Rect2(320, 0, 170, 40), "lava")
	add_ground(Rect2(490, 0, 240, 60), "lava_rock")

	# ============ PRVI USPON: stepenice uz stenu ============
	add_ground(Rect2(660, -70, 80, 16), "stone")
	add_ground(Rect2(540, -140, 80, 16), "lava_rock")
	add_ground(Rect2(660, -210, 80, 16), "stone")
	add_ground(Rect2(790, -270, 200, 20), "lava_rock")

	# ============ LEBDENJE preko prve provalije ============
	# Merenje: skok nosi 171px. Sa y=-270 na y=-160 pad je 110px, pa
	# lebdeci domet oko 235px. Jaz je 210px - skokom se NE moze.
	add_ground(Rect2(1200, -160, 200, 20), "stone")

	# ============ KRHKI KAMEN nad lavom ============
	add_hazard(Rect2(1400, -100, 280, 40), "lava")
	add_fragile(Rect2(1470, -150, 100, 18), "lava_rock", 1.0, 2.8)
	add_ground(Rect2(1680, -160, 200, 20), "lava_rock")

	# ============ DRUGI USPON: viši, sa krhkim plocama ============
	add_ground(Rect2(1760, -240, 80, 16), "stone")
	add_fragile(Rect2(1640, -310, 90, 18), "lava_rock", 1.1, 2.6)
	add_ground(Rect2(1780, -380, 80, 16), "stone")
	add_ground(Rect2(1900, -440, 190, 20), "lava_rock")

	# ============ LEBDENJE preko druge, sire provalije ============
	# Sa y=-440 na y=-330: pad 110px, jaz 230px - lebdenje obavezno.
	add_ground(Rect2(2320, -330, 200, 20), "stone")

	# ============ ZAVRSNI USPON DO VRHA ============
	#
	# Merenje je nasло jaz 2090->2270 = 180px pri dometu skoka 171px, a
	# isao je NAGORE (dy -40) pa lebdenje ne pomaze. Krhka ploca je
	# pomerena levo na 2210 - sada je jaz 120px, u dometu skoka.
	add_ground(Rect2(2400, -410, 80, 16), "lava_rock")
	add_fragile(Rect2(2210, -480, 90, 18), "lava_rock", 1.1, 2.6)
	add_ground(Rect2(2400, -550, 80, 16), "stone")
	add_ground(Rect2(2520, -620, 80, 16), "lava_rock")
	add_ground(Rect2(2400, -690, 80, 16), "stone")

	# ============ VRH: kuca Roki ceka na sigurnom ============
	add_ground(Rect2(2520, -780, 300, 26), "stone")
	# Mali plato iznad - da kuca ne stoji na samoj ivici.
	add_ground(Rect2(2580, -836, 180, 20), "stone")


func _build_stars() -> void:
	add_star(Vector2(140, -34))
	add_star(Vector2(260, -34))
	add_star_line(Vector2(350, -78), Vector2(460, -78), 3)
	add_star(Vector2(550, -34))

	# Prvi uspon.
	add_star(Vector2(700, -104))
	add_star(Vector2(580, -174))
	add_star(Vector2(700, -244))
	add_star(Vector2(850, -304))
	add_star(Vector2(950, -304))

	# LEBDENJE 1: luk spustanja.
	add_star(Vector2(1030, -290))
	add_star(Vector2(1090, -256))
	add_star(Vector2(1150, -216))
	add_star(Vector2(1240, -194))

	# Krhki kamen nad lavom.
	add_star(Vector2(1430, -196))
	add_star(Vector2(1520, -186))
	add_star(Vector2(1620, -196))
	add_star(Vector2(1740, -194))

	# Drugi uspon.
	add_star(Vector2(1800, -274))
	add_star(Vector2(1685, -346))
	add_star(Vector2(1820, -414))
	add_star(Vector2(1960, -474))
	add_star(Vector2(2050, -474))

	# LEBDENJE 2.
	add_star(Vector2(2140, -456))
	add_star(Vector2(2210, -420))
	add_star(Vector2(2280, -378))
	add_star(Vector2(2370, -364))

	# Zavrsni uspon.
	add_star(Vector2(2440, -444))
	add_star(Vector2(2255, -516))
	add_star(Vector2(2440, -584))
	add_star(Vector2(2560, -654))
	add_star(Vector2(2440, -724))

	# Vrh - poslednje zvezdice, nagrada.
	add_star(Vector2(2600, -814))
	add_star(Vector2(2700, -814))
	add_star(Vector2(2670, -870))


func _build_animals() -> void:
	add_animal("lavaguster", Vector2(560, -32))
	add_animal("skarabej", Vector2(880, -302))
	add_animal("lavaguster", Vector2(1280, -192))
	add_animal("skarabej", Vector2(1980, -472))
	add_animal("lavaguster", Vector2(2400, -362))
	add_animal("skarabej", Vector2(2620, -812))


func _build_checkpoints() -> void:
	# Cesto - ovo je poslednji nivo i najvisi; dete ne treba da ponavlja
	# ceo uspon zbog jednog promasaja.
	for p in [Vector2(60, -36), Vector2(520, -36), Vector2(830, -306),
			Vector2(1240, -196), Vector2(1720, -196), Vector2(1940, -476),
			Vector2(2360, -366), Vector2(2560, -816)]:
		add_checkpoint(p)


## Vrh vulkana: nebo se otvara ka visini, krater ispod, oblaci u nivou
## Eve na vrhu. Sto se vise ide, to je svetlije - nagrada za uspon.
func _draw_summit(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13740

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Zar dole, svetlije gore - vertikalni gradijent u pojasevima.
	# Sto je Eva vise, to je nebo mirnije: vizualna nagrada za uspon.
	# Prozirnost je NISKA (0.16 dole, 0.10 gore): na snimku je pri 0.3
	# ceo ekran bio preplavljen istom sivo-plavom bojom i staza se gubila.
	var bands := 10
	for i in bands:
		var t := float(i) / float(bands - 1)
		var y0 := 80.0 - t * 1000.0
		var col := Color(1, 0.5, 0.22, 0.16).lerp(Color(0.62, 0.8, 0.98, 0.1), t)
		_poly(bg, col, [
			Vector2(-100, y0), Vector2(3100, y0),
			Vector2(3100, y0 - 100.0), Vector2(-100, y0 - 100.0)])

	# --- Krater dole levo, gleda se odozgo ---
	var cx := 900.0
	_poly(bg, Color(0.22, 0.18, 0.2, 0.8), [
		Vector2(cx - 520, 60), Vector2(cx - 220, -180),
		Vector2(cx + 220, -180), Vector2(cx + 520, 60)])
	_poly(bg, Color(1, 0.45, 0.15, 0.6), [
		Vector2(cx - 200, -170), Vector2(cx + 200, -170),
		Vector2(cx + 150, -130), Vector2(cx - 150, -130)])
	_poly(bg, Color(1, 0.8, 0.3, 0.45), [
		Vector2(cx - 140, -166), Vector2(cx + 140, -166),
		Vector2(cx + 100, -142), Vector2(cx - 100, -142)])

	# --- Padine vulkana ---
	#
	# Prva verzija je bila jedan veliki poligon koji je sekao ekran
	# dijagonalno i izgledao kao greska u crtanju (video na snimku).
	# Sada su to NAZUBLJENE stene u dva sloja, uz samu stazu - citaju se
	# kao planina, ne kao dijagonalna crta.
	var ridge := PackedVector2Array()
	ridge.append(Vector2(-100, 80))
	var rx := -100.0
	while rx < 3100.0:
		# Silueta pratimo stazu: sto dalje desno, to vise gore.
		var base_y: float = 80.0 - (rx + 100.0) / 3200.0 * 900.0
		var peak: float = rng.randf_range(40.0, 110.0)
		var step: float = rng.randf_range(150.0, 280.0)
		ridge.append(Vector2(rx + step * 0.5, base_y - peak))
		ridge.append(Vector2(rx + step, base_y - peak * 0.35))
		rx += step
	ridge.append(Vector2(3100, 80))
	var rg := Polygon2D.new()
	rg.color = Color(0.28, 0.23, 0.26, 0.6)
	rg.polygon = ridge
	bg.add_child(rg)

	# Blizi, tamniji sloj - daje dubinu bez zaklanjanja staze.
	var ridge2 := PackedVector2Array()
	ridge2.append(Vector2(-100, 80))
	rx = -100.0
	while rx < 3100.0:
		var base_y2: float = 80.0 - (rx + 100.0) / 3200.0 * 620.0
		var peak2: float = rng.randf_range(28.0, 70.0)
		var step2: float = rng.randf_range(110.0, 200.0)
		ridge2.append(Vector2(rx + step2 * 0.5, base_y2 - peak2))
		ridge2.append(Vector2(rx + step2, base_y2 - peak2 * 0.3))
		rx += step2
	ridge2.append(Vector2(3100, 80))
	var rg2 := Polygon2D.new()
	rg2.color = Color(0.2, 0.17, 0.2, 0.55)
	rg2.polygon = ridge2
	bg.add_child(rg2)

	# --- Oblaci - u visini vrha, ispod Eve na kraju ---
	for i in 16:
		var x := rng.randf_range(-100.0, 3100.0)
		var y := rng.randf_range(-880.0, -420.0)
		var w := rng.randf_range(70.0, 170.0)
		var a := rng.randf_range(0.3, 0.6)
		_poly(bg, Color(1, 0.97, 0.95, a), [
			Vector2(x - w, y + 10), Vector2(x - w * 0.6, y - 12),
			Vector2(x, y - 18), Vector2(x + w * 0.6, y - 10),
			Vector2(x + w, y + 10)])

	# --- Crne stene uz stazu ---
	for i in 22:
		var p := Vector2(rng.randf_range(-60.0, 3060.0), rng.randf_range(-780.0, 44.0))
		var w := rng.randf_range(16.0, 44.0)
		var h := rng.randf_range(14.0, 34.0)
		var a := rng.randf_range(0.4, 0.7)
		_poly(bg, Color(0.19, 0.16, 0.18, a), [
			p + Vector2(-w, h), p + Vector2(-w * 0.7, -h * 0.6),
			p + Vector2(-w * 0.1, -h), p + Vector2(w * 0.6, -h * 0.5),
			p + Vector2(w, h)])

	# --- Iskre koje lete nagore, gusce dole (blize krateru) ---
	for i in 30:
		var sx := rng.randf_range(-60.0, 3060.0)
		# Vise iskri nisko, manje visoko.
		var sy: float = -rng.randf_range(0.0, 1.0) * rng.randf_range(0.0, 1.0) * 700.0 + 40.0
		var sz := rng.randf_range(2.5, 5.5)
		var em := Polygon2D.new()
		em.color = [Color(1, 0.72, 0.25, 0.85), Color(1, 0.45, 0.15, 0.8),
			Color(0.6, 0.55, 0.55, 0.5)][i % 3]
		em.polygon = PackedVector2Array([
			Vector2(0, -sz), Vector2(sz * 0.7, 0),
			Vector2(0, sz), Vector2(-sz * 0.7, 0)])
		em.position = Vector2(sx, sy)
		bg.add_child(em)

		var rise := rng.randf_range(140.0, 330.0)
		var dur := rng.randf_range(3.2, 6.5)
		var tw := create_tween().set_loops()
		tw.tween_property(em, "position:y", sy - rise, dur).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(em, "modulate:a", 0.0, dur)
		tw.tween_callback(func() -> void:
			em.position.y = sy
			em.modulate.a = 1.0
		)

	# --- Zastavica na vrhu: cilj je VIDLJIV izdaleka ---
	var top := Vector2(2670, -836)
	_poly(bg, Color(0.45, 0.35, 0.28), [
		top + Vector2(-3, 0), top + Vector2(3, 0),
		top + Vector2(3, -90), top + Vector2(-3, -90)])
	_poly(bg, Color(0.98, 0.35, 0.5), [
		top + Vector2(3, -90), top + Vector2(58, -74),
		top + Vector2(3, -58)])
	_poly(bg, Color(1, 0.6, 0.72), [
		top + Vector2(3, -86), top + Vector2(44, -75),
		top + Vector2(3, -64)])
	_circle(bg, top + Vector2(0, -92), 5.0, Color(1, 0.85, 0.3))


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
