# TileManager.gd
class_name TileManager
extends Node

var map_size = 25
var tile_size = 2

# Tile tracking dictionary
var tile_data: Dictionary = {}

static var instance : TileManager = null

func _init():
	if instance != null:
		push_error("TileManager already exists. Use TileManager.get_instance() instead.")
	else:
		instance = self

func get_instance():
	if instance == null:
		instance = TileManager.new()
		return instance
	else:
		return instance
		

func store_tile_data(x: int, y: int, z: int, tile_type: String, position: Vector3, number: int) -> void:
	var key = Vector3(x, y, z)
	tile_data[key] = {
		"type": tile_type,
		"position": position,
		"trees": number
	}
	
func get_tile_data(x: int, y: int, z: int) -> Dictionary:
	var key = Vector3(x, y, z)
	return tile_data.get(key, {})

func get_all_tile_data() -> Dictionary:
	return tile_data

func get_tiles_of_type(tile_type: String) -> Array:
	var tiles = []
	for key in tile_data:
		if tile_data[key]["type"] == tile_type:
			tiles.append({"coordinates": key, "data": tile_data[key]})
	return tiles

func update_tile_data(x: int, y: int, z: int, new_data: Dictionary) -> void:
	var key = Vector3(x, y, z)
	if key in tile_data:
		tile_data[key].merge(new_data)
