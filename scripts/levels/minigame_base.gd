extends Node2D
class_name MinigameBase
## Zajednicki temelj za mini-igre (spoji tacke, bojenje, obuci lutku...).
##
## Razlika od LevelBase: nema Eve, fizike ni skakanja. Dete resava
## zagonetku dodirom/klikom, pa se prijatelj oslobodi.
##
## Nivo koji nasledjuje popunjava _setup() i zove win() kad je resio.

const FriendScene := preload("res://scenes/friend.tscn")

## Ko se spasava.
var friend_kind := "maca"
## Naslov zadatka - sta dete treba da uradi.
var task_text := "Reši zagonetku!"

var _hud: CanvasLayer
var _win_screen: CanvasLayer
var _friend: Area2D
var _done := false
var _steps_done := 0
var _steps_total := 1


func _ready() -> void:
	_setup()

	Game.reset_run()
	Game.total_stars = _steps_total

	_build_friend()
	_wire_ui()
	_build_task_label()

	Audio.play_music()


## Nivo prepisuje ovo.
func _setup() -> void:
	pass


## Nivo zove ovo kad dete uradi jedan korak (npr. spoji dve tacke).
func step_done() -> void:
	_steps_done += 1
	Game.stars_collected = _steps_done
	Game.stars_changed.emit(_steps_done)
	Audio.play("star")


## Nivo zove ovo kad je zagonetka resena.
func win() -> void:
	if _done:
		return
	_done = true

	Audio.play("meow", 0.0)
	if not Audio.has_voice_win():
		Audio.play("win")
		Audio.play_win_music()

	Game.rescued_friend = _friend.friend_name() if _friend else "prijatelja"
	Game.stop_timer()
	Game.mark_completed(Game.current_level, _steps_done, Game.elapsed_seconds())
	Game.save_progress()

	_hud.show_banner("BRAVO!", Color(0.95, 0.4, 0.6), 1.6)
	await _celebrate_friend()
	_win_screen.show_result(_steps_done, _steps_total, Game.elapsed_string())


## Proslava: kavez se raspadne, prijatelj doleti u centar, poraste i
## poskakuje. Dete mora da VIDI koga je oslobodilo.
func _celebrate_friend() -> void:
	if _friend == null:
		await get_tree().create_timer(1.2).timeout
		return

	var cage: Node2D = _friend.get_node("Visual/Cage")

	# 1) Kavez puca - sipke se razlete na strane.
	var i := 0
	for bar in cage.get_children():
		if not (bar is Polygon2D):
			continue
		var b := bar as Polygon2D
		var dir := Vector2(-1.0 if i % 2 == 0 else 1.0, -0.5).normalized()
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(b, "position", b.position + dir * 90.0, 0.5) \
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "rotation", randf_range(-2.5, 2.5), 0.5)
		tw.tween_property(b, "modulate:a", 0.0, 0.5)
		i += 1

	Audio.play("stomp")
	# Prijatelj ide iznad crteza tokom proslave.
	_friend.z_index = 8
	await get_tree().create_timer(0.35).timeout

	# 2) Prijatelj skoci iz kaveza u centar ekrana i poraste.
	var vis: Node2D = _friend.get_node("Visual")
	var jump := create_tween()
	jump.set_parallel(true)
	jump.tween_property(_friend, "position", Vector2(0, 40), 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	jump.tween_property(_friend, "scale", Vector2(4.2, 4.2), 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	jump.tween_property(vis, "rotation", 0.0, 0.4)

	_burst_confetti(Vector2(0, 40))
	Audio.play("heart")
	await get_tree().create_timer(0.8).timeout

	# 3) Poskakuje od srece dok ceka panel.
	var hop := create_tween().set_loops(3)
	hop.tween_property(_friend, "position:y", 10.0, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop.tween_property(_friend, "position:y", 40.0, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(1.4).timeout


## Konfeti oko oslobodjenog prijatelja.
func _burst_confetti(center: Vector2) -> void:
	var cols := [Color(1, 0.85, 0.25), Color(0.98, 0.55, 0.75),
		Color(0.42, 0.72, 0.45), Color(0.35, 0.65, 0.95), Color(1, 1, 1)]
	for i in 34:
		var piece := Polygon2D.new()
		var sz := randf_range(6.0, 13.0)
		piece.color = cols[i % cols.size()]
		piece.polygon = PackedVector2Array([
			Vector2(-sz * 0.5, -sz * 0.5), Vector2(sz * 0.5, -sz * 0.5),
			Vector2(sz * 0.5, sz * 0.5), Vector2(-sz * 0.5, sz * 0.5)])
		piece.position = center
		piece.z_index = 6
		add_child(piece)

		var ang := TAU * float(i) / 34.0 + randf_range(-0.2, 0.2)
		var dist := randf_range(150.0, 340.0)
		var target := center + Vector2(cos(ang), sin(ang)) * dist

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(piece, "position", target, randf_range(0.7, 1.2)) \
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(piece, "rotation", randf_range(-7.0, 7.0), 1.1)
		tw.tween_property(piece, "modulate:a", 0.0, 1.1).set_delay(0.35)
		tw.chain().tween_callback(piece.queue_free)


func set_total_steps(n: int) -> void:
	_steps_total = n


## Prijatelj u kavezu, gore u sredini - dete vidi koga spasava.
func _build_friend() -> void:
	_friend = FriendScene.instantiate()
	_friend.set("kind", friend_kind)
	_friend.position = Vector2(-430, -150)
	_friend.scale = Vector2(1.7, 1.7)
	# Bez kolizije - u mini-igri se ne dotice, oslobadja se resavanjem.
	_friend.set_deferred("monitoring", false)
	add_child(_friend)


func _build_task_label() -> void:
	var lbl := Label.new()
	lbl.text = task_text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.2, 0.3, 0.45))
	lbl.add_theme_constant_override("outline_size", 9)
	lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.offset_left = -400.0
	lbl.offset_right = 400.0
	lbl.offset_top = 16.0
	lbl.offset_bottom = 60.0
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var layer := CanvasLayer.new()
	layer.layer = 5
	layer.add_child(lbl)
	add_child(layer)


func _wire_ui() -> void:
	_hud = get_node("HUD")
	_win_screen = get_node("WinScreen")
	_win_screen.map_requested.connect(_go_to_map)
	_win_screen.replay_requested.connect(_restart)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_restart()
	if Input.is_action_just_pressed("world_map"):
		_go_to_map()
	if Input.is_action_just_pressed("mute"):
		Audio.toggle_mute()


func _restart() -> void:
	get_tree().reload_current_scene()


func _go_to_map() -> void:
	Audio.stop_music()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
