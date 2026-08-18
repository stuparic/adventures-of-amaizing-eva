extends LevelBase
## NIVO — "Skok po oblacima" (Ostrvo u oblacima)
##
## Eva dobija moc "glide". Nivo je gradjen prema MERENOM dometu skoka:
## tap nosi 194px, drzanje 224px (vidi Game.PLAYER_*). Obicne praznine su
## do 170px, pa ih dete prelazi i kad samo tapne. Praznine gde je moc
## OBAVEZNA su oznacene u kodu i imaju rezervu.
##
## Eva spasava labuda Belka.


func _setup() -> void:
	biome = "oblaci"
	start = Vector2(40, -40)
	fall_limit = 620.0
	power = "glide"
	set_friend(Vector2(2900, -44), "labud")

	set_decor(_draw_bg)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Eva lebdi!\nDrži SPACE dok padaš"


func _build_terrain() -> void:
	# --- Deo 1: sigurno tlo, moc se uci bez kazne ---
	add_ground(Rect2(0, 0, 320, 60), "stone")
	add_ground(Rect2(240, -70, 70, 16), "ice")

	# Prva praznina je 150px - preskace se i obicnim tapom.
	add_ground(Rect2(470, 0, 260, 60), "stone")

	# --- Deo 2: uspinjanje po platformama ---
	add_ground(Rect2(620, -76, 76, 16), "ice")
	add_ground(Rect2(760, -140, 76, 16), "ice")
	add_ground(Rect2(900, -204, 76, 16), "ice")
	add_ground(Rect2(1020, -256, 200, 20), "ice")

	# --- Deo 3: MOC je obavezna ---
	#
	# Jaz od 250px sa visine -256 na -60: obican skok nosi 194px pa se NE
	# moze; sa mocju je domet znatno veci, pa je prolaz udoban.
	add_ground(Rect2(1470, -60, 220, 20), "ice")

	# --- Deo 4: spust pa uspon ---
	add_ground(Rect2(1750, -16, 80, 16), "ice")
	add_ground(Rect2(1890, 0, 260, 60), "stone")
	add_ground(Rect2(1920, -80, 70, 16), "ice")
	add_ground(Rect2(1880, -148, 70, 16), "ice")
	add_ground(Rect2(1960, -214, 70, 16), "ice")

	# --- Deo 4b: niz platformi preko provalije ---
	add_ground(Rect2(2160, -60, 90, 18), "ice")
	add_ground(Rect2(2320, -96, 90, 18), "ice")
	add_ground(Rect2(2480, -60, 90, 18), "ice")
	add_ground(Rect2(2560, 0, 200, 60), "stone")

	# --- Deo 5: finale ---
	add_ground(Rect2(2600, -100, 74, 16), "ice")
	add_ground(Rect2(2760, 0, 340, 60), "stone")
	add_ground(Rect2(2860, -84, 64, 16), "ice")


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
	add_animal("zaba", Vector2(540, -32))
	add_animal("pingvince", Vector2(1120, -288))
	add_animal("zaba", Vector2(1570, -92))
	add_animal("pingvince", Vector2(1990, -32))
	add_animal("zaba", Vector2(2840, -32))


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
	rng.seed = 20337

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Svetlo nebo.
	Draw2D.poly(bg, Color(0.8, 0.9, 0.99, 0.5), [
		Vector2(-100, -700), Vector2(3200, -700),
		Vector2(3200, 80), Vector2(-100, 80)])
	# Slojevi oblaka - vise spojenih krugova, kao pravi oblak.
	for i in 26:
		var x := rng.randf_range(-100.0, 3200.0)
		var y := rng.randf_range(-620.0, 40.0)
		var r := rng.randf_range(26.0, 62.0)
		for k in 5:
			Draw2D.circle(bg, Vector2(x + (float(k) - 2.0) * r * 0.62,
				y + sin(float(k)) * r * 0.2),
				r * rng.randf_range(0.6, 1.0), Color(1, 1, 1, 0.5))
	# Daleke ptice.
	for i in 9:
		var x := rng.randf_range(0.0, 3100.0)
		var y := rng.randf_range(-520.0, -160.0)
		Draw2D.poly(bg, Color(0.6, 0.66, 0.78, 0.5), [
			Vector2(x - 12, y), Vector2(x, y - 5), Vector2(x + 12, y),
			Vector2(x, y - 1)])

