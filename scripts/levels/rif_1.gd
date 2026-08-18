extends LevelBase
## NIVO — "Kroz koral" (Koralni rif)
##
## Eva dobija moc "swim". Nivo je gradjen prema MERENOM dometu skoka:
## tap nosi 194px, drzanje 224px (vidi Game.PLAYER_*). Obicne praznine su
## do 170px, pa ih dete prelazi i kad samo tapne. Praznine gde je moc
## OBAVEZNA su oznacene u kodu i imaju rezervu.
##
## Eva spasava sirenu Koralku.


func _setup() -> void:
	biome = "rif"
	start = Vector2(40, -40)
	fall_limit = 560.0
	power = "swim"
	set_friend(Vector2(2900, -44), "mornarka")

	set_decor(_draw_bg)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Eva pliva!\nDrži SPACE da plivaš"


func _build_terrain() -> void:
	# --- Deo 1: sigurno tlo, moc se uci bez kazne ---
	add_ground(Rect2(0, 0, 320, 60), "sand")
	add_ground(Rect2(240, -70, 70, 16), "stone")

	# Prva praznina je 150px - preskace se i obicnim tapom.
	add_ground(Rect2(470, 0, 260, 60), "sand")

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
	add_ground(Rect2(1890, 0, 260, 60), "sand")
	add_ground(Rect2(1920, -80, 70, 16), "stone")
	add_ground(Rect2(1880, -148, 70, 16), "stone")
	add_ground(Rect2(1960, -214, 70, 16), "stone")

	# --- Voda: prelazi se PLIVANJEM ---
	#
	# Korito je duboko do dna vidljivog sveta: plitka voda koja pocinje
	# ispod tla izgleda kao plava mrlja koja visi u vazduhu.
	add_water(Rect2(2150, 0, 420, 260))
	add_ground(Rect2(2340, -40, 84, 18), "stone")
	add_ground(Rect2(2480, -40, 84, 18), "stone")
	add_ground(Rect2(2560, 0, 200, 60), "sand")

	# --- Deo 5: finale ---
	add_ground(Rect2(2600, -100, 74, 16), "stone")
	add_ground(Rect2(2760, 0, 340, 60), "sand")
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
	add_animal("rak", Vector2(540, -32))
	add_animal("kornjaca", Vector2(1120, -288))
	add_animal("rak", Vector2(1570, -92))
	add_animal("kornjaca", Vector2(1990, -32))
	add_animal("rak", Vector2(2840, -32))


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
	rng.seed = 22696

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Bistra tirkizna voda.
	Draw2D.poly(bg, Color(0.45, 0.82, 0.85, 0.32), [
		Vector2(-100, -620), Vector2(3200, -620),
		Vector2(3200, 80), Vector2(-100, 80)])
	# Zraci svetla kroz vodu.
	for i in 9:
		var x := rng.randf_range(0.0, 3100.0)
		var w := rng.randf_range(30.0, 66.0)
		Draw2D.poly(bg, Color(1, 1, 0.85, 0.1), [
			Vector2(x, -600), Vector2(x + w, -600),
			Vector2(x + w + 120, 80), Vector2(x + 120, 80)])
	# Korali - razgranati, jarki.
	const CORAL: Array[Color] = [
		Color(0.98, 0.52, 0.58, 0.8), Color(0.98, 0.72, 0.4, 0.8),
		Color(0.68, 0.5, 0.92, 0.8), Color(0.45, 0.85, 0.78, 0.8)]
	for i in 34:
		var x := rng.randf_range(-60.0, 3160.0)
		var h := rng.randf_range(40.0, 120.0)
		var col: Color = CORAL[i % 4]
		Draw2D.poly(bg, col, [
			Vector2(x - 8, 60), Vector2(x + 8, 60),
			Vector2(x + 5, 60 - h), Vector2(x - 5, 60 - h)])
		for k in 3:
			var t := 0.4 + float(k) * 0.2
			var side := 1.0 if k % 2 == 0 else -1.0
			Draw2D.poly(bg, col, [
				Vector2(x, 60 - h * t),
				Vector2(x + side * 30.0, 60 - h * t - 22.0),
				Vector2(x + side * 20.0, 60 - h * t + 4.0)])
	# Ribice.
	for i in 26:
		var x := rng.randf_range(-60.0, 3160.0)
		var y := rng.randf_range(-500.0, 30.0)
		var col2 := Color(0.99, 0.75, 0.3, 0.7) if i % 2 == 0 \
			else Color(0.4, 0.7, 0.95, 0.7)
		Draw2D.poly(bg, col2, [
			Vector2(x - 9, y), Vector2(x, y - 5),
			Vector2(x + 9, y), Vector2(x, y + 5)])
		Draw2D.poly(bg, col2, [
			Vector2(x + 8, y), Vector2(x + 15, y - 5), Vector2(x + 15, y + 5)])

