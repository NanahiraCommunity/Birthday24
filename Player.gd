extends CharacterBody3D

@export var static_world_map : GridMap = null
@export var interactables_map : GridMap = null
var crop_scene = preload("res://crops/corn_stage_a.tscn")

const SPEED = 2.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_direction = Vector3(1, 0, 0)

@onready var raycast_down : RayCast3D = $RCDown
@onready var raycast_up : RayCast3D = $RCUp
@onready var raycast_right : RayCast3D = $RCRight
@onready var raycast_left : RayCast3D = $RCLeft

var can_place : bool = true

func _physics_process(delta):
	if (raycast_down.is_colliding() || raycast_up.is_colliding() || raycast_right.is_colliding() || raycast_left.is_colliding()):
		can_place = false
	else:
		can_place = true
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		last_direction = direction
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if (Input.is_action_just_pressed("interact") && is_on_floor() && can_place):
		_place_crop()

func _place_crop():
	if (interactables_map != null && static_world_map != null):
		var player_global_pos = self.position
		var cell_pos = to_global(interactables_map.map_to_local(player_global_pos))
		var cell_item = interactables_map.get_cell_item(cell_pos)
		var cell_bases = interactables_map.get_cell_item_basis(cell_pos)
		var meshes = interactables_map.get_meshes()
		var mesh_library = interactables_map.mesh_library
		var item = mesh_library.find_item_by_name("crops_cornStageA2")
		player_global_pos.y = cell_pos.y / 2
		if (last_direction.x == 1):
			player_global_pos.x += 0.5
			
		elif (last_direction.x == -1):
			player_global_pos.x -= 0.5
		elif (last_direction.z == 1):
			player_global_pos.z += 0.5
		elif (last_direction.z == -1):
			player_global_pos.z -= 0.5
		#static_world_map.set_cell_item(interactables_map.local_to_map(player_global_pos), -1)
		#interactables_map.set_cell_item(interactables_map.local_to_map(player_global_pos), item)
		var instance = crop_scene.instantiate()
		instance.position = player_global_pos
		#instance.position.x = player_global_pos.x / 2
		#instance.position.y = player_global_pos.y / 2
		#instance.position.z = player_global_pos.z / 2
		interactables_map.add_child(instance)
		print("placed")
		
		

func _check_interactable():
	pass
		
