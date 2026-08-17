extends CanvasLayer
## Meni sa rezultatima: high score, spisak nivoa i reset napretka.
##
## Otvara se sa mape (dugme "REZULTATI") i preko njega se ulazi u pojedinacni
## nivo - red u spisku je klikabilan, kao link.
##
## Ovde se KORISTE Control cvorovi i Button, za razliku od mini-igara gde
## klik ide geometrijski kroz _input(). Razlika je bitna:
##   - u mini-igrama su mete Node2D u SVETU, pa Button (koji zivi u
##     ekranskom prostoru) zavrsava na pogresnom mestu kad kamera zumira
##   - ovde je ceo meni UI sloj bez kamere, pa je Button tacno prava stvar
##
## Sto se moralo paziti (naucen na starim greskama u ovom projektu):
##   - pozadinski ColorRect MORA da bude mouse_filter = STOP da klik ne
##     prodje kroz meni na mapu ispod; ali sve DEKORACIJE moraju biti
##     IGNORE, inace jedu klik na dugmad
##   - svaki Button ima focus_mode = NONE, inace fokusirano dugme reaguje
##     na SPACE (a SPACE na mapi ulazi u nivo)
##   - `visible = false` na CanvasLayer skriva grafiku ali NE gasi Control
##     input, pa se meni gasi i preko _shown zastave

signal closed
## Trazen ulaz u nivo (indeks u Game.LEVELS).
signal level_chosen(index: int)

## Zvezdica je POLIGON, ne znak "★".
##
## Godotov web font ne sadrzi ★ - na webu se prikazuje kao prazna kockica
## ("tofu"), sto je u ovom projektu vec potvrdjeno citanjem piksela iz
## WebGL canvasa (vidi hud.gd). Zato ide ista scena koju koristi HUD.
const StarIcon := preload("res://scenes/hud_star.tscn")

const PANEL_W := 760.0
const ROW_H := 62.0
const PAD := 22.0

var _shown := false
var _root: Control
var _rows_box: VBoxContainer


func _ready() -> void:
	layer = 90            # iznad mape, ispod HUD poruka
	_build()
	hide_menu()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# STOP: zaustavi klik da ne prodje na mapu ispod.
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Zatamljenje preko cele mape.
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.12, 0.2, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	# --- Panel u sredini ---
	#
	# CenterContainer, ne PRESET_CENTER: preset postavi anchor u centar ali
	# panel i dalje RASTE desno-dole od te tacke, pa je pola panela bilo van
	# ekrana (video na snimku). CenterContainer centrira i po sirini i po
	# visini, bez racunanja offseta.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_W, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.99, 0.97, 0.92)
	st.set_corner_radius_all(26)
	st.set_border_width_all(6)
	st.border_color = Color(0.45, 0.72, 0.9)
	st.set_content_margin_all(PAD)
	panel.add_theme_stylebox_override("panel", st)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)

	var title := Label.new()
	title.text = "MOJI REZULTATI"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.2, 0.42, 0.62))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)

	# Ukupan rezultat - "high score" cele igre. Zvezdica je ikona pored
	# teksta, jer se znak ★ na webu ne prikazuje.
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", 8)
	trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(trow)
	trow.add_child(_star_node(1.25))

	var total := Label.new()
	total.name = "Total"
	total.add_theme_font_size_override("font_size", 26)
	total.add_theme_color_override("font_color", Color(0.35, 0.5, 0.35))
	total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trow.add_child(total)

	# --- Spisak nivoa, skrolabilan ---
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_W - PAD * 2, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 6)
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows_box)

	# --- Dugmad dole ---
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btns)

	btns.add_child(_make_button("ZATVORI", Color(0.42, 0.66, 0.9),
		func() -> void:
			Audio.play("checkpoint")
			hide_menu()
			closed.emit()
	))
	btns.add_child(_make_button("OBRIŠI SVE", Color(0.9, 0.45, 0.45),
		_ask_reset))


## Dugme u stilu HUD-a. focus_mode = NONE je OBAVEZNO: fokusirano dugme
## reaguje na SPACE, a SPACE na mapi ulazi u nivo - tako je ranije svaki
## pritisak tastera prevrtao stanje zvuka.
func _make_button(text: String, col: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(190, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(1, 1, 1))

	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = col.lightened(0.12)
	b.add_theme_stylebox_override("hover", hov)
	var pr := sb.duplicate() as StyleBoxFlat
	pr.bg_color = col.darkened(0.12)
	b.add_theme_stylebox_override("pressed", pr)

	b.pressed.connect(on_press)
	return b


## Zvezdica upakovana u Control, da moze u HBoxContainer.
## hud_star.tscn je Node2D i sam ne moze da bude dete kontejnera.
func _star_node(scale := 1.0) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(26.0 * scale, 26.0 * scale)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Bez ovoga se zvezdica lepi na VRH reda (HBox je rastegnut po visini
	# reda od 62px), pa visi iznad linije teksta - video na snimku.
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st: Node2D = StarIcon.instantiate()
	st.position = Vector2(13.0 * scale, 13.0 * scale)
	st.scale = Vector2(scale, scale)
	holder.add_child(st)
	return holder


## --- Prikaz ---

func show_menu() -> void:
	_refresh()
	_shown = true
	visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP


func hide_menu() -> void:
	_shown = false
	visible = false
	# Kljucno: `visible = false` skriva grafiku ali Control i dalje hvata
	# klik. Bez ovoga se posle zatvaranja menija ne moze kliknuti na mapu.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_shown() -> bool:
	return _shown


func _refresh() -> void:
	var total := _root.find_child("Total", true, false) as Label
	if total != null:
		var got := Game.total_score()
		var pos := Game.total_possible()
		var txt := str(got) if pos <= 0 else "%d / %d" % [got, pos]
		total.text = "%s     •     %d / %d nivoa" % [
			txt, Game.completed_count(), Game.playable_count()]

	for c in _rows_box.get_children():
		c.queue_free()

	var last_island := ""
	for i in Game.level_count():
		if not Game.level_exists(i):
			continue

		# Naslov ostrva iznad prve tacke tog ostrva.
		var isl := Game.island_of(i)
		var iname := String(isl.get("name", ""))
		if iname != last_island:
			last_island = iname
			_rows_box.add_child(_island_header(iname))

		_rows_box.add_child(_level_row(i))


func _island_header(name: String) -> Control:
	var l := Label.new()
	l.text = name
	l.add_theme_font_size_override("font_size", 19)
	l.add_theme_color_override("font_color", Color(0.55, 0.5, 0.42))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Jedan red: broj, ime nivoa, zvezdice, vreme. Ceo red je dugme - to je
## "link" do nivoa iz zahteva.
func _level_row(index: int) -> Control:
	var d := Game.level_data(index)
	var b := Game.best_for(index)
	var unlocked := Game.level_unlocked(index)
	var done := Game.level_completed(index)

	var row := Button.new()
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0, ROW_H)
	row.disabled = not unlocked
	row.tooltip_text = "" if unlocked else "Završi prethodni nivo"

	var bg := Color(0.93, 0.96, 1.0)
	if done:
		bg = Color(1, 0.96, 0.82)
	elif not unlocked:
		bg = Color(0.9, 0.9, 0.9)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(8)
	if done:
		sb.set_border_width_all(3)
		sb.border_color = Color(0.95, 0.78, 0.3)
	row.add_theme_stylebox_override("normal", sb)
	row.add_theme_stylebox_override("disabled", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.06)
	row.add_theme_stylebox_override("hover", hov)

	# Sadrzaj reda ide u HBox PREKO dugmeta; sve mora da bude IGNORE da
	# klik stigne do dugmeta ispod.
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.offset_left = 12
	h.offset_right = -12
	row.add_child(h)

	var num := Label.new()
	num.text = "%d." % (index + 1)
	num.custom_minimum_size = Vector2(42, 0)
	num.add_theme_font_size_override("font_size", 22)
	num.add_theme_color_override("font_color", Color(0.45, 0.5, 0.58))
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(num)

	var nm := Label.new()
	nm.text = String(d.get("name", "?"))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_font_size_override("font_size", 23)
	nm.add_theme_color_override("font_color",
		Color(0.25, 0.3, 0.38) if unlocked else Color(0.6, 0.6, 0.62))
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(nm)

	var res := Label.new()
	res.add_theme_font_size_override("font_size", 21)
	res.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	res.custom_minimum_size = Vector2(200, 0)
	res.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		res.text = "zatvoreno"
		res.add_theme_color_override("font_color", Color(0.62, 0.62, 0.64))
	elif b.is_empty():
		res.text = "—"
		res.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	else:
		var stars := int(b.get("stars", 0))
		var mx := int(b.get("max", 0))
		var t := float(b.get("time", 0.0))
		var star_txt := str(stars) if mx <= 0 else "%d/%d" % [stars, mx]
		res.text = "%s   %d:%02d" % [star_txt, int(t) / 60, int(t) % 60]
		res.add_theme_color_override("font_color", Color(0.45, 0.42, 0.2))
		# Zvezdica-ikona ide PRE teksta rezultata.
		h.add_child(_star_node(0.85))
	h.add_child(res)

	if unlocked:
		row.pressed.connect(func() -> void:
			Audio.play("star")
			hide_menu()
			level_chosen.emit(index)
		)
	return row


## --- Reset napretka ---
##
## Trazi potvrdu: dete moze slucajno da pritisne, a ovo brise sve.
func _ask_reset() -> void:
	Audio.play("hurt")
	var dlg := ConfirmationDialog.new()
	dlg.title = "Obriši napredak?"
	dlg.dialog_text = "Sve zvezdice i vremena će biti obrisani.\nOvo se ne može vratiti."
	dlg.ok_button_text = "Obriši"
	dlg.cancel_button_text = "Ne"
	add_child(dlg)
	dlg.confirmed.connect(func() -> void:
		Game.reset_progress()
		Audio.play("checkpoint")
		_refresh()
		dlg.queue_free()
		# Mapa mora da se prekrca da se katanci i boje puteva osveze.
		get_tree().reload_current_scene()
	)
	dlg.canceled.connect(func() -> void: dlg.queue_free())
	dlg.popup_centered()
