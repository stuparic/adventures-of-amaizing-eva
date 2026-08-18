extends "res://scripts/levels/oblaci_2.gd"
## NIVO — "Ponovi melodiju" (Bambusov gaj)
##
## Ista igra kao oblaci_2, ali TEZA: nizovi pocinju od 3 clana.
##
## Nasledjuje oblaci_2 - logika je identicna, menja se tema i tezina.
func _setup() -> void:
	# Pre super(): super() zove set_total_steps(rounds).
	rounds = 5
	first_len = 3
	super()
	friend_kind = "zmajcic"
	biome = "bambus"
	task_text = "Zapamti melodiju pa je ponovi!"
