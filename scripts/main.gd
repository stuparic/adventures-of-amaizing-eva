extends Node2D
## Glavna scena. Gradi nivo iz tabele ispod, pa vodi tok igre.
##
## NIVO SE MENJA OVDE - u PLATFORMS/STARS/ANIMALS listama.
## Koordinate su u pikselima. Tlo je na y = 0. Nivo ide u desno.

const EvaScene := preload("res://scenes/eva.tscn")
const BudScene := preload("res://scenes/budzumbora.tscn")
const StarScene := preload("res://scenes/star.tscn")
const CheckpointScene := preload("res://scenes/checkpoint.tscn")
const MacaScene := preload("res://scenes/maca.tscn")
const PuzScene := preload("res://scenes/puz.tscn")
const KornjacaScene := preload("res://scenes/kornjaca.tscn")

const TILE := 16.0
const START := Vector2(40, -40)

## Platforme: Rect2(x, y, sirina, visina). y je negativno = iznad tla.
## Rupe se prave tako sto NE stavis platformu - vidi prazninu izmedju segmenata.
const PLATFORMS: Array[Rect2] = [
	# --- Deo 1: siguran start, uci se skakanje ---
	Rect2(0, 0, 260, 48),
	Rect2(200, -56, 64, 16),          # niska platforma za prvi skok

	# rupa: 260 -> 300 (40px, lako preskociti)
	Rect2(300, 0, 200, 48),
	Rect2(360, -64, 48, 16),
	Rect2(440, -96, 48, 16),          # stepenik gore

	# rupa: 500 -> 552
	Rect2(552, 0, 180, 48),
	Rect2(600, -72, 56, 16),

	# --- Deo 2: lebdeće platforme preko vece rupe ---
	# velika rupa: 732 -> 900, ali sa platformama preko
	Rect2(760, -48, 56, 16),
	Rect2(848, -64, 56, 16),
	Rect2(900, 0, 240, 48),
	Rect2(980, -80, 72, 16),

	# rupa: 1140 -> 1196
	Rect2(1196, 0, 300, 48),
	Rect2(1250, -56, 48, 16),
	Rect2(1330, -88, 48, 16),
	Rect2(1410, -56, 48, 16),

	# --- Deo 3: finale, put do mace ---
	# rupa: 1496 -> 1560
	Rect2(1560, 0, 180, 48),
	Rect2(1620, -64, 64, 16),

	# rupa: 1740 -> 1800
	Rect2(1800, 0, 420, 48),          # veliki siguran plato sa macom
	Rect2(1880, -72, 56, 16),
	Rect2(1980, -104, 56, 16),
]

## Zvezdice: pozicije. Vodе dete kroz nivo - stavljene su iznad skokova
## da pokazu kuda treba ici.
const STARS: Array[Vector2] = [
	Vector2(120, -32), Vector2(160, -32), Vector2(232, -80),
	Vector2(280, -48), Vector2(340, -40),                      # preko prve rupe
	Vector2(384, -88), Vector2(464, -120), Vector2(464, -152),
	Vector2(526, -56),                                          # preko rupe
	Vector2(628, -96), Vector2(700, -32),
	Vector2(746, -40), Vector2(788, -72), Vector2(832, -80),    # lanac preko velike rupe
	Vector2(876, -88), Vector2(1016, -104), Vector2(1016, -136),
	Vector2(1080, -32), Vector2(1168, -48),
	Vector2(1274, -80), Vector2(1354, -112), Vector2(1434, -80),
	Vector2(1528, -56),
	Vector2(1652, -88), Vector2(1700, -32),
	Vector2(1770, -56),
	Vector2(1908, -96), Vector2(2008, -128), Vector2(2008, -160),
]

## Zivotinje: [tip, pozicija]. Tip: "puz" ili "kornjaca".
## Prva se pojavljuje tek posle 500px - dete prvo nauci da skace.
const ANIMALS: Array = [
	["puz", Vector2(600, -20)],
	["puz", Vector2(960, -20)],
	["kornjaca", Vector2(1060, -20)],
	["puz", Vector2(1280, -20)],
	["kornjaca", Vector2(1400, -20)],
	["puz", Vector2(1660, -20)],
	["kornjaca", Vector2(1880, -20)],
]

## Checkpointi - cvetovi. Ima ih puno, pre svake tezje sekcije.
const CHECKPOINTS: Array[Vector2] = [
	Vector2(220, -24),
	Vector2(320, -24),
	Vector2(580, -24),
	Vector2(920, -24),
	Vector2(1220, -24),
	Vector2(1580, -24),
	Vector2(1830, -24),
]

const MACA_POS := Vector2(2150, -44)

## Granica pada - ispod ovoga se racuna da je pala u rupu.
const FALL_LIMIT := 260.0

var _eva: CharacterBody2D
var _hud: CanvasLayer
var _win_screen: CanvasLayer
var _bud: Node2D
var _level_over := false


func _ready() -> void:
	Game.reset_run()
	_build_level()
	_spawn_actors()

	_hud = get_node("HUD")
	_win_screen = get_node("WinScreen")
	Game.level_won.connect(_on_won)
	Game.player_died.connect(_on_died)
	Game.hearts_changed.connect(_on_hearts_changed)

	_hud.show_banner("Idi desno!\nSPACE = skok", Color(0.2, 0.35, 0.6), 2.5)
	Audio.play_music()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_restart()

	if Input.is_action_just_pressed("mute"):
		Audio.toggle_mute()
		_hud.show_banner("Zvuk ISKLJUCEN" if Audio.is_muted() else "Zvuk UKLJUCEN",
			Color(0.35, 0.4, 0.5), 1.0)

	if _eva != null and not _level_over and _eva.global_position.y > FALL_LIMIT:
		_eva.fall_out()


## --- Gradnja nivoa ---

func _build_level() -> void:
	var world := StaticBody2D.new()
	world.name = "World"
	world.collision_layer = 1
	world.collision_mask = 0
	add_child(world)

	for rect in PLATFORMS:
		_add_platform(world, rect)

	Game.total_stars = STARS.size()
	for pos in STARS:
		var s := StarScene.instantiate()
		s.position = pos
		add_child(s)

	for pos in CHECKPOINTS:
		var c := CheckpointScene.instantiate()
		c.position = pos
		add_child(c)

	for entry in ANIMALS:
		var scene: PackedScene = PuzScene if entry[0] == "puz" else KornjacaScene
		var a := scene.instantiate()
		a.position = entry[1]
		add_child(a)

	var maca := MacaScene.instantiate()
	maca.position = MACA_POS
	add_child(maca)


## Boje platforme - menjaj ovde da promenis izgled celog sveta.
const C_SOIL_DARK := Color(0.42, 0.28, 0.17)
const C_SOIL := Color(0.55, 0.38, 0.24)
const C_SOIL_LIGHT := Color(0.63, 0.45, 0.29)
const C_GRASS_DARK := Color(0.3, 0.56, 0.28)
const C_GRASS := Color(0.42, 0.72, 0.38)
const C_GRASS_LIGHT := Color(0.55, 0.83, 0.45)
const C_ROCK := Color(0.48, 0.44, 0.42)


## Gradi jednu platformu sa detaljima: trava sa vlatima, slojevita zemlja,
## kamencici i korenje. Detalji su deterministicki (seed iz pozicije), pa
## svaka platforma izgleda drugacije ali isto pri svakom pokretanju.
func _add_platform(parent: StaticBody2D, rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size * 0.5
	parent.add_child(shape)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x) * 7919 + int(rect.position.y) * 104729

	var w := rect.size.x
	var h := rect.size.y
	var top := rect.position

	# --- ZEMLJA: tri sloja za dubinu ---
	_poly(parent, C_SOIL_DARK, [
		top + Vector2(0, 4), top + Vector2(w, 4),
		top + Vector2(w, h), top + Vector2(0, h),
	])
	_poly(parent, C_SOIL, [
		top + Vector2(0, 4), top + Vector2(w, 4),
		top + Vector2(w, h - 3), top + Vector2(0, h - 3),
	])
	# Svetliji pojas odmah pod travom - kao presek zemlje.
	_poly(parent, C_SOIL_LIGHT, [
		top + Vector2(0, 5), top + Vector2(w, 5),
		top + Vector2(w, 8), top + Vector2(0, 8),
	])

	# --- KAMENCICI u zemlji ---
	var rocks := maxi(1, int(w / 55.0))
	for i in rocks:
		var rx := rng.randf_range(6.0, maxf(w - 6.0, 7.0))
		var ry := rng.randf_range(11.0, maxf(h - 6.0, 12.0))
		var rs := rng.randf_range(1.6, 3.0)
		_poly(parent, C_ROCK, [
			top + Vector2(rx - rs, ry),
			top + Vector2(rx - rs * 0.4, ry - rs * 0.8),
			top + Vector2(rx + rs, ry - rs * 0.3),
			top + Vector2(rx + rs * 0.5, ry + rs * 0.7),
			top + Vector2(rx - rs * 0.5, ry + rs * 0.8),
		])

	# --- KORENJE koje visi sa dna trave ---
	if h > 20.0:
		var roots := maxi(1, int(w / 70.0))
		for i in roots:
			var rx := rng.randf_range(8.0, maxf(w - 8.0, 9.0))
			var rl := rng.randf_range(4.0, 9.0)
			_poly(parent, C_GRASS_DARK, [
				top + Vector2(rx - 0.7, 8),
				top + Vector2(rx + 0.7, 8),
				top + Vector2(rx + 0.4, 8 + rl),
				top + Vector2(rx - 0.4, 8 + rl),
			])

	# --- TRAVA: tamna baza, svetli sloj, pa vlati ---
	_poly(parent, C_GRASS_DARK, [
		top, top + Vector2(w, 0), top + Vector2(w, 5), top + Vector2(0, 5),
	])
	_poly(parent, C_GRASS, [
		top, top + Vector2(w, 0), top + Vector2(w, 3.5), top + Vector2(0, 3.5),
	])
	_poly(parent, C_GRASS_LIGHT, [
		top, top + Vector2(w, 0), top + Vector2(w, 1.6), top + Vector2(0, 1.6),
	])

	# Vlati trave koje vire iznad ivice - daju "mekan" gornji rub.
	var blades := int(w / 7.0)
	for i in blades:
		var bx := (i + 0.5) * 7.0 + rng.randf_range(-1.5, 1.5)
		if bx < 1.0 or bx > w - 1.0:
			continue
		var bh := rng.randf_range(1.5, 3.4)
		var lean := rng.randf_range(-0.8, 0.8)
		var col := C_GRASS_LIGHT if rng.randf() > 0.45 else C_GRASS
		_poly(parent, col, [
			top + Vector2(bx - 1.0, 0.5),
			top + Vector2(bx + 1.0, 0.5),
			top + Vector2(bx + lean, -bh),
		])


## Helper: napravi Polygon2D i dodaj ga.
func _poly(parent: Node, color: Color, points: Array) -> void:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array(points)
	parent.add_child(p)


func _spawn_actors() -> void:
	_eva = EvaScene.instantiate()
	_eva.position = START
	add_child(_eva)

	_bud = BudScene.instantiate()
	_bud.position = START + Vector2(-34, -14)
	add_child(_bud)
	_bud.follow(_eva)

	Game.set_checkpoint(START)


## --- Tok igre ---

func _on_hearts_changed(value: int) -> void:
	if _bud != null and _bud.has_method("startle") and value < Game.MAX_HEARTS:
		_bud.startle()


func _on_won() -> void:
	if _level_over:
		return
	_level_over = true
	Game.stop_timer()

	# Kratka pauza da dete vidi kavez kako se otvara i Carlija kako skace,
	# pa tek onda winning screen.
	await get_tree().create_timer(1.2).timeout
	_win_screen.show_result(Game.stars_collected, Game.total_stars, Game.elapsed_string())


func _on_died() -> void:
	if _level_over:
		return
	Audio.play("gameover")
	_hud.show_banner("Probaj ponovo!\nPritisni R", Color(0.4, 0.45, 0.7), 3.0)
	await get_tree().create_timer(2.0).timeout
	_restart_soft()


## Blagi restart: vraca srca i nastavlja od poslednjeg cveta.
## Nivo se NE resetuje - skupljene zvezdice ostaju.
func _restart_soft() -> void:
	Game.hearts = Game.MAX_HEARTS
	Game.hearts_changed.emit(Game.hearts)
	var pos: Vector2 = Game.checkpoint_position if Game.has_checkpoint else START
	_eva.revive_at(pos)


func _restart() -> void:
	get_tree().reload_current_scene()
