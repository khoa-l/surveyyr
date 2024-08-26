extends CharacterBody3D


const SPEED = 1.0
const JUMP_VELOCITY = 2.5
const CLIMB_SPEED = 0.25
const SENSITIVITY = 0.005

var is_climbing = false

@onready var head = $Head
@onready var camera = $Head/Camera3D

@onready var wall_check = $Head/WallCheck
@onready var ledge_check = $Head/LedgeCheck

var gravity = true

func _read():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	climbing()
	# Add the gravity.
	if gravity and not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not is_climbing and is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.y * SPEED, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.y * SPEED, delta * 2.0)
		
	if is_climbing:
		direction = Vector3.ZERO
		gravity = Vector3.ZERO
		
		var rot = -(atan2(wall_check.get_collision_normal().z, wall_check.get_collision_normal().x) - PI/2)
		var f_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
		var h_input = Input.get_action_strength("ui_right") - Input.get_action_raw_strength("ui_left")
		direction = Vector3(h_input, f_input, 0).rotated(Vector3.UP, rot).normalized()

	move_and_slide()
	
func climbing():
	if wall_check.is_colliding():
		if wall_check.get_collider().get_parent().name != "TreeTrunk":
			if ledge_check.is_colliding():
				is_climbing = true
				gravity = false
			else:
				velocity.y = JUMP_VELOCITY
				is_climbing = false
				gravity = true
	else:
		is_climbing = false
		gravity = true
	
