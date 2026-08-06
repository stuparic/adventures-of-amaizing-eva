extends CanvasLayer
## Touch kontrole za telefon i tablet: dva dugmeta levo/desno i skok.
##
## Pojavljuju se SAMO na dodirnim ekranima - na desktopu se ne vide.
## Rade preko Input.action_press/release, pa eva.gd ne mora nista da zna
## o njima: za igru je to isto kao pritisak tastera.

const BTN_ALPHA := 0.32
const BTN_ALPHA_HELD := 0.6

@onready var root: Control = $Root
@onready var btn_left: TouchScreenButton = $Root/Left
@onready var btn_right: TouchScreenButton = $Root/Right
@onready var btn_jump: TouchScreenButton = $Root/Jump


func _ready() -> void:
	layer = 5

	# Prikazi samo ako uredjaj ima ekran na dodir.
	var touch := DisplayServer.is_touchscreen_available()
	visible = touch
	if not touch:
		return

	_wire(btn_left, "move_left")
	_wire(btn_right, "move_right")
	_wire(btn_jump, "jump")

	_place()
	get_viewport().size_changed.connect(_place)


## Rasporedi dugmad po stvarnoj velicini ekrana: kretanje levo dole,
## skok desno dole, sa marginom da ne budu na samoj ivici.
func _place() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0:
		return

	const SIZE := 156.0   # velicina teksture dugmeta

	# Na telefonu dete drzi uredjaj sa dva palca - dugmad idu BLIZE
	# ivicama i donjem rubu, gde palac prirodno pada.
	var win := DisplayServer.window_get_size()
	var phone := mini(win.x, win.y) < 500
	var margin := 16.0 if phone else 34.0
	var gap := 14.0 if phone else 24.0
	var y := vp.y - SIZE - margin

	btn_left.position = Vector2(margin, y)
	btn_right.position = Vector2(margin + SIZE + gap, y)
	btn_jump.position = Vector2(vp.x - SIZE - margin, y)

	# Skok je NAJVAZNIJE dugme - na telefonu je veci.
	var jump_scale := 1.15 if phone else 1.0
	btn_jump.scale = Vector2(jump_scale, jump_scale)


## Poveži dugme na akciju iz Input mape.
func _wire(btn: TouchScreenButton, action: String) -> void:
	btn.pressed.connect(func() -> void:
		Input.action_press(action)
		btn.modulate.a = BTN_ALPHA_HELD
	)
	btn.released.connect(func() -> void:
		Input.action_release(action)
		btn.modulate.a = BTN_ALPHA
	)
	btn.modulate.a = BTN_ALPHA
