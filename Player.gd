extends CharacterBody3D

@export var static_world_map : GridMap = null
@export var interactables_map : GridMap = null

const SPEED = 2.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
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
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if (Input.is_action_just_pressed("interact") && is_on_floor()):
		_dig()

func _dig():
	if (interactables_map != null && static_world_map != null):
		var player_global_pos = self.position
		var cell_pos = to_global(interactables_map.map_to_local(player_global_pos))
		var cell_item = interactables_map.get_cell_item(cell_pos)
		var meshes = interactables_map.get_meshes()
		var mesh_library = interactables_map.mesh_library
		var item = mesh_library.find_item_by_name("ground_pathOpen2")
		player_global_pos.y = cell_pos.y / 2
		static_world_map.set_cell_item(interactables_map.local_to_map(player_global_pos), -1)
		interactables_map.set_cell_item(interactables_map.local_to_map(player_global_pos), item)

func _check_interactable():
	pass
		
