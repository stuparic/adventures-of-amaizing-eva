extends LevelBase
## NIVO — "Pečurke i vile" (Čarobna šuma)
##
## Eva dobija moc "double_jump". Nivo je gradjen prema MERENOM dometu skoka:
## tap nosi 194px, drzanje 224px (vidi Game.PLAYER_*). Obicne praznine su
## do 170px, pa ih dete prelazi i kad samo tapne. Praznine gde je moc
## OBAVEZNA su oznacene u kodu i imaju rezervu.
##
## Eva spasava jelena Šumka.


func _setup() -> void:
	biome = "bajka"
	start = Vector2(40, -40)
	fall_limit = 520.0
	power = "double_jump"
	set_friend(Vector2(2900, -44), "jelen")

	set_decor(_draw_bg)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Eva skače dva puta!\nSPACE pa opet SPACE"


func _build_terrain() -> void:
	# --- Deo 1: sigurno tlo, moc se uci bez kazne ---
	add_ground(Rect2(0, 0, 320, 60), "ground")
	add_ground(Rect2(240, -70, 70, 16), "wood")

	# Prva praznina je 150px - preskace se i obicnim tapom.
	add_ground(Rect2(470, 0, 260, 60), "ground")

	# --- Deo 2: uspinjanje po platformama ---
	add_ground(Rect2(620, -76, 76, 16), "wood")
	add_ground(Rect2(760, -140, 76, 16), "wood")
	add_ground(Rect2(900, -204, 76, 16), "wood")
	add_ground(Rect2(1020, -256, 200, 20), "wood")

	# --- Deo 3: MOC je obavezna ---
	#
	# Jaz od 250px sa visine -256 na -60: obican skok nosi 194px pa se NE
	# moze; sa mocju je domet znatno veci, pa je prolaz udoban.
	add_ground(Rect2(1470, -60, 220, 20), "wood")

	# --- Deo 4: spust pa uspon ---
	add_ground(Rect2(1750, -16, 80, 16), "wood")
	add_ground(Rect2(1890, 0, 260, 60), "ground")
	add_ground(Rect2(1920, -80, 70, 16), "wood")
	add_ground(Rect2(1880, -148, 70, 16), "wood")
	add_ground(Rect2(1960, -214, 70, 16), "wood")

	# --- Deo 4b: niz platformi preko provalije ---
	add_ground(Rect2(2160, -60, 90, 18), "wood")
	add_ground(Rect2(2320, -96, 90, 18), "wood")
	add_ground(Rect2(2480, -60, 90, 18), "wood")
	add_ground(Rect2(2560, 0, 200, 60), "ground")

	# --- Deo 5: finale ---
	add_ground(Rect2(2600, -100, 74, 16), "wood")
	add_ground(Rect2(2760, 0, 340, 60), "ground")
	add_ground(Rect2(2860, -84, 64, 16), "wood")


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
	add_animal("kornjaca", Vector2(1120, -288))
	add_animal("zaba", Vector2(1570, -92))
	add_animal("kornjaca", Vector2(1990, -32))
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
##
## VISINE SU MERENE. Kamera prati Evu i pokazuje samo y -73..+73 na
## telefonu, -136..+136 na desktopu (Eva je na y=0). Nivo se uspinje do
## y=-290, pa je koristan opseg priblizno -330..+60.
##
## Prva verzija je crtala po y -720..+80 (kao da je kadar visok 800px) i
## skoro se NISTA nije videlo - kristali i planete su bili iznad kadra.
## Zato: ono sto raste iz zemlje ide od y=60 nagore, a ono sto "visi u
## vazduhu" ide u opseg -300..-40, gde kamera zaista gleda.
##
## Ono sto raste iz zemlje vezano je za y=6, ne y=60: tlo je Rect2 koje
## POCINJE na y=0 (debelo 60px), pa je njegova gornja ivica na nuli.
## Dekor na y=60 zavrsi na DNU bloka tla i ne vidi se - to je prva verzija
## i radila pogresno. Radni nivo sneg_1 iz istog razloga koristi y=50.
func _draw_bg(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21011

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Ljubicasti sumrak - bajkovito, ne obicna suma.
	Draw2D.poly(bg, Color(0.42, 0.3, 0.5, 0.26), [
		Vector2(-100, -340), Vector2(3200, -340),
		Vector2(3200, 80), Vector2(-100, 80)])

	# Drvece sa ljubicastim krosnjama - iz zemlje nagore.
	for i in 26:
		var x := rng.randf_range(-60.0, 3160.0)
		var h := rng.randf_range(120.0, 300.0)
		Draw2D.poly(bg, Color(0.34, 0.24, 0.3, 0.8), [
			Vector2(x - 12, 6), Vector2(x + 12, 6),
			Vector2(x + 7, 6 - h), Vector2(x - 7, 6 - h)])
		for k in 3:
			Draw2D.circle(bg, Vector2(x + (float(k) - 1.0) * 26.0, 6 - h - 8.0),
				rng.randf_range(30.0, 52.0), Color(0.6, 0.36, 0.66, 0.75))

	# Velike pecurke - na zemlji.
	for i in 20:
		var x := rng.randf_range(-60.0, 3160.0)
		var s := rng.randf_range(0.9, 2.0)
		Draw2D.poly(bg, Color(0.96, 0.94, 0.9, 0.85), [
			Vector2(x - 6 * s, 6), Vector2(x + 6 * s, 6),
			Vector2(x + 4 * s, 6 - 22 * s), Vector2(x - 4 * s, 6 - 22 * s)])
		var cap := PackedVector2Array()
		for k in 10:
			var a: float = PI + PI * float(k) / 9.0
			cap.append(Vector2(x + cos(a) * 24 * s, 6 - 20 * s + sin(a) * 16 * s))
		Draw2D.poly(bg, Color(0.9, 0.32, 0.42, 0.9), cap)
		for k in 3:
			Draw2D.circle(bg, Vector2(x + (float(k) - 1.0) * 9.0 * s,
				6 - 26 * s), 2.6 * s, Color(1, 1, 1, 0.9))

	# Svici - u vazduhu, u vidljivom opsegu.
	for i in 110:
		var x := rng.randf_range(-60.0, 3160.0)
		var y := rng.randf_range(-300.0, 40.0)
		Draw2D.circle(bg, Vector2(x, y), rng.randf_range(2.5, 5.0),
			Color(1, 0.97, 0.5, rng.randf_range(0.45, 0.85)))
