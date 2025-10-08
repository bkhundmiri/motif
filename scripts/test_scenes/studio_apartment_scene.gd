extends Node3D

## Studio Apartment Scene
## Demonstrates the dynamic furnishing system with a fully furnished studio layout

@onready var studio_container: Node3D = $StudioContainer
@onready var ui_panel: Control = $UI/StudioFurnishingPanel

# Apartment generation components
var apartment_layout  # ApartmentLayout type
var furnishing_system  # ApartmentFurnishingSystem type
var furnished_items: Array = []

# Studio apartment dimensions
const STUDIO_WIDTH = 8.0
const STUDIO_DEPTH = 6.0
const WALL_THICKNESS = 0.15
const WALL_HEIGHT = 2.8

# Style options
var current_style = "modern"
var available_styles = ["modern", "traditional", "minimalist"]

func _ready():
	print("🏠 Studio Apartment Scene - Dynamic Furnishing Demo")
	
	# Initialize systems
	furnishing_system = ApartmentFurnishingSystem.new()
	
	# Generate studio layout
	_generate_studio_layout()
	
	# Create apartment structure (walls)
	_create_apartment_structure()
	
	# Furnish the apartment
	_furnish_apartment()
	
	# Setup UI controls
	_setup_ui_controls()
	
	print("✅ Studio apartment ready with dynamic furnishing system")

func _generate_studio_layout():
	"""Generate the studio apartment layout using room-based system"""
	apartment_layout = ApartmentLayout.new("studio")
	
	# Define entry zone
	apartment_layout.entry_zone = Vector3(STUDIO_WIDTH/2 - 1.5, 0, 1.0)
	
	# Create rooms - using the improved open concept approach
	var bathroom = ApartmentRoom.new(
		"Bathroom",
		Vector3(WALL_THICKNESS, 0, WALL_THICKNESS),
		Vector3(2.2, 0, 2.2),
		"bathroom", true, false
	)
	
	var open_living_space = ApartmentRoom.new(
		"Open Living/Kitchen Space",
		Vector3(2.2 + WALL_THICKNESS, 0, WALL_THICKNESS),
		Vector3(STUDIO_WIDTH - WALL_THICKNESS, 0, STUDIO_DEPTH - WALL_THICKNESS),
		"living", false, true
	)
	
	apartment_layout.add_room(bathroom)
	apartment_layout.add_room(open_living_space)
	
	# Validate layout
	if apartment_layout.validate_layout():
		print("✅ Studio layout validated successfully")
	else:
		print("⚠️  Studio layout validation issues detected")

func _create_apartment_structure():
	"""Create the physical walls and structure of the apartment"""
	var structure_parent = Node3D.new()
	structure_parent.name = "ApartmentStructure"
	studio_container.add_child(structure_parent)
	
	# Create perimeter walls
	_create_perimeter_walls(structure_parent)
	
	# Create internal walls (only bathroom walls for studio)
	_create_internal_walls(structure_parent)
	
	# Create floor
	_create_floor(structure_parent)

func _create_perimeter_walls(parent: Node3D):
	"""Create the outer walls of the apartment"""
	var wall_color = Color(0.9, 0.9, 0.95)  # Light gray-blue
	
	# North wall (front)
	_create_wall(parent, Vector3(0, 0, 0), Vector3(STUDIO_WIDTH, WALL_HEIGHT, WALL_THICKNESS), wall_color, "north_wall")
	
	# South wall (back)
	_create_wall(parent, Vector3(0, 0, STUDIO_DEPTH - WALL_THICKNESS), Vector3(STUDIO_WIDTH, WALL_HEIGHT, WALL_THICKNESS), wall_color, "south_wall")
	
	# East wall (right)
	_create_wall(parent, Vector3(STUDIO_WIDTH - WALL_THICKNESS, 0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, STUDIO_DEPTH), wall_color, "east_wall")
	
	# West wall (left)
	_create_wall(parent, Vector3(0, 0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, STUDIO_DEPTH), wall_color, "west_wall")

func _create_internal_walls(parent: Node3D):
	"""Create internal walls for private spaces (bathroom)"""
	var wall_color = Color(0.85, 0.85, 0.9)  # Slightly darker for interior walls
	
	# Bathroom walls
	var bathroom = apartment_layout.get_room_by_type("bathroom")
	if bathroom:
		# East wall of bathroom (separates from living space)
		_create_wall(parent, 
			Vector3(bathroom.max_pos.x, 0, bathroom.min_pos.z), 
			Vector3(WALL_THICKNESS, WALL_HEIGHT, bathroom.max_pos.z - bathroom.min_pos.z), 
			wall_color, "bathroom_east_wall")
		
		# South wall of bathroom
		_create_wall(parent, 
			Vector3(bathroom.min_pos.x, 0, bathroom.max_pos.z), 
			Vector3(bathroom.max_pos.x - bathroom.min_pos.x, WALL_HEIGHT, WALL_THICKNESS), 
			wall_color, "bathroom_south_wall")

func _create_floor(parent: Node3D):
	"""Create the apartment floor"""
	var floor_mesh_instance = MeshInstance3D.new()
	floor_mesh_instance.name = "Floor"
	
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(STUDIO_WIDTH, 0.1, STUDIO_DEPTH)
	floor_mesh_instance.mesh = floor_mesh
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.8, 0.7, 0.6)  # Light wood color
	floor_material.roughness = 0.8
	floor_mesh_instance.material_override = floor_material
	
	floor_mesh_instance.position = Vector3(STUDIO_WIDTH/2, -0.05, STUDIO_DEPTH/2)
	parent.add_child(floor_mesh_instance)

func _create_wall(parent: Node3D, pos: Vector3, size: Vector3, color: Color, wall_name: String):
	"""Create a single wall mesh"""
	var wall = MeshInstance3D.new()
	wall.name = wall_name
	
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = size
	wall.mesh = wall_mesh
	
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = color
	wall_material.roughness = 0.9
	wall.material_override = wall_material
	
	# Position at center of the wall
	wall.position = pos + size * 0.5
	parent.add_child(wall)

func _furnish_apartment():
	"""Furnish all rooms in the apartment using the dynamic system"""
	var furniture_parent = Node3D.new()
	furniture_parent.name = "Furniture"
	studio_container.add_child(furniture_parent)
	
	print("\n🪑 FURNISHING STUDIO APARTMENT")
	print("==================================================")
	
	# Furnish each room
	for room in apartment_layout.rooms:
		print("\n📦 Furnishing room: %s" % room.name)
		var room_furniture = furnishing_system.furnish_room(room, furniture_parent, current_style)
		furnished_items.append_array(room_furniture)
		
		print("   ✅ Added %d furniture items" % room_furniture.size())
	
	print("\n🎯 FURNISHING COMPLETE")
	print("Total furniture items: %d" % furnished_items.size())
	print("Studio style: %s" % current_style)
	
	# Update UI labels
	_update_ui_labels()

func _setup_ui_controls():
	"""Setup UI controls for apartment customization"""
	_update_ui_labels()
	
	# Connect reset camera button
	var reset_button = ui_panel.get_node_or_null("VBoxContainer/ResetCameraButton")
	if reset_button:
		reset_button.pressed.connect(_on_reset_camera_pressed)
	
	print("\n🎨 Available customization options:")
	print("Styles: %s" % str(available_styles))
	print("Controls: F1-F3 for styles, WASD for camera")

func _on_reset_camera_pressed():
	"""Reset camera to initial view"""
	var camera = get_node("Camera3D")
	if camera and camera.has_method("focus_on_apartment"):
		camera.focus_on_apartment()
		print("📹 Camera reset to apartment view")

func _update_ui_labels():
	"""Update UI labels with current state"""
	var style_label = ui_panel.get_node_or_null("VBoxContainer/CurrentStyleLabel")
	var count_label = ui_panel.get_node_or_null("VBoxContainer/FurnitureCountLabel")
	
	if style_label:
		style_label.text = "Current Style: %s" % current_style.capitalize()
	
	if count_label:
		count_label.text = "Furniture Items: %d" % furnished_items.size()

func _input(event):
	"""Handle input for style changes and customization"""
	if event.is_action_pressed("style_modern"):
		_change_style("modern")
	elif event.is_action_pressed("style_traditional"):
		_change_style("traditional")
	elif event.is_action_pressed("style_minimalist"):
		_change_style("minimalist")

func _change_style(new_style: String):
	"""Change the furnishing style and regenerate furniture"""
	if new_style == current_style:
		return
	
	print("\n🎨 Changing style from %s to %s" % [current_style, new_style])
	current_style = new_style
	
	# Remove existing furniture
	_clear_furniture()
	
	# Regenerate with new style
	_furnish_apartment()
	
	# Update UI
	_update_ui_labels()

func _clear_furniture():
	"""Remove all existing furniture"""
	var furniture_parent = studio_container.get_node_or_null("Furniture")
	if furniture_parent:
		furniture_parent.queue_free()
	
	furnished_items.clear()
	print("🧹 Cleared existing furniture")

func get_layout_summary() -> Dictionary:
	"""Get summary information about the current layout"""
	if not apartment_layout:
		return {}
	
	return {
		"apartment_type": apartment_layout.layout_type,
		"total_rooms": apartment_layout.rooms.size(),
		"total_area": apartment_layout.get_total_area(),
		"private_rooms": apartment_layout.get_private_rooms().size(),
		"common_rooms": apartment_layout.get_common_rooms().size(),
		"furniture_items": furnished_items.size(),
		"current_style": current_style
	}
