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
var _hazards: Array = []        # [Rect2, tip] - "hot_sand"/"lava"/"trnje"
var _fragiles: Array = []       # [Rect2, tip, delay, respawn] - krhke platforme
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
	Audio.play_biome_music(biome)


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


## Opasna zona koja odbija Evu na dodir (vruc pesak, lava, trnje).
##
## Razlika od vode: nema plivanja, uvek boli. `kind` odredjuje boju i
## detalje - vidi _add_hazard_body().
func add_hazard(r: Rect2, kind := "hot_sand") -> void:
	_hazards.append([r, kind])


## Krhka platforma: pukne kratko posle sto Eva stane na nju.
##
## Za dete od 5 godina je vazno da ima UPOZORENJE - platforma se prvo
## zatrese i promeni boju, pa tek onda padne. `delay` je koliko traje to
## upozorenje (podrazumevano 0.9s, dovoljno da dete odskoci bez trke).
##
## Vraca se posle `respawn` sekundi, pa nivo nikad ne postane neprohodan.
func add_fragile(r: Rect2, kind := "ice", delay := 0.9, respawn := 2.6) -> void:
	_fragiles.append([r, kind, delay, respawn])


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

	for entry in _hazards:
		_add_hazard_body(entry[0], String(entry[1]))

	for entry in _fragiles:
		_add_fragile(entry[0], String(entry[1]), float(entry[2]), float(entry[3]))

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


## Opasna zona: boli na dodir, bez plivanja i bez izuzetka.
##
## Koristi isti sloj kao voda (16) i istu masku (2 = Eva), ali zove hurt()
## umesto enter_water(). Za dete je pravilo jednostavno: ako je narandzasto
## i mreska se, ne staje se na to.
func _add_hazard_body(r: Rect2, kind: String) -> void:
	var area := Area2D.new()
	area.name = "Hazard"
	area.collision_layer = 16
	area.collision_mask = 2
	area.position = r.position + r.size * 0.5

	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = r.size
	shape.shape = box
	area.add_child(shape)
	add_child(area)

	_draw_hazard(r, kind)

	area.body_entered.connect(func(body: Node) -> void:
		if body.has_method("hurt"):
			body.hurt()
	)


## Vizual opasne zone. Mora da bude OCIGLEDNO opasno na prvi pogled -
## dete od 5 godina ne cita uputstva.
func _draw_hazard(r: Rect2, kind: String) -> void:
	var holder := Node2D.new()
	holder.z_index = 2
	add_child(holder)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 31 + int(r.position.y)

	var base := Color(0.95, 0.45, 0.15, 0.85)      # hot_sand
	var glow := Color(1, 0.72, 0.25, 0.55)
	var spark := Color(1, 0.95, 0.6, 0.9)
	if kind == "lava":
		base = Color(0.9, 0.25, 0.1, 0.92)
		glow = Color(1, 0.55, 0.15, 0.6)

	# Telo zone.
	_hz_poly(holder, base, [
		r.position + Vector2(0, 4), r.position + Vector2(r.size.x, 4),
		r.position + r.size, r.position + Vector2(0, r.size.y)])

	# Plamenovi koji izlaze IZNAD povrsine.
	#
	# Prva verzija ih je crtala na r.position.y, gde je i nivo tla, pa se
	# na snimku videla samo ravna narandzasta traka. Sada su siljci vidno
	# iznad ivice i u dve boje, da se zona cita kao opasna iz daljine.
	var teeth := maxi(3, int(r.size.x / 22.0))
	for i in teeth:
		var x0 := r.position.x + r.size.x * float(i) / float(teeth)
		var x1 := r.position.x + r.size.x * float(i + 1) / float(teeth)
		var mid := (x0 + x1) * 0.5
		var peak := rng.randf_range(20.0, 34.0)
		# Vanjski, tamniji plamen.
		_hz_poly(holder, base, [
			Vector2(x0, r.position.y + 6), Vector2(mid, r.position.y - peak),
			Vector2(x1, r.position.y + 6)])
		# Unutrasnji, svetliji - daje "zar".
		_hz_poly(holder, glow, [
			Vector2(x0 + (mid - x0) * 0.42, r.position.y + 4),
			Vector2(mid, r.position.y - peak * 0.62),
			Vector2(x1 - (x1 - mid) * 0.42, r.position.y + 4)])

	# Iskre koje lebde gore - pokret privlaci paznju.
	for i in maxi(2, int(r.size.x / 60.0)):
		var sx := rng.randf_range(r.position.x + 8.0, r.position.x + r.size.x - 8.0)
		var s := Polygon2D.new()
		var sz := rng.randf_range(3.0, 6.0)
		s.color = spark
		s.polygon = PackedVector2Array([
			Vector2(0, -sz), Vector2(sz * 0.7, 0),
			Vector2(0, sz), Vector2(-sz * 0.7, 0)])
		# Iskre polaze sa VRHA plamena, ne sa nivoa tla - inace su
		# zaklonjene telom zone i ne vide se.
		var y_start := r.position.y - 18.0
		s.position = Vector2(sx, y_start)
		holder.add_child(s)

		var rise := rng.randf_range(38.0, 66.0)
		var t := rng.randf_range(1.1, 2.0)
		var tw := create_tween().set_loops()
		tw.tween_property(s, "position:y", y_start - rise, t) \
			.set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(s, "modulate:a", 0.0, t)
		tw.tween_callback(func() -> void:
			s.position.y = y_start
			s.modulate.a = 1.0
		)


func _hz_poly(parent: Node2D, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)


## Krhka platforma: puca kratko posle sto Eva stane, pa se vrati.
##
## Kljucno za dete: ima UPOZORENJE. Platforma se zatrese i pobeli pre nego
## sto padne, tako da dete vidi sta se desava i ima vremena da odskoci.
## Bez upozorenja bi ovo bila zamka, ne izazov.
##
## Vraca se posle `respawn` sekundi - nivo nikad ne postane neprohodan
## ako dete pogresi.
func _add_fragile(r: Rect2, kind: String, delay: float, respawn: float) -> void:
	# Svoj StaticBody2D, ne _world - da moze da se sakrije nezavisno.
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	# Ime se postavlja POSLE add_child: pre toga Godot ionako dodeli
	# auto-ime pri dodavanju, pa je samo prvi cvor dobijao "Fragile" a
	# ostali "@StaticBody2D@...". Sa pozicijom u imenu se u debugu odmah
	# vidi o kojoj je ploci rec.
	body.name = "Fragile_%d" % int(r.position.x)

	LevelArt.draw_platform(body, r, kind)

	# Detektor: Area2D malo iznad platforme, hvata Evu kad stane.
	var probe := Area2D.new()
	probe.collision_layer = 0
	probe.collision_mask = 2
	probe.position = r.position + Vector2(r.size.x * 0.5, -6.0)
	var pshape := CollisionShape2D.new()
	var pbox := RectangleShape2D.new()
	pbox.size = Vector2(r.size.x, 14.0)
	pshape.shape = pbox
	probe.add_child(pshape)
	add_child(probe)

	var triggered := [false]
	probe.body_entered.connect(func(who: Node) -> void:
		if triggered[0] or not who.is_in_group("player"):
			return
		triggered[0] = true
		_break_fragile(body, probe, r, kind, delay, respawn, triggered)
	)


func _break_fragile(body: StaticBody2D, probe: Area2D, r: Rect2, kind: String,
		delay: float, respawn: float, triggered: Array) -> void:
	# 1) UPOZORENJE: trese se i beli.
	var shake := create_tween().set_loops(int(delay / 0.1))
	shake.tween_property(body, "position:x", 3.0, 0.05)
	shake.tween_property(body, "position:x", -3.0, 0.05)
	var warn := create_tween()
	warn.tween_property(body, "modulate", Color(1.5, 1.5, 1.7), delay * 0.7)

	Audio.play("land", 0.2)
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return

	# 2) PADA: kolizija se gasi, krhotine padaju.
	body.position.x = 0.0
	body.collision_layer = 0
	_fragile_shards(r, kind)

	var fall := create_tween()
	fall.tween_property(body, "modulate:a", 0.0, 0.25)
	Audio.play("stomp", 0.15)

	# 3) VRACA SE - nivo ostaje prohodan i posle greske.
	await get_tree().create_timer(respawn).timeout
	if not is_inside_tree():
		return
	body.modulate = Color(1, 1, 1, 0)
	body.collision_layer = 1
	var back := create_tween()
	back.tween_property(body, "modulate", Color(1, 1, 1, 1), 0.4)
	Audio.play("checkpoint", 0.15)
	triggered[0] = false


## Krhotine kad platforma pukne - dete vidi da je nesto palo.
func _fragile_shards(r: Rect2, kind: String) -> void:
	var col := Color(0.85, 0.94, 0.99)
	if kind == "lava_rock":
		col = Color(0.35, 0.3, 0.32)
	elif kind == "stone":
		col = Color(0.62, 0.6, 0.58)

	for i in 7:
		var sh := Polygon2D.new()
		var sz := randf_range(6.0, 13.0)
		sh.color = col
		sh.polygon = PackedVector2Array([
			Vector2(-sz, 0), Vector2(0, -sz * 0.8),
			Vector2(sz, 0), Vector2(0, sz * 0.7)])
		sh.position = Vector2(
			r.position.x + r.size.x * (float(i) + 0.5) / 7.0,
			r.position.y + 6.0)
		sh.z_index = 3
		add_child(sh)

		# Krhotine padaju JEDNOM i nestanu - bez set_loops.
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(sh, "position",
			sh.position + Vector2(randf_range(-30, 30), 120.0), 0.8) \
			.set_ease(Tween.EASE_IN)
		tw.tween_property(sh, "rotation", randf_range(-4.0, 4.0), 0.8)
		tw.tween_property(sh, "modulate:a", 0.0, 0.8).set_delay(0.2)
		tw.chain().tween_callback(sh.queue_free)


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
