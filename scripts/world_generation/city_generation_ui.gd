extends Control
class_name CityGenerationUI

## City Generation UI - Test interface for city generation

@onready var generate_button: Button
@onready var clear_button: Button
@onready var regenerate_button: Button
@onready var seed_input: SpinBox
@onready var progress_bar: ProgressBar
@onready var status_label: Label

var city_generator: CityGenerator

func _ready():
	# Create UI elements
	_setup_ui()
	
	# Get reference to city generator autoload
	city_generator = get_node("/root/CityGeneratorUI")
	
	# Connect signals
	if city_generator:
		city_generator.generation_started.connect(_on_generation_started)
		city_generator.generation_progress.connect(_on_generation_progress)
		city_generator.generation_completed.connect(_on_generation_completed)
		city_generator.building_spawned.connect(_on_building_spawned)
	else:
		print("ERROR: CityGenerator autoload not found")

func _setup_ui():
	"""Create the UI elements for city generation testing"""
	
	# Set up main container
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(300, 200)
	position = Vector2(10, 10)
	
	# Background panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	# VBox container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# Add some padding
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size.y = 10
	vbox.add_child(spacer_top)
	
	# Title
	var title = Label.new()
	title.text = "City Generation Test"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Seed input
	var seed_container = HBoxContainer.new()
	var seed_label = Label.new()
	seed_label.text = "Seed:"
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 999999999
	seed_input.value = randi() % 1000000
	seed_container.add_child(seed_label)
	seed_container.add_child(seed_input)
	vbox.add_child(seed_container)
	
	# Buttons
	generate_button = Button.new()
	generate_button.text = "Generate 4x4 Test Area"
	generate_button.pressed.connect(_on_generate_pressed)
	vbox.add_child(generate_button)
	
	clear_button = Button.new()
	clear_button.text = "Clear Buildings"
	clear_button.pressed.connect(_on_clear_pressed)
	vbox.add_child(clear_button)
	
	regenerate_button = Button.new()
	regenerate_button.text = "Regenerate (New Seed)"
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	vbox.add_child(regenerate_button)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	vbox.add_child(progress_bar)
	
	# Status label
	status_label = Label.new()
	status_label.text = "Ready to generate\\nNote: First building (bottom-left) will have interactive entrance"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

func _on_generate_pressed():
	"""Handle generate button press"""
	if not city_generator:
		status_label.text = "ERROR: City generator not found"
		return
	
	if not city_generator or not CityGenerator.is_ready():
		status_label.text = "ERROR: City generator not ready"
		return
	
	var seed_value = int(seed_input.value)
	city_generator.generate_test_area(seed_value)

func _on_clear_pressed():
	"""Handle clear button press"""
	if city_generator:
		city_generator.clear_generated_buildings()
		status_label.text = "Buildings cleared"

func _on_regenerate_pressed():
	"""Handle regenerate button press"""
	if city_generator:
		# Generate new random seed
		var new_seed = randi() % 1000000
		seed_input.value = new_seed
		city_generator.regenerate_with_new_seed()

func _on_generation_started():
	"""Handle generation started signal"""
	generate_button.disabled = true
	clear_button.disabled = true
	regenerate_button.disabled = true
	progress_bar.visible = true
	progress_bar.value = 0
	status_label.text = "Generating city..."

func _on_generation_progress(current: int, total: int):
	"""Handle generation progress signal"""
	progress_bar.value = (float(current) / float(total)) * 100.0
	status_label.text = "Generating... %d/%d buildings" % [current, total]

func _on_generation_completed():
	"""Handle generation completed signal"""
	generate_button.disabled = false
	clear_button.disabled = false
	regenerate_button.disabled = false
	progress_bar.visible = false
	
	if city_generator:
		var stats = city_generator.get_generation_stats()
		status_label.text = "Completed! %d buildings generated" % stats.buildings_generated

func _on_building_spawned(building: Node3D):
	"""Handle building spawned signal"""
	# Building spawned - progress tracking handled elsewhere
	pass

# Input handling removed to prevent conflicts with camera controls
# UI now only responds to mouse clicks on buttons