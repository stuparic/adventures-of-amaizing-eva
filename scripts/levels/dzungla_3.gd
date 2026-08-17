extends LevelBase
## NIVO 8 — "Skrivena reka" (Divlja džungla)
##
## PODZEMNI nivo: Eva ulazi u pecinu ispod dzungle, gde tece skrivena
## reka. Ovde PLIVA - voda nije opasna nego put.
##
## Razlika od "Palmin gaj" (gde je takodje plivanje): tamo je bilo
## otvoreno more i sunce, ovde je pecina - uzak prostor, stalaktiti,
## voda koja svetli. Isti pokret, drugo mesto.
##
## Eva spasava kornjaču Žuću.


func _setup() -> void:
	biome = "dzungla"
	start = Vector2(40, -40)
	fall_limit = 480.0
	power = "swim"
	set_friend(Vector2(2760, -44), "kornjaca")

	set_decor(_draw_cave)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Skrivena reka!\nDrži SPACE da plivaš"


func _build_terrain() -> void:
	# --- Deo 1: ulaz u pecinu, plitka voda ---
	add_ground(Rect2(0, 0, 300, 60), "jungle")
	add_water(Rect2(300, 0, 170, 80))
	add_ground(Rect2(470, 0, 230, 60), "stone")

	# --- Deo 2: prvi dublji bazen, plivanje je lakse od skoka ---
	add_water(Rect2(700, 0, 300, 150))
	# Kamen u sredini - odmor ako dete zeli.
	add_ground(Rect2(830, -26, 80, 18), "stone")
	add_ground(Rect2(1000, 0, 200, 60), "stone")

	# --- Deo 3: uspon uz stalagmite, van vode ---
	add_ground(Rect2(1140, -66, 76, 16), "stone")
	add_ground(Rect2(1260, -124, 76, 16), "stone")
	add_ground(Rect2(1140, -186, 76, 16), "stone")
	add_ground(Rect2(1260, -244, 180, 20), "stone")

	# --- Deo 4: skok u duboku vodu odozgo ---
	# Sa y=-244 Eva pada u bazen - plivanje je jedini izlaz.
	add_water(Rect2(1500, 0, 420, 240))
	add_ground(Rect2(1660, -40, 80, 18), "stone")
	add_ground(Rect2(1920, 0, 200, 60), "stone")

	# --- Deo 5: plivanje ISPOD niske stene ---
	# Prolaz je nizak, pa Eva mora kroz vodu, ne preko.
	add_ground(Rect2(2120, -120, 260, 40), "stone")
	add_water(Rect2(2120, 0, 260, 150))
	add_ground(Rect2(2380, 0, 200, 60), "stone")

	# --- Deo 6: izlaz iz pecine, kornjaca na suncu ---
	add_ground(Rect2(2460, -76, 70, 16), "wood")
	add_ground(Rect2(2600, 0, 320, 60), "jungle")


func _build_stars() -> void:
	add_star(Vector2(130, -34))
	add_star(Vector2(240, -34))
	# Zvezdice U VODI - vode dete da pliva.
	add_star_line(Vector2(340, 24), Vector2(430, 24), 3)
	add_star(Vector2(540, -34))
	add_star(Vector2(660, -34))

	# Prvi bazen: po dubini.
	add_star_line(Vector2(730, 30), Vector2(810, 60), 3)
	add_star(Vector2(870, -58))
	add_star_line(Vector2(920, 60), Vector2(980, 26), 3)
	add_star(Vector2(1060, -34))

	# Uspon.
	add_star(Vector2(1178, -100))
	add_star(Vector2(1298, -158))
	add_star(Vector2(1178, -220))
	add_star(Vector2(1330, -278))
	add_star(Vector2(1410, -278))

	# Skok u duboku vodu - trag nadole.
	add_star(Vector2(1470, -220))
	add_star(Vector2(1520, -150))
	add_star(Vector2(1570, -70))
	add_star(Vector2(1620, 10))
	add_star(Vector2(1700, -70))
	add_star_line(Vector2(1760, 40), Vector2(1880, 30), 3)
	add_star(Vector2(1980, -34))

	# Plivanje ispod stene - zvezdice u prolazu.
	add_star_line(Vector2(2160, 20), Vector2(2340, 20), 4)
	add_star(Vector2(2440, -34))

	add_star(Vector2(2494, -110))
	add_star(Vector2(2660, -34))
	add_star(Vector2(2820, -34))


func _build_animals() -> void:
	add_animal("zaba", Vector2(540, -32))
	add_animal("puz", Vector2(1060, -32))
	add_animal("zaba", Vector2(1360, -276))
	add_animal("puz", Vector2(1980, -32))
	add_animal("zaba", Vector2(2440, -32))
	add_animal("puz", Vector2(2680, -32))


func _build_checkpoints() -> void:
	for p in [Vector2(60, -36), Vector2(500, -36), Vector2(1030, -36),
			Vector2(1300, -280), Vector2(1950, -36), Vector2(2410, -36),
			Vector2(2640, -36)]:
		add_checkpoint(p)


## Pecina: tamni svod, stalaktiti i stalagmiti, gljive koje svetle,
## kapljice vode. Voda svetli plavo - vidi se da je put, ne opasnost.
##
## NIJE mracno do neprohodnosti: svod je taman ali staza je jasno
## osvetljena. Petogodisnjak treba da vidi gde ide.
func _draw_cave(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8320

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Svod pecine - podignut i SVETLIJI nego u prvoj verziji.
	#
	# Na snimku je gornja polovina ekrana bila skoro crna: svod je pocinjao
	# na y=-300 (tacno u vidnom polju) i imao alfu 0.75. Sada je gore na
	# y=-460 i prozirniji, pa se vidi da je pecina prostorija a ne mrak.
	Draw2D.poly(bg, Color(0.2, 0.17, 0.24, 0.5), [
		Vector2(-100, -700), Vector2(3100, -700),
		Vector2(3100, -460), Vector2(-100, -460)])
	# Neravan donji rub svoda.
	var x := -100.0
	while x < 3100.0:
		var w := rng.randf_range(80.0, 190.0)
		var d := rng.randf_range(20.0, 70.0)
		Draw2D.poly(bg, Color(0.2, 0.17, 0.24, 0.5), [
			Vector2(x, -460), Vector2(x + w * 0.5, -460 + d),
			Vector2(x + w, -460)])
		x += w * 0.85

	# Zadnja stena - svetlija podloga, da se platforme jasno izdvajaju.
	Draw2D.poly(bg, Color(0.3, 0.26, 0.33, 0.45), [
		Vector2(-100, -460), Vector2(3100, -460),
		Vector2(3100, 80), Vector2(-100, 80)])

	# --- Stalaktiti sa svoda ---
	for i in 34:
		var sx := rng.randf_range(-60.0, 3060.0)
		var y0 := -460.0 + rng.randf_range(0.0, 60.0)
		var h := rng.randf_range(70.0, 210.0)
		var w := rng.randf_range(11.0, 26.0)
		var a := rng.randf_range(0.55, 0.85)
		Draw2D.poly(bg, Color(0.28, 0.24, 0.3, a), [
			Vector2(sx - w, y0), Vector2(sx + w, y0), Vector2(sx, y0 + h)])
		# Svetliji rub - daje zapreminu.
		Draw2D.poly(bg, Color(0.4, 0.35, 0.42, a * 0.8), [
			Vector2(sx - w * 0.4, y0), Vector2(sx + w * 0.15, y0),
			Vector2(sx, y0 + h * 0.75)])

	# --- Stalagmiti sa tla ---
	for i in 22:
		var sx := rng.randf_range(-60.0, 3060.0)
		var h := rng.randf_range(30.0, 90.0)
		var w := rng.randf_range(12.0, 26.0)
		var a := rng.randf_range(0.5, 0.8)
		Draw2D.poly(bg, Color(0.26, 0.22, 0.28, a), [
			Vector2(sx - w, 60), Vector2(sx + w, 60), Vector2(sx, 60 - h)])

	# --- Gljive koje svetle: osvetljavaju stazu ---
	const SHROOM_COLS: Array[Color] = [
		Color(0.5, 0.95, 0.8), Color(0.6, 0.8, 1.0), Color(0.85, 0.7, 1.0)]
	for i in 26:
		var gx := rng.randf_range(-40.0, 3040.0)
		var gy := rng.randf_range(-30.0, 46.0)
		var col: Color = SHROOM_COLS[i % 3]

		# Halo - mek krug svetla koji blago pulsira, pa pecina deluje ziva.
		# Halo je u svom Node2D-u da se moze skalirati bez diranja gljive.
		var halo := Node2D.new()
		halo.position = Vector2(gx, gy - 8)
		bg.add_child(halo)
		Draw2D.circle(halo, Vector2.ZERO, 26.0, Color(col.r, col.g, col.b, 0.1))
		Draw2D.circle(halo, Vector2.ZERO, 15.0, Color(col.r, col.g, col.b, 0.16))

		var t := rng.randf_range(1.6, 3.0)
		var pulse := create_tween().set_loops()
		pulse.tween_interval(rng.randf_range(0.15, 1.5))
		pulse.tween_property(halo, "scale", Vector2(1.25, 1.25), t) \
			.set_trans(Tween.TRANS_SINE)
		pulse.tween_property(halo, "scale", Vector2.ONE, t) \
			.set_trans(Tween.TRANS_SINE)
		# Stablo i klobuk.
		Draw2D.poly(bg, Color(0.85, 0.9, 0.88, 0.8), [
			Vector2(gx - 3, gy), Vector2(gx + 3, gy),
			Vector2(gx + 2, gy - 14), Vector2(gx - 2, gy - 14)])
		Draw2D.poly(bg, col, [
			Vector2(gx - 13, gy - 13), Vector2(gx, gy - 24),
			Vector2(gx + 13, gy - 13)])
		# Tackice na klobuku.
		Draw2D.circle(bg, Vector2(gx - 4, gy - 16), 2.0, Color(1, 1, 1, 0.8))
		Draw2D.circle(bg, Vector2(gx + 5, gy - 17), 1.8, Color(1, 1, 1, 0.8))

	# --- Kapljice koje padaju sa stalaktita ---
	for i in 16:
		var dx := rng.randf_range(-40.0, 3040.0)
		var dy := rng.randf_range(-260.0, -150.0)
		var drop := Polygon2D.new()
		drop.color = Color(0.6, 0.85, 1.0, 0.7)
		drop.polygon = PackedVector2Array([
			Vector2(0, -5), Vector2(2.5, 0), Vector2(0, 6), Vector2(-2.5, 0)])
		drop.position = Vector2(dx, dy)
		bg.add_child(drop)

		var fall := rng.randf_range(180.0, 320.0)
		var dur := rng.randf_range(1.4, 2.6)
		var tw := create_tween().set_loops()
		tw.tween_interval(rng.randf_range(0.15, 2.0))
		tw.tween_property(drop, "position:y", dy + fall, dur).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: drop.position.y = dy)

	# --- Zraci svetla na ulazu i izlazu (dete vidi gde je pocetak/kraj) ---
	for sx2 in [120.0, 2820.0]:
		Draw2D.poly(bg, Color(1, 0.97, 0.8, 0.13), [
			Vector2(sx2 - 40, -460), Vector2(sx2 + 40, -460),
			Vector2(sx2 + 90, 70), Vector2(sx2 + 10, 70)])
		Draw2D.poly(bg, Color(1, 0.97, 0.8, 0.09), [
			Vector2(sx2 - 10, -460), Vector2(sx2 + 70, -460),
			Vector2(sx2 + 120, 70), Vector2(sx2 + 40, 70)])
