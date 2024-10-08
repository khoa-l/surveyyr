extends Node
# NOTE: This script uses an "effect" pattern. Talk to Garrett for details.

# The measuring wheel overrides the existing character controller.
# The player moves from hex to hex instead of freely

@onready var map : HexMap = $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/HexMap"

@onready var player : CharacterBody3D = $"../"
@onready var head : Node3D = $"../Head"

@onready var label = $"CanvasLayer/Control/CenterContainer/Label"

var where_to_be : Vector3
var traversed := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred("set_physics_process", false)
	label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	label.text = str(traversed)

func _physics_process(delta):
	# Normal gravity calc
	if player.gravity and not player.test_move(player.transform, Vector3(0,-0.01, 0)):
		player.velocity += player.get_gravity() * delta
	where_to_be.y = player.position.y # compensation for gravity
	
	# Test if we need to move to another hex
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and (player.position.is_equal_approx(where_to_be)):
		player.velocity = Vector3(0,0,0)
		var where := map.closest_hex(player.position+(direction * map.tile_size))
		var test_where_to_be = Vector3(where.x, player.position.y, where.y)
		
		# Successful move
		if (not player.test_move(player.transform, test_where_to_be - player.position)):
			traversed += 1
			where_to_be = test_where_to_be
	
	# Handling the automatic movement of player towards destination
	var dist := where_to_be - player.position
	if (dist.length() < 0.01):
		player.position = where_to_be
	else:
		var move : Vector3 = dist.normalized() * delta
		player.position += move
	# NOTE: velocity only used for gravity
	player.move_and_collide(player.velocity * delta)

func _input(event):
	if event.is_action_pressed("s_wheel"):
		var p := is_physics_processing() # get toggle variable
		traversed = 0 # reset hex counter
		# set hex we should be at
		var where := map.closest_hex(player.position)
		where_to_be = Vector3(where.x, player.position.y, where.y)
		
		# toggle all relevant states
		label.visible = !p
		call_deferred("set_physics_process", !p)
		player.set_deferred("velocity", Vector3(0,0,0))
		player.call_deferred("set_physics_process", p)
		player.call_deferred("set_collision_mask_value", 2, p)
