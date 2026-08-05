extends RefCounted
class_name BiomeArt
## Crtanje ostrva po biomu. Svaki bioma ima svoju paletu, oblik i vegetaciju.
##
## Sve je deterministicki: isti `seed` daje isto ostrvo pri svakom
## pokretanju, pa mapa nije "nova" svaki put.
##
## Koriscenje:
##   BiomeArt.draw_island(parent, "dzungla", center, size, seed)


## Palete po biomu. Redom: dubina mora oko ostrva, plicak, pesak,
## tlo (2 tona), akcent (sneg/lava/kamen).
const PALETTES := {
	"livada": {
		"shallow": Color(0.55, 0.79, 0.85),
		"sand": Color(0.94, 0.89, 0.68),
		"ground": Color(0.55, 0.78, 0.42),
		"ground2": Color(0.44, 0.68, 0.34),
		"accent": Color(0.36, 0.6, 0.28),
	},
	"plaza": {
		"shallow": Color(0.6, 0.87, 0.9),
		"sand": Color(0.98, 0.93, 0.73),
		"ground": Color(0.96, 0.88, 0.6),
		"ground2": Color(0.9, 0.8, 0.5),
		"accent": Color(0.55, 0.78, 0.5),
	},
	"dzungla": {
		"shallow": Color(0.42, 0.72, 0.7),
		"sand": Color(0.84, 0.82, 0.58),
		"ground": Color(0.28, 0.56, 0.28),
		"ground2": Color(0.19, 0.44, 0.22),
		"accent": Color(0.13, 0.34, 0.18),
	},
	"pustinja": {
		"shallow": Color(0.66, 0.84, 0.86),
		"sand": Color(0.97, 0.88, 0.62),
		"ground": Color(0.93, 0.76, 0.42),
		"ground2": Color(0.85, 0.66, 0.34),
		"accent": Color(0.72, 0.54, 0.3),
	},
	"sneg": {
		"shallow": Color(0.68, 0.84, 0.92),
		"sand": Color(0.84, 0.88, 0.92),
		"ground": Color(0.93, 0.96, 0.99),
		"ground2": Color(0.82, 0.88, 0.95),
		"accent": Color(0.68, 0.78, 0.9),
	},
	"vulkan": {
		"shallow": Color(0.5, 0.6, 0.66),
		"sand": Color(0.42, 0.38, 0.4),
		"ground": Color(0.34, 0.29, 0.31),
		"ground2": Color(0.25, 0.21, 0.24),
		"accent": Color(0.92, 0.42, 0.16),
	},
}


## Nacrtaj celo ostrvo: more oko njega, obalu, tlo i vegetaciju.
static func draw_island(parent: Node2D, biome: String, center: Vector2,
		size: Vector2, rseed: int) -> void:
	var pal: Dictionary = PALETTES.get(biome, PALETTES["livada"])
	var rng := RandomNumberGenerator.new()
	rng.seed = rseed

	# Nepravilan oblik ostrva - ne elipsa. 22 tacke sa slucajnim odstupanjem.
	var shape := _island_shape(size, rng, 22)

	# Slojevi od spolja ka unutra: plicak, obala (pesak), tlo, tamnije tlo.
	_ring(parent, center, shape, 1.42, Color(pal["shallow"], 0.45), Vector2(0, 9))
	_ring(parent, center, shape, 1.22, pal["shallow"], Vector2(0, 6))
	_ring(parent, center, shape, 1.08, pal["sand"], Vector2(0, 3))
	_ring(parent, center, shape, 1.0, pal["ground"], Vector2.ZERO)
	# Tamniji donji deo tla - daje osecaj zapremine.
	_half_ring(parent, center, shape, 0.97, pal["ground2"])

	# Vegetacija i detalji po biomu.
	match biome:
		"livada":   _decor_livada(parent, center, size, pal, rng)
		"plaza":    _decor_plaza(parent, center, size, pal, rng)
		"dzungla":  _decor_dzungla(parent, center, size, pal, rng)
		"pustinja": _decor_pustinja(parent, center, size, pal, rng)
		"sneg":     _decor_sneg(parent, center, size, pal, rng)
		"vulkan":   _decor_vulkan(parent, center, size, pal, rng)


## Nepravilan zatvoren oblik: jedinicni radijusi sa "wobble"-om.
static func _island_shape(size: Vector2, rng: RandomNumberGenerator,
		segments: int) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in segments:
		var a := TAU * float(i) / float(segments)
		var w := rng.randf_range(0.84, 1.16)
		pts.append(Vector2(cos(a) * size.x * 0.5 * w, sin(a) * size.y * 0.5 * w))
	return pts


static func _ring(parent: Node2D, center: Vector2, shape: Array[Vector2],
		scale_f: float, col: Color, offset: Vector2) -> void:
	var pts := PackedVector2Array()
	for p in shape:
		pts.append(center + offset + p * scale_f)
	_poly(parent, col, pts)


## Donja polovina ostrva u tamnijem tonu - simulira senku/dubinu.
static func _half_ring(parent: Node2D, center: Vector2, shape: Array[Vector2],
		scale_f: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for p in shape:
		if p.y >= -size_hint(shape) * 0.1:
			pts.append(center + p * scale_f)
	if pts.size() >= 3:
		_poly(parent, col, pts)


static func size_hint(shape: Array[Vector2]) -> float:
	var m := 0.0
	for p in shape:
		m = maxf(m, absf(p.y))
	return m


# --- VEGETACIJA PO BIOMU ---

## Livada: listopadno drvece, cvetici, jezerce.
static func _decor_livada(parent: Node2D, c: Vector2, size: Vector2,
		pal: Dictionary, rng: RandomNumberGenerator) -> void:
	_lake(parent, c + Vector2(size.x * 0.18, size.y * 0.2), size.x * 0.17, rng)
	for i in 7:
		var p := _spot(c, size, rng, 0.66)
		_tree_round(parent, p, rng.randf_range(0.8, 1.15),
			Color(0.28, 0.55, 0.3), Color(0.42, 0.7, 0.38), rng)
	for i in 12:
		var p := _spot(c, size, rng, 0.78)
		_flower(parent, p, rng)


## Plaza: palme, suncobrani-oblici, skoljke, mnogo peska.
static func _decor_plaza(parent: Node2D, c: Vector2, size: Vector2,
		pal: Dictionary, rng: RandomNumberGenerator) -> void:
	for i in 5:
		var p := _spot(c, size, rng, 0.6)
		_palm(parent, p, rng.randf_range(0.85, 1.2), rng)
	# Skoljke i kamencici na pesku.
	for i in 10:
		var p := _spot(c, size, rng, 0.9)
		_poly(parent, Color(1, 0.94, 0.88, 0.9), _blob_pts(p, rng.randf_range(2.5, 4.5), 7))
	# Plicak-laguna.
	_lake(parent, c + Vector2(-size.x * 0.2, size.y * 0.22), size.x * 0.14, rng)


## Dzungla: gusto, visoko drvece u tri sloja, lijane, tamno.
static func _decor_dzungla(parent: Node2D, c: Vector2, size: Vector2,
		pal: Dictionary, rng: RandomNumberGenerator) -> void:
	# Gusta podloga - tamne mrlje lisca.
	for i in 14:
		var p := _spot(c, size, rng, 0.85)
		_poly(parent, Color(0.16, 0.4, 0.2, 0.5),
			_blob_pts(p, rng.randf_range(9.0, 18.0), 9))
	for i in 11:
		var p := _spot(c, size, rng, 0.7)
		_tree_tall(parent, p, rng.randf_range(0.95, 1.4),
			Color(0.13, 0.36, 0.18), Color(0.24, 0.52, 0.26), rng)
	# Nekoliko svetlijih krosnji na vrhu.
	for i in 4:
		var p := _spot(c, size, rng, 0.5)
		_blob(parent, p + Vector2(0, -22), rng.randf_range(11.0, 16.0),
			Color(0.32, 0.62, 0.3))


## Pustinja: kaktusi, dine, stene, bez vode.
static func _decor_pustinja(parent: Node2D, c: Vector2, size: Vector2,
		pal: Dictionary, rng: RandomNumberGenerator) -> void:
	# Dine - svetle lucne mrlje.
	for i in 5:
		var p := _spot(c, size, rng, 0.8)
		var w := rng.randf_range(26.0, 48.0)
		_poly(parent, Color(0.98, 0.9, 0.66, 0.55), [
			p + Vector2(-w, 4), p + Vector2(-w * 0.4, -7),
			p + Vector2(w * 0.5, -5), p + Vector2(w, 5),
		])
	for i in 6:
		var p := _spot(c, size, rng, 0.68)
		_cactus(parent, p, rng.randf_range(0.85, 1.25), rng)
	# Stene.
	for i in 5:
		var p := _spot(c, size, rng, 0.82)
		_rock(parent, p, rng.randf_range(5.0, 11.0), pal["accent"], rng)


## Sneg: jelke, smetovi, zaledjeno jezero, kamen koji vri iz snega.
static func _decor_sneg(parent: Node2D, c: Vector2, size: Vector2,
		pal: Dictionary, rng: RandomNumberGenerator) -> void:
	# Zaledjeno jezero.
	var lp := c + Vector2(size.x * 0.16, size.y * 0.2)
	_poly(parent, Color(0.7, 0.85, 0.95), _blob_pts(lp, size.x * 0.16, 14))
	_poly(parent, Color(0.85, 0.93, 0.99, 0.7), _blob_pts(lp, size.x * 0.12, 12))

	for i in 8:
		var p := _spot(c, size, rng, 0.68)
		_fir(parent, p, rng.randf_range(0.85, 1.3), rng)
	# Smetovi.
	for i in 7:
		var p := _spot(c, size, rng, 0.85)
		_blob(parent, p, rng.randf_range(6.0, 13.0), Color(1, 1, 1, 0.75))


## Vulkan: krater sa lavom, tokovi lave, mrtvo drvo, pepeo.
static func _decor_vulkan(parent: Node2D, c: Vector2, size: Vector2,
		pal: Dictionary, rng: RandomNumberGenerator) -> void:
	# Krater u sredini-gore.
	var kp := c + Vector2(size.x * 0.05, -size.y * 0.16)
	var kr := size.x * 0.2
	_poly(parent, Color(0.22, 0.18, 0.2), _blob_pts(kp, kr, 14))
	_poly(parent, Color(0.85, 0.32, 0.12), _blob_pts(kp, kr * 0.66, 12))
	_poly(parent, Color(1, 0.68, 0.2), _blob_pts(kp, kr * 0.34, 10))

	# Tokovi lave koji se spustaju od kratera.
	for i in 4:
		var ang := TAU * float(i) / 4.0 + rng.randf_range(-0.4, 0.4)
		var pts: Array[Vector2] = [kp]
		var cur := kp
		for step in 5:
			cur += Vector2(cos(ang), sin(ang) * 0.7) * rng.randf_range(14.0, 24.0)
			ang += rng.randf_range(-0.35, 0.35)
			pts.append(cur)
		_ribbon(parent, pts, rng.randf_range(5.0, 9.0), Color(0.9, 0.36, 0.12))
		_ribbon(parent, pts, 2.6, Color(1, 0.75, 0.28, 0.9))

	# Mrtvo drvo i stene.
	for i in 4:
		var p := _spot(c, size, rng, 0.72)
		_dead_tree(parent, p, rng.randf_range(0.8, 1.15))
	for i in 6:
		var p := _spot(c, size, rng, 0.82)
		_rock(parent, p, rng.randf_range(4.0, 9.0), Color(0.2, 0.17, 0.19), rng)


# --- POJEDINACNI ELEMENTI ---

## Slucajna tacka unutar ostrva (elipsa, `inset` koliko blize centru).
static func _spot(c: Vector2, size: Vector2, rng: RandomNumberGenerator,
		inset: float) -> Vector2:
	var a := rng.randf_range(0.0, TAU)
	var r := sqrt(rng.randf()) * inset
	return c + Vector2(cos(a) * size.x * 0.5 * r, sin(a) * size.y * 0.5 * r)


static func _tree_round(parent: Node2D, p: Vector2, s: float,
		dark: Color, light: Color, rng: RandomNumberGenerator) -> void:
	_poly(parent, Color(0.3, 0.35, 0.28, 0.2), _blob_pts(p + Vector2(0, 4 * s), 11 * s, 8))
	_poly(parent, Color(0.48, 0.34, 0.22), [
		p + Vector2(-2.6 * s, -5 * s), p + Vector2(2.6 * s, -5 * s),
		p + Vector2(2 * s, 4 * s), p + Vector2(-2 * s, 4 * s),
	])
	_blob(parent, p + Vector2(-6 * s, -13 * s), 9 * s, dark)
	_blob(parent, p + Vector2(6 * s, -12 * s), 8 * s, dark)
	_blob(parent, p + Vector2(0, -20 * s), 10.5 * s, dark)
	_blob(parent, p + Vector2(-2 * s, -17 * s), 7 * s, light)


static func _tree_tall(parent: Node2D, p: Vector2, s: float,
		dark: Color, light: Color, rng: RandomNumberGenerator) -> void:
	_poly(parent, Color(0.3, 0.35, 0.28, 0.22), _blob_pts(p + Vector2(0, 4 * s), 10 * s, 8))
	_poly(parent, Color(0.4, 0.3, 0.2), [
		p + Vector2(-2.2 * s, -8 * s), p + Vector2(2.2 * s, -8 * s),
		p + Vector2(1.7 * s, 4 * s), p + Vector2(-1.7 * s, 4 * s),
	])
	# Vise slojeva lisca - dzungla je gusta.
	_blob(parent, p + Vector2(-7 * s, -18 * s), 9 * s, dark)
	_blob(parent, p + Vector2(7 * s, -20 * s), 8.5 * s, dark)
	_blob(parent, p + Vector2(0, -27 * s), 11 * s, dark)
	_blob(parent, p + Vector2(-3 * s, -24 * s), 7.5 * s, light)
	_blob(parent, p + Vector2(4 * s, -30 * s), 6 * s, light)


static func _palm(parent: Node2D, p: Vector2, s: float,
		rng: RandomNumberGenerator) -> void:
	_poly(parent, Color(0.3, 0.35, 0.28, 0.2), _blob_pts(p + Vector2(0, 3 * s), 9 * s, 8))
	# Blago iskrivljeno stablo.
	var lean := rng.randf_range(-3.0, 3.0) * s
	_poly(parent, Color(0.56, 0.42, 0.26), [
		p + Vector2(-2 * s, 3 * s), p + Vector2(2 * s, 3 * s),
		p + Vector2(lean + 1.6 * s, -20 * s), p + Vector2(lean - 1.6 * s, -20 * s),
	])
	# Listovi na sve strane.
	var top := p + Vector2(lean, -21 * s)
	for i in 6:
		var a := TAU * float(i) / 6.0 + rng.randf_range(-0.2, 0.2)
		var tip := top + Vector2(cos(a) * 15 * s, sin(a) * 8 * s - 3 * s)
		var mid := top + Vector2(cos(a) * 8 * s, sin(a) * 4 * s - 5 * s)
		_poly(parent, Color(0.24, 0.58, 0.3), [
			top + Vector2(-1.6 * s, 0), mid, tip, mid + Vector2(0, 3.5 * s),
			top + Vector2(1.6 * s, 1 * s),
		])
	# Kokosi.
	for i in 2:
		_blob(parent, top + Vector2(rng.randf_range(-4, 4) * s, 2.5 * s),
			2.2 * s, Color(0.45, 0.32, 0.2))


static func _cactus(parent: Node2D, p: Vector2, s: float,
		rng: RandomNumberGenerator) -> void:
	_poly(parent, Color(0.3, 0.3, 0.25, 0.2), _blob_pts(p + Vector2(0, 3 * s), 8 * s, 8))
	var green := Color(0.3, 0.58, 0.34)
	# Stablo.
	_poly(parent, green, [
		p + Vector2(-3.4 * s, 3 * s), p + Vector2(3.4 * s, 3 * s),
		p + Vector2(3 * s, -17 * s), p + Vector2(-3 * s, -17 * s),
	])
	_blob(parent, p + Vector2(0, -17 * s), 3.2 * s, green)
	# Krake - jedna ili dve.
	if rng.randf() > 0.35:
		_poly(parent, green, [
			p + Vector2(-3 * s, -8 * s), p + Vector2(-9 * s, -8 * s),
			p + Vector2(-9 * s, -14 * s), p + Vector2(-6.4 * s, -14 * s),
			p + Vector2(-6.4 * s, -10.6 * s), p + Vector2(-3 * s, -10.6 * s),
		])
	if rng.randf() > 0.5:
		_poly(parent, green, [
			p + Vector2(3 * s, -11 * s), p + Vector2(8.6 * s, -11 * s),
			p + Vector2(8.6 * s, -16 * s), p + Vector2(6.2 * s, -16 * s),
			p + Vector2(6.2 * s, -13.4 * s), p + Vector2(3 * s, -13.4 * s),
		])
	# Cvetic na vrhu.
	if rng.randf() > 0.6:
		_blob(parent, p + Vector2(0, -20 * s), 2 * s, Color(0.95, 0.5, 0.65))


static func _fir(parent: Node2D, p: Vector2, s: float,
		rng: RandomNumberGenerator) -> void:
	_poly(parent, Color(0.55, 0.62, 0.7, 0.25), _blob_pts(p + Vector2(0, 3 * s), 9 * s, 8))
	_poly(parent, Color(0.42, 0.32, 0.22), [
		p + Vector2(-1.8 * s, 3 * s), p + Vector2(1.8 * s, 3 * s),
		p + Vector2(1.4 * s, -3 * s), p + Vector2(-1.4 * s, -3 * s),
	])
	var dark := Color(0.2, 0.42, 0.3)
	# Tri nivoa - jelka.
	_poly(parent, dark, [
		p + Vector2(-9 * s, -2 * s), p + Vector2(9 * s, -2 * s), p + Vector2(0, -13 * s)])
	_poly(parent, dark, [
		p + Vector2(-7.5 * s, -9 * s), p + Vector2(7.5 * s, -9 * s), p + Vector2(0, -19 * s)])
	_poly(parent, dark, [
		p + Vector2(-5.5 * s, -15 * s), p + Vector2(5.5 * s, -15 * s), p + Vector2(0, -24 * s)])
	# Sneg na granama.
	_poly(parent, Color(1, 1, 1, 0.85), [
		p + Vector2(-6 * s, -3 * s), p + Vector2(6 * s, -3 * s),
		p + Vector2(3.4 * s, -6 * s), p + Vector2(-3.4 * s, -6 * s)])
	_poly(parent, Color(1, 1, 1, 0.8), [
		p + Vector2(-4.4 * s, -10 * s), p + Vector2(4.4 * s, -10 * s),
		p + Vector2(2.4 * s, -13 * s), p + Vector2(-2.4 * s, -13 * s)])
	_blob(parent, p + Vector2(0, -24.5 * s), 2 * s, Color(1, 1, 1, 0.9))


static func _dead_tree(parent: Node2D, p: Vector2, s: float) -> void:
	var col := Color(0.24, 0.2, 0.18)
	_poly(parent, col, [
		p + Vector2(-2 * s, 3 * s), p + Vector2(2 * s, 3 * s),
		p + Vector2(1.4 * s, -16 * s), p + Vector2(-1.4 * s, -16 * s)])
	# Gole grane.
	_poly(parent, col, [
		p + Vector2(-1.4 * s, -9 * s), p + Vector2(-8 * s, -15 * s),
		p + Vector2(-7 * s, -16.6 * s), p + Vector2(-1.4 * s, -11.4 * s)])
	_poly(parent, col, [
		p + Vector2(1.4 * s, -11 * s), p + Vector2(7 * s, -17.6 * s),
		p + Vector2(8 * s, -16 * s), p + Vector2(1.4 * s, -13.4 * s)])


static func _rock(parent: Node2D, p: Vector2, r: float, col: Color,
		rng: RandomNumberGenerator) -> void:
	_poly(parent, Color(0.3, 0.3, 0.3, 0.18), _blob_pts(p + Vector2(1, r * 0.5), r, 7))
	_poly(parent, col, [
		p + Vector2(-r, r * 0.4), p + Vector2(-r * 0.5, -r * 0.8),
		p + Vector2(r * 0.4, -r), p + Vector2(r, -r * 0.2),
		p + Vector2(r * 0.6, r * 0.5),
	])
	_poly(parent, col.lightened(0.22), [
		p + Vector2(-r * 0.4, -r * 0.3), p + Vector2(0, -r * 0.8),
		p + Vector2(r * 0.4, -r * 0.4), p + Vector2(0, -r * 0.1),
	])


static func _flower(parent: Node2D, p: Vector2, rng: RandomNumberGenerator) -> void:
	var cols := [Color(1, 0.95, 0.4), Color(1, 0.6, 0.75), Color(0.95, 0.98, 1),
		Color(0.75, 0.6, 0.95)]
	var col: Color = cols[rng.randi() % cols.size()]
	_poly(parent, Color(0.35, 0.6, 0.3), [
		p + Vector2(-0.6, 0), p + Vector2(0.6, 0),
		p + Vector2(0.6, -4), p + Vector2(-0.6, -4)])
	for i in 4:
		var a := TAU * float(i) / 4.0
		_blob(parent, p + Vector2(cos(a) * 2.2, sin(a) * 2.2 - 5), 1.7, col)
	_blob(parent, p + Vector2(0, -5), 1.2, Color(1, 0.85, 0.3))


static func _lake(parent: Node2D, p: Vector2, r: float,
		rng: RandomNumberGenerator) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var seg := 16
	for i in seg:
		var a := TAU * float(i) / float(seg)
		var w := rng.randf_range(0.85, 1.15)
		var d := Vector2(cos(a), sin(a) * 0.58)
		outer.append(p + d * (r * w))
		inner.append(p + d * (r * w * 0.82))
	_poly(parent, Color(0.72, 0.86, 0.7), outer)
	_poly(parent, Color(0.42, 0.7, 0.88), inner)
	_poly(parent, Color(1, 1, 1, 0.3), [
		p + Vector2(-r * 0.4, -r * 0.18), p + Vector2(-r * 0.05, -r * 0.26),
		p + Vector2(r * 0.1, -r * 0.12), p + Vector2(-r * 0.28, -r * 0.04)])


# --- NISKO-NIVO HELPERI ---

static func _blob_pts(center: Vector2, r: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(center + Vector2(cos(a), sin(a) * 0.9) * r)
	return pts


static func _blob(parent: Node2D, center: Vector2, r: float, col: Color) -> void:
	_poly(parent, col, _blob_pts(center, r, 12))


static func _ribbon(parent: Node2D, line: Array, width: float, col: Color) -> void:
	if line.size() < 2:
		return
	var half := width * 0.5
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in line.size():
		var p: Vector2 = line[i]
		var d: Vector2
		if i == 0:
			d = (line[1] - p).normalized()
		elif i == line.size() - 1:
			d = (p - line[i - 1]).normalized()
		else:
			d = (line[i + 1] - line[i - 1]).normalized()
		if d == Vector2.ZERO:
			d = Vector2.RIGHT
		var n := Vector2(-d.y, d.x) * half
		left.append(p + n)
		right.append(p - n)
	var poly := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	_poly(parent, col, poly)


static func _poly(parent: Node, col: Color, points: Variant) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = points if points is PackedVector2Array else PackedVector2Array(points)
	parent.add_child(p)
