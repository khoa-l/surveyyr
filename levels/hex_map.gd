extends Node3D

var map_size = 50
var map_height = 3
var tile_size = 2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
		
	for z in range(map_height):
		_generate_map(z, map_size - (10 * z))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _generate_map(z, map_size):
	
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			if in_map(x, y):
				_add_tile(x, y, z)
			
func _add_tile(x, y, z):
	var tile = preload("res://bodies/tile/tile.tscn").instantiate()
	var offset = 0.0 if !(y % 2) else tile_size / 2
	
	add_child(tile)
	tile.translate(Vector3(x * tile_size - offset, z, y * tile_size - y * 0.3))

func in_map(x, y):
	var r = ceil(map_size / 2)
	var cube = evenr_to_cube(Vector2(x, y))
	if cube.x <= r and cube.x >= -r and cube.y <= r and cube.y >= -r and cube.z <= r and cube.z >= -r:
		return true
	return false

func evenr_to_cube(hex):
	var q = hex.x - (hex.y + (int(hex.y)&1)) / 2
	var r = hex.y
	return Vector3(q, r, -q-r)
