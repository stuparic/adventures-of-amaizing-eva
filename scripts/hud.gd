extends CanvasLayer
## HUD: srca i zvezdice. Namerno velike, jasne ikone bez teksta -
## dete od 5 godina ne cita brojeve pouzdano.

@onready var hearts_box: HBoxContainer = $Margin/Rows/Hearts
@onready var star_count: Label = $Margin/Rows/Stars/Count
@onready var banner: Label = $Banner

var _heart_nodes: Array[Label] = []


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
