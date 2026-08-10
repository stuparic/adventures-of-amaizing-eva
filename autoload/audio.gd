extends Node
## Centralni audio menadzer. Autoload, dostupan svuda kao `Audio`.
##
## Svi zvukovi su generisani sinteticki (chiptune u C majoru) - nema
## eksternih fajlova, licenci ni preuzimanja.
##
## Koriscenje:
##   Audio.play("star")
##   Audio.play_music()
##   Audio.set_muted(true)

const SFX_PATH := "res://audio/sfx_%s.wav"

## Glasnost po zvuku u decibelima. Podesavaj ovde ako je nesto
## previse/premalo glasno u odnosu na ostalo.
const SFX_DB := {
	"jump": -8.0,
	"land": -14.0,
	"star": -7.0,
	"heart": -5.0,
	"stomp": -7.0,
	"hurt": -6.0,
	"checkpoint": -7.0,
	"meow": -4.0,
	"win": -4.0,
	"gameover": -6.0,
}

## Broj paralelnih SFX kanala. Zvezdice u nizu se ne prekidaju.
const VOICES := 10

const MUSIC_DB := -14.0        # muzika je tiha podloga, ne takmici se sa SFX
const MUSIC_DUCK_DB := -24.0   # jos tise dok traje fanfara

## --- SNIMLJENI GLAS (opciono) ---
## Ako postoji fajl audio/voice_win.wav (ili .ogg / .mp3), pusta se na
## pobednickom ekranu umesto sintetickе fanfare.
##
## Kako da snimis - vidi README, sekciju "Snimljeni glas".
## Fajl NE mora da postoji: ako ga nema, igra normalno radi sa fanfarom.
const VOICE_WIN_PATHS: Array[String] = [
	"res://audio/voice_win.wav",
	"res://audio/voice_win.ogg",
	"res://audio/voice_win.mp3",
]

## Glas je glasniji od svega - to je poruka detetu, mora da se cuje jasno.
const VOICE_DB := -1.0

## Dok glas govori, muzika se utisa jos vise da ne smeta razumevanju.
const MUSIC_DUCK_VOICE_DB := -30.0

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _voice_idx := 0
var _music: AudioStreamPlayer
var _music_win: AudioStreamPlayer
var _voice_win: AudioStreamPlayer
var _has_voice_win := false
var _muted := false
var _duck_tween: Tween = null

## Muzika i efekti se guse ODVOJENO.
##
## Ranije je postojao samo Master bus, pa je mute gasio sve. Sada su
## Music i Sfx zasebni busevi, a dugme u HUD-u kruzi kroz tri stanja:
##   SVE -> BEZ MUZIKE (efekti rade) -> TIHO (sve iskljuceno) -> SVE
## Dete tako moze da cuje "zvezdica!" i "bravo!" bez pozadinske muzike.
var _music_muted := false
var _sfx_muted := false

## Busevi se prave u kodu, ne preko default_bus_layout.tres - tako ne
## zavisi od uvoza resursa i radi isto na webu i na desktopu.
const BUS_MUSIC := "Music"
const BUS_SFX := "Sfx"


## Napravi Music i Sfx busove ako ih nema.
func _setup_buses() -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _ready() -> void:
	_setup_buses()
	# Ucitaj SFX-ove.
	for key: String in SFX_DB:
		var path: String = SFX_PATH % key
		var stream: AudioStream = load(path)
		if stream != null:
			_streams[key] = stream
		else:
			push_warning("Audio: nema fajla %s" % path)

	# Kanali za SFX.
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_voices.append(p)

	# Pozadinska muzika - loopuje se.
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	_music.volume_db = MUSIC_DB
	var loop_stream := load("res://audio/music_loop.wav") as AudioStreamWAV
	if loop_stream != null:
		# Loop se MORA postaviti runtime - Godot ne prenosi edit/loop_mode
		# iz .import fajla na ucitani AudioStreamWAV.
		# Granice racunaj iz trajanja, ne iz data.size(): velicina bajta po
		# frejmu zavisi od formata (PCM16 stereo = 4, ADPCM = drugacije).
		loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop_stream.loop_begin = 0
		loop_stream.loop_end = int(loop_stream.get_length() * loop_stream.mix_rate)
		_music.stream = loop_stream
	add_child(_music)

	# Pobednicka tema - ne loopuje.
	_music_win = AudioStreamPlayer.new()
	_music_win.bus = BUS_MUSIC
	_music_win.volume_db = MUSIC_DB + 4.0
	_music_win.stream = load("res://audio/music_win.wav")
	add_child(_music_win)

	_load_voice_win()
	_load_mode()


## Trazi snimljeni glas. Ako ga nema, igra radi normalno sa fanfarom.
func _load_voice_win() -> void:
	# Snimljeni glas ide na Sfx: to je poruka detetu, ne pozadinska
	# muzika - treba da se cuje i kad je muzika iskljucena.
	_voice_win = AudioStreamPlayer.new()
	_voice_win.bus = BUS_SFX
	_voice_win.volume_db = VOICE_DB
	add_child(_voice_win)

	for path in VOICE_WIN_PATHS:
		# ResourceLoader.exists() a ne load() - load() na fajl koji ne
		# postoji ispisuje gresku u konzolu.
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path)
		if stream == null:
			continue
		# Snimljeni glas ne sme da se vrti u petlji.
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = false
		elif stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = false
		_voice_win.stream = stream
		_has_voice_win = true
		print("Audio: snimljeni glas ucitan (%s, %.1fs)" % [path, stream.get_length()])
		return


func has_voice_win() -> bool:
	return _has_voice_win


## Pusti zvucni efekat. `name` je kljuc iz SFX_DB (bez "sfx_" prefiksa).
## `pitch_var` daje blagu varijaciju visine da ponavljanje ne zvuci robotski.
func play(name: String, pitch_var := 0.06) -> void:
	if _muted or not _streams.has(name):
		return

	var p := _voices[_voice_idx]
	_voice_idx = (_voice_idx + 1) % VOICES

	p.stream = _streams[name]
	p.volume_db = SFX_DB.get(name, -8.0)
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play_music() -> void:
	if _muted or _music.stream == null or _music.playing:
		return
	_music.play()


func stop_music() -> void:
	_music.stop()


## Utisaj muziku privremeno (dok traje fanfara ili glas), pa je vrati.
## Cuva referencu na tween: novi duck prekida stari, inace se dva tweena
## bore za volume_db i muzika ostane trajno utisana.
func duck_music(duration := 3.0, duck_to := MUSIC_DUCK_DB) -> void:
	if not _music.playing:
		return

	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()

	_duck_tween = create_tween()
	_duck_tween.tween_property(_music, "volume_db", duck_to, 0.3)
	_duck_tween.tween_interval(duration)
	_duck_tween.tween_property(_music, "volume_db", MUSIC_DB, 1.2)


## Pobednicka tema + utisana podloga.
func play_win_music() -> void:
	if _muted:
		return
	duck_music(6.0)
	_music_win.play()


## Pusti snimljeni glas i utisaj muziku dok govori.
## Vraca true ako glas postoji i pusten je.
func play_voice_win() -> bool:
	if _muted or not _has_voice_win:
		return false

	var dur := _voice_win.stream.get_length()
	_voice_win.play()

	# Utisaj muziku dok govori, pa je vrati. Ide kroz duck_music da bi
	# prekinuo eventualni prethodni duck (npr. od fanfare).
	duck_music(dur, MUSIC_DUCK_VOICE_DB)

	return true


## --- MUTE: jedno dugme, gasi SVE ---

const MODE_PATH := "user://audio.json"


## Iskljuci/ukljuci sav zvuk. Jedno dugme, gasi SVE - i muziku i efekte.
##
## Gusi Music i Sfx bus, NE Master. Master je zauzet: PauseMgr fejduje
## njegov volumen na -80dB kad se prozor minimizuje i vraca ga na
## zapamcenu vrednost. Kad se mute i taj fade preklope, Master ostane
## na tudjoj vrednosti i dugme naizgled ne radi.
##
## Odvojeni busevi resavaju to: mute i fade vise ne diraju isti kanal.
func set_muted(value: bool) -> void:
	_muted = value
	_music_muted = value
	_sfx_muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MUSIC), value)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_SFX), value)

	if value:
		# Zaustavi muziku, ne samo utisaj - inace tece nemo i posle
		# vracanja zvuka ulazi na sredini petlje.
		_music.stop()
		_music_win.stop()
	else:
		# Vrati muziku odmah: dete ne treba da ceka sledeci nivo da bi
		# cuo da je zvuk vracen.
		play_music()

	_save_mode()


func is_muted() -> bool:
	return _muted


func toggle_mute() -> void:
	set_muted(not _muted)


## --- Pamcenje izbora ---

func _save_mode() -> void:
	var f := FileAccess.open(MODE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"muted": _muted}))
	f.close()


func _load_mode() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		return
	var f := FileAccess.open(MODE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary and (parsed as Dictionary).has("muted"):
		# Primeni tiho, bez play_music() i bez ponovnog upisa.
		_muted = bool((parsed as Dictionary)["muted"])
		_music_muted = _muted
		_sfx_muted = _muted
		AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MUSIC), _muted)
		AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_SFX), _muted)
