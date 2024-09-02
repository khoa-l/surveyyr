extends CanvasLayer

@onready var player : CharacterBody3D = $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/Surveyor"
@onready var player_view := $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/Surveyor/Head/Camera3D"
@onready var hex_map : HexMap = $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/HexMap"

@onready var hex_label := $"Control/MarginContainer/VBoxContainer/hexLabel"
@onready var position_label := $"Control/MarginContainer/VBoxContainer/positionLabel"
@onready var view_label := $"Control/MarginContainer/VBoxContainer/viewLabel"
@onready var coll_label := $"Control/MarginContainer/VBoxContainer2/collLabel"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	hex_label.text = "hex: %.2v" % [closest_hex(player.position.x, player.position.z)]
	position_label.text = "position: %.2v" % [player.position]
	view_label.text = "view angle: %.1v" % [player_view.global_rotation/PI/2 * 360.0]
	

func _physics_process(_delta):
	if (player.get_slide_collision_count()>0):
		var c := player.get_slide_collision(0)
		var s : CollisionShape3D = c.get_collider_shape(c.get_collider_shape_index())
		#print(PhysicsServer3D.body_get_direct_state(c.get_collider_rid()).transform)
		coll_label.text = "collision with: %.2v" % s.global_position


func closest_hex(x: float, y: float):
	var t : float = hex_map.tile_size
	var y_s := t-0.3 # y interval, the spacing between y values in square coords
	var x_s := t/2
	var p : Vector2 = snapped(Vector2(x, y), Vector2(x_s, y_s))
	
	if (fmod(p.y/y_s, t)): # true if y is odd interval
		p.x = snappedf(p.x-x_s, t)+x_s
	else:
		p.x = snappedf(p.x, t)
		
	return p
