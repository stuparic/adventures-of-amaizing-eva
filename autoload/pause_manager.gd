extends Node
## Pauzira igru i gasi zvuk kad se prozor minimizuje ili tab sakrije.
##
## Bitno na telefonu: kad dete prebaci na drugu aplikaciju, igra treba da
## stane (Eva ne pada u rupu dok se ne gleda) i muzika da utihne.
##
## Dva odvojena signala, jer nijedan sam nije dovoljan:
##   1. NOTIFICATION_APPLICATION_FOCUS_OUT - radi na desktopu
##   2. document.visibilitychange (JS) - jedini pouzdan na telefonu,
##      gde Godot cesto ne dobije focus event pri prebacivanju aplikacije
##
## Autoload je van pause dreveta (PROCESS_MODE_ALWAYS), pa nastavlja da
## radi i dok je igra pauzirana - inace ne bi mogao da je odpauzira.

## Koliko brzo zvuk utihne / vrati se (sekunde).
const FADE_OUT := 0.12
const FADE_IN := 0.35

var _paused_by_us := false
var _master_bus := 0
var _saved_volume_db := 0.0
var _web_check_timer := 0.0

## Na webu proveravamo document.hidden periodicno - visibilitychange
## upisuje flag u window.evaHidden koji ovde citamo.
const WEB_POLL_INTERVAL := 0.25

var _is_web := OS.has_feature("web")

var _fade_tween: Tween = null
var _overlay: CanvasLayer
var _label: Label


func _ready() -> void:
	# Mora da radi i kad je igra pauzirana, inace ne moze da je odpauzira.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master_bus = AudioServer.get_bus_index("Master")
	_saved_volume_db = AudioServer.get_bus_volume_db(_master_bus)

	_build_overlay()

	if _is_web:
		_install_web_hook()


## Poruka "Pauza" preko celog ekrana. Pravi se u kodu da bi radila u
## SVAKOJ sceni (mapa, nivo) bez menjanja tih scena.
func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 100          # iznad svega, i iznad win screena
	_overlay.visible = false
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.14, 0.24, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)

	_label = Label.new()
	_label.text = "PAUZA"
	_label.add_theme_font_size_override("font_size", 56)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_constant_override("outline_size", 10)
	_label.add_theme_color_override("font_outline_color", Color(0.2, 0.3, 0.5))
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_label)


## JS hook: upisuje 1/0 u window.evaHidden na svaku promenu vidljivosti.
## Radi i za prebacivanje aplikacije na telefonu, i za zaključavanje ekrana.
func _install_web_hook() -> void:
	JavaScriptBridge.eval("""
		window.evaHidden = document.hidden ? 1 : 0;
		if (!window.evaVisHooked) {
			window.evaVisHooked = 1;
			document.addEventListener('visibilitychange', function () {
				window.evaHidden = document.hidden ? 1 : 0;
			});
			// iOS Safari ne salje uvek visibilitychange pri prebacivanju -
			// pagehide/blur su rezerva.
			window.addEventListener('pagehide', function () { window.evaHidden = 1; });
			window.addEventListener('blur', function () { window.evaHidden = 1; });
			window.addEventListener('focus', function () {
				window.evaHidden = document.hidden ? 1 : 0;
			});
		}
	""", true)


func _process(delta: float) -> void:
	if not _is_web:
		return

	# Anketiraj JS flag - jedini pouzdan nacin na telefonu.
	_web_check_timer += delta
	if _web_check_timer < WEB_POLL_INTERVAL:
		return
	_web_check_timer = 0.0

	if get_tree() == null:
		return
	var hidden := int(JavaScriptBridge.eval("window.evaHidden || 0;", true)) == 1
	if hidden and not _paused_by_us:
		pause_game()
	elif not hidden and _paused_by_us:
		resume_game()


## Desktop: Godotove notifikacije o fokusu i minimizovanju.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			pause_game()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			resume_game()


func pause_game() -> void:
	if _paused_by_us:
		return
	_paused_by_us = true

	# Zapamti glasnost SAMO ako fade ne traje - inace bismo zapamtili
	# vec umanjenu vrednost i zvuk se nikad ne bi vratio.
	if _fade_tween == null or not _fade_tween.is_valid():
		_saved_volume_db = AudioServer.get_bus_volume_db(_master_bus)

	var tree := get_tree()
	if tree == null:
		return
	tree.paused = true
	if _overlay != null:
		_overlay.visible = true
	_fade_audio(-80.0, FADE_OUT)


func resume_game() -> void:
	if not _paused_by_us:
		return
	_paused_by_us = false

	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	if _overlay != null:
		_overlay.visible = false
	# Ne vracaj zvuk ako je korisnik rucno iskljucio (taster N).
	if not Audio.is_muted():
		_fade_audio(_saved_volume_db, FADE_IN)


## Meko utisavanje - naglo gasenje "klikne" u zvucnicima.
##
## Cuva referencu i ubija prethodni tween: bez toga se fade-out i fade-in
## bore za istu vrednost i glasnost zavrsi na slucajnom nivou.
func _fade_audio(to_db: float, duration: float) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	# Tween MORA da radi dok je igra pauzirana - inace se zvuk nikad ne
	# utisa (get_tree().paused zamrzne obicne tvinove).
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_method(
		func(v: float) -> void: AudioServer.set_bus_volume_db(_master_bus, v),
		AudioServer.get_bus_volume_db(_master_bus), to_db, duration
	)


func is_paused_by_us() -> bool:
	return _paused_by_us
