extends LevelBase
## NIVO 8 — "Vruće dine" (Vruća pustinja)
##
## Prvi nivo sa OPASNIM TLOM. Pesak izmedju kamenih platoa je vruc: ako
## Eva stane na njega, boli. Zato se ide po kamenju i po hladu.
##
## Eva ima dupli skok (kao u "Kroz šumu"), ali ovde ima novu svrhu -
## nije za sirinu nego za IZBEGAVANJE. Merenje: skok nosi 171px, dupli
## oko 300px, pa su vruce zone sirine 200-260px prelazne samo duplim.
##
## Eva spasava lisicu Rumenku.


func _setup() -> void:
	biome = "pustinja"
	start = Vector2(40, -40)
	fall_limit = 460.0
	power = "double_jump"
	set_friend(Vector2(2870, -44), "lisica")

	set_decor(_draw_desert)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Pesak je vruć!\nSkači dva puta: SPACE, SPACE"


func _build_terrain() -> void:
	# --- Deo 1: siguran kamen, uci se da je narandzasto opasno ---
	add_ground(Rect2(0, 0, 300, 60), "sand")
	# Prva vruca zona je UZA (140px) - preskace se i obicnim skokom.
	# Namerno: dete prvo vidi da boli, pa da mora dupli skok.
	add_hazard(Rect2(300, 0, 140, 40), "hot_sand")
	add_ground(Rect2(440, 0, 240, 60), "stone")

	# --- Deo 2: prva SIROKA vruca zona - samo dupli skok ---
	# 230px: obican skok nosi 171px, dupli oko 300px.
	add_hazard(Rect2(680, 0, 230, 40), "hot_sand")
	add_ground(Rect2(910, 0, 220, 60), "stone")

	# --- Deo 3: stepenice uz kamen, hlad na vrhu ---
	add_ground(Rect2(1060, -66, 76, 16), "stone")
	add_ground(Rect2(1190, -124, 76, 16), "stone")
	add_ground(Rect2(1320, -70, 76, 16), "stone")
	add_ground(Rect2(1440, 0, 200, 60), "stone")

	# --- Deo 4: dve vruce zone sa uskim ostrvcetom izmedju ---
	# Ostrvce je nagrada za precizan dupli skok, ne obaveza.
	add_hazard(Rect2(1640, 0, 200, 40), "hot_sand")
	add_ground(Rect2(1790, -30, 70, 18), "stone")
	add_hazard(Rect2(1860, 0, 190, 40), "hot_sand")
	add_ground(Rect2(2050, 0, 220, 60), "stone")

	# --- Deo 5: NAJSIRA zona, prelazi se preko visokih stena ---
	add_ground(Rect2(2130, -86, 76, 16), "stone")
	add_hazard(Rect2(2270, 0, 260, 40), "hot_sand")
	add_ground(Rect2(2330, -60, 80, 18), "stone")
	add_ground(Rect2(2530, 0, 200, 60), "sand")

	# --- Deo 6: finale, oaza u hladu ---
	add_ground(Rect2(2620, -76, 70, 16), "wood")
	add_ground(Rect2(2760, 0, 320, 60), "sand")


func _build_stars() -> void:
	add_star(Vector2(130, -34))
	add_star(Vector2(240, -34))
	# Trag preko prve vruce zone - visoko, van dometa peska.
	add_star_line(Vector2(330, -70), Vector2(410, -70), 3)
	add_star(Vector2(500, -34))

	# Siroka zona: zvezdice prate luk duplog skoka (gore pa dole).
	add_star(Vector2(700, -80))
	add_star(Vector2(760, -120))
	add_star(Vector2(830, -110))
	add_star(Vector2(890, -70))
	add_star(Vector2(970, -34))

	# Stepenice.
	add_star(Vector2(1094, -100))
	add_star(Vector2(1224, -158))
	add_star(Vector2(1354, -104))
	add_star(Vector2(1500, -34))

	# Dve zone sa ostrvcetom.
	add_star(Vector2(1690, -80))
	add_star(Vector2(1760, -110))
	add_star(Vector2(1824, -64))
	add_star(Vector2(1900, -100))
	add_star(Vector2(1980, -80))
	add_star(Vector2(2100, -34))

	# Najsira zona preko stena.
	add_star(Vector2(2168, -120))
	add_star(Vector2(2250, -140))
	add_star(Vector2(2368, -94))
	add_star(Vector2(2450, -120))
	add_star(Vector2(2580, -34))

	add_star(Vector2(2654, -110))
	add_star(Vector2(2800, -34))
	add_star(Vector2(2900, -34))


func _build_animals() -> void:
	# Skorpioni bi bili strasni - ostajem na puzu i kornjaci koje dete
	# vec poznaje. Razlika je u pustinjskoj boji tla, ne u pretnji.
	add_animal("skarabej", Vector2(520, -32))
	add_animal("puz", Vector2(990, -32))
	add_animal("skarabej", Vector2(1500, -32))
	add_animal("puz", Vector2(2120, -32))
	add_animal("skarabej", Vector2(2600, -32))
	add_animal("puz", Vector2(2830, -32))


func _build_checkpoints() -> void:
	# Posle SVAKE vruce zone - ako dete izgori, vraca se tu, ne na pocetak.
	for p in [Vector2(60, -36), Vector2(470, -36), Vector2(940, -36),
			Vector2(1470, -36), Vector2(2080, -36), Vector2(2560, -36),
			Vector2(2790, -36)]:
		add_checkpoint(p)


## Pustinja: dine u tri sloja, kaktusi, stene, vrelo sunce i talasanje
## vazduha nad peskom.
func _draw_desert(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8410

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Vrelo nebo - zutkasti sloj nad horizontom.
	_poly(bg, Color(1, 0.88, 0.6, 0.35), [
		Vector2(-100, -240), Vector2(3200, -240),
		Vector2(3200, 60), Vector2(-100, 60)])

	# Sunce - veliko i nisko, bez zraka da ne bode oci.
	_circle(bg, Vector2(700, -380), 58.0, Color(1, 0.88, 0.45, 0.35))
	_circle(bg, Vector2(700, -380), 42.0, Color(1, 0.94, 0.62, 0.7))
	_circle(bg, Vector2(700, -380), 30.0, Color(1, 0.98, 0.8, 0.9))

	# --- Dine u tri sloja: daleke svetlije i nize ---
	const D_ALPHA: Array[float] = [0.9, 0.6, 0.38]
	const D_SCALE: Array[float] = [1.0, 0.72, 0.5]
	const D_Y: Array[float] = [40.0, -30.0, -90.0]
	for layer_i in 3:
		var far := 2 - layer_i
		var alpha: float = D_ALPHA[far]
		var s: float = D_SCALE[far]
		var y0: float = D_Y[far]
		var col := Color(0.95, 0.85, 0.6, alpha)
		var col2 := Color(0.88, 0.76, 0.52, alpha)

		var x := -120.0
		var i := 0
		while x < 3200.0:
			var w: float = rng.randf_range(200.0, 380.0) * s
			var h: float = rng.randf_range(50.0, 110.0) * s
			# Dina je asimetricna - jedna strana blaza, druga strmija.
			var peak: float = x + w * rng.randf_range(0.35, 0.62)
			_poly(bg, col if i % 2 == 0 else col2, [
				Vector2(x, y0 + 60), Vector2(peak, y0 + 60 - h),
				Vector2(x + w, y0 + 60)])
			# Osencena strana - daje zapreminu.
			_poly(bg, Color(0.78, 0.66, 0.44, alpha * 0.5), [
				Vector2(peak, y0 + 60 - h), Vector2(x + w, y0 + 60),
				Vector2(peak + w * 0.18, y0 + 60)])
			x += w * rng.randf_range(0.55, 0.8)
			i += 1

	# --- Kaktusi ---
	for i in 18:
		var x := rng.randf_range(-40.0, 3160.0)
		var h := rng.randf_range(46.0, 96.0)
		var far := rng.randf() > 0.55
		var a := 0.45 if far else 0.85
		var s := 0.7 if far else 1.0
		var body := Color(0.28, 0.55, 0.32, a)
		var bw := 9.0 * s

		# Stablo.
		_poly(bg, body, [
			Vector2(x - bw, 34), Vector2(x + bw, 34),
			Vector2(x + bw, -h), Vector2(x - bw, -h)])
		_circle(bg, Vector2(x, -h), bw, body)
		# Dve ruke, na razlicitim visinama.
		for side in [-1.0, 1.0]:
			if rng.randf() > 0.45:
				continue
			var ay := -h * rng.randf_range(0.35, 0.7)
			var alen := rng.randf_range(16.0, 28.0) * s
			_poly(bg, body, [
				Vector2(x + side * bw, ay + 6 * s),
				Vector2(x + side * (bw + alen), ay + 6 * s),
				Vector2(x + side * (bw + alen), ay - 4 * s),
				Vector2(x + side * bw, ay - 4 * s)])
			_poly(bg, body, [
				Vector2(x + side * (bw + alen - 9 * s), ay - 4 * s),
				Vector2(x + side * (bw + alen), ay - 4 * s),
				Vector2(x + side * (bw + alen), ay - alen * 0.9),
				Vector2(x + side * (bw + alen - 9 * s), ay - alen * 0.9)])
			_circle(bg, Vector2(x + side * (bw + alen - 4.5 * s), ay - alen * 0.9),
				4.5 * s, body)
		# Bodlje - kratke crtice.
		for k in int(h / 12.0):
			var sy := 30.0 - k * 12.0
			_poly(bg, Color(0.9, 0.88, 0.7, a * 0.8), [
				Vector2(x - bw - 3 * s, sy), Vector2(x - bw, sy - 1.5),
				Vector2(x - bw, sy + 1.5)])
			_poly(bg, Color(0.9, 0.88, 0.7, a * 0.8), [
				Vector2(x + bw + 3 * s, sy), Vector2(x + bw, sy - 1.5),
				Vector2(x + bw, sy + 1.5)])

	# --- Stene ---
	for i in 14:
		var p := Vector2(rng.randf_range(-40.0, 3160.0), rng.randf_range(6.0, 40.0))
		var w := rng.randf_range(18.0, 46.0)
		var h := rng.randf_range(12.0, 30.0)
		var a := rng.randf_range(0.45, 0.75)
		_poly(bg, Color(0.66, 0.56, 0.44, a), [
			p + Vector2(-w, h), p + Vector2(-w * 0.6, -h * 0.7),
			p + Vector2(w * 0.3, -h), p + Vector2(w, h * 0.4),
			p + Vector2(w * 0.5, h)])
		# Svetlija gornja ivica.
		_poly(bg, Color(0.78, 0.68, 0.54, a), [
			p + Vector2(-w * 0.6, -h * 0.7), p + Vector2(w * 0.3, -h),
			p + Vector2(w * 0.34, -h * 0.78), p + Vector2(-w * 0.5, -h * 0.5)])

	# --- Talasanje vazduha nad peskom (vrelina) ---
	# Vodoravne prozirne crtice koje se blago pomeraju gore-dole.
	for i in 26:
		var x := rng.randf_range(-40.0, 3160.0)
		var y := rng.randf_range(-30.0, 30.0)
		var w := rng.randf_range(30.0, 70.0)
		var shimmer := Polygon2D.new()
		shimmer.color = Color(1, 0.97, 0.85, 0.16)
		shimmer.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(w, 0), Vector2(w, 2.5), Vector2(0, 2.5)])
		shimmer.position = Vector2(x, y)
		bg.add_child(shimmer)

		var t := rng.randf_range(1.6, 3.0)
		var tw := create_tween().set_loops()
		tw.tween_property(shimmer, "position:y", y - 7.0, t).set_trans(Tween.TRANS_SINE)
		tw.tween_property(shimmer, "position:y", y, t).set_trans(Tween.TRANS_SINE)

	# --- Kosti (flavor) - pustinja je surova, ali crtano bezopasno ---
	for i in 5:
		var p := Vector2(rng.randf_range(200.0, 3000.0), rng.randf_range(20.0, 38.0))
		var col := Color(0.94, 0.92, 0.84, 0.6)
		_poly(bg, col, [
			p + Vector2(-14, 0), p + Vector2(14, 0),
			p + Vector2(14, 3), p + Vector2(-14, 3)])
		_circle(bg, p + Vector2(-15, 1.5), 3.5, col)
		_circle(bg, p + Vector2(15, 1.5), 3.5, col)


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
