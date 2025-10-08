extends Node
class_name CityGenerator

## City Generation System - Main Controller
## Orchestrates the procedural generation of the entire city

# Singleton reference
static var instance: CityGenerator

# Core generation data
var city_data: Dictionary
var building_templates: Dictionary
var apartment_layouts: Dictionary
var generation_config: Dictionary

# Generation state
var current_seed: int = 0
var generation_phase: String = "phase_1"
var generated_buildings: Array[Node3D] = []

# File paths
const DATA_PATH = "res://data/world_generation/"
const CITY_ZONES_FILE = DATA_PATH + "city_zones.json"
const BUILDING_TEMPLATES_FILE = DATA_PATH + "building_templates.json"
const APARTMENT_LAYOUTS_FILE = DATA_PATH + "apartment_layouts.json"
const GENERATION_CONFIG_FILE = DATA_PATH + "generation_config.json"

# Signals
signal generation_started()
signal generation_progress(current: int, total: int)
signal generation_completed()
signal building_spawned(building: Node3D)

func _ready():
	# Set up singleton
	if instance == null:
		instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		print("CityGenerator initialized")
		
		# Load all JSON data
		_load_generation_data()
	else:
		queue_free()

func _load_generation_data():
	"""Load all JSON configuration files"""
	
	# Load city zones
	city_data = _load_json_file(CITY_ZONES_FILE)
	if city_data.is_empty():
		print("ERROR: Failed to load city zones data")
		return
	
	# Load building templates
	building_templates = _load_json_file(BUILDING_TEMPLATES_FILE)
	if building_templates.is_empty():
		print("ERROR: Failed to load building templates")
		return
	
	# Load apartment layouts
	apartment_layouts = _load_json_file(APARTMENT_LAYOUTS_FILE)
	if apartment_layouts.is_empty():
		print("ERROR: Failed to load apartment layouts")
		return
	
	# Load generation config
	generation_config = _load_json_file(GENERATION_CONFIG_FILE)
	if generation_config.is_empty():
		print("ERROR: Failed to load generation config")
		return
	
	print("CityGenerator initialized")

func _load_json_file(file_path: String) -> Dictionary:
	"""Load and parse a JSON file"""
	if not FileAccess.file_exists(file_path):
		print("ERROR: File not found: %s" % file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open file: %s" % file_path)
		return {}
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result != OK:
		print("ERROR: Failed to parse JSON file: %s" % file_path)
		return {}
	
	return json.data

func generate_test_area(seed_value: int = -1):
	"""Generate the 4x4 test area in downtown core"""
	# Set up random seed
	if seed_value == -1:
		current_seed = randi()
	else:
		current_seed = seed_value
	
	seed(current_seed)
	
	# Get test area configuration
	var test_area = city_data.get("city_zones", {}).get("test_area", {})
	if test_area.is_empty():
		print("ERROR: No test area defined in city data")
		return
	
	# Get downtown core zone for building types
	var downtown_zone = city_data.get("city_zones", {}).get("districts", {}).get("downtown_core", {})
	if downtown_zone.is_empty():
		print("ERROR: Downtown core zone not found")
		return
	
	emit_signal("generation_started")
	
	# Generate 4x4 grid of buildings
	var test_bounds = test_area.get("bounds", {})
	var base_grid_size = city_data.get("city_zones", {}).get("map_info", {}).get("grid_cell_size", 50)
	# Increase spacing significantly to prevent overlap
	var building_spacing = base_grid_size * 2  # Double the spacing
	var buildings_generated = 0
	var total_buildings = 16  # 4x4 grid
	
	# Use batched generation for better performance
	var batch_size = 4  # Generate 4 buildings per frame
	var current_batch = 0
	
	for x in range(4):
		for y in range(4):
			# Calculate world position with proper spacing
			var world_x = test_bounds.get("x", 900) + (x * building_spacing)
			var world_y = test_bounds.get("y", 900) + (y * building_spacing)
			var world_pos = Vector3(world_x, 0, world_y)
			
			# Generate building at this position
			var building = _generate_building_at_position(world_pos, downtown_zone)
			if building:
				generated_buildings.append(building)
				emit_signal("building_spawned", building)
				buildings_generated += 1
				emit_signal("generation_progress", buildings_generated, total_buildings)
			
			current_batch += 1
			
			# Process in batches to prevent frame drops
			if current_batch >= batch_size:
				current_batch = 0
				await get_tree().process_frame  # Wait one frame
				await get_tree().process_frame  # Wait additional frame for stability
	
	emit_signal("generation_completed")

func _generate_building_at_position(world_pos: Vector3, zone_config: Dictionary) -> Node3D:
	"""Generate a single building at the specified world position"""
	
	# Select building type based on zone distribution
	var building_type = _select_building_type(zone_config)
	if building_type.is_empty():
		print("ERROR: Could not select building type")
		return null
	
	# Get building template
	var template = building_templates.get("building_templates", {}).get(building_type, {})
	if template.is_empty():
		print("ERROR: Building template not found: %s" % building_type)
		return null
	
	# Create optimized building spawner and generate
	var building_spawner = load("res://scripts/world_generation/building_spawner.gd").new()
	var building = building_spawner.create_building(template, world_pos, zone_config)
	
	if building:
		# Add to current scene
		get_tree().current_scene.add_child(building)
		building.name = "Building_%s_%d_%d" % [building_type, world_pos.x, world_pos.z]
	
	return building

func _select_building_type(zone_config: Dictionary) -> String:
	"""Select a building type based on zone distribution"""
	var building_types = zone_config.get("building_types", [])
	var distribution = zone_config.get("building_distribution", {})
	
	if building_types.is_empty():
		print("ERROR: No building types defined for zone")
		return ""
	
	# Use weighted random selection
	var random_value = randf()
	var cumulative_weight = 0.0
	
	for building_type in building_types:
		var weight = distribution.get(building_type, 1.0 / building_types.size())
		cumulative_weight += weight
		
		if random_value <= cumulative_weight:
			return building_type
	
	# Fallback to first type
	return building_types[0]

func clear_generated_buildings():
	"""Clear all generated buildings"""
	
	for building in generated_buildings:
		if is_instance_valid(building):
			building.queue_free()
	
	generated_buildings.clear()

func regenerate_with_new_seed():
	"""Clear current buildings and regenerate with a new seed"""
	clear_generated_buildings()
	await get_tree().process_frame  # Wait for cleanup
	generate_test_area()

# Static helper functions
static func get_instance() -> CityGenerator:
	return instance

static func is_ready() -> bool:
	return instance != null and not instance.city_data.is_empty()

# Debug functions
func get_generation_stats() -> Dictionary:
	"""Get current generation statistics"""
	return {
		"buildings_generated": generated_buildings.size(),
		"current_seed": current_seed,
		"generation_phase": generation_phase,
		"data_loaded": not city_data.is_empty()
	}

func print_generation_info():
	"""Print detailed generation information"""
	# Debug info removed for cleaner console output
	pass