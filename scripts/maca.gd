extends Area2D
## Maca - cilj nivoa. Zatvorena je u kavezu i mjauce da je dete cuje/vidi izdaleka.
## Kad Eva dodje, kavez se otvori i maca skace od srece.

## Koliko cesto mjauce dok je zatvorena. Zvuk vodi dete ka cilju.
const MEOW_INTERVAL := 4.5

## Mjauce samo ako je Eva blizu - da se ne cuje kroz ceo nivo.
const MEOW_RANGE := 420.0

@onready var visual: Node2D = $Visual
@onready var cage: Node2D = $Visual/Cage

var _rescued := false
var _t := 0.0
var _meow_timer := 2.0
var _player: Node2D


func _ready() -> void:
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta

	if _rescued:
		# Skakuce od srece.
		visual.position.y = -absf(sin(_t * 6.0)) * 10.0
		return

	# Nemirno se meskolji u kavezu - privlaci pogled.
	visual.rotation = sin(_t * 3.0) * 0.08

	_tick_meow(delta)


## Doziva Evu zvukom kad je dovoljno blizu.
func _tick_meow(delta: float) -> void:
	_meow_timer -= delta
	if _meow_timer > 0.0:
		return

	_meow_timer = MEOW_INTERVAL

	if _player == null:
		_player = _find_player()
	if _player == null:
		return

	if global_position.distance_to(_player.global_position) < MEOW_RANGE:
		Audio.play("meow", 0.1)


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		return node as Node2D
	return null


func _on_body(body: Node) -> void:
	if _rescued or not body.has_method("hurt"):
		return

	_rescued = true
	set_deferred("monitoring", false)

	Audio.play("meow", 0.0)

	# Ako postoji snimljeni glas, on ide na winning screenu - fanfara bi ga
	# zagusila. Bez glasa: fanfara + pobednicka tema kao i pre.
	if not Audio.has_voice_win():
		Audio.play("win")
		Audio.play_win_music()

	var tw := create_tween()
	tw.tween_property(cage, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(cage, "scale", Vector2(1.6, 1.6), 0.4)
	tw.tween_callback(func() -> void:
		visual.rotation = 0.0
		Game.level_won.emit()
	)
