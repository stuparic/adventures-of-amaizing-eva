extends CharacterBody2D
## Eva - devojcica od 5 godina, plava kosa, plave oci.
## Kontrole: strelice/WASD za kretanje, SPACE/gore za skok. Radi i gamepad.

signal died
signal respawned

@onready var body_visual: Node2D = $Visual
@onready var stomp_area: Area2D = $StompArea
@onready var hurt_area: Area2D = $HurtArea
@onready var camera: Camera2D = $Camera

## Koliko sirok deo sveta kamera pokazuje, u pikselima.
## MANJI broj = VECI likovi.
const WORLD_WIDTH_PHONE := 300.0     # telefon: likovi krupni
const WORLD_WIDTH_TABLET := 430.0
const WORLD_WIDTH_DESKTOP := 560.0

## Telefon se prepoznaje po KRACOJ strani ekrana, ne po sirini:
## telefon u landscape-u je npr. 844x390 - sirok je, ali je i dalje telefon.
## Sirina bi ga pogresno svrstala u desktop i likovi bi ispali sitni.
const PHONE_MAX_SHORT_SIDE := 500.0
const TABLET_MAX_SHORT_SIDE := 780.0

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _invuln_timer := 0.0
var _was_on_floor := false
var _is_dead := false
var _facing := 1

var _base_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 900.0)


func _ready() -> void:
	add_to_group("player")
	stomp_area.body_entered.connect(_on_stomp)
	hurt_area.body_entered.connect(_on_hurt)

	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)


## Namesti zum tako da likovi budu iste velicine na svakom ekranu.
##
## Bez ovoga: zum je fiksan, pa na telefonu (uzak ekran) kamera pokazuje
## previse sveta i Eva ispadne sitna - tekst i likovi se ne vide.
func _fit_camera() -> void:
	# Racunaj iz VELICINE PROZORA, ne iz visible_rect: visible_rect je
	# virtualna velicina (1280 px) koju stretch daje, a nama treba stvarna
	# sirina ekrana da znamo da li je telefon.
	var win := DisplayServer.window_get_size()
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or win.x <= 0 or win.y <= 0:
		return

	# Kraca strana odredjuje klasu uredjaja - radi i u portretu i u landscape-u.
	var short_side := float(mini(win.x, win.y))
	var target_width := WORLD_WIDTH_DESKTOP
	if short_side < PHONE_MAX_SHORT_SIDE:
		target_width = WORLD_WIDTH_PHONE
	elif short_side < TABLET_MAX_SHORT_SIDE:
		target_width = WORLD_WIDTH_TABLET

	var z := vp.x / target_width
	camera.zoom = Vector2(z, z)
	camera.offset = Vector2(24.0, 10.0) * (2.25 / z)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_tick_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal()
	_handle_jump()

	_was_on_floor = is_on_floor()
	move_and_slide()
	_animate(delta)


func _tick_timers(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		# Blinkanje dok je neranjiva - vizualni signal detetu.
		body_visual.visible = fmod(_invuln_timer, 0.16) > 0.08
		if _invuln_timer <= 0.0:
			body_visual.visible = true

	if is_on_floor():
		_coyote_timer = Game.COYOTE_TIME
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var g := _base_gravity * Game.PLAYER_GRAVITY_SCALE

	# Milost 1: kad drzi skok, pada jos sporije -> skok se "produzava",
	# a kad pusti, pada malo brze. Daje osecaj kontrole bez preciznosti.
	if velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		g *= 1.7

	velocity.y = minf(velocity.y + g * delta, 700.0)


func _handle_horizontal() -> void:
	var dir := Input.get_axis("move_left", "move_right")

	if absf(dir) > 0.01:
		# Milost 2: nema inercije/klizanja. Pusti taster - odmah stane.
		# Mario ima momentum; za dete je to izvor frustracije.
		velocity.x = dir * Game.PLAYER_SPEED
		_facing = 1 if dir > 0.0 else -1
		body_visual.scale.x = _facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, Game.PLAYER_SPEED * 0.4)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = Game.JUMP_BUFFER_TIME

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = Game.PLAYER_JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_squash(0.7, 1.3)
		Audio.play("jump")


func _animate(delta: float) -> void:
	# Blago "dihanje" dok stoji, squash pri sletanju.
	if is_on_floor() and not _was_on_floor:
		_squash(1.3, 0.7)
		Audio.play("land")

	body_visual.scale.x = move_toward(body_visual.scale.x, float(_facing), delta * 6.0)
	body_visual.scale.y = move_toward(body_visual.scale.y, 1.0, delta * 6.0)


func _squash(sx: float, sy: float) -> void:
	body_visual.scale = Vector2(sx * _facing, sy)


## --- Interakcije ---

func _on_stomp(node: Node) -> void:
	# Skok na zivotinju je odozgo: mora da pada da bi se racunalo.
	if velocity.y <= 0.0:
		return
	if node.has_method("get_stomped"):
		node.get_stomped()
		velocity.y = Game.PLAYER_JUMP_VELOCITY * 0.75  # odskok
		_squash(1.2, 0.8)
		Audio.play("stomp")


func _on_hurt(node: Node) -> void:
	if node.has_method("get_stomped"):
		hurt()


func hurt() -> void:
	if _invuln_timer > 0.0 or _is_dead:
		return

	Game.take_damage()
	_invuln_timer = Game.INVULN_TIME
	Audio.play("hurt")

	# Odbacivanje unazad - jasan feedback bez gubitka pozicije.
	velocity = Vector2(-_facing * 140.0, -220.0)

	if Game.hearts <= 0:
		_die()


## Pad u rupu - nikad instant smrt, samo jedno srce i vracanje na checkpoint.
func fall_out() -> void:
	if _is_dead:
		return
	Game.take_damage()
	Audio.play("hurt")
	if Game.hearts <= 0:
		_die()
	else:
		_respawn_at_checkpoint()


func _respawn_at_checkpoint() -> void:
	velocity = Vector2.ZERO
	_invuln_timer = Game.INVULN_TIME
	if Game.has_checkpoint:
		global_position = Game.checkpoint_position
	respawned.emit()


func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	died.emit()


func revive_at(pos: Vector2) -> void:
	_is_dead = false
	velocity = Vector2.ZERO
	global_position = pos
	body_visual.visible = true
	_invuln_timer = Game.INVULN_TIME
