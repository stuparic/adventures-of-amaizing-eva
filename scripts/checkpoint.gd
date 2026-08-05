extends Area2D
## Checkpoint - cvet koji procveta kad Eva prodje.
## Ovih je namerno MNOGO u nivou: dete se nikad ne vraca daleko.

@onready var visual: Node2D = $Visual

var _active := false


## Neaktivan cvet: blago izbledeo i plavicast, ali se boje jos vide.
## (Pun sivi modulate bi ugusio sve latice - probano, izgleda mrtvo.)
const TINT_OFF := Color(0.72, 0.76, 0.85)
const TINT_ON := Color(1, 1, 1)


func _ready() -> void:
	body_entered.connect(_on_body)
	visual.modulate = TINT_OFF


func _on_body(body: Node) -> void:
	if _active or not body.has_method("hurt"):
		return

	_active = true
	Game.set_checkpoint(global_position + Vector2(0, -8))
	Audio.play("checkpoint")

	var tw := create_tween()
	tw.tween_property(visual, "modulate", TINT_ON, 0.3)
	tw.parallel().tween_property(visual, "scale", Vector2(1.4, 1.4), 0.18)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC)
