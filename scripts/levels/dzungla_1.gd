extends LevelBase
## NIVO 6 — "Gusto lišće" (Divlja džungla)
##
## Eva dobija LEBDENJE. Dzungla je visoka: sa krosnji se pada duboko,
## pa Eva drzi SPACE i spusta se kao na padobranu.
##
## Zato je nivo gradjen NAGORE pa NADOLE: dete se uspinje po granama,
## a onda lebdi preko sirokih praznina koje se skokom ne mogu preci.
## Eva spasava pandu Bambu.


func _setup() -> void:
	biome = "dzungla"
	start = Vector2(40, -40)
	# Dzungla je visoka - Eva legalno leti duboko dole dok lebdi,
	# pa je granica pada nize nego u ostalim nivoima.
	fall_limit = 560.0
	power = "glide"
	set_friend(Vector2(2930, -44), "panda")

	set_decor(_draw_jungle)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Eva lebdi!\nDrži SPACE dok padaš"


func _build_terrain() -> void:
	# --- Deo 1: tlo, uci se lebdenje bez kazne ---
	add_ground(Rect2(0, 0, 300, 60), "jungle")
	# Niska grana - prvi skok.
	add_ground(Rect2(230, -66, 64, 16), "wood")

	# Prva praznina je UZA nego sto izgleda: i bez lebdenja se preskoci.
	# Namerno - dete prvo vidi da lebdenje pomaze, pa da je obavezno.
	add_ground(Rect2(400, 0, 240, 60), "jungle")

	# --- Deo 2: uspinjanje po granama do krosnje ---
	add_ground(Rect2(560, -70, 70, 16), "wood")
	add_ground(Rect2(700, -128, 70, 16), "wood")
	add_ground(Rect2(840, -186, 70, 16), "wood")
	# Velika platforma u krosnji - odmor pre prvog pravog lebdenja.
	add_ground(Rect2(960, -240, 220, 20), "wood")

	# --- Deo 3: PRVO pravo lebdenje - sa krosnje preko sireg jaza ---
	#
	# Merenje: obican skok nosi 171px. Ovaj jaz je 230px, pa se skokom
	# NE MOZE preci - dete mora da drzi SPACE. Pad je 180px, sto lebdenjem
	# daje ~331px dometa: udobna rezerva, ne tesan prolaz.
	add_ground(Rect2(1410, -60, 220, 20), "wood")

	# --- Deo 4: spust kroz lisce, pa uspon uz lijane do visoke grane ---
	add_ground(Rect2(1690, -10, 80, 16), "wood")
	add_ground(Rect2(1830, 0, 260, 60), "jungle")
	# Stepenice nagore - skokovi po ~58px visine, u dometu (visina skoka 106px).
	add_ground(Rect2(1860, -74, 66, 16), "wood")
	add_ground(Rect2(1820, -140, 66, 16), "stone")
	add_ground(Rect2(1900, -204, 66, 16), "wood")

	# --- Deo 5: reka, prelazi se LEBDENJEM (Eva ne pliva u ovom nivou!) ---
	#
	# Merenje: obican skok nosi 171px vodoravno. Zato polazna grana mora
	# da bude VISOKO nad panjevima - lebdenje daje domet samo ako ima
	# visine da se spusta (pad je ogranicen na 110px/s).
	# Sa y=-210 do panja na y=-34: pad 176px -> lebdeci domet ~326px.
	# Prvi panj je na 220px: skokom (171px) se NE stize, lebdenjem lako.
	add_ground(Rect2(1970, -210, 110, 18), "wood")

	# Reka je DUBOKA i puni korito do dna vidljivog sveta. Plitka voda
	# koja pocinje ispod tla izgleda kao plava mrlja koja visi u vazduhu -
	# to sam video na snimku pa produbio korito.
	add_water(Rect2(2090, 0, 420, 260))
	# Dva panja u reci: prvi zahteva lebdenje, drugi je obican skok -
	# ritam "tesko pa lako" da dete stigne da odahne.
	add_ground(Rect2(2300, -34, 80, 18), "wood")
	add_ground(Rect2(2440, -34, 80, 18), "wood")
	add_ground(Rect2(2510, 0, 200, 60), "jungle")

	# --- Deo 6: finale, visoka grana pa spust do pande ---
	add_ground(Rect2(2610, -96, 70, 16), "wood")
	add_ground(Rect2(2770, 0, 320, 60), "jungle")
	add_ground(Rect2(2870, -80, 60, 16), "wood")


func _build_stars() -> void:
	add_star(Vector2(130, -34))
	add_star(Vector2(262, -100))
	# Trag preko prve praznine - uci dete da skace u prazno.
	add_star_line(Vector2(320, -60), Vector2(380, -60), 3)
	add_star(Vector2(470, -34))

	# Uspinjanje - zvezdica nad svakom granom.
	add_star(Vector2(594, -104))
	add_star(Vector2(734, -162))
	add_star(Vector2(874, -220))
	add_star(Vector2(1010, -274))
	add_star(Vector2(1120, -274))

	# LEBDENJE preko jaza: zvezdice prate luk spustanja, ne pravu liniju.
	# Dete prati zvezdice i samo od sebe drzi SPACE.
	add_star(Vector2(1215, -262))
	add_star(Vector2(1275, -224))
	add_star(Vector2(1335, -184))
	add_star(Vector2(1395, -146))
	add_star(Vector2(1460, -110))
	add_star(Vector2(1540, -94))

	add_star(Vector2(1700, -44))
	add_star(Vector2(1790, -34))

	# Uspon uz grane do visoke lijanske grane.
	add_star(Vector2(1892, -108))
	add_star(Vector2(1852, -174))
	add_star(Vector2(1932, -238))
	add_star(Vector2(2024, -244))

	# LEBDENJE preko reke: zvezdice prate luk spustanja sa grane (y=-210)
	# do panja (y=-34). Dete prati zvezdice i drzi SPACE.
	add_star(Vector2(2100, -212))
	add_star(Vector2(2150, -170))
	add_star(Vector2(2200, -128))
	add_star(Vector2(2255, -90))
	add_star(Vector2(2340, -74))
	add_star(Vector2(2480, -74))
	add_star(Vector2(2570, -34))

	add_star(Vector2(2644, -130))
	add_star(Vector2(2730, -100))
	add_star(Vector2(2830, -34))
	add_star(Vector2(2900, -114))


func _build_animals() -> void:
	add_animal("puz", Vector2(470, -32))
	add_animal("kornjaca", Vector2(1060, -272))
	add_animal("puz", Vector2(1510, -92))
	add_animal("kornjaca", Vector2(1950, -32))
	add_animal("puz", Vector2(2590, -32))
	add_animal("kornjaca", Vector2(2850, -32))


func _build_checkpoints() -> void:
	# Cesto - dete od 5 godina ne treba da ponavlja pola nivoa.
	# Poslednji pre reke je na visokoj grani: ako padne u vodu, vraca se
	# tacno tamo odakle se lebdi, ne na pocetak dela.
	for p in [Vector2(60, -36), Vector2(430, -36), Vector2(1000, -276),
			Vector2(1450, -96), Vector2(1870, -36), Vector2(2000, -240),
			Vector2(2550, -36), Vector2(2800, -36)]:
		add_checkpoint(p)


## Dzungla: tri sloja gustog lisca, debela stabla, lijane, zracci sunca.
##
## Kljucno je da bude GUSTO (ime nivoa), ali da se platforme i dalje
## jasno vide - pa je sve iza sa niskom prozirnoscu i bez jarkih boja.
func _draw_jungle(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6301

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Zeleni sumrak - u dzungli je tamnije jer krosnje zaklanjaju nebo.
	_poly(bg, Color(0.16, 0.4, 0.24, 0.28), [
		Vector2(-100, -620), Vector2(3000, -620),
		Vector2(3000, 80), Vector2(-100, 80)])

	# Krov od lisca gore - "gusto lisce" iz naslova.
	for i in 60:
		var x := rng.randf_range(-60.0, 2980.0)
		var y := rng.randf_range(-600.0, -430.0)
		var r := rng.randf_range(40.0, 78.0)
		_circle(bg, Vector2(x, y), r,
			Color(0.14, 0.36, 0.2, rng.randf_range(0.3, 0.5)))

	# Zracci sunca kroz lisce - probijaju se ukoso.
	for i in 7:
		var x := rng.randf_range(0.0, 2900.0)
		var w := rng.randf_range(26.0, 54.0)
		_poly(bg, Color(1, 0.97, 0.72, 0.09), [
			Vector2(x, -520), Vector2(x + w, -520),
			Vector2(x + w + 130, 80), Vector2(x + 130, 80)])

	# --- Stabla u tri sloja: daleka slabija, bliza jaca ---
	const T_ALPHA: Array[float] = [0.9, 0.6, 0.38]
	const T_SCALE: Array[float] = [1.0, 0.78, 0.58]
	const T_COUNT: Array[int] = [12, 16, 20]
	const ROOT_OFF: Array[float] = [-1.0, 0.0, 1.0]

	for layer_i in 3:
		var far := 2 - layer_i          # 2 = najdalje
		var alpha: float = T_ALPHA[far]
		var s: float = T_SCALE[far]
		var count: int = T_COUNT[far]
		var trunk_col := Color(0.34, 0.24, 0.16, alpha)
		var leaf_a := Color(0.2, 0.5, 0.27, alpha)
		var leaf_b := Color(0.28, 0.62, 0.33, alpha)

		for i in count:
			var x := rng.randf_range(-60.0, 2980.0)
			var h: float = rng.randf_range(220.0, 400.0) * s

			# Debelo stablo koje se suzava ka vrhu.
			var bw: float = rng.randf_range(13.0, 22.0) * s
			var lean := rng.randf_range(-14.0, 14.0)
			_poly(bg, trunk_col, [
				Vector2(x - bw, 60), Vector2(x + bw, 60),
				Vector2(x + lean + bw * 0.55, -h),
				Vector2(x + lean - bw * 0.55, -h)])

			# Korenje - siri se u dnu, daje tezinu.
			for k in 3:
				var kx: float = x + ROOT_OFF[k] * bw * 1.5
				_poly(bg, trunk_col, [
					Vector2(x, 20), Vector2(kx, 62),
					Vector2(kx + 9 * s, 62)])

			# Krosnja: puna masa pa listovi preko.
			# (Bez pune mase krosnje izgledaju kao sive sipke izdaleka -
			#  na to sam vec naletao sa palmama.)
			var top := Vector2(x + lean, -h)
			for k in 5:
				var off := Vector2(rng.randf_range(-46, 46) * s,
					rng.randf_range(-30, 16) * s)
				_circle(bg, top + off, rng.randf_range(34.0, 56.0) * s,
					leaf_a if k % 2 == 0 else leaf_b)

			# Siroki listovi na obodu - oblik dzungle, ne obicnog drveta.
			for k in 8:
				var a := TAU * float(k) / 8.0 + rng.randf_range(-0.2, 0.2)
				var d := Vector2(cos(a), sin(a) * 0.6)
				var tip: Vector2 = top + d * rng.randf_range(58.0, 84.0) * s
				var mid: Vector2 = top + d * 34.0 * s
				_poly(bg, leaf_b if k % 2 == 0 else leaf_a, [
					top, mid + Vector2(-11 * s, -9 * s), tip,
					mid + Vector2(11 * s, 9 * s)])

	# --- Lijane koje vise sa krosnji ---
	for i in 22:
		var x := rng.randf_range(-40.0, 2960.0)
		var top_y := rng.randf_range(-520.0, -380.0)
		var len_v := rng.randf_range(140.0, 320.0)
		var sway := rng.randf_range(-24.0, 24.0)
		var col := Color(0.22, 0.46, 0.24, rng.randf_range(0.4, 0.65))

		# Blago kriva lijana - segmentima, da nije prava linija.
		var segs := 7
		for k in segs:
			var t0 := float(k) / float(segs)
			var t1 := float(k + 1) / float(segs)
			var x0 := x + sin(t0 * PI) * sway
			var x1 := x + sin(t1 * PI) * sway
			var y0 := top_y + len_v * t0
			var y1 := top_y + len_v * t1
			_poly(bg, col, [
				Vector2(x0 - 3, y0), Vector2(x0 + 3, y0),
				Vector2(x1 + 3, y1), Vector2(x1 - 3, y1)])

		# Listic na kraju lijane.
		var end := Vector2(x + sin(PI) * sway, top_y + len_v)
		_poly(bg, Color(0.26, 0.56, 0.3, 0.6), [
			end, end + Vector2(-9, 12), end + Vector2(0, 22),
			end + Vector2(9, 12)])

	# --- Paprat i grmlje po tlu ---
	for i in 34:
		var x := rng.randf_range(-40.0, 2960.0)
		var base := Vector2(x, rng.randf_range(-4.0, 34.0))
		var col := Color(0.24, 0.54, 0.28, rng.randf_range(0.45, 0.7))
		for k in 6:
			var a := PI + PI * (float(k) + 0.5) / 6.0
			var d := Vector2(cos(a), sin(a))
			var tip: Vector2 = base + d * rng.randf_range(22.0, 40.0)
			_poly(bg, col, [
				base + Vector2(-3, 0), base + d * 14.0 + Vector2(-5, 0),
				tip, base + d * 14.0 + Vector2(5, 0), base + Vector2(3, 0)])

	# --- Korito reke: obale se koso spustaju u vodu ---
	#
	# Bez ovoga voda izgleda kao plav pravougaonik zakacen u vazduhu.
	# Kose obale i mokro kamenje daju reci dno i kontekst.
	var bank := Color(0.3, 0.24, 0.16, 0.9)
	var bank_dark := Color(0.22, 0.17, 0.11, 0.9)
	# Leva obala: od tla na x=2090 ukoso nadole u vodu.
	_poly(bg, bank, [
		Vector2(2010, 0), Vector2(2090, 0),
		Vector2(2090, 260), Vector2(2010, 260)])
	_poly(bg, bank_dark, [
		Vector2(2090, 0), Vector2(2140, 60),
		Vector2(2140, 260), Vector2(2090, 260)])
	# Desna obala.
	_poly(bg, bank, [
		Vector2(2510, 0), Vector2(2590, 0),
		Vector2(2590, 260), Vector2(2510, 260)])
	_poly(bg, bank_dark, [
		Vector2(2460, 60), Vector2(2510, 0),
		Vector2(2510, 260), Vector2(2460, 260)])
	# Dno korita - mulj.
	_poly(bg, Color(0.26, 0.22, 0.15, 0.85), [
		Vector2(2090, 230), Vector2(2510, 230),
		Vector2(2510, 260), Vector2(2090, 260)])
	# Mokro kamenje na dnu.
	for i in 12:
		_circle(bg, Vector2(rng.randf_range(2110.0, 2490.0),
			rng.randf_range(200.0, 244.0)),
			rng.randf_range(9.0, 20.0), Color(0.36, 0.33, 0.28, 0.7))

	# --- Cvetovi - jedina jarka boja, da dzungla ne bude samo zelena ---
	const FLOWER_COLS: Array[Color] = [
		Color(0.98, 0.4, 0.55, 0.75), Color(1, 0.72, 0.3, 0.75),
		Color(0.85, 0.5, 0.9, 0.75)]
	for i in 16:
		var c := Vector2(rng.randf_range(0.0, 2920.0), rng.randf_range(-6.0, 26.0))
		var col: Color = FLOWER_COLS[i % 3]
		for k in 5:
			var a := TAU * float(k) / 5.0
			_circle(bg, c + Vector2(cos(a), sin(a)) * 6.0, 5.0, col)
		_circle(bg, c, 3.5, Color(1, 0.95, 0.6, 0.9))


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
