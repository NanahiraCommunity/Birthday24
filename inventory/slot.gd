extends PanelContainer

signal slot_clicked(index: int, button: int)

@onready var texture_rect = $MarginContainer/TextureRect
@onready var color_rect = $MarginContainer/ColorRect
@onready var quantity_label = $QuantityLabel
@onready var hotbar = get_node("/root/Sandbox/UI/Inventory/HotbarInventory")

func _ready() -> void:
	hotbar.hotbar_action.connect(set_selected_slot)
	set_selected_slot(PlayerManager.selected_item_index)

func set_selected_slot(index: int) -> void:
	#var children = get_tree().get_nodes_in_group("hotbar_slots")[0].get_children()
	#for _slot in children:
		#print(_slot)
	if index == get_index():
		color_rect.show()
	else:
		color_rect.hide()

func set_slot_data(slot_data: SlotData) -> void:
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.texture
	tooltip_text = "%s\n%s" % [item_data.name, item_data.description]
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
