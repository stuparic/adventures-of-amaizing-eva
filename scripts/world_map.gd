extends Node2D
## Mapa sveta - level picker. Tacke po klimatskim predelima, spojene
## krivudavim putevima, sa drvecem, jezerima i rekom.
##
## Nivoi se citaju iz Game.LEVELS. Nivo koji jos nema scenu prikazuje se kao
## zatvorena tacka sa oznakom "uskoro" - kad mu upises scenu, sam se otvori.
##
## Kontrole:
##   strelice / A-D  - biraj nivo
##   SPACE / Enter   - udji u nivo
##   + / -           - zumiraj (radi i skrol misa, i pinch na telefonu)
##   klik / dodir    - izaberi, pa ponovo za ulaz

const DOT_R := 34.0            # poluprecnik tacke nivoa
const ROAD_W := 7.0            # sirina puta
const DASH_LEN := 26.0         # duzina crtice na putu
const DASH_GAP := 20.0         # praznina izmedju crtica
const CURVE_STEPS := 30        # segmenata po krivini (vise = glatkije)

## Putevi su MORSKI - putujemo brodom od ostrva do ostrva.
## ZATVOREN: jedva vidljive tackice.
const C_ROAD := Color(1, 1, 1, 0.2)
const C_ROAD_EDGE := Color(0.6, 0.8, 0.92, 0.14)
## PROHODAN: jasna bela brazda - moze se ploviti.
const C_ROAD_OPEN := Color(1, 1, 1, 0.72)
const C_ROAD_OPEN_EDGE := Color(0.55, 0.78, 0.92, 0.55)
## PREDJEN: zlatna brazda.
const C_ROAD_DONE := Color(1, 0.92, 0.5, 0.9)
const C_ROAD_DONE_EDGE := Color(0.88, 0.68, 0.22, 0.7)
## Kopneni put (unutar ostrva) - zemljana staza.
## NEPRELAZAN: bleda, tanka, providna - vidi se da tu jos ne moze.
const C_LAND := Color(0.72, 0.68, 0.6, 0.4)
const C_LAND_EDGE := Color(0.55, 0.5, 0.45, 0.3)
## PROHODAN: jasna zemljana staza - moze se ici, ali cilj nije predjen.
const C_LAND_OPEN := Color(0.88, 0.78, 0.56)
const C_LAND_OPEN_EDGE := Color(0.68, 0.56, 0.38)
## PREDJEN: puna zlatna staza sa jasnim obodom.
const C_LAND_DONE := Color(0.98, 0.84, 0.34)
const C_LAND_DONE_EDGE := Color(0.78, 0.6, 0.2)
const LAND_W := 12.0
const LAND_W_LOCKED := 5.0

const C_LOCKED := Color(0.62, 0.62, 0.66)
const C_TEXT := Color(0.22, 0.3, 0.42)

const StarIcon := preload("res://scenes/hud_star.tscn")

## Granice zuma. MANJI broj = vidi se VISE mape.
const ZOOM_MIN := 0.16
const ZOOM_MAX := 1.6
const ZOOM_STEP := 0.12

@onready var camera: Camera2D = $Camera
@onready var title: Label = $UI/Title
@onready var info: Label = $UI/Info
@onready var eva_marker: Node2D = $EvaMarker
@onready var scenery: Node2D = $Scenery

var _selected := 0
var _dots: Array[Node2D] = []
var _t := 0.0
var _entering := false
var _zoom := 1.0
var _target_zoom := 1.0

## Pinch na telefonu: prati prste i pocetnu razdaljinu.
var _touches: Dictionary = {}
var _pinch_start_dist := 0.0
var _pinch_start_zoom := 1.0
var _zoom_initialized := false
var _boat: Node2D
var _is_web := OS.has_feature("web")


## Pomeranje mape prevlacenjem (drag). Kad korisnik pomeri mapu, kamera
## prestaje da prati izabranu tacku dok ne izabere drugu.
var _dragging := false
var _drag_last := Vector2.ZERO
var _free_camera := false


func _ready() -> void:
	# Evina instanca nosi svoju Camera2D. Ugasi je i uzmi kontrolu -
	# inace render prati nju, a zoom mapine kamere nema efekta.
	var eva_cam := get_node_or_null("EvaMarker/Eva/Camera") as Camera2D
	if eva_cam != null:
		eva_cam.enabled = false
	camera.make_current()

	_selected = _first_playable()
	_build_scenery()
	_build_map()
	_build_boat()
	_fit_zoom()
	_update_selection()

	# Vidljiva dugmad za zum - rade svuda, bez zavisnosti od skrola,
	# tastature ili pinch gesta (koji se razlikuju po platformi).
	# Web: izlozi zum HTML dugmadima iz shell.html preko JavaScriptBridge.
	# Godotov input na webu nije pouzdan za skrol/pinch, pa HTML dugmad
	# pozivaju ovo direktno.
	if OS.has_feature("web"):
		_expose_web_api()


	Audio.play_music()


func _first_playable() -> int:
	for i in Game.level_count():
		if Game.level_unlocked(i) and Game.level_exists(i) and not Game.level_completed(i):
			return i
	for i in range(Game.level_count() - 1, -1, -1):
		if Game.level_unlocked(i):
			return i
	return 0


## Pocetni zum: na telefonu blize (uzak ekran), na desktopu sire.
##
## BITNO: ovo se izvrsava SAMO JEDNOM. Ranije je bilo vezano na
## viewport.size_changed, a browser taj signal salje stalno (canvas se
## prilagodjava) - pa se korisnikov zum resetovao svaki put.
func _fit_zoom() -> void:
	if _zoom_initialized:
		return
	_zoom_initialized = true

	var win := DisplayServer.window_get_size()
	var short_side := float(mini(win.x, win.y))
	if short_side <= 0.0:
		# Prvi frejm na webu moze da vrati 0 - probaj iz viewporta.
		short_side = minf(get_viewport().get_visible_rect().size.x,
			get_viewport().get_visible_rect().size.y)
	_target_zoom = 0.85 if short_side < 500.0 else 1.0
	_zoom = _target_zoom
	camera.zoom = Vector2(_zoom, _zoom)


## --- PEJZAZ: jezera, reka, drvece, kamenje ---

func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260805   # fiksno: arhipelag izgleda isto pri svakom pokretanju

	# Talasi po okeanu - daju osecaj vode, ne praznog plavog polja.
	_add_ocean_waves(rng)

	# Ostrva iz ISLANDS - na jednom moze da bude vise nivoa.
	for i in Game.island_count():
		var isl := Game.island_data(i)
		BiomeArt.draw_island(scenery, String(isl["biome"]),
			isl["pos"], isl["size"], 1000 + i * 137)


	# Mnogo bezimenih ostrvaca - okean treba da bude PUN, ne prazan.
	# Bioma svakog prati najblize veliko ostrvo, pa se svet oseca povezano.
	_scatter_islets(rng)


## Brodic pod Evom - na mapi putuje morem od ostrva do ostrva.
func _build_boat() -> void:
	_boat = Node2D.new()
	_boat.z_index = 2
	eva_marker.add_child(_boat)
	eva_marker.move_child(_boat, 0)   # ispod Eve i Budzumbore

	# Trup.
	_poly(_boat, Color(0.62, 0.42, 0.26), [
		Vector2(-26, 8), Vector2(26, 8), Vector2(20, 20), Vector2(-20, 20),
	])
	_poly(_boat, Color(0.74, 0.53, 0.34), [
		Vector2(-26, 8), Vector2(26, 8), Vector2(24, 12), Vector2(-24, 12),
	])
	# Jarbol i jedro.
	_poly(_boat, Color(0.5, 0.36, 0.22), [
		Vector2(-1.6, -26), Vector2(1.6, -26), Vector2(1.6, 8), Vector2(-1.6, 8),
	])
	_poly(_boat, Color(1, 0.98, 0.94), [
		Vector2(2.6, -24), Vector2(20, -4), Vector2(2.6, 4),
	])
	_poly(_boat, Color(0.95, 0.4, 0.55), [
		Vector2(2.6, -24), Vector2(12, -13), Vector2(2.6, -9),
	])
	# Zastavica.
	_poly(_boat, Color(0.98, 0.75, 0.25), [
		Vector2(1.6, -26), Vector2(11, -23.5), Vector2(1.6, -21),
	])


## Nekoliko malih ostrvaca radi flavora - NE gomila. Glavna ostrva su
## velika i dominiraju kadrom; ovi su samo detalj u prolazu.
func _scatter_islets(rng: RandomNumberGenerator) -> void:
	# Rucno izabrane pozicije u prazninama izmedju velikih ostrva.
	var spots := [
		[Vector2(760, 1010), "livada", 150.0],
		[Vector2(1620, 240), "plaza", 130.0],
		[Vector2(2400, 1080), "dzungla", 150.0],
		[Vector2(3220, 240), "pustinja", 135.0],
		[Vector2(4120, 1040), "sneg", 145.0],
		[Vector2(1500, 620), "plaza", 100.0],
		[Vector2(3160, 640), "sneg", 110.0],
		[Vector2(4800, 700), "vulkan", 120.0],
	]
	for i in spots.size():
		var pos: Vector2 = spots[i][0]
		var biome: String = spots[i][1]
		var w: float = spots[i][2]
		var sz := Vector2(w, w * rng.randf_range(0.6, 0.72))
		BiomeArt.draw_island(scenery, biome, pos, sz, 5000 + i * 131)

## Talasi: kratke bele crtice po okeanu, gusce blizu ostrva.
func _add_ocean_waves(rng: RandomNumberGenerator) -> void:
	# Jata riba - male tamne tackice u grupama.
	for school in 8:
		var cx := rng.randf_range(-300.0, 3450.0)
		var cy := rng.randf_range(60.0, 1280.0)
		for f in rng.randi_range(4, 8):
			var fp := Vector2(cx + rng.randf_range(-22.0, 22.0),
				cy + rng.randf_range(-12.0, 12.0))
			_poly(scenery, Color(0.24, 0.42, 0.55, 0.35), [
				fp + Vector2(-3.4, 0), fp + Vector2(0, -1.7),
				fp + Vector2(3.4, 0), fp + Vector2(0, 1.7),
			])

	# Nekoliko dalekih jedrilica - svet je naseljen.
	for i in 3:
		var p := Vector2(rng.randf_range(0.0, 3700.0), rng.randf_range(180.0, 1080.0))
		_poly(scenery, Color(1, 1, 1, 0.5), [
			p + Vector2(-5, 3), p + Vector2(5, 3), p + Vector2(4, 5), p + Vector2(-4, 5)])
		_poly(scenery, Color(1, 1, 1, 0.55), [
			p + Vector2(0.5, -7), p + Vector2(5, 2), p + Vector2(0.5, 2)])

	for i in 90:
		var p := Vector2(rng.randf_range(-400.0, 3600.0), rng.randf_range(20.0, 1320.0))
		var w := rng.randf_range(9.0, 20.0)
		var a := Color(1, 1, 1, rng.randf_range(0.1, 0.24))
		_poly(scenery, a, [
			p + Vector2(-w, 0), p + Vector2(-w * 0.35, -2.2),
			p + Vector2(w * 0.35, 0), p + Vector2(w, -1.6),
			p + Vector2(w * 0.35, 1.4), p + Vector2(-w * 0.35, -0.6),
		])



## Jezero: nepravilan poligon + svetliji obod (plicak) + odsjaj.
func _add_lake(center: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var seg := 20
	var wob: Array[float] = []
	for i in seg:
		wob.append(rng.randf_range(0.82, 1.18))

	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		# sin * 0.6 -> spljosteno, kao jezero u perspektivi
		var d := Vector2(cos(a), sin(a) * 0.6)
		outer.append(center + d * (r * wob[i]))
		inner.append(center + d * (r * wob[i] * 0.85))

	_poly_pts(scenery, Color(0.74, 0.87, 0.72), outer)
	_poly_pts(scenery, Color(0.42, 0.7, 0.88), inner)
	_poly(scenery, Color(1, 1, 1, 0.28), [
		center + Vector2(-r * 0.42, -r * 0.2),
		center + Vector2(-r * 0.04, -r * 0.28),
		center + Vector2(r * 0.12, -r * 0.12),
		center + Vector2(-r * 0.3, -r * 0.04),
	])


## Reka: glatka Catmull-Rom kriva kroz sve tacke, sa obalom i odsjajem.
func _add_river(pts: Array) -> void:
	var smooth := _catmull(pts, 16)
	_ribbon(scenery, smooth, 34.0, Color(0.74, 0.87, 0.72))       # obala
	_ribbon(scenery, smooth, 24.0, Color(0.45, 0.72, 0.9))        # voda
	_ribbon(scenery, smooth, 8.0, Color(0.7, 0.87, 0.97, 0.45))   # odsjaj


## Drvo: senka, stablo, krosnja od tri "blob"-a u dva tona.
func _add_tree(pos: Vector2, big: bool, rng: RandomNumberGenerator) -> void:
	var s := (1.25 if big else 0.9) * rng.randf_range(0.88, 1.12)

	_poly(scenery, Color(0.35, 0.4, 0.32, 0.2), [
		pos + Vector2(-13 * s, 2 * s), pos + Vector2(13 * s, 2 * s),
		pos + Vector2(11 * s, 8 * s), pos + Vector2(-11 * s, 8 * s),
	])
	_poly(scenery, Color(0.5, 0.36, 0.24), [
		pos + Vector2(-3.5 * s, -6 * s), pos + Vector2(3.5 * s, -6 * s),
		pos + Vector2(2.8 * s, 5 * s), pos + Vector2(-2.8 * s, 5 * s),
	])

	var dark := Color(0.24, 0.5, 0.28)
	var light := Color(0.37, 0.67, 0.37)
	_blob(scenery, pos + Vector2(-8 * s, -16 * s), 11 * s, dark)
	_blob(scenery, pos + Vector2(8 * s, -15 * s), 10 * s, dark)
	_blob(scenery, pos + Vector2(0, -24 * s), 13 * s, dark)
	_blob(scenery, pos + Vector2(-3 * s, -20 * s), 9 * s, light)
	_blob(scenery, pos + Vector2(5 * s, -22 * s), 7 * s, light)


## --- MAPA: krivudavi putevi i tacke ---

func _build_map() -> void:
	var roads := Node2D.new()
	roads.name = "Roads"
	roads.z_index = 1
	add_child(roads)

	for i in Game.level_count() - 1:
		_add_curved_road(roads, i)

	for i in Game.level_count():
		_add_dot(i)


## Put izmedju dva nivoa. Dve vrste:
##   KOPNENI (isto ostrvo)  - zemljana staza, Eva ide peske
##   MORSKI (drugo ostrvo)  - bela brazda, Eva ide brodicem
##
## Oba su krivudava: kvadratna Bezier kriva sa kontrolnom tackom
## pomerenom u stranu, plus sitno "vijuganje" da linija ne bude
## matematicki glatka nego organska.
func _add_curved_road(parent: Node2D, from_index: int) -> void:
	# Ne crtaj put ka nivou koji jos NE POSTOJI - staza ka praznom mestu
	# samo zbunjuje. Tacka "uskoro" stoji sama.
	if not Game.level_exists(from_index + 1):
		return

	var a: Vector2 = Game.level_data(from_index)["pos"]
	var b: Vector2 = Game.level_data(from_index + 1)["pos"]
	var land := Game.same_island(from_index, from_index + 1)
	# Tri stanja: PREDJEN (oba predjena), PROHODAN (moze se ici ali
	# ciljni nije predjen), ZATVOREN (nivo pre nije predjen).
	var passable := Game.level_completed(from_index)
	var done := passable and Game.level_completed(from_index + 1)

	# Kopneni put krivuda manje (staza po ostrvu), morski vise (plovidba).
	var span := a.distance_to(b)
	var bend := span * (0.16 if land else 0.3)
	# Naizmenicno gore/dole, da putevi ne budu svi u istu stranu.
	if from_index % 2 == 1:
		bend = -bend

	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var ctrl := mid + normal * bend

	var col: Color
	var edge: Color
	if land:
		if done:
			col = C_LAND_DONE
			edge = C_LAND_DONE_EDGE
		elif passable:
			col = C_LAND_OPEN
			edge = C_LAND_OPEN_EDGE
		else:
			col = C_LAND
			edge = C_LAND_EDGE
	else:
		if done:
			col = C_ROAD_DONE
			edge = C_ROAD_DONE_EDGE
		elif passable:
			col = C_ROAD_OPEN
			edge = C_ROAD_OPEN_EDGE
		else:
			col = C_ROAD
			edge = C_ROAD_EDGE

	# Uzorkuj krivu + dodaj organsko vijuganje.
	var wob := RandomNumberGenerator.new()
	wob.seed = 700 + from_index * 53
	var pts: Array = []
	for i in CURVE_STEPS + 1:
		var t := float(i) / float(CURVE_STEPS)
		var base := _bezier(a, ctrl, b, t)
		# Vijuganje: sinus po duzini, jace u sredini nego na krajevima.
		var taper := sin(t * PI)
		var amp := (7.0 if land else 11.0) * taper
		var phase := t * (5.0 if land else 3.2) * TAU
		base += normal * sin(phase + wob.randf() * 0.4) * amp * 0.35
		pts.append(base)

	if land:
		var inset := DOT_R + 6.0
		var trimmed: Array = []
		for pt in pts:
			if pt.distance_to(a) > inset and pt.distance_to(b) > inset:
				trimmed.append(pt)
		if trimmed.size() < 2:
			return

		if passable:
			# PROHODAN ili PREDJEN: puna staza sa kamencicima - Eva ide peske.
			_ribbon(parent, trimmed, LAND_W + 5.0, edge)
			_ribbon(parent, trimmed, LAND_W, col)
			var stone_col := Color(0.8, 0.72, 0.5, 0.8) if done \
				else Color(0.72, 0.64, 0.48, 0.7)
			for i in range(2, trimmed.size() - 2, 4):
				var pp: Vector2 = trimmed[i]
				_poly(parent, stone_col,
					_ring_pts(pp + Vector2(wob.randf_range(-3, 3), wob.randf_range(-3, 3)),
						wob.randf_range(1.6, 2.6), 6))
		else:
			# NEPRELAZAN: samo tackice - staza jos "nije prokopana".
			for i in range(1, trimmed.size() - 1, 3):
				var pp: Vector2 = trimmed[i]
				_poly(parent, col, _ring_pts(pp, LAND_W_LOCKED * 0.45, 7))
		return

	# Morski put: isprekidana brazda. Neprelazan ima redje i tanje crtice.
	var dash_len := DASH_LEN if passable else DASH_LEN * 0.4
	var dash_gap := DASH_GAP if passable else DASH_GAP * 1.8
	var inset := DOT_R + 7.0
	var walked := 0.0
	var dash_on := true
	var current: Array = []

	for i in pts.size() - 1:
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		if p1.distance_to(a) < inset or p1.distance_to(b) < inset:
			continue
		walked += p1.distance_to(p2)
		if dash_on:
			if current.is_empty():
				current.append(p1)
			current.append(p2)
			if walked >= dash_len:
				_dash(parent, current, edge, col, ROAD_W if passable else ROAD_W * 0.55)
				current = []
				walked = 0.0
				dash_on = false
		elif walked >= dash_gap:
			walked = 0.0
			dash_on = true

	if current.size() >= 2:
		_dash(parent, current, edge, col, ROAD_W if passable else ROAD_W * 0.55)


## Krug od tacaka - za kamencice.
func _ring_pts(center: Vector2, r: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var ang := TAU * float(i) / float(seg)
		pts.append(center + Vector2(cos(ang), sin(ang) * 0.85) * r)
	return pts



## Jedna crtica: obod pa ispuna.
func _dash(parent: Node2D, line: Array, edge: Color, fill: Color, w := ROAD_W) -> void:
	if line.size() < 2:
		return
	_ribbon(parent, line, w + 4.0, edge)
	_ribbon(parent, line, w, fill)


func _add_dot(index: int) -> void:
	var data := Game.level_data(index)
	var pos: Vector2 = data["pos"]
	var exists := Game.level_exists(index)
	var unlocked := Game.level_unlocked(index)
	var done := Game.level_completed(index)

	var dot := Node2D.new()
	dot.name = "Dot%d" % index
	dot.position = pos
	dot.z_index = 2
	add_child(dot)
	_dots.append(dot)

	var isl := Game.island_of(index)
	var biome_col: Color = BiomeArt.PALETTES.get(
		String(isl.get("biome", "livada")), BiomeArt.PALETTES["livada"])["ground"]

	# Senka na tlu.
	var shadow := _circle(DOT_R * 1.05, Color(0.15, 0.2, 0.28, 0.22))
	shadow.position = Vector2(2, DOT_R * 0.5)
	shadow.scale = Vector2(1.15, 0.4)
	dot.add_child(shadow)

	if done:
		# --- ZAVRSEN: zlatan medaljon sa dvostrukim prstenom i sjajem ---
		dot.add_child(_circle(DOT_R + 5.0, Color(1, 0.88, 0.4, 0.5)))
		dot.add_child(_circle(DOT_R + 3.0, Color(1, 1, 1, 0.95)))
		dot.add_child(_circle(DOT_R, C_ROAD_DONE))
		dot.add_child(_circle(DOT_R - 5.0, Color(1, 0.95, 0.72)))
		dot.add_child(_circle(DOT_R - 9.0, Color(1, 0.99, 0.88)))
	elif exists and unlocked:
		# --- DOSTUPAN: cist medaljon u boji biomа, pulsira ---
		dot.add_child(_circle(DOT_R + 3.0, Color(1, 1, 1, 0.95)))
		dot.add_child(_circle(DOT_R, biome_col.darkened(0.12)))
		dot.add_child(_circle(DOT_R - 6.0, Color(0.99, 0.98, 0.94)))
	elif exists:
		# --- ZAKLJUCAN (postoji ali nije otvoren): siv sa katancem ---
		dot.add_child(_circle(DOT_R + 3.0, Color(0.92, 0.92, 0.94, 0.9)))
		dot.add_child(_circle(DOT_R, Color(0.62, 0.63, 0.68)))
		dot.add_child(_circle(DOT_R - 6.0, Color(0.82, 0.83, 0.86)))
	else:
		# --- NE POSTOJI ("uskoro"): isprekidan obris, providno, bez ispune.
		#     Vizualno jasno drugacije: nije zakljucan nego jos NE POSTOJI.
		var seg := 16
		for k in seg:
			if k % 2 == 1:
				continue
			var a0 := TAU * float(k) / float(seg)
			var a1 := TAU * float(k + 1) / float(seg)
			var pts := PackedVector2Array()
			for t in 5:
				var aa: float = lerpf(a0, a1, float(t) / 4.0)
				pts.append(Vector2(cos(aa), sin(aa)) * (DOT_R + 2.0))
			for t in range(4, -1, -1):
				var aa: float = lerpf(a0, a1, float(t) / 4.0)
				pts.append(Vector2(cos(aa), sin(aa)) * (DOT_R - 3.0))
			_poly_pts(dot, Color(1, 1, 1, 0.6), pts)
		# Bleda ispuna - vidi se da je mesto rezervisano.
		dot.add_child(_circle(DOT_R - 4.0, Color(1, 1, 1, 0.14)))
		# Znak pitanja umesto broja.
		var q := Label.new()
		q.text = "?"
		q.add_theme_font_size_override("font_size", 30)
		q.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		q.add_theme_constant_override("outline_size", 6)
		q.add_theme_color_override("font_outline_color", Color(0.35, 0.5, 0.65, 0.5))
		q.size = Vector2(DOT_R * 2, DOT_R * 2)
		q.position = Vector2(-DOT_R, -DOT_R + 3)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(q)

	# Sjaj gore levo - medaljon nije ravan (osim "uskoro" tacaka).
	if exists:
		var shine := _circle(DOT_R * 0.4, Color(1, 1, 1, 0.5))
		shine.position = Vector2(-DOT_R * 0.28, -DOT_R * 0.32)
		dot.add_child(shine)


	# Oznaka: kvacica (predjen) / broj (dostupan) / katanac (zakljucan).
	# "Uskoro" tacke vec imaju "?" pa se preskacu.
	if not exists:
		pass
	elif done:
		_add_check(dot)
	elif not unlocked:
		_add_lock(dot)
	else:
		var mark := Label.new()
		mark.text = str(index + 1)
		mark.add_theme_font_size_override("font_size", 28)
		mark.add_theme_color_override("font_color", C_TEXT)
		mark.add_theme_constant_override("outline_size", 5)
		mark.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		mark.size = Vector2(DOT_R * 2, DOT_R * 2)
		mark.position = Vector2(-DOT_R, -DOT_R + 5)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.add_child(mark)

	var name_label := Label.new()
	name_label.text = String(data["name"])
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color",
		C_TEXT if (exists and unlocked) else Color(0.5, 0.5, 0.56))
	name_label.add_theme_constant_override("outline_size", 7)
	name_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	name_label.size = Vector2(210, 28)
	name_label.position = Vector2(-105, DOT_R + 8)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.add_child(name_label)

	if not exists:
		var soon := Label.new()
		soon.text = "uskoro"
		soon.add_theme_font_size_override("font_size", 14)
		soon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.58))
		soon.add_theme_constant_override("outline_size", 6)
		soon.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.85))
		soon.size = Vector2(210, 22)
		soon.position = Vector2(-105, DOT_R + 30)
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.add_child(soon)

	var btn := Button.new()
	btn.flat = true
	btn.size = Vector2(DOT_R * 2 + 18, DOT_R * 2 + 18)
	btn.position = Vector2(-DOT_R - 9, -DOT_R - 9)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		if _selected == index:
			_enter_level()
		else:
			_selected = index
			_free_camera = false
			_update_selection()
			Audio.play("checkpoint")
	)
	dot.add_child(btn)


## Kvacica - oznaka da je nivo PREDJEN.
func _add_check(parent: Node2D) -> void:
	# Debela kvacica sa belim obodom - vidi se na zlatnoj podlozi.
	var pts := PackedVector2Array([
		Vector2(-10, 0), Vector2(-6.5, -3.5), Vector2(-2.5, 1),
		Vector2(6.5, -8.5), Vector2(10.5, -5), Vector2(-2.5, 8.5),
	])
	var outline := Polygon2D.new()
	outline.color = Color(1, 1, 1, 0.9)
	outline.polygon = pts
	outline.scale = Vector2(1.28, 1.28)
	parent.add_child(outline)

	var check := Polygon2D.new()
	check.color = Color(0.24, 0.58, 0.3)
	check.polygon = pts
	parent.add_child(check)


## Katanac od poligona (emoji ne radi u Godotovom web fontu).
func _add_lock(parent: Node2D) -> void:
	var shackle := Polygon2D.new()
	shackle.color = Color(0.48, 0.48, 0.54)
	shackle.polygon = PackedVector2Array([
		Vector2(-5, -2), Vector2(-5, -8), Vector2(-2.5, -11), Vector2(2.5, -11),
		Vector2(5, -8), Vector2(5, -2), Vector2(2.5, -2), Vector2(2.5, -7.5),
		Vector2(1.5, -8.5), Vector2(-1.5, -8.5), Vector2(-2.5, -7.5), Vector2(-2.5, -2),
	])
	parent.add_child(shackle)

	var body := Polygon2D.new()
	body.color = Color(0.58, 0.58, 0.63)
	body.polygon = PackedVector2Array([
		Vector2(-8, -2), Vector2(8, -2), Vector2(8, 11), Vector2(-8, 11),
	])
	parent.add_child(body)

	var hole := Polygon2D.new()
	hole.color = Color(0.34, 0.34, 0.38)
	hole.polygon = PackedVector2Array([
		Vector2(-1.8, 2), Vector2(1.8, 2), Vector2(1.8, 6.5), Vector2(-1.8, 6.5),
	])
	parent.add_child(hole)


## --- Geometrija ---

## Kvadratna Bezier kriva.
func _bezier(a: Vector2, ctrl: Vector2, b: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return a * (u * u) + ctrl * (2.0 * u * t) + b * (t * t)


## Catmull-Rom: glatka kriva koja prolazi kroz SVE date tacke (reka).
func _catmull(pts: Array, steps: int) -> Array:
	if pts.size() < 2:
		return pts.duplicate()
	var out: Array = []
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		for s in steps:
			var t := float(s) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * (
				(2.0 * p1)
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	out.append(pts[pts.size() - 1])
	return out


## "Traka" konstantne sirine duz niza tacaka - reka i putevi.
func _ribbon(parent: Node2D, line: Array, width: float, col: Color) -> void:
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
	_poly_pts(parent, col, poly)


func _blob(parent: Node2D, center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var seg := 14
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(center + Vector2(cos(a), sin(a) * 0.92) * r)
	_poly_pts(parent, col, pts)


func _circle(r: float, col: Color, segments := 28) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	return p


func _poly(parent: Node, col: Color, points: Array) -> void:
	_poly_pts(parent, col, PackedVector2Array(points))


func _poly_pts(parent: Node, col: Color, points: PackedVector2Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = points
	parent.add_child(p)


## --- Izbor nivoa i zum ---

func _process(delta: float) -> void:
	_t += delta

	if _is_web:
		_poll_web_commands()

	# Glatko zumiranje.
	_zoom = lerpf(_zoom, _target_zoom, delta * 8.0)
	camera.zoom = Vector2(_zoom, _zoom)

	if _selected < _dots.size():
		var target: Vector2 = _dots[_selected].position + Vector2(0, -DOT_R - 30.0)
		target.y += sin(_t * 3.0) * 5.0
		eva_marker.position = eva_marker.position.lerp(target, delta * 7.0)
		# Kamera prati izbor - ali ne ako je korisnik sam pomerio mapu.
		# Cilja ostrvo, ne bovu: bova je u vodi ispod ostrva, pa bi kadar
		# ispao previse nisko.
		if not _free_camera:
			# Cilja malo iznad tacke - vidi se i ostrvo iza nje.
			var target_c: Vector2 = _dots[_selected].position + Vector2(0, -40.0)
			camera.position = camera.position.lerp(target_c, delta * 4.0)

	for i in _dots.size():
		var s := 1.0
		if i == _selected:
			s = 1.0 + sin(_t * 4.0) * 0.07
		_dots[i].scale = _dots[i].scale.lerp(Vector2(s, s), delta * 8.0)


## Zum ide u _input, NE u _unhandled_input: Button nodovi na tackama
## presrecu skrol i dodir pre nego sto stigne do _unhandled_input.
func _input(event: InputEvent) -> void:
	if _entering:
		return

	# --- ZUM: skrol misa / trackpad ---
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(ZOOM_STEP)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(-ZOOM_STEP)
			return

	# --- POMERANJE MAPE: prevlacenje misem ---
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_dragging = true
			_drag_last = mb.position
		else:
			_dragging = false
		# NE vracaj - klik mora da stigne i do dugmadi na tackama.

	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		# Deli sa zumom: pomeraj u svetu, ne u pikselima ekrana.
		var d: Vector2 = (mm.position - _drag_last) / _zoom
		if d.length() > 0.5:
			camera.position -= d
			_drag_last = mm.position
			_free_camera = true
		return

	# Na WEBU skrol dolazi kao pan gesture, ne kao WHEEL_UP/DOWN.
	if event is InputEventPanGesture:
		_zoom_by(-event.delta.y * ZOOM_STEP * 0.5)
		return

	# Trackpad pinch na macOS-u.
	if event is InputEventMagnifyGesture:
		_target_zoom = clampf(_target_zoom * event.factor, ZOOM_MIN, ZOOM_MAX)
		return

	# --- ZUM: tasteri + i - ---
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
			_zoom_by(ZOOM_STEP)
			return
		if event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_zoom_by(-ZOOM_STEP)
			return

	# --- ZUM: pinch sa dva prsta ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
			_pinch_start_dist = 0.0
		return

	if event is InputEventScreenDrag:
		var dg := event as InputEventScreenDrag
		# Jedan prst = pomeranje mape. Dva prsta = zum (ispod).
		if _touches.size() <= 1:
			var prev: Vector2 = _touches.get(dg.index, dg.position)
			var d: Vector2 = (dg.position - prev) / _zoom
			if d.length() > 0.5:
				camera.position -= d
				_free_camera = true
			_touches[dg.index] = dg.position
			return

		_touches[dg.index] = dg.position
		if _touches.size() >= 2:
			var keys := _touches.keys()
			var p0: Vector2 = _touches[keys[0]]
			var p1: Vector2 = _touches[keys[1]]
			var d := p0.distance_to(p1)
			if _pinch_start_dist <= 0.0:
				_pinch_start_dist = d
				_pinch_start_zoom = _target_zoom
			elif _pinch_start_dist > 1.0:
				_target_zoom = clampf(
					_pinch_start_zoom * (d / _pinch_start_dist), ZOOM_MIN, ZOOM_MAX)
		return


func _unhandled_input(event: InputEvent) -> void:
	if _entering:
		return

	# --- IZBOR NIVOA ---
	if event.is_action_pressed("move_right"):
		_move_selection(1)
	elif event.is_action_pressed("move_left"):
		_move_selection(-1)
	elif event.is_action_pressed("jump") \
			or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_enter_level()


## Web: kaži shell-u da je mapa aktivna, pa da prikaze kontrole.
##
## API (window.evaCmd, evaZoomIn...) definise SHELL, ne igra.
## create_callback() ne radi ovde - registruje funkciju u window, ali se
## GDScript telo nikad ne izvrsi (potvrdjeno logovanjem). Zato igra samo
## CITA broj iz window.evaCmd svaki frejm.
func _expose_web_api() -> void:
	JavaScriptBridge.eval("window.evaMapActive = 1;", true)


func _exit_tree() -> void:
	# Sakrij kontrole kad izadjemo sa mape (npr. ulazak u nivo).
	if _is_web:
		JavaScriptBridge.eval("window.evaMapActive = 0;", true)


## Procitaj i izvrsi komandu iz JS-a. Zove se iz _process (samo web).
## Jedan eval za sve tri vrednosti - manje prelaza JS<->WASM po frejmu.
func _poll_web_commands() -> void:
	var raw: Variant = JavaScriptBridge.eval("""
		(function () {
			var c = window.evaCmd || 0;
			var x = window.evaPanX || 0;
			var y = window.evaPanY || 0;
			window.evaCmd = 0;
			window.evaPanX = 0;
			window.evaPanY = 0;
			return c + ',' + x.toFixed(2) + ',' + y.toFixed(2);
		})();
	""", true)
	if raw == null:
		return

	var parts := String(raw).split(",")
	if parts.size() < 3:
		return

	match int(parts[0]):
		1: _zoom_by(ZOOM_STEP * 1.6)
		2: _zoom_by(-ZOOM_STEP * 1.6)
		3: _free_camera = false

	var px := float(parts[1])
	var py := float(parts[2])
	if absf(px) > 0.01 or absf(py) > 0.01:
		camera.position -= Vector2(px, py) / _zoom
		_free_camera = true


func _zoom_by(delta_zoom: float) -> void:
	_target_zoom = clampf(_target_zoom + delta_zoom, ZOOM_MIN, ZOOM_MAX)


func _move_selection(step: int) -> void:
	var next := clampi(_selected + step, 0, Game.level_count() - 1)
	if next == _selected:
		return
	_selected = next
	_free_camera = false   # opet prati izbor
	_update_selection()
	Audio.play("checkpoint")


func _update_selection() -> void:
	var data := Game.level_data(_selected)
	var isl := Game.island_of(_selected)
	# Naslov: ime nivoa, pa ostrvo manjim tekstom u info liniji.
	title.text = String(data.get("name", ""))

	if not Game.level_exists(_selected):
		info.text = "Ovaj predeo se pravi..."
	elif not Game.level_unlocked(_selected):
		info.text = "Zavrsi prethodni nivo"
	else:
		var b := Game.best_for(_selected)
		if b.is_empty():
			info.text = "%s  ·  SPACE ili dodir = igraj" % String(isl.get("name", ""))
		else:
			info.text = "Najbolje: %d zvezdica   vreme %d:%02d" % [
				int(b.get("stars", 0)),
				int(b.get("time", 0.0)) / 60,
				int(b.get("time", 0.0)) % 60,
			]


func _enter_level() -> void:
	if _entering:
		return

	if not Game.level_exists(_selected):
		info.text = "Ovaj predeo se pravi..."
		Audio.play("hurt")
		_shake(_dots[_selected])
		return

	if not Game.level_unlocked(_selected):
		info.text = "Zavrsi prethodni nivo"
		Audio.play("hurt")
		_shake(_dots[_selected])
		return

	_entering = true
	Audio.play("star")
	Game.current_level = _selected
	Audio.stop_music()
	get_tree().change_scene_to_file(String(Game.level_data(_selected)["scene"]))


func _shake(node: Node2D) -> void:
	var base := node.position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(node, "position", base + Vector2(8, 0), 0.05)
		tw.tween_property(node, "position", base - Vector2(8, 0), 0.05)
	tw.tween_property(node, "position", base, 0.05)
