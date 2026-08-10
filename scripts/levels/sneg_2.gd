extends MinigameBase
## NIVO 11 — "Prebroj pahulje" (Snežna dolina)
##
## Na ekranu je grupa pahulja. Dete ih prebroji i dodirne pravi broj.
## Pet zadataka, svaki sa vise pahulja od prethodnog.
##
## Prilagodjeno petogodisnjaku:
##  - brojevi idu do 5, ne dalje (koliko dete sigurno prepoznaje)
##  - pahulje su u JASNOM redu, ne razbacane - lakse za brojanje
##  - dodir na pahulju je BROJI naglas (ona poskoci i pobeli) - dete
##    moze da broji prstom, kao na papiru
##  - pogresan odgovor se samo zatrese, bez kazne i bez gubljenja srca
##  - tacan odgovor pokazuje zeleni znak i ide na sledeci zadatak
##
## Eva spasava ježa Bodljka.

## Koliko pahulja u kom zadatku. Raste, ali ne preko 5.
const TASKS: Array[int] = [2, 3, 5, 4, 5]

## Ponudjeni brojevi - uvek 1..5, pa dete uci da bira, ne da pogadja.
##
## Mereno: sa 6 dugmadi je dugme padalo na 40.2 fizickih px na telefonu
## (cilj je 55px za detinji prst). Sa 5 ima mesta za 190px = ~58px.
## Petogodisnjak ionako sigurnije prepoznaje do 5.
const CHOICES: Array[int] = [1, 2, 3, 4, 5]

## Velicina dugmeta sa brojem. Veliko - telefon je primarni klijent.
##
## Mereno: 170px sa GAP 18 daje 51.8 fizickih px (cilj 55). Suzavanjem
## razmaka na 10 i sirenjem dugmeta na 190px ostaje ukupno 990px u
## viewportu od 1280, pa skala ostaje 1.0 a dugme ide na ~58px.
const BTN_SIZE := 190.0
const BTN_GAP := 10.0

## Pahulje se crtaju u redu; ovo je razmak izmedju njih.
const FLAKE_STEP := 118.0
const FLAKE_R := 40.0

var _task := 0
var _flakes: Array[Node2D] = []
var _buttons: Array[Node2D] = []
var _stage: Node2D
var _flake_holder: Node2D
var _busy := false
## Koje je pahulje dete "prebrojalo" prstom - samo vizualna pomoc.
var _counted: Array[bool] = []


func _setup() -> void:
	friend_kind = "jez"
	biome = "sneg"
	task_text = "Koliko je pahulja? Dodirni broj."
	set_total_steps(TASKS.size())


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)
	_flake_holder = Node2D.new()
	_stage.add_child(_flake_holder)

	_build_buttons()
	_show_task()
	_fit_stage()
	get_viewport().size_changed.connect(_fit_stage)


## Klik/dodir geometrijski - vidi komentar u ostalim mini-igrama:
## Button je Control (ekranski prostor), Area2D zavisi od physics pickinga.
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
	var local: Vector2 = _stage.to_local(world)

	# Prvo brojevi.
	var half := BTN_SIZE * 0.5
	for i in _buttons.size():
		var d: Vector2 = local - _buttons[i].position
		if absf(d.x) <= half and absf(d.y) <= half:
			_answer(CHOICES[i])
			get_viewport().set_input_as_handled()
			return

	# Pa pahulje - dodir ih "prebroji" (pomoc, ne obaveza).
	for i in _flakes.size():
		if local.distance_to(_flakes[i].position) <= FLAKE_R + 10.0:
			_count_flake(i)
			get_viewport().set_input_as_handled()
			return


## Dete dodirne pahulju - ona pobeli i poskoci, kao da je prebrojana.
##
## Ovo je pomoc za brojanje prstom, kao na papiru. Ne utice na resenje:
## dete moze da odgovori i bez dodirivanja pahulja.
func _count_flake(index: int) -> void:
	if _counted[index]:
		return
	_counted[index] = true
	var f := _flakes[index]
	Audio.play("star", 0.15)

	var tw := create_tween()
	tw.tween_property(f, "scale", Vector2(1.3, 1.3), 0.13).set_trans(Tween.TRANS_BACK)
	tw.tween_property(f, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	# Prebrojana pahulja dobija zlatni sjaj.
	for c in f.get_children():
		if c is Polygon2D:
			var p := c as Polygon2D
			var t2 := create_tween()
			t2.tween_property(p, "color", p.color.lerp(Color(1, 0.9, 0.4), 0.55), 0.2)


func _answer(n: int) -> void:
	var want: int = TASKS[_task]
	var btn_i: int = CHOICES.find(n)

	if n != want:
		# Pogresno - samo zatresi. Bez kazne, bez gubljenja srca.
		if btn_i >= 0:
			_shake(_buttons[btn_i])
		Audio.play("land", 0.15)
		return

	_busy = true
	Audio.play("heart", 0.1)
	if btn_i >= 0:
		_mark_correct(_buttons[btn_i])

	step_done()
	_task += 1

	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return

	if _task >= TASKS.size():
		win()
		return

	_show_task()
	_busy = false


## Nacrtaj pahulje za trenutni zadatak.
func _show_task() -> void:
	# Ubij sway petlju PRE queue_free: tvin vezan za obrisan cvor nastavlja
	# da se vrti u prazno i Godot prijavljuje "Infinite loop detected" za
	# svaku pahulju iz prethodnog zadatka (14 gresaka u logu na 5 zadataka).
	for f in _flakes:
		var t: Variant = f.get_meta("sway", null)
		if t != null and t is Tween and (t as Tween).is_valid():
			(t as Tween).kill()
		f.queue_free()
	_flakes.clear()
	_counted.clear()

	var n: int = TASKS[_task]
	# Pahulje u JASNOM redu (do 3 u redu), ne razbacane - lakse za brojanje.
	var per_row: int = mini(n, 3)
	var rows: int = int(ceil(float(n) / float(per_row)))

	for i in n:
		var row := i / per_row
		var col := i % per_row
		var in_row: int = mini(per_row, n - row * per_row)
		var x := (float(col) - float(in_row - 1) * 0.5) * FLAKE_STEP
		var y := -150.0 + (float(row) - float(rows - 1) * 0.5) * 108.0

		var f := Node2D.new()
		f.position = Vector2(x, y)
		_flake_holder.add_child(f)
		_flakes.append(f)
		_counted.append(false)
		_draw_flake(f)

		# Pahulje "sletnu" jedna po jedna - dete ih vidi kako dolaze.
		#
		# tween_interval se dodaje SAMO ako je > 0: za prvu pahulju (i=0)
		# interval bi bio nula, sto Godot prijavljuje kao "Infinite loop
		# detected" (korak trajanja 0). Video u logu.
		f.scale = Vector2.ZERO
		var tw := create_tween()
		if i > 0:
			tw.tween_interval(float(i) * 0.14)
		tw.tween_property(f, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK)

		# Blago se njise - ziva slika, ne statična.
		#
		# set_loops() se poziva POSLE tween_property: ako se pozove pre,
		# petlja je prazna i Godot prijavljuje "Infinite loop detected"
		# na svaku pahulju (video u logu).
		var amp := randf_range(0.06, 0.13)
		var sway := create_tween()
		sway.tween_property(f, "rotation", amp, randf_range(1.4, 2.2)) \
			.set_trans(Tween.TRANS_SINE)
		sway.tween_property(f, "rotation", -amp, randf_range(1.4, 2.2)) \
			.set_trans(Tween.TRANS_SINE)
		sway.set_loops()
		# Zapamti tvin da moze da se ubije kad pahulja nestane.
		f.set_meta("sway", sway)


## Pahulja: sest krakova sa granama, plus sjaj u sredini.
func _draw_flake(p: Node2D) -> void:
	var col := Color(0.98, 0.99, 1.0)
	# Obod je NAMERNO tamniji (0.35): na snimku su pahulje bile skoro
	# nevidljive jer je i nebo i pahulja bilo belo-plavo.
	var edge := Color(0.32, 0.55, 0.78)

	# Obod - malo veci, tamniji, da se pahulja vidi na svetloj pozadini.
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := Vector2(cos(a), sin(a))
		_poly(p, edge, [
			d.rotated(0.14) * 8.0, d * (FLAKE_R + 2.0), d.rotated(-0.14) * 8.0])
		# Grane na kraku.
		for side in [-1.0, 1.0]:
			var base: Vector2 = d * (FLAKE_R * 0.55)
			var tip: Vector2 = base + d.rotated(side * 0.7) * (FLAKE_R * 0.34)
			_poly(p, edge, [base, tip, base + d * 5.0])

	# Ispuna.
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := Vector2(cos(a), sin(a))
		_poly(p, col, [
			d.rotated(0.1) * 6.0, d * (FLAKE_R - 3.0), d.rotated(-0.1) * 6.0])
		for side in [-1.0, 1.0]:
			var base: Vector2 = d * (FLAKE_R * 0.55)
			var tip: Vector2 = base + d.rotated(side * 0.7) * (FLAKE_R * 0.28)
			_poly(p, col, [base, tip, base + d * 4.0])

	_circle(p, Vector2.ZERO, 9.0, col)
	_circle(p, Vector2(-2, -3), 4.0, Color(1, 1, 1, 0.9))


## --- DUGMAD SA BROJEVIMA ---

func _build_buttons() -> void:
	var total := CHOICES.size() * BTN_SIZE + (CHOICES.size() - 1) * BTN_GAP
	var x0 := -total * 0.5 + BTN_SIZE * 0.5

	for i in CHOICES.size():
		var b := Node2D.new()
		b.position = Vector2(x0 + i * (BTN_SIZE + BTN_GAP), 150.0)
		_stage.add_child(b)
		_buttons.append(b)

		# Kartica.
		_rounded(b, BTN_SIZE * 0.5, BTN_SIZE * 0.5, Color(0.55, 0.72, 0.88))
		_rounded(b, BTN_SIZE * 0.5 - 6.0, BTN_SIZE * 0.5 - 6.0,
			Color(0.98, 0.99, 1.0))

		# Broj. Cifre POSTOJE u Godotovom web fontu (slova i cifre rade;
		# samo simboli kao zvezda i srce ne) - proveravao sam ranije.
		var lbl := Label.new()
		lbl.text = str(CHOICES[i])
		lbl.add_theme_font_size_override("font_size", 62)
		lbl.add_theme_color_override("font_color", Color(0.18, 0.36, 0.58))
		lbl.size = Vector2(BTN_SIZE, BTN_SIZE)
		lbl.position = Vector2(-BTN_SIZE * 0.5, -BTN_SIZE * 0.5 + 4.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lbl)

		# Tacki ispod broja - dete koje ne cita cifre moze da broji tacke.
		var dots := Node2D.new()
		dots.position = Vector2(0, BTN_SIZE * 0.5 - 20.0)
		b.add_child(dots)
		var cnt: int = CHOICES[i]
		var dstep := 15.0
		for k in cnt:
			_circle(dots, Vector2((float(k) - float(cnt - 1) * 0.5) * dstep, 0),
				5.0, Color(0.4, 0.62, 0.82))


## Tacan odgovor - zeleni okvir i kvacica.
func _mark_correct(b: Node2D) -> void:
	var ring := Node2D.new()
	ring.z_index = -1
	b.add_child(ring)
	_rounded(ring, BTN_SIZE * 0.5 + 8.0, BTN_SIZE * 0.5 + 8.0,
		Color(0.35, 0.8, 0.45))

	# Kvacica se CRTA, ne pise - Godotov web font nema znak za nju.
	var chk := Node2D.new()
	chk.position = Vector2(BTN_SIZE * 0.5 - 12.0, -BTN_SIZE * 0.5 + 12.0)
	chk.z_index = 4
	b.add_child(chk)
	_circle(chk, Vector2.ZERO, 17.0, Color(0.3, 0.75, 0.4))
	_poly(chk, Color(1, 1, 1), [
		Vector2(-8, 0), Vector2(-3, 6), Vector2(9, -7),
		Vector2(9, -3), Vector2(-3, 10), Vector2(-8, 4)])

	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.16, 1.16), 0.13).set_trans(Tween.TRANS_BACK)
	tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	# Okvir i kvacica nestanu pre sledeceg zadatka.
	var fade := create_tween()
	fade.tween_interval(0.55)
	fade.tween_property(ring, "modulate:a", 0.0, 0.25)
	fade.parallel().tween_property(chk, "modulate:a", 0.0, 0.25)
	fade.tween_callback(func() -> void:
		ring.queue_free()
		chk.queue_free()
	)


func _shake(b: Node2D) -> void:
	var base := b.position
	var tw := create_tween()
	for i in 2:
		tw.tween_property(b, "position", base + Vector2(7, 0), 0.05)
		tw.tween_property(b, "position", base - Vector2(7, 0), 0.05)
	tw.tween_property(b, "position", base, 0.05)


## Uklopi scenu u ekran. Sest dugmadi je siroko; na telefonu se skalira.
func _fit_stage() -> void:
	if _stage == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return

	var total_w := CHOICES.size() * BTN_SIZE + (CHOICES.size() - 1) * BTN_GAP
	# Visina: pahulje gore (do 2 reda) + dugmad dole.
	var total_h := 150.0 + BTN_SIZE + 260.0

	const TOP_RESERVE := 84.0
	var s := minf((vp.x - 40.0) / total_w, (vp.y - TOP_RESERVE) / total_h)
	s = minf(s, 1.0)
	_stage.scale = Vector2(s, s)
	_stage.position = Vector2(0, TOP_RESERVE * 0.35)

	# Kavez sa jezom gore-levo, van pahulja i dugmadi.
	if _friend != null:
		const CAGE_R := 62.0
		# Kavez je gore-levo gde je SLOBODAN prostor iznad dugmadi, pa ga
		# ogranicava visina do prve pahulje, ne sirina. Na snimku je pri
		# vezivanju za sirinu ispadao sitan (0.7).
		var free_h: float = 260.0 * s
		var fs: float = clampf(free_h / (CAGE_R * 2.2), 1.0, 2.0)
		_friend.scale = Vector2(fs, fs)
		_friend.position = Vector2(-vp.x * 0.5 + CAGE_R * fs + 18.0,
			-vp.y * 0.5 + TOP_RESERVE + CAGE_R * fs * 0.7)


## --- Helperi ---

func _rounded(parent: Node2D, hw: float, hh: float, col: Color) -> void:
	const R := 16.0
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
