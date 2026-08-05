extends CharacterBody2D
## Zivotinja-prepreka. Nije "neprijatelj" - samo setа levo-desno po platformi.
## Namerno lagana: sporo ide, ne juri Evu, i vidno se okrene pre promene smera.

signal stomped

@export var speed := 34.0
@export var patrol_half_width := 48.0   # koliko daleko od pocetne tacke ide

@onready var visual: Node2D = $Visual

var _dir := 1
var _origin_x := 0.0
var _turning := false
var _squashed := false

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 900.0)


func _ready() -> void:
	_origin_x = global_position.x


func _physics_process(delta: float) -> void:
	if _squashed:
		return

	if not is_on_floor():
		velocity.y += _gravity * delta
	else:
		velocity.y = 0.0

	if _turning:
		velocity.x = 0.0
	else:
		velocity.x = _dir * speed

	move_and_slide()

	# Okreni se na ivici patrole, na zidu, ili pred rupom.
	var past_edge := absf(global_position.x - _origin_x) > patrol_half_width
	if not _turning and (past_edge or is_on_wall()):
		_turn_around()


## Pauza + rotacija pre okretanja: dete stigne da vidi sta ce se desiti.
func _turn_around() -> void:
	_turning = true
	var tw := create_tween()
	tw.tween_property(visual, "scale:x", 0.0, 0.14)
	tw.tween_callback(func() -> void:
		_dir *= -1
		# Vrati poziciju unutar granica da ne zaglavi na ivici.
		global_position.x = clampf(
			global_position.x, _origin_x - patrol_half_width, _origin_x + patrol_half_width
		)
	)
	tw.tween_property(visual, "scale:x", 1.0, 0.14)
	tw.tween_callback(func() -> void: _turning = false)


## Eva je skocila na nju - zivotinja se samo splosti i pobegne, ne "umire".
func get_stomped() -> void:
	if _squashed:
		return
	_squashed = true
	stomped.emit()
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(visual, "scale", Vector2(1.4, 0.25), 0.1)
	tw.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tw.chain().tween_callback(queue_free)
