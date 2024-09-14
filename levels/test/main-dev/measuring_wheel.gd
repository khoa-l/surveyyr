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
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and (player.position == where_to_be):
		traversed += 1
		var where := map.closest_hex(player.position+(direction * map.tile_size))
		where_to_be = Vector3(where.x, player.position.y, where.y)
	
	var dist := where_to_be - player.position
	if (dist.length() < 0.01):
		player.position = where_to_be
	else:
		var move : Vector3 = dist.normalized() * delta
		player.position += move

func _input(event):
	if event.is_action_pressed("s_wheel"):
		traversed = 0
		var p := is_physics_processing()
		call_deferred("set_physics_process", !p)
		label.visible = !p
		player.call_deferred("set_physics_process", p)
		var where := map.closest_hex(player.position)
		where_to_be = Vector3(where.x, player.position.y, where.y)
