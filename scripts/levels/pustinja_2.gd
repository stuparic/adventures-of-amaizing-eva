extends MinigameBase
## NIVO 9 — "Obuci Budžumboru" (Vruća pustinja)
##
## Dete oblaci lutku: bira haljinu, cipele i sesir sa police i dodiruje
## lutku da ih obuce. Kad ima sva tri dela, sova Mudra je slobodna.
##
## Za petogodisnjaka:
##  - NEMA pogresnog izbora: svaka haljina/cipela/sesir se prima
##  - tri kategorije jasno razdvojene, svaka u svom redu
##  - izabrani predmet se odmah vidi NA lutki, ne u nekakvom inventaru
##  - moze da menja koliko puta zeli; nivo se resava kad ima sva tri dela
##
## Zato je zadatak "obuci", ne "obuci tacno" - ovo je igra oblacenja,
## ne test.

## Kategorije i ponude. Boje su iz Budzumborine palete (sa slike lutke),
## pa sve sto dete izabere izgleda kao da pripada njoj.
const OUTFITS := {
	"haljina": [
		{"id": "roze", "col": Color(0.96, 0.28, 0.58)},
		{"id": "zlatna", "col": Color(1, 0.78, 0.28)},
		{"id": "plava", "col": Color(0.4, 0.68, 0.95)},
		{"id": "zelena", "col": Color(0.42, 0.78, 0.5)},
	],
	"cipele": [
		{"id": "crvene", "col": Color(0.82, 0.2, 0.3)},
		{"id": "bele", "col": Color(0.98, 0.97, 0.95)},
		{"id": "ljubicaste", "col": Color(0.72, 0.45, 0.9)},
	],
	"sesir": [
		{"id": "sunce", "col": Color(1, 0.84, 0.42)},
		{"id": "mašna", "col": Color(0.98, 0.5, 0.72)},
		{"id": "cvet", "col": Color(0.6, 0.82, 0.55)},
	],
}

## Red kategorija na ekranu (odozgo nadole).
const ROWS: Array[String] = ["haljina", "cipele", "sesir"]

## Velicina ponude na polici. Veliko - telefon je primarni klijent.
##
## Mereno: pri 150px kartica je 45.7 fizickih px na telefonu (ispod cilja
## od 55px za detinji prst). Prostora je bilo - polica je isla do x=567
## pri ekranu do 640. Na 190px je oko 58px.
const ITEM_W := 190.0
const ITEM_H := 160.0
const ITEM_GAP := 16.0

## Sta je dete izabralo: kategorija -> indeks u OUTFITS, ili -1.
var _chosen := {"haljina": -1, "cipele": -1, "sesir": -1}
## Cvorovi ponude: kategorija -> Array[Node2D]
var _items := {}
## Lutka i njeni delovi koji se menjaju.
var _doll: Node2D
var _doll_dress: Node2D
var _doll_shoes: Node2D
var _doll_hat: Node2D
## Cela scena je u ovom cvoru da se moze skalirati na mali ekran.
var _stage: Node2D
var _shelf: Node2D


func _setup() -> void:
	friend_kind = "sova"
	biome = "pustinja"
	task_text = "Obuci Budžumboru! Dodirni šta ti se sviđa."
	# Tri koraka: haljina, cipele, sesir.
	set_total_steps(3)


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)

	_build_doll()
	_build_shelf()
	_fit_stage()
	get_viewport().size_changed.connect(_fit_stage)


## Klik/dodir se obradjuje geometrijski, u prostoru _stage.
##
## Ni Button ni Area2D ne rade pouzdano: Button je Control i njegova
## pozicija je u EKRANSKOM prostoru (ne prolazi kroz canvas transform),
## a Area2D zavisi od physics pickinga koji nije dostavljao input_event.
## Isti nalaz kao u bojenju, memoriju i spoji-tacke.
func _input(event: InputEvent) -> void:
	if _done:
		return

	var pos := Vector2.ZERO
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		pos = mb.position
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			return
		pos = st.position
	else:
		return

	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * pos
	var local: Vector2 = _stage.to_local(world)
	var half := Vector2(ITEM_W, ITEM_H) * 0.5

	for cat in ROWS:
		var arr: Array = _items[cat]
		for i in arr.size():
			var n: Node2D = arr[i]
			var d: Vector2 = local - n.position
			if absf(d.x) <= half.x and absf(d.y) <= half.y:
				_pick(String(cat), i)
				get_viewport().set_input_as_handled()
				return


## Dete je izabralo predmet.
func _pick(cat: String, index: int) -> void:
	var was_new: bool = int(_chosen[cat]) < 0
	_chosen[cat] = index

	# Predmet poskoci - potvrda da je dodir primljen.
	var n: Node2D = (_items[cat] as Array)[index]
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(1.18, 1.18), 0.11).set_trans(Tween.TRANS_BACK)
	tw.tween_property(n, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

	_refresh_highlight(cat)
	_dress_doll(cat)

	if was_new:
		step_done()
	else:
		# Promena vec izabranog - zvuk, ali ne racuna se kao nov korak.
		Audio.play("star", 0.12)

	# Sva tri dela? Gotovo.
	for c in ROWS:
		if int(_chosen[c]) < 0:
			return
	await get_tree().create_timer(0.5).timeout
	_celebrate_doll()
	win()


## Izabrani predmet dobija zlatni okvir, ostali ga gube.
func _refresh_highlight(cat: String) -> void:
	var arr: Array = _items[cat]
	for i in arr.size():
		var n: Node2D = arr[i]
		var ring: Node2D = n.get_node_or_null("Ring")
		if ring != null:
			ring.visible = i == int(_chosen[cat])


## --- LUTKA ---

## Budzumbora, nacrtana ovde (ne iz scenes/budzumbora.tscn).
##
## Namerno odvojeno: mini-igra menja haljinu, cipele i sesir, pa bi
## diranje zajednicke scene pokvarilo lika u svim ostalim nivoima.
func _build_doll() -> void:
	_doll = Node2D.new()
	_doll.position = Vector2(-430, 40)
	_stage.add_child(_doll)

	var skin := Color(0.99, 0.86, 0.78)
	var hair := Color(1, 0.55, 0.16)

	# Stalak - lutka stoji na njemu.
	_poly(_doll, Color(0.62, 0.45, 0.3), [
		Vector2(-56, 190), Vector2(56, 190), Vector2(44, 205), Vector2(-44, 205)])
	_poly(_doll, Color(0.74, 0.56, 0.38), [
		Vector2(-52, 186), Vector2(52, 186), Vector2(52, 191), Vector2(-52, 191)])

	# Noge - pocinju na y=56 da se SPOJE sa trupom (koji ide do y=60).
	# Na snimku su visile odvojeno jer su pocinjale na y=96.
	for sx in [-1.0, 1.0]:
		_poly(_doll, skin, [
			Vector2(sx * 26 - 12, 56), Vector2(sx * 26 + 12, 56),
			Vector2(sx * 26 + 9, 176), Vector2(sx * 26 - 9, 176)])

	# CIPELE - menjaju se (prazan cvor koji se puni pri izboru).
	_doll_shoes = Node2D.new()
	_doll_shoes.z_index = 2
	_doll.add_child(_doll_shoes)

	# Trup - bez njega lutka izgleda kao ruke i noge bez tela (video na
	# snimku dok je bila gola).
	_poly(_doll, skin, [
		Vector2(-30, -52), Vector2(30, -52),
		Vector2(34, 60), Vector2(-34, 60)])
	_circle(_doll, Vector2(0, -50), 30.0, skin)

	# HALJINA - menja se, ide preko trupa.
	_doll_dress = Node2D.new()
	_doll_dress.z_index = 1
	_doll.add_child(_doll_dress)

	# Ruke - pocinju na trupu (x = +-26, trup je sirok do +-34), ne u
	# vazduhu pored njega.
	for sx in [-1.0, 1.0]:
		_poly(_doll, skin, [
			Vector2(sx * 26, -40), Vector2(sx * 40, -34),
			Vector2(sx * 50, 44), Vector2(sx * 36, 48)])
		_circle(_doll, Vector2(sx * 43, 48), 11.0, skin)

	# --- Glava. Red crtanja je bitan: kosa IZA, pa glava, pa kosa GORE ---
	#
	# Na prvom snimku je kosa pokrivala celo lice, jer je crtana posle
	# glave i bila preduga. Sada: repovi iza glave, glava preko njih, pa
	# samo kapa i siske na vrh - lice (oci na y=-106) ostaje slobodno.

	# 1) Repovi kose - iza glave, sa strane, do ramena.
	for sx in [-1.0, 1.0]:
		_poly(_doll, hair, [
			Vector2(sx * 34, -132), Vector2(sx * 50, -120),
			Vector2(sx * 48, -44), Vector2(sx * 32, -40),
			Vector2(sx * 28, -114)])

	# 2) Vrat i glava - preko repova.
	_poly(_doll, skin, [
		Vector2(-12, -66), Vector2(12, -66), Vector2(12, -40), Vector2(-12, -40)])
	_circle(_doll, Vector2(0, -104), 46.0, skin)

	# 3) Kapa kose - samo gornji deo glave, iznad ociju.
	_poly(_doll, hair, [
		Vector2(-45, -114), Vector2(-36, -140), Vector2(0, -152),
		Vector2(36, -140), Vector2(45, -114),
		Vector2(26, -128), Vector2(0, -134), Vector2(-26, -128)])
	# Siske - kratke, ka spolja, ne preko ociju.
	for sx in [-1.0, 1.0]:
		_poly(_doll, hair, [
			Vector2(sx * 10, -142), Vector2(sx * 40, -128),
			Vector2(sx * 38, -116), Vector2(sx * 14, -128)])

	# Lice: oci, rumen, osmeh.
	for sx in [-1.0, 1.0]:
		_circle(_doll, Vector2(sx * 16, -106), 8.0, Color(1, 1, 1))
		_circle(_doll, Vector2(sx * 16, -106), 5.0, Color(0.16, 0.36, 0.6))
		_circle(_doll, Vector2(sx * 14, -108), 2.0, Color(1, 1, 1))
		_circle(_doll, Vector2(sx * 30, -94), 7.0, Color(1, 0.72, 0.75, 0.7))
	# Osmeh - blagi luk.
	var smile := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		var a := lerpf(PI * 0.18, PI * 0.82, t)
		smile.append(Vector2(cos(a) * -19.0, -84.0 + sin(a) * 11.0))
	for i in range(8, -1, -1):
		var t := float(i) / 8.0
		var a := lerpf(PI * 0.18, PI * 0.82, t)
		smile.append(Vector2(cos(a) * -19.0, -87.0 + sin(a) * 11.0))
	var sm := Polygon2D.new()
	sm.color = Color(0.72, 0.16, 0.2)
	sm.polygon = smile
	_doll.add_child(sm)

	# SESIR - menja se.
	_doll_hat = Node2D.new()
	_doll_hat.z_index = 3
	_doll.add_child(_doll_hat)


## Obuci izabrani deo na lutku.
func _dress_doll(cat: String) -> void:
	var idx: int = int(_chosen[cat])
	if idx < 0:
		return
	var col: Color = (OUTFITS[cat] as Array)[idx]["col"]

	match cat:
		"haljina":
			_clear(_doll_dress)
			# Telo haljine - trapez od ramena do kolena.
			_poly(_doll_dress, col.darkened(0.18), [
				Vector2(-34, -44), Vector2(34, -44),
				Vector2(56, 104), Vector2(-56, 104)])
			_poly(_doll_dress, col, [
				Vector2(-31, -42), Vector2(31, -42),
				Vector2(50, 98), Vector2(-50, 98)])
			# Rub - svetliji.
			_poly(_doll_dress, col.lightened(0.3), [
				Vector2(-50, 90), Vector2(50, 90),
				Vector2(52, 100), Vector2(-52, 100)])
			# Bretele.
			for sx in [-1.0, 1.0]:
				_poly(_doll_dress, col, [
					Vector2(sx * 12, -58), Vector2(sx * 26, -50),
					Vector2(sx * 30, -40), Vector2(sx * 16, -46)])
			# Dva dugmeta.
			_circle(_doll_dress, Vector2(0, -20), 5.0, Color(1, 1, 1, 0.9))
			_circle(_doll_dress, Vector2(0, 4), 5.0, Color(1, 1, 1, 0.9))
			_pop(_doll_dress)

		"cipele":
			_clear(_doll_shoes)
			for sx in [-1.0, 1.0]:
				_poly(_doll_shoes, col.darkened(0.25), [
					Vector2(sx * 26 - 15, 168), Vector2(sx * 26 + 15, 168),
					Vector2(sx * 26 + 17, 182), Vector2(sx * 26 - 17, 182)])
				_poly(_doll_shoes, col, [
					Vector2(sx * 26 - 14, 166), Vector2(sx * 26 + 14, 166),
					Vector2(sx * 26 + 15, 177), Vector2(sx * 26 - 15, 177)])
				# Sjaj.
				_poly(_doll_shoes, Color(1, 1, 1, 0.45), [
					Vector2(sx * 26 - 9, 168), Vector2(sx * 26 - 1, 168),
					Vector2(sx * 26 - 3, 172), Vector2(sx * 26 - 10, 172)])
			_pop(_doll_shoes)

		"sesir":
			_clear(_doll_hat)
			var id: String = String((OUTFITS[cat] as Array)[idx]["id"])
			if id == "sunce":
				# Sesir sa sirokim obodom - pustinjski.
				_poly(_doll_hat, col.darkened(0.2), [
					Vector2(-74, -136), Vector2(74, -136),
					Vector2(66, -126), Vector2(-66, -126)])
				_poly(_doll_hat, col, [
					Vector2(-70, -140), Vector2(70, -140),
					Vector2(62, -130), Vector2(-62, -130)])
				_poly(_doll_hat, col, [
					Vector2(-32, -140), Vector2(32, -140),
					Vector2(24, -178), Vector2(-24, -178)])
				_poly(_doll_hat, col.darkened(0.15), [
					Vector2(-33, -148), Vector2(33, -148),
					Vector2(33, -142), Vector2(-33, -142)])
			elif id == "mašna":
				# Velika masna na glavi.
				for sx in [-1.0, 1.0]:
					_poly(_doll_hat, col, [
						Vector2(0, -146), Vector2(sx * 40, -166),
						Vector2(sx * 44, -140), Vector2(sx * 12, -136)])
					_poly(_doll_hat, col.lightened(0.25), [
						Vector2(0, -146), Vector2(sx * 30, -158),
						Vector2(sx * 32, -146)])
				_circle(_doll_hat, Vector2(0, -146), 11.0, col.darkened(0.15))
			else:
				# Cvet u kosi.
				for k in 6:
					var a := TAU * float(k) / 6.0
					_circle(_doll_hat, Vector2(-30, -142) + Vector2(cos(a), sin(a)) * 13.0,
						10.0, col)
				_circle(_doll_hat, Vector2(-30, -142), 8.0, Color(1, 0.92, 0.45))
				# Listic.
				_poly(_doll_hat, Color(0.34, 0.62, 0.36), [
					Vector2(-30, -128), Vector2(-16, -122), Vector2(-30, -118)])
			_pop(_doll_hat)


## Novi deo "sleti" na lutku - dete vidi da se nesto promenilo.
func _pop(n: Node2D) -> void:
	n.scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)
	Audio.play("checkpoint", 0.1)


## Lutka se okrene i poskoci kad je obucena.
func _celebrate_doll() -> void:
	var tw := create_tween()
	tw.tween_property(_doll, "position:y", 10.0, 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_doll, "position:y", 40.0, 0.26) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.set_loops(3)


## --- POLICA SA PONUDOM ---

func _build_shelf() -> void:
	_shelf = Node2D.new()
	_stage.add_child(_shelf)

	for r in ROWS.size():
		var cat: String = ROWS[r]
		var arr: Array = OUTFITS[cat]
		_items[cat] = []

		var row_w := arr.size() * ITEM_W + (arr.size() - 1) * ITEM_GAP
		var y := -170.0 + r * (ITEM_H + 30.0)
		# Ponuda je desno od lutke. Redovi se poravnavaju LEVO (isti x0
		# za sve), pa najsiri red odredjuje desnu ivicu - tako _fit_stage
		# racuna sirinu tacno i nista ne izlazi van ekrana.
		# (Na snimku je zadnja kolona haljina bila odsecena jer su redovi
		#  bili centrirani, pa je najsiri red isao dalje desno od racuna.)
		var x0 := -110.0 + ITEM_W * 0.5

		for i in arr.size():
			var n := Node2D.new()
			n.position = Vector2(x0 + i * (ITEM_W + ITEM_GAP), y)
			_shelf.add_child(n)
			(_items[cat] as Array).append(n)

			# Zlatni okvir - vidljiv samo kad je izabrano.
			var ring := Node2D.new()
			ring.name = "Ring"
			ring.visible = false
			ring.z_index = -1
			n.add_child(ring)
			_rounded(ring, ITEM_W * 0.5 + 8.0, ITEM_H * 0.5 + 8.0,
				Color(1, 0.85, 0.3))
			_rounded(ring, ITEM_W * 0.5 + 3.0, ITEM_H * 0.5 + 3.0,
				Color(1, 0.95, 0.6, 0.5))

			# Kartica.
			_rounded(n, ITEM_W * 0.5, ITEM_H * 0.5, Color(0.86, 0.72, 0.52))
			_rounded(n, ITEM_W * 0.5 - 6.0, ITEM_H * 0.5 - 6.0, Color(1, 0.98, 0.93))

			# Ikonica predmeta.
			var col: Color = arr[i]["col"]
			var id: String = String(arr[i]["id"])
			_draw_icon(n, cat, id, col)


## Ikonica na kartici - mora da se prepozna bez citanja.
func _draw_icon(p: Node2D, cat: String, id: String, col: Color) -> void:
	match cat:
		"haljina":
			_poly(p, col.darkened(0.2), [
				Vector2(-22, -40), Vector2(22, -40),
				Vector2(40, 44), Vector2(-40, 44)])
			_poly(p, col, [
				Vector2(-19, -37), Vector2(19, -37),
				Vector2(35, 40), Vector2(-35, 40)])
			for sx in [-1.0, 1.0]:
				_poly(p, col, [
					Vector2(sx * 7, -50), Vector2(sx * 17, -44),
					Vector2(sx * 20, -36), Vector2(sx * 10, -40)])
			_circle(p, Vector2(0, -14), 4.0, Color(1, 1, 1, 0.9))
			_circle(p, Vector2(0, 4), 4.0, Color(1, 1, 1, 0.9))

		"cipele":
			for sx in [-1.0, 1.0]:
				_poly(p, col.darkened(0.25), [
					Vector2(sx * 24 - 20, 6), Vector2(sx * 24 + 20, 6),
					Vector2(sx * 24 + 22, 26), Vector2(sx * 24 - 22, 26)])
				_poly(p, col, [
					Vector2(sx * 24 - 18, 2), Vector2(sx * 24 + 18, 2),
					Vector2(sx * 24 + 19, 18), Vector2(sx * 24 - 19, 18)])
				_poly(p, Color(1, 1, 1, 0.45), [
					Vector2(sx * 24 - 12, 5), Vector2(sx * 24 - 2, 5),
					Vector2(sx * 24 - 5, 11), Vector2(sx * 24 - 13, 11)])

		"sesir":
			if id == "sunce":
				_poly(p, col.darkened(0.2), [
					Vector2(-46, 12), Vector2(46, 12),
					Vector2(40, 24), Vector2(-40, 24)])
				_poly(p, col, [
					Vector2(-44, 8), Vector2(44, 8),
					Vector2(38, 20), Vector2(-38, 20)])
				_poly(p, col, [
					Vector2(-20, 8), Vector2(20, 8),
					Vector2(14, -34), Vector2(-14, -34)])
				_poly(p, col.darkened(0.15), [
					Vector2(-21, -2), Vector2(21, -2),
					Vector2(21, 4), Vector2(-21, 4)])
			elif id == "mašna":
				for sx in [-1.0, 1.0]:
					_poly(p, col, [
						Vector2(0, 0), Vector2(sx * 38, -22),
						Vector2(sx * 42, 12), Vector2(sx * 11, 9)])
					_poly(p, col.lightened(0.25), [
						Vector2(0, 0), Vector2(sx * 28, -13),
						Vector2(sx * 30, 0)])
				_circle(p, Vector2(0, 0), 11.0, col.darkened(0.15))
			else:
				for k in 6:
					var a := TAU * float(k) / 6.0
					_circle(p, Vector2(cos(a), sin(a)) * 20.0, 15.0, col)
				_circle(p, Vector2.ZERO, 12.0, Color(1, 0.92, 0.45))
				_poly(p, Color(0.34, 0.62, 0.36), [
					Vector2(0, 22), Vector2(18, 34), Vector2(0, 34)])


## Uklopi scenu u ekran.
##
## Lutka + tri reda ponude su siroki; na telefonu (viewport 620px visok)
## sve mora da se smanji da stane. Skalira se cela scena, pa odnosi
## ostaju isti.
func _fit_stage() -> void:
	if _stage == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return

	# Sirina se meri iz STVARNIH pozicija karata, ne iz pretpostavljenih
	# konstanti - dva puta sam pogresio racunajuci je "u glavi" i zadnja
	# kolona je ispadala van ekrana.
	var left := -520.0        # leva ivica lutke: -430 (pozicija) - 90
	var right := -1e9
	for cat in ROWS:
		for n in (_items[cat] as Array):
			var nn := n as Node2D
			left = minf(left, nn.position.x - ITEM_W * 0.5)
			right = maxf(right, nn.position.x + ITEM_W * 0.5)
	var total_w: float = (right - left) + 40.0
	var total_h := ROWS.size() * ITEM_H + (ROWS.size() - 1) * 30.0 + 60.0

	const TOP_RESERVE := 84.0
	var s := minf((vp.x - 40.0) / total_w, (vp.y - TOP_RESERVE - 20.0) / total_h)
	s = minf(s, 1.0)
	_stage.scale = Vector2(s, s)

	# Centriraj: sadrzaj ide od `left` do `right`, pa se njegov centar
	# pomera na sredinu ekrana. Bez ovoga scena staje po sirini ali visi
	# na jednu stranu.
	var content_mid: float = (left + right) * 0.5
	_stage.position = Vector2(-content_mid * s, TOP_RESERVE * 0.4)

	# Kavez sa sovom ide gore-levo, iznad lutke.
	if _friend != null:
		const CAGE_R := 62.0
		var fs: float = clampf((vp.y * 0.5 - TOP_RESERVE) / (CAGE_R * 2.2), 0.8, 1.6)
		_friend.scale = Vector2(fs, fs)
		_friend.position = Vector2(-vp.x * 0.5 + CAGE_R * fs + 20.0,
			-vp.y * 0.5 + TOP_RESERVE + CAGE_R * fs * 0.6)


## --- Helperi ---

func _clear(n: Node2D) -> void:
	for c in n.get_children():
		c.queue_free()


func _rounded(parent: Node2D, hw: float, hh: float, col: Color) -> void:
	const R := 14.0
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(hw - R, hh - R), 0.0],
		[Vector2(-hw + R, hh - R), PI * 0.5],
		[Vector2(-hw + R, -hh + R), PI],
		[Vector2(hw - R, -hh + R), PI * 1.5],
	]
	for c in corners:
		var center: Vector2 = c[0]
		var start: float = c[1]
		for i in 5:
			var a: float = start + PI * 0.5 * float(i) / 4.0
			pts.append(center + Vector2(cos(a), sin(a)) * R)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)


func _circle(parent: Node2D, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)


func _poly(parent: Node2D, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)
