extends Node2D
## ZAVRSNI VIDEO - pusta se kad Eva predje CELU igru.
##
## Nije pravi video fajl nego animirana scena: fajl bi bio desetine
## megabajta, a ovo je nekoliko kilobajta koda i radi na svakom ekranu.
##
## Sest scena, oko 40 sekundi ukupno:
##   1. "BRAVO EVA!" - naslov ulece
##   2. Eva i Budzumbora dolaze sa strane
##   3. Svih 14 prijatelja slecu jedan po jedan i masu
##   4. Zajednicka fotografija - svi poskakuju
##   5. Vatromet i konfeti
##   6. "HVALA!" i dugme za mapu
##
## Dete moze da preskoci dodirom u svakom trenutku - 40 sekundi je dugo
## ako je vec videlo.

const FriendScene := preload("res://scenes/friend.tscn")
const EvaScene := preload("res://scenes/eva.tscn")
const BudScene := preload("res://scenes/budzumbora.tscn")

## Svi prijatelji po redu nivoa - isti redosled kao u Game.LEVELS.
## Svi prijatelji, u redu u kom se spasavaju.
##
## MORA da prati Game.LEVELS: svaki nivo ima svog prijatelja i finale ih
## prikazuje sve. Ako se doda nivo a ovo se ne dopuni, novi prijatelj
## nedostaje na zavrsnoj slici. Provereno testom koji uporedjuje ova dva
## spiska.
const ALL_FRIENDS: Array[String] = [
	"maca", "zeka", "veverica", "delfin", "ptica",
	"panda", "koala", "kornjaca", "lisica", "sova",
	"pingvin", "jez", "macak", "kuca",
	# Drugi red arhipelaga.
	"hobotnica", "morskikonj", "labud", "zmaj", "slepimis", "krtica",
	"jelen", "vila", "medvedic", "vevericaB", "vanzemaljac", "robot",
	"dabar", "vidra", "crvenapanda", "zmajcic", "mornarka", "rakic",
	"feniks",
]

var _sky: ColorRect
var _title: Label
var _subtitle: Label
var _stage: Node2D
var _friends: Array[Node2D] = []
var _skip_hint: Label
var _done := false
var _tw: Tween


func _ready() -> void:
	_build_background()
	_build_labels()
	_stage = Node2D.new()
	add_child(_stage)

	Audio.play_biome_music("livada")
	_run()


## Dodir/klik/taster preskace na kraj.
func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventKey:
		pressed = (event as InputEventKey).pressed
	if pressed and not _done:
		_finish()
		get_viewport().set_input_as_handled()


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	_sky = ColorRect.new()
	_sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky.color = Color(0.35, 0.62, 0.9)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_sky)


func _build_labels() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 76)
	_title.add_theme_color_override("font_color", Color(1, 0.94, 0.35))
	_title.add_theme_color_override("font_outline_color", Color(0.55, 0.2, 0.35))
	_title.add_theme_constant_override("outline_size", 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.offset_left = -600.0
	_title.offset_right = 600.0
	_title.offset_top = 40.0
	_title.offset_bottom = 140.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.modulate.a = 0.0
	layer.add_child(_title)

	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 34)
	_subtitle.add_theme_color_override("font_color", Color(1, 1, 1))
	_subtitle.add_theme_color_override("font_outline_color", Color(0.2, 0.35, 0.55))
	_subtitle.add_theme_constant_override("outline_size", 10)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_subtitle.offset_left = -600.0
	_subtitle.offset_right = 600.0
	_subtitle.offset_top = 132.0
	_subtitle.offset_bottom = 190.0
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.modulate.a = 0.0
	layer.add_child(_subtitle)

	# Podsetnik da moze da se preskoci - malo, dole, da ne odvlaci paznju.
	_skip_hint = Label.new()
	_skip_hint.text = "dodirni da preskočiš"
	_skip_hint.add_theme_font_size_override("font_size", 17)
	_skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_hint.offset_left = -300.0
	_skip_hint.offset_right = 300.0
	_skip_hint.offset_top = -44.0
	_skip_hint.offset_bottom = -14.0
	_skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_skip_hint)


## --- TOK VIDEA ---

func _run() -> void:
	# 1) NASLOV
	_title.text = "BRAVO EVA!"
	_subtitle.text = "Spasila si sve prijatelje!"
	_fade_in(_title, 0.7)
	await get_tree().create_timer(0.4).timeout
	if _done: return
	_fade_in(_subtitle, 0.6)
	_pulse(_title)
	Audio.play("win")
	await get_tree().create_timer(1.8).timeout
	if _done: return

	# 2) EVA I BUDZUMBORA ULAZE
	var eva := EvaScene.instantiate()
	eva.set_script(null)          # bez fizike - ovo je scena, ne igra
	eva.position = Vector2(-760, 118)
	eva.scale = Vector2(4.2, 4.2)
	_stage.add_child(eva)

	var bud := BudScene.instantiate()
	bud.set_script(null)
	bud.position = Vector2(-880, 126)
	bud.scale = Vector2(4.2, 4.2)
	_stage.add_child(bud)

	var walk := create_tween()
	walk.set_parallel(true)
	walk.tween_property(eva, "position", Vector2(-390, 118), 1.6) \
		.set_trans(Tween.TRANS_SINE)
	walk.tween_property(bud, "position", Vector2(-520, 126), 1.6) \
		.set_trans(Tween.TRANS_SINE)
	_hop(eva, 8.0, 0.34)
	_hop(bud, 6.0, 0.4)
	await get_tree().create_timer(1.8).timeout
	if _done: return

	# 3) PRIJATELJI SLECU JEDAN PO JEDAN
	_subtitle.text = "Svi su slobodni!"
	var n := ALL_FRIENDS.size()
	for i in n:
		if _done: return
		var f := FriendScene.instantiate()
		f.set("kind", ALL_FRIENDS[i])
		f.set_deferred("monitoring", false)
		# Dva reda, da se svih 14 vidi bez gužve.
		var row := i / 7
		var col := i % 7
		var target := Vector2(-180.0 + float(col) * 118.0, -40.0 + float(row) * 150.0)
		f.position = target + Vector2(0, -700)     # dolazi odozgo
		f.scale = Vector2(2.1, 2.1)
		_stage.add_child(f)
		_friends.append(f)

		# Kavez je otvoren - ovo su slobodni prijatelji.
		var cage: Node2D = f.get_node_or_null("Visual/Cage")
		if cage != null:
			cage.visible = false

		var drop := create_tween()
		drop.tween_property(f, "position", target, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Audio.play("star", 0.2)
		await get_tree().create_timer(0.24).timeout

	if _done: return
	await get_tree().create_timer(0.5).timeout
	if _done: return

	# 4) ZAJEDNICKA FOTOGRAFIJA - svi poskakuju
	_title.text = "SVI ZAJEDNO!"
	_subtitle.text = "14 prijatelja"
	for i in _friends.size():
		_hop(_friends[i], 16.0, 0.4 + float(i % 3) * 0.06)
	Audio.play("heart")
	await get_tree().create_timer(1.6).timeout
	if _done: return

	# 5) VATROMET
	for burst in 5:
		if _done: return
		_firework(Vector2(randf_range(-450.0, 450.0), randf_range(-260.0, -60.0)))
		Audio.play("star", 0.25)
		await get_tree().create_timer(0.5).timeout

	if _done: return
	await get_tree().create_timer(0.8).timeout
	_finish()


## Kraj - naslov "HVALA" i dugme na mapu.
func _finish() -> void:
	if _done:
		return
	_done = true
	if _tw != null and _tw.is_valid():
		_tw.kill()

	_title.text = "HVALA!"
	_title.modulate.a = 1.0
	_subtitle.text = "Evine Avanture"
	_subtitle.modulate.a = 1.0
	_skip_hint.visible = false

	_burst_confetti(Vector2(0, -60), 60)
	Audio.play("win")
	_build_exit_button()


func _build_exit_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)

	var btn := Button.new()
	btn.text = "NA MAPU"
	btn.focus_mode = Control.FOCUS_NONE   # inace SPACE/Enter okida dugme
	btn.custom_minimum_size = Vector2(260, 78)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_left = -130.0
	btn.offset_right = 130.0
	btn.offset_top = -120.0
	btn.offset_bottom = -42.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.35, 0.62, 0.88)
	sb.border_color = Color(1, 1, 1, 0.9)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	btn.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = Color(0.45, 0.72, 0.96)
	btn.add_theme_stylebox_override("hover", sb2)
	btn.add_theme_stylebox_override("pressed", sb2)
	btn.add_theme_stylebox_override("focus", sb)

	btn.pressed.connect(func() -> void:
		Audio.play("checkpoint")
		Game.returning_from_level = true
		get_tree().change_scene_to_file("res://scenes/world_map.tscn")
	)
	layer.add_child(btn)


## --- Efekti ---

func _fade_in(node: CanvasItem, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 1.0, dur)


## Naslov blago pulsira - ziv ekran bez naglih pokreta.
func _pulse(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.06, 1.06), 0.7) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	tw.set_loops()
	_tw = tw


func _hop(node: Node2D, height: float, period: float) -> void:
	var base := node.position.y
	var tw := create_tween()
	tw.tween_property(node, "position:y", base - height, period) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position:y", base, period) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.set_loops()


## Vatromet: iskre se razlete iz tacke pa padnu.
func _firework(center: Vector2) -> void:
	var cols := [Color(1, 0.85, 0.3), Color(0.98, 0.45, 0.6),
		Color(0.5, 0.85, 1), Color(0.6, 1, 0.7), Color(1, 1, 1)]
	var col: Color = cols[randi() % cols.size()]
	for i in 24:
		var s := Polygon2D.new()
		var sz := randf_range(4.0, 8.0)
		s.color = col
		s.polygon = PackedVector2Array([
			Vector2(0, -sz), Vector2(sz * 0.6, 0),
			Vector2(0, sz), Vector2(-sz * 0.6, 0)])
		s.position = center
		s.z_index = 5
		_stage.add_child(s)

		var ang := TAU * float(i) / 24.0
		var dist := randf_range(90.0, 190.0)
		var mid := center + Vector2(cos(ang), sin(ang)) * dist

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", mid, 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 0.0, 0.9).set_delay(0.3)
		tw.chain().tween_callback(s.queue_free)


func _burst_confetti(center: Vector2, count: int) -> void:
	var cols := [Color(1, 0.85, 0.25), Color(0.98, 0.55, 0.75),
		Color(0.42, 0.72, 0.45), Color(0.35, 0.65, 0.95), Color(1, 1, 1)]
	for i in count:
		var piece := Polygon2D.new()
		var sz := randf_range(7.0, 15.0)
		piece.color = cols[i % cols.size()]
		piece.polygon = PackedVector2Array([
			Vector2(-sz * 0.5, -sz * 0.5), Vector2(sz * 0.5, -sz * 0.5),
			Vector2(sz * 0.5, sz * 0.5), Vector2(-sz * 0.5, sz * 0.5)])
		piece.position = center + Vector2(randf_range(-120, 120), 0)
		piece.z_index = 6
		_stage.add_child(piece)

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(piece, "position",
			piece.position + Vector2(randf_range(-260, 260), randf_range(420, 620)),
			randf_range(1.6, 2.6)).set_ease(Tween.EASE_IN)
		tw.tween_property(piece, "rotation", randf_range(-9.0, 9.0), 2.2)
		tw.tween_property(piece, "modulate:a", 0.0, 1.0).set_delay(1.2)
		tw.chain().tween_callback(piece.queue_free)
