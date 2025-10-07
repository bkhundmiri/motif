extends RefCounted
class_name ApartmentInteriorGenerator

## Apartment Interior Generator
## Creates detailed apartment interiors based on JSON templates

# Constants for apartment generation
const WALL_HEIGHT = 2.8
const WALL_THICKNESS = 0.15
const DOOR_WIDTH = 0.9
const DOOR_HEIGHT = 2.1
const WINDOW_HEIGHT = 1.5

# Apartment layout cache for performance
static var layout_cache: Dictionary = {}
static var furniture_cache: Dictionary = {}

func generate_apartment_interior(apartment_type: String, position: Vector3, rotation: float = 0.0) -> Node3D:
	"""Generate a complete apartment interior from template"""
	
	# Load apartment layout template
	var layout_template = _load_apartment_template(apartment_type)
	if layout_template.is_empty():
		print("ERROR: Apartment template not found: %s" % apartment_type)
		return null
	
	# Create main apartment node
	var apartment = Node3D.new()
	apartment.name = "Apartment_%s" % apartment_type
	apartment.position = position
	apartment.rotation_degrees.y = rotation
	
	# Create apartment structure (walls, floors, ceiling)
	var structure = _create_apartment_structure(layout_template)
	if structure:
		apartment.add_child(structure)
	
	# Create rooms based on layout
	var rooms = _create_apartment_rooms(layout_template)
	if rooms:
		apartment.add_child(rooms)
	
	# Add furniture to rooms
	var furniture = _create_apartment_furniture(layout_template)
	if furniture:
		apartment.add_child(furniture)
	
	# Create doors and windows
	var openings = _create_doors_and_windows(layout_template)
	if openings:
		apartment.add_child(openings)
	
	# Add lighting
	var lighting = _create_apartment_lighting(layout_template)
	if lighting:
		apartment.add_child(lighting)
	
	return apartment

func _load_apartment_template(apartment_type: String) -> Dictionary:
	"""Load apartment template from JSON data"""
	
	# Check cache first
	if layout_cache.has(apartment_type):
		return layout_cache[apartment_type]
	
	# Load from JSON file
	var file_path = "res://data/world_generation/apartment_layouts.json"
	if not FileAccess.file_exists(file_path):
		print("ERROR: Apartment layouts file not found")
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open apartment layouts file")
		return {}
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		print("ERROR: Failed to parse apartment layouts JSON")
		return {}
	
	var apartment_layouts = json.data.get("apartment_layouts", {})
	var template = apartment_layouts.get(apartment_type, {})
	
	# Cache the template
	layout_cache[apartment_type] = template
	
	return template

func _create_apartment_structure(template: Dictionary) -> Node3D:
	"""Create basic apartment structure (floor, ceiling, exterior walls)"""
	
	var structure = Node3D.new()
	structure.name = "Structure"
	
	var dimensions = template.get("size", {"width": 12, "depth": 8})
	var width = dimensions.get("width", 12)
	var depth = dimensions.get("depth", 8)
	
	# Get color scheme for this apartment type
	var colors = template.get("color", {"wall": [0.9, 0.9, 0.9], "floor": [0.8, 0.8, 0.8]})
	var wall_color = Color(colors.wall[0], colors.wall[1], colors.wall[2])
	var floor_color = Color(colors.floor[0], colors.floor[1], colors.floor[2])
	
	# Create floor with color
	var floor_mesh = _create_colored_floor(width, depth, floor_color)
	structure.add_child(floor_mesh)
	
	# Create ceiling with color
	var ceiling = _create_colored_ceiling(width, depth, wall_color * 0.9)
	structure.add_child(ceiling)
	
	return structure

func _create_colored_floor(width: float, depth: float, color: Color) -> MeshInstance3D:
	"""Create apartment floor with specified color"""
	
	var floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, 0.1, depth)
	floor_mesh.mesh = box_mesh
	floor_mesh.position.y = -0.05
	
	# Floor material with custom color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	floor_mesh.material_override = material
	
	return floor_mesh

func _create_colored_ceiling(width: float, depth: float, color: Color) -> MeshInstance3D:
	"""Create apartment ceiling with specified color"""
	
	var ceiling = MeshInstance3D.new()
	ceiling.name = "Ceiling"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, 0.1, depth)
	ceiling.mesh = box_mesh
	ceiling.position.y = WALL_HEIGHT + 0.05
	
	# Ceiling material with custom color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	ceiling.material_override = material
	
	return ceiling

func _create_exterior_walls(width: float, depth: float) -> Node3D:
	"""Create exterior walls of apartment"""
	
	var walls = Node3D.new()
	walls.name = "ExteriorWalls"
	
	# Front wall (facing outward)
	var front_wall = _create_wall(width, WALL_HEIGHT, WALL_THICKNESS)
	front_wall.position = Vector3(0, WALL_HEIGHT/2, depth/2)
	walls.add_child(front_wall)
	
	# Back wall
	var back_wall = _create_wall(width, WALL_HEIGHT, WALL_THICKNESS)
	back_wall.position = Vector3(0, WALL_HEIGHT/2, -depth/2)
	walls.add_child(back_wall)
	
	# Left wall
	var left_wall = _create_wall(WALL_THICKNESS, WALL_HEIGHT, depth)
	left_wall.position = Vector3(-width/2, WALL_HEIGHT/2, 0)
	walls.add_child(left_wall)
	
	# Right wall
	var right_wall = _create_wall(WALL_THICKNESS, WALL_HEIGHT, depth)
	right_wall.position = Vector3(width/2, WALL_HEIGHT/2, 0)
	walls.add_child(right_wall)
	
	return walls

func _create_wall(width: float, height: float, thickness: float) -> MeshInstance3D:
	"""Create a single wall mesh"""
	
	var wall = MeshInstance3D.new()
	wall.name = "Wall"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, height, thickness)
	wall.mesh = box_mesh
	
	# Wall material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.85)  # Off-white wall
	wall.material_override = material
	
	return wall

func _create_apartment_rooms(template: Dictionary) -> Node3D:
	"""Create interior room divisions"""
	
	var rooms = Node3D.new()
	rooms.name = "Rooms"
	
	var layout = template.get("layout", {})
	var colors = template.get("color", {"wall": [0.9, 0.9, 0.9], "floor": [0.8, 0.8, 0.8]})
	var wall_color = Color(colors.wall[0], colors.wall[1], colors.wall[2])
	
	# Create room walls based on layout
	for room_name in layout.keys():
		var room_data = layout[room_name]
		var room_walls = _create_room_walls(room_data, wall_color, room_name)
		if room_walls:
			rooms.add_child(room_walls)
	
	return rooms

func _create_room_walls(room_data: Dictionary, wall_color: Color, room_name: String) -> Node3D:
	"""Create walls for a specific room"""
	
	var room_walls = Node3D.new()
	room_walls.name = "%s_Walls" % room_name
	
	var x = room_data.get("x", 0)
	var y = room_data.get("y", 0)  # This is actually Z in 3D space
	var width = room_data.get("width", 2)
	var depth = room_data.get("depth", 2)
	
	# Create room perimeter walls
	# Front wall
	var front_wall = _create_colored_wall(width, WALL_HEIGHT, WALL_THICKNESS, wall_color)
	front_wall.position = Vector3(x + width/2, WALL_HEIGHT/2, y + depth)
	front_wall.name = "%s_FrontWall" % room_name
	room_walls.add_child(front_wall)
	
	# Back wall
	var back_wall = _create_colored_wall(width, WALL_HEIGHT, WALL_THICKNESS, wall_color)
	back_wall.position = Vector3(x + width/2, WALL_HEIGHT/2, y)
	back_wall.name = "%s_BackWall" % room_name
	room_walls.add_child(back_wall)
	
	# Left wall
	var left_wall = _create_colored_wall(WALL_THICKNESS, WALL_HEIGHT, depth, wall_color)
	left_wall.position = Vector3(x, WALL_HEIGHT/2, y + depth/2)
	left_wall.name = "%s_LeftWall" % room_name
	room_walls.add_child(left_wall)
	
	# Right wall
	var right_wall = _create_colored_wall(WALL_THICKNESS, WALL_HEIGHT, depth, wall_color)
	right_wall.position = Vector3(x + width, WALL_HEIGHT/2, y + depth/2)
	right_wall.name = "%s_RightWall" % room_name
	room_walls.add_child(right_wall)
	
	return room_walls

func _create_colored_wall(width: float, height: float, thickness: float, color: Color) -> MeshInstance3D:
	"""Create a single wall mesh with specified color"""
	
	var wall = MeshInstance3D.new()
	wall.name = "Wall"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, height, thickness)
	wall.mesh = box_mesh
	
	# Wall material with custom color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	wall.material_override = material
	
	return wall

func _create_apartment_furniture(template: Dictionary) -> Node3D:
	"""Create furniture based on apartment layout"""
	
	var furniture = Node3D.new()
	furniture.name = "Furniture"
	
	var _furniture_layout = template.get("furniture_layout", {})
	var dimensions = template.get("size", {"width": 12, "depth": 8})
	
	# Create basic furniture for the apartment type
	var apartment_type = template.get("type", "studio")
	
	# Always add basic furniture
	var bed = _create_furniture_piece("bed", Vector3(dimensions.width/3, 0.3, dimensions.depth/3))
	furniture.add_child(bed)
	
	var sofa = _create_furniture_piece("sofa", Vector3(-dimensions.width/4, 0.4, -dimensions.depth/4))
	furniture.add_child(sofa)
	
	var table = _create_furniture_piece("table", Vector3(0, 0.4, -dimensions.depth/3))
	furniture.add_child(table)
	
	# Add type-specific furniture
	if apartment_type != "studio":
		var desk = _create_furniture_piece("desk", Vector3(-dimensions.width/3, 0.4, dimensions.depth/4))
		furniture.add_child(desk)
	
	return furniture

func _create_furniture_piece(furniture_type: String, position: Vector3) -> MeshInstance3D:
	"""Create a single furniture piece"""
	
	var furniture = MeshInstance3D.new()
	furniture.name = furniture_type.capitalize()
	furniture.position = position
	
	var box_mesh = BoxMesh.new()
	var material = StandardMaterial3D.new()
	
	# Set size and color based on furniture type
	match furniture_type:
		"bed":
			box_mesh.size = Vector3(2.0, 0.6, 1.5)
			material.albedo_color = Color(0.4, 0.3, 0.2)  # Brown
		"sofa":
			box_mesh.size = Vector3(1.8, 0.8, 0.9)
			material.albedo_color = Color(0.2, 0.4, 0.6)  # Blue
		"table":
			box_mesh.size = Vector3(1.2, 0.8, 0.8)
			material.albedo_color = Color(0.6, 0.4, 0.2)  # Wood
		"desk":
			box_mesh.size = Vector3(1.5, 0.8, 0.6)
			material.albedo_color = Color(0.5, 0.5, 0.5)  # Gray
		_:
			box_mesh.size = Vector3(1.0, 1.0, 1.0)
			material.albedo_color = Color(0.5, 0.5, 0.5)
	
	furniture.mesh = box_mesh
	furniture.material_override = material
	
	return furniture

func _create_doors_and_windows(template: Dictionary) -> Node3D:
	"""Create doors and windows for the apartment"""
	
	var openings = Node3D.new()
	openings.name = "Openings"
	
	var dimensions = template.get("dimensions", {"width": 12, "depth": 8})
	
	# Create main entrance door
	var door = _create_door(Vector3(0, DOOR_HEIGHT/2, -dimensions.depth/2))
	openings.add_child(door)
	
	# Create window (facing outward)
	var window = _create_window(Vector3(dimensions.width/3, WINDOW_HEIGHT/2, dimensions.depth/2))
	openings.add_child(window)
	
	return openings

func _create_door(position: Vector3) -> MeshInstance3D:
	"""Create a door"""
	
	var door = MeshInstance3D.new()
	door.name = "Door"
	door.position = position
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(DOOR_WIDTH, DOOR_HEIGHT, 0.05)
	door.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.25, 0.1)  # Dark wood
	door.material_override = material
	
	return door

func _create_window(position: Vector3) -> MeshInstance3D:
	"""Create a window"""
	
	var window = MeshInstance3D.new()
	window.name = "Window"
	window.position = position
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.5, WINDOW_HEIGHT, 0.05)
	window.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.9, 1.0, 0.3)  # Light blue glass
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	window.material_override = material
	
	return window

func _create_apartment_lighting(_template: Dictionary) -> Node3D:
	"""Create basic lighting for the apartment"""
	
	var lighting = Node3D.new()
	lighting.name = "Lighting"
	
	# Create central ceiling light
	var ceiling_light = OmniLight3D.new()
	ceiling_light.position = Vector3(0, WALL_HEIGHT - 0.2, 0)
	ceiling_light.light_energy = 1.0
	ceiling_light.omni_range = 8.0
	ceiling_light.light_color = Color(1.0, 0.95, 0.8)  # Warm white
	lighting.add_child(ceiling_light)
	
	return lighting

# Static function to clear caches
static func clear_caches():
	"""Clear apartment layout and furniture caches"""
	layout_cache.clear()
	furniture_cache.clear()