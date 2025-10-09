extends StaticBody3D
class_name FurnitureItem

## Base class for all furniture items in apartments
## Handles placement, collision, and interaction

@export var furniture_id: String = ""
@export var furniture_type: String = ""
@export var luxury_level: String = "standard"  # "standard" or "luxury"
@export var placement_rules: Array[String] = []

# Size information for placement calculations
@export var item_size: Vector3 = Vector3.ONE
@export var rotation_snap: float = 90.0  # Degrees for rotation snapping

# Visual and interaction
@onready var mesh_instance: MeshInstance3D
@onready var collision_shape: CollisionShape3D

# Placement information
var is_placed: bool = false
var placement_surface: String = ""  # "floor", "wall", "counter", etc.
var room_type: String = ""

func _ready():
	# Set up collision and interaction
	_setup_collision()
	_setup_interaction()
	
	# Add to furniture group for easy finding
	add_to_group("furniture")
	add_to_group("furniture_" + furniture_type)

func _setup_collision():
	"""Set up collision detection for furniture placement"""
	# Ensure we have a collision shape
	if not collision_shape:
		collision_shape = $CollisionShape3D if has_node("CollisionShape3D") else null
	
	if collision_shape and not collision_shape.shape:
		# Create a box collision shape based on item size
		var box_shape = BoxShape3D.new()
		box_shape.size = item_size
		collision_shape.shape = box_shape

func _setup_interaction():
	"""Set up interaction capabilities"""
	# Add input detection for potential interactions
	input_event.connect(_on_furniture_clicked)

func _on_furniture_clicked(_camera: Camera3D, event: InputEvent, click_position: Vector3, _normal: Vector3, _shape_idx: int):
	"""Handle furniture interaction (for detective investigation)"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Investigating furniture: %s (%s) at %s" % [furniture_id, furniture_type, click_position])
		# This will be expanded for detective gameplay
		investigate_furniture()

func investigate_furniture():
	"""Called when player investigates this furniture (crime scene analysis)"""
	# Placeholder for crime scene investigation
	# Could reveal clues, evidence, or story elements
	pass

func place_furniture(new_position: Vector3, new_rotation: Vector3 = Vector3.ZERO):
	"""Place furniture at specified position with optional rotation"""
	position = new_position
	rotation_degrees = new_rotation
	is_placed = true
	
	print("Placed %s at %s" % [furniture_id, position])

func get_placement_bounds() -> AABB:
	"""Get the bounding box for placement calculations"""
	return AABB(-item_size/2, item_size)

func can_place_at(_check_position: Vector3, check_room_type: String) -> bool:
	"""Check if furniture can be placed at given position in given room type"""
	# Check room compatibility
	if room_type != "" and room_type != check_room_type:
		return false
	
	# Basic placement validation (can be expanded)
	return true

func get_furniture_data() -> Dictionary:
	"""Get furniture data for saving/loading"""
	return {
		"furniture_id": furniture_id,
		"furniture_type": furniture_type,
		"luxury_level": luxury_level,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"rotation": {"x": rotation.x, "y": rotation.y, "z": rotation.z},
		"is_placed": is_placed,
		"room_type": room_type
	}

func load_furniture_data(data: Dictionary):
	"""Load furniture from saved data"""
	furniture_id = data.get("furniture_id", "")
	furniture_type = data.get("furniture_type", "")
	luxury_level = data.get("luxury_level", "standard")
	
	if data.has("position"):
		var pos_data = data["position"]
		position = Vector3(pos_data.x, pos_data.y, pos_data.z)
	
	if data.has("rotation"):
		var rot_data = data["rotation"]
		rotation = Vector3(rot_data.x, rot_data.y, rot_data.z)
	
	is_placed = data.get("is_placed", false)
	room_type = data.get("room_type", "")