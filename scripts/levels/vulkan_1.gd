extends LevelBase
## NIVO 12 — "Crna staza" (Vulkan)
##
## Lava je opasna kao vruc pesak, ali ovde ide sa KRHKIM KAMENOM: ploce
## nad lavom puknu kratko posle sto Eva stane. Ne moze da se ceka.
##
## Eva ima DUPLI SKOK - jedini nacin da prede sire reke lave.
##
## Namerno NIJE strasno za petogodisnjaka: nema mraka, nebo je toplo
## narandzasto (ne crno), a protivnici su isti puz i kornjaca koje dete
## vec poznaje. Napetost je u ritmu, ne u pretnji.
##
## Eva spasava mačka Garu.


func _setup() -> void:
	biome = "vulkan"
	start = Vector2(40, -40)
	fall_limit = 500.0
	power = "double_jump"
	set_friend(Vector2(2900, -44), "macak")

	set_decor(_draw_volcano)
	_build_terrain()
	_build_stars()
	_build_animals()
	_build_checkpoints()


func intro_text() -> String:
	return "Lava! Kamen puca.\nSkači dva puta: SPACE, SPACE"


func _build_terrain() -> void:
	# --- Deo 1: cvrsto crno kamenje, uci se da je lava opasna ---
	add_ground(Rect2(0, 0, 300, 60), "lava_rock")
	# Prva reka lave je uza (150px) - preskace se obicnim skokom.
	add_hazard(Rect2(300, 0, 150, 40), "lava")
	add_ground(Rect2(450, 0, 240, 60), "lava_rock")

	# --- Deo 2: prva SIROKA reka - samo dupli skok (230px) ---
	add_hazard(Rect2(690, 0, 230, 40), "lava")
	add_ground(Rect2(920, 0, 220, 60), "lava_rock")

	# --- Deo 3: KRHKO kamenje nad lavom ---
	# Ploce puknu, pa se ne moze cekati. Prva je usamljena, sa cvrstim
	# kamenom odmah posle - dete moze da pogresi bez kazne.
	add_hazard(Rect2(1140, 0, 300, 40), "lava")
	add_fragile(Rect2(1230, -40, 100, 18), "lava_rock", 1.0, 2.8)
	add_ground(Rect2(1440, 0, 220, 60), "lava_rock")

	# --- Deo 4: uspon uz stene, dalje od lave ---
	add_ground(Rect2(1580, -70, 76, 16), "lava_rock")
	add_ground(Rect2(1460, -136, 76, 16), "stone")
	add_ground(Rect2(1580, -202, 76, 16), "lava_rock")
	add_ground(Rect2(1700, -256, 180, 20), "stone")

	# --- Deo 5: DVE krhke ploce nad sirokom lavom ---
	# Sa visine y=-256 pad je velik, pa dupli skok nosi dovoljno.
	add_hazard(Rect2(1900, 0, 380, 40), "lava")
	add_fragile(Rect2(1990, -40, 95, 18), "lava_rock", 0.9, 2.6)
	add_fragile(Rect2(2130, -40, 95, 18), "lava_rock", 0.9, 2.6)
	add_ground(Rect2(2280, 0, 200, 60), "lava_rock")

	# --- Deo 6: poslednja reka pa macak na sigurnom ---
	add_ground(Rect2(2360, -80, 76, 16), "stone")
	add_hazard(Rect2(2480, 0, 210, 40), "lava")
	add_ground(Rect2(2690, 0, 340, 60), "lava_rock")
	add_ground(Rect2(2790, -76, 70, 16), "stone")


func _build_stars() -> void:
	add_star(Vector2(130, -34))
	add_star(Vector2(250, -34))
	# Trag preko prve reke - visoko, van lave.
	add_star_line(Vector2(330, -74), Vector2(420, -74), 3)
	add_star(Vector2(510, -34))

	# Siroka reka: luk duplog skoka.
	add_star(Vector2(710, -84))
	add_star(Vector2(770, -124))
	add_star(Vector2(840, -114))
	add_star(Vector2(900, -74))
	add_star(Vector2(980, -34))

	# Krhka ploca nad lavom.
	add_star(Vector2(1170, -90))
	add_star(Vector2(1280, -76))
	add_star(Vector2(1390, -90))
	add_star(Vector2(1500, -34))

	# Uspon.
	add_star(Vector2(1618, -104))
	add_star(Vector2(1498, -170))
	add_star(Vector2(1618, -236))
	add_star(Vector2(1760, -290))
	add_star(Vector2(1840, -290))

	# Dve krhke ploce - zvezdica nad svakom, vodi ritam.
	add_star(Vector2(1930, -200))
	add_star(Vector2(2038, -78))
	add_star(Vector2(2178, -78))
	add_star(Vector2(2340, -34))

	# Poslednja reka.
	add_star(Vector2(2398, -114))
	add_star(Vector2(2520, -90))
	add_star(Vector2(2610, -90))
	add_star(Vector2(2750, -34))
	add_star(Vector2(2824, -110))
	add_star(Vector2(2950, -34))


func _build_animals() -> void:
	add_animal("lavaguster", Vector2(530, -32))
	add_animal("skarabej", Vector2(1000, -32))
	add_animal("lavaguster", Vector2(1520, -32))
	add_animal("skarabej", Vector2(1780, -288))
	add_animal("lavaguster", Vector2(2340, -32))
	add_animal("skarabej", Vector2(2760, -32))


func _build_checkpoints() -> void:
	# Posle SVAKE reke lave i pre svakog niza krhkog kamena.
	for p in [Vector2(60, -36), Vector2(480, -36), Vector2(950, -36),
			Vector2(1470, -36), Vector2(1740, -292), Vector2(2310, -36),
			Vector2(2720, -36)]:
		add_checkpoint(p)


## Vulkan: krater u pozadini, tekuca lava, crne stene, pepeo i iskre.
##
## Namerno TOPLO, ne mracno: nebo je narandzasto a ne crno, i nema
## dima koji zaklanja vidljivost. Petogodisnjak treba da bude uzbudjen,
## ne uplasen.
func _draw_volcano(_lvl: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12630

	var bg := Node2D.new()
	bg.z_index = -6
	add_child(bg)

	# Zar na nebu - topao narandzasti sloj.
	Draw2D.poly(bg, Color(1, 0.55, 0.25, 0.3), [
		Vector2(-100, -300), Vector2(3200, -300),
		Vector2(3200, 60), Vector2(-100, 60)])

	# --- Veliki krater u pozadini ---
	var cx := 1500.0
	Draw2D.poly(bg, Color(0.24, 0.2, 0.22, 0.85), [
		Vector2(cx - 620, 60), Vector2(cx - 260, -300),
		Vector2(cx - 110, -370), Vector2(cx + 110, -370),
		Vector2(cx + 260, -300), Vector2(cx + 620, 60)])
	# Svetlija strana.
	Draw2D.poly(bg, Color(0.32, 0.27, 0.29, 0.85), [
		Vector2(cx - 620, 60), Vector2(cx - 260, -300),
		Vector2(cx - 110, -370), Vector2(cx - 60, -350),
		Vector2(cx - 300, -60), Vector2(cx - 420, 60)])
	# Zar u krateru.
	Draw2D.poly(bg, Color(1, 0.5, 0.15, 0.75), [
		Vector2(cx - 110, -370), Vector2(cx + 110, -370),
		Vector2(cx + 70, -342), Vector2(cx - 70, -342)])
	Draw2D.poly(bg, Color(1, 0.82, 0.3, 0.6), [
		Vector2(cx - 74, -366), Vector2(cx + 74, -366),
		Vector2(cx + 46, -348), Vector2(cx - 46, -348)])

	# Lava koja tece iz kratera - cetiri toka.
	for i in 4:
		var sx := cx + rng.randf_range(-170.0, 170.0)
		var pts := PackedVector2Array()
		var w := rng.randf_range(11.0, 22.0)
		var y := -340.0
		var x := sx
		pts.append(Vector2(x - w, y))
		var right := PackedVector2Array()
		while y < 56.0:
			x += rng.randf_range(-16.0, 16.0)
			y += rng.randf_range(38.0, 62.0)
			pts.append(Vector2(x - w, y))
			right.append(Vector2(x + w, y))
		for k in range(right.size() - 1, -1, -1):
			pts.append(right[k])
		pts.append(Vector2(sx + w, -340.0))
		var lv := Polygon2D.new()
		lv.color = Color(1, 0.42, 0.14, 0.7)
		lv.polygon = pts
		bg.add_child(lv)

	# --- Crne stene u prednjem planu ---
	for i in 20:
		var p := Vector2(rng.randf_range(-60.0, 3160.0), rng.randf_range(8.0, 44.0))
		var w := rng.randf_range(20.0, 54.0)
		var h := rng.randf_range(16.0, 40.0)
		var a := rng.randf_range(0.55, 0.85)
		Draw2D.poly(bg, Color(0.19, 0.16, 0.18, a), [
			p + Vector2(-w, h), p + Vector2(-w * 0.7, -h * 0.6),
			p + Vector2(-w * 0.1, -h), p + Vector2(w * 0.6, -h * 0.5),
			p + Vector2(w, h)])
		# Zareno dno - kao da tinja.
		Draw2D.poly(bg, Color(0.9, 0.35, 0.12, a * 0.5), [
			p + Vector2(-w * 0.8, h), p + Vector2(w * 0.8, h),
			p + Vector2(w * 0.7, h - 4), p + Vector2(-w * 0.7, h - 4)])

	# --- Mrtva drveta (flavor) ---
	for i in 9:
		var x := rng.randf_range(0.0, 3100.0)
		var h := rng.randf_range(50.0, 100.0)
		var col := Color(0.16, 0.13, 0.14, 0.7)
		Draw2D.poly(bg, col, [
			Vector2(x - 5, 44), Vector2(x + 5, 44),
			Vector2(x + 3, -h), Vector2(x - 3, -h)])
		for side in [-1.0, 1.0]:
			var by := -h * rng.randf_range(0.4, 0.8)
			Draw2D.poly(bg, col, [
				Vector2(x, by), Vector2(x + side * 26, by - 16),
				Vector2(x + side * 22, by - 8)])

	# --- Iskre i pepeo koji lete NAGORE ---
	for i in 34:
		var sx2 := rng.randf_range(-60.0, 3160.0)
		var sy := rng.randf_range(10.0, 50.0)
		var sz := rng.randf_range(2.5, 5.5)
		var em := Polygon2D.new()
		em.color = [Color(1, 0.72, 0.25, 0.85), Color(1, 0.45, 0.15, 0.8),
			Color(0.55, 0.5, 0.5, 0.6)][i % 3]
		em.polygon = PackedVector2Array([
			Vector2(0, -sz), Vector2(sz * 0.7, 0),
			Vector2(0, sz), Vector2(-sz * 0.7, 0)])
		em.position = Vector2(sx2, sy)
		bg.add_child(em)

		var rise := rng.randf_range(150.0, 380.0)
		var dur := rng.randf_range(3.0, 6.5)
		var tw := create_tween().set_loops()
		tw.tween_property(em, "position:y", sy - rise, dur).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(em, "modulate:a", 0.0, dur)
		tw.tween_callback(func() -> void:
			em.position.y = sy
			em.modulate.a = 1.0
		)
		# Blago se njise dok lete.
		var sway := create_tween().set_loops()
		sway.tween_property(em, "position:x", sx2 + rng.randf_range(12.0, 34.0),
			rng.randf_range(1.4, 2.6)).set_trans(Tween.TRANS_SINE)
		sway.tween_property(em, "position:x", sx2,
			rng.randf_range(1.4, 2.6)).set_trans(Tween.TRANS_SINE)
