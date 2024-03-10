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
var can_water : bool = false
var water_component : WaterComponent = null

func _physics_process(delta):
	#if (raycast_down.is_colliding() || raycast_up.is_colliding() || raycast_right.is_colliding() || raycast_left.is_colliding()):
		#can_place = false
	#else:
		#can_place = true
		
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
	if direction:
		last_direction = direction
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if (Input.is_action_just_pressed("interact") && is_on_floor()):
		if can_place:
			_place_crop()
		elif can_water:
			_water_crop()

func _place_crop():
	can_place = false
	if (interactables_map != null):
		var cell_pos = interactables_map.to_global(self.position)
		var crop_corn = crop_scene.instantiate()
		crop_corn.global_position = cell_pos
		interactables_map.set_cell_item(interactables_map.local_to_map(to_local(cell_pos)), -1)
		interactables_map.add_child(crop_corn)

func _water_crop():
	# check if a crop is in front of the player
	# ideally, this should be the cell in front of the player
	# water crop
	water_component.water()
	can_water = false
		


func _on_area_3d_area_entered(area):
	var owner = area.owner
	var child = owner.get_node("WaterComponent")
	if child.is_in_group(WaterComponent.group_name):
		can_water = true
		can_place = false
		water_component = child

func _on_area_3d_area_exited(area):
	can_place = true
	can_water = false
