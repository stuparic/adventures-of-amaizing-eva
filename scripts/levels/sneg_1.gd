extends LevelBase
## NIVO 10 — "Snežna staza" (Snežna dolina)
##
## Prvi nivo sa KRHKIM LEDOM: tanke ledene ploce puknu kratko posle sto
## Eva stane na njih. Ploca se prvo zatrese i pobeli - dete vidi sta se
## desava i ima ~0.9s da odskoci. Vraca se posle 2.6s, pa nivo nikad ne
## postane neprohodan.
##
## Eva lebdi (glide) - sa visokih smrca se spusta kao na padobranu, i to
## je nacin da se preleti preko dugih nizova krhkog leda.
##
## Eva spasava pingvina Frku.


func _setup() -> void:
	biome = "sneg"
	start = Vector2(40, -40)
	fall_limit = 520.0
	power = "glide"
	set_friend(Vector2(2900, -44), "pingvin")

	set_decor(_draw_snow)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Led puca!\nDrži SPACE da lebdiš"


func _build_terrain() -> void:
	# --- Deo 1: cvrsto tlo, uci se da krhki led trese i beli ---
	add_ground(Rect2(0, 0, 300, 60), "ground")
	# PRVA krhka ploca je usamljena i sa cvrstim tlom odmah posle -
	# dete moze da pogresi bez kazne.
	add_fragile(Rect2(340, -20, 110, 18), "ice")
	add_ground(Rect2(500, 0, 240, 60), "ground")

	# --- Deo 2: dve krhke ploce u nizu ---
	add_fragile(Rect2(790, -30, 100, 18), "ice")
	add_fragile(Rect2(950, -30, 100, 18), "ice")
	add_ground(Rect2(1100, 0, 220, 60), "ice")

	# --- Deo 3: uspon uz smrce do visoke grane ---
	add_ground(Rect2(1250, -66, 76, 16), "wood")
	add_ground(Rect2(1130, -132, 76, 16), "wood")
	add_ground(Rect2(1250, -198, 76, 16), "wood")
	add_ground(Rect2(1360, -252, 180, 20), "wood")

	# --- Deo 4: LEBDENJE preko dugog niza krhkog leda ---
	#
	# Merenje: obican skok nosi 171px. Prva verzija je imala prvu plocu
	# na x=1700, sto je jaz od samo 160px sa grane na x=1540 - preskakalo
	# se obicnim skokom, pa lebdenje nije bilo NIGDE obavezno i moc se
	# nije ucila.
	#
	# Sada je prva ploca na x=1790: jaz 250px, a pad sa y=-252 na y=-30
	# je 222px sto lebdenjem daje ~390px. Skokom se NE moze.
	add_fragile(Rect2(1790, -30, 90, 18), "ice")
	add_fragile(Rect2(1920, -30, 90, 18), "ice")
	add_ground(Rect2(2060, 0, 200, 60), "ice")

	# --- Deo 5: ledeno jezero - voda je opasna (Eva ne pliva ovde) ---
	add_water(Rect2(2260, 0, 300, 200))
	# Santa u sredini - krhka je, pa ne moze da se ceka na njoj.
	add_fragile(Rect2(2370, -34, 90, 18), "ice", 1.2, 3.0)
	add_ground(Rect2(2560, 0, 200, 60), "ground")

	# --- Deo 6: finale, iglu i pingvin ---
	add_ground(Rect2(2640, -80, 70, 16), "ice")
	add_ground(Rect2(2780, 0, 320, 60), "ground")


func _build_stars() -> void:
	add_star(Vector2(130, -34))
	add_star(Vector2(250, -34))
	add_star(Vector2(395, -56))
	add_star(Vector2(560, -34))
	add_star(Vector2(680, -34))

	# Dve ploce u nizu - zvezdica nad svakom, vodi ritam.
	add_star(Vector2(840, -66))
	add_star(Vector2(1000, -66))
	add_star(Vector2(1160, -34))
	add_star(Vector2(1280, -34))

	# Uspon uz smrce.
	add_star(Vector2(1288, -100))
	add_star(Vector2(1168, -166))
	add_star(Vector2(1288, -232))
	add_star(Vector2(1420, -286))
	add_star(Vector2(1500, -286))

	# LEBDENJE: zvezdice prate luk spustanja sa grane (y=-252) do leda.
	add_star(Vector2(1570, -240))
	add_star(Vector2(1630, -190))
	add_star(Vector2(1690, -134))
	add_star(Vector2(1835, -80))
	add_star(Vector2(1965, -70))
	add_star(Vector2(2120, -34))

	# Preko jezera - visoko, van vode.
	add_star(Vector2(2280, -90))
	add_star(Vector2(2350, -80))
	add_star(Vector2(2415, -74))
	add_star(Vector2(2490, -84))
	add_star(Vector2(2620, -34))

	add_star(Vector2(2674, -114))
	add_star(Vector2(2840, -34))
	add_star(Vector2(2950, -34))


func _build_animals() -> void:
	add_animal("pingvince", Vector2(560, -32))
	add_animal("kornjaca", Vector2(1180, -32))
	add_animal("pingvince", Vector2(1440, -284))
	add_animal("kornjaca", Vector2(2120, -32))
	add_animal("pingvince", Vector2(2620, -32))
	add_animal("kornjaca", Vector2(2860, -32))


func _build_checkpoints() -> void:
	# Posle svakog niza krhkog leda i pre lebdenja.
	for p in [Vector2(60, -36), Vector2(530, -36), Vector2(1140, -36),
			Vector2(1400, -288), Vector2(2090, -36), Vector2(2590, -36),
			Vector2(2820, -36)]:
		add_checkpoint(p)


## Sneg: smrce u tri sloja, nanosi, pahulje koje padaju, severna svetlost.
func _draw_snow(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 10520

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Hladno nebo - plavicasti sloj.
	_poly(bg, Color(0.72, 0.85, 0.95, 0.4), [
		Vector2(-100, -620), Vector2(3200, -620),
		Vector2(3200, 60), Vector2(-100, 60)])

	# Severna svetlost - blage zelene/ljubicaste zavese visoko na nebu.
	const AURORA_COLS: Array[Color] = [
		Color(0.4, 0.9, 0.7, 0.16), Color(0.6, 0.6, 0.95, 0.14),
		Color(0.5, 0.85, 0.9, 0.15)]
	for i in 5:
		var x := rng.randf_range(-100.0, 3100.0)
		var w := rng.randf_range(120.0, 260.0)
		var col: Color = AURORA_COLS[i % 3]
		_poly(bg, col, [
			Vector2(x, -600), Vector2(x + w, -600),
			Vector2(x + w * 0.7, -340), Vector2(x + w * 0.2, -340)])

	# --- Smrce u tri sloja ---
	const T_ALPHA: Array[float] = [0.92, 0.62, 0.4]
	const T_SCALE: Array[float] = [1.0, 0.74, 0.54]
	const T_COUNT: Array[int] = [11, 15, 19]
	for layer_i in 3:
		var far := 2 - layer_i
		var alpha: float = T_ALPHA[far]
		var s: float = T_SCALE[far]
		var count: int = T_COUNT[far]
		var needle := Color(0.16, 0.42, 0.3, alpha)
		var needle2 := Color(0.22, 0.52, 0.36, alpha)
		var snow_col := Color(0.96, 0.98, 1.0, alpha * 0.95)

		for i in count:
			var x := rng.randf_range(-60.0, 3160.0)
			var h: float = rng.randf_range(150.0, 280.0) * s
			# Stablo.
			_poly(bg, Color(0.4, 0.28, 0.2, alpha), [
				Vector2(x - 7 * s, 50), Vector2(x + 7 * s, 50),
				Vector2(x + 5 * s, -h * 0.2), Vector2(x - 5 * s, -h * 0.2)])
			# Tri sloja grana, odozdo nagore sve uze.
			for k in 3:
				var t := float(k) / 2.0
				var wy: float = -h * (0.2 + t * 0.62)
				var ww: float = (46.0 - t * 22.0) * s
				var hh: float = (58.0 - t * 12.0) * s
				_poly(bg, needle if k % 2 == 0 else needle2, [
					Vector2(x - ww, wy), Vector2(x, wy - hh), Vector2(x + ww, wy)])
				# Sneg na granama - beli rub.
				_poly(bg, snow_col, [
					Vector2(x - ww, wy), Vector2(x - ww * 0.5, wy - hh * 0.4),
					Vector2(x - ww * 0.3, wy - hh * 0.25), Vector2(x - ww * 0.6, wy)])
				_poly(bg, snow_col, [
					Vector2(x + ww, wy), Vector2(x + ww * 0.5, wy - hh * 0.4),
					Vector2(x + ww * 0.3, wy - hh * 0.25), Vector2(x + ww * 0.6, wy)])
			# Vrh.
			_poly(bg, needle2, [
				Vector2(x - 12 * s, -h * 0.82), Vector2(x, -h),
				Vector2(x + 12 * s, -h * 0.82)])

	# --- Nanosi snega po tlu ---
	for i in 30:
		var x := rng.randf_range(-60.0, 3160.0)
		var w := rng.randf_range(50.0, 130.0)
		var h := rng.randf_range(10.0, 26.0)
		_poly(bg, Color(0.97, 0.99, 1.0, rng.randf_range(0.5, 0.8)), [
			Vector2(x - w, 50), Vector2(x - w * 0.5, 50 - h),
			Vector2(x + w * 0.4, 50 - h * 0.8), Vector2(x + w, 50)])

	# --- Pahulje koje padaju ---
	for i in 44:
		var sx := rng.randf_range(-60.0, 3160.0)
		var sy := rng.randf_range(-560.0, 20.0)
		var r := rng.randf_range(2.5, 5.5)
		var fl := Polygon2D.new()
		fl.color = Color(1, 1, 1, rng.randf_range(0.5, 0.9))
		# Sest krakova - prava pahulja, ne kruzic.
		var pts := PackedVector2Array()
		for k in 12:
			var a := TAU * float(k) / 12.0
			var rr := r if k % 2 == 0 else r * 0.4
			pts.append(Vector2(cos(a), sin(a)) * rr)
		fl.polygon = pts
		fl.position = Vector2(sx, sy)
		bg.add_child(fl)

		# Pada i blago se njise.
		var dur := rng.randf_range(6.0, 12.0)
		var tw := create_tween().set_loops()
		tw.tween_property(fl, "position:y", sy + 620.0, dur)
		tw.tween_callback(func() -> void: fl.position.y = sy - 60.0)
		var sway := create_tween().set_loops()
		sway.tween_property(fl, "position:x", sx + rng.randf_range(14.0, 30.0),
			rng.randf_range(1.8, 3.4)).set_trans(Tween.TRANS_SINE)
		sway.tween_property(fl, "position:x", sx,
			rng.randf_range(1.8, 3.4)).set_trans(Tween.TRANS_SINE)

	# --- Iglu na kraju (flavor kod pingvina) ---
	var ig := Vector2(2960, 40)
	_poly(bg, Color(0.92, 0.96, 1.0, 0.9), [
		ig + Vector2(-58, 0), ig + Vector2(-52, -36), ig + Vector2(-28, -58),
		ig + Vector2(28, -58), ig + Vector2(52, -36), ig + Vector2(58, 0)])
	# Blokovi.
	for k in 4:
		var by := -12.0 - k * 12.0
		var bw := 54.0 - k * 9.0
		_poly(bg, Color(0.82, 0.9, 0.97, 0.55), [
			ig + Vector2(-bw, by), ig + Vector2(bw, by),
			ig + Vector2(bw, by + 1.5), ig + Vector2(-bw, by + 1.5)])
	# Ulaz.
	_poly(bg, Color(0.5, 0.66, 0.8, 0.9), [
		ig + Vector2(-16, 0), ig + Vector2(-14, -22),
		ig + Vector2(14, -22), ig + Vector2(16, 0)])


func _poly(parent: Node, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)
