extends CanvasLayer
## HUD: srca i zvezdice. Namerno velike, jasne ikone bez teksta -
## dete od 5 godina ne cita brojeve pouzdano.
##
## VAZNO: srca i zvezdica su Polygon2D scene, NE tekstualni znakovi.
## Godotov web font ne sadrzi ♥ ♡ ★ - na webu su se prikazivali kao
## prazne kockice ("tofu"). Potvrdjeno citanjem piksela iz WebGL canvasa.

const HeartScene := preload("res://scenes/heart.tscn")
const StarScene := preload("res://scenes/hud_star.tscn")

@onready var hearts_box: Control = $Margin/Rows/Hearts
@onready var star_icon_box: Control = $Margin/Rows/Stars/IconBox
@onready var star_count: Label = $Margin/Rows/Stars/Count
@onready var banner: Label = $Banner
@onready var rows: VBoxContainer = $Margin/Rows
@onready var map_button: Button = $MapButton
@onready var mute_button: Button = $MuteButton
@onready var again_button: Button = $AgainButton

## Signal koji nivo hvata - HUD ne zna kako se menja scena.
signal map_requested
## Restart nivoa. Taster R radi isto, ali na telefonu tastera nema -
## zato je dugme obavezno.
signal restart_requested

## HUD i banner se uvecavaju na malim ekranima - inace su srca i
## zvezdice sitni i dete ih ne vidi.
## Klasa uredjaja po KRACOJ strani (telefon u landscape-u je sirok!).
const PHONE_MAX_SHORT_SIDE := 500.0
const TABLET_MAX_SHORT_SIDE := 780.0
const PHONE_UI_SCALE := 2.1
const TABLET_UI_SCALE := 1.5

## Razmak izmedju srca i njihova velicina u HUD-u.
const HEART_STEP := 27.0
const HEART_SCALE := 1.0

var _hearts: Array[Node2D] = []
var _banner_base_size := 34


func _ready() -> void:
	_build_hearts()
	_build_star_icon()

	Game.hearts_changed.connect(_on_hearts)
	Game.stars_changed.connect(_on_stars)
	_on_hearts(Game.hearts)
	_on_stars(Game.stars_collected)
	banner.modulate.a = 0.0

	map_button.pressed.connect(func() -> void:
		Audio.play("checkpoint")
		map_requested.emit()
	)
	again_button.pressed.connect(func() -> void:
		Audio.play("checkpoint")
		restart_requested.emit()
	)
	mute_button.pressed.connect(_toggle_mute)
	_refresh_mute()

	_fit_ui()
	get_viewport().size_changed.connect(_fit_ui)


func _build_hearts() -> void:
	hearts_box.custom_minimum_size = Vector2(HEART_STEP * Game.MAX_HEARTS, 26)
	for i in Game.MAX_HEARTS:
		var h: Node2D = HeartScene.instantiate()
		h.position = Vector2(13.0 + i * HEART_STEP, 13.0)
		h.scale = Vector2(HEART_SCALE, HEART_SCALE)
		hearts_box.add_child(h)
		_hearts.append(h)


func _build_star_icon() -> void:
	star_icon_box.custom_minimum_size = Vector2(26, 26)
	var s: Node2D = StarScene.instantiate()
	s.position = Vector2(13, 13)
	s.scale = Vector2(0.85, 0.85)
	star_icon_box.add_child(s)


## Uvecaj HUD i banner na malim ekranima.
func _fit_ui() -> void:
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return
	var short_side := float(mini(win.x, win.y))
	var s := 1.0
	if short_side < PHONE_MAX_SHORT_SIDE:
		s = PHONE_UI_SCALE
	elif short_side < TABLET_MAX_SHORT_SIDE:
		s = TABLET_UI_SCALE

	# Sa "expand" viewport moze da bude visi od baznih 620px - HUD je u tom
	# prostoru pa se srazmerno smanji. Ogranici da ne postane ogroman.
	var vp := get_viewport().get_visible_rect().size
	if vp.y > 620.0:
		s *= minf(vp.y / 620.0, 1.35)
	s = minf(s, 2.4)

	rows.scale = Vector2(s, s)
	banner.add_theme_font_size_override("font_size", int(_banner_base_size * s))


func _toggle_mute() -> void:
	Audio.toggle_mute()
	_refresh_mute()


## Ikonica pokazuje stanje: zvuk radi ili je precrtan.
func _refresh_mute() -> void:
	if Audio.is_muted():
		mute_button.text = "TIHO"
		mute_button.modulate = Color(0.75, 0.75, 0.78)
	else:
		mute_button.text = "ZVUK"
		mute_button.modulate = Color(1, 1, 1)


## Puno srce = jarko crveno. Prazno = sivo, izbledelo i malo manje.
func _on_hearts(value: int) -> void:
	for i in _hearts.size():
		var full := i < value
		var h := _hearts[i]
		var fill := h.get_node("Fill") as Polygon2D
		var shine := h.get_node("Shine") as Polygon2D

		fill.color = Color(0.95, 0.3, 0.4) if full else Color(0.62, 0.6, 0.63)
		shine.visible = full
		h.modulate.a = 1.0 if full else 0.5

		var target := Vector2(HEART_SCALE, HEART_SCALE) if full \
			else Vector2(HEART_SCALE * 0.82, HEART_SCALE * 0.82)
		var tw := create_tween()
		tw.tween_property(h, "scale", target, 0.18).set_trans(Tween.TRANS_BACK)


func _on_stars(value: int) -> void:
	star_count.text = str(value)


## Velika poruka preko ekrana ("Bravo Eva!", "Probaj ponovo").
func show_banner(text: String, color: Color, hold := 2.0) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.scale = Vector2(0.6, 0.6)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(hold)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
