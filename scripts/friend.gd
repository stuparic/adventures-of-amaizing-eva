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
	# --- Prijatelji sa novih ostrva ---
	"hobotnica": "hobotnicu Osmicu",
	"morskikonj": "morskog konjića Pega",
	"labud": "labuda Belka",
	"zmaj": "zmaja Oblačka",
	"slepimis": "slepog miša Šuška",
	"krtica": "krticu Kopalu",
	"jelen": "jelena Šumka",
	"vila": "vilu Zvončicu",
	"medvedic": "medvedića Šećerka",
	"vevericaB": "vevericu Bombonu",
	"vanzemaljac": "vanzemaljca Zvezdana",
	"robot": "robota Kockicu",
	"dabar": "dabra Gradišu",
	"vidra": "vidru Plivku",
	"crvenapanda": "crvenu pandu Riđu",
	"zmajcic": "zmajčića Bambusa",
	"mornarka": "sirenu Koralku",
	"rakic": "rakića Štipka",
	"feniks": "feniksa Žarka",
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
	# Glas imenuje TOG prijatelja ("...oslobodila si macu Carlija!").
	# Ako snimka nema, ide stari put: opsti glas ili fanfara.
	if not Audio.play_friend_voice(kind):
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
		"hobotnica":   _draw_octopus(body)
		"morskikonj":  _draw_seahorse(body)
		"labud":       _draw_swan(body)
		"zmaj":        _draw_dragon(body, Color(0.72, 0.84, 0.96), Color(0.55, 0.7, 0.9))
		"slepimis":    _draw_bat(body)
		"krtica":      _draw_mole(body)
		"jelen":       _draw_deer(body)
		"vila":        _draw_fairy(body)
		"medvedic":    _draw_bear_cub(body)
		"vevericaB":   _draw_squirrel(body)
		"vanzemaljac": _draw_alien(body)
		"robot":       _draw_robot(body)
		"dabar":       _draw_beaver(body)
		"vidra":       _draw_otter(body)
		"crvenapanda": _draw_red_panda(body)
		"zmajcic":     _draw_dragon(body, Color(0.6, 0.82, 0.45), Color(0.44, 0.66, 0.32))
		"mornarka":    _draw_mermaid(body)
		"rakic":       _draw_crab_friend(body)
		"feniks":      _draw_phoenix(body)
		_:          _draw_cat(body, Color(0.98, 0.68, 0.32), Color(0.86, 0.55, 0.24))


func _draw_cat(p: Node2D, fur: Color, dark: Color) -> void:
	Draw2D.poly(p, dark, [V(-9, 0), V(-7, -6), V(-3, -10), V(3, -10), V(7, -6), V(9, 0), V(8, 10), V(-8, 10)])
	Draw2D.poly(p, fur, [V(-8, -1), V(-6, -6), V(-3, -9), V(3, -9), V(6, -6), V(8, -1), V(7, 9), V(-7, 9)])
	# Usi.
	Draw2D.poly(p, fur, [V(-7, -8), V(-5, -14), V(-1, -9)])
	Draw2D.poly(p, fur, [V(7, -8), V(5, -14), V(1, -9)])
	Draw2D.poly(p, Color(0.96, 0.6, 0.62), [V(-5.6, -8.6), V(-4.6, -12), V(-2.6, -9.2)])
	Draw2D.poly(p, Color(0.96, 0.6, 0.62), [V(5.6, -8.6), V(4.6, -12), V(2.6, -9.2)])
	# Rep.
	Draw2D.poly(p, fur, [V(-8, 4), V(-14, -1), V(-13, -3), V(-7, 2)])
	_face(p, Color(0.3, 0.66, 0.4), -4.5, 3.4)
	_muzzle(p, Color(1, 0.95, 0.88), Color(0.9, 0.45, 0.5))


func _draw_dog(p: Node2D) -> void:
	var fur := Color(0.85, 0.66, 0.4)
	var dark := Color(0.68, 0.5, 0.3)
	Draw2D.poly(p, dark, [V(-9, 0), V(-7, -7), V(0, -11), V(7, -7), V(9, 0), V(8, 10), V(-8, 10)])
	Draw2D.poly(p, fur, [V(-8, -1), V(-6, -7), V(0, -10), V(6, -7), V(8, -1), V(7, 9), V(-7, 9)])
	# Klempave usi.
	Draw2D.poly(p, dark, [V(-8, -6), V(-12, -2), V(-11, 4), V(-6, 0)])
	Draw2D.poly(p, dark, [V(8, -6), V(12, -2), V(11, 4), V(6, 0)])
	# Rep gore.
	Draw2D.poly(p, fur, [V(-8, 2), V(-13, -4), V(-11, -6), V(-7, 0)])
	_face(p, Color(0.35, 0.24, 0.16), -4.2, 3.2)
	_muzzle(p, Color(0.96, 0.9, 0.8), Color(0.25, 0.2, 0.18))
	# Mrlja oko oka.
	Draw2D.poly(p, dark, [V(1.4, -6), V(6.4, -6.6), V(6.8, -2), V(1.6, -1.6)])


func _draw_bunny(p: Node2D) -> void:
	var fur := Color(0.97, 0.95, 0.94)
	var shade := Color(0.87, 0.84, 0.85)
	var pink := Color(0.98, 0.72, 0.76)

	# Repic - pahuljast, iza tela.
	_circle(p, V(-8.5, 5.5), 4.2, shade)
	_circle(p, V(-8.5, 5.0), 3.4, Color(1, 1, 1))

	# Stopala - ispod tela, siroka.
	Draw2D.poly(p, shade, [V(-7, 8), V(-1.5, 8), V(-1, 11.5), V(-7.5, 11.5)])
	Draw2D.poly(p, shade, [V(1.5, 8), V(7, 8), V(7.5, 11.5), V(1, 11.5)])
	Draw2D.poly(p, fur, [V(-6.6, 8), V(-2, 8), V(-1.6, 10.8), V(-7, 10.8)])
	Draw2D.poly(p, fur, [V(2, 8), V(6.6, 8), V(7, 10.8), V(1.6, 10.8)])
	# Prstici na stopalima.
	for x in [-5.4, -4.0, 4.0, 5.4]:
		_circle(p, V(x, 10.4), 0.8, pink)

	# Telo - kruskasto, sire dole.
	Draw2D.poly(p, shade, [V(-7.5, -3), V(-5.5, -8), V(0, -10.5), V(5.5, -8),
		V(7.5, -3), V(8, 5), V(5, 9), V(-5, 9), V(-8, 5)])
	Draw2D.poly(p, fur, [V(-6.6, -4), V(-4.8, -8), V(0, -9.8), V(4.8, -8),
		V(6.6, -4), V(7, 4.6), V(4.4, 8.2), V(-4.4, 8.2), V(-7, 4.6)])
	# Svetli trbuh.
	Draw2D.poly(p, Color(1, 1, 1), [V(-3.4, 0), V(3.4, 0), V(2.8, 7.6), V(-2.8, 7.6)])

	# Prednje sapice.
	_circle(p, V(-5.2, 3.4), 2.2, fur)
	_circle(p, V(5.2, 3.4), 2.2, fur)

	# Dugacke usi - blago razmaknute, sa roze unutrasnjoscu.
	Draw2D.poly(p, shade, [V(-5.4, -8), V(-8.4, -22), V(-4.6, -24.5), V(-2, -9)])
	Draw2D.poly(p, shade, [V(5.4, -8), V(8.4, -22), V(4.6, -24.5), V(2, -9)])
	Draw2D.poly(p, fur, [V(-5, -8.6), V(-7.8, -21.6), V(-4.8, -23.6), V(-2.6, -9.4)])
	Draw2D.poly(p, fur, [V(5, -8.6), V(7.8, -21.6), V(4.8, -23.6), V(2.6, -9.4)])
	Draw2D.poly(p, pink, [V(-4.8, -10.4), V(-6.6, -20.4), V(-4.9, -21.6), V(-3.4, -10.8)])
	Draw2D.poly(p, pink, [V(4.8, -10.4), V(6.6, -20.4), V(4.9, -21.6), V(3.4, -10.8)])

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
	Draw2D.poly(p, pink.darkened(0.1), [V(-1.1, -5.6), V(1.1, -5.6), V(0, -4.2)])
	Draw2D.poly(p, Color(0.6, 0.42, 0.44), [V(-0.3, -4.4), V(0.3, -4.4), V(0.3, -3.2), V(-0.3, -3.2)])
	Draw2D.poly(p, Color(0.6, 0.42, 0.44), [V(-0.3, -3.5), V(-2.4, -2.4), V(-2.1, -1.9), V(-0.1, -3.0)])
	Draw2D.poly(p, Color(0.6, 0.42, 0.44), [V(0.3, -3.5), V(2.4, -2.4), V(2.1, -1.9), V(0.1, -3.0)])

	# Brkovi.
	for sy in [-0.5, 0.6]:
		Draw2D.poly(p, Color(0.75, 0.7, 0.7, 0.8), [
			V(-2.6, -4.2 + sy), V(-7.4, -5.0 + sy * 1.5),
			V(-7.4, -4.5 + sy * 1.5), V(-2.6, -3.8 + sy)])
		Draw2D.poly(p, Color(0.75, 0.7, 0.7, 0.8), [
			V(2.6, -4.2 + sy), V(7.4, -5.0 + sy * 1.5),
			V(7.4, -4.5 + sy * 1.5), V(2.6, -3.8 + sy)])

	# Zubici - zeka.
	Draw2D.poly(p, Color(1, 1, 1), [V(-1.0, -2.6), V(-0.15, -2.6), V(-0.15, -1.2), V(-1.0, -1.2)])
	Draw2D.poly(p, Color(1, 1, 1), [V(0.15, -2.6), V(1.0, -2.6), V(1.0, -1.2), V(0.15, -1.2)])


func _draw_bird(p: Node2D) -> void:
	var fur := Color(0.35, 0.68, 0.92)
	var dark := Color(0.24, 0.52, 0.78)
	Draw2D.poly(p, dark, [V(-7, -2), V(-5, -8), V(0, -11), V(5, -8), V(7, -2), V(5, 9), V(-5, 9)])
	Draw2D.poly(p, fur, [V(-6, -3), V(-4, -8), V(0, -10), V(4, -8), V(6, -3), V(4, 8), V(-4, 8)])
	# Krila.
	Draw2D.poly(p, dark, [V(-6, -2), V(-12, 2), V(-10, 6), V(-5, 4)])
	Draw2D.poly(p, dark, [V(6, -2), V(12, 2), V(10, 6), V(5, 4)])
	# Perjanica.
	Draw2D.poly(p, Color(0.98, 0.78, 0.28), [V(-2, -10), V(0, -16), V(2, -10)])
	# Kljun.
	Draw2D.poly(p, Color(0.98, 0.72, 0.2), [V(-2, -3), V(-6.5, -1), V(-2, 1)])
	_face(p, Color(0.16, 0.18, 0.22), -4.0, 2.6)
	# Noge.
	Draw2D.poly(p, Color(0.95, 0.7, 0.2), [V(-3, 8), V(-2, 8), V(-2, 12), V(-3, 12)])
	Draw2D.poly(p, Color(0.95, 0.7, 0.2), [V(2, 8), V(3, 8), V(3, 12), V(2, 12)])


func _draw_squirrel(p: Node2D) -> void:
	var fur := Color(0.82, 0.5, 0.26)
	var dark := Color(0.66, 0.38, 0.2)
	# Veliki rep.
	Draw2D.poly(p, dark, [V(-6, 6), V(-16, 0), V(-18, -10), V(-12, -14), V(-7, -6), V(-5, 0)])
	Draw2D.poly(p, fur, [V(-6, 4), V(-14, -1), V(-15, -9), V(-11, -12), V(-7, -5)])
	Draw2D.poly(p, dark, [V(-7, -2), V(-6, -8), V(0, -11), V(6, -8), V(8, -2), V(7, 10), V(-6, 10)])
	Draw2D.poly(p, fur, [V(-6, -3), V(-5, -8), V(0, -10), V(5, -8), V(7, -3), V(6, 9), V(-5, 9)])
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
		Draw2D.poly(p, spine, [V(x - 1.4, -2), V(x, -11 - absf(x) * 0.25), V(x + 1.4, -2)])
	for i in 8:
		var x := -8.0 + float(i) * 2.3
		Draw2D.poly(p, spine.lightened(0.15), [V(x - 1.2, 0), V(x, -7 - absf(x) * 0.2), V(x + 1.2, 0)])
	Draw2D.poly(p, fur, [V(-9, -2), V(9, -2), V(8, 10), V(-8, 10)])
	# Lice ide desno - mala glavica.
	Draw2D.poly(p, fur, [V(4, -3), V(11, -1), V(11, 5), V(4, 6)])
	_circle(p, V(9.6, 1.4), 1.2, Color(0.2, 0.16, 0.16))
	_circle(p, V(6.6, -0.4), 1.5, Color(0.16, 0.14, 0.14))
	_circle(p, V(6.1, -0.9), 0.6, Color(1, 1, 1))


func _draw_turtle(p: Node2D) -> void:
	var shell := Color(0.35, 0.6, 0.35)
	var shell_l := Color(0.5, 0.75, 0.45)
	var skin := Color(0.5, 0.78, 0.45)
	# Noge.
	Draw2D.poly(p, skin, [V(-8, 4), V(-4, 4), V(-4, 10), V(-8, 10)])
	Draw2D.poly(p, skin, [V(4, 4), V(8, 4), V(8, 10), V(4, 10)])
	# Oklop.
	Draw2D.poly(p, shell, [V(-10, 4), V(-9, -3), V(-4, -8), V(4, -8), V(9, -3), V(10, 4)])
	for i in 3:
		var x := -4.5 + float(i) * 4.5
		Draw2D.poly(p, shell_l, [V(x - 2, 2), V(x - 1.5, -4), V(x + 1.5, -4), V(x + 2, 2)])
	# Glava.
	Draw2D.poly(p, skin, [V(-3, -8), V(3, -8), V(4, -13), V(-4, -13)])
	_circle(p, V(-1.8, -11), 1.3, Color(0.15, 0.15, 0.2))
	_circle(p, V(1.8, -11), 1.3, Color(0.15, 0.15, 0.2))
	Draw2D.poly(p, Color(0.9, 0.85, 0.5), [V(-1.6, -8.6), V(1.6, -8.6), V(0, -7)])


func _draw_dolphin(p: Node2D) -> void:
	var body := Color(0.5, 0.7, 0.86)
	var dark := Color(0.36, 0.56, 0.75)
	var belly := Color(0.92, 0.96, 0.99)
	Draw2D.poly(p, dark, [V(-12, 2), V(-6, -6), V(4, -8), V(11, -3), V(12, 2), V(6, 7), V(-6, 8)])
	Draw2D.poly(p, body, [V(-11, 1), V(-5, -5), V(4, -7), V(10, -3), V(11, 1), V(5, 6), V(-5, 7)])
	Draw2D.poly(p, belly, [V(-8, 3), V(6, 3), V(4, 7), V(-5, 7)])
	# Peraje na vrhu i rep.
	Draw2D.poly(p, dark, [V(-1, -7), V(2, -14), V(5, -6)])
	Draw2D.poly(p, dark, [V(-11, 0), V(-18, -4), V(-16, 3), V(-18, 7), V(-11, 4)])
	# Kljun.
	Draw2D.poly(p, body, [V(10, -1), V(16, 1), V(10, 3)])
	_circle(p, V(6, -2.6), 1.6, Color(0.15, 0.18, 0.24))
	_circle(p, V(5.5, -3.1), 0.7, Color(1, 1, 1))
	Draw2D.poly(p, dark, [V(2, -1), V(7, -1), V(7, 0), V(2, 0)])


func _draw_penguin(p: Node2D) -> void:
	var black := Color(0.22, 0.24, 0.3)
	var white := Color(0.96, 0.97, 0.99)
	Draw2D.poly(p, black, [V(-8, -3), V(-6, -9), V(0, -12), V(6, -9), V(8, -3), V(7, 10), V(-7, 10)])
	Draw2D.poly(p, white, [V(-5, -4), V(0, -8), V(5, -4), V(5, 9), V(-5, 9)])
	# Krila.
	Draw2D.poly(p, black, [V(-8, -2), V(-11, 3), V(-9, 8), V(-6, 4)])
	Draw2D.poly(p, black, [V(8, -2), V(11, 3), V(9, 8), V(6, 4)])
	# Kljun i noge.
	Draw2D.poly(p, Color(0.98, 0.7, 0.2), [V(-2, -5), V(2, -5), V(0, -1.5)])
	Draw2D.poly(p, Color(0.98, 0.7, 0.2), [V(-6, 10), V(-1, 10), V(-2, 13), V(-6, 13)])
	Draw2D.poly(p, Color(0.98, 0.7, 0.2), [V(1, 10), V(6, 10), V(6, 13), V(2, 13)])
	_circle(p, V(-2.6, -7), 1.5, Color(0.1, 0.1, 0.14))
	_circle(p, V(2.6, -7), 1.5, Color(0.1, 0.1, 0.14))
	_circle(p, V(-3.1, -7.5), 0.7, white)
	_circle(p, V(2.1, -7.5), 0.7, white)


func _draw_fox(p: Node2D) -> void:
	var fur := Color(0.92, 0.52, 0.24)
	var dark := Color(0.76, 0.38, 0.16)
	var white := Color(0.98, 0.95, 0.9)
	# Veliki rep sa belim vrhom.
	Draw2D.poly(p, dark, [V(-7, 6), V(-16, 2), V(-19, -6), V(-13, -9), V(-6, -2)])
	Draw2D.poly(p, white, [V(-16, 1), V(-19, -6), V(-15, -8), V(-14, -1)])
	Draw2D.poly(p, dark, [V(-8, -2), V(-6, -8), V(0, -11), V(6, -8), V(8, -2), V(7, 10), V(-7, 10)])
	Draw2D.poly(p, fur, [V(-7, -3), V(-5, -8), V(0, -10), V(5, -8), V(7, -3), V(6, 9), V(-6, 9)])
	Draw2D.poly(p, white, [V(-4, 1), V(4, 1), V(3, 9), V(-3, 9)])
	# Siljate usi.
	Draw2D.poly(p, fur, [V(-7, -8), V(-6, -16), V(-1, -9)])
	Draw2D.poly(p, fur, [V(7, -8), V(6, -16), V(1, -9)])
	Draw2D.poly(p, Color(0.3, 0.24, 0.24), [V(-5.8, -9), V(-5.2, -14), V(-2.6, -9.6)])
	Draw2D.poly(p, Color(0.3, 0.24, 0.24), [V(5.8, -9), V(5.2, -14), V(2.6, -9.6)])
	_face(p, Color(0.28, 0.2, 0.16), -4.2, 3.0)
	_muzzle(p, white, Color(0.2, 0.16, 0.16))


func _draw_owl(p: Node2D) -> void:
	var fur := Color(0.72, 0.58, 0.42)
	var dark := Color(0.56, 0.44, 0.3)
	var pale := Color(0.9, 0.84, 0.72)
	Draw2D.poly(p, dark, [V(-9, -4), V(-7, -11), V(0, -14), V(7, -11), V(9, -4), V(8, 9), V(-8, 9)])
	Draw2D.poly(p, fur, [V(-8, -5), V(-6, -10), V(0, -13), V(6, -10), V(8, -5), V(7, 8), V(-7, 8)])
	# Perje na grudima.
	for i in 3:
		for j in 2:
			_circle(p, V(-3.5 + float(j) * 7.0 - float(i % 2) * 3.5, -1.0 + float(i) * 3.4),
				2.0, pale)
	# Cuperci-usi.
	Draw2D.poly(p, fur, [V(-7, -10), V(-8, -17), V(-3, -12)])
	Draw2D.poly(p, fur, [V(7, -10), V(8, -17), V(3, -12)])
	# Velike oci - sova.
	_circle(p, V(-3.6, -7), 3.6, pale)
	_circle(p, V(3.6, -7), 3.6, pale)
	_circle(p, V(-3.6, -7), 2.2, Color(0.98, 0.78, 0.2))
	_circle(p, V(3.6, -7), 2.2, Color(0.98, 0.78, 0.2))
	_circle(p, V(-3.6, -7), 1.2, Color(0.1, 0.1, 0.12))
	_circle(p, V(3.6, -7), 1.2, Color(0.1, 0.1, 0.12))
	Draw2D.poly(p, Color(0.95, 0.7, 0.24), [V(-1.4, -5), V(1.4, -5), V(0, -2)])
	# Krila.
	Draw2D.poly(p, dark, [V(-8, -4), V(-11, 2), V(-9, 7), V(-6, 2)])
	Draw2D.poly(p, dark, [V(8, -4), V(11, 2), V(9, 7), V(6, 2)])


func _draw_koala(p: Node2D) -> void:
	var fur := Color(0.7, 0.72, 0.75)
	var dark := Color(0.55, 0.57, 0.6)
	var pale := Color(0.9, 0.91, 0.93)
	Draw2D.poly(p, dark, [V(-8, -2), V(-6, -9), V(0, -12), V(6, -9), V(8, -2), V(7, 10), V(-7, 10)])
	Draw2D.poly(p, fur, [V(-7, -3), V(-5, -9), V(0, -11), V(5, -9), V(7, -3), V(6, 9), V(-6, 9)])
	Draw2D.poly(p, pale, [V(-4, 1), V(4, 1), V(3, 9), V(-3, 9)])
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
	Draw2D.poly(p, Color(0.2, 0.18, 0.2), [V(-2.4, -4), V(2.4, -4), V(1.8, -0.6), V(-1.8, -0.6)])


func _draw_panda(p: Node2D) -> void:
	var white := Color(0.96, 0.96, 0.95)
	var black := Color(0.2, 0.2, 0.22)
	Draw2D.poly(p, black, [V(-8, -2), V(-6, -9), V(0, -12), V(6, -9), V(8, -2), V(7, 10), V(-7, 10)])
	Draw2D.poly(p, white, [V(-7, -3), V(-5, -9), V(0, -11), V(5, -9), V(7, -3), V(6, 5), V(-6, 5)])
	# Crne ruke i noge.
	Draw2D.poly(p, black, [V(-8, 1), V(-4, 1), V(-4, 10), V(-8, 10)])
	Draw2D.poly(p, black, [V(4, 1), V(8, 1), V(8, 10), V(4, 10)])
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
	Draw2D.poly(p, black, [V(-1.8, -3.4), V(1.8, -3.4), V(0, -1.4)])


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
	Draw2D.poly(p, pale, [V(-3.6, -1.6), V(3.6, -1.6), V(3, 2.6), V(-3, 2.6)])
	Draw2D.poly(p, nose, [V(-1.4, -1.4), V(1.4, -1.4), V(0, 0.6)])
	Draw2D.poly(p, nose.darkened(0.2), [V(-1.2, 0.4), V(0.2, 0.4), V(0.2, 1), V(-1.2, 1)])
	Draw2D.poly(p, nose.darkened(0.2), [V(-0.2, 0.4), V(1.2, 0.4), V(1.2, 1), V(-0.2, 1)])


## --- Helperi ---

## --- Prijatelji sa novih ostrva ---
##
## Isti "recept" kao ostali: telo u prostoru ~±14px, pa detalji, pa oci sa
## belom tackom (zbog toga likovi izgledaju zivi).

func _draw_octopus(p: Node2D) -> void:
	var fur := Color(0.85, 0.45, 0.7)
	var dark := Color(0.7, 0.32, 0.58)
	# Glava - velika kupola.
	Draw2D.poly(p, dark, [V(-9, 2), V(-8, -6), V(-4, -11), V(4, -11), V(8, -6), V(9, 2)])
	_circle(p, V(0, -4), 8.6, fur)
	# Osam krakova - cetiri para, naizmenicno duzi.
	for i in 8:
		var t := (float(i) - 3.5) / 3.5
		var x := t * 8.0
		var h: float = 8.0 + (3.0 if i % 2 == 0 else 0.0)
		Draw2D.poly(p, dark, [
			V(x - 1.6, 2), V(x + 1.6, 2),
			V(x + 2.4, 2.0 + h), V(x - 0.8, 2.0 + h)])
		_circle(p, V(x + 0.8, 2.0 + h), 1.8, fur)
	# Oci.
	_circle(p, V(-3.4, -6), 2.6, Color(1, 1, 1))
	_circle(p, V(3.4, -6), 2.6, Color(1, 1, 1))
	_circle(p, V(-3.4, -6), 1.4, Color(0.12, 0.1, 0.14))
	_circle(p, V(3.4, -6), 1.4, Color(0.12, 0.1, 0.14))
	_circle(p, V(-4.0, -6.7), 0.7, Color(1, 1, 1))
	# Rumen.
	_circle(p, V(-6.4, -2.4), 1.5, Color(1, 0.6, 0.75, 0.6))
	_circle(p, V(6.4, -2.4), 1.5, Color(1, 0.6, 0.75, 0.6))


func _draw_seahorse(p: Node2D) -> void:
	var fur := Color(0.98, 0.78, 0.35)
	var dark := Color(0.86, 0.62, 0.22)
	# Telo u obliku S - savijen rep.
	Draw2D.poly(p, dark, [
		V(-5, -10), V(3, -11), V(6, -5), V(4, 2), V(6, 8), V(2, 11),
		V(-2, 9), V(0, 4), V(-3, 0), V(-6, -4)])
	Draw2D.poly(p, fur, [
		V(-4, -9), V(2, -10), V(5, -5), V(3, 2), V(5, 7), V(2, 9.6),
		V(-1, 8), V(0.6, 3.6), V(-2, 0), V(-5, -4)])
	# Grebeni na ledjima.
	for i in 4:
		Draw2D.poly(p, dark, [
			V(3.4, -8.0 + float(i) * 3.4), V(6.6, -7.0 + float(i) * 3.4),
			V(3.4, -5.4 + float(i) * 3.4)])
	# Rilica.
	Draw2D.poly(p, fur, [V(-5, -8), V(-11, -6.4), V(-5, -5)])
	# Oko.
	_circle(p, V(-2.4, -8), 2.0, Color(1, 1, 1))
	_circle(p, V(-2.4, -8), 1.1, Color(0.12, 0.1, 0.14))
	_circle(p, V(-2.9, -8.5), 0.6, Color(1, 1, 1))


func _draw_swan(p: Node2D) -> void:
	var fur := Color(0.99, 0.99, 1.0)
	var dark := Color(0.88, 0.9, 0.95)
	# Telo - okruglo, nisko.
	Draw2D.poly(p, dark, [V(-9, 1), V(-7, -4), V(0, -6), V(8, -3), V(9, 3), V(6, 9), V(-7, 9)])
	_circle(p, V(-1, 2), 7.6, fur)
	# Dugi vrat u luku.
	Draw2D.poly(p, fur, [
		V(2, -3), V(5, -8), V(6, -14), V(4, -17),
		V(6.6, -17.6), V(8.6, -13.6), V(7.4, -7), V(4.4, -2)])
	# Glava i kljun.
	_circle(p, V(5.4, -17.4), 2.8, fur)
	Draw2D.poly(p, Color(0.98, 0.66, 0.2), [V(3.2, -17.8), V(-0.4, -16.8), V(3.2, -15.8)])
	# Krilo - naslagana pera.
	for i in 3:
		Draw2D.poly(p, dark, [
			V(-7.0 + float(i) * 2.4, -1.0), V(-1.0 + float(i) * 2.4, 1.4),
			V(-6.0 + float(i) * 2.4, 5.4)])
	# Oko.
	_circle(p, V(6.2, -18.0), 1.0, Color(0.12, 0.1, 0.14))


func _draw_dragon(p: Node2D, fur: Color, dark: Color) -> void:
	# Telo.
	Draw2D.poly(p, dark, [V(-9, -3), V(-7, -10), V(0, -13), V(7, -10), V(9, -3), V(8, 9), V(-8, 9)])
	Draw2D.poly(p, fur, [V(-8, -4), V(-6, -9), V(0, -12), V(6, -9), V(8, -4), V(7, 8), V(-7, 8)])
	# Krila - poluprozirna, kao kod zmaja.
	Draw2D.poly(p, Color(fur.r, fur.g, fur.b, 0.55), [
		V(-7, -3), V(-15, -9), V(-16, -1), V(-11, 3)])
	Draw2D.poly(p, Color(fur.r, fur.g, fur.b, 0.55), [
		V(7, -3), V(15, -9), V(16, -1), V(11, 3)])
	# Grebeni na glavi.
	for i in 3:
		Draw2D.poly(p, dark, [
			V(-3.0 + float(i) * 3.0, -12.0), V(-2.0 + float(i) * 3.0, -16.4),
			V(-0.4 + float(i) * 3.0, -12.0)])
	# Trbuh.
	Draw2D.poly(p, Color(0.99, 0.95, 0.85, 0.8), [V(-4, 0), V(4, 0), V(3.4, 7.6), V(-3.4, 7.6)])
	# Oci i nozdrve.
	_circle(p, V(-3.4, -7), 2.4, Color(1, 1, 1))
	_circle(p, V(3.4, -7), 2.4, Color(1, 1, 1))
	_circle(p, V(-3.4, -7), 1.3, Color(0.12, 0.1, 0.14))
	_circle(p, V(3.4, -7), 1.3, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.9, -7.6), 0.6, Color(1, 1, 1))
	_circle(p, V(-1.6, -3.4), 0.7, dark)
	_circle(p, V(1.6, -3.4), 0.7, dark)


func _draw_bat(p: Node2D) -> void:
	var fur := Color(0.52, 0.44, 0.6)
	var dark := Color(0.38, 0.32, 0.46)
	# Krila - velika, sa tri "prsta".
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, dark, [
			V(side * 6, -4), V(side * 17, -8), V(side * 14, -2),
			V(side * 16, 1), V(side * 12, 3), V(side * 13, 6), V(side * 7, 4)])
	# Telo.
	Draw2D.poly(p, dark, [V(-7, -4), V(-5, -10), V(0, -12), V(5, -10), V(7, -4), V(6, 7), V(-6, 7)])
	Draw2D.poly(p, fur, [V(-6, -5), V(-4, -9), V(0, -11), V(4, -9), V(6, -5), V(5, 6), V(-5, 6)])
	# Velike siljate usi.
	Draw2D.poly(p, fur, [V(-5, -9), V(-7, -17), V(-1, -11)])
	Draw2D.poly(p, fur, [V(5, -9), V(7, -17), V(1, -11)])
	# Oci.
	_circle(p, V(-2.6, -6.4), 2.2, Color(1, 1, 1))
	_circle(p, V(2.6, -6.4), 2.2, Color(1, 1, 1))
	_circle(p, V(-2.6, -6.4), 1.2, Color(0.12, 0.1, 0.14))
	_circle(p, V(2.6, -6.4), 1.2, Color(0.12, 0.1, 0.14))
	# Zubici - simpaticni, ne strasni.
	Draw2D.poly(p, Color(1, 1, 1), [V(-1.6, -2.4), V(-0.6, -2.4), V(-1.1, -0.8)])
	Draw2D.poly(p, Color(1, 1, 1), [V(0.6, -2.4), V(1.6, -2.4), V(1.1, -0.8)])


func _draw_mole(p: Node2D) -> void:
	var fur := Color(0.55, 0.45, 0.4)
	var dark := Color(0.42, 0.34, 0.3)
	Draw2D.poly(p, dark, [V(-9, -2), V(-7, -9), V(0, -12), V(7, -9), V(9, -2), V(8, 9), V(-8, 9)])
	Draw2D.poly(p, fur, [V(-8, -3), V(-6, -8), V(0, -11), V(6, -8), V(8, -3), V(7, 8), V(-7, 8)])
	# Ruzicasta rilica.
	_circle(p, V(0, -3.6), 3.0, Color(0.95, 0.68, 0.68))
	_circle(p, V(-1.0, -4.2), 0.7, Color(0.7, 0.42, 0.44))
	_circle(p, V(1.0, -4.2), 0.7, Color(0.7, 0.42, 0.44))
	# Zatvorene oci - krtica ne vidi (crtice, ne krugovi).
	Draw2D.poly(p, Color(0.2, 0.16, 0.16), [V(-5.4, -7.4), V(-1.8, -7.4), V(-1.8, -6.6), V(-5.4, -6.6)])
	Draw2D.poly(p, Color(0.2, 0.16, 0.16), [V(1.8, -7.4), V(5.4, -7.4), V(5.4, -6.6), V(1.8, -6.6)])
	# Velike kandze za kopanje.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, Color(0.9, 0.88, 0.82), [
			V(side * 7, 2), V(side * 12, 4), V(side * 11.4, 6), V(side * 7, 6)])
		for k in 3:
			Draw2D.poly(p, Color(0.98, 0.97, 0.92), [
				V(side * 11.0, 3.4 + float(k) * 1.0), V(side * 13.6, 3.8 + float(k) * 1.0),
				V(side * 11.0, 4.4 + float(k) * 1.0)])


func _draw_deer(p: Node2D) -> void:
	var fur := Color(0.8, 0.6, 0.42)
	var dark := Color(0.65, 0.46, 0.3)
	var pale := Color(0.95, 0.9, 0.82)
	Draw2D.poly(p, dark, [V(-8, -3), V(-6, -10), V(0, -13), V(6, -10), V(8, -3), V(7, 9), V(-7, 9)])
	Draw2D.poly(p, fur, [V(-7, -4), V(-5, -9), V(0, -12), V(5, -9), V(7, -4), V(6, 8), V(-6, 8)])
	# Rogovi - grananje, po dve grane.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, Color(0.72, 0.58, 0.36), [
			V(side * 3.4, -11), V(side * 4.6, -19), V(side * 2.6, -19), V(side * 1.8, -11)])
		Draw2D.poly(p, Color(0.72, 0.58, 0.36), [
			V(side * 4.0, -15.4), V(side * 8.4, -18.4), V(side * 7.6, -16.6)])
		Draw2D.poly(p, Color(0.72, 0.58, 0.36), [
			V(side * 4.4, -18.0), V(side * 7.4, -22.4), V(side * 6.2, -20.0)])
	# Usi.
	Draw2D.poly(p, fur, [V(-6, -9), V(-11, -11), V(-6, -6)])
	Draw2D.poly(p, fur, [V(6, -9), V(11, -11), V(6, -6)])
	# Bele pege.
	for i in 4:
		_circle(p, V(-3.4 + float(i % 2) * 6.0, 0.6 + float(i) * 2.0), 1.1, pale)
	# Oci i nos.
	_circle(p, V(-2.8, -7), 2.2, Color(1, 1, 1))
	_circle(p, V(2.8, -7), 2.2, Color(1, 1, 1))
	_circle(p, V(-2.8, -7), 1.2, Color(0.12, 0.1, 0.14))
	_circle(p, V(2.8, -7), 1.2, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.3, -7.6), 0.6, Color(1, 1, 1))
	_circle(p, V(0, -3.4), 1.4, Color(0.3, 0.22, 0.2))


func _draw_fairy(p: Node2D) -> void:
	var dress := Color(0.85, 0.5, 0.85)
	var skin := Color(0.99, 0.85, 0.74)
	# Krila - dva para, prozirna.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, Color(0.8, 0.92, 1.0, 0.6), [
			V(side * 4, -4), V(side * 15, -12), V(side * 16, -3), V(side * 6, 0)])
		Draw2D.poly(p, Color(0.9, 0.8, 1.0, 0.5), [
			V(side * 4, -1), V(side * 13, 2), V(side * 12, 8), V(side * 5, 3)])
	# Haljina - zvonasta.
	Draw2D.poly(p, dress, [V(-3, -5), V(3, -5), V(7, 9), V(-7, 9)])
	Draw2D.poly(p, Color(0.95, 0.7, 0.95), [V(-7, 9), V(7, 9), V(6, 11), V(-6, 11)])
	# Glava.
	_circle(p, V(0, -9), 5.0, skin)
	# Kosa.
	Draw2D.poly(p, Color(0.98, 0.85, 0.35), [
		V(-5, -9), V(-5.4, -14.4), V(0, -16), V(5.4, -14.4), V(5, -9),
		V(3, -12), V(-3, -12)])
	# Oci i osmeh.
	_circle(p, V(-1.8, -9), 1.5, Color(1, 1, 1))
	_circle(p, V(1.8, -9), 1.5, Color(1, 1, 1))
	_circle(p, V(-1.8, -9), 0.8, Color(0.12, 0.1, 0.14))
	_circle(p, V(1.8, -9), 0.8, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.6, -7.4), 1.1, Color(1, 0.6, 0.7, 0.6))
	_circle(p, V(3.6, -7.4), 1.1, Color(1, 0.6, 0.7, 0.6))
	# Carobni stapic sa zvezdicom.
	Draw2D.poly(p, Color(0.9, 0.85, 0.7), [V(7, -2), V(8.4, -2), V(9.6, 6), V(8.2, 6)])
	var st := PackedVector2Array()
	for k in 10:
		var a := TAU * float(k) / 10.0 - PI * 0.5
		var rr: float = 3.4 if k % 2 == 0 else 1.5
		st.append(V(7.7, -4.4) + Vector2(cos(a), sin(a)) * rr)
	Draw2D.poly(p, Color(1, 0.95, 0.4), st)


func _draw_bear_cub(p: Node2D) -> void:
	var fur := Color(0.76, 0.56, 0.4)
	var dark := Color(0.6, 0.42, 0.3)
	var pale := Color(0.95, 0.86, 0.74)
	Draw2D.poly(p, dark, [V(-9, -2), V(-7, -9), V(0, -12), V(7, -9), V(9, -2), V(8, 9), V(-8, 9)])
	Draw2D.poly(p, fur, [V(-8, -3), V(-6, -8), V(0, -11), V(6, -8), V(8, -3), V(7, 8), V(-7, 8)])
	# Okrugle usi.
	_circle(p, V(-6, -9), 3.2, fur)
	_circle(p, V(6, -9), 3.2, fur)
	_circle(p, V(-6, -9), 1.7, Color(0.95, 0.72, 0.66))
	_circle(p, V(6, -9), 1.7, Color(0.95, 0.72, 0.66))
	# Svetla mrlja oko rilice.
	_circle(p, V(0, -3.0), 3.6, pale)
	_circle(p, V(0, -4.0), 1.3, Color(0.3, 0.22, 0.2))
	Draw2D.poly(p, Color(0.3, 0.22, 0.2), [V(-1.6, -1.6), V(1.6, -1.6), V(0, -0.4)])
	# Oci.
	_circle(p, V(-3.0, -7), 2.2, Color(1, 1, 1))
	_circle(p, V(3.0, -7), 2.2, Color(1, 1, 1))
	_circle(p, V(-3.0, -7), 1.2, Color(0.12, 0.1, 0.14))
	_circle(p, V(3.0, -7), 1.2, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.5, -7.6), 0.6, Color(1, 1, 1))
	# Trbuh.
	_circle(p, V(0, 3.4), 4.2, pale)


func _draw_alien(p: Node2D) -> void:
	var skin := Color(0.55, 0.85, 0.5)
	var dark := Color(0.4, 0.7, 0.38)
	# Telo - usko.
	Draw2D.poly(p, dark, [V(-5, -2), V(5, -2), V(7, 9), V(-7, 9)])
	Draw2D.poly(p, skin, [V(-4, -2), V(4, -2), V(6, 8), V(-6, 8)])
	# Velika glava - sira nego telo.
	_circle(p, V(0, -8), 8.0, dark)
	_circle(p, V(0, -8.6), 7.2, skin)
	# Antene sa kuglicama.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, dark, [
			V(side * 2.6, -14), V(side * 4.6, -19), V(side * 3.4, -19.4), V(side * 1.4, -14.4)])
		_circle(p, V(side * 4.8, -20.2), 1.9, Color(0.98, 0.85, 0.35))
	# Velike crne oci - kao kod vanzemaljca.
	var eye := PackedVector2Array()
	for k in 12:
		var a := TAU * float(k) / 12.0
		eye.append(V(-3.4, -9) + Vector2(cos(a) * 2.8, sin(a) * 3.6))
	Draw2D.poly(p, Color(0.1, 0.12, 0.16), eye)
	var eye2 := PackedVector2Array()
	for k in 12:
		var a := TAU * float(k) / 12.0
		eye2.append(V(3.4, -9) + Vector2(cos(a) * 2.8, sin(a) * 3.6))
	Draw2D.poly(p, Color(0.1, 0.12, 0.16), eye2)
	_circle(p, V(-4.2, -10.4), 0.9, Color(1, 1, 1))
	_circle(p, V(2.6, -10.4), 0.9, Color(1, 1, 1))
	# Osmeh.
	Draw2D.poly(p, dark, [V(-2.4, -4.4), V(2.4, -4.4), V(0, -2.8)])


func _draw_robot(p: Node2D) -> void:
	var body_col := Color(0.72, 0.76, 0.84)
	var dark := Color(0.55, 0.6, 0.7)
	# Telo - kockasto, robot nije okrugao.
	Draw2D.poly(p, dark, [V(-8, -2), V(8, -2), V(8, 9), V(-8, 9)])
	Draw2D.poly(p, body_col, [V(-7, -1), V(7, -1), V(7, 8), V(-7, 8)])
	# Glava - kocka.
	Draw2D.poly(p, dark, [V(-6.4, -13), V(6.4, -13), V(6.4, -2.4), V(-6.4, -2.4)])
	Draw2D.poly(p, body_col, [V(-5.6, -12.2), V(5.6, -12.2), V(5.6, -3.2), V(-5.6, -3.2)])
	# Antena.
	Draw2D.poly(p, dark, [V(-0.7, -13), V(0.7, -13), V(0.7, -17), V(-0.7, -17)])
	_circle(p, V(0, -18.2), 1.9, Color(0.95, 0.35, 0.4))
	# Oci - svetleci pravougaonici.
	Draw2D.poly(p, Color(0.35, 0.85, 0.95), [V(-4.0, -9.6), V(-1.2, -9.6), V(-1.2, -6.8), V(-4.0, -6.8)])
	Draw2D.poly(p, Color(0.35, 0.85, 0.95), [V(1.2, -9.6), V(4.0, -9.6), V(4.0, -6.8), V(1.2, -6.8)])
	_circle(p, V(-3.2, -9.0), 0.7, Color(1, 1, 1))
	# Usta - resetka.
	for i in 4:
		Draw2D.poly(p, dark, [
			V(-3.0 + float(i) * 2.0, -5.6), V(-2.2 + float(i) * 2.0, -5.6),
			V(-2.2 + float(i) * 2.0, -4.2), V(-3.0 + float(i) * 2.0, -4.2)])
	# Dugmici na trbuhu.
	_circle(p, V(-3.0, 2.6), 1.5, Color(0.95, 0.75, 0.3))
	_circle(p, V(0, 2.6), 1.5, Color(0.5, 0.85, 0.5))
	_circle(p, V(3.0, 2.6), 1.5, Color(0.9, 0.45, 0.5))
	# Ruke.
	Draw2D.poly(p, dark, [V(-8, 0), V(-12, 1), V(-12, 4), V(-8, 3)])
	Draw2D.poly(p, dark, [V(8, 0), V(12, 1), V(12, 4), V(8, 3)])


func _draw_beaver(p: Node2D) -> void:
	var fur := Color(0.6, 0.44, 0.32)
	var dark := Color(0.46, 0.33, 0.24)
	Draw2D.poly(p, dark, [V(-8, -2), V(-6, -9), V(0, -12), V(6, -9), V(8, -2), V(7, 9), V(-7, 9)])
	Draw2D.poly(p, fur, [V(-7, -3), V(-5, -8), V(0, -11), V(5, -8), V(7, -3), V(6, 8), V(-6, 8)])
	# Rep - siroka veslasta lopata sa sarom.
	Draw2D.poly(p, Color(0.4, 0.3, 0.24), [V(6, 3), V(14, 5), V(14, 10), V(6, 8)])
	for i in 3:
		Draw2D.poly(p, Color(0.32, 0.24, 0.19), [
			V(8.0 + float(i) * 2.0, 4.2), V(8.4 + float(i) * 2.0, 4.2),
			V(8.4 + float(i) * 2.0, 9.0), V(8.0 + float(i) * 2.0, 9.0)])
	# Male okrugle usi.
	_circle(p, V(-5, -9), 2.2, fur)
	_circle(p, V(5, -9), 2.2, fur)
	# Oci.
	_circle(p, V(-2.8, -7), 2.1, Color(1, 1, 1))
	_circle(p, V(2.8, -7), 2.1, Color(1, 1, 1))
	_circle(p, V(-2.8, -7), 1.1, Color(0.12, 0.1, 0.14))
	_circle(p, V(2.8, -7), 1.1, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.3, -7.6), 0.6, Color(1, 1, 1))
	# Nos i veliki prednji zubi - dabar.
	_circle(p, V(0, -3.6), 1.5, Color(0.3, 0.22, 0.2))
	Draw2D.poly(p, Color(0.99, 0.98, 0.9), [V(-1.8, -2.2), V(-0.2, -2.2), V(-0.2, 1.4), V(-1.8, 1.4)])
	Draw2D.poly(p, Color(0.99, 0.98, 0.9), [V(0.2, -2.2), V(1.8, -2.2), V(1.8, 1.4), V(0.2, 1.4)])


func _draw_otter(p: Node2D) -> void:
	var fur := Color(0.66, 0.5, 0.38)
	var dark := Color(0.52, 0.38, 0.28)
	var pale := Color(0.9, 0.84, 0.74)
	# Telo - izduzeno, vidra je vitka.
	Draw2D.poly(p, dark, [V(-8, -1), V(-6, -8), V(0, -11), V(6, -8), V(8, -1), V(7, 9), V(-7, 9)])
	Draw2D.poly(p, fur, [V(-7, -2), V(-5, -7), V(0, -10), V(5, -7), V(7, -2), V(6, 8), V(-6, 8)])
	# Svetlo lice i grudi.
	_circle(p, V(0, -4.4), 4.0, pale)
	Draw2D.poly(p, pale, [V(-3, 0), V(3, 0), V(2.4, 7.4), V(-2.4, 7.4)])
	# Male usi.
	_circle(p, V(-5.4, -8), 1.8, fur)
	_circle(p, V(5.4, -8), 1.8, fur)
	# Oci.
	_circle(p, V(-2.6, -6.4), 2.0, Color(1, 1, 1))
	_circle(p, V(2.6, -6.4), 2.0, Color(1, 1, 1))
	_circle(p, V(-2.6, -6.4), 1.1, Color(0.12, 0.1, 0.14))
	_circle(p, V(2.6, -6.4), 1.1, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.1, -7.0), 0.6, Color(1, 1, 1))
	# Nos i brkovi.
	_circle(p, V(0, -3.6), 1.3, Color(0.28, 0.2, 0.18))
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, Color(0.35, 0.28, 0.24), [
			V(side * 1.6, -3.2), V(side * 6.4, -4.4), V(side * 6.4, -3.8)])
	# Rep.
	Draw2D.poly(p, dark, [V(6, 5), V(13, 7), V(12.4, 9.4), V(6, 8.6)])


func _draw_red_panda(p: Node2D) -> void:
	var fur := Color(0.85, 0.48, 0.3)
	var dark := Color(0.68, 0.36, 0.22)
	var pale := Color(0.98, 0.96, 0.92)
	Draw2D.poly(p, dark, [V(-9, -2), V(-7, -9), V(0, -12), V(7, -9), V(9, -2), V(8, 9), V(-8, 9)])
	Draw2D.poly(p, fur, [V(-8, -3), V(-6, -8), V(0, -11), V(6, -8), V(8, -3), V(7, 8), V(-7, 8)])
	# Velike bele usi.
	_circle(p, V(-6.4, -9.4), 3.2, fur)
	_circle(p, V(6.4, -9.4), 3.2, fur)
	_circle(p, V(-6.4, -9.4), 1.8, pale)
	_circle(p, V(6.4, -9.4), 1.8, pale)
	# Bela maska oko ociju - prepoznatljiva za crvenu pandu.
	_circle(p, V(-3.2, -6.6), 3.0, pale)
	_circle(p, V(3.2, -6.6), 3.0, pale)
	_circle(p, V(-3.2, -6.6), 1.7, Color(0.12, 0.1, 0.14))
	_circle(p, V(3.2, -6.6), 1.7, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.8, -7.3), 0.7, Color(1, 1, 1))
	# Bela rilica.
	_circle(p, V(0, -2.8), 2.6, pale)
	_circle(p, V(0, -3.6), 1.2, Color(0.2, 0.15, 0.14))
	# Prugast rep.
	for i in 4:
		Draw2D.poly(p, fur if i % 2 == 0 else Color(0.5, 0.3, 0.2), [
			V(7.0 + float(i) * 1.8, 3.0 + float(i) * 1.2),
			V(9.0 + float(i) * 1.8, 3.4 + float(i) * 1.2),
			V(9.0 + float(i) * 1.8, 7.4 + float(i) * 0.8),
			V(7.0 + float(i) * 1.8, 7.0 + float(i) * 0.8)])


func _draw_mermaid(p: Node2D) -> void:
	var skin := Color(0.99, 0.84, 0.72)
	var tail := Color(0.35, 0.8, 0.78)
	var tail2 := Color(0.25, 0.66, 0.68)
	# Riblji rep.
	Draw2D.poly(p, tail2, [V(-5, 0), V(5, 0), V(4, 7), V(-4, 7)])
	Draw2D.poly(p, tail, [V(-4, 0), V(4, 0), V(3, 6), V(-3, 6)])
	# Peraje na kraju repa.
	Draw2D.poly(p, tail, [V(-3, 6), V(3, 6), V(9, 12), V(2, 10), V(-2, 10), V(-9, 12)])
	# Krljusti.
	for i in 3:
		for j in 2:
			_circle(p, V(-2.0 + float(j) * 4.0, 1.4 + float(i) * 2.0), 1.2,
				Color(0.5, 0.9, 0.86, 0.7))
	# Torzo.
	Draw2D.poly(p, skin, [V(-3.4, -6), V(3.4, -6), V(4.4, 0.6), V(-4.4, 0.6)])
	# Skoljke.
	_circle(p, V(-2.0, -4.4), 2.0, Color(0.95, 0.6, 0.7))
	_circle(p, V(2.0, -4.4), 2.0, Color(0.95, 0.6, 0.7))
	# Glava.
	_circle(p, V(0, -10), 4.8, skin)
	# Duga crvena kosa.
	Draw2D.poly(p, Color(0.9, 0.35, 0.25), [
		V(-4.8, -10), V(-5.4, -15.4), V(0, -17), V(5.4, -15.4), V(4.8, -10),
		V(6.4, -3), V(3.4, -8), V(-3.4, -8), V(-6.4, -3)])
	# Oci i osmeh.
	_circle(p, V(-1.8, -10), 1.5, Color(1, 1, 1))
	_circle(p, V(1.8, -10), 1.5, Color(1, 1, 1))
	_circle(p, V(-1.8, -10), 0.8, Color(0.12, 0.1, 0.14))
	_circle(p, V(1.8, -10), 0.8, Color(0.12, 0.1, 0.14))
	_circle(p, V(-3.4, -8.4), 1.1, Color(1, 0.6, 0.7, 0.6))
	_circle(p, V(3.4, -8.4), 1.1, Color(1, 0.6, 0.7, 0.6))


func _draw_crab_friend(p: Node2D) -> void:
	var shell := Color(0.95, 0.42, 0.38)
	var dark := Color(0.8, 0.3, 0.28)
	# Noge - po tri sa svake strane.
	for side in [-1.0, 1.0]:
		for k in 3:
			Draw2D.poly(p, dark, [
				V(side * 6, 1.0 + float(k) * 2.4), V(side * 12, 3.0 + float(k) * 2.8),
				V(side * 12, 4.2 + float(k) * 2.8), V(side * 6, 2.4 + float(k) * 2.4)])
	# Oklop - siri nego visok.
	var sh := PackedVector2Array()
	for k in 14:
		var a := TAU * float(k) / 14.0
		sh.append(V(0, -1) + Vector2(cos(a) * 9.4, sin(a) * 7.0))
	Draw2D.poly(p, dark, sh)
	var sh2 := PackedVector2Array()
	for k in 14:
		var a := TAU * float(k) / 14.0
		sh2.append(V(0, -1.6) + Vector2(cos(a) * 8.4, sin(a) * 6.2))
	Draw2D.poly(p, shell, sh2)
	# Klijesta.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, dark, [
			V(side * 8, -3), V(side * 13.4, -7), V(side * 15.4, -4.4), V(side * 10, -0.6)])
		Draw2D.poly(p, shell, [
			V(side * 12.4, -7.4), V(side * 16.4, -8.4), V(side * 15.0, -5.0)])
	# Oci na stapicima.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, dark, [
			V(side * 2.6, -6), V(side * 3.4, -11), V(side * 2.0, -11), V(side * 1.4, -6)])
		_circle(p, V(side * 2.7, -12.0), 2.2, Color(1, 1, 1))
		_circle(p, V(side * 2.7, -12.0), 1.2, Color(0.12, 0.1, 0.14))
	# Osmeh.
	Draw2D.poly(p, Color(0.6, 0.2, 0.2), [V(-2.6, 0.6), V(2.6, 0.6), V(0, 2.4)])


func _draw_phoenix(p: Node2D) -> void:
	var fur := Color(0.98, 0.55, 0.2)
	var dark := Color(0.88, 0.36, 0.14)
	# Vatrena krila - siroka, u dva sloja.
	for side in [-1.0, 1.0]:
		Draw2D.poly(p, dark, [
			V(side * 5, -4), V(side * 18, -14), V(side * 20, -2),
			V(side * 14, 5)])
		Draw2D.poly(p, Color(0.99, 0.78, 0.3), [
			V(side * 6, -3), V(side * 15, -10), V(side * 16, -1),
			V(side * 11, 3)])
	# Telo.
	Draw2D.poly(p, dark, [V(-7, -4), V(-5, -11), V(0, -13), V(5, -11), V(7, -4), V(6, 8), V(-6, 8)])
	Draw2D.poly(p, fur, [V(-6, -5), V(-4, -10), V(0, -12), V(4, -10), V(6, -5), V(5, 7), V(-5, 7)])
	# Perjanica na glavi - tri plamena.
	for k in 3:
		Draw2D.poly(p, Color(0.99, 0.82, 0.3), [
			V(-3.0 + float(k) * 3.0, -12.0), V(-2.4 + float(k) * 3.0, -19.0),
			V(-0.6 + float(k) * 3.0, -12.0)])
	# Rep - dugo vatreno perje.
	for k in 3:
		Draw2D.poly(p, Color(0.95, 0.45, 0.16), [
			V(3, 5), V(9.0 + float(k) * 3.0, 9.0 + float(k) * 2.0),
			V(5.0 + float(k) * 2.0, 7.0)])
	# Kljun i oci.
	Draw2D.poly(p, Color(0.98, 0.8, 0.25), [V(-1.6, -6), V(1.6, -6), V(0, -3)])
	_circle(p, V(-2.8, -8), 2.2, Color(1, 1, 1))
	_circle(p, V(2.8, -8), 2.2, Color(1, 1, 1))
	_circle(p, V(-2.8, -8), 1.2, Color(0.14, 0.1, 0.1))
	_circle(p, V(2.8, -8), 1.2, Color(0.14, 0.1, 0.1))
	_circle(p, V(-3.3, -8.6), 0.6, Color(1, 1, 1))

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

## Krug sa 12 segmenata - ovaj fajl crta glatkije oblike
## od podrazumevanih 14 u Draw2D.
func _circle(parent: Node, center: Vector2, r: float,
		col: Color) -> Polygon2D:
	return Draw2D.circle(parent, center, r, col, 12)
