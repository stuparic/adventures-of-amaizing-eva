extends Node2D
## Budzumbora - Evina lutka pomocnica. Mala, roze haljina, narandzasta kosa.
## Lebdi iza Eve, sakuplja zvezdice u prolazu i upozorava na opasnost.

@export var follow_distance := 34.0
@export var follow_speed := 3.2

@onready var magnet: Area2D = $Magnet
@onready var visual: Node2D = $Visual

var _target: CharacterBody2D
var _bob_time := 0.0
var _base_scale := Vector2.ONE


func _ready() -> void:
	_base_scale = visual.scale
	magnet.area_entered.connect(_on_magnet)


## Zovi ovo posle add_child() - direktna referenca, bez NodePath timing zamke.
func follow(target: CharacterBody2D) -> void:
	_target = target
	if target != null:
		global_position = target.global_position + Vector2(-follow_distance, -14.0)


func _process(delta: float) -> void:
	if _target == null:
		return

	_bob_time += delta

	# Stoji iza Eve, na strani sa koje je dosla, malo iznad glave.
	var side := -signf(_target.velocity.x) if absf(_target.velocity.x) > 5.0 else 1.0
	var desired := _target.global_position + Vector2(side * follow_distance, -14.0)

	# Lebdenje: sinus gore-dole da izgleda kao da pluta.
	desired.y += sin(_bob_time * 2.4) * 4.0

	global_position = global_position.lerp(desired, delta * follow_speed)

	# Blago rotiranje u smeru kretanja - daje osecaj mekog, lutkastog tela.
	var drift := (desired.x - global_position.x) * 0.01
	visual.rotation = lerp(visual.rotation, clampf(drift, -0.3, 0.3), delta * 4.0)


## Magnet: zvezdice u blizini same doleću. Dete ne mora precizno da ih pogodi.
func _on_magnet(area: Area2D) -> void:
	if area.has_method("attract_to"):
		area.attract_to(self)


## Kad Eva bude pogodjena, Budzumbora "skoci" od straha.
## Skala je relativna na osnovnu (postavljenu u sceni), ne apsolutna -
## inace bi lutka posle prvog udarca ostala trajno uvecana.
func startle() -> void:
	var tw := create_tween()
	tw.tween_property(visual, "scale", _base_scale * Vector2(1.35, 0.7), 0.08)
	tw.tween_property(visual, "scale", _base_scale, 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
