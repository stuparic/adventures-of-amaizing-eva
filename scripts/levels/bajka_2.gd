extends MinigamePick
## NIVO — "Prva glasa" (Čarobna šuma)
##
## Prikaze se veliko SLOVO, a ispod tri slicice. Dete dodirne onu koja
## POCINJE tim glasom.
##
## Ovo je jedini nivo koji dodiruje citanje, pa je namerno olaksan - Eva ima
## 5 godina i ne cita:
##   - slovo je ogromno i uvek VELIKO pisano (A, ne a)
##   - koriste se samo glasovi koji se jasno cuju na pocetku reci
##   - ispod svake slicice pise i rec, da roditelj moze da procita
##   - nema merenja vremena i nema kazne za promasaj
##
## Slicice su poligoni (kao sve u igri), ne slova - dete prepoznaje sliku,
## a slovo samo uparuje.

var rounds := 5

## Zadaci: slovo -> [ime oblika koji POCINJE tim glasom, rec].
## Oblici koje _draw_pic ume da nacrta: jabuka, riba, sunce, kuca, medved,
## zvezda, cvet, mesec, lopta, drvo.
const TASKS: Array = [
	["J", "jabuka", "Jabuka"],
	["R", "riba", "Riba"],
	["S", "sunce", "Sunce"],
	["K", "kuca", "Kuća"],
	["M", "medved", "Medved"],
	["Z", "zvezda", "Zvezda"],
	["C", "cvet", "Cvet"],
	["L", "lopta", "Lopta"],
	["D", "drvo", "Drvo"],
]

## Sve slicice - iz ovoga se biraju "pogresni" odgovori.
const ALL_PICS: Array[String] = [
	"jabuka", "riba", "sunce", "kuca", "medved",
	"zvezda", "cvet", "lopta", "drvo",
]

const SLOT_STEP := 300.0
const PIC_R := 82.0

var _round := 0
var _want := 0
var _stage: Node2D
var _items: Array[Node2D] = []
var _letter: Label
var _order: Array[int] = []
var _rng := RandomNumberGenerator.new()


func _setup() -> void:
	friend_kind = "vila"
	biome = "bajka"
	task_text = "Šta počinje ovim slovom?"
	set_total_steps(rounds)
	_rng.randomize()

	# Randomizovan izbor zadataka, bez ponavljanja.
	var pool: Array[int] = []
	for i in TASKS.size():
		pool.append(i)
	for i in range(pool.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t: int = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	_order = pool.slice(0, rounds)


func _ready() -> void:
	super()
	_stage = Node2D.new()
	add_child(_stage)

	# Veliko slovo gore. Slova i cifre POSTOJE u Godotovom web fontu
	# (samo simboli kao ★ ♥ ✓ ne rade), pa se slovo sme pisati tekstom.
	_letter = Label.new()
	_letter.add_theme_font_size_override("font_size", 150)
	_letter.add_theme_color_override("font_color", Color(0.75, 0.35, 0.7))
	_letter.add_theme_constant_override("outline_size", 12)
	_letter.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_letter.size = Vector2(300, 180)
	_letter.position = Vector2(-150, -300)
	_letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_letter)

	_fit()
	get_viewport().size_changed.connect(_fit)
	_next_round()


func _fit() -> void:
	fit_stage(_stage, Vector2(SLOT_STEP * 3.0 + 140.0, 700.0), 110.0)


func _next_round() -> void:
	for it in _items:
		if is_instance_valid(it):
			it.queue_free()
	_items.clear()
	clear_targets()

	var task: Array = TASKS[_order[_round]]
	var letter := String(task[0])
	var correct := String(task[1])
	_letter.text = letter

	# Dva pogresna odgovora - ne smeju poceti istim glasom.
	var wrong: Array[String] = []
	var guard := 0
	while wrong.size() < 2 and guard < 100:
		guard += 1
		var cand: String = ALL_PICS[_rng.randi_range(0, ALL_PICS.size() - 1)]
		if cand == correct or wrong.has(cand):
			continue
		# Proveri da i on ne pocinje istim glasom (npr. "kuca" i "cvet" su
		# razliciti, ali dve reci na "s" bi imale dva tacna odgovora).
		var starts_same := false
		for t in TASKS:
			if String(t[1]) == cand and String(t[0]) == letter:
				starts_same = true
		if starts_same:
			continue
		wrong.append(cand)

	var picks: Array[String] = [correct, wrong[0], wrong[1]]
	# Promesaj da tacan nije uvek prvi.
	for i in range(picks.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t2: String = picks[i]
		picks[i] = picks[j]
		picks[j] = t2
	_want = picks.find(correct)

	var x0 := -SLOT_STEP
	for i in picks.size():
		var it := Node2D.new()
		it.position = Vector2(x0 + float(i) * SLOT_STEP, 60.0)
		_stage.add_child(it)
		_items.append(it)

		# Bela kartica pod slicicom - meta je jasno omedjena.
		Draw2D.poly(it, Color(0.35, 0.5, 0.42, 0.25), [
			Vector2(-112, -104), Vector2(112, -104),
			Vector2(112, 116), Vector2(-112, 116)])
		Draw2D.poly(it, Color(0.99, 0.98, 0.95), [
			Vector2(-106, -98), Vector2(106, -98),
			Vector2(106, 110), Vector2(-106, 110)])
		_draw_pic(it, picks[i])

		# Rec ispod slicice - za roditelja koji cita sa detetom.
		var w := Label.new()
		for t in TASKS:
			if String(t[1]) == picks[i]:
				w.text = String(t[2])
		w.add_theme_font_size_override("font_size", 26)
		w.add_theme_color_override("font_color", Color(0.35, 0.3, 0.4))
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w.size = Vector2(212, 40)
		w.position = Vector2(-106, 68)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(w)

		add_target(it, 130.0)


## Slicice - svaka je prepoznatljiva silueta u par poligona.
func _draw_pic(p: Node2D, kind: String) -> void:
	var r := PIC_R
	match kind:
		"jabuka":
			Draw2D.circle(p, Vector2(0, -8), r * 0.62, Color(0.9, 0.28, 0.32), 16)
			Draw2D.circle(p, Vector2(-r * 0.2, -r * 0.3), r * 0.16,
				Color(1, 1, 1, 0.4), 10)
			Draw2D.poly(p, Color(0.45, 0.32, 0.2), [
				Vector2(-2, -r * 0.62 - 8), Vector2(2, -r * 0.62 - 8),
				Vector2(3, -r * 0.62 + 4), Vector2(-3, -r * 0.62 + 4)])
			Draw2D.poly(p, Color(0.4, 0.7, 0.35), [
				Vector2(2, -r * 0.62 - 4), Vector2(r * 0.4, -r * 0.8),
				Vector2(r * 0.34, -r * 0.5)])
		"riba":
			Draw2D.poly(p, Color(0.35, 0.68, 0.9), [
				Vector2(-r * 0.7, 0), Vector2(-r * 0.2, -r * 0.4),
				Vector2(r * 0.4, -r * 0.3), Vector2(r * 0.55, 0),
				Vector2(r * 0.4, r * 0.3), Vector2(-r * 0.2, r * 0.4)])
			Draw2D.poly(p, Color(0.28, 0.56, 0.8), [
				Vector2(r * 0.5, 0), Vector2(r * 0.85, -r * 0.35),
				Vector2(r * 0.85, r * 0.35)])
			Draw2D.circle(p, Vector2(-r * 0.32, -r * 0.1), r * 0.1,
				Color(1, 1, 1), 8)
			Draw2D.circle(p, Vector2(-r * 0.34, -r * 0.1), r * 0.05,
				Color(0.1, 0.1, 0.12), 6)
		"sunce":
			for k in 8:
				var a := TAU * float(k) / 8.0
				var d := Vector2(cos(a), sin(a))
				Draw2D.poly(p, Color(0.99, 0.8, 0.25), [
					d.rotated(0.18) * r * 0.45, d * r * 0.85,
					d.rotated(-0.18) * r * 0.45])
			Draw2D.circle(p, Vector2.ZERO, r * 0.45, Color(1, 0.85, 0.3), 16)
			Draw2D.circle(p, Vector2(-r * 0.12, -r * 0.12), r * 0.14,
				Color(1, 1, 1, 0.5), 10)
		"kuca":
			Draw2D.poly(p, Color(0.95, 0.9, 0.82), [
				Vector2(-r * 0.5, 0), Vector2(r * 0.5, 0),
				Vector2(r * 0.5, r * 0.5), Vector2(-r * 0.5, r * 0.5)])
			Draw2D.poly(p, Color(0.85, 0.35, 0.3), [
				Vector2(-r * 0.62, 0), Vector2(0, -r * 0.5),
				Vector2(r * 0.62, 0)])
			Draw2D.poly(p, Color(0.5, 0.36, 0.24), [
				Vector2(-r * 0.14, r * 0.5), Vector2(r * 0.14, r * 0.5),
				Vector2(r * 0.14, r * 0.14), Vector2(-r * 0.14, r * 0.14)])
		"medved":
			Draw2D.circle(p, Vector2(-r * 0.4, -r * 0.4), r * 0.2,
				Color(0.6, 0.44, 0.32), 10)
			Draw2D.circle(p, Vector2(r * 0.4, -r * 0.4), r * 0.2,
				Color(0.6, 0.44, 0.32), 10)
			Draw2D.circle(p, Vector2.ZERO, r * 0.55, Color(0.7, 0.52, 0.38), 16)
			Draw2D.circle(p, Vector2(0, r * 0.14), r * 0.24,
				Color(0.92, 0.85, 0.75), 12)
			Draw2D.circle(p, Vector2(0, r * 0.06), r * 0.09,
				Color(0.28, 0.2, 0.18), 8)
			Draw2D.circle(p, Vector2(-r * 0.2, -r * 0.14), r * 0.07,
				Color(0.15, 0.12, 0.14), 8)
			Draw2D.circle(p, Vector2(r * 0.2, -r * 0.14), r * 0.07,
				Color(0.15, 0.12, 0.14), 8)
		"zvezda":
			var pts := PackedVector2Array()
			for k in 10:
				var a := TAU * float(k) / 10.0 - PI * 0.5
				var rr: float = r * 0.8 if k % 2 == 0 else r * 0.36
				pts.append(Vector2(cos(a), sin(a)) * rr)
			Draw2D.poly(p, Color(0.98, 0.78, 0.25), pts)
			var pts2 := PackedVector2Array()
			for k in 10:
				var a := TAU * float(k) / 10.0 - PI * 0.5
				var rr2: float = r * 0.52 if k % 2 == 0 else r * 0.22
				pts2.append(Vector2(cos(a), sin(a)) * rr2)
			Draw2D.poly(p, Color(1, 0.92, 0.55), pts2)
		"cvet":
			for k in 5:
				var a := TAU * float(k) / 5.0 - PI * 0.5
				Draw2D.circle(p, Vector2(cos(a), sin(a)) * r * 0.42,
					r * 0.28, Color(0.95, 0.45, 0.68), 12)
			Draw2D.circle(p, Vector2.ZERO, r * 0.24, Color(1, 0.88, 0.35), 12)
		"lopta":
			Draw2D.circle(p, Vector2.ZERO, r * 0.6, Color(0.98, 0.98, 0.96), 18)
			for k in 5:
				var a := TAU * float(k) / 5.0 - PI * 0.5
				Draw2D.poly(p, Color(0.25, 0.28, 0.34), [
					Vector2(cos(a), sin(a)) * r * 0.2,
					Vector2(cos(a + 0.5), sin(a + 0.5)) * r * 0.44,
					Vector2(cos(a), sin(a)) * r * 0.52,
					Vector2(cos(a - 0.5), sin(a - 0.5)) * r * 0.44])
		_:
			# drvo
			Draw2D.poly(p, Color(0.5, 0.36, 0.22), [
				Vector2(-r * 0.12, r * 0.5), Vector2(r * 0.12, r * 0.5),
				Vector2(r * 0.1, -r * 0.1), Vector2(-r * 0.1, -r * 0.1)])
			Draw2D.circle(p, Vector2(0, -r * 0.35), r * 0.42,
				Color(0.35, 0.65, 0.35), 14)
			Draw2D.circle(p, Vector2(-r * 0.26, -r * 0.16), r * 0.28,
				Color(0.4, 0.72, 0.38), 12)
			Draw2D.circle(p, Vector2(r * 0.26, -r * 0.16), r * 0.28,
				Color(0.4, 0.72, 0.38), 12)


func _on_pick(index: int) -> void:
	if index != _want:
		shake(_items[index])
		return

	busy = true
	pop(_items[index])
	mark_ok(_items[index], Vector2(0, -120.0))
	step_done()
	_round += 1
	if _round >= rounds:
		await get_tree().create_timer(0.6).timeout
		win()
		return
	await get_tree().create_timer(0.8).timeout
	busy = false
	_next_round()
