extends MinigamePick
## NIVO — "Saberi bombone" (Ostrvo slatkiša)
##
## Levo je grupa bombona, desno druga grupa. Dete izabere broj koliko ih je
## UKUPNO.
##
## Sabiranje je za petogodisnjaka granicno, pa je namerno olaksano:
##   - zbir NIKAD ne prelazi 6, a sabirci su do 3
##   - bombone se VIDE i mogu se prebrojati prstom (dodir ih "oznaci")
##   - dugmad imaju i tackice pored cifre, pa dete koje ne cita cifre
##     moze da uparuje kolicine
##   - nema merenja vremena, promasaj samo zatrese dugme

var rounds := 5

## Ponudjeni odgovori. Do 6 - dalje petogodisnjak ne broji sigurno.
const CHOICES: Array[int] = [2, 3, 4, 5, 6]

const BTN_SIZE := 150.0
const BTN_GAP := 16.0
const CANDY_R := 26.0

var _round := 0
var _sum := 0
var _tasks: Array = []
var _stage: Node2D
var _left: Node2D
var _right: Node2D
var _buttons: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()


func _setup() -> void:
	friend_kind = "vevericaB"
	biome = "slatkisi"
	task_text = "Koliko ima bombona ukupno?"
	set_total_steps(rounds)
	_rng.randomize()

	# Zadaci: par (a, b) tako da a+b <= 6, a i b >= 1.
	_tasks.clear()
	var guard := 0
	while _tasks.size() < rounds and guard < 300:
		guard += 1
		var a := _rng.randi_range(1, 3)
		var b := _rng.randi_range(1, 3)
		if a + b < 2 or a + b > 6:
			continue
		# Ne isti zbir dva puta zaredom.
		if _tasks.size() > 0 and (_tasks[_tasks.size() - 1][0]
				+ _tasks[_tasks.size() - 1][1]) == a + b:
			continue
		_tasks.append([a, b])


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)
	_left = Node2D.new()
	_left.position = Vector2(-230, -170)
	_stage.add_child(_left)
	_right = Node2D.new()
	_right.position = Vector2(190, -170)
	_stage.add_child(_right)

	# Znak "+" izmedju grupa - crta se poligonima (font ga ima, ali ovako
	# je debeo i vidljiv detetu).
	var plus := Node2D.new()
	plus.position = Vector2(-20, -170)
	_stage.add_child(plus)
	Draw2D.poly(plus, Color(0.75, 0.4, 0.5), [
		Vector2(-30, -9), Vector2(30, -9), Vector2(30, 9), Vector2(-30, 9)])
	Draw2D.poly(plus, Color(0.75, 0.4, 0.5), [
		Vector2(-9, -30), Vector2(9, -30), Vector2(9, 30), Vector2(-9, 30)])

	_build_buttons()
	_next_round()
	_fit()
	get_viewport().size_changed.connect(_fit)


func _fit() -> void:
	var w := float(CHOICES.size()) * (BTN_SIZE + BTN_GAP)
	fit_stage(_stage, Vector2(maxf(w, 900.0), 640.0))


func _build_buttons() -> void:
	var total := float(CHOICES.size()) * BTN_SIZE \
		+ float(CHOICES.size() - 1) * BTN_GAP
	var x0 := -total * 0.5 + BTN_SIZE * 0.5
	for i in CHOICES.size():
		var b := Node2D.new()
		b.position = Vector2(x0 + float(i) * (BTN_SIZE + BTN_GAP), 120.0)
		_stage.add_child(b)
		_buttons.append(b)

		Draw2D.poly(b, Color(0.85, 0.5, 0.6), [
			Vector2(-BTN_SIZE * 0.5, -BTN_SIZE * 0.5),
			Vector2(BTN_SIZE * 0.5, -BTN_SIZE * 0.5),
			Vector2(BTN_SIZE * 0.5, BTN_SIZE * 0.5),
			Vector2(-BTN_SIZE * 0.5, BTN_SIZE * 0.5)])
		Draw2D.poly(b, Color(0.99, 0.96, 0.94), [
			Vector2(-BTN_SIZE * 0.5 + 7, -BTN_SIZE * 0.5 + 7),
			Vector2(BTN_SIZE * 0.5 - 7, -BTN_SIZE * 0.5 + 7),
			Vector2(BTN_SIZE * 0.5 - 7, BTN_SIZE * 0.5 - 7),
			Vector2(-BTN_SIZE * 0.5 + 7, BTN_SIZE * 0.5 - 7)])

		# Cifra. Cifre POSTOJE u Godotovom web fontu.
		var lbl := Label.new()
		lbl.text = str(CHOICES[i])
		lbl.add_theme_font_size_override("font_size", 58)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.28, 0.4))
		lbl.size = Vector2(BTN_SIZE, BTN_SIZE * 0.72)
		lbl.position = Vector2(-BTN_SIZE * 0.5, -BTN_SIZE * 0.5)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lbl)

		# Tackice ispod cifre - dete koje ne cita cifre uparuje kolicinu.
		var n: int = CHOICES[i]
		for k in n:
			Draw2D.circle(b, Vector2(
				(float(k) - float(n - 1) * 0.5) * 17.0, BTN_SIZE * 0.5 - 26.0),
				5.5, Color(0.85, 0.45, 0.55), 10)

		add_target(b, BTN_SIZE * 0.62)


func _next_round() -> void:
	for grp in [_left, _right]:
		for c in grp.get_children():
			c.queue_free()

	var task: Array = _tasks[_round]
	var a: int = task[0]
	var b: int = task[1]
	_sum = a + b

	_draw_candies(_left, a)
	_draw_candies(_right, b)


## Bombone u grupi - poredjane u red, dovoljno velike za brojanje prstom.
func _draw_candies(parent: Node2D, n: int) -> void:
	# Tanjir pod grupom - jasno omedjuje "ovu" grupu.
	Draw2D.poly(parent, Color(0.98, 0.9, 0.93), [
		Vector2(-150, -60), Vector2(150, -60),
		Vector2(150, 62), Vector2(-150, 62)])
	Draw2D.poly(parent, Color(0.94, 0.78, 0.84), [
		Vector2(-150, 50), Vector2(150, 50),
		Vector2(150, 62), Vector2(-150, 62)])

	const COLS: Array[Color] = [
		Color(0.98, 0.45, 0.55), Color(0.55, 0.8, 0.95),
		Color(0.99, 0.82, 0.35), Color(0.65, 0.85, 0.55)]
	for k in n:
		var x := (float(k) - float(n - 1) * 0.5) * 74.0
		var col: Color = COLS[k % 4]
		# Bombona: telo + omot sa strane + sjaj.
		Draw2D.circle(parent, Vector2(x, 2), CANDY_R, col.darkened(0.2), 14)
		Draw2D.circle(parent, Vector2(x, 0), CANDY_R - 3.0, col, 14)
		Draw2D.circle(parent, Vector2(x - 8, -9), 7.0, Color(1, 1, 1, 0.5), 10)
		Draw2D.poly(parent, col.darkened(0.1), [
			Vector2(x - CANDY_R - 12, -9), Vector2(x - CANDY_R + 2, 0),
			Vector2(x - CANDY_R - 12, 9)])
		Draw2D.poly(parent, col.darkened(0.1), [
			Vector2(x + CANDY_R + 12, -9), Vector2(x + CANDY_R - 2, 0),
			Vector2(x + CANDY_R + 12, 9)])


func _on_pick(index: int) -> void:
	if CHOICES[index] != _sum:
		shake(_buttons[index])
		return

	busy = true
	pop(_buttons[index])
	mark_ok(_buttons[index], Vector2(BTN_SIZE * 0.42, -BTN_SIZE * 0.42))
	step_done()
	_round += 1
	if _round >= rounds:
		await get_tree().create_timer(0.6).timeout
		win()
		return
	await get_tree().create_timer(0.8).timeout
	busy = false
	_next_round()
