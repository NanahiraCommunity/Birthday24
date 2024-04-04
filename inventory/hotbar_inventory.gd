extends PanelContainer
class_name Hotbar

signal hotbar_use(index: int)
signal hotbar_action(index: int)

const Slot = preload("res://inventory/slot.tscn")

@onready var h_box_container = $MarginContainer/HBoxContainer

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	
	if range(KEY_1, KEY_7).has(event.keycode):
		hotbar_use.emit(event.keycode - KEY_1)
		PlayerManager.selected_item_index = event.keycode - KEY_1
		hotbar_action.emit(event.keycode - KEY_1)
	
	if Input.is_action_just_pressed("hotbar_use"):
		hotbar_action.emit(PlayerManager.selected_item_index)
		hotbar_use.emit(PlayerManager.selected_item_index)
	
	if Input.is_action_just_pressed("hotbar_next"):
		if PlayerManager.selected_item_index == 5:
			PlayerManager.selected_item_index = 0
		else:
			PlayerManager.selected_item_index += 1
		hotbar_action.emit(PlayerManager.selected_item_index)
		
	if Input.is_action_just_pressed("hotbar_back"):
		if PlayerManager.selected_item_index == 0:
			PlayerManager.selected_item_index = 5
		else:
			PlayerManager.selected_item_index -= 1
	hotbar_action.emit(PlayerManager.selected_item_index)

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hotbar)
	populate_hotbar(inventory_data)
	hotbar_use.connect(inventory_data.use_slot_data)

func populate_hotbar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas.slice(0, 6):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		#slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		
		if slot_data:
			slot.set_slot_data(slot_data)
