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

## --- PRISTUP AUTOLOAD-IMA ---
##
## Eva se NE sme oslanjati na `Game` i `Audio` kao globalne identifikatore.
##
## Zasto: scenes/world_map.tscn je GLAVNA scena i ugrađuje scenes/eva.tscn
## kao ext_resource. Godot ucitava glavnu scenu PRE nego sto registruje
## autoload-e, pa u tom trenutku `Game` i `Audio` ne postoje i eva.gd pada
## sa "Identifier "Game" not declared in the current scope". Cela mapa je
## ostajala prazna - bez ostrva, puteva i tacaka.
##
## Lokalno se to NIJE videlo jer je .godot kes vec imao kompajlirani
## eva.gd; pucalo je samo u cistom CI buildu.
##
## Zato se autoload-i traze runtime, kroz /root. Konstante se citaju uz
## fallback na iste vrednosti kao u game.gd, da Eva radi i ako je ucitana
## pre autoload-a.

## MORA da prati game.gd - ako se razlikuje, Eva na mapi (koja se ucitava
## pre autoload-a) igra po drugoj fizici od Eve u nivou.
const FALLBACK := {
	"COYOTE_TIME": 0.25,
	"JUMP_BUFFER_TIME": 0.28,
	"INVULN_TIME": 2.0,
	"PLAYER_SPEED": 162.0,
	"PLAYER_JUMP_VELOCITY": -400.0,
	"PLAYER_GRAVITY_SCALE": 0.64,
}


## Konstanta iz Game autoload-a, sa fallback vrednoscu.
func _gc(key: String) -> float:
	var g := get_node_or_null("/root/Game")
	if g != null:
		var v: Variant = g.get(key)
		if v != null:
			return float(v)
	return float(FALLBACK[key])


## Game autoload, ili null ako jos ne postoji.
func _game() -> Node:
	return get_node_or_null("/root/Game")


## Zvuk kroz Audio autoload. Tiho preskoci ako autoload ne postoji.
func _sfx(name: String, pitch_var := 0.06) -> void:
	var a := get_node_or_null("/root/Audio")
	if a != null and a.has_method("play"):
		a.play(name, pitch_var)

## --- MOCI ---
## Postavlja nivo: "" (nista), "double_jump", "swim", "glide", "light".
var power := ""

## Dupli skok: da li je drugi skok jos dostupan.
var _air_jumps := 0
const AIR_JUMPS_MAX := 1

## Plivanje: da li je u vodi i da li ume da pliva.
var _in_water := false
var _can_swim := false
const SWIM_UP := -130.0        # koliko snazno pliva nagore
const SWIM_GRAVITY := 0.18     # u vodi gravitacija je slaba
const SWIM_MAX_FALL := 90.0

## Lebdenje: dok drzi skok u vazduhu, pada mnogo sporije.
const GLIDE_GRAVITY := 0.22


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
		_coyote_timer = _gc("COYOTE_TIME")
		_air_jumps = AIR_JUMPS_MAX      # dupli skok se puni na tlu
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	# U VODI: gravitacija je slaba, a drzanje skoka plivа nagore.
	if _in_water:
		var wg := _base_gravity * SWIM_GRAVITY
		if _can_swim and Input.is_action_pressed("jump"):
			velocity.y = maxf(velocity.y + SWIM_UP * delta * 6.0, SWIM_UP)
		else:
			velocity.y = minf(velocity.y + wg * delta, SWIM_MAX_FALL)
		return

	if is_on_floor():
		return

	var g := _base_gravity * _gc("PLAYER_GRAVITY_SCALE")

	# LEBDENJE: dok drzi skok i pada, spusta se kao na padobranu.
	if power == "glide" and velocity.y > 0.0 and Input.is_action_pressed("jump"):
		velocity.y = minf(velocity.y + _base_gravity * GLIDE_GRAVITY * delta, 110.0)
		return

	# Milost 1: kad drzi skok, skok se "produzava"; kad pusti, pada malo brze.
	#
	# Kazna za pustanje je BLAGA (1.2, ne 1.7). Merenje je pokazalo da je sa
	# 1.7 tap davao 113px a drzanje 171px - razlika od 51%, pa dete koje ne
	# drzi taster nije moglo da preskoci ni obicnu prazninu. Sa 1.2 tap nosi
	# 194px: prelazi sve, a drzanje i dalje nosi dalje.
	if velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		g *= 1.2

	velocity.y = minf(velocity.y + g * delta, 700.0)


func _handle_horizontal() -> void:
	var dir := Input.get_axis("move_left", "move_right")

	if absf(dir) > 0.01:
		# Milost 2: nema inercije/klizanja. Pusti taster - odmah stane.
		# Mario ima momentum; za dete je to izvor frustracije.
		velocity.x = dir * _gc("PLAYER_SPEED")
		_facing = 1 if dir > 0.0 else -1
		body_visual.scale.x = _facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, _gc("PLAYER_SPEED") * 0.4)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = _gc("JUMP_BUFFER_TIME")

	# U vodi skok = plivanje, obradjeno u _apply_gravity.
	if _in_water:
		return

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = _gc("PLAYER_JUMP_VELOCITY")
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_squash(0.7, 1.3)
		_sfx("jump")
		return

	# DUPLI SKOK: u vazduhu, ako je moc dostupna i jos ima skokova.
	if power == "double_jump" and _jump_buffer_timer > 0.0 and _air_jumps > 0:
		velocity.y = _gc("PLAYER_JUMP_VELOCITY") * 0.88
		_jump_buffer_timer = 0.0
		_air_jumps -= 1
		_squash(0.75, 1.25)
		_sfx("jump", 0.14)
		_spawn_jump_puff()


func _animate(delta: float) -> void:
	# Blago "dihanje" dok stoji, squash pri sletanju.
	if is_on_floor() and not _was_on_floor:
		_squash(1.3, 0.7)
		_sfx("land")

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
		velocity.y = _gc("PLAYER_JUMP_VELOCITY") * 0.75  # odskok
		_squash(1.2, 0.8)
		_sfx("stomp")


func _on_hurt(node: Node) -> void:
	if node.has_method("get_stomped"):
		hurt()


func hurt() -> void:
	if _invuln_timer > 0.0 or _is_dead:
		return

	var g := _game()
	if g != null:
		g.take_damage()
	_invuln_timer = _gc("INVULN_TIME")
	_sfx("hurt")

	# Odbacivanje unazad - jasan feedback bez gubitka pozicije.
	velocity = Vector2(-_facing * 140.0, -220.0)

	if g != null and int(g.hearts) <= 0:
		_die()


## Zove ga voda (Area2D iz nivoa) kad Eva ude/izade.
func enter_water(can_swim: bool) -> void:
	if _in_water:
		return
	_in_water = true
	_can_swim = can_swim
	# Ulazak u vodu koci pad - bez ovoga "propadne" kroz plicak.
	velocity.y = minf(velocity.y, 60.0)
	_sfx("land", 0.12)

	if not can_swim:
		# Ne ume da pliva - voda je opasna, gubi srce i vraca se.
		hurt()


func exit_water() -> void:
	_in_water = false


func is_in_water() -> bool:
	return _in_water


## Oblacic pri duplom skoku - vizualni znak da je moc iskoriscena.
func _spawn_jump_puff() -> void:
	var puff := Polygon2D.new()
	puff.color = Color(1, 1, 1, 0.7)
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a) * 0.6) * 7.0)
	puff.polygon = pts
	puff.position = Vector2(0, 12)
	add_child(puff)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "scale", Vector2(2.2, 1.2), 0.3)
	tw.tween_property(puff, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(puff.queue_free)


## Pad u rupu - nikad instant smrt, samo jedno srce i vracanje na checkpoint.
func fall_out() -> void:
	if _is_dead:
		return
	var g := _game()
	if g != null:
		g.take_damage()
	_sfx("hurt")
	if g != null and int(g.hearts) <= 0:
		_die()
	else:
		_respawn_at_checkpoint()


func _respawn_at_checkpoint() -> void:
	velocity = Vector2.ZERO
	_invuln_timer = _gc("INVULN_TIME")
	var g := _game()
	if g != null and bool(g.has_checkpoint):
		global_position = g.checkpoint_position
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
	_invuln_timer = _gc("INVULN_TIME")
