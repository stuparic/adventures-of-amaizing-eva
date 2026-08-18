extends "res://scripts/levels/pecina_2.gd"
## NIVO — "Nađi različito 2" (Koralni rif)
##
## Ista igra kao pecina_2, ali TEZA: pet meta i vise rundi.
func _setup() -> void:
	# Pre super(): super() zove set_total_steps(rounds).
	rounds = 6
	slots = 5
	super()
	friend_kind = "rakic"
	biome = "rif"
	task_text = "Koji koral je različit?"
