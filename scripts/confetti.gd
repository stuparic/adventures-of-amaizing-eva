extends Node2D
## Konfeti za winning screen. Pixel-art kvadratici koji padaju i rotiraju se.
## Ne koristi GPUParticles - obicni Polygon2D da ostane u istom vizualnom stilu.

const COUNT := 110
const COLORS: Array[Color] = [
	Color(1, 0.85, 0.25),   # zlatna
	Color(0.98, 0.55, 0.75), # roze (Budzumbora)
	Color(0.42, 0.72, 0.45), # zelena (Evina haljina)
	Color(0.98, 0.68, 0.32), # narandzasta (Carli)
	Color(0.35, 0.65, 0.95), # plava
	Color(1, 1, 1),          # bela
]

var _pieces: Array[Dictionary] = []
var _running := false
var _area := Vector2(960, 540)


func _ready() -> void:
	_area = get_viewport().get_visible_rect().size


func start() -> void:
	if _running:
		return
	_running = true

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260805

	for i in COUNT:
		var size := rng.randf_range(7.0, 14.0)
		var p := Polygon2D.new()
		p.color = COLORS[rng.randi() % COLORS.size()]
		p.polygon = PackedVector2Array([
			Vector2(-size * 0.5, -size * 0.5),
			Vector2(size * 0.5, -size * 0.5),
			Vector2(size * 0.5, size * 0.5),
			Vector2(-size * 0.5, size * 0.5),
		])
		p.position = Vector2(
			rng.randf_range(0.0, _area.x),
			rng.randf_range(-_area.y * 0.8, -10.0)
		)
		add_child(p)

		_pieces.append({
			"node": p,
			"vy": rng.randf_range(55.0, 145.0),
			"vx": rng.randf_range(-24.0, 24.0),
			"spin": rng.randf_range(-3.2, 3.2),
			"sway": rng.randf_range(0.6, 2.0),
			"phase": rng.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	if not _running:
		return

	for piece in _pieces:
		var node: Polygon2D = piece["node"]
		node.position.y += piece["vy"] * delta
		# Blago lelujanje levo-desno dok pada.
		piece["phase"] += delta * piece["sway"]
		node.position.x += (piece["vx"] + sin(piece["phase"]) * 18.0) * delta
		node.rotation += piece["spin"] * delta

		# Kad izadje ispod ekrana, vrati je gore - beskonacni konfeti.
		if node.position.y > _area.y + 12.0:
			node.position.y = -12.0
			node.position.x = fmod(node.position.x + _area.x, _area.x)
