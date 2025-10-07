extends StaticBody3D
class_name BuildingEntrance

## Building Entrance - Handles player interaction and apartment access
## Manages elevator system and floor navigation

signal building_entered(building: Node3D)
signal floor_changed(floor_number: int)

@export var building_reference: Node3D
@export var interaction_distance: float = 3.0

var player_in_range: bool = false
var player: Node3D
var current_floor: int = 0
var apartments_generated: Dictionary = {}  # Track which apartments are loaded

# UI elements
var floor_selector_ui: Control
var apartment_list_ui: Control

func _ready():
	# Set up interaction area
	_setup_interaction_area()
	
	# Connect to interaction manager if available
	var interaction_manager = get_node_or_null("/root/InteractionManagerUI")
	if interaction_manager:
		building_entered.connect(_on_building_entered)

func _setup_interaction_area():
	"""Set up the interaction detection area"""
	
	# Create interaction area
	var area = Area3D.new()
	add_child(area)
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = interaction_distance
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	
	# Connect signals
	area.connect("body_entered", _on_body_entered)
	area.connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	"""Called when player enters interaction range"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		player = body
		_show_interaction_prompt()

func _on_body_exited(body):
	"""Called when player exits interaction range"""
	if body == player:
		player_in_range = false
		player = null
		_hide_interaction_prompt()

func _show_interaction_prompt():
	"""Show building entrance prompt"""
	var interaction_manager = get_node_or_null("/root/InteractionManagerUI")
	if interaction_manager:
		interaction_manager.show_interaction_prompt("Press E to Enter Building", self)

func _hide_interaction_prompt():
	"""Hide interaction prompt"""
	var interaction_manager = get_node_or_null("/root/InteractionManagerUI")
	if interaction_manager:
		interaction_manager.hide_interaction_prompt(self)

func _input(event):
	"""Handle building entrance input"""
	if event.is_action_pressed("interact") and player_in_range:
		enter_building()

func enter_building():
	"""Handle building entrance - show floor selector"""
	if not building_reference:
		print("ERROR: No building reference set for entrance")
		return
	
	emit_signal("building_entered", building_reference)
	
	# Show floor selection UI
	_show_floor_selector()
	
	# Pause game
	var game_manager = get_node_or_null("/root/GameManagerUI")
	if game_manager:
		game_manager.open_ui()

func _show_floor_selector():
	"""Show floor selection UI"""
	
	if floor_selector_ui:
		floor_selector_ui.queue_free()
	
	# Create floor selector UI
	floor_selector_ui = Control.new()
	floor_selector_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(floor_selector_ui)
	
	# Background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floor_selector_ui.add_child(background)
	
	# Main panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(400, 500)
	panel.position = Vector2(-200, -250)
	floor_selector_ui.add_child(panel)
	
	# Title
	var title = Label.new()
	title.text = "Building Floor Selection"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 20)
	title.size = Vector2(300, 40)
	panel.add_child(title)
	
	# Get building info
	var building_floors = building_reference.get_meta("floors", 20)
	
	# Create floor buttons
	var scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(20, 70)
	scroll_container.size = Vector2(360, 350)
	panel.add_child(scroll_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	scroll_container.add_child(vbox)
	
	# Ground floor / Lobby
	var lobby_button = Button.new()
	lobby_button.text = "Ground Floor - Lobby"
	lobby_button.pressed.connect(_on_floor_selected.bind(0))
	vbox.add_child(lobby_button)
	
	# Apartment floors
	for floor_num in range(1, building_floors):
		var floor_button = Button.new()
		floor_button.text = "Floor %d - Apartments" % floor_num
		floor_button.pressed.connect(_on_floor_selected.bind(floor_num))
		vbox.add_child(floor_button)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Exit Building"
	close_button.position = Vector2(150, 440)
	close_button.size = Vector2(100, 40)
	close_button.pressed.connect(_close_floor_selector)
	panel.add_child(close_button)
	
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_floor_selected(floor_number: int):
	"""Handle floor selection"""
	current_floor = floor_number
	emit_signal("floor_changed", floor_number)
	
	if floor_number == 0:
		# Lobby - just show message for now
		_show_lobby()
	else:
		# Apartment floor - show apartment selector
		_show_apartment_selector(floor_number)

func _show_lobby():
	"""Show building lobby"""
	_close_floor_selector()
	
	# For now, just show a message
	# TODO: Create lobby interior when we expand the system

func _show_apartment_selector(floor_number: int):
	"""Show apartment selection for a floor"""
	_close_floor_selector()
	
	# Create apartment selector UI
	apartment_list_ui = Control.new()
	apartment_list_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(apartment_list_ui)
	
	# Background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	apartment_list_ui.add_child(background)
	
	# Main panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(350, 400)
	panel.position = Vector2(-175, -200)
	apartment_list_ui.add_child(panel)
	
	# Title
	var title = Label.new()
	title.text = "Floor %d - Select Apartment" % floor_number
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(25, 20)
	title.size = Vector2(300, 40)
	panel.add_child(title)
	
	# Get apartments per floor from building
	var apartments_per_floor = building_reference.get_meta("apartments_per_floor", 6)
	
	# Create apartment buttons
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 70)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	for apt_num in range(1, apartments_per_floor + 1):
		var apt_button = Button.new()
		apt_button.text = "Apartment %d%02d" % [floor_number, apt_num]
		apt_button.pressed.connect(_on_apartment_selected.bind(floor_number, apt_num))
		vbox.add_child(apt_button)
	
	# Back button
	var back_button = Button.new()
	back_button.text = "Back to Floors"
	back_button.position = Vector2(50, 330)
	back_button.size = Vector2(100, 40)
	back_button.pressed.connect(_back_to_floor_selector)
	panel.add_child(back_button)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Exit Building"
	close_button.position = Vector2(200, 330)
	close_button.size = Vector2(100, 40)
	close_button.pressed.connect(_close_apartment_selector)
	panel.add_child(close_button)

func _on_apartment_selected(floor_number: int, apartment_number: int):
	"""Handle apartment selection - generate and show interior"""
	
	var apt_key = "%d_%d" % [floor_number, apartment_number]
	
	# Check if apartment is already generated
	if not apartments_generated.has(apt_key):
		_generate_apartment_interior(floor_number, apartment_number)
		apartments_generated[apt_key] = true
	
	# Show the apartment
	_enter_apartment(floor_number, apartment_number)

func _generate_apartment_interior(floor_number: int, apartment_number: int):
	"""Generate apartment interior on demand"""
	
	# Create apartment generator
	var apartment_generator = load("res://scripts/world_generation/apartment_interior_generator.gd").new()
	
	# Determine apartment type based on building and floor
	var apartment_types = ["studio", "one_bedroom", "two_bedroom", "penthouse"]
	var apartment_type = apartment_types[apartment_number % apartment_types.size()]
	
	# If top floor, make it penthouse
	var building_floors = building_reference.get_meta("floors", 20)
	if floor_number >= building_floors - 2:
		apartment_type = "penthouse"
	
	# Calculate apartment position within building
	var apartments_per_floor = building_reference.get_meta("apartments_per_floor", 6)
	var building_footprint = building_reference.get_meta("footprint", {"width": 40, "depth": 30})
	
	var apt_width = building_footprint.width / apartments_per_floor
	var apt_x = -(building_footprint.width / 2.0) + (apartment_number - 1 + 0.5) * apt_width
	var apt_y = floor_number * 3.2  # Floor height
	var apt_z = 0
	
	var apartment_position = Vector3(apt_x, apt_y, apt_z)
	
	# Generate apartment interior
	var apartment_interior = apartment_generator.generate_apartment_interior(apartment_type, apartment_position)
	
	if apartment_interior:
		# Add to building structure
		building_reference.add_child(apartment_interior)

func _enter_apartment(floor_number: int, apartment_number: int):
	"""Enter the apartment - move player or camera"""
	_close_apartment_selector()
	
	# TODO: Move player/camera to apartment position
	# For now, just close the UI
	
	# Resume game
	var game_manager = get_node_or_null("/root/GameManagerUI")
	if game_manager:
		game_manager.close_ui()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _back_to_floor_selector():
	"""Go back to floor selection"""
	_close_apartment_selector()
	_show_floor_selector()

func _close_floor_selector():
	"""Close floor selector UI"""
	if floor_selector_ui:
		floor_selector_ui.queue_free()
		floor_selector_ui = null
	
	# Resume game
	var game_manager = get_node_or_null("/root/GameManagerUI")
	if game_manager:
		game_manager.close_ui()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _close_apartment_selector():
	"""Close apartment selector UI"""
	if apartment_list_ui:
		apartment_list_ui.queue_free()
		apartment_list_ui = null
	
	# Resume game
	var game_manager = get_node_or_null("/root/GameManagerUI")
	if game_manager:
		game_manager.close_ui()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_building_entered(building: Node3D):
	"""Handle building entered signal"""
	# Building entry handled - message removed for cleaner console output
	pass