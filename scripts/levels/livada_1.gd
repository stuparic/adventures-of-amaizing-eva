extends LevelBase
## NIVO 1 — "Prvi koraci" (Zelena livada)
##
## Uvodni nivo: uci se hodanje, skakanje i skupljanje zvezdica.
## Rupe su male, zivotinje se pojavljuju tek posle 500px, ima mnogo
## checkpointa. Eva spasava macu Carlija.
##
## Bez specijalnih moci - to je namerno, prvi nivo uci osnove.


func _setup() -> void:
	biome = "livada"
	start = Vector2(40, -40)
	fall_limit = 260.0
	set_friend(Vector2(2150, -44), "maca")

	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Idi desno!\nSPACE = skok"


## Tlo: tri dela sa sve vecim rupama. Rupa se pravi tako sto NE stavis
## platformu - prazan prostor izmedju dva add_ground.
func _build_terrain() -> void:
	# --- Deo 1: siguran start, uci se skakanje ---
	add_ground(Rect2(0, 0, 260, 48))
	add_ground(Rect2(200, -56, 64, 16))          # niska platforma za prvi skok

	# rupa: 260 -> 300 (40px, lako preskociti)
	add_ground(Rect2(300, 0, 200, 48))
	add_ground(Rect2(360, -64, 48, 16))
	add_ground(Rect2(440, -96, 48, 16))          # stepenik gore

	# rupa: 500 -> 552
	add_ground(Rect2(552, 0, 180, 48))
	add_ground(Rect2(600, -72, 56, 16))

	# --- Deo 2: lebdece platforme preko vece rupe ---
	add_ground(Rect2(760, -48, 56, 16))
	add_ground(Rect2(848, -64, 56, 16))
	add_ground(Rect2(900, 0, 240, 48))
	add_ground(Rect2(980, -80, 72, 16))

	# rupa: 1140 -> 1196
	add_ground(Rect2(1196, 0, 300, 48))
	add_ground(Rect2(1250, -56, 48, 16))
	add_ground(Rect2(1330, -88, 48, 16))
	add_ground(Rect2(1410, -56, 48, 16))

	# --- Deo 3: finale, put do mace ---
	# rupa: 1496 -> 1560
	add_ground(Rect2(1560, 0, 180, 48))
	add_ground(Rect2(1620, -64, 64, 16))

	# rupa: 1740 -> 1800
	add_ground(Rect2(1800, 0, 420, 48))          # veliki siguran plato
	add_ground(Rect2(1880, -72, 56, 16))
	add_ground(Rect2(1980, -104, 56, 16))


## Zvezdice vode dete kroz nivo - postavljene su iznad skokova
## da pokazu kuda treba ici.
func _build_stars() -> void:
	for p in [
		Vector2(120, -32), Vector2(160, -32), Vector2(232, -80),
		Vector2(280, -48), Vector2(340, -40),
		Vector2(384, -88), Vector2(464, -120), Vector2(464, -152),
		Vector2(526, -56),
		Vector2(628, -96), Vector2(700, -32),
		Vector2(746, -40), Vector2(788, -72), Vector2(832, -80),
		Vector2(876, -88), Vector2(1016, -104), Vector2(1016, -136),
		Vector2(1080, -32), Vector2(1168, -48),
		Vector2(1274, -80), Vector2(1354, -112), Vector2(1434, -80),
		Vector2(1528, -56),
		Vector2(1652, -88), Vector2(1700, -32),
		Vector2(1770, -56),
		Vector2(1908, -96), Vector2(2008, -128), Vector2(2008, -160),
	]:
		add_star(p)


## Prva zivotinja tek posle 500px - dete prvo nauci da skace.
func _build_animals() -> void:
	add_animal("puz", Vector2(600, -20))
	add_animal("puz", Vector2(960, -20))
	add_animal("kornjaca", Vector2(1060, -20))
	add_animal("puz", Vector2(1280, -20))
	add_animal("kornjaca", Vector2(1400, -20))
	add_animal("puz", Vector2(1660, -20))
	add_animal("kornjaca", Vector2(1880, -20))


## Mnogo checkpointa - dete se nikad ne vraca daleko.
func _build_checkpoints() -> void:
	for p in [
		Vector2(220, -24), Vector2(320, -24), Vector2(580, -24),
		Vector2(920, -24), Vector2(1220, -24), Vector2(1580, -24),
		Vector2(1830, -24),
	]:
		add_checkpoint(p)
