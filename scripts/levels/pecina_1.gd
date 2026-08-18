extends LevelBase
## NIVO — "Mračni hodnik" (Kristalna pećina)
##
## Eva dobija moc "light". Nivo je gradjen prema MERENOM dometu skoka:
## tap nosi 194px, drzanje 224px (vidi Game.PLAYER_*). Obicne praznine su
## do 170px, pa ih dete prelazi i kad samo tapne. Praznine gde je moc
## OBAVEZNA su oznacene u kodu i imaju rezervu.
##
## Eva spasava slepog miša Šuška.


func _setup() -> void:
	biome = "pecina"
	start = Vector2(40, -40)
	fall_limit = 560.0
	power = "light"
	set_friend(Vector2(2900, -44), "slepimis")

	set_decor(_draw_bg)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Eva svetli!\nIdi kroz mrak"


func _build_terrain() -> void:
	# --- Deo 1: sigurno tlo, moc se uci bez kazne ---
	add_ground(Rect2(0, 0, 320, 60), "stone")
	add_ground(Rect2(240, -70, 70, 16), "stone")

	# Prva praznina je 150px - preskace se i obicnim tapom.
	add_ground(Rect2(470, 0, 260, 60), "stone")

	# --- Deo 2: uspinjanje po platformama ---
	add_ground(Rect2(620, -76, 76, 16), "stone")
	add_ground(Rect2(760, -140, 76, 16), "stone")
	add_ground(Rect2(900, -204, 76, 16), "stone")
	add_ground(Rect2(1020, -256, 200, 20), "stone")

	# --- Deo 3: MOC je obavezna ---
	#
	# Jaz od 250px sa visine -256 na -60: obican skok nosi 194px pa se NE
	# moze; sa mocju je domet znatno veci, pa je prolaz udoban.
	add_ground(Rect2(1470, -60, 220, 20), "stone")

	# --- Deo 4: spust pa uspon ---
	add_ground(Rect2(1750, -16, 80, 16), "stone")
	add_ground(Rect2(1890, 0, 260, 60), "stone")
	add_ground(Rect2(1920, -80, 70, 16), "stone")
	add_ground(Rect2(1880, -148, 70, 16), "stone")
	add_ground(Rect2(1960, -214, 70, 16), "stone")

	# --- Deo 4b: niz platformi preko provalije ---
	add_ground(Rect2(2160, -60, 90, 18), "stone")
	add_ground(Rect2(2320, -96, 90, 18), "stone")
	add_ground(Rect2(2480, -60, 90, 18), "stone")
	add_ground(Rect2(2560, 0, 200, 60), "stone")

	# --- Deo 5: finale ---
	add_ground(Rect2(2600, -100, 74, 16), "stone")
	add_ground(Rect2(2760, 0, 340, 60), "stone")
	add_ground(Rect2(2860, -84, 64, 16), "stone")


func _build_stars() -> void:
	add_star(Vector2(140, -34))
	add_star(Vector2(272, -104))
	add_star_line(Vector2(340, -60), Vector2(420, -60), 3)
	add_star(Vector2(540, -34))

	add_star(Vector2(654, -110))
	add_star(Vector2(794, -174))
	add_star(Vector2(934, -238))
	add_star(Vector2(1070, -290))
	add_star(Vector2(1170, -290))

	# Zvezdice prate luk kretanja sa mocju - dete prati njih i samo od
	# sebe drzi SPACE.
	add_star(Vector2(1265, -278))
	add_star(Vector2(1325, -240))
	add_star(Vector2(1385, -200))
	add_star(Vector2(1445, -160))
	add_star(Vector2(1520, -110))
	add_star(Vector2(1600, -94))

	add_star(Vector2(1760, -50))
	add_star(Vector2(1850, -34))
	add_star(Vector2(1952, -114))
	add_star(Vector2(1912, -182))
	add_star(Vector2(1992, -248))
	add_star(Vector2(2084, -254))

	add_star(Vector2(2150, -220))
	add_star(Vector2(2260, -120))
	add_star(Vector2(2400, -80))
	add_star(Vector2(2560, -40))

	add_star(Vector2(2634, -134))
	add_star(Vector2(2820, -34))
	add_star(Vector2(2892, -118))


func _build_animals() -> void:
	add_animal("skarabej", Vector2(540, -32))
	add_animal("kornjaca", Vector2(1120, -288))
	add_animal("skarabej", Vector2(1570, -92))
	add_animal("kornjaca", Vector2(1990, -32))
	add_animal("skarabej", Vector2(2840, -32))


func _build_checkpoints() -> void:
	# Cesto - dete od 5 godina ne treba da ponavlja pola nivoa.
	for p in [Vector2(60, -36), Vector2(500, -36), Vector2(1060, -292),
			Vector2(1510, -96), Vector2(1930, -36), Vector2(1990, -250),
			Vector2(2620, -36), Vector2(2800, -36)]:
		add_checkpoint(p)


## Pozadina nivoa. Ostrvo na mapi crta BiomeArt; ovo je scenografija IZA
## platformi, pa je namerno blago i bez jarkih boja - inace se platforme
## izgube u sarenilu.
func _draw_bg(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20674

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Mrak - pecina je tamna, ali ne crna (platforme moraju da se vide).
	Draw2D.poly(bg, Color(0.14, 0.13, 0.22, 0.55), [
		Vector2(-100, -700), Vector2(3200, -700),
		Vector2(3200, 80), Vector2(-100, 80)])
	# Stalaktiti sa svoda.
	for i in 30:
		var x := rng.randf_range(-60.0, 3160.0)
		var h := rng.randf_range(50.0, 150.0)
		var w := rng.randf_range(12.0, 26.0)
		Draw2D.poly(bg, Color(0.26, 0.24, 0.36), [
			Vector2(x - w, -620), Vector2(x + w, -620), Vector2(x, -620 + h)])
	# Kristali koji svetle - jedini izvor boje.
	const CRYS: Array[Color] = [
		Color(0.6, 0.82, 0.96, 0.75), Color(0.78, 0.66, 0.96, 0.75),
		Color(0.55, 0.95, 0.88, 0.75)]
	for i in 26:
		var x := rng.randf_range(-60.0, 3160.0)
		var y := rng.randf_range(-520.0, 50.0)
		var h := rng.randf_range(18.0, 40.0)
		var col: Color = CRYS[i % 3]
		Draw2D.poly(bg, col, [
			Vector2(x - 8, y), Vector2(x, y - h), Vector2(x + 8, y)])
		Draw2D.circle(bg, Vector2(x, y - h * 0.4), h * 0.4,
			Color(col.r, col.g, col.b, 0.12))

