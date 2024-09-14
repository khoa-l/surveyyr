extends Node
# NOTE: This script uses an "effect" pattern. Talk to Garrett for details.

# The measuring wheel overrides the existing character controller.
# The player moves from hex to hex instead of freely

@onready var player : CharacterBody3D = get_parent()
@onready var head : Node3D = player.head

# Called when the node enters the scene tree for the first time.
func _ready():
	#player.call_deferred("set_physics_process", false)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
