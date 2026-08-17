class_name Draw2D
extends Object
## Deljeni pomocnici za crtanje poligonima.
##
## Sve u igri je nacrtano kao Polygon2D - nema ni jedne slike. Zbog toga su
## `_poly` i `_circle` bili prepisani u 16 fajlova (213 linija ukupno), u
## cetiri neznatno razlicite varijante koje su se razlikovale samo po broju
## segmenata kruga i tipu roditelja.
##
## Ovde su jednom, sa `segments` kao parametrom.
##
## Koriscenje:
##   Draw2D.poly(parent, color, [Vector2(0,0), Vector2(10,0), Vector2(5,8)])
##   Draw2D.circle(parent, Vector2(4, 2), 6.0, color)
##   Draw2D.circle(parent, center, r, color, 24)   # glatkiji krug


## Poligon iz niza tacaka. `parent` je Node, ne samo Node2D - neki
## pozivaoci dodaju u StaticBody2D.
static func poly(parent: Node, col: Color, pts: Array) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)
	return p


## Krug kao poligon. 14 segmenata je dovoljno za sitne detalje i najcesci
## je slucaj; za velike krugove prosledi vise.
static func circle(parent: Node, center: Vector2, r: float, col: Color,
		segments := 14) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return poly(parent, col, pts)
