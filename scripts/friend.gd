extends Area2D
## Prijatelj koga Eva spasava. Svaki nivo ima drugog.
##
## `kind` odredjuje ko je: maca, kuca, zeka, ptica, veverica, jez,
## kornjaca, delfin, pingvin, lisica, sova, macak.
##
## Lik se crta poligonima po `kind` - nema slika.

## Ko je zatvoren. Postavlja se pre dodavanja u scenu.
var kind := "maca"

## Koliko cesto doziva (zvukom) dok je zatvoren.
const CALL_INTERVAL := 4.5
const CALL_RANGE := 420.0

@onready var visual: Node2D = $Visual
@onready var cage: Node2D = $Visual/Cage

var _rescued := false
var _t := 0.0
var _call_timer := 2.0
var _player: Node2D


## Imena za banner - ko je spasen.
const NAMES := {
	"maca": "macu Čarlija",
	"kuca": "kucu Rokija",
	"zeka": "zeku Bakija",
	"ptica": "pticu Cvrkuta",
	"veverica": "vevericu Rilu",
	"jez": "ježa Bodljka",
	"kornjaca": "kornjaču Žuću",
	"delfin": "delfina Pliska",
	"pingvin": "pingvina Frku",
	"lisica": "lisicu Rumenku",
	"sova": "sovu Mudru",
	"macak": "mačka Garu",
	"koala": "koalu Snenu",
	"panda": "pandu Bambu",
}


func friend_name() -> String:
	return String(NAMES.get(kind, "prijatelja"))


func _ready() -> void:
	body_entered.connect(_on_body)
	_draw_friend()


func _process(delta: float) -> void:
	_t += delta
	if _rescued:
		visual.position.y = -absf(sin(_t * 6.0)) * 10.0
		return

	visual.rotation = sin(_t * 3.0) * 0.08
	_tick_call(delta)


func _tick_call(delta: float) -> void:
	_call_timer -= delta
	if _call_timer > 0.0:
		return
	_call_timer = CALL_INTERVAL

	if _player == null:
		for n in get_tree().get_nodes_in_group("player"):
			_player = n as Node2D
			break
	if _player == null:
		return

	if global_position.distance_to(_player.global_position) < CALL_RANGE:
		Audio.play("meow", 0.1)


func _on_body(body: Node) -> void:
	if _rescued or not body.has_method("hurt"):
		return

	_rescued = true
	set_deferred("monitoring", false)

	Audio.play("meow", 0.0)
	if not Audio.has_voice_win():
		Audio.play("win")
		Audio.play_win_music()

	Game.rescued_friend = friend_name()

	var tw := create_tween()
	tw.tween_property(cage, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(cage, "scale", Vector2(1.6, 1.6), 0.4)
	tw.tween_callback(func() -> void:
		visual.rotation = 0.0
		Game.level_won.emit()
	)


## --- Crtanje lika po vrsti ---

func _draw_friend() -> void:
	var body := Node2D.new()
	body.name = "Body"
	visual.add_child(body)
	visual.move_child(body, 0)

	match kind:
		"kuca":     _draw_dog(body)
		"zeka":     _draw_bunny(body)
		"ptica":    _draw_bird(body)
		"veverica": _draw_squirrel(body)
		"jez":      _draw_hedgehog(body)
		"kornjaca": _draw_turtle(body)
		"delfin":   _draw_dolphin(body)
		"pingvin":  _draw_penguin(body)
		"lisica":   _draw_fox(body)
		"sova":     _draw_owl(body)
		"koala":    _draw_koala(body)
		"panda":    _draw_panda(body)
		"macak":    _draw_cat(body, Color(0.45, 0.42, 0.46), Color(0.34, 0.32, 0.36))
		_:          _draw_cat(body, Color(0.98, 0.68, 0.32), Color(0.86, 0.55, 0.24))


func _draw_cat(p: Node2D, fur: Color, dark: Color) -> void:
	_poly(p, dark, [V(-9, 0), V(-7, -6), V(-3, -10), V(3, -10), V(7, -6), V(9, 0), V(8, 10), V(-8, 10)])
	_poly(p, fur, [V(-8, -1), V(-6, -6), V(-3, -9), V(3, -9), V(6, -6), V(8, -1), V(7, 9), V(-7, 9)])
	# Usi.
	_poly(p, fur, [V(-7, -8), V(-5, -14), V(-1, -9)])
	_poly(p, fur, [V(7, -8), V(5, -14), V(1, -9)])
	_poly(p, Color(0.96, 0.6, 0.62), [V(-5.6, -8.6), V(-4.6, -12), V(-2.6, -9.2)])
	_poly(p, Color(0.96, 0.6, 0.62), [V(5.6, -8.6), V(4.6, -12), V(2.6, -9.2)])
	# Rep.
	_poly(p, fur, [V(-8, 4), V(-14, -1), V(-13, -3), V(-7, 2)])
	_face(p, Color(0.3, 0.66, 0.4), -4.5, 3.4)
	_muzzle(p, Color(1, 0.95, 0.88), Color(0.9, 0.45, 0.5))


func _draw_dog(p: Node2D) -> void:
	var fur := Color(0.85, 0.66, 0.4)
	var dark := Color(0.68, 0.5, 0.3)
	_poly(p, dark, [V(-9, 0), V(-7, -7), V(0, -11), V(7, -7), V(9, 0), V(8, 10), V(-8, 10)])
	_poly(p, fur, [V(-8, -1), V(-6, -7), V(0, -10), V(6, -7), V(8, -1), V(7, 9), V(-7, 9)])
	# Klempave usi.
	_poly(p, dark, [V(-8, -6), V(-12, -2), V(-11, 4), V(-6, 0)])
	_poly(p, dark, [V(8, -6), V(12, -2), V(11, 4), V(6, 0)])
	# Rep gore.
	_poly(p, fur, [V(-8, 2), V(-13, -4), V(-11, -6), V(-7, 0)])
	_face(p, Color(0.35, 0.24, 0.16), -4.2, 3.2)
	_muzzle(p, Color(0.96, 0.9, 0.8), Color(0.25, 0.2, 0.18))
	# Mrlja oko oka.
	_poly(p, dark, [V(1.4, -6), V(6.4, -6.6), V(6.8, -2), V(1.6, -1.6)])


func _draw_bunny(p: Node2D) -> void:
	var fur := Color(0.97, 0.95, 0.94)
	var shade := Color(0.87, 0.84, 0.85)
	var pink := Color(0.98, 0.72, 0.76)

	# Repic - pahuljast, iza tela.
	_circle(p, V(-8.5, 5.5), 4.2, shade)
	_circle(p, V(-8.5, 5.0), 3.4, Color(1, 1, 1))

	# Stopala - ispod tela, siroka.
	_poly(p, shade, [V(-7, 8), V(-1.5, 8), V(-1, 11.5), V(-7.5, 11.5)])
	_poly(p, shade, [V(1.5, 8), V(7, 8), V(7.5, 11.5), V(1, 11.5)])
	_poly(p, fur, [V(-6.6, 8), V(-2, 8), V(-1.6, 10.8), V(-7, 10.8)])
	_poly(p, fur, [V(2, 8), V(6.6, 8), V(7, 10.8), V(1.6, 10.8)])
	# Prstici na stopalima.
	for x in [-5.4, -4.0, 4.0, 5.4]:
		_circle(p, V(x, 10.4), 0.8, pink)

	# Telo - kruskasto, sire dole.
	_poly(p, shade, [V(-7.5, -3), V(-5.5, -8), V(0, -10.5), V(5.5, -8),
		V(7.5, -3), V(8, 5), V(5, 9), V(-5, 9), V(-8, 5)])
	_poly(p, fur, [V(-6.6, -4), V(-4.8, -8), V(0, -9.8), V(4.8, -8),
		V(6.6, -4), V(7, 4.6), V(4.4, 8.2), V(-4.4, 8.2), V(-7, 4.6)])
	# Svetli trbuh.
	_poly(p, Color(1, 1, 1), [V(-3.4, 0), V(3.4, 0), V(2.8, 7.6), V(-2.8, 7.6)])

	# Prednje sapice.
	_circle(p, V(-5.2, 3.4), 2.2, fur)
	_circle(p, V(5.2, 3.4), 2.2, fur)

	# Dugacke usi - blago razmaknute, sa roze unutrasnjoscu.
	_poly(p, shade, [V(-5.4, -8), V(-8.4, -22), V(-4.6, -24.5), V(-2, -9)])
	_poly(p, shade, [V(5.4, -8), V(8.4, -22), V(4.6, -24.5), V(2, -9)])
	_poly(p, fur, [V(-5, -8.6), V(-7.8, -21.6), V(-4.8, -23.6), V(-2.6, -9.4)])
	_poly(p, fur, [V(5, -8.6), V(7.8, -21.6), V(4.8, -23.6), V(2.6, -9.4)])
	_poly(p, pink, [V(-4.8, -10.4), V(-6.6, -20.4), V(-4.9, -21.6), V(-3.4, -10.8)])
	_poly(p, pink, [V(4.8, -10.4), V(6.6, -20.4), V(4.9, -21.6), V(3.4, -10.8)])

	# Glava - okrugla, iznad tela.
	_circle(p, V(0, -7), 7.4, shade)
	_circle(p, V(0, -7.4), 6.9, fur)

	# Obrazi.
	_circle(p, V(-4.6, -5.4), 2.0, Color(0.99, 0.78, 0.8, 0.75))
	_circle(p, V(4.6, -5.4), 2.0, Color(0.99, 0.78, 0.8, 0.75))

	# Oci - velike, sa dva odsjaja.
	_circle(p, V(-2.9, -8.4), 2.3, Color(0.99, 1, 0.98))
	_circle(p, V(2.9, -8.4), 2.3, Color(0.99, 1, 0.98))
	_circle(p, V(-2.9, -8.2), 1.8, Color(0.38, 0.26, 0.3))
	_circle(p, V(2.9, -8.2), 1.8, Color(0.38, 0.26, 0.3))
	_circle(p, V(-2.9, -8.1), 1.0, Color(0.12, 0.1, 0.12))
	_circle(p, V(2.9, -8.1), 1.0, Color(0.12, 0.1, 0.12))
	_circle(p, V(-3.5, -9.0), 0.75, Color(1, 1, 1))
	_circle(p, V(2.3, -9.0), 0.75, Color(1, 1, 1))
	_circle(p, V(-2.3, -7.4), 0.4, Color(1, 1, 1, 0.7))
	_circle(p, V(3.5, -7.4), 0.4, Color(1, 1, 1, 0.7))

	# Nosic i usta - Y oblik.
	_poly(p, pink.darkened(0.1), [V(-1.1, -5.6), V(1.1, -5.6), V(0, -4.2)])
	_poly(p, Color(0.6, 0.42, 0.44), [V(-0.3, -4.4), V(0.3, -4.4), V(0.3, -3.2), V(-0.3, -3.2)])
	_poly(p, Color(0.6, 0.42, 0.44), [V(-0.3, -3.5), V(-2.4, -2.4), V(-2.1, -1.9), V(-0.1, -3.0)])
	_poly(p, Color(0.6, 0.42, 0.44), [V(0.3, -3.5), V(2.4, -2.4), V(2.1, -1.9), V(0.1, -3.0)])

	# Brkovi.
	for sy in [-0.5, 0.6]:
		_poly(p, Color(0.75, 0.7, 0.7, 0.8), [
			V(-2.6, -4.2 + sy), V(-7.4, -5.0 + sy * 1.5),
			V(-7.4, -4.5 + sy * 1.5), V(-2.6, -3.8 + sy)])
		_poly(p, Color(0.75, 0.7, 0.7, 0.8), [
			V(2.6, -4.2 + sy), V(7.4, -5.0 + sy * 1.5),
			V(7.4, -4.5 + sy * 1.5), V(2.6, -3.8 + sy)])

	# Zubici - zeka.
	_poly(p, Color(1, 1, 1), [V(-1.0, -2.6), V(-0.15, -2.6), V(-0.15, -1.2), V(-1.0, -1.2)])
	_poly(p, Color(1, 1, 1), [V(0.15, -2.6), V(1.0, -2.6), V(1.0, -1.2), V(0.15, -1.2)])


func _draw_bird(p: Node2D) -> void:
	var fur := Color(0.35, 0.68, 0.92)
	var dark := Color(0.24, 0.52, 0.78)
	_poly(p, dark, [V(-7, -2), V(-5, -8), V(0, -11), V(5, -8), V(7, -2), V(5, 9), V(-5, 9)])
	_poly(p, fur, [V(-6, -3), V(-4, -8), V(0, -10), V(4, -8), V(6, -3), V(4, 8), V(-4, 8)])
	# Krila.
	_poly(p, dark, [V(-6, -2), V(-12, 2), V(-10, 6), V(-5, 4)])
	_poly(p, dark, [V(6, -2), V(12, 2), V(10, 6), V(5, 4)])
	# Perjanica.
	_poly(p, Color(0.98, 0.78, 0.28), [V(-2, -10), V(0, -16), V(2, -10)])
	# Kljun.
	_poly(p, Color(0.98, 0.72, 0.2), [V(-2, -3), V(-6.5, -1), V(-2, 1)])
	_face(p, Color(0.16, 0.18, 0.22), -4.0, 2.6)
	# Noge.
	_poly(p, Color(0.95, 0.7, 0.2), [V(-3, 8), V(-2, 8), V(-2, 12), V(-3, 12)])
	_poly(p, Color(0.95, 0.7, 0.2), [V(2, 8), V(3, 8), V(3, 12), V(2, 12)])


func _draw_squirrel(p: Node2D) -> void:
	var fur := Color(0.82, 0.5, 0.26)
	var dark := Color(0.66, 0.38, 0.2)
	# Veliki rep.
	_poly(p, dark, [V(-6, 6), V(-16, 0), V(-18, -10), V(-12, -14), V(-7, -6), V(-5, 0)])
	_poly(p, fur, [V(-6, 4), V(-14, -1), V(-15, -9), V(-11, -12), V(-7, -5)])
	_poly(p, dark, [V(-7, -2), V(-6, -8), V(0, -11), V(6, -8), V(8, -2), V(7, 10), V(-6, 10)])
	_poly(p, fur, [V(-6, -3), V(-5, -8), V(0, -10), V(5, -8), V(7, -3), V(6, 9), V(-5, 9)])
	# Male okrugle usi.
	_circle(p, V(-4.6, -10), 2.8, fur)
	_circle(p, V(4.6, -10), 2.8, fur)
	_face(p, Color(0.24, 0.16, 0.12), -4.2, 3.0)
	_muzzle(p, Color(0.98, 0.92, 0.84), Color(0.4, 0.26, 0.2))


func _draw_hedgehog(p: Node2D) -> void:
	var fur := Color(0.8, 0.68, 0.5)
	var spine := Color(0.42, 0.32, 0.24)
	# Bodlje u dva reda.
	for i in 9:
		var x := -9.0 + float(i) * 2.4
		_poly(p, spine, [V(x - 1.4, -2), V(x, -11 - absf(x) * 0.25), V(x + 1.4, -2)])
	for i in 8:
		var x := -8.0 + float(i) * 2.3
		_poly(p, spine.lightened(0.15), [V(x - 1.2, 0), V(x, -7 - absf(x) * 0.2), V(x + 1.2, 0)])
	_poly(p, fur, [V(-9, -2), V(9, -2), V(8, 10), V(-8, 10)])
	# Lice ide desno - mala glavica.
	_poly(p, fur, [V(4, -3), V(11, -1), V(11, 5), V(4, 6)])
	_circle(p, V(9.6, 1.4), 1.2, Color(0.2, 0.16, 0.16))
	_circle(p, V(6.6, -0.4), 1.5, Color(0.16, 0.14, 0.14))
	_circle(p, V(6.1, -0.9), 0.6, Color(1, 1, 1))


func _draw_turtle(p: Node2D) -> void:
	var shell := Color(0.35, 0.6, 0.35)
	var shell_l := Color(0.5, 0.75, 0.45)
	var skin := Color(0.5, 0.78, 0.45)
	# Noge.
	_poly(p, skin, [V(-8, 4), V(-4, 4), V(-4, 10), V(-8, 10)])
	_poly(p, skin, [V(4, 4), V(8, 4), V(8, 10), V(4, 10)])
	# Oklop.
	_poly(p, shell, [V(-10, 4), V(-9, -3), V(-4, -8), V(4, -8), V(9, -3), V(10, 4)])
	for i in 3:
		var x := -4.5 + float(i) * 4.5
		_poly(p, shell_l, [V(x - 2, 2), V(x - 1.5, -4), V(x + 1.5, -4), V(x + 2, 2)])
	# Glava.
	_poly(p, skin, [V(-3, -8), V(3, -8), V(4, -13), V(-4, -13)])
	_circle(p, V(-1.8, -11), 1.3, Color(0.15, 0.15, 0.2))
	_circle(p, V(1.8, -11), 1.3, Color(0.15, 0.15, 0.2))
	_poly(p, Color(0.9, 0.85, 0.5), [V(-1.6, -8.6), V(1.6, -8.6), V(0, -7)])


func _draw_dolphin(p: Node2D) -> void:
	var body := Color(0.5, 0.7, 0.86)
	var dark := Color(0.36, 0.56, 0.75)
	var belly := Color(0.92, 0.96, 0.99)
	_poly(p, dark, [V(-12, 2), V(-6, -6), V(4, -8), V(11, -3), V(12, 2), V(6, 7), V(-6, 8)])
	_poly(p, body, [V(-11, 1), V(-5, -5), V(4, -7), V(10, -3), V(11, 1), V(5, 6), V(-5, 7)])
	_poly(p, belly, [V(-8, 3), V(6, 3), V(4, 7), V(-5, 7)])
	# Peraje na vrhu i rep.
	_poly(p, dark, [V(-1, -7), V(2, -14), V(5, -6)])
	_poly(p, dark, [V(-11, 0), V(-18, -4), V(-16, 3), V(-18, 7), V(-11, 4)])
	# Kljun.
	_poly(p, body, [V(10, -1), V(16, 1), V(10, 3)])
	_circle(p, V(6, -2.6), 1.6, Color(0.15, 0.18, 0.24))
	_circle(p, V(5.5, -3.1), 0.7, Color(1, 1, 1))
	_poly(p, dark, [V(2, -1), V(7, -1), V(7, 0), V(2, 0)])


func _draw_penguin(p: Node2D) -> void:
	var black := Color(0.22, 0.24, 0.3)
	var white := Color(0.96, 0.97, 0.99)
	_poly(p, black, [V(-8, -3), V(-6, -9), V(0, -12), V(6, -9), V(8, -3), V(7, 10), V(-7, 10)])
	_poly(p, white, [V(-5, -4), V(0, -8), V(5, -4), V(5, 9), V(-5, 9)])
	# Krila.
	_poly(p, black, [V(-8, -2), V(-11, 3), V(-9, 8), V(-6, 4)])
	_poly(p, black, [V(8, -2), V(11, 3), V(9, 8), V(6, 4)])
	# Kljun i noge.
	_poly(p, Color(0.98, 0.7, 0.2), [V(-2, -5), V(2, -5), V(0, -1.5)])
	_poly(p, Color(0.98, 0.7, 0.2), [V(-6, 10), V(-1, 10), V(-2, 13), V(-6, 13)])
	_poly(p, Color(0.98, 0.7, 0.2), [V(1, 10), V(6, 10), V(6, 13), V(2, 13)])
	_circle(p, V(-2.6, -7), 1.5, Color(0.1, 0.1, 0.14))
	_circle(p, V(2.6, -7), 1.5, Color(0.1, 0.1, 0.14))
	_circle(p, V(-3.1, -7.5), 0.7, white)
	_circle(p, V(2.1, -7.5), 0.7, white)


func _draw_fox(p: Node2D) -> void:
	var fur := Color(0.92, 0.52, 0.24)
	var dark := Color(0.76, 0.38, 0.16)
	var white := Color(0.98, 0.95, 0.9)
	# Veliki rep sa belim vrhom.
	_poly(p, dark, [V(-7, 6), V(-16, 2), V(-19, -6), V(-13, -9), V(-6, -2)])
	_poly(p, white, [V(-16, 1), V(-19, -6), V(-15, -8), V(-14, -1)])
	_poly(p, dark, [V(-8, -2), V(-6, -8), V(0, -11), V(6, -8), V(8, -2), V(7, 10), V(-7, 10)])
	_poly(p, fur, [V(-7, -3), V(-5, -8), V(0, -10), V(5, -8), V(7, -3), V(6, 9), V(-6, 9)])
	_poly(p, white, [V(-4, 1), V(4, 1), V(3, 9), V(-3, 9)])
	# Siljate usi.
	_poly(p, fur, [V(-7, -8), V(-6, -16), V(-1, -9)])
	_poly(p, fur, [V(7, -8), V(6, -16), V(1, -9)])
	_poly(p, Color(0.3, 0.24, 0.24), [V(-5.8, -9), V(-5.2, -14), V(-2.6, -9.6)])
	_poly(p, Color(0.3, 0.24, 0.24), [V(5.8, -9), V(5.2, -14), V(2.6, -9.6)])
	_face(p, Color(0.28, 0.2, 0.16), -4.2, 3.0)
	_muzzle(p, white, Color(0.2, 0.16, 0.16))


func _draw_owl(p: Node2D) -> void:
	var fur := Color(0.72, 0.58, 0.42)
	var dark := Color(0.56, 0.44, 0.3)
	var pale := Color(0.9, 0.84, 0.72)
	_poly(p, dark, [V(-9, -4), V(-7, -11), V(0, -14), V(7, -11), V(9, -4), V(8, 9), V(-8, 9)])
	_poly(p, fur, [V(-8, -5), V(-6, -10), V(0, -13), V(6, -10), V(8, -5), V(7, 8), V(-7, 8)])
	# Perje na grudima.
	for i in 3:
		for j in 2:
			_circle(p, V(-3.5 + float(j) * 7.0 - float(i % 2) * 3.5, -1.0 + float(i) * 3.4),
				2.0, pale)
	# Cuperci-usi.
	_poly(p, fur, [V(-7, -10), V(-8, -17), V(-3, -12)])
	_poly(p, fur, [V(7, -10), V(8, -17), V(3, -12)])
	# Velike oci - sova.
	_circle(p, V(-3.6, -7), 3.6, pale)
	_circle(p, V(3.6, -7), 3.6, pale)
	_circle(p, V(-3.6, -7), 2.2, Color(0.98, 0.78, 0.2))
	_circle(p, V(3.6, -7), 2.2, Color(0.98, 0.78, 0.2))
	_circle(p, V(-3.6, -7), 1.2, Color(0.1, 0.1, 0.12))
	_circle(p, V(3.6, -7), 1.2, Color(0.1, 0.1, 0.12))
	_poly(p, Color(0.95, 0.7, 0.24), [V(-1.4, -5), V(1.4, -5), V(0, -2)])
	# Krila.
	_poly(p, dark, [V(-8, -4), V(-11, 2), V(-9, 7), V(-6, 2)])
	_poly(p, dark, [V(8, -4), V(11, 2), V(9, 7), V(6, 2)])


func _draw_koala(p: Node2D) -> void:
	var fur := Color(0.7, 0.72, 0.75)
	var dark := Color(0.55, 0.57, 0.6)
	var pale := Color(0.9, 0.91, 0.93)
	_poly(p, dark, [V(-8, -2), V(-6, -9), V(0, -12), V(6, -9), V(8, -2), V(7, 10), V(-7, 10)])
	_poly(p, fur, [V(-7, -3), V(-5, -9), V(0, -11), V(5, -9), V(7, -3), V(6, 9), V(-6, 9)])
	_poly(p, pale, [V(-4, 1), V(4, 1), V(3, 9), V(-3, 9)])
	# Velike okrugle usi.
	_circle(p, V(-7.5, -9), 4.6, fur)
	_circle(p, V(7.5, -9), 4.6, fur)
	_circle(p, V(-7.5, -9), 3.0, Color(0.85, 0.8, 0.8))
	_circle(p, V(7.5, -9), 3.0, Color(0.85, 0.8, 0.8))
	_circle(p, V(-3, -6.4), 1.6, Color(0.14, 0.14, 0.16))
	_circle(p, V(3, -6.4), 1.6, Color(0.14, 0.14, 0.16))
	_circle(p, V(-3.5, -7), 0.7, Color(1, 1, 1))
	_circle(p, V(2.5, -7), 0.7, Color(1, 1, 1))
	# Veliki crni nos.
	_poly(p, Color(0.2, 0.18, 0.2), [V(-2.4, -4), V(2.4, -4), V(1.8, -0.6), V(-1.8, -0.6)])


func _draw_panda(p: Node2D) -> void:
	var white := Color(0.96, 0.96, 0.95)
	var black := Color(0.2, 0.2, 0.22)
	_poly(p, black, [V(-8, -2), V(-6, -9), V(0, -12), V(6, -9), V(8, -2), V(7, 10), V(-7, 10)])
	_poly(p, white, [V(-7, -3), V(-5, -9), V(0, -11), V(5, -9), V(7, -3), V(6, 5), V(-6, 5)])
	# Crne ruke i noge.
	_poly(p, black, [V(-8, 1), V(-4, 1), V(-4, 10), V(-8, 10)])
	_poly(p, black, [V(4, 1), V(8, 1), V(8, 10), V(4, 10)])
	# Crne usi.
	_circle(p, V(-6.4, -10), 3.6, black)
	_circle(p, V(6.4, -10), 3.6, black)
	# Crne mrlje oko ociju.
	_circle(p, V(-3.4, -6.6), 2.8, black)
	_circle(p, V(3.4, -6.6), 2.8, black)
	_circle(p, V(-3.4, -6.6), 1.3, white)
	_circle(p, V(3.4, -6.6), 1.3, white)
	_circle(p, V(-3.4, -6.6), 0.7, Color(0.1, 0.1, 0.1))
	_circle(p, V(3.4, -6.6), 0.7, Color(0.1, 0.1, 0.1))
	_poly(p, black, [V(-1.8, -3.4), V(1.8, -3.4), V(0, -1.4)])


## --- Deljeni delovi lica ---

func _face(p: Node2D, eye: Color, y: float, dx: float) -> void:
	_circle(p, V(-dx, y), 2.0, Color(0.98, 0.99, 0.96))
	_circle(p, V(dx, y), 2.0, Color(0.98, 0.99, 0.96))
	_circle(p, V(-dx, y + 0.2), 1.4, eye)
	_circle(p, V(dx, y + 0.2), 1.4, eye)
	_circle(p, V(-dx, y + 0.3), 0.7, Color(0.1, 0.1, 0.12))
	_circle(p, V(dx, y + 0.3), 0.7, Color(0.1, 0.1, 0.12))
	_circle(p, V(-dx - 0.6, y - 0.6), 0.6, Color(1, 1, 1))
	_circle(p, V(dx - 0.6, y - 0.6), 0.6, Color(1, 1, 1))


func _muzzle(p: Node2D, pale: Color, nose: Color) -> void:
	_poly(p, pale, [V(-3.6, -1.6), V(3.6, -1.6), V(3, 2.6), V(-3, 2.6)])
	_poly(p, nose, [V(-1.4, -1.4), V(1.4, -1.4), V(0, 0.6)])
	_poly(p, nose.darkened(0.2), [V(-1.2, 0.4), V(0.2, 0.4), V(0.2, 1), V(-1.2, 1)])
	_poly(p, nose.darkened(0.2), [V(-0.2, 0.4), V(1.2, 0.4), V(1.2, 1), V(-0.2, 1)])


## --- Helperi ---

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


func _poly(parent: Node, col: Color, pts: Array) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array(pts)
	parent.add_child(p)


func _circle(parent: Node, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var p := Polygon2D.new()
	p.color = col
	p.polygon = pts
	parent.add_child(p)
