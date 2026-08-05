extends RefCounted
class_name LevelArt
## Crtanje platformi i vode u nivoima. Tip platforme odredjuje boje i
## detalje: trava, kamen, led, pesak, drvo.
##
## Deterministicki po poziciji - platforma izgleda isto pri svakom pokretanju.

const KINDS := {
	"ground": {
		"top": Color(0.55, 0.83, 0.45), "top2": Color(0.42, 0.72, 0.38),
		"body": Color(0.55, 0.38, 0.24), "body2": Color(0.42, 0.28, 0.17),
		"detail": Color(0.48, 0.44, 0.42),
	},
	"stone": {
		"top": Color(0.62, 0.6, 0.58), "top2": Color(0.5, 0.48, 0.47),
		"body": Color(0.4, 0.38, 0.38), "body2": Color(0.3, 0.28, 0.29),
		"detail": Color(0.55, 0.53, 0.5),
	},
	"ice": {
		"top": Color(0.85, 0.94, 0.99), "top2": Color(0.72, 0.86, 0.95),
		"body": Color(0.58, 0.76, 0.88), "body2": Color(0.45, 0.62, 0.76),
		"detail": Color(0.95, 0.98, 1.0),
	},
	"sand": {
		"top": Color(0.97, 0.9, 0.66), "top2": Color(0.9, 0.8, 0.54),
		"body": Color(0.82, 0.68, 0.44), "body2": Color(0.68, 0.54, 0.34),
		"detail": Color(0.75, 0.66, 0.5),
	},
	"wood": {
		"top": Color(0.7, 0.52, 0.32), "top2": Color(0.58, 0.42, 0.26),
		"body": Color(0.45, 0.32, 0.2), "body2": Color(0.34, 0.24, 0.15),
		"detail": Color(0.3, 0.22, 0.14),
	},
	"jungle": {
		"top": Color(0.4, 0.7, 0.34), "top2": Color(0.26, 0.54, 0.26),
		"body": Color(0.36, 0.28, 0.18), "body2": Color(0.26, 0.2, 0.13),
		"detail": Color(0.2, 0.44, 0.22),
	},
	"lava_rock": {
		"top": Color(0.35, 0.3, 0.32), "top2": Color(0.26, 0.22, 0.24),
		"body": Color(0.2, 0.17, 0.19), "body2": Color(0.14, 0.12, 0.14),
		"detail": Color(0.85, 0.35, 0.14),
	},
}


## Nacrtaj platformu: kolizija + vizual sa detaljima.
static func draw_platform(parent: StaticBody2D, rect: Rect2, kind: String) -> void:
	var pal: Dictionary = KINDS.get(kind, KINDS["ground"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x) * 7919 + int(rect.position.y) * 104729

	# Kolizija.
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size * 0.5
	parent.add_child(shape)

	var w := rect.size.x
	var h := rect.size.y
	var top := rect.position

	# Telo u dva tona.
	_poly(parent, pal["body2"], [
		top + Vector2(0, 4), top + Vector2(w, 4),
		top + Vector2(w, h), top + Vector2(0, h)])
	_poly(parent, pal["body"], [
		top + Vector2(0, 4), top + Vector2(w, 4),
		top + Vector2(w, h - 3), top + Vector2(0, h - 3)])

	# Detalji u telu po tipu.
	match kind:
		"stone", "lava_rock":
			for i in maxi(1, int(w / 40.0)):
				var cx := rng.randf_range(5.0, maxf(w - 5.0, 6.0))
				var cy := rng.randf_range(9.0, maxf(h - 5.0, 10.0))
				_poly(parent, pal["detail"].darkened(0.1), [
					top + Vector2(cx - 4, cy), top + Vector2(cx, cy - 3),
					top + Vector2(cx + 4, cy + 1), top + Vector2(cx, cy + 3)])
		"ice":
			# Pukotine u ledu.
			for i in maxi(1, int(w / 55.0)):
				var cx := rng.randf_range(8.0, maxf(w - 8.0, 9.0))
				_poly(parent, Color(1, 1, 1, 0.45), [
					top + Vector2(cx, 6), top + Vector2(cx + 2, 6),
					top + Vector2(cx + 4, h - 6), top + Vector2(cx + 2, h - 6)])
		"wood":
			# Daske - vertikalne linije.
			for i in maxi(1, int(w / 24.0)):
				var cx := float(i) * 24.0
				if cx > 2.0 and cx < w - 2.0:
					_poly(parent, pal["detail"], [
						top + Vector2(cx, 4), top + Vector2(cx + 1.5, 4),
						top + Vector2(cx + 1.5, h), top + Vector2(cx, h)])
		_:
			# Kamencici u zemlji.
			for i in maxi(1, int(w / 55.0)):
				var cx := rng.randf_range(6.0, maxf(w - 6.0, 7.0))
				var cy := rng.randf_range(11.0, maxf(h - 6.0, 12.0))
				var rs := rng.randf_range(1.6, 3.0)
				_poly(parent, pal["detail"], [
					top + Vector2(cx - rs, cy), top + Vector2(cx - rs * 0.4, cy - rs * 0.8),
					top + Vector2(cx + rs, cy - rs * 0.3), top + Vector2(cx + rs * 0.5, cy + rs * 0.7),
					top + Vector2(cx - rs * 0.5, cy + rs * 0.8)])

	# Gornji sloj (trava/sneg/pesak) u dva tona.
	_poly(parent, pal["top2"], [
		top, top + Vector2(w, 0), top + Vector2(w, 5), top + Vector2(0, 5)])
	_poly(parent, pal["top"], [
		top, top + Vector2(w, 0), top + Vector2(w, 2.4), top + Vector2(0, 2.4)])

	# Vlati / kristali / talasici na povrsini.
	if kind in ["ground", "jungle"]:
		var blades := int(w / 7.0)
		for i in blades:
			var bx := (i + 0.5) * 7.0 + rng.randf_range(-1.5, 1.5)
			if bx < 1.0 or bx > w - 1.0:
				continue
			var bh := rng.randf_range(1.5, 3.4)
			_poly(parent, pal["top"] if rng.randf() > 0.45 else pal["top2"], [
				top + Vector2(bx - 1.0, 0.5), top + Vector2(bx + 1.0, 0.5),
				top + Vector2(bx + rng.randf_range(-0.8, 0.8), -bh)])
	elif kind == "ice":
		for i in int(w / 22.0):
			var bx := (i + 0.5) * 22.0
			if bx < 3.0 or bx > w - 3.0:
				continue
			_poly(parent, Color(1, 1, 1, 0.8), [
				top + Vector2(bx - 2.5, 0.5), top + Vector2(bx + 2.5, 0.5),
				top + Vector2(bx, -rng.randf_range(2.5, 5.0))])
	elif kind == "lava_rock":
		# Zareze koje svetle - lava ispod kamena.
		for i in maxi(1, int(w / 45.0)):
			var bx := rng.randf_range(6.0, maxf(w - 6.0, 7.0))
			_poly(parent, Color(0.92, 0.4, 0.14, 0.8), [
				top + Vector2(bx - 5, 1), top + Vector2(bx + 5, 0.4),
				top + Vector2(bx + 4, 2.6), top + Vector2(bx - 4, 3.2)])


## Voda: povrsina sa talasicima i providno telo.
static func draw_water(parent: Node2D, r: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) * 3571 + int(r.position.y) * 6151

	var node := Node2D.new()
	node.z_index = -1
	parent.add_child(node)

	# Telo vode - dva sloja za dubinu.
	_poly(node, Color(0.28, 0.55, 0.78, 0.62), [
		r.position, r.position + Vector2(r.size.x, 0),
		r.position + r.size, r.position + Vector2(0, r.size.y)])
	_poly(node, Color(0.4, 0.68, 0.86, 0.5), [
		r.position, r.position + Vector2(r.size.x, 0),
		r.position + Vector2(r.size.x, r.size.y * 0.35),
		r.position + Vector2(0, r.size.y * 0.35)])

	# Povrsina - svetla linija.
	_poly(node, Color(0.75, 0.92, 1.0, 0.7), [
		r.position + Vector2(0, -1), r.position + Vector2(r.size.x, -1),
		r.position + Vector2(r.size.x, 3), r.position + Vector2(0, 3)])

	# Talasici na povrsini.
	for i in int(r.size.x / 26.0):
		var x := (i + 0.5) * 26.0 + rng.randf_range(-4.0, 4.0)
		if x < 4.0 or x > r.size.x - 4.0:
			continue
		_poly(node, Color(1, 1, 1, 0.35), [
			r.position + Vector2(x - 7, 1), r.position + Vector2(x - 2, -1.6),
			r.position + Vector2(x + 3, 1), r.position + Vector2(x + 8, -1),
			r.position + Vector2(x + 3, 2.4), r.position + Vector2(x - 2, 0.6)])

	# Mehurici u vodi.
	for i in int(r.size.x / 40.0):
		var bx := rng.randf_range(6.0, maxf(r.size.x - 6.0, 7.0))
		var by := rng.randf_range(10.0, maxf(r.size.y - 6.0, 11.0))
		var br := rng.randf_range(1.5, 3.2)
		_circle(node, r.position + Vector2(bx, by), br, Color(1, 1, 1, 0.22))


static func _poly(parent: Node, col: Color, points: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(points)
	parent.add_child(p)


static func _circle(parent: Node, center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)
