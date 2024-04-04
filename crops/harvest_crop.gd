extends StaticBody3D

@export var drop: SlotData

func player_interact() -> void:
	print("harvest crop")
	if PlayerManager.player.inventory_data.pick_up_slot_data(drop):
			queue_free()
