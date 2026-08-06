extends Node2D
class_name LevelBase
## Zajednicki temelj za sve nivoe.
##
## Nivo koji nasledjuje ovo popunjava `_setup()` sa svojim sadrzajem:
##   platforms, water, stars, animals, checkpoints, friend...
## Sve ostalo (Eva, Budzumbora, HUD, kamera, pobeda, restart) radi samo.
##
## Primer minimalnog nivoa:
##   extends LevelBase
##   func _setup() -> void:
##       biome = "livada"
##       start = Vector2(40, -40)
##       add_ground(Rect2(0, 0, 400, 48))
##       add_star(Vector2(120, -40))
##       set_friend(Vector2(360, -40), "maca")

const EvaScene := preload("res://scenes/eva.tscn")
const BudScene := preload("res://scenes/budzumbora.tscn")
const StarScene := preload("res://scenes/star.tscn")
const CheckpointScene := preload("res://scenes/checkpoint.tscn")
const FriendScene := preload("res://scenes/friend.tscn")
const PuzScene := preload("res://scenes/puz.tscn")
const KornjacaScene := preload("res://scenes/kornjaca.tscn")

## --- Sta nivo postavlja u _setup() ---

## Bioma odredjuje boje tla i neba.
var biome := "livada"
## Gde Eva pocinje.
var start := Vector2(40, -40)
## Ispod ovoga se racuna da je pala.
var fall_limit := 400.0
## Koju moc Eva ima u ovom nivou ("", "double_jump", "swim", "glide", "light").
var power := ""

var _platforms: Array = []      # [Rect2, tip] - tip: "ground"/"stone"/"ice"/"sand"/"wood"
var _waters: Array[Rect2] = []
var _stars: Array[Vector2] = []
var _checkpoints: Array[Vector2] = []
var _animals: Array = []        # [tip, pozicija]
var _friend_pos := Vector2.ZERO
var _friend_kind := "maca"
var _decor_fn: Callable = Callable()

## --- Interno ---

var _eva: CharacterBody2D
var _bud: Node2D
var _hud: CanvasLayer
var _win_screen: CanvasLayer
var _level_over := false
var _world: StaticBody2D


func _ready() -> void:
	_setup()

	Game.reset_run()
	_build_world()
	_spawn_actors()
	_wire_ui()

	_hud.show_banner(intro_text(), Color(0.2, 0.35, 0.6), 2.5)
	Audio.play_music()


## Nivo prepisuje ovo i puni svoj sadrzaj.
func _setup() -> void:
	pass


## Nivo moze da prepise uputstvo na pocetku.
func intro_text() -> String:
	if power == "double_jump":
		return "Dupli skok!\nPritisni SPACE dva puta"
	if power == "swim":
		return "Eva ume da pliva!\nUdji u vodu"
	if power == "glide":
		return "Eva lebdi!\nDrzi SPACE u vazduhu"
	return "Idi desno!\nSPACE = skok"


## --- API koji nivo koristi u _setup() ---

func add_ground(r: Rect2, kind := "ground") -> void:
	_platforms.append([r, kind])


func add_water(r: Rect2) -> void:
	_waters.append(r)


func add_star(p: Vector2) -> void:
	_stars.append(p)


## Vise zvezdica u nizu - cesto se koristi za "trag" preko rupe.
func add_star_line(from: Vector2, to: Vector2, count: int) -> void:
	for i in count:
		var t := float(i) / maxf(float(count - 1), 1.0)
		_stars.append(from.lerp(to, t))


func add_checkpoint(p: Vector2) -> void:
	_checkpoints.append(p)


func add_animal(kind: String, p: Vector2) -> void:
	_animals.append([kind, p])


func set_friend(p: Vector2, kind := "maca") -> void:
	_friend_pos = p
	_friend_kind = kind


## Nivo moze da doda svoj dekor (pozadina, pecine, biljke).
func set_decor(fn: Callable) -> void:
	_decor_fn = fn


## --- Gradnja sveta ---

func _build_world() -> void:
	_world = StaticBody2D.new()
	_world.name = "World"
	_world.collision_layer = 1
	_world.collision_mask = 0
	add_child(_world)

	# Dekor prvo - ide iza svega.
	if _decor_fn.is_valid():
		_decor_fn.call(self)

	for entry in _platforms:
		LevelArt.draw_platform(_world, entry[0], String(entry[1]))

	for r in _waters:
		_add_water_body(r)

	Game.total_stars = _stars.size()
	for p in _stars:
		var s := StarScene.instantiate()
		s.position = p
		add_child(s)

	for p in _checkpoints:
		var c := CheckpointScene.instantiate()
		c.position = p
		add_child(c)

	for entry in _animals:
		_spawn_animal(String(entry[0]), entry[1])

	if _friend_pos != Vector2.ZERO:
		var f := FriendScene.instantiate()
		f.position = _friend_pos
		f.set("kind", _friend_kind)
		add_child(f)


## Voda: Area2D koja gura Evu nagore (pliva) ili je vraca (bez moci).
func _add_water_body(r: Rect2) -> void:
	var area := Area2D.new()
	area.name = "Water"
	area.collision_layer = 16
	area.collision_mask = 2
	area.position = r.position + r.size * 0.5

	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = r.size
	shape.shape = box
	area.add_child(shape)
	add_child(area)

	LevelArt.draw_water(self, r)

	area.body_entered.connect(func(body: Node) -> void:
		if body.has_method("enter_water"):
			body.enter_water(power == "swim")
	)
	area.body_exited.connect(func(body: Node) -> void:
		if body.has_method("exit_water"):
			body.exit_water()
	)


func _spawn_animal(kind: String, pos: Vector2) -> void:
	var scene: PackedScene
	match kind:
		"puz": scene = PuzScene
		"kornjaca": scene = KornjacaScene
		_: scene = PuzScene
	var a := scene.instantiate()
	a.position = pos
	add_child(a)


func _spawn_actors() -> void:
	_eva = EvaScene.instantiate()
	_eva.position = start
	add_child(_eva)
	if power != "":
		_eva.set("power", power)

	_bud = BudScene.instantiate()
	_bud.position = start + Vector2(-34, -14)
	add_child(_bud)
	_bud.follow(_eva)

	Game.set_checkpoint(start)


func _wire_ui() -> void:
	_hud = get_node("HUD")
	_win_screen = get_node("WinScreen")
	_win_screen.map_requested.connect(_go_to_map)
	# Dugme MAPA iz HUD-a - vidljivo tokom cele igre.
	if _hud.has_signal("map_requested"):
		_hud.map_requested.connect(_go_to_map)
	_win_screen.replay_requested.connect(_restart)
	Game.level_won.connect(_on_won)
	Game.player_died.connect(_on_died)
	Game.hearts_changed.connect(_on_hearts_changed)


## --- Tok igre ---

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_restart()

	if Input.is_action_just_pressed("mute"):
		Audio.toggle_mute()
		_hud.show_banner("Zvuk ISKLJUCEN" if Audio.is_muted() else "Zvuk UKLJUCEN",
			Color(0.35, 0.4, 0.5), 1.0)

	if Input.is_action_just_pressed("world_map"):
		_go_to_map()

	if _eva != null and not _level_over and _eva.global_position.y > fall_limit:
		_eva.fall_out()


func _on_hearts_changed(value: int) -> void:
	if _bud != null and _bud.has_method("startle") and value < Game.MAX_HEARTS:
		_bud.startle()


func _on_won() -> void:
	if _level_over:
		return
	_level_over = true
	Game.stop_timer()
	Game.mark_completed(Game.current_level, Game.stars_collected, Game.elapsed_seconds())
	Game.save_progress()

	await get_tree().create_timer(1.2).timeout
	_win_screen.show_result(Game.stars_collected, Game.total_stars, Game.elapsed_string())


func _on_died() -> void:
	if _level_over:
		return
	Audio.play("gameover")
	_hud.show_banner("Probaj ponovo!", Color(0.4, 0.45, 0.7), 3.0)
	await get_tree().create_timer(2.0).timeout
	_restart_soft()


func _restart_soft() -> void:
	Game.hearts = Game.MAX_HEARTS
	Game.hearts_changed.emit(Game.hearts)
	var pos: Vector2 = Game.checkpoint_position if Game.has_checkpoint else start
	_eva.revive_at(pos)


func _restart() -> void:
	get_tree().reload_current_scene()


func _go_to_map() -> void:
	# Mapa treba da oznaci OVAJ nivo, ne sledeci.
	Game.returning_from_level = true
	Audio.stop_music()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
