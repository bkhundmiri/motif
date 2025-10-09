extends Control
class_name ApartmentSelector

## Apartment Type Selector
## Loads and displays buttons for each apartment type from apartment_layouts.json

var apartment_data: Dictionary = {}
var apartment_grid: GridContainer
var apartment_scenes: Dictionary = {}

func _ready():
	# Get UI references
	apartment_grid = $MainContainer/ScrollContainer/ApartmentGrid
	$MainContainer/ButtonContainer/ExitButton.pressed.connect(_on_exit_pressed)
	
	# Load apartment data
	_load_apartment_data()
	
	# Create apartment buttons
	_create_apartment_buttons()
	
	# Set mouse mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _load_apartment_data():
	"""Load apartment configuration from JSON"""
	var file = FileAccess.open("res://data/world_generation/apartment_layouts.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			apartment_data = json.data.get("apartment_layouts", {})
			print("Loaded %d apartment layouts" % apartment_data.size())
		else:
			print("Error parsing apartment layouts JSON: ", json.error_string)
	else:
		print("Could not load apartment layouts JSON file")

func _create_apartment_buttons():
	"""Create buttons for each apartment type"""
	# Define apartment order for better organization
	var apartment_order = [
		"studio", "studio_open",
		"one_bedroom", "one_bedroom_open", 
		"two_bedroom_one_bath", "two_bedroom_one_bath_open", "two_bedroom_one_bath_luxury",
		"two_bedroom_two_bath", "two_bedroom_two_bath_open", "two_bedroom_two_bath_luxury",
		"penthouse", "penthouse_open", "penthouse_luxury"
	]
	
	for apartment_key in apartment_order:
		if apartment_key in apartment_data:
			var apt_config = apartment_data[apartment_key]
			_create_apartment_button(apartment_key, apt_config)

func _create_apartment_button(apartment_key: String, config: Dictionary):
	"""Create a button for a specific apartment type"""
	var button_container = VBoxContainer.new()
	button_container.custom_minimum_size = Vector2(380, 120)
	
	# Main apartment button
	var button = Button.new()
	button.custom_minimum_size = Vector2(380, 80)
	button.text = _format_apartment_name(apartment_key)
	button.pressed.connect(_on_apartment_selected.bind(apartment_key))
	
	# Info label
	var info_label = Label.new()
	info_label.text = _format_apartment_info(config)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	
	button_container.add_child(button)
	button_container.add_child(info_label)
	apartment_grid.add_child(button_container)

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

func _format_apartment_info(config: Dictionary) -> String:
	"""Format apartment info for display"""
	var area = config.get("total_area_sqm", 0)
	var rent_range = config.get("rent_range", {})
	var min_rent = rent_range.get("min", 0)
	var max_rent = rent_range.get("max", 0)
	
	return "%d sqm • $%d - $%d/month" % [area, min_rent, max_rent]

func _on_apartment_selected(apartment_key: String):
	"""Handle apartment selection"""
	print("Loading apartment: %s" % apartment_key)
	
	# Map apartment keys to scene paths
	var scene_path = _get_apartment_scene_path(apartment_key)
	
	if FileAccess.file_exists(scene_path):
		# Store the selector scene reference for returning
		ApartmentManager.selector_scene = self
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Scene not found: %s" % scene_path)
		# For now, create a placeholder scene
		_create_placeholder_scene(apartment_key)

func _get_apartment_scene_path(apartment_key: String) -> String:
	"""Get the scene path for an apartment type"""
	var category = ""
	
	if apartment_key.begins_with("studio"):
		category = "studio"
	elif apartment_key.begins_with("one_bedroom"):
		category = "one_bedroom"
	elif apartment_key.begins_with("two_bedroom"):
		category = "two_bedroom"
	elif apartment_key.begins_with("penthouse"):
		category = "penthouse"
	
	var apt_config = apartment_data[apartment_key]
	var apt_id = apt_config.get("id", apartment_key)
	
	return "res://scenes/apartments/%s/%s.tscn" % [category, apt_id]

func _create_placeholder_scene(apartment_key: String):
	"""Create a placeholder scene for missing apartments"""
	print("Creating placeholder for: %s" % apartment_key)
	# This will be implemented when we create the individual apartment scenes

func _on_exit_pressed():
	"""Exit to main menu"""
	# For now, just quit - you can change this to load your main menu scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")
