extends LevelBase
## NIVO 3 — "Kroz šumu" (Zelena livada)
##
## Prvi nivo sa MOCI: dupli skok. Rupe su sire nego u nivou 1, pa dupli
## skok nije ukras nego potreba. Ima i vode koja je opasna (Eva jos ne
## ume da pliva) - uci se da voda nije prijatelj.
##
## Eva spasava vevericu Rilu.


func _setup() -> void:
	biome = "livada"
	start = Vector2(40, -40)
	fall_limit = 320.0
	power = "double_jump"
	set_friend(Vector2(2380, -44), "veverica")

	set_decor(_draw_forest)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Dupli skok!\nPritisni SPACE dva puta"


func _build_terrain() -> void:
	# --- Deo 1: uci se dupli skok na sirokoj rupi ---
	add_ground(Rect2(0, 0, 300, 48))
	add_ground(Rect2(220, -64, 60, 16), "wood")

	# SIROKA rupa 300 -> 420: bez duplog skoka se ne prelazi
	add_ground(Rect2(420, 0, 240, 48))
	add_ground(Rect2(480, -72, 56, 16), "wood")

	# --- Deo 2: voda je opasna ---
	add_ground(Rect2(760, 0, 140, 48))
	add_water(Rect2(660, 14, 100, 40))          # plicak izmedju platformi
	add_ground(Rect2(820, -80, 60, 16), "wood")

	add_ground(Rect2(1000, 0, 160, 48))
	add_water(Rect2(900, 14, 100, 40))

	# --- Deo 3: stepenice kroz krosnje ---
	add_ground(Rect2(1240, -40, 70, 16), "wood")
	add_ground(Rect2(1370, -88, 70, 16), "wood")
	add_ground(Rect2(1500, -136, 70, 16), "wood")
	add_ground(Rect2(1630, -88, 70, 16), "wood")
	add_ground(Rect2(1760, 0, 200, 48))

	# --- Deo 4: finale ---
	add_water(Rect2(1960, 14, 120, 40))
	add_ground(Rect2(2080, 0, 120, 48))
	add_ground(Rect2(2140, -80, 60, 16), "wood")
	add_ground(Rect2(2260, 0, 320, 48))
	add_ground(Rect2(2330, -96, 60, 16), "wood")


func _build_stars() -> void:
	# Zvezdice iznad rupa - pokazuju gde treba dupli skok.
	add_star_line(Vector2(320, -60), Vector2(400, -100), 3)
	add_star(Vector2(250, -96))
	add_star(Vector2(510, -104))
	add_star_line(Vector2(680, -70), Vector2(740, -70), 2)
	add_star(Vector2(850, -112))
	add_star_line(Vector2(920, -70), Vector2(980, -70), 2)
	add_star(Vector2(1275, -72))
	add_star(Vector2(1405, -120))
	add_star(Vector2(1535, -168))
	add_star(Vector2(1535, -200))
	add_star(Vector2(1665, -120))
	add_star_line(Vector2(1990, -70), Vector2(2060, -70), 3)
	add_star(Vector2(2170, -112))
	add_star(Vector2(2360, -128))
	add_star(Vector2(2360, -160))


func _build_animals() -> void:
	add_animal("puz", Vector2(480, -20))
	add_animal("kornjaca", Vector2(1060, -20))
	add_animal("puz", Vector2(1820, -20))
	add_animal("kornjaca", Vector2(1880, -20))
	add_animal("puz", Vector2(2320, -20))


func _build_checkpoints() -> void:
	for p in [Vector2(60, -24), Vector2(450, -24), Vector2(790, -24),
			Vector2(1030, -24), Vector2(1790, -24), Vector2(2300, -24)]:
		add_checkpoint(p)


## Sumska pozadina: gusto drvece iza platformi.
func _draw_forest(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3103

	var bg := Node2D.new()
	bg.z_index = -5
	add_child(bg)

	# Daleki sloj: samo krosnje, blede - kao suma u magli.
	for i in 26:
		var x := rng.randf_range(-60.0, 2620.0)
		var y := rng.randf_range(-150.0, -60.0)
		_blob(bg, Vector2(x, y), rng.randf_range(40.0, 70.0),
			Color(0.62, 0.8, 0.62))

	# Blizi sloj: cela drveta - deblo pa krosnja iznad njega.
	for i in 22:
		var x := rng.randf_range(-40.0, 2600.0)
		var h := rng.randf_range(110.0, 190.0)
		var w := rng.randf_range(13.0, 22.0)
		# Deblo.
		_poly(bg, Color(0.42, 0.31, 0.2), [
			Vector2(x, -h), Vector2(x + w, -h),
			Vector2(x + w * 0.82, 14), Vector2(x + w * 0.18, 14)])
		# Krosnja PREKO vrha debla, u dva tona.
		var top := Vector2(x + w * 0.5, -h - 6.0)
		_blob(bg, top + Vector2(-22, 8), 30.0, Color(0.24, 0.47, 0.26))
		_blob(bg, top + Vector2(22, 6), 28.0, Color(0.24, 0.47, 0.26))
		_blob(bg, top + Vector2(0, -14), 34.0, Color(0.28, 0.53, 0.29))
		_blob(bg, top + Vector2(-8, -6), 22.0, Color(0.36, 0.63, 0.34))


func _blob(parent: Node2D, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(c + Vector2(cos(a), sin(a) * 0.85) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)


func _poly(parent: Node, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)
