extends MinigameBase
## NIVO 7 — "Nađi parove" (Divlja džungla)
##
## Klasican memori: 12 karata = 6 parova plodova dzungle. Dete otvara
## dve karte; ako se poklapaju, ostaju otvorene.
##
## Prilagodjeno petogodisnjaku:
##  - samo 6 parova (ne 8+), u mrezi 4x3
##  - motivi su OBLIKOM razliciti, ne samo bojom (banana je duga, ananas
##    je siljat) - dete koje mesa boje ih ipak razlikuje
##  - pogresan par se vraca posle 0.9s, bez kazne i bez brojanja poteza
##  - nema tajmera koji pritiska
##  - vec pogodjeni par se ne moze ponovo kliknuti
##
## Eva spasava koalu Snenu.

## Koliko parova. 6 parova = 12 karata.
##
## Mreza je 4x3. Merio sam oba oblika sa kvadratnim kartama: 6x2 puni
## sirinu (6 kolona + kolona za kavez ~ ceo viewport), pa sirina postane
## ogranicenje; 4x3 ostavlja vise mesta po x, a kvadratna karta ne trosi
## visinu, tako da karta ispada NAJVECA u 4x3.
const PAIRS := 6
const COLS := 4
const ROWS := 3

## Velicina karte. NAMERNO velika - telefon je primarni klijent, a
## detinji prst je neprecizan.
##
## Mereno kroz nekoliko iteracija (fizicki px na 390px telefonu):
##   128x150 u 4x3  -> 39px  premalo
##   216x250 u 4x3  -> 50px  jos premalo (visina skalira mrezu na 0.76)
##   216x250 u 6x2  -> 51px  bolje, ali karta je previse VISOKA
##   180x180 u 6x2  -> ovde  kvadratna karta ne trosi visinu uzalud
##
## Kvadratna karta je kljuc: motivi su okrugli/kompaktni, pa visina od
## 250px nije nosila sadrzaj - samo je terala _fit_grid da smanji sve.
##   180x180 u 4x3  -> 55px
##   200x200 u 4x3  -> 58px na desktopu, ali samo 46.6px na TELEFONU
##
## Telefonski viewport je samo 620px visok (bazna visina projekta), pa
## 3 reda x 200px ne staju i _fit_grid mora da smanji celu mrezu.
## Resenje: karta je SIROKA a niska. Sirina je ono sto prst pogadja po
## x, a niski redovi staju u 620px bez smanjivanja.
##   220x150 u 4x3  -> ovde
const CARD_W := 220.0
const CARD_H := 150.0
const GAP_X := 20.0
const GAP_Y := 16.0

## Koliko se pogresan par vidi pre nego se vrati.
const PEEK_TIME := 0.9

## Motivi: ime + boja. Oblik crta _draw_motif po imenu.
const MOTIFS: Array[Dictionary] = [
	{"id": "banana", "col": Color(0.98, 0.82, 0.24)},
	{"id": "ananas", "col": Color(0.95, 0.7, 0.2)},
	{"id": "cvet", "col": Color(0.96, 0.38, 0.55)},
	{"id": "list", "col": Color(0.3, 0.68, 0.36)},
	{"id": "kokos", "col": Color(0.55, 0.38, 0.24)},
	{"id": "papagaj", "col": Color(0.35, 0.62, 0.95)},
]

## Karta u igri.
var _cards: Array[Dictionary] = []
## Indeksi trenutno otvorenih karata (0, 1 ili 2 komada).
var _open: Array[int] = []
## Zabrana klika dok se pogresan par vraca.
var _busy := false
var _found := 0
## Mreza je u svom Node2D-u da se moze skalirati kao celina.
var _grid: Node2D


func _setup() -> void:
	friend_kind = "koala"
	biome = "dzungla"
	task_text = "Nađi dva ista! Dodirni kartu."
	set_total_steps(PAIRS)


func _ready() -> void:
	super()
	_grid = Node2D.new()
	add_child(_grid)
	_build_cards()
	_fit_grid()
	get_viewport().size_changed.connect(_fit_grid)


## Klik/dodir se obradjuje OVDE, geometrijski - vidi komentar u _build_cards.
func _input(event: InputEvent) -> void:
	if _busy or _done:
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
	# Mreza je skalirana i pomerena, pa poredi u NJENOM prostoru.
	var local: Vector2 = _grid.to_local(world)
	var half := Vector2(CARD_W, CARD_H) * 0.5

	for i in _cards.size():
		var card: Node2D = _cards[i]["node"]
		var d: Vector2 = local - card.position
		if absf(d.x) <= half.x and absf(d.y) <= half.y:
			_on_card(i)
			get_viewport().set_input_as_handled()
			return


## Uklopi mrezu u ekran.
##
## Karte su namerno velike (dodir prstom), pa je mreza 4x3 visa od
## viewporta. Ovde se skalira da cela stane, uz marginu za naslov
## zadatka gore i HUD dugmad. Skalira se CELA mreza, pa karte ostaju
## proporcionalno najvece sto ekran dozvoljava.
func _fit_grid() -> void:
	if _grid == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return

	var total_w := COLS * CARD_W + (COLS - 1) * GAP_X
	var total_h := ROWS * CARD_H + (ROWS - 1) * GAP_Y

	# Levo se ostavlja KOLONA za kavez sa prijateljem. Bez nje mreza 6x2
	# zauzme punu sirinu i kavez nema gde - meri se da preseca karte.
	const TOP_RESERVE := 84.0
	const SIDE_RESERVE := 20.0
	# Kolona za kavez. Mereno: pri 190px karta padne na 48 fizickih px
	# (pod ciljem 55), pri 130px ostaje 53-56px a kavez i dalje staje.
	const CAGE_COL := 130.0

	var avail_w := vp.x - SIDE_RESERVE * 2.0 - CAGE_COL
	var avail_h := vp.y - TOP_RESERVE - 20.0

	var s := minf(avail_w / total_w, avail_h / total_h)
	# Nikad ne uvecavaj preko 1.0 - karte su vec dimenzionisane za dodir.
	s = minf(s, 1.0)
	_grid.scale = Vector2(s, s)

	# Mreza se pomera DESNO od kavezove kolone, i spusta ispod naslova.
	_grid.position = Vector2(CAGE_COL * 0.5, TOP_RESERVE * 0.5)

	# Kavez ide u svoju kolonu LEVO od mreze, vertikalno centriran.
	# Skala se izvodi iz sirine kolone, pa je kavez uvek najveci sto
	# kolona dozvoljava, a nikad ne preseca karte.
	if _friend != null:
		# Kavez je ~62px poluprecnika pri skali 1.0.
		const CAGE_R := 62.0
		var grid_left: float = _grid.position.x - total_w * 0.5 * s
		var col_w: float = grid_left - (-vp.x * 0.5)
		var fs: float = clampf((col_w - 24.0) * 0.5 / CAGE_R, 0.8, 2.2)
		# Ne sme da bude visi od ekrana ni da udje u naslov.
		fs = minf(fs, (vp.y - TOP_RESERVE - 30.0) * 0.5 / CAGE_R)
		_friend.scale = Vector2(fs, fs)
		_friend.position = Vector2(-vp.x * 0.5 + col_w * 0.5,
			TOP_RESERVE * 0.5)


## Napravi 12 karata: svaki motiv dva puta, pa promesaj.
func _build_cards() -> void:
	# SLUCAJAN raspored pri svakom pokretanju.
	#
	# Prvo je bilo fiksno seme, sa idejom da detetu bude poznato. Ali
	# memori sa istim rasporedom nije memori - dete zapamti gde je sta i
	# drugi put samo ponavlja poteze. Randomizacija vraca igri svrhu, a
	# dugme PONOVO daje novi raspored kad god zeli.
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var deck: Array[int] = []
	for i in PAIRS:
		deck.append(i)
		deck.append(i)

	# Fisher-Yates sa fiksnim semenom.
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := deck[i]
		deck[i] = deck[j]
		deck[j] = t

	# Mreza je centrirana oko (0,0) svog roditelja; _fit_grid() je posle
	# skalira i spusta ispod naslova zadatka.
	var total_w := COLS * CARD_W + (COLS - 1) * GAP_X
	var total_h := ROWS * CARD_H + (ROWS - 1) * GAP_Y
	var origin := Vector2(-total_w * 0.5 + CARD_W * 0.5,
		-total_h * 0.5 + CARD_H * 0.5)

	for i in deck.size():
		var col := i % COLS
		var row := i / COLS
		var pos := origin + Vector2(col * (CARD_W + GAP_X), row * (CARD_H + GAP_Y))

		var card := Node2D.new()
		card.position = pos
		card.z_index = 2
		_grid.add_child(card)

		# Zadnja strana (zatvorena karta) i prednja (motiv) su dva sloja;
		# okretanje samo menja koji je vidljiv.
		var back := Node2D.new()
		card.add_child(back)
		_draw_back(back)

		var front := Node2D.new()
		front.visible = false
		card.add_child(front)
		_draw_front(front, deck[i])

		# Bez klik cvora: _input() nalazi kartu geometrijski.
		#
		# Ni Button ni Area2D ne rade ovde. Button je Control - pozicija
		# mu je u EKRANSKOM prostoru i ne prolazi kroz canvas transform
		# kamere, pa zavrsi van karte. Area2D zavisi od physics object
		# picking-a, koji nije dostavljao input_event (mereno na bojenju:
		# cvorovi ispravni, handler povezan, ali klik nikad ne dodje).

		_cards.append({
			"node": card, "back": back, "front": front,
			"motif": deck[i], "open": false, "done": false,
		})


func _on_card(index: int) -> void:
	if _busy:
		return
	var c := _cards[index]
	if c["done"] or c["open"]:
		return
	# Vise od dve karte se ne otvaraju - drugo otvaranje odmah presudi.
	if _open.size() >= 2:
		return

	_flip_open(index)
	_open.append(index)

	if _open.size() < 2:
		return

	var a := _open[0]
	var b := _open[1]
	if _cards[a]["motif"] == _cards[b]["motif"]:
		_on_match(a, b)
	else:
		_on_miss(a, b)


func _on_match(a: int, b: int) -> void:
	_cards[a]["done"] = true
	_cards[b]["done"] = true
	_open.clear()
	_found += 1
	step_done()

	# Par poskoci i ostane svetao - jasna nagrada.
	for i in [a, b]:
		var n: Node2D = _cards[i]["node"]
		var tw := create_tween()
		tw.tween_property(n, "scale", Vector2(1.18, 1.18), 0.16) \
			.set_trans(Tween.TRANS_BACK)
		tw.tween_property(n, "scale", Vector2.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK)
		_glow(n)

	if _found >= PAIRS:
		await get_tree().create_timer(0.5).timeout
		win()


func _on_miss(a: int, b: int) -> void:
	_busy = true
	Audio.play("land", 0.15)
	await get_tree().create_timer(PEEK_TIME).timeout
	# Ako je nivo u medjuvremenu resen/restartovan, ne diraj karte.
	if not is_inside_tree():
		return
	_flip_closed(a)
	_flip_closed(b)
	_open.clear()
	_busy = false


## Okretanje: karta se "stisne" po x pa se zameni strana.
func _flip_open(index: int) -> void:
	var c := _cards[index]
	c["open"] = true
	var n: Node2D = c["node"]
	Audio.play("star", 0.1)

	var tw := create_tween()
	tw.tween_property(n, "scale:x", 0.05, 0.11).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		(c["back"] as Node2D).visible = false
		(c["front"] as Node2D).visible = true
	)
	tw.tween_property(n, "scale:x", 1.0, 0.13).set_trans(Tween.TRANS_SINE)


func _flip_closed(index: int) -> void:
	var c := _cards[index]
	c["open"] = false
	var n: Node2D = c["node"]

	var tw := create_tween()
	tw.tween_property(n, "scale:x", 0.05, 0.11).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		(c["front"] as Node2D).visible = false
		(c["back"] as Node2D).visible = true
	)
	tw.tween_property(n, "scale:x", 1.0, 0.13).set_trans(Tween.TRANS_SINE)


## Zlatni okvir oko pogodjenog para.
func _glow(card: Node2D) -> void:
	var g := Node2D.new()
	g.z_index = -1
	card.add_child(g)
	_rounded(g, CARD_W * 0.5 + 7.0, CARD_H * 0.5 + 7.0, Color(1, 0.85, 0.3, 0.95))
	_rounded(g, CARD_W * 0.5 + 2.0, CARD_H * 0.5 + 2.0, Color(1, 0.95, 0.6, 0.55))


## --- Crtanje karata ---

## Zadnja strana: tamnozelena sa listom - motiv dzungle.
func _draw_back(parent: Node2D) -> void:
	# Pozadina nivoa je zelena (dzungla), pa zadnja strana NE sme biti
	# zelena - na snimku su se karte stapale sa pozadinom. Toplo drvo
	# sa svetlim obodom se jasno izdvaja.
	_rounded(parent, CARD_W * 0.5, CARD_H * 0.5, Color(0.99, 0.96, 0.88))
	_rounded(parent, CARD_W * 0.5 - 7.0, CARD_H * 0.5 - 7.0, Color(0.55, 0.36, 0.22))
	_rounded(parent, CARD_W * 0.5 - 14.0, CARD_H * 0.5 - 14.0, Color(0.67, 0.45, 0.27))

	# Sara: listovi jedan pod drugim. Skalirano po MANJOJ dimenziji
	# karte (karta je siroka a niska) da sara ne prelije ivice.
	var holder := Node2D.new()
	holder.scale = Vector2.ONE * (minf(CARD_W, CARD_H) / 128.0)
	parent.add_child(holder)

	for i in 3:
		var y := -30.0 + i * 30.0
		Draw2D.poly(holder, Color(0.28, 0.58, 0.33, 0.95), [
			Vector2(-30, y), Vector2(0, y - 15),
			Vector2(30, y), Vector2(0, y + 15)])
		Draw2D.poly(holder, Color(0.17, 0.4, 0.23, 0.95), [
			Vector2(-28, y), Vector2(28, y),
			Vector2(28, y + 2), Vector2(-28, y + 2)])


## Prednja strana: svetao karton sa motivom u sredini.
func _draw_front(parent: Node2D, motif: int) -> void:
	_rounded(parent, CARD_W * 0.5, CARD_H * 0.5, Color(0.85, 0.78, 0.62))
	_rounded(parent, CARD_W * 0.5 - 7.0, CARD_H * 0.5 - 7.0, Color(1, 0.98, 0.92))

	# Motivi su crtani u kvadratu ~128px. Skaliraj po MANJOJ dimenziji
	# karte - karta je siroka a niska, pa bi skaliranje po sirini
	# prelilo motiv van gornje i donje ivice.
	var holder := Node2D.new()
	holder.scale = Vector2.ONE * (minf(CARD_W, CARD_H) / 128.0) * 0.9
	parent.add_child(holder)
	_draw_motif(holder, String(MOTIFS[motif]["id"]), MOTIFS[motif]["col"])


## Motivi su razliciti OBLIKOM, ne samo bojom - dete koje mesa boje
## ih ipak razlikuje.
func _draw_motif(p: Node2D, id: String, col: Color) -> void:
	match id:
		"banana":
			# Dug savijen luk. Debljina je MERENA sa snimka: na 15px
			# razlike izmedju spoljnog i unutrasnjeg luka izgledala je
			# kao zuta linija, pa je sada 26px - puna, mesnata banana.
			var pts := PackedVector2Array()
			for i in 14:
				var t := float(i) / 13.0
				var a := lerpf(-2.5, -0.64, t)
				pts.append(Vector2(cos(a) * 46.0, sin(a) * 40.0) + Vector2(0, 26))
			for i in range(13, -1, -1):
				var t := float(i) / 13.0
				var a := lerpf(-2.5, -0.64, t)
				pts.append(Vector2(cos(a) * 30.0, sin(a) * 14.0) + Vector2(0, 26))
			var poly := Polygon2D.new()
			poly.color = col
			poly.polygon = pts
			p.add_child(poly)
			# Svetliji odsjaj po duzini - daje zapreminu.
			var hl := PackedVector2Array()
			for i in 10:
				var t := float(i) / 9.0
				var a := lerpf(-2.3, -0.8, t)
				hl.append(Vector2(cos(a) * 42.0, sin(a) * 36.0) + Vector2(0, 26))
			for i in range(9, -1, -1):
				var t := float(i) / 9.0
				var a := lerpf(-2.3, -0.8, t)
				hl.append(Vector2(cos(a) * 37.0, sin(a) * 29.0) + Vector2(0, 26))
			var hp := Polygon2D.new()
			hp.color = Color(1, 0.93, 0.55, 0.8)
			hp.polygon = hl
			p.add_child(hp)
			# Peteljka i vrh - tamnije, kao na pravoj banani.
			_circle(p, Vector2(-37, 6), 7.0, Color(0.42, 0.32, 0.13))
			_circle(p, Vector2(37, 6), 6.0, Color(0.35, 0.26, 0.1))

		"ananas":
			# Siljat: telo sa krunom listova gore.
			Draw2D.poly(p, col, [
				Vector2(-24, 6), Vector2(-18, -20), Vector2(18, -20),
				Vector2(24, 6), Vector2(18, 34), Vector2(-18, 34)])
			# Kockasta sara.
			for r in 4:
				for c in 3:
					Draw2D.poly(p, Color(0.78, 0.52, 0.12, 0.7), [
						Vector2(-14 + c * 12, -14 + r * 12),
						Vector2(-8 + c * 12, -14 + r * 12),
						Vector2(-8 + c * 12, -8 + r * 12),
						Vector2(-14 + c * 12, -8 + r * 12)])
			# Kruna.
			for i in 5:
				var x := -16.0 + i * 8.0
				Draw2D.poly(p, Color(0.24, 0.56, 0.28), [
					Vector2(x, -20), Vector2(x + 3, -46), Vector2(x + 6, -20)])

		"cvet":
			# Pet okruglih latica - mek, okrugao oblik.
			for i in 5:
				var a := TAU * float(i) / 5.0 - PI * 0.5
				_circle(p, Vector2(cos(a), sin(a)) * 22.0, 16.0, col)
			_circle(p, Vector2.ZERO, 13.0, Color(1, 0.9, 0.4))
			_circle(p, Vector2.ZERO, 7.0, Color(0.95, 0.72, 0.2))

		"list":
			# Siljat list sa nervima - jedini sa "vrhom" gore i dole.
			Draw2D.poly(p, col, [
				Vector2(0, -42), Vector2(24, -6), Vector2(14, 30),
				Vector2(0, 40), Vector2(-14, 30), Vector2(-24, -6)])
			Draw2D.poly(p, Color(0.18, 0.46, 0.24), [
				Vector2(-2, -38), Vector2(2, -38), Vector2(2, 38), Vector2(-2, 38)])
			for i in 4:
				var y := -24.0 + i * 16.0
				Draw2D.poly(p, Color(0.2, 0.5, 0.26, 0.8), [
					Vector2(0, y), Vector2(17, y + 9),
					Vector2(17, y + 12), Vector2(0, y + 4)])
				Draw2D.poly(p, Color(0.2, 0.5, 0.26, 0.8), [
					Vector2(0, y), Vector2(-17, y + 9),
					Vector2(-17, y + 12), Vector2(0, y + 4)])

		"kokos":
			# Okrugao, tamnobraon, sa tri "oka" - kao pravi kokos.
			_circle(p, Vector2(0, 4), 32.0, Color(0.4, 0.27, 0.16))
			_circle(p, Vector2(0, 4), 27.0, col)
			# Dlakava tekstura.
			for i in 14:
				var a := TAU * float(i) / 14.0
				var d := Vector2(cos(a), sin(a))
				Draw2D.poly(p, Color(0.44, 0.3, 0.18, 0.6), [
					Vector2(0, 4) + d * 14.0, Vector2(0, 4) + d * 27.0,
					Vector2(0, 4) + d.rotated(0.18) * 25.0])
			for i in 3:
				var a2 := TAU * float(i) / 3.0 - PI * 0.5
				_circle(p, Vector2(0, 4) + Vector2(cos(a2), sin(a2)) * 11.0,
					5.0, Color(0.28, 0.18, 0.1))

		"papagaj":
			# Ptica: telo, krilo, kljun, repno perje - najsloženiji oblik.
			_circle(p, Vector2(-2, 6), 24.0, col)
			# Rep - dugo perje ukoso.
			Draw2D.poly(p, Color(0.9, 0.35, 0.35), [
				Vector2(14, 14), Vector2(44, 36), Vector2(30, 40), Vector2(10, 24)])
			Draw2D.poly(p, Color(0.98, 0.75, 0.25), [
				Vector2(12, 20), Vector2(38, 42), Vector2(24, 44), Vector2(8, 28)])
			# Krilo.
			Draw2D.poly(p, Color(0.22, 0.48, 0.8), [
				Vector2(-8, -2), Vector2(14, 6), Vector2(6, 22), Vector2(-10, 14)])
			# Glava i kljun.
			_circle(p, Vector2(-10, -18), 15.0, col)
			Draw2D.poly(p, Color(0.98, 0.72, 0.2), [
				Vector2(-22, -18), Vector2(-36, -12), Vector2(-22, -6)])
			# Oko.
			_circle(p, Vector2(-8, -22), 5.0, Color(1, 1, 1))
			_circle(p, Vector2(-9, -22), 3.0, Color(0.1, 0.1, 0.12))
			# Cuperak.
			Draw2D.poly(p, Color(0.98, 0.75, 0.25), [
				Vector2(-12, -32), Vector2(-6, -46), Vector2(-2, -30)])


## Pravougaonik sa zaobljenim uglovima - karta ne treba da ima ostre uglove.
func _rounded(parent: Node2D, hw: float, hh: float, col: Color) -> void:
	const R := 12.0
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

## Krug sa 16 segmenata - ovaj fajl crta glatkije oblike
## od podrazumevanih 14 u Draw2D.
func _circle(parent: Node, center: Vector2, r: float,
		col: Color) -> Polygon2D:
	return Draw2D.circle(parent, center, r, col, 16)
