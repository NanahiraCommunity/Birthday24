extends CharacterBody3D

signal toggle_inventory()

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray = $InteractRay

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip

#@export var static_world_map : GridMap = null
@export var interactables_map : GridMap = null

@export var equipped = {}

const SPEED = 2.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_direction = Vector3(1, 0, 0)

var health: int = 5
var defence: int = 5

var can_place : bool = true
var can_water : bool = false
var water_component : WaterComponent = null
var crop_mound = preload("res://interactables/crops/crop_mound.tscn")

var body

func _ready() -> void:
	PlayerManager.player = self

func _physics_process(delta: float) -> void:
	if interact_ray.is_colliding():
		var body = interact_ray.get_collider()
		if body and body.is_in_group("tilled_land"):
			PlayerManager.can_place_crop = true
	else:
		PlayerManager.can_place_crop = false
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			#interact_ray.rotation.y = -atan2(velocity.x, velocity.z)
	if velocity != Vector3.ZERO:
		var forward = -global_transform.basis.z
		var angle = forward.angle_to(velocity)
		if (last_direction == Vector3(1, 0, 0)):
			interact_ray.rotation.y = -angle
		else:
			interact_ray.rotation.y = angle
	if direction:
		last_direction = direction
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
	
	if Input.is_action_just_pressed("interact") && is_on_floor():
		interact()

func interact() -> void:
	if interact_ray.is_colliding():
		body = interact_ray.get_collider()
		if body.is_in_group("external_inventory") or body.is_in_group("harvestable"):
			interact_ray.get_collider().player_interact()

func get_drop_position() -> Vector3:
	return self.global_position + Vector3(0, 0, -2)

func heal(heal_value: int) -> void:
	health += heal_value

func increase_def(def_value: int, name: String) -> void:
	if !equipped.has(name):
		equipped[name] = def_value
		
		for items in equipped:
			defence += equipped[items]

func till_land() -> void:
	if (interactables_map != null and !interact_ray.is_colliding()):
		var map_pos = interactables_map.local_to_map(self.position)
		var cell_pos = interactables_map.map_to_local(map_pos)
		var crop = crop_mound.instantiate()
		crop.global_position = interactables_map.to_global(cell_pos * interactables_map.cell_size)
		interactables_map.add_child(crop)

func place_crop(crop_type: PlayerManager.CropType) -> void:
	if interact_ray.is_colliding():
		body = interact_ray.get_collider()
		if (interactables_map != null):
			if (body.is_in_group("tilled_land") && !body.is_in_group("crop")):
				body.place_crop(interactables_map, crop_type)
				PlayerManager.can_place_crop = false

func water_crop() -> void:
	if interact_ray.is_colliding():
		body = interact_ray.get_collider()
		if body.is_in_group("crop"):
			for child in body.get_children():
				if child is WaterComponent:
					child.water()
