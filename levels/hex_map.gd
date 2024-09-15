class_name HexMap
extends Node3D

const WATER_TILE = preload("res://bodies/tile/water.tscn")
const GRASS_TILE = preload("res://bodies/tile/grass.tscn")
const DIRT_TILE = preload("res://bodies/tile/tile.tscn")
const TREE = preload("res://bodies/tile/tree.tscn")

@export var map_size: int = 25
@export var tile_size: float = 2.0
@export var max_height: int = 10
@export var low_color: Color = Color(0.2, 0.6, 0.2)
@export var high_color: Color = Color(0.5, 0.5, 0.5)
@export var terrain_color_variation: float = 0.1

@export_group("Tree Settings")
@export var tree_density: float = 0.5
@export var max_trees_per_tile: int = 5
@export var min_tree_spacing: float = 0.25
@export var tree_noise_scale: float = 0.1
@export var min_scale: float = 0.25
@export var max_scale: float = 0.50

var terrain_noise: NoiseTexture2D
var tree_noise: NoiseTexture2D
var tile_manager: TileManager

func _ready() -> void:
	randomize()
	terrain_noise = create_noise_texture()
	tree_noise = create_noise_texture()
	tile_manager = TileManager.new()
	
	clear_existing_map()
	generate_map()

func create_noise_texture() -> NoiseTexture2D:
	var texture = NoiseTexture2D.new()
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_gain = 1.5
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 2.5
	texture.noise = noise
	return texture

func clear_existing_map() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func generate_map() -> void:
	await terrain_noise.changed
	await tree_noise.changed
	
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			var height = calculate_height(x, y)
			if in_map(x, y, map_size):
				add_tile(x, y, height)
			elif in_map(x, y, map_size + 1):
				add_border_tile(x, y, height)

func calculate_height(x: int, y: int) -> int:
	return pow(floor(abs(terrain_noise.noise.get_noise_2d(x, y)) * 5), 2)

func add_tile(x: int, y: int, height: int) -> void:
	for i in range(height + 1):
		var tile_type = get_tile_type(i, height)
		var tile = instantiate_tile(tile_type)
		var pos = calculate_tile_position(x, y, i)
		add_child(tile)
		tile.translate(pos)
		
		var num_trees = 0
		if tile_type == "grass":
			num_trees = calculate_num_trees(pos)
			place_trees(tile, pos, num_trees)
		
		tile_manager.store_tile_data(x, y, i, tile_type, pos, num_trees)
		
		if i > 0 or height > 0:
			apply_height_based_color(tile, height)
			
func calculate_num_trees(pos: Vector3) -> int:
	var noise_value = tree_noise.noise.get_noise_2d(pos.x * tree_noise_scale, pos.z * tree_noise_scale)
	var normalized_noise = (noise_value + 1) / 2  # Convert from [-1, 1] to [0, 1]
	var tree_count = int(normalized_noise * tree_density * max_trees_per_tile)
	return clamp(tree_count, 0, max_trees_per_tile)

func get_tile_type(current_height: int, max_height: int) -> String:
	if current_height == max_height:
		return "grass" if max_height > 0 else "water"
	return "dirt"

func instantiate_tile(tile_type: String) -> Node3D:
	match tile_type:
		"water": return WATER_TILE.instantiate()
		"grass": return GRASS_TILE.instantiate()
		_: return DIRT_TILE.instantiate()

func calculate_tile_position(x: int, y: int, height: int) -> Vector3:
	var offset = 0.0 if !(y % 2) else tile_size / 2
	return Vector3(
		x * tile_size - offset,
		height,
		y * tile_size - y * 0.3 * (tile_size / 2)
	)

func add_border_tile(x: int, y: int, height: int) -> void:
	for i in range(height + 1):
		var tile = DIRT_TILE.instantiate()
		tile.get_child(0).visible = false
		add_child(tile)
		tile.translate(calculate_tile_position(x, y, i))

func place_trees(tile: Node3D, tile_pos: Vector3, num_trees: int) -> void:
	var placed_trees = []
	for _i in range(num_trees):
		var attempts = 0
		while attempts < 100:
			var local_tree_pos = get_random_position()
			if is_valid_tree_placement(local_tree_pos, placed_trees):
				place_tree(tile, local_tree_pos)
				placed_trees.append(local_tree_pos)
				break
			attempts += 1

func get_random_position() -> Vector3:
	var radius = tile_size / 2
	var angle = randf() * TAU
	var distance = sqrt(randf()) * radius
	return Vector3(cos(angle) * distance, 0, sin(angle) * distance)

func is_valid_tree_placement(pos: Vector3, placed_trees: Array) -> bool:
	for tree in placed_trees:
		if pos.distance_to(tree) < min_tree_spacing:
			return false
	return true

func apply_vertical_gradient(noise_value: float, y: float) -> float:
	var gradient = 1.0 - (y / float(max_height))
	return noise_value * pow(gradient, 2)

func place_tree(parent_tile: Node3D, local_pos: Vector3) -> void:
	var tree = TREE.instantiate()
	var random_scale = randf_range(min_scale, max_scale)
	tree.scale = Vector3.ONE * random_scale
	
	var global_pos = parent_tile.global_transform.origin + local_pos
	var surface_normal = get_surface_normal(global_pos)
	var aligned_basis = align_up(tree.transform.basis, surface_normal)
	
	tree.transform = Transform3D(aligned_basis, local_pos)
	parent_tile.add_child(tree)

func get_surface_normal(pos: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 50, pos + Vector3.DOWN * 50)
	var result = space_state.intersect_ray(query)
	return result.normal if result else Vector3.UP

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

func apply_height_based_color(tile: Node3D, height: int) -> void:
	var material = StandardMaterial3D.new()
	var blend_factor = clamp(float(height) / max_height, 0, 1)
	var base_color = low_color.lerp(high_color, blend_factor)
	
	var color_offset = Vector3(
		randf_range(-terrain_color_variation, terrain_color_variation),
		randf_range(-terrain_color_variation, terrain_color_variation),
		randf_range(-terrain_color_variation, terrain_color_variation)
	)
	
	var tile_color = Color(
		clamp(base_color.r + color_offset.x, 0, 1),
		clamp(base_color.g + color_offset.y, 0, 1),
		clamp(base_color.b + color_offset.z, 0, 1)
	)
	
	material.albedo_color = tile_color
	tile.get_child(0).set_material_override(material)

func in_map(x: int, y: int, size: int) -> bool:
	var r = ceil(size / 2)
	var cube = evenr_to_cube(Vector2(x, y))
	return abs(cube.x) <= r and abs(cube.y) <= r and abs(cube.z) <= r

func evenr_to_cube(hex: Vector2) -> Vector3:
	var q = hex.x - (hex.y + (int(hex.y) & 1)) / 2
	var r = hex.y
	return Vector3(q, r, -q-r)

func cube_to_evenr(cube: Vector3) -> Vector2:
	var q = cube.x + (cube.y + (int(cube.y) & 1)) / 2
	var r = cube.y
	return Vector2(q, r)
