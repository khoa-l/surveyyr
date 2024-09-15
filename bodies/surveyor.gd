extends CharacterBody3D

const SPEED = 1.0
const JUMP_VELOCITY = 2.5
const CLIMB_SPEED = 0.25
const SENSITIVITY = 0.005

var is_climbing = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var wall_check = $Head/WallCheck
@onready var ledge_check = $Head/LedgeCheck

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	handle_climbing()
	
	# Add gravity when not climbing
	if not is_climbing and not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_climbing:
		handle_climbing_movement(direction, delta)
	else:
		handle_normal_movement(direction, delta)
	
	move_and_slide()

func handle_normal_movement(direction: Vector3, delta: float) -> void:
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 2.0)

func handle_climbing_movement(direction: Vector3, delta: float) -> void:
	var rot = -(atan2(wall_check.get_collision_normal().z, wall_check.get_collision_normal().x) - PI/2)
	var f_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var h_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction = Vector3(h_input, f_input, 0).rotated(Vector3.UP, rot).normalized()
	
	velocity = direction * CLIMB_SPEED

func handle_climbing() -> void:
	if wall_check.is_colliding():
		var collider = wall_check.get_collider()
		if collider and collider.get_parent().name != "TreeTrunk":
			if ledge_check.is_colliding():
				is_climbing = true
			else:
				velocity.y = JUMP_VELOCITY
				is_climbing = false
	else:
		is_climbing = false
