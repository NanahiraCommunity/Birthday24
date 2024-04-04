extends Node

var player

var selected_item = null
var selected_item_index = 0
var can_place_crop = true

func use_slot_data(slot_data: SlotData) -> void:
	slot_data.item_data.use(player)
	player.interact()

func get_global_position() -> Vector3:
	return player.global_position
