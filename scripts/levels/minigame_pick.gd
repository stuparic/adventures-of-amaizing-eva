extends MinigameBase
class_name MinigamePick
## Osnova za mini-igre u kojima dete BIRA jednu od nekoliko meta.
##
## Sve nove mini-igre rade isto: nacrtaj nekoliko meta, dete dodirne jednu,
## proveri da li je tacna. Ovo skida taj obrazac na jedno mesto - inace bi
## se u svakoj od 6 novih igara ponavljalo isto, ukljucujuci i sve zamke
## koje su u ovom projektu vec jednom pojele po pola dana:
##
##   - Klik se obradjuje GEOMETRIJSKI u _input(), ne preko Area2D ni
##     Button-a. Area2D zavisi od Godotovog physics object picking-a koji
##     ovde nije dostavljao input_event; Button je Control i zivi u
##     EKRANSKOM prostoru, pa kad kamera zumira zavrsi pored mete.
##   - Meta se trazi kao NAJBLIZA u dometu, ne "prva na koju naletis":
##     zone se preklapaju kod gustih meta, pa bi "prva" cesto bila pogresna.
##   - Pogresan izbor se NE kaznjava: meta se zatrese i igra ide dalje.
##
## Nivo koji nasledjuje ovo popunjava _setup(), doda mete preko add_target()
## i dobija _on_pick(index) kad dete izabere.

## Jedna meta: cvor + poluprecnik zone za dodir.
var _targets: Array[Node2D] = []
var _radii: Array[float] = []

## Dok je true, dodir se ignorise (npr. dok se animacija odigrava).
var busy := false

## Najmanja zona za dodir. Mereno na telefonu (390px sirok ekran, bazni
## viewport 1280): 55 fizickih px je granica za detinji prst, a to je
## ~180px u prostoru igre. Zato meta ne sme biti manja od 90px poluprecnika.
const MIN_TOUCH_R := 90.0


## Dodaj metu. `r` je poluprecnik zone za dodir - namerno VECI od crteza.
func add_target(node: Node2D, r := MIN_TOUCH_R) -> int:
	_targets.append(node)
	_radii.append(maxf(r, 44.0))
	return _targets.size() - 1


func clear_targets() -> void:
	_targets.clear()
	_radii.clear()


## Nivo prepisuje ovo - dobija indeks mete koju je dete dodirnulo.
func _on_pick(_index: int) -> void:
	pass


func _input(event: InputEvent) -> void:
	if busy or _done:
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

	# Ekranska -> svetska koordinata (uzima u obzir kameru i zoom).
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * pos

	# NAJBLIZA meta u dometu - ne prva na koju naletis.
	var best := -1
	var best_d := INF
	for i in _targets.size():
		if _targets[i] == null or not is_instance_valid(_targets[i]):
			continue
		var d := world.distance_to(_targets[i].global_position)
		if d <= _radii[i] and d < best_d:
			best_d = d
			best = i

	if best >= 0:
		get_viewport().set_input_as_handled()
		_on_pick(best)


## Zatresi metu - povratna informacija za pogresan izbor, BEZ kazne.
func shake(node: Node2D) -> void:
	if node == null or not is_instance_valid(node):
		return
	var base := node.position
	var tw := create_tween()
	for i in 2:
		tw.tween_property(node, "position", base + Vector2(9, 0), 0.05)
		tw.tween_property(node, "position", base - Vector2(9, 0), 0.05)
	tw.tween_property(node, "position", base, 0.05)
	Audio.play("land", 0.15)


## Kratki "pop" - meta poskoci kad je tacna.
func pop(node: Node2D) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.tween_property(node, "scale", node.scale * 1.18, 0.11) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", node.scale, 0.2) \
		.set_trans(Tween.TRANS_ELASTIC)


## Zelena kvacica preko mete - "tacno".
##
## CRTA se poligonima, ne pise se kao znak: Godotov web font ne sadrzi ✓ i
## na webu bi bila prazna kockica (isto vazi za ★ i ♥ - vidi hud.gd).
func mark_ok(node: Node2D, at := Vector2.ZERO) -> void:
	if node == null or not is_instance_valid(node):
		return
	var chk := Node2D.new()
	chk.position = at
	chk.z_index = 20
	node.add_child(chk)
	Draw2D.circle(chk, Vector2.ZERO, 20.0, Color(0.3, 0.75, 0.4))
	Draw2D.poly(chk, Color(1, 1, 1), [
		Vector2(-9, 0), Vector2(-3.5, 7), Vector2(10, -8),
		Vector2(10, -3.5), Vector2(-3.5, 11.5), Vector2(-9, 4.5)])
	var tw := create_tween()
	tw.tween_property(chk, "scale", Vector2.ONE * 1.25, 0.12) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(chk, "scale", Vector2.ONE, 0.18)


## Uklopi scenu u ekran po SIROKOJ i VISOKOJ strani.
##
## Telefonski viewport je samo 620px visok (bazna visina projekta), pa se
## sadrzaj koji staje na desktopu na telefonu ne vidi ceo. Skala se zato
## racuna po obe ose i uzima manja.
func fit_stage(stage: Node2D, content: Vector2, top_reserve := 96.0) -> void:
	if stage == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0 or content.x <= 0.0 or content.y <= 0.0:
		return
	var s := minf((vp.x - 60.0) / content.x, (vp.y - top_reserve) / content.y)
	s = minf(s, 1.0)
	stage.scale = Vector2(s, s)
