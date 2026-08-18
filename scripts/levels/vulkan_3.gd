extends "res://scripts/levels/oblaci_2.gd"
## NIVO — "Ponovi vatru" (Vatrena gora)
##
## Ista igra kao oblaci_2 (ponovi redosled), tema vulkan.
## Vulkan je bio jedino ostrvo bez mini-igre.
func _setup() -> void:
	# Pre super(): super() zove set_total_steps(rounds).
	rounds = 4
	first_len = 2
	super()
	friend_kind = "feniks"
	biome = "vulkan"
	task_text = "Gledaj vatru pa ponovi!"
