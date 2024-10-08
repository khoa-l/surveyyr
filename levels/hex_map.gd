class_name HexMap extends Node3D

var map_size = 25
var tile_size = 2
var texture
var tree_texture
var low_color = Color(0.2, 0.6, 0.2)
var high_color = Color(0.5, 0.5, 0.5)
var max_height = 10
var color_variation = 0.1
var tile_manager

@export var MIN_TREES := 0
@export var MAX_TREES := 4
@export var MIN_SCALE := 0.25
@export var MAX_SCALE := 0.50
@export var PLACEMENT_DIAMETER := 1.65
@export var MIN_TREE_SPACING := 0.25
@export var TREE_DISTRIBUTION_CURVE: Curve

func _ready() -> void:
	texture = NoiseTexture2D.new()
	texture.noise = FastNoiseLite.new()
	texture.noise.seed = randi()
	texture.noise.set_noise_type(FastNoiseLite.NoiseType.TYPE_SIMPLEX)
	texture.noise.set_fractal_gain(1.5)
	texture.noise.set_fractal_octaves(3)
	texture.noise.set_fractal_lacunarity(2.5)
	await texture.changed
	
	tile_manager = TileManager.new()
	
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
		
	generate_map()

func generate_map():
	var z
	
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			z = pow(floor(abs(texture.noise.get_noise_2d(x, y)) * 5), 2)
			
			if in_map(x, y):
				add_tile(x, y, z)

func add_tile(x, y, z):
	var tile
	for i in range(z + 1):
		var tile_type
		if i == z and z == 0:   
			tile = preload("res://bodies/tile/water.tscn").instantiate()
			tile_type = "water"
		elif i == z:
			tile = preload("res://bodies/tile/grass.tscn").instantiate()
			tile_type = "grass"
		else:
			tile = preload("res://bodies/tile/tile.tscn").instantiate()
			tile_type = "dirt"
			
		var offset = 0.0 if !(y % 2) else tile_size / 2
		add_child(tile)
		var pos = Vector3(x * tile_size - offset, i, y * tile_size - y * 0.3 * (tile_size / 2))
		tile.translate(pos)
		
		if tile_type == "grass":
			var num_trees = get_tree_count()
			place_trees(tile, pos, num_trees)
			tile_manager.store_tile_data(x, y, i, tile_type, pos, num_trees)
		else:
			tile_manager.store_tile_data(x, y, i, tile_type, pos, 0)

		
		if i > 0 or z > 0:
			apply_height_based_color(tile, z)
		

func place_trees(tile, tile_pos, num_trees):
	var attempts = 0
	var max_attempts = 100
	var placed_trees = []
	
	while len(placed_trees) < num_trees and attempts < max_attempts:
		var local_tree_pos = get_random_position()
		if is_valid_placement(local_tree_pos, placed_trees):
			place_tree(tile, local_tree_pos)
			placed_trees.append(local_tree_pos)
		attempts += 1

func get_tree_count() -> int:
	if TREE_DISTRIBUTION_CURVE:
		var t = randf()
		var distribution = TREE_DISTRIBUTION_CURVE.sample(t)
		return int(lerp(MIN_TREES, MAX_TREES, distribution))
	else:
		return randi_range(MIN_TREES, MAX_TREES)

func is_valid_placement(pos: Vector3, placed_trees: Array) -> bool:
	# Check if the position is within the placement diameter
	if pos.length() > PLACEMENT_DIAMETER / 2:
		return false
	
	# Check minimum spacing from other trees
	for tree in placed_trees:
		if pos.distance_to(tree) < MIN_TREE_SPACING:
			return false
	return true

func place_tree(parent_tile, local_pos):
	var tree = preload("res://bodies/tile/tree.tscn").instantiate()
	
	var random_scale = randf_range(MIN_SCALE, MAX_SCALE)
	tree.scale = Vector3(random_scale, random_scale, random_scale)
	
	var surface_normal = get_surface_normal(parent_tile.global_transform.origin + local_pos)
	var aligned_basis = align_up(tree.transform.basis, surface_normal)
	
	tree.transform = Transform3D(aligned_basis, local_pos)
	
	parent_tile.add_child(tree)

func get_random_position() -> Vector3:
	var radius = PLACEMENT_DIAMETER / 2
	var angle = randf() * TAU  # Random angle in radians
	var distance = sqrt(randf()) * radius  # Square root for uniform distribution
	var x = cos(angle) * distance
	var z = sin(angle) * distance
	return Vector3(x, 0, z)

func align_up(node_basis: Basis, normal: Vector3) -> Basis:
	var result = Basis()
	var size = node_basis.get_scale()
	result.x = normal.cross(node_basis.z).normalized()
	result.y = normal
	result.z = result.x.cross(normal).normalized()
	result = result.orthonormalized()
	result.x *= size.x 
	result.y *= size.y 
	result.z *= size.z 
	return result

func get_surface_normal(pos: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 50, pos + Vector3.DOWN * 50)
	var result = space_state.intersect_ray(query)
	if result:
		return result.normal
	return Vector3.UP

func apply_height_based_color(tile, height):
	var material = StandardMaterial3D.new()
	
	var blend_factor = clamp(float(height) / max_height, 0, 1)
	
	var base_color = low_color.lerp(high_color, blend_factor)
	
	var r_offset = randf_range(-color_variation, color_variation)
	var g_offset = randf_range(-color_variation, color_variation)
	var b_offset = randf_range(-color_variation, color_variation)
	
	var tile_color = Color(
		clamp(base_color.r + r_offset, 0, 1),
		clamp(base_color.g + g_offset, 0, 1),
		clamp(base_color.b + b_offset, 0, 1)
	)
	
	material.albedo_color = tile_color
	tile.get_child(0).set_material_override(material)

func in_map(x, y) -> bool:
	var r = ceil(map_size / 2)
	var cube = evenr_to_cube(Vector2(x, y))
	if cube.x <= r and cube.x >= -r and cube.y <= r and cube.y >= -r and cube.z <= r and cube.z >= -r:
		return true
	return false

func evenr_to_cube(hex):
	var q = hex.x - (hex.y + (int(hex.y)&1)) / 2
	var r = hex.y
	return Vector3(q, r, -q-r)

func cube_to_evenr(cube):
	var q = cube.x + (cube.y + (cube.y&1)) / 2
	var r = cube.y
	return Vector2(q, r)

# function for finding the world coords for the closest hex tile (x,z) only
func closest_hex(v: Vector3) -> Vector2:
	var x := v.x
	var y := v.z
	var t : float = tile_size # The base scale of the grid
	
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
		return p
	elif (not i.y % 2 and not i.x % 2):
		return p
	
	# CORRECTIVE ACTION
	var x_adj_p := Vector2(p.x-x_s, p.y) if p.x>x else Vector2(p.x+x_s, p.y)
	var y_adj_p := Vector2(p.x, p.y-y_s) if p.y>y else Vector2(p.x, p.y+y_s)
	if ((x_adj_p-Vector2(x, y)).length_squared() > (y_adj_p-Vector2(x, y)).length_squared()):
		return y_adj_p
	return x_adj_p
