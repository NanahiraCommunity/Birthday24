extends CharacterBody3D

signal toggle_inventory()

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip

@export var static_world_map : GridMap = null
@export var interactables_map : GridMap = null
var crop_scene = preload("res://crops/corn_stage_a.tscn")

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

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray = $InteractRay

func _ready() -> void:
	PlayerManager.player = self

func _physics_process(delta):
	#if (raycast_down.is_colliding() || raycast_up.is_colliding() || raycast_right.is_colliding() || raycast_left.is_colliding()):
		#can_place = false
	#else:
		#can_place = true
	
	if interact_ray.is_colliding():
		PlayerManager.can_place_crop = false
	else:
		PlayerManager.can_place_crop = true
		
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
	#if event is InputEventMouseMotion:
		#rotate_y(-event.relative.x * .005)
		#camera.rotate_x(-event.relative.y * .005)
		#camera.rotation.x = clamp(camera.rotation.x, -PI/4, PI/4)
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
	
	if Input.is_action_just_pressed("interact") && is_on_floor():
		interact()

func interact() -> void:
	print("interacting")
	if interact_ray.is_colliding():
		var body = interact_ray.get_collider()
		if body.is_in_group("external inventory"):
			interact_ray.get_collider().player_interact()

func get_drop_position() -> Vector3:
	#print(self.global_position)
	return self.global_position + Vector3(0, 0, -2)
	#var direction = -camera.global_transform.basis.z
	#return self.global_position + direction

func heal(heal_value: int) -> void:
	health += heal_value

func increase_def(def_value: int, name: String) -> void:
	if !equipped.has(name):
		equipped[name] = def_value
		
		for items in equipped:
			defence += equipped[items]

func place_crop():
	print("placing crop")
	can_place = false
	if (interactables_map != null):
		var cell_pos = interactables_map.to_global(self.position)
		var crop_corn = crop_scene.instantiate()
		crop_corn.global_position = cell_pos
		crop_corn.position.y = 1
		interactables_map.set_cell_item(interactables_map.local_to_map(to_local(cell_pos)), -1)
		interactables_map.add_child(crop_corn)

func water_crop():
	print("watering crop")
	if interact_ray.is_colliding():
		var body = interact_ray.get_collider()
		if body.is_in_group("crop"):
			for child in body.get_children():
				if child is WaterComponent:
					child.water()

func _on_area_3d_area_entered(area):
	pass
	#var owner = area.owner
	#var child = owner.get_node("WaterComponent")
	#if child.is_in_group(WaterComponent.group_name):
		#can_water = true
		#can_place = false
		#water_component = child

func _on_area_3d_area_exited(area):
	can_place = true
	can_water = false
