extends Area2D
## Zvezdica. Ima veliki hitbox i moze da bude privucena Budzumborom -
## dete ne mora precizno da je pogodi.

@onready var visual: Node2D = $Visual

var _collected := false
var _spin := 0.0
var _attractor: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body)
	_spin = randf() * TAU


func _process(delta: float) -> void:
	if _collected:
		return

	_spin += delta * 2.0
	visual.scale.x = 0.75 + sin(_spin) * 0.25
	visual.position.y = sin(_spin * 1.3) * 2.0

	if _attractor != null:
		global_position = global_position.lerp(_attractor.global_position, delta * 7.0)


func attract_to(node: Node2D) -> void:
	if not _collected:
		_attractor = node


func _on_body(body: Node) -> void:
	if _collected or not body.has_method("hurt"):
		return
	_collect()


func _collect() -> void:
	_collected = true
	set_deferred("monitoring", false)

	var hearts_before := Game.hearts
	Game.add_star()
	Game.maybe_reward_heart()

	# Ako je ova zvezdica donela srce, pusti bogatiji zvuk umesto obicnog "cin".
	if Game.hearts > hearts_before:
		Audio.play("heart")
	else:
		Audio.play("star")

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.8, 1.8), 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_property(self, "position:y", position.y - 18.0, 0.25)
	tw.chain().tween_callback(queue_free)
