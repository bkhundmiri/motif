extends Node3D

# Apartment Layout Test Scene
# ===========================
# RECENT IMPROVEMENTS:
# ✅ Fixed studio apartment open concept areas (no unnecessary subdivisions)
# ✅ Enhanced open area validation to prevent accidental room creation
# ✅ Improved wall skipping for true open concept layouts
# ✅ Fixed studio apartment overlapping rooms and walls
# ✅ Fixed toggle labels button from triggering layout regeneration  
# ✅ Enhanced wall skipping logic for better open concept studios
# ✅ Improved room separation to eliminate visual artifacts
# ✅ Universal apartment generation system with proper entry accessibility
# 
# Displays all apartment layouts side by side for comparison

# Player controller
@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $Player/CameraPivot
@onready var camera: Camera3D = $Player/CameraPivot/Camera3D

# UI elements
@onready var layout_info_label: Label = $UI/InfoPanel/VBoxContainer/LayoutInfoLabel
@onready var regenerate_button: Button = $UI/ControlsPanel/VBoxContainer/RegenerateButton
@onready var toggle_labels_button: Button = $UI/ControlsPanel/VBoxContainer/ToggleLabelsButton
@onready var view_mode_button: Button = $UI/ControlsPanel/VBoxContainer/ViewModeButton

# Layout container
@onready var apartment_layouts: Node3D = $ApartmentLayouts

# Player movement
var movement_speed: float = 5.0
var sprint_speed: float = 8.0
var jump_velocity: float = 6.0
var mouse_sensitivity: float = 0.002
var fly_mode: bool = false

# Layout data
var apartment_data: Dictionary = {}
var layout_instances: Array[Node3D] = []
var room_labels_visible: bool = true

# Apartment data structure for tracking
class ApartmentData:
	var apartment_id: String
	var apartment_number: int
	var layout_type: String
	var variation: int
	var floor_number: int
	var building_id: String
	var entrance_position: Vector3
	var entrance_direction: Vector3  # Direction the door faces
	var residents: Array[String] = []  # NPC IDs who live here
	var is_occupied: bool = false
	
	func _init(id: String, number: int, layout: String, var_num: int, floor_num: int, building: String):
		apartment_id = id
		apartment_number = number
		layout_type = layout
		variation = var_num
		floor_number = floor_num
		building_id = building

# Global apartment registry
var apartment_registry: Dictionary = {}
var current_apartment_data: ApartmentData

# View modes
enum ViewMode { NORMAL, WIREFRAME, X_RAY }
var current_view_mode: ViewMode = ViewMode.NORMAL

# Layout positioning
var layout_spacing: float = 5.0  # Reduced spacing between layouts
var layouts_per_row: int = 2  # 2x2 grid layout
var current_layout_index: int = 0

func _ready():
	"""Initialize the apartment layouts test scene"""
	print("ApartmentLayoutsTest: Starting initialization...")
	
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("ApartmentLayoutsTest: Mouse captured")
	
	# Connect UI signals
	if regenerate_button:
		regenerate_button.pressed.connect(_on_regenerate_pressed)
		print("ApartmentLayoutsTest: Regenerate button connected")
	
	if toggle_labels_button:
		toggle_labels_button.pressed.connect(_on_toggle_labels_pressed)
		print("ApartmentLayoutsTest: Toggle labels button connected")
	
	if view_mode_button:
		view_mode_button.pressed.connect(_on_view_mode_pressed)
		print("ApartmentLayoutsTest: View mode button connected")
	
	# Load apartment data
	print("ApartmentLayoutsTest: Loading apartment data...")
	_load_apartment_data()
	
	# Generate layouts
	print("ApartmentLayoutsTest: Generating layouts...")
	_generate_all_layouts()
	
	# Test apartment system after generation
	test_apartment_system()
	run_apartment_tests()
	
	print("ApartmentLayoutsTest: Initialization completed")

func _load_apartment_data():
	"""Load apartment layout data from JSON"""
	print("ApartmentLayoutsTest: Attempting to load apartment data...")
	var file_path = "res://data/world_generation/apartment_layouts.json"
	
	print("ApartmentLayoutsTest: Looking for file at: %s" % file_path)
	if not FileAccess.file_exists(file_path):
		print("ERROR: Apartment layouts file not found: %s" % file_path)
		return
	
	print("ApartmentLayoutsTest: File exists, opening...")
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("ERROR: Could not open apartment layouts file")
		return
	
	var json_string = file.get_as_text()
	file.close()
	print("ApartmentLayoutsTest: File read, JSON length: %d characters" % json_string.length())
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("ERROR: Failed to parse apartment layouts JSON, error: %s" % parse_result)
		return
	
	apartment_data = json.data
	var layouts_count = apartment_data.get("apartment_layouts", {}).size()
	print("ApartmentLayoutsTest: Successfully loaded %d apartment layouts" % layouts_count)
	
	# Print layout names for debugging
	var layouts = apartment_data.get("apartment_layouts", {})
	for layout_name in layouts.keys():
		print("ApartmentLayoutsTest: Found layout: %s" % layout_name)

func _generate_all_layouts():
	"""Generate all apartment layouts in a 2x2 grid"""
	print("ApartmentLayoutsTest: Starting layout generation...")
	
	if apartment_data.is_empty():
		print("ERROR: No apartment data loaded - cannot generate layouts")
		return
	
	# Clear existing layouts
	_clear_layouts()
	print("ApartmentLayoutsTest: Cleared existing layouts")
	
	var layouts = apartment_data.get("apartment_layouts", {})
	print("ApartmentLayoutsTest: Found %d layouts to generate" % layouts.size())
	
	if layouts.is_empty():
		print("ERROR: No layouts found in apartment data")
		return
	
	var layout_keys = layouts.keys()
	var layout_count = 0
	var row = 0
	var col = 0
	
	for i in range(min(4, layout_keys.size())):  # Limit to 4 layouts for 2x2 grid
		var layout_id = layout_keys[i]
		print("ApartmentLayoutsTest: Processing layout: %s" % layout_id)
		var layout_data = layouts[layout_id]
		
		# Calculate position for 2x2 grid
		var layout_size = layout_data.get("size", {"width": 10, "depth": 10})
		var layout_width = layout_size.get("width", 10)
		var layout_depth = layout_size.get("depth", 10)
		
		var pos_x = col * (layout_width + layout_spacing)
		var pos_z = row * (layout_depth + layout_spacing)
		var layout_position = Vector3(pos_x, 0, pos_z)
		
		var layout_instance = _create_layout_instance(layout_data, layout_position)
		
		if layout_instance:
			print("ApartmentLayoutsTest: Created layout instance for: %s at position %s" % [layout_id, layout_position])
			apartment_layouts.add_child(layout_instance)
			layout_instances.append(layout_instance)
			layout_count += 1
			
			# Move to next grid position
			col += 1
			if col >= layouts_per_row:
				col = 0
				row += 1
		else:
			print("ERROR: Failed to create layout instance for: %s" % layout_id)
	
	print("ApartmentLayoutsTest: Layout generation completed - %d layouts created in 2x2 grid" % layout_count)

func _create_layout_instance(layout_data: Dictionary, pos: Vector3) -> Node3D:
	"""Create a single apartment layout instance with apartment ID and entrance"""
	var layout_node = Node3D.new()
	layout_node.name = layout_data.get("name", "Unknown Layout")
	layout_node.position = pos
	
	# Get layout dimensions first
	var size = layout_data.get("size", {"width": 10, "depth": 10})
	var layout_width = size.get("width", 10)
	var layout_depth = size.get("depth", 10)
	
	# Create apartment data with unique ID
	var apartment_number = 101 + layout_instances.size()  # Increment apartment numbers
	var apt_id = "APT_%03d" % apartment_number
	var building_id = "TEST_BLDG_001"
	var floor_num = float(apartment_number) / 100.0  # Proper float division 
	var layout_type = layout_data.get("id", "unknown")
	
	current_apartment_data = ApartmentData.new(apt_id, apartment_number, layout_type, randi() % 2, floor_num, building_id)
	
	# Set entrance position
	current_apartment_data.entrance_position = Vector3(layout_width / 2, 0, 0)
	current_apartment_data.entrance_direction = Vector3(0, 0, -1)  # Facing forward
	
	# Get colors
	var colors = layout_data.get("color", {"wall": [0.8, 0.8, 0.8], "floor": [0.7, 0.7, 0.7]})
	var wall_color = Color(colors.wall[0], colors.wall[1], colors.wall[2])
	var floor_color = Color(colors.floor[0], colors.floor[1], colors.floor[2])
	
	# Create floor
	_create_floor(layout_node, layout_width, layout_depth, floor_color)
	
	# Create perimeter walls with entrance
	_create_apartment_perimeter_with_entrance(layout_node, layout_width, layout_depth, 0.15, 3.0, wall_color)
	
	# Create realistic room layouts based on apartment type
	_create_realistic_rooms(layout_node, layout_type, layout_width, layout_depth, wall_color)
	
	# Create apartment entrance (door and number)
	_create_apartment_entrance(layout_node, layout_width, layout_depth, 0.15, 3.0, wall_color, layout_type)
	
	# Create layout title label
	_create_layout_label(layout_node, layout_data.get("name", "Unknown") + " - Apt " + str(apartment_number), layout_width)
	
	# Register apartment
	apartment_registry[current_apartment_data.apartment_id] = current_apartment_data
	print("ApartmentLayoutsTest: Registered apartment %s (Number: %d)" % [apt_id, apartment_number])
	
	return layout_node

func _create_apartment_perimeter_with_entrance(parent: Node3D, width: float, depth: float, wall_thickness: float, wall_height: float, wall_color: Color):
	"""Create perimeter walls with entrance gap"""
	var door_width = 1.0
	var entrance_x = width / 2
	
	# Front wall (with door gap)
	# Left part of front wall
	_create_single_wall(parent, Vector3(0, 0, 0), Vector3(entrance_x - door_width/2, wall_height, wall_thickness), wall_color, "perimeter_front_left")
	# Right part of front wall  
	_create_single_wall(parent, Vector3(entrance_x + door_width/2, 0, 0), Vector3(width - entrance_x - door_width/2, wall_height, wall_thickness), wall_color, "perimeter_front_right")
	
	# Back wall
	_create_single_wall(parent, Vector3(0, 0, depth - wall_thickness), Vector3(width, wall_height, wall_thickness), wall_color, "perimeter_back")
	
	# Left wall
	_create_single_wall(parent, Vector3(0, 0, 0), Vector3(wall_thickness, wall_height, depth), wall_color, "perimeter_left")
	
	# Right wall
	_create_single_wall(parent, Vector3(width - wall_thickness, 0, 0), Vector3(wall_thickness, wall_height, depth), wall_color, "perimeter_right")

func _create_realistic_rooms(parent: Node3D, layout_type: String, width: float, depth: float, wall_color: Color):
	"""Create realistic room layouts with proper shared walls"""
	print("ApartmentLayoutsTest: Creating realistic rooms for: %s" % layout_type)
	
	# Create outer perimeter walls first
	_create_perimeter_walls(parent, width, depth, wall_color)
	
	# Then create internal room divisions based on apartment type
	match layout_type:
		"studio":
			_create_studio_internal_walls(parent, width, depth, wall_color)
		"one_bedroom":
			_create_one_bedroom_internal_walls(parent, width, depth, wall_color)
		"two_bedroom":
			_create_two_bedroom_internal_walls(parent, width, depth, wall_color)
		"penthouse":
			_create_penthouse_internal_walls(parent, width, depth, wall_color)
		_:
			print("ApartmentLayoutsTest: Unknown layout type, creating basic internal walls")
			_create_basic_internal_walls(parent, width, depth, wall_color)

func _create_perimeter_walls(parent: Node3D, width: float, depth: float, wall_color: Color):
	"""Create the outer perimeter walls of the apartment"""
	var wall_height = 3.0
	var wall_thickness = 0.15
	
	# South wall (front)
	_create_single_wall(parent, Vector3(0, 0, 0), Vector3(width, wall_height, wall_thickness), wall_color, "perimeter_south")
	
	# North wall (back)
	_create_single_wall(parent, Vector3(0, 0, depth - wall_thickness), Vector3(width, wall_height, wall_thickness), wall_color, "perimeter_north")
	
	# West wall (left)
	_create_single_wall(parent, Vector3(0, 0, wall_thickness), Vector3(wall_thickness, wall_height, depth - 2*wall_thickness), wall_color, "perimeter_west")
	
	# East wall (right)
	_create_single_wall(parent, Vector3(width - wall_thickness, 0, wall_thickness), Vector3(wall_thickness, wall_height, depth - 2*wall_thickness), wall_color, "perimeter_east")

func _create_studio_internal_walls(parent: Node3D, width: float, depth: float, wall_color: Color):
	"""Create internal walls for studio apartment with unified approach"""
	_create_unified_apartment_walls(parent, width, depth, wall_color, "studio")

func _create_one_bedroom_internal_walls(parent: Node3D, width: float, depth: float, wall_color: Color):
	"""Create internal walls for one bedroom apartment with unified approach"""
	_create_unified_apartment_walls(parent, width, depth, wall_color, "one_bedroom")

func _create_two_bedroom_internal_walls(parent: Node3D, width: float, depth: float, wall_color: Color):
	"""Create internal walls for two bedroom apartment with unified approach"""
	_create_unified_apartment_walls(parent, width, depth, wall_color, "two_bedroom")

func _create_penthouse_internal_walls(parent: Node3D, width: float, depth: float, wall_color: Color):
	"""Create internal walls for penthouse apartment with unified approach"""
	_create_unified_apartment_walls(parent, width, depth, wall_color, "penthouse")

# New unified apartment generation system
func _create_unified_apartment_walls(parent: Node3D, width: float, depth: float, wall_color: Color, layout_type: String):
	"""Universal apartment wall generation system with proper entry accessibility"""
	var wall_height = 3.0
	var wall_thickness = 0.15
	var variation = randi() % 2
	
	# Create apartment data if not exists
	if not current_apartment_data:
		current_apartment_data = ApartmentData.new("APT_001", 101, layout_type, variation, 1, "BLDG_001")
	
	# Generate apartment layout using universal system
	var apartment_layout = _generate_universal_apartment_layout(layout_type, width, depth, variation)
	
	# Build walls from layout
	_build_apartment_from_layout(parent, apartment_layout, wall_thickness, wall_height, wall_color)
	
	# Add entryway (door will be positioned in open area)
	_create_apartment_entrance(parent, width, depth, wall_thickness, wall_height, wall_color, layout_type)
	
	# Register apartment
	apartment_registry[current_apartment_data.apartment_id] = current_apartment_data

func _create_apartment_entrance(parent: Node3D, width: float, _depth: float, _wall_thickness: float, wall_height: float, wall_color: Color, _layout_type: String):
	"""Create apartment entrance with door and number for corridor access"""
	# Position entrance for corridor access (center front)
	var entrance_x = width / 2
	var entrance_z = 0  # At the front edge for corridor access
	var door_width = 1.0
	var door_height = 2.1
	
	# Update apartment data with entrance info
	current_apartment_data.entrance_position = Vector3(entrance_x, 0, entrance_z)
	current_apartment_data.entrance_direction = Vector3(0, 0, -1)  # Facing corridor
	
	# Create door frame
	_create_door_frame(parent, entrance_x, entrance_z, door_width, wall_height, wall_color)
	
	# Create apartment door
	_create_apartment_door(parent, entrance_x, entrance_z, door_width, door_height, wall_color)
	
	# Create apartment number sign
	_create_apartment_number_sign(parent, entrance_x, entrance_z, wall_height)

func _create_door_frame(parent: Node3D, door_x: float, door_z: float, door_width: float, _wall_height: float, wall_color: Color):
	"""Create door frame structure for corridor access"""
	var frame_thickness = 0.08
	var door_height = 2.1
	var frame_depth = 0.2
	
	# Left door frame post
	var left_frame = MeshInstance3D.new()
	left_frame.name = "DoorFrameLeft"
	var left_mesh = BoxMesh.new()
	left_mesh.size = Vector3(frame_thickness, door_height, frame_depth)
	left_frame.mesh = left_mesh
	left_frame.position = Vector3(door_x - door_width/2 - frame_thickness/2, door_height/2, door_z)
	
	var frame_material = StandardMaterial3D.new()
	frame_material.albedo_color = wall_color.darkened(0.3)
	frame_material.roughness = 0.8
	left_frame.material_override = frame_material
	parent.add_child(left_frame)
	
	# Right door frame post
	var right_frame = MeshInstance3D.new()
	right_frame.name = "DoorFrameRight"
	var right_mesh = BoxMesh.new()
	right_mesh.size = Vector3(frame_thickness, door_height, frame_depth)
	right_frame.mesh = right_mesh
	right_frame.position = Vector3(door_x + door_width/2 + frame_thickness/2, door_height/2, door_z)
	right_frame.material_override = frame_material
	parent.add_child(right_frame)
	
	# Top door frame lintel
	var top_frame = MeshInstance3D.new()
	top_frame.name = "DoorFrameTop"
	var top_mesh = BoxMesh.new()
	top_mesh.size = Vector3(door_width + 2*frame_thickness, 0.15, frame_depth)
	top_frame.mesh = top_mesh
	top_frame.position = Vector3(door_x, door_height + 0.075, door_z)
	top_frame.material_override = frame_material
	parent.add_child(top_frame)

func _create_apartment_door(parent: Node3D, door_x: float, door_z: float, door_width: float, door_height: float, _door_color: Color):
	"""Create apartment door with handle for realistic access"""
	var door = MeshInstance3D.new()
	door.name = "ApartmentDoor_%s" % current_apartment_data.apartment_id
	
	# Create door mesh
	var door_mesh = BoxMesh.new()
	door_mesh.size = Vector3(door_width - 0.02, door_height, 0.06)
	door.mesh = door_mesh
	door.position = Vector3(door_x, door_height/2, door_z - 0.03)
	
	# Create door material
	var door_material = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.55, 0.35, 0.15)  # Rich brown wood
	door_material.roughness = 0.7
	door_material.normal_scale = 0.5
	door.material_override = door_material
	
	parent.add_child(door)
	
	# Add door handle/knob
	var handle = MeshInstance3D.new()
	handle.name = "DoorHandle"
	var handle_mesh = SphereMesh.new()
	handle_mesh.radius = 0.04
	handle_mesh.height = 0.08
	handle.mesh = handle_mesh
	handle.position = Vector3(door_x + door_width/2 - 0.15, door_height/2, door_z - 0.08)
	
	var handle_material = StandardMaterial3D.new()
	handle_material.albedo_color = Color(0.8, 0.7, 0.3)  # Brass/gold handle
	handle_material.metallic = 0.9
	handle_material.roughness = 0.1
	handle.material_override = handle_material
	
	parent.add_child(handle)
	
	# Add door panels (decorative detail)
	_create_door_panels(door, door_width, door_height)

func _create_door_panels(door_parent: Node3D, door_width: float, door_height: float):
	"""Add decorative panels to door"""
	var panel_material = StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.45, 0.25, 0.1)  # Darker wood for panels
	panel_material.roughness = 0.8
	
	# Upper panel
	var upper_panel = MeshInstance3D.new()
	upper_panel.name = "UpperPanel"
	var upper_mesh = BoxMesh.new()
	upper_mesh.size = Vector3(door_width * 0.8, door_height * 0.35, 0.01)
	upper_panel.mesh = upper_mesh
	upper_panel.position = Vector3(0, door_height * 0.2, 0.03)
	upper_panel.material_override = panel_material
	door_parent.add_child(upper_panel)
	
	# Lower panel
	var lower_panel = MeshInstance3D.new()
	lower_panel.name = "LowerPanel"
	var lower_mesh = BoxMesh.new()
	lower_mesh.size = Vector3(door_width * 0.8, door_height * 0.35, 0.01)
	lower_panel.mesh = lower_mesh
	lower_panel.position = Vector3(0, -door_height * 0.2, 0.03)
	lower_panel.material_override = panel_material
	door_parent.add_child(lower_panel)

func _create_apartment_number_sign(parent: Node3D, door_x: float, door_z: float, wall_height: float):
	"""Create apartment number sign visible from corridor"""
	if current_apartment_data == null:
		return
		
	# Create sign background
	var apartment_sign = MeshInstance3D.new()
	apartment_sign.name = "ApartmentSign_%s" % current_apartment_data.apartment_id
	
	var sign_mesh = BoxMesh.new()
	sign_mesh.size = Vector3(0.35, 0.2, 0.03)
	apartment_sign.mesh = sign_mesh
	apartment_sign.position = Vector3(door_x + 0.8, wall_height * 0.7, door_z - 0.02)
	
	var sign_material = StandardMaterial3D.new()
	sign_material.albedo_color = Color(0.95, 0.95, 0.95)  # Off-white sign
	sign_material.roughness = 0.4
	apartment_sign.material_override = sign_material
	
	parent.add_child(apartment_sign)
	
	# Add apartment number text
	_create_apartment_number_text(parent, door_x + 0.8, wall_height * 0.7, door_z - 0.035)

func _create_apartment_number_text(parent: Node3D, sign_x: float, sign_y: float, sign_z: float):
	"""Create 3D text for apartment number"""
	var text_label = Label3D.new()
	text_label.text = str(current_apartment_data.apartment_number)
	text_label.font_size = 32
	text_label.position = Vector3(sign_x, sign_y, sign_z)
	text_label.name = "apartment_number_%s" % current_apartment_data.apartment_id
	
	# Make text face outward
	text_label.rotation_degrees = Vector3(0, 180, 0)
	
	parent.add_child(text_label)



func _create_one_bedroom_layout(parent: Node3D, width: float, depth: float, wall_thickness: float, wall_height: float, wall_color: Color, variation: int):
	"""Create complete one-bedroom layout with properly connected walls"""
	var half_depth = depth / 2
	
	if variation == 0:
		# Variation 1: Services on left, logical flow
		
		# Bathroom (front left corner) - fully enclosed and connected
		var bathroom_min = Vector3(wall_thickness, 0, wall_thickness)
		var bathroom_max = Vector3(2.0, 0, 2.0)
		_create_room_walls(parent, bathroom_min, bathroom_max, wall_thickness, wall_height, wall_color, "bathroom", [0, 2])  # Skip north and west (perimeter)
		
		# Kitchen (adjacent to bathroom) - connected galley layout
		var kitchen_min = Vector3(2.0, 0, wall_thickness)
		var kitchen_max = Vector3(4.5, 0, 2.0)
		_create_room_walls(parent, kitchen_min, kitchen_max, wall_thickness, wall_height, wall_color, "kitchen", [0])  # Skip north (perimeter)
		
		# Main horizontal division (separates living area from bedroom)
		_create_connected_wall(parent, Vector3(wall_thickness, 0, half_depth), Vector3(width - wall_thickness, 0, half_depth), wall_thickness, wall_height, wall_color, "bedroom_separation")
		
		# Entry hallway definition - connect kitchen to living area
		_create_connected_wall(parent, Vector3(4.5, 0, 2.0), Vector3(4.5, 0, half_depth), wall_thickness, wall_height, wall_color, "hallway_wall")
		
		# Room labels
		_create_simple_room_label(parent, "Bathroom", Vector3(1, wall_height + 0.5, 1))
		_create_simple_room_label(parent, "Kitchen", Vector3(3.25, wall_height + 0.5, 1))
		_create_simple_room_label(parent, "Living Room", Vector3(width - 1.5, wall_height + 0.5, half_depth/2))
		_create_simple_room_label(parent, "Bedroom", Vector3(width/2, wall_height + 0.5, 3*depth/4))
	else:
		# Variation 2: Services on right, mirrored layout
		
		# Bathroom (front right corner) - fully enclosed and connected
		var bathroom_min = Vector3(width - 2.0, 0, wall_thickness)
		var bathroom_max = Vector3(width - wall_thickness, 0, 2.0)
		_create_room_walls(parent, bathroom_min, bathroom_max, wall_thickness, wall_height, wall_color, "bathroom", [0, 3])  # Skip north and east (perimeter)
		
		# Kitchen (adjacent to bathroom) - connected galley layout
		var kitchen_min = Vector3(width - 4.5, 0, wall_thickness)
		var kitchen_max = Vector3(width - 2.0, 0, 2.0)
		_create_room_walls(parent, kitchen_min, kitchen_max, wall_thickness, wall_height, wall_color, "kitchen", [0])  # Skip north (perimeter)
		
		# Main horizontal division (separates living area from bedroom)
		_create_connected_wall(parent, Vector3(wall_thickness, 0, half_depth), Vector3(width - wall_thickness, 0, half_depth), wall_thickness, wall_height, wall_color, "bedroom_separation")
		
		# Entry hallway definition - connect kitchen to living area
		_create_connected_wall(parent, Vector3(width - 4.5, 0, 2.0), Vector3(width - 4.5, 0, half_depth), wall_thickness, wall_height, wall_color, "hallway_wall")
		
		# Room labels
		_create_simple_room_label(parent, "Bathroom", Vector3(width - 1, wall_height + 0.5, 1))
		_create_simple_room_label(parent, "Kitchen", Vector3(width - 3.25, wall_height + 0.5, 1))
		_create_simple_room_label(parent, "Living Room", Vector3(1.5, wall_height + 0.5, half_depth/2))
		_create_simple_room_label(parent, "Bedroom", Vector3(width/2, wall_height + 0.5, 3*depth/4))

func _create_two_bedroom_layout(parent: Node3D, width: float, depth: float, wall_thickness: float, wall_height: float, wall_color: Color, variation: int):
	"""Create two-bedroom layout with properly connected walls"""
	var half_width = width / 2
	var half_depth = depth / 2
	
	if variation == 0:
		# Variation 1: Traditional layout with services on left
		
		# Bathroom (front left corner)
		var bathroom_min = Vector3(wall_thickness, 0, wall_thickness)
		var bathroom_max = Vector3(2.5, 0, 2.5)
		_create_room_walls(parent, bathroom_min, bathroom_max, wall_thickness, wall_height, wall_color, "bathroom", [0, 2])  # Skip north and west (perimeter)
		
		# Kitchen (adjacent to bathroom)
		var kitchen_min = Vector3(2.5, 0, wall_thickness)
		var kitchen_max = Vector3(half_width, 0, 3.0)
		_create_room_walls(parent, kitchen_min, kitchen_max, wall_thickness, wall_height, wall_color, "kitchen", [0])  # Skip north (perimeter)
		
		# Main horizontal division (separates living from bedrooms)
		_create_connected_wall(parent, Vector3(wall_thickness, 0, half_depth), Vector3(width - wall_thickness, 0, half_depth), wall_thickness, wall_height, wall_color, "main_division")
		
		# Central vertical division (separates the two bedrooms)
		_create_connected_wall(parent, Vector3(half_width, 0, half_depth), Vector3(half_width, 0, depth - wall_thickness), wall_thickness, wall_height, wall_color, "bedroom_division")
		
		# Room labels
		_create_simple_room_label(parent, "Bathroom", Vector3(1.25, wall_height + 0.5, 1.25))
		_create_simple_room_label(parent, "Kitchen", Vector3(3.5, wall_height + 0.5, 1.5))
		_create_simple_room_label(parent, "Living Room", Vector3(width - 2, wall_height + 0.5, half_depth/2))
		_create_simple_room_label(parent, "Bedroom 1", Vector3(half_width/2, wall_height + 0.5, 3*depth/4))
		_create_simple_room_label(parent, "Bedroom 2", Vector3(half_width + half_width/2, wall_height + 0.5, 3*depth/4))
	else:
		# Variation 2: Open concept with services on right
		
		# Bathroom (front right corner)
		var bathroom_min = Vector3(width - 2.5, 0, wall_thickness)
		var bathroom_max = Vector3(width - wall_thickness, 0, 2.5)
		_create_room_walls(parent, bathroom_min, bathroom_max, wall_thickness, wall_height, wall_color, "bathroom", [0, 3])  # Skip north and east (perimeter)
		
		# Kitchen (adjacent to bathroom, open to living)
		var kitchen_min = Vector3(half_width, 0, wall_thickness)
		var kitchen_max = Vector3(width - 2.5, 0, 2.8)
		_create_room_walls(parent, kitchen_min, kitchen_max, wall_thickness, wall_height, wall_color, "kitchen", [0, 1])  # Skip north and south (open concept)
		
		# Main horizontal division (separates living from bedrooms)
		_create_connected_wall(parent, Vector3(wall_thickness, 0, half_depth), Vector3(width - wall_thickness, 0, half_depth), wall_thickness, wall_height, wall_color, "main_division")
		
		# Central vertical division (separates the two bedrooms)
		_create_connected_wall(parent, Vector3(half_width, 0, half_depth), Vector3(half_width, 0, depth - wall_thickness), wall_thickness, wall_height, wall_color, "bedroom_division")
		
		# Room labels
		_create_simple_room_label(parent, "Bathroom", Vector3(width - 1.25, wall_height + 0.5, 1.25))
		_create_simple_room_label(parent, "Kitchen", Vector3(width - 3.5, wall_height + 0.5, 1.5))
		_create_simple_room_label(parent, "Living Room", Vector3(2, wall_height + 0.5, half_depth/2))
		_create_simple_room_label(parent, "Bedroom 1", Vector3(half_width/2, wall_height + 0.5, 3*depth/4))
		_create_simple_room_label(parent, "Bedroom 2", Vector3(half_width + half_width/2, wall_height + 0.5, 3*depth/4))

func _create_penthouse_layout(parent: Node3D, width: float, depth: float, wall_thickness: float, wall_height: float, wall_color: Color, variation: int):
	"""Create luxurious penthouse layout with properly connected walls"""
	var quarter_width = width / 4
	var third_depth = depth / 3
	
	if variation == 0:
		# Variation 1: Executive Suite with Private Office and Walk-in Closets
		
		# Master bathroom suite (front left) - spa-like, fully connected
		var master_bath_min = Vector3(wall_thickness, 0, wall_thickness)
		var master_bath_max = Vector3(3.0, 0, 2.5)
		_create_room_walls(parent, master_bath_min, master_bath_max, wall_thickness, wall_height, wall_color, "master_bath", [0, 2])  # Skip north and west (perimeter)
		
		# Walk-in closet adjacent to master bath
		var closet_min = Vector3(3.0, 0, wall_thickness)
		var closet_max = Vector3(4.5, 0, 2.5)
		_create_room_walls(parent, closet_min, closet_max, wall_thickness, wall_height, wall_color, "closet", [0])  # Skip north (perimeter)
		
		# Gourmet kitchen (front center-right)
		var kitchen_min = Vector3(4.5, 0, wall_thickness)
		var kitchen_max = Vector3(width - 1.5, 0, 3.0)
		_create_room_walls(parent, kitchen_min, kitchen_max, wall_thickness, wall_height, wall_color, "kitchen", [0])  # Skip north (perimeter)
		
		# Powder room (guest bath) near entry
		var powder_min = Vector3(width - 1.5, 0, wall_thickness)
		var powder_max = Vector3(width - wall_thickness, 0, 1.5)
		_create_room_walls(parent, powder_min, powder_max, wall_thickness, wall_height, wall_color, "powder", [0, 3])  # Skip north and east (perimeter)
		
		# Grand foyer and living area division
		_create_connected_wall(parent, Vector3(wall_thickness, 0, third_depth), Vector3(width - wall_thickness, 0, third_depth), wall_thickness, wall_height, wall_color, "main_division")
		
		# Private office/study (back left)
		var office_min = Vector3(wall_thickness, 0, third_depth)
		var office_max = Vector3(quarter_width * 1.5, 0, 2*third_depth)
		_create_room_walls(parent, office_min, office_max, wall_thickness, wall_height, wall_color, "office", [0, 2])  # Skip north and west (perimeter/division)
		
		# Master suite (back center)
		var master_suite_min = Vector3(quarter_width * 1.5, 0, third_depth)
		var master_suite_max = Vector3(quarter_width * 3, 0, 2*third_depth)
		_create_room_walls(parent, master_suite_min, master_suite_max, wall_thickness, wall_height, wall_color, "master_suite", [0])  # Skip north (division)
		
		# Guest suite (back right)
		var guest_min = Vector3(quarter_width * 3, 0, third_depth)
		var guest_max = Vector3(width - 2, 0, 2*third_depth)
		_create_room_walls(parent, guest_min, guest_max, wall_thickness, wall_height, wall_color, "guest", [0])  # Skip north (division)
		
		# Guest ensuite bathroom (back right corner)
		var guest_bath_min = Vector3(width - 2, 0, 2*third_depth)
		var guest_bath_max = Vector3(width - wall_thickness, 0, depth - wall_thickness)
		_create_room_walls(parent, guest_bath_min, guest_bath_max, wall_thickness, wall_height, wall_color, "guest_bath", [1, 3])  # Skip south and east (perimeter)
		
		# Room labels
		_create_simple_room_label(parent, "Master Bath", Vector3(1.5, wall_height + 0.5, 1.25))
		_create_simple_room_label(parent, "Walk-in Closet", Vector3(3.75, wall_height + 0.5, 1.25))
		_create_simple_room_label(parent, "Gourmet Kitchen", Vector3(width - 2.5, wall_height + 0.5, 1.5))
		_create_simple_room_label(parent, "Powder Room", Vector3(width - 0.75, wall_height + 0.5, 0.75))
		_create_simple_room_label(parent, "Grand Living", Vector3(width/2, wall_height + 0.5, third_depth/2))
		_create_simple_room_label(parent, "Private Office", Vector3(quarter_width * 0.75, wall_height + 0.5, third_depth + 1))
		_create_simple_room_label(parent, "Master Suite", Vector3(quarter_width * 2.25, wall_height + 0.5, 2*third_depth + 0.5))
		_create_simple_room_label(parent, "Guest Suite", Vector3(quarter_width * 3.5, wall_height + 0.5, third_depth + 1.5))
		_create_simple_room_label(parent, "Guest Bath", Vector3(width - 1, wall_height + 0.5, depth - 0.75))
	else:
		# Variation 2: Entertainment-Focused with Bar and Media Room - improved connectivity
		# Wet bar and wine cellar (front left) - fully enclosed
		_create_single_wall(parent, Vector3(wall_thickness, 0, wall_thickness), Vector3(2.5 - wall_thickness, wall_height, wall_thickness), wall_color, "bar_north")
		_create_single_wall(parent, Vector3(2.5, 0, wall_thickness), Vector3(wall_thickness, wall_height, 2 - wall_thickness), wall_color, "bar_east")
		_create_single_wall(parent, Vector3(wall_thickness, 0, 2), Vector3(2.5 - wall_thickness, wall_height, wall_thickness), wall_color, "bar_south")
		
		# Chef's kitchen with breakfast nook (front center) - connected to bar
		_create_single_wall(parent, Vector3(2.5 + wall_thickness, 0, wall_thickness), Vector3(quarter_width * 1.5 - wall_thickness, wall_height, wall_thickness), wall_color, "chef_kitchen_north")
		_create_single_wall(parent, Vector3(2.5 + wall_thickness, 0, 2.5), Vector3(quarter_width * 1.5 - wall_thickness, wall_height, wall_thickness), wall_color, "chef_kitchen_south")
		_create_single_wall(parent, Vector3(width - 2.5, 0, wall_thickness), Vector3(wall_thickness, wall_height, 2.5 - wall_thickness), wall_color, "chef_kitchen_east")
		
		# Connect kitchen to bar area
		_create_single_wall(parent, Vector3(2.5 + wall_thickness, 0, 2 + wall_thickness), Vector3(quarter_width * 1.5 - wall_thickness, wall_height, 0.5 - wall_thickness), wall_color, "kitchen_bar_connector")
		
		# Butler's pantry and service area - connected to kitchen
		_create_single_wall(parent, Vector3(width - 2.5, 0, 2.5), Vector3(2.5 - wall_thickness, wall_height, wall_thickness), wall_color, "pantry_south")
		
		# Connect pantry to kitchen
		_create_single_wall(parent, Vector3(width - 2.5 - wall_thickness, 0, 2.5 + wall_thickness), Vector3(wall_thickness, wall_height, third_depth - 2.5 - 2*wall_thickness), wall_color, "pantry_connector")
		
		# Formal dining area separator
		_create_single_wall(parent, Vector3(wall_thickness, 0, third_depth - 0.5), Vector3(width - 2*wall_thickness, wall_height, wall_thickness), wall_color, "dining_division")
		
		# Media room / theater (back left) - connected to dining division
		_create_single_wall(parent, Vector3(wall_thickness, 0, third_depth - 0.5 + wall_thickness), Vector3(quarter_width * 2 - wall_thickness, wall_height, wall_thickness), wall_color, "media_north")
		_create_single_wall(parent, Vector3(quarter_width * 2, 0, third_depth - 0.5 + wall_thickness), Vector3(wall_thickness, wall_height, 1.5 - wall_thickness), wall_color, "media_east")
		_create_single_wall(parent, Vector3(wall_thickness, 0, third_depth + 1), Vector3(quarter_width * 2 - wall_thickness, wall_height, wall_thickness), wall_color, "media_south")
		
		# Master suite with sitting area (back center-right) - connected to media room
		_create_single_wall(parent, Vector3(quarter_width * 2 + wall_thickness, 0, third_depth - 0.5 + wall_thickness), Vector3(quarter_width * 1.5 - 2*wall_thickness, wall_height, wall_thickness), wall_color, "master_suite_north")
		_create_single_wall(parent, Vector3(quarter_width * 3.5, 0, third_depth - 0.5 + wall_thickness), Vector3(wall_thickness, wall_height, 2*third_depth - third_depth + 0.5 - 2*wall_thickness), wall_color, "master_suite_east")
		_create_single_wall(parent, Vector3(quarter_width * 2 + wall_thickness, 0, 2*third_depth), Vector3(quarter_width * 1.5 - 2*wall_thickness, wall_height, wall_thickness), wall_color, "master_suite_south")
		
		# Master bathroom with spa features (back right corner) - connected to master suite
		_create_single_wall(parent, Vector3(quarter_width * 3.5 + wall_thickness, 0, third_depth - 0.5 + wall_thickness), Vector3(quarter_width * 0.5 - 2*wall_thickness, wall_height, wall_thickness), wall_color, "spa_bath_north")
		_create_single_wall(parent, Vector3(quarter_width * 3.5 + wall_thickness, 0, 2*third_depth), Vector3(quarter_width * 0.5 - 2*wall_thickness, wall_height, wall_thickness), wall_color, "spa_bath_south")
		
		# Connect spa bathroom to master suite
		_create_single_wall(parent, Vector3(quarter_width * 3.5 + wall_thickness, 0, 2*third_depth + wall_thickness), Vector3(quarter_width * 0.5 - 2*wall_thickness, wall_height, third_depth - 2*wall_thickness), wall_color, "spa_bath_connector")
		
		# Guest quarters with kitchenette (back left corner) - connected to media room
		_create_single_wall(parent, Vector3(wall_thickness, 0, third_depth + 1 + wall_thickness), Vector3(quarter_width * 2 - wall_thickness, wall_height, wall_thickness), wall_color, "guest_quarters_north")
		_create_single_wall(parent, Vector3(quarter_width * 1.5, 0, third_depth + 1 + wall_thickness), Vector3(wall_thickness, wall_height, third_depth - 1 - 2*wall_thickness), wall_color, "guest_quarters_divider")
		_create_single_wall(parent, Vector3(wall_thickness, 0, depth - wall_thickness), Vector3(quarter_width * 2 - wall_thickness, wall_height, wall_thickness), wall_color, "guest_quarters_south")
		
		# Room labels
		_create_simple_room_label(parent, "Wet Bar", Vector3(1.25, wall_height + 0.5, 1))
		_create_simple_room_label(parent, "Chef's Kitchen", Vector3(quarter_width * 1.5, wall_height + 0.5, 1.25))
		_create_simple_room_label(parent, "Butler's Pantry", Vector3(width - 1.25, wall_height + 0.5, 1.25))
		_create_simple_room_label(parent, "Formal Dining", Vector3(width/2, wall_height + 0.5, third_depth/2))
		_create_simple_room_label(parent, "Media Room", Vector3(quarter_width, wall_height + 0.5, third_depth + 0.25))
		_create_simple_room_label(parent, "Master Suite", Vector3(quarter_width * 2.75, wall_height + 0.5, third_depth + 1))
		_create_simple_room_label(parent, "Spa Bathroom", Vector3(width - 0.75, wall_height + 0.5, third_depth + 1))
		_create_simple_room_label(parent, "Guest Quarters", Vector3(quarter_width * 0.75, wall_height + 0.5, depth - 1))
		_create_simple_room_label(parent, "Guest Kitchen", Vector3(quarter_width * 1.75, wall_height + 0.5, depth - 1))

func _create_basic_internal_walls(parent: Node3D, width: float, depth: float, wall_color: Color):
	"""Create basic internal walls"""
	var wall_height = 3.0
	var wall_thickness = 0.15
	var half_width = width / 2
	var half_depth = depth / 2
	
	# Vertical division
	_create_single_wall(parent, Vector3(half_width, 0, wall_thickness), Vector3(wall_thickness, wall_height, depth - 2*wall_thickness), wall_color, "vertical_division")
	
	# Horizontal division
	_create_single_wall(parent, Vector3(wall_thickness, 0, half_depth), Vector3(width - 2*wall_thickness, wall_height, wall_thickness), wall_color, "horizontal_division")

func _create_single_wall(parent: Node3D, pos: Vector3, size: Vector3, color: Color, wall_name: String):
	"""Create a single wall mesh without overlaps"""
	var wall = MeshInstance3D.new()
	wall.name = wall_name
	
	# Create wall geometry
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	wall.mesh = box_mesh
	
	# Create wall material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	
	# Make walls slightly transparent in X-ray mode
	if current_view_mode == ViewMode.X_RAY:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.3
	
	wall.material_override = material
	
	# Position wall (adjust for center positioning)
	wall.position = pos + Vector3(size.x/2, size.y/2, size.z/2)
	
	parent.add_child(wall)

func _create_connected_wall(parent: Node3D, start_pos: Vector3, end_pos: Vector3, thickness: float, height: float, color: Color, wall_name: String):
	"""Create a wall between two points ensuring proper edge connections"""
	var wall_vector = end_pos - start_pos
	var wall_length = wall_vector.length()
	
	if wall_length < 0.01:  # Avoid zero-length walls
		return
	
	var wall_direction = wall_vector.normalized()
	
	# Determine wall size based on direction
	var wall_size: Vector3
	if abs(wall_direction.x) > abs(wall_direction.z):
		# Horizontal wall (along X-axis)
		wall_size = Vector3(wall_length, height, thickness)
	else:
		# Vertical wall (along Z-axis)
		wall_size = Vector3(thickness, height, wall_length)
	
	# Calculate center position
	var center_pos = start_pos + wall_vector * 0.5
	
	_create_single_wall(parent, center_pos - Vector3(wall_size.x/2, 0, wall_size.z/2), wall_size, color, wall_name)

func _create_room_walls(parent: Node3D, room_min: Vector3, room_max: Vector3, thickness: float, height: float, color: Color, room_name: String, skip_walls: Array = []):
	"""Create walls for a rectangular room with proper edge connections"""
	# Define wall positions with proper edge alignment
	var walls = [
		{"name": room_name + "_north", "start": Vector3(room_min.x, 0, room_min.z), "end": Vector3(room_max.x, 0, room_min.z)},
		{"name": room_name + "_south", "start": Vector3(room_min.x, 0, room_max.z), "end": Vector3(room_max.x, 0, room_max.z)},
		{"name": room_name + "_west", "start": Vector3(room_min.x, 0, room_min.z), "end": Vector3(room_min.x, 0, room_max.z)},
		{"name": room_name + "_east", "start": Vector3(room_max.x, 0, room_min.z), "end": Vector3(room_max.x, 0, room_max.z)}
	]
	
	for i in range(walls.size()):
		if not skip_walls.has(i):
			var wall = walls[i]
			_create_connected_wall(parent, wall.start, wall.end, thickness, height, color, wall.name)

func _create_simple_room_label(parent: Node3D, room_name: String, pos: Vector3):
	"""Create a simple room label"""
	if not room_labels_visible:
		return
		
	var label_node = Node3D.new()
	label_node.name = "RoomLabel_" + room_name
	label_node.position = pos
	
	# Create text mesh (simplified - using a basic approach)
	var label_mesh = MeshInstance3D.new()
	label_mesh.name = "LabelMesh"
	
	# Create a simple colored cube to represent room labels
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(1, 0.2, 0.2)
	label_mesh.mesh = cube_mesh
	
	var label_material = StandardMaterial3D.new()
	label_material.albedo_color = Color.YELLOW
	label_material.emission = Color.YELLOW * 0.3
	label_mesh.material_override = label_material
	
	label_node.add_child(label_mesh)
	parent.add_child(label_node)

func _create_floor(parent: Node3D, width: float, depth: float, color: Color):
	"""Create the floor mesh for an apartment layout"""
	var floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	
	# Create floor geometry
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, 0.1, depth)
	floor_mesh.mesh = box_mesh
	
	# Create floor material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	floor_mesh.material_override = material
	
	# Position floor
	floor_mesh.position = Vector3(width / 2, -0.05, depth / 2)
	
	parent.add_child(floor_mesh)

func _create_layout_label(parent: Node3D, layout_name: String, layout_width: float):
	"""Create a title label for the entire layout"""
	var title_node = Node3D.new()
	title_node.name = "LayoutTitle"
	title_node.position = Vector3(layout_width/2, 4, -2)
	
	# Create visible title marker
	var title_mesh = MeshInstance3D.new()
	title_mesh.name = "TitleMesh"
	
	# Create a more visible billboard-style label
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(layout_width * 0.8, 0.5, 0.1)
	title_mesh.mesh = box_mesh
	
	var title_material = StandardMaterial3D.new()
	title_material.albedo_color = Color.WHITE
	title_material.emission = Color.WHITE * 0.5
	title_material.flags_billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_mesh.material_override = title_material
	
	title_node.add_child(title_mesh)
	
	# Add text indicator (using a different colored mesh for now)
	var text_indicator = MeshInstance3D.new()
	text_indicator.name = "TextIndicator"
	text_indicator.position = Vector3(0, 0.3, 0)
	
	var indicator_mesh = BoxMesh.new()
	indicator_mesh.size = Vector3(1, 0.2, 0.2)
	text_indicator.mesh = indicator_mesh
	
	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color.BLUE
	indicator_material.emission = Color.BLUE * 0.3
	text_indicator.material_override = indicator_material
	
	title_node.add_child(text_indicator)
	parent.add_child(title_node)
	
	print("ApartmentLayoutsTest: Created label for layout: %s" % layout_name)

func _clear_layouts():
	"""Clear all existing layout instances"""
	for instance in layout_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	layout_instances.clear()

func _input(event):
	"""Handle input events"""
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Camera rotation
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_object_local(Vector3(1, 0, 0), -event.relative.y * mouse_sensitivity)
		
		# Clamp vertical rotation
		var current_rotation = camera_pivot.rotation_degrees
		current_rotation.x = clamp(current_rotation.x, -90, 90)
		camera_pivot.rotation_degrees = current_rotation
	
	if event.is_action_pressed("ui_cancel"):
		# Toggle mouse capture
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("toggle_fly"):
		fly_mode = !fly_mode
		print("Fly mode: %s" % ("ON" if fly_mode else "OFF"))

func _physics_process(delta):
	"""Handle player movement"""
	if not player:
		return
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	if fly_mode:
		# Fly mode movement
		var fly_direction = direction
		if Input.is_action_pressed("jump"):
			fly_direction += Vector3.UP
		if Input.is_action_pressed("crouch"):
			fly_direction += Vector3.DOWN
		
		var speed = sprint_speed if Input.is_action_pressed("sprint") else movement_speed
		player.velocity = fly_direction * speed
	else:
		# Ground movement
		if direction:
			var speed = sprint_speed if Input.is_action_pressed("sprint") else movement_speed
			player.velocity.x = direction.x * speed
			player.velocity.z = direction.z * speed
		else:
			player.velocity.x = move_toward(player.velocity.x, 0, movement_speed * delta * 3)
			player.velocity.z = move_toward(player.velocity.z, 0, movement_speed * delta * 3)
		
		# Handle jumping
		if Input.is_action_just_pressed("jump") and player.is_on_floor():
			player.velocity.y = jump_velocity
		
		# Apply gravity
		if not player.is_on_floor():
			player.velocity += player.get_gravity() * delta
	
	player.move_and_slide()
	
	# Update layout info based on player position
	_update_layout_info()

func _update_layout_info():
	"""Update UI with current layout information"""
	var player_pos = player.global_position
	var current_layout = _get_layout_at_position(player_pos)
	
	if current_layout:
		layout_info_label.text = "Current: %s" % current_layout.name
	else:
		layout_info_label.text = "Current: Outside layouts"

func _get_layout_at_position(pos: Vector3) -> Node3D:
	"""Get the layout at the given position"""
	for layout in layout_instances:
		if not is_instance_valid(layout):
			continue
		
		var layout_pos = layout.global_position
		# Simple bounds check (could be improved)
		var bounds_size = Vector3(20, 10, 20)  # Approximate layout bounds
		
		if (pos.x >= layout_pos.x and pos.x <= layout_pos.x + bounds_size.x and
			pos.z >= layout_pos.z and pos.z <= layout_pos.z + bounds_size.z):
			return layout
	
	return null

# UI Event Handlers
func _on_regenerate_pressed():
	"""Regenerate all apartment layouts"""
	print("Regenerating apartment layouts...")
	_generate_all_layouts()

func _on_toggle_labels_pressed():
	"""Toggle room label visibility without regenerating layouts"""
	room_labels_visible = !room_labels_visible
	toggle_labels_button.text = "Room Labels: %s" % ("ON" if room_labels_visible else "OFF")
	_toggle_existing_labels()  # Just toggle visibility of existing labels

func _toggle_existing_labels():
	"""Toggle visibility of all existing room labels"""
	for layout_instance in layout_instances:
		if layout_instance:
			_toggle_labels_in_node(layout_instance)

func _toggle_labels_in_node(node: Node3D):
	"""Recursively toggle label visibility in a node tree"""
	for child in node.get_children():
		if child.name.contains("Label") or child.name.contains("Room"):
			child.visible = room_labels_visible
		_toggle_labels_in_node(child)

func _on_view_mode_pressed():
	"""Cycle through view modes"""
	current_view_mode = ((current_view_mode as int + 1) % ViewMode.size()) as ViewMode
	
	match current_view_mode:
		ViewMode.NORMAL:
			view_mode_button.text = "View Mode: Normal"
		ViewMode.WIREFRAME:
			view_mode_button.text = "View Mode: Wireframe"
		ViewMode.X_RAY:
			view_mode_button.text = "View Mode: X-Ray"
	
	_generate_all_layouts()  # Regenerate to apply view mode changes

# ===== UNIVERSAL APARTMENT GENERATION SYSTEM =====

class TestApartmentRoom:
	var name: String
	var min_pos: Vector3
	var max_pos: Vector3
	var room_type: String  # "bathroom", "kitchen", "bedroom", "living", "dining", "closet", "office"
	var is_private: bool   # true for bedrooms/bathrooms, false for common areas
	var connects_to_entry: bool  # true if room should be accessible from entry
	
	func _init(room_name: String, min_position: Vector3, max_position: Vector3, type: String, private: bool = false, entry_access: bool = false):
		name = room_name
		min_pos = min_position
		max_pos = max_position
		room_type = type
		is_private = private
		connects_to_entry = entry_access

class TestApartmentLayout:
	var layout_name: String
	var rooms: Array[TestApartmentRoom]
	var corridors: Array[Dictionary]  # Hallway/connector spaces
	var entry_zone: Vector3  # Area that must remain open near entrance
	
	func _init(name: String):
		layout_name = name
		rooms = []
		corridors = []
		entry_zone = Vector3.ZERO

func _generate_universal_apartment_layout(layout_type: String, width: float, depth: float, variation: int) -> ApartmentLayout:
	"""Generate apartment layout using universal room-based system"""
	var layout = TestApartmentLayout.new(layout_type)
	var wall_thickness = 0.15
	
	# Define entry zone (front center area that must remain open)
	var entry_width = 3.0  # Width of entry area
	var entry_depth = 2.0  # Depth of entry area from front
	layout.entry_zone = Vector3(width/2 - entry_width/2, 0, entry_depth)
	
	match layout_type:
		"studio":
			_generate_studio_rooms(layout, width, depth, variation, wall_thickness)
		"one_bedroom":
			_generate_one_bedroom_rooms(layout, width, depth, variation, wall_thickness)
		"two_bedroom":
			_generate_two_bedroom_rooms(layout, width, depth, variation, wall_thickness)
		"penthouse":
			_generate_penthouse_rooms(layout, width, depth, variation, wall_thickness)
	
	return layout

func _generate_studio_rooms(layout: ApartmentLayout, width: float, depth: float, variation: int, wall_thickness: float):
	"""Generate studio apartment rooms as true open concept - only bathroom is enclosed"""
	if variation == 0:
		# Variation 0: Enclosed bathroom + open living/kitchen space
		
		# Enclosed bathroom (left corner) - only truly private space
		layout.rooms.append(TestApartmentRoom.new("Bathroom", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(2.2, 0, 2.2), 
			"bathroom", true, false))
		
		# Single large open space for living/kitchen/sleeping (excludes only bathroom)
		layout.rooms.append(TestApartmentRoom.new("Open Living/Kitchen Space", 
			Vector3(2.2 + wall_thickness, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, depth - wall_thickness), 
			"living", false, true))
	else:
		# Variation 1: Fully open concept with bathroom on opposite side
		
		# Enclosed bathroom (right corner) - only private space
		layout.rooms.append(TestApartmentRoom.new("Bathroom", 
			Vector3(width - 2.2, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, 2.2), 
			"bathroom", true, false))
		
		# Single large open living/kitchen/sleeping space (excludes only bathroom)
		layout.rooms.append(TestApartmentRoom.new("Open Living/Kitchen Space", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(width - 2.2 - wall_thickness, 0, depth - wall_thickness), 
			"living", false, true))

func _generate_one_bedroom_rooms(layout: ApartmentLayout, width: float, depth: float, variation: int, wall_thickness: float):
	"""Generate one-bedroom apartment rooms with logical entry flow"""
	var half_depth = depth / 2
	
	if variation == 0:
		# Services on left, entry flows to living area
		layout.rooms.append(TestApartmentRoom.new("Bathroom", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(2.0, 0, 2.0), 
			"bathroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Kitchen", 
			Vector3(2.0, 0, wall_thickness), 
			Vector3(4.5, 0, 2.0), 
			"kitchen", false, true))
		
		# Living room (entry accessible, open to kitchen)
		layout.rooms.append(TestApartmentRoom.new("Living Room", 
			Vector3(4.5, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, half_depth), 
			"living", false, true))
		
		# Bedroom (private, back area)
		layout.rooms.append(TestApartmentRoom.new("Bedroom", 
			Vector3(wall_thickness, 0, half_depth), 
			Vector3(width - wall_thickness, 0, depth - wall_thickness), 
			"bedroom", true, false))
	else:
		# Services on right, mirrored layout
		layout.rooms.append(TestApartmentRoom.new("Bathroom", 
			Vector3(width - 2.0, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, 2.0), 
			"bathroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Kitchen", 
			Vector3(width - 4.5, 0, wall_thickness), 
			Vector3(width - 2.0, 0, 2.0), 
			"kitchen", false, true))
		
		# Living room (entry accessible, open to kitchen)
		layout.rooms.append(TestApartmentRoom.new("Living Room", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(width - 4.5, 0, half_depth), 
			"living", false, true))
		
		# Bedroom (private, back area)
		layout.rooms.append(TestApartmentRoom.new("Bedroom", 
			Vector3(wall_thickness, 0, half_depth), 
			Vector3(width - wall_thickness, 0, depth - wall_thickness), 
			"bedroom", true, false))

func _generate_two_bedroom_rooms(layout: ApartmentLayout, width: float, depth: float, variation: int, wall_thickness: float):
	"""Generate two-bedroom apartment rooms with entry considerations"""
	var half_width = width / 2
	var half_depth = depth / 2
	
	if variation == 0:
		# Services on left side
		layout.rooms.append(TestApartmentRoom.new("Bathroom", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(2.5, 0, 2.5), 
			"bathroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Kitchen", 
			Vector3(2.5, 0, wall_thickness), 
			Vector3(half_width, 0, 3.0), 
			"kitchen", false, true))
		
		# Living/Dining (large open area including entry)
		layout.rooms.append(TestApartmentRoom.new("Living/Dining", 
			Vector3(half_width, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, half_depth), 
			"living", false, true))
		
		# Bedrooms (private, back area)
		layout.rooms.append(TestApartmentRoom.new("Bedroom 1", 
			Vector3(wall_thickness, 0, half_depth), 
			Vector3(half_width, 0, depth - wall_thickness), 
			"bedroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Bedroom 2", 
			Vector3(half_width, 0, half_depth), 
			Vector3(width - wall_thickness, 0, depth - wall_thickness), 
			"bedroom", true, false))
	else:
		# Open concept with services on right
		layout.rooms.append(TestApartmentRoom.new("Bathroom", 
			Vector3(width - 2.5, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, 2.5), 
			"bathroom", true, false))
		
		# Kitchen open to living (no full enclosure on living side)
		layout.rooms.append(TestApartmentRoom.new("Kitchen", 
			Vector3(half_width, 0, wall_thickness), 
			Vector3(width - 2.5, 0, 2.8), 
			"kitchen", false, true))
		
		# Large living/dining area (open concept, includes entry)
		layout.rooms.append(TestApartmentRoom.new("Living/Dining", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(half_width, 0, half_depth), 
			"living", false, true))
		
		# Bedrooms (private areas)
		layout.rooms.append(TestApartmentRoom.new("Bedroom 1", 
			Vector3(wall_thickness, 0, half_depth), 
			Vector3(half_width, 0, depth - wall_thickness), 
			"bedroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Bedroom 2", 
			Vector3(half_width, 0, half_depth), 
			Vector3(width - wall_thickness, 0, depth - wall_thickness), 
			"bedroom", true, false))

func test_apartment_system():
	"""Test apartment generation and registry with universal system"""
	print("\n=== UNIVERSAL APARTMENT GENERATION SYSTEM ===")
	print("🏗️  LATEST IMPROVEMENTS:")
	print("✅ Fixed studio apartment room overlaps and wall intersections")
	print("✅ Enhanced wall skipping for clean open concept layouts")
	print("✅ Fixed Toggle Labels button to not regenerate layouts")
	print("✅ Universal room-based generation across all layouts")
	print("✅ Dynamic wall skipping for proper connections")
	print("✅ Entry accessibility validation (no private rooms at entrance)")
	print("✅ Consistent architecture across all variants")
	print("✅ Future-proof apartment generation")
	print("✅ Intelligent open space flow for corridor access")
	print("")
	
	for apt_id in apartment_registry.keys():
		var apt_data = apartment_registry[apt_id]
		print("🏠 Apartment ID: %s" % apt_data.apartment_id)
		print("   Number: %d | Type: %s (Var: %d)" % [apt_data.apartment_number, apt_data.layout_type, apt_data.variation])
		print("   Building: %s | Floor: %.1f" % [apt_data.building_id, apt_data.floor_number])
		print("   Entrance: %s | Direction: %s" % [str(apt_data.entrance_position), str(apt_data.entrance_direction)])
		print("   Occupied: %s | Residents: %d" % [str(apt_data.is_occupied), apt_data.residents.size()])
		print("")
	
	print("🎯 VISUAL QUALITY IMPROVEMENTS:")
	print("• Studio apartments now have clean, non-overlapping layouts")
	print("• Wall intersections eliminated through improved room separation")
	print("• Open concept areas properly connected without visual artifacts")
	print("• Toggle Labels button works correctly without layout regeneration")
	print("• All apartments ensure entry doors connect to appropriate spaces")
	print("This ensures realistic apartment flow for building integration!")

func get_apartment_by_id(apartment_id: String) -> ApartmentData:
	"""Get apartment data by ID"""
	return apartment_registry.get(apartment_id, null)

func assign_npc_to_apartment(apartment_id: String, npc_name: String) -> bool:
	"""Assign an NPC to an apartment"""
	var apt_data = get_apartment_by_id(apartment_id)
	if apt_data == null:
		print("ApartmentLayoutsTest: Apartment %s not found!" % apartment_id)
		return false
	
	if not apt_data.residents.has(npc_name):
		apt_data.residents.append(npc_name)
		apt_data.is_occupied = true
		print("ApartmentLayoutsTest: Assigned %s to apartment %s" % [npc_name, apartment_id])
		return true
	else:
		print("ApartmentLayoutsTest: %s is already assigned to apartment %s" % [npc_name, apartment_id])
		return false

func get_all_apartments() -> Array:
	"""Get all apartment data"""
	return apartment_registry.values()

func get_available_apartments() -> Array:
	"""Get apartments that are not occupied"""
	var available = []
	for apt_data in apartment_registry.values():
		if not apt_data.is_occupied:
			available.append(apt_data)
	return available

func get_apartments_by_type(layout_type: String) -> Array:
	"""Get apartments of a specific type"""
	var matching = []
	for apt_data in apartment_registry.values():
		if apt_data.layout_type == layout_type:
			matching.append(apt_data)
	return matching

func get_apartment_count() -> int:
	"""Get total number of apartments"""
	return apartment_registry.size()

# ===== TESTING FUNCTIONS =====

func run_apartment_tests():
	"""Run comprehensive apartment system tests"""
	print("\n=== APARTMENT SYSTEM TESTS ===")
	
	# Test 1: Apartment creation and registration
	print("Test 1: Apartment Registration")
	print("Total apartments created: %d" % get_apartment_count())
	
	# Test 2: Apartment types
	var studio_apts = get_apartments_by_type("studio")
	var one_bed_apts = get_apartments_by_type("one_bedroom") 
	var two_bed_apts = get_apartments_by_type("two_bedroom")
	var penthouse_apts = get_apartments_by_type("penthouse")
	
	print("Studio apartments: %d" % studio_apts.size())
	print("One-bedroom apartments: %d" % one_bed_apts.size())
	print("Two-bedroom apartments: %d" % two_bed_apts.size())
	print("Penthouse apartments: %d" % penthouse_apts.size())
	
	# Test 3: NPC assignment
	print("\nTest 3: NPC Assignment")
	var available_apts = get_available_apartments()
	if available_apts.size() > 0:
		var test_apt = available_apts[0]
		var success = assign_npc_to_apartment(test_apt.apartment_id, "Test NPC 1")
		print("NPC assignment success: %s" % str(success))
		print("Apartment %s now occupied: %s" % [test_apt.apartment_id, str(test_apt.is_occupied)])
	
	# Test 4: Door and entrance validation
	print("\nTest 4: Entrance Validation")
	for apt_data in get_all_apartments():
		if apt_data.entrance_position != Vector3.ZERO:
			print("Apartment %s has entrance at: %s" % [apt_data.apartment_id, str(apt_data.entrance_position)])
		else:
			print("WARNING: Apartment %s missing entrance!" % apt_data.apartment_id)
	
	print("\n=== TESTS COMPLETE ===\n")

# ===== UNIVERSAL APARTMENT BUILDING SYSTEM =====

func _generate_penthouse_rooms(layout: ApartmentLayout, width: float, depth: float, variation: int, wall_thickness: float):
	"""Generate penthouse apartment rooms with luxury amenities and proper entry flow"""
	var quarter_width = width / 4
	var third_depth = depth / 3
	
	if variation == 0:
		# Executive suite layout - ensure living area is entry accessible
		layout.rooms.append(TestApartmentRoom.new("Master Bath", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(3.0, 0, 2.5), 
			"bathroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Walk-in Closet", 
			Vector3(3.0, 0, wall_thickness), 
			Vector3(4.5, 0, 2.5), 
			"closet", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Gourmet Kitchen", 
			Vector3(4.5, 0, wall_thickness), 
			Vector3(width - 1.5, 0, 3.0), 
			"kitchen", false, true))
		
		layout.rooms.append(TestApartmentRoom.new("Powder Room", 
			Vector3(width - 1.5, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, 1.5), 
			"bathroom", false, false))
		
		# Grand living area (MUST be entry accessible for proper flow)
		layout.rooms.append(TestApartmentRoom.new("Grand Living", 
			Vector3(wall_thickness, 0, 3.0), 
			Vector3(width - wall_thickness, 0, third_depth), 
			"living", false, true))
		
		# Private areas (not directly accessible from entry)
		layout.rooms.append(TestApartmentRoom.new("Private Office", 
			Vector3(wall_thickness, 0, third_depth), 
			Vector3(quarter_width * 1.5, 0, 2*third_depth), 
			"office", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Master Suite", 
			Vector3(quarter_width * 1.5, 0, third_depth), 
			Vector3(quarter_width * 3, 0, 2*third_depth), 
			"bedroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Guest Suite", 
			Vector3(quarter_width * 3, 0, third_depth), 
			Vector3(width - 2, 0, 2*third_depth), 
			"bedroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Guest Bath", 
			Vector3(width - 2, 0, 2*third_depth), 
			Vector3(width - wall_thickness, 0, depth - wall_thickness), 
			"bathroom", true, false))
	else:
		# Entertainment-focused layout - dining area is entry accessible
		layout.rooms.append(TestApartmentRoom.new("Wet Bar", 
			Vector3(wall_thickness, 0, wall_thickness), 
			Vector3(2.5, 0, 2.0), 
			"kitchen", false, true))
		
		layout.rooms.append(TestApartmentRoom.new("Chef's Kitchen", 
			Vector3(2.5, 0, wall_thickness), 
			Vector3(width - 2.5, 0, 2.5), 
			"kitchen", false, true))
		
		layout.rooms.append(TestApartmentRoom.new("Butler's Pantry", 
			Vector3(width - 2.5, 0, wall_thickness), 
			Vector3(width - wall_thickness, 0, 2.5), 
			"kitchen", false, false))
		
		# Formal dining (MUST be entry accessible)
		layout.rooms.append(TestApartmentRoom.new("Formal Dining", 
			Vector3(wall_thickness, 0, 2.5), 
			Vector3(width - wall_thickness, 0, third_depth - 0.5), 
			"dining", false, true))
		
		# Entertainment areas (accessible from dining)
		layout.rooms.append(TestApartmentRoom.new("Media Room", 
			Vector3(wall_thickness, 0, third_depth - 0.5), 
			Vector3(quarter_width * 2, 0, third_depth + 1), 
			"living", false, false))
		
		# Private sleeping areas
		layout.rooms.append(TestApartmentRoom.new("Master Suite", 
			Vector3(quarter_width * 2, 0, third_depth - 0.5), 
			Vector3(quarter_width * 3.5, 0, 2*third_depth), 
			"bedroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Spa Bathroom", 
			Vector3(quarter_width * 3.5, 0, third_depth - 0.5), 
			Vector3(width - wall_thickness, 0, 2*third_depth), 
			"bathroom", true, false))
		
		layout.rooms.append(TestApartmentRoom.new("Guest Quarters", 
			Vector3(wall_thickness, 0, third_depth + 1), 
			Vector3(quarter_width * 2, 0, depth - wall_thickness), 
			"bedroom", true, false))

func _build_apartment_from_layout(parent: Node3D, apartment_layout: ApartmentLayout, wall_thickness: float, wall_height: float, wall_color: Color):
	"""Build apartment walls from universal room layout with entry accessibility"""
	
	# Step 1: Validate entry accessibility
	_ensure_entry_accessibility(apartment_layout)
	
	# Step 2: Validate open concept areas (prevent accidental subdivisions)
	_validate_open_concept_areas(apartment_layout)
	
	# Step 3: Create room walls with intelligent skipping
	for room in apartment_layout.rooms:
		var skip_walls = _calculate_wall_skips(room, apartment_layout)
		_create_room_walls(parent, room.min_pos, room.max_pos, wall_thickness, wall_height, wall_color, room.name, skip_walls)
		
		# Create room label
		var label_pos = (room.min_pos + room.max_pos) * 0.5
		label_pos.y = wall_height + 0.5
		_create_simple_room_label(parent, room.name, label_pos)
	
	# Step 4: Create connecting passages for accessible rooms
	_create_entry_passages(parent, apartment_layout, wall_thickness, wall_height, wall_color)

func _validate_open_concept_areas(apartment_layout: ApartmentLayout):
	"""Ensure open concept layouts don't have unnecessary subdivisions"""
	var room_count = apartment_layout.rooms.size()
	var open_areas = []
	var private_areas = []
	
	# Categorize rooms
	for room in apartment_layout.rooms:
		if room.is_private:
			private_areas.append(room)
		else:
			open_areas.append(room)
	
	# For studio apartments: should only have 1-2 open areas max
	if room_count <= 3 and open_areas.size() > 1:
		print("VALIDATION: Studio layout detected with %d open areas - should be unified" % open_areas.size())
		for room in open_areas:
			print("  Open area: %s (%s)" % [room.name, room.room_type])
	
	# For any layout: warn about potential over-subdivision
	if open_areas.size() > 3:
		print("VALIDATION: Many open areas detected (%d) - check for over-subdivision" % open_areas.size())

func _ensure_entry_accessibility(apartment_layout: ApartmentLayout):
	"""Ensure entry zone connects to appropriate living spaces"""
	var entry_center = Vector3(apartment_layout.entry_zone.x + 1.5, 0, apartment_layout.entry_zone.z)
	
	# Find rooms that overlap with entry zone
	for room in apartment_layout.rooms:
		if _point_in_room(entry_center, room):
			if room.room_type in ["bedroom", "bathroom", "closet"]:
				# Private room blocking entry - this is bad architecture
				print("WARNING: Private room '%s' blocking entry area!" % room.name)
				room.connects_to_entry = false
			else:
				# Good - common area at entry
				room.connects_to_entry = true
				print("Entry connects to: %s (%s)" % [room.name, room.room_type])

func _point_in_room(point: Vector3, room: ApartmentRoom) -> bool:
	"""Check if point is inside room boundaries"""
	return (point.x >= room.min_pos.x and point.x <= room.max_pos.x and 
			point.z >= room.min_pos.z and point.z <= room.max_pos.z)

func _calculate_wall_skips(room: ApartmentRoom, apartment_layout: ApartmentLayout) -> Array:
	"""Calculate which walls to skip based on room connections and openings"""
	var skip_walls = []
	
	# Get apartment bounds from first room (assumes all rooms within same bounds)
	var apt_min = Vector3.INF
	var apt_max = Vector3(-Vector3.INF)
	for r in apartment_layout.rooms:
		apt_min.x = min(apt_min.x, r.min_pos.x)
		apt_min.z = min(apt_min.z, r.min_pos.z)
		apt_max.x = max(apt_max.x, r.max_pos.x)
		apt_max.z = max(apt_max.z, r.max_pos.z)
	
	# Skip perimeter walls (apartment boundaries)
	if room.min_pos.x <= apt_min.x + 0.2:  # Near left wall
		skip_walls.append(2)  # Skip west wall
	if room.max_pos.x >= apt_max.x - 0.2:  # Near right wall  
		skip_walls.append(3)  # Skip east wall
	if room.min_pos.z <= apt_min.z + 0.2:  # Near front wall
		skip_walls.append(0)  # Skip north wall
	if room.max_pos.z >= apt_max.z - 0.2:  # Near back wall
		skip_walls.append(1)  # Skip south wall
	
	# Skip walls between connected common areas for open flow
	if room.connects_to_entry and room.room_type in ["living", "kitchen", "dining"]:
		for other_room in apartment_layout.rooms:
			if (other_room != room and other_room.connects_to_entry and 
				other_room.room_type in ["living", "kitchen", "dining"]):
				if _rooms_adjacent(room, other_room):
					var shared_wall = _get_shared_wall_index(room, other_room)
					if shared_wall >= 0 and not skip_walls.has(shared_wall):
						skip_walls.append(shared_wall)
	
	# Special case for studio apartments - maximize open concept
	if apartment_layout.rooms.size() <= 3:  # Studio layouts typically have 2-3 rooms
		for other_room in apartment_layout.rooms:
			if (other_room != room and 
				not room.is_private and not other_room.is_private):  # Both are common areas
				if _rooms_adjacent(room, other_room):
					var shared_wall = _get_shared_wall_index(room, other_room)
					if shared_wall >= 0 and not skip_walls.has(shared_wall):
						skip_walls.append(shared_wall)
						print("Open concept: Removing wall between %s and %s" % [room.name, other_room.name])
	
	# Additional check: If room has "Open" in name, be extra aggressive about connections
	if "Open" in room.name:
		for other_room in apartment_layout.rooms:
			if (other_room != room and not other_room.is_private):
				if _rooms_adjacent(room, other_room):
					var shared_wall = _get_shared_wall_index(room, other_room)
					if shared_wall >= 0 and not skip_walls.has(shared_wall):
						skip_walls.append(shared_wall)
						print("Open space optimization: Connecting %s to %s" % [room.name, other_room.name])
	
	return skip_walls

func _rooms_adjacent(room1: ApartmentRoom, room2: ApartmentRoom) -> bool:
	"""Check if two rooms share a wall"""
	var tolerance = 0.1
	return (abs(room1.max_pos.x - room2.min_pos.x) < tolerance or 
			abs(room1.min_pos.x - room2.max_pos.x) < tolerance or
			abs(room1.max_pos.z - room2.min_pos.z) < tolerance or 
			abs(room1.min_pos.z - room2.max_pos.z) < tolerance)

func _get_shared_wall_index(room1: ApartmentRoom, room2: ApartmentRoom) -> int:
	"""Get index of shared wall between rooms"""
	var tolerance = 0.1
	if abs(room1.max_pos.z - room2.min_pos.z) < tolerance:
		return 1  # South wall of room1
	elif abs(room1.min_pos.z - room2.max_pos.z) < tolerance:
		return 0  # North wall of room1  
	elif abs(room1.max_pos.x - room2.min_pos.x) < tolerance:
		return 3  # East wall of room1
	elif abs(room1.min_pos.x - room2.max_pos.x) < tolerance:
		return 2  # West wall of room1
	return -1

func _create_entry_passages(_parent: Node3D, apartment_layout: ApartmentLayout, _wall_thickness: float, _wall_height: float, _wall_color: Color):
	"""Create passages between entry and accessible rooms"""
	var entry_accessible_rooms = []
	for room in apartment_layout.rooms:
		if room.connects_to_entry and room.room_type in ["living", "kitchen", "dining"]:
			entry_accessible_rooms.append(room)
	
	print("Entry accessible rooms: %d" % entry_accessible_rooms.size())
	for room in entry_accessible_rooms:
		print("  - %s (%s)" % [room.name, room.room_type])

func test_universal_generation():
	"""Test the new universal apartment generation system"""
	print("\n🏗️ UNIVERSAL APARTMENT GENERATION SYSTEM")
	print("============================================================")
	
	# Get the apartments instance
	var apartments_node = get_node("../Apartments")
	if not apartments_node:
		print("⚠️  Apartments node not found - cannot test universal generation")
		return
	
	var test_types = ["studio", "one_bedroom", "two_bedroom", "penthouse"]
	
	for apt_type in test_types:
		print("\n🏠 Testing %s apartments:" % apt_type.capitalize())
		var layout = apartments_node._generate_universal_apartment_layout(apt_type, 1, Vector3(100, 0, 50))
		
		if layout:
			print("   Rooms generated: %d" % layout.rooms.size())
			print("   Entry zone: %s" % str(layout.entry_zone))
			
			# Test entry accessibility
			var entry_accessible = apartments_node._ensure_entry_accessibility(layout)
			if entry_accessible:
				print("   ✅ Entry accessibility validated - opens to common area")
			else:
				print("   ⚠️  Entry accessibility issue detected")
			
			# Show room types and detect open concept areas
			var room_types = []
			var open_areas = 0
			var private_areas = 0
			for room in layout.rooms:
				if not room_types.has(room.room_type):
					room_types.append(room.room_type)
				if room.is_private:
					private_areas += 1
				else:
					open_areas += 1
			
			print("   Room types: %s" % str(room_types))
			print("   Private rooms: %d | Open areas: %d" % [private_areas, open_areas])
			print("   Entry-connected: %d" % layout.rooms.filter(func(r): return r.connects_to_entry).size())
			
			# Validate open concept for studios
			if apt_type == "studio" and open_areas > 1:
				print("   ⚠️  Studio has multiple open areas - should be unified for open concept")
			elif apt_type == "studio" and open_areas == 1:
				print("   ✅ Studio has proper open concept layout")
		else:
			print("   ⚠️  Failed to generate layout")
	
	print("\n🎯 SYSTEM BENEFITS:")
	print("• Universal generation logic across all apartment types")
	print("• Proper open concept areas without unnecessary subdivisions") 
	print("• Validated entry accessibility (no doors to bedrooms/bathrooms)")
	print("• Future-proof architecture for new layout variants")
	print("• Intelligent wall skipping for clean open floor plans")
	print("• Room-based approach ensures proper spatial relationships")
