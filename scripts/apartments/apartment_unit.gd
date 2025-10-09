extends Node3D
class_name ApartmentUnit

## Base class for all apartment scenes
## Handles common functionality like camera, ESC menu, and apartment data

@export var apartment_id: String = ""
@export var apartment_type: String = ""

var apartment_data: Dictionary = {}
var camera_controller: ApartmentCameraController
var esc_menu: EscMenu

func _ready():
	# Set up the apartment
	_load_apartment_data()
	_setup_camera()
	_setup_ui()
	
	print("Loaded apartment: %s (%s)" % [apartment_type, apartment_id])

func _load_apartment_data():
	"""Load apartment configuration from JSON"""
	var file = FileAccess.open("res://data/world_generation/apartment_layouts.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var all_apartments = json.data.get("apartment_layouts", {})
			for apt_key in all_apartments:
				var apt_config = all_apartments[apt_key]
				if apt_config.get("id", "") == apartment_id:
					apartment_data = apt_config
					apartment_type = apt_key
					break
		else:
			print("Error parsing apartment layouts JSON: ", json.error_string)
	else:
		print("Could not load apartment layouts JSON file")

func _setup_camera():
	"""Setup the camera controller"""
	camera_controller = $ApartmentCameraController
	if camera_controller:
		print("Camera controller ready")
	else:
		print("Warning: No camera controller found")

func _setup_ui():
	"""Setup UI elements"""
	esc_menu = $UI/EscMenu
	if esc_menu:
		print("ESC menu ready")
	else:
		print("Warning: No ESC menu found")
	
	# Update info panel with apartment data
	_update_info_panel()

func _update_info_panel():
	"""Update the info panel with current apartment data"""
	if apartment_data.is_empty():
		return
	
	# Update apartment title
	var title_label = $UI/InfoPanel/InfoContainer/ApartmentTitle
	if title_label:
		var area = apartment_data.get("total_area_sqm", 0)
		title_label.text = "%s (%d sqm)" % [_format_apartment_name(apartment_type), area]
	
	# Update dimensions
	var dims_label = $UI/InfoPanel/InfoContainer/DimensionsLabel
	if dims_label:
		var overall_dims = apartment_data.get("overall_dimensions", {})
		var width = overall_dims.get("width", 0)
		var depth = overall_dims.get("depth", 0)
		dims_label.text = "Overall: %.1fm × %.1fm" % [width, depth]
	
	# Update rooms list
	var rooms_label = $UI/InfoPanel/InfoContainer/RoomsLabel
	if rooms_label:
		var room_config = apartment_data.get("room_configuration", {})
		var room_names = []
		for room_key in room_config.keys():
			room_names.append(room_key.replace("_", " ").capitalize())
		rooms_label.text = "Rooms: " + ", ".join(room_names)

func _format_apartment_name(apartment_key: String) -> String:
	"""Format apartment key into display name"""
	var formatted = apartment_key.replace("_", " ").capitalize()
	
	# Special formatting for specific types
	if "One Bedroom" in formatted:
		formatted = formatted.replace("One Bedroom", "1 Bedroom")
	if "Two Bedroom" in formatted:
		formatted = formatted.replace("Two Bedroom", "2 Bedroom")
	if "One Bath" in formatted:
		formatted = formatted.replace("One Bath", "1 Bath")
	if "Two Bath" in formatted:
		formatted = formatted.replace("Two Bath", "2 Bath")
		
	return formatted

func _input(event):
	"""Handle apartment-level input"""
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if esc_menu:
			# Set mouse to visible before opening menu
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			esc_menu.open_menu()
		get_viewport().set_input_as_handled()

func get_apartment_info() -> Dictionary:
	"""Get apartment information for display"""
	return {
		"id": apartment_id,
		"type": apartment_type,
		"area": apartment_data.get("total_area_sqm", 0),
		"rent_range": apartment_data.get("rent_range", {}),
		"demographics": apartment_data.get("target_demographics", [])
	}