extends Node3D

var map_size = 100
var tile_size = 2
var texture


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture = NoiseTexture2D.new()
	texture.noise = FastNoiseLite.new()
	texture.noise.set_noise_type(FastNoiseLite.NoiseType.TYPE_SIMPLEX)
	texture.noise.set_fractal_gain(0.5)
	texture.noise.set_fractal_octaves(3)
	texture.noise.set_fractal_lacunarity(2.5)
	await texture.changed
	
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
		
	_generate_map()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _generate_map():
	var z
	
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			z = pow(floor(abs(texture.noise.get_noise_2d(x, y)) * 5), 2)
			
			if in_map(x, y):
				_add_tile(x, y, z)
			
func _add_tile(x, y, z):
	var tile
	for i in range(z + 1):
		if i == z and z == 0:	
			tile = preload("res://bodies/tile/water.tscn").instantiate()
		elif i == z:
			tile = preload("res://bodies/tile/grass.tscn").instantiate()
		else:
			tile = preload("res://bodies/tile/tile.tscn").instantiate()

			
		var offset = 0.0 if !(y % 2) else tile_size / 2

		add_child(tile)
		tile.translate(Vector3(x * tile_size - offset, i, y * tile_size - y * 0.3 * (tile_size / 2)))

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
