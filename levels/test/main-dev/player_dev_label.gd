extends CanvasLayer

@onready var player : CharacterBody3D = $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/Surveyor"
@onready var player_view := $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/Surveyor/Head/Camera3D"
@onready var hex_map : HexMap = $"/root/Node/RenderContainer/SubViewportContainer/SubViewport/Main/HexMap"

@onready var hex_label := $"Control/MarginContainer/VBoxContainer/hexLabel"
@onready var position_label := $"Control/MarginContainer/VBoxContainer/positionLabel"
@onready var view_label := $"Control/MarginContainer/VBoxContainer/viewLabel"
@onready var coll_label := $"Control/MarginContainer/VBoxContainer2/collLabel"

@onready var hexes_traveled_label = $"Control/MarginContainer/VBoxContainer3/distLabel"
@onready var bearing_label = $"Control/MarginContainer/VBoxContainer3/compassLabel"

@onready var prev_hex := closest_hex(player.position)
var hexes_traveled := 0
func _process(delta):
	var hex := closest_hex(player.position)
	hex_label.text = "hex: %.2v" % [hex]
	if (not hex.is_equal_approx(prev_hex)):
		hexes_traveled+=1
	hexes_traveled_label.text = "Hexes Traveled: %d" % hexes_traveled
	prev_hex = hex
	
	bearing_label.text = "Bearing: %s" % bearing(player_view.global_rotation)
	
	position_label.text = "position: %.2v" % [player.position]
	view_label.text = "view angle: %.1v" % [player_view.global_rotation/PI/2 * 360.0]
	

func _physics_process(_delta):
	if (player.get_slide_collision_count()>0):
		var c := player.get_slide_collision(0)
		var s : CollisionShape3D = c.get_collider_shape(c.get_collider_shape_index())
		#print(PhysicsServer3D.body_get_direct_state(c.get_collider_rid()).transform)
		coll_label.text = "collision with: %.2v" % s.global_position

func bearing(r: Vector3):
	r /= 2*PI
	r += Vector3(.5,.5,.5)
	# vector has been normalized 0-1
	r *= 6
	var b: String
	match int(snapped(r.y, 1.0)):
		0, 6:
			b = "A"
		1:
			b = "F"
		2:
			b = "E"
		3:
			b = "S"
		4:
			b = "W"
		5:
			b = "V"
		_:
			b = "InvalidSign"
	var remainder = r.y - snapped(r.y, 1.0)
	b = "%s %s%dº" % [b,
		"+" if remainder > 0 else "-",
		int(snapped(abs(remainder*360/6),1))
	]
	return b

func closest_hex(v: Vector3) -> Vector2:
	var x := v.x
	var y := v.z
	var t : float = hex_map.tile_size # The base scale of the grid
	
	# y interval, the spacing between y values in square coords
	var y_s := t-0.3
	# x interval, the spacing between x...
	# x intervals are doubled, meaning only every other value is a real hex centerpoint
	var x_s := t/2.0
	
	# CHEAP COMPUTE
	var p : Vector2 = snapped(Vector2(x, y), Vector2(x_s, y_s))
	
	# find if p is valid. if so, return and leave program
	var i := Vector2i(int(p.y/y_s), int(p.x/x_s))
	# even x intervals are valid at even y intervals; odd x intervals are valid at odd y intervals
	if (i.y % 2 and i.x % 2): # true if both are odd
		#print("cheap double odd")
		#print("intervals: %.0v" % i)
		#print(p)
		return p
	elif (not i.y % 2 and not i.x % 2):
		#print("cheap double even")
		#print("intervals: %.0v" % i)
		#print(p)
		return p
	
	#print("proceeding with point correction")
	# CORRECTIVE ACTION
	var x_adj_p := Vector2(p.x-x_s, p.y) if p.x>x else Vector2(p.x+x_s, p.y)
	var y_adj_p := Vector2(p.x, p.y-y_s) if p.y>y else Vector2(p.x, p.y+y_s)
	if ((x_adj_p-Vector2(x, y)).length_squared() > (y_adj_p-Vector2(x, y)).length_squared()):
		return y_adj_p
	return x_adj_p
