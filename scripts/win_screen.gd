extends CanvasLayer
## Winning screen. Prikazuje se kad Eva spasi macu Carlija.
##
## Sve na srpskom, velikim slovima, sa brojevima koji se animirano
## "namotavaju" - detetu je to nagrada koju gleda, ne tekst koji cita.

signal replay_requested
signal map_requested

@onready var dim: ColorRect = $Dim
@onready var panel: Control = $Center/Panel
@onready var title: Label = $Center/Panel/Rows/Title
@onready var subtitle: Label = $Center/Panel/Rows/Subtitle
@onready var stars_value: Label = $Center/Panel/Rows/Stats/StarsBox/Value
@onready var time_value: Label = $Center/Panel/Rows/Stats/TimeBox/Value
@onready var hint: Label = $Center/Panel/Rows/Hint
@onready var confetti: Node2D = $Confetti
@onready var btn_map: Button = $Center/Panel/Rows/Buttons/Map
@onready var btn_again: Button = $Center/Panel/Rows/Buttons/Again
@onready var star_box: Control = $Center/Panel/Rows/Stats/StarsBox/IconBox
@onready var time_box: Control = $Center/Panel/Rows/Stats/TimeBox/IconBox

## Zvezdica i sat kao poligoni - web font ne sadrzi ★ ◷ (bile bi kockice).
const StarIcon := preload("res://scenes/hud_star.tscn")

var _shown := false
var _panel_scale := 1.0


## Na uskom ekranu panel se skalira da tekst ostane citljiv i da
## panel ne izadje van ekrana.
const PANEL_WIDTH := 560.0
const PANEL_MARGIN := 0.92


func _ready() -> void:
	visible = false
	layer = 10

	_build_icons()

	btn_map.pressed.connect(func() -> void:
		Audio.play("star")
		map_requested.emit()
	)
	btn_again.pressed.connect(func() -> void:
		Audio.play("jump")
		replay_requested.emit()
	)

	_fit_panel()
	get_viewport().size_changed.connect(_fit_panel)


## Uklopi panel u sirinu ekrana (telefon u portretu je uzak).
func _fit_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0:
		return
	# Nikad ne uvecavaj preko 1.0 - samo smanji ako ne staje.
	var s := minf(1.0, (vp.x * PANEL_MARGIN) / PANEL_WIDTH)
	panel.pivot_offset = Vector2(PANEL_WIDTH * 0.5, 170.0)
	panel.scale = Vector2(s, s)
	_panel_scale = s


## Prikazi ekran sa rezultatom.
func show_result(stars: int, total: int, time_text: String) -> void:
	if _shown:
		return
	_shown = true
	visible = true

	title.text = "BRAVO EVA!"
	subtitle.text = "Spasila si macu Čarlija"
	hint.text = "M = mapa   ·   R = ponovo"

	stars_value.text = "0"
	time_value.text = time_text

	# Ulazna animacija: zatamnjenje, pa panel uleti odozgo.
	dim.modulate.a = 0.0
	panel.scale = _panel_scale * Vector2(0.75, 0.75)
	panel.modulate.a = 0.0

	# Konfeti krecu odmah - ne vezuj ih na kraj tween lanca.
	confetti.start()

	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(panel, "scale", _panel_scale * Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Brojac zvezdica se "namotava" do konacne cifre.
	tw.tween_method(
		func(v: float) -> void: stars_value.text = "%d / %d" % [int(v), total],
		0.0, float(stars), 0.7
	).set_ease(Tween.EASE_OUT)

	tw.tween_callback(_pulse.bind(stars_value))

	# Snimljeni glas ako postoji, inace kratak nagradni zvuk.
	tw.tween_callback(func() -> void:
		if not Audio.play_voice_win():
			Audio.play("heart")
	)


## Ikonice u statistici: zvezdica (poligon) i sat (nacrtan poligonima).
func _build_icons() -> void:
	var st: Node2D = StarIcon.instantiate()
	st.position = Vector2(60, 24)
	st.scale = Vector2(1.7, 1.7)
	star_box.add_child(st)

	time_box.add_child(_make_clock())


## Sat od poligona - obod, lice, dve kazaljke.
func _make_clock() -> Node2D:
	var root := Node2D.new()
	root.position = Vector2(60, 24)

	root.add_child(_disc(19.0, Color(0.25, 0.45, 0.7)))
	root.add_child(_disc(15.5, Color(0.45, 0.72, 0.95)))
	root.add_child(_disc(13.0, Color(0.93, 0.97, 1.0)))

	var h := Polygon2D.new()
	h.color = Color(0.2, 0.32, 0.5)
	h.polygon = PackedVector2Array([
		Vector2(-1.4, 1.4), Vector2(1.4, 1.4), Vector2(1.0, -7.5), Vector2(-1.0, -7.5),
	])
	root.add_child(h)

	var m := Polygon2D.new()
	m.color = Color(0.2, 0.32, 0.5)
	m.polygon = PackedVector2Array([
		Vector2(-1.2, -1.2), Vector2(-1.2, 1.2), Vector2(8.0, 0.9), Vector2(8.0, -0.9),
	])
	root.add_child(m)

	return root


func _disc(r: float, col: Color, seg := 22) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	return p


func _pulse(node: Control) -> void:
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(node, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC)
