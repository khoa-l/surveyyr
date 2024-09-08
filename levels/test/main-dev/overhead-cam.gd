extends Camera3D


@onready var track := $"../../"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	global_position = track.global_position
	position.y += 5.0
	rotation.y = track.rotation.y
