extends CanvasLayer
## HUD: srca i zvezdice. Namerno velike, jasne ikone bez teksta -
## dete od 5 godina ne cita brojeve pouzdano.

@onready var hearts_box: HBoxContainer = $Margin/Rows/Hearts
@onready var star_count: Label = $Margin/Rows/Stars/Count
@onready var banner: Label = $Banner
@onready var rows: VBoxContainer = $Margin/Rows

## HUD i banner se uvecavaju na malim ekranima - inace su srca i
## zvezdice sitni i dete ih ne vidi.
## Klasa uredjaja po KRACOJ strani (telefon u landscape-u je sirok!).
const PHONE_MAX_SHORT_SIDE := 500.0
const TABLET_MAX_SHORT_SIDE := 780.0
const PHONE_UI_SCALE := 2.1
const TABLET_UI_SCALE := 1.5

var _heart_nodes: Array[Label] = []
var _banner_base_size := 34


func _ready() -> void:
	for i in Game.MAX_HEARTS:
		var h := Label.new()
		h.text = "♥"
		h.add_theme_font_size_override("font_size", 22)
		h.add_theme_color_override("font_color", Color(0.95, 0.3, 0.4))
		h.add_theme_constant_override("outline_size", 5)
		h.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
		hearts_box.add_child(h)
		_heart_nodes.append(h)

	Game.hearts_changed.connect(_on_hearts)
	Game.stars_changed.connect(_on_stars)
	_on_hearts(Game.hearts)
	_on_stars(Game.stars_collected)
	banner.modulate.a = 0.0

	_fit_ui()
	get_viewport().size_changed.connect(_fit_ui)


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

	# Sa "expand" viewport moze da bude visi od baznih 720px - HUD je u tom
	# prostoru pa se srazmerno smanji. Ogranici da ne postane ogroman.
	var vp := get_viewport().get_visible_rect().size
	if vp.y > 620.0:
		s *= minf(vp.y / 620.0, 1.35)
	s = minf(s, 2.4)

	rows.scale = Vector2(s, s)
	banner.add_theme_font_size_override("font_size", int(_banner_base_size * s))


func _on_hearts(value: int) -> void:
	for i in _heart_nodes.size():
		var full := i < value
		_heart_nodes[i].text = "♥" if full else "♡"
		_heart_nodes[i].modulate.a = 1.0 if full else 0.45


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
