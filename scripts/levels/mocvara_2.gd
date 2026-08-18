extends "res://scripts/levels/podvodni_2.gd"
## NIVO — "Uklopi oblike 2" (Zelena močvara)
##
## Ista igra kao podvodni_2, ali TEZA: vise rundi.
##
## Nasledjuje podvodni_2 umesto da kopira 159 linija - logika uklapanja je
## identicna, menja se samo tema, prijatelj i broj rundi.
func _setup() -> void:
	# rounds MORA pre super(): super() gradi listu rundi i zove
	# set_total_steps, pa bi kasnija promena dala pogresan broj koraka.
	rounds = 7
	super()
	friend_kind = "vidra"
	biome = "mocvara"
	task_text = "Uklopi oblik u pravi otvor!"
