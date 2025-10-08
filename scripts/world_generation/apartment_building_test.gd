extends Node3D
class_name ApartmentBuildingTest

## Test Scene for Single Building with Complete Apartment Interiors
## Generates one building with full collision, floors, walls, and apartments

# Building generation components
var city_generator: CityGenerator
var building_spawner: BuildingSpawner
var apartment_generator: ApartmentInteriorGenerator

# Building data
var current_building: Node3D
var building_template: Dictionary
var building_parameters: Dictionary

# Input protection
var input_cooldown: float = 0.0
var cooldown_time: float = 0.5  # 500ms between inputs

# Camera and player
@onready var camera: Camera3D
@onready var player_controller: CharacterBody3D

func _ready():
	# Get city generator instance
	city_generator = get_node("/root/CityGeneratorUI")
	
	# Create building spawner and apartment generator
	building_spawner = load("res://scripts/world_generation/building_spawner.gd").new()
	apartment_generator = load("res://scripts/world_generation/apartment_interior_generator.gd").new()
	
	# Wait a frame then generate test building
	await get_tree().process_frame
	_generate_test_building()

func _process(delta):
	"""Update input cooldown"""
	if input_cooldown > 0:
		input_cooldown -= delta

func _generate_test_building():
	"""Generate a single test building with complete interiors"""
	
	# Load building templates
	if not city_generator or not CityGenerator.is_ready():
		print("ERROR: City generator not ready")
		return
	
	# Get a random building template
	var building_templates = city_generator.building_templates.get("building_templates", {})
	if building_templates.is_empty():
		print("ERROR: No building templates found")
		return
	
	# Select random template
	var template_keys = building_templates.keys()
	var random_template_key = template_keys[randi() % template_keys.size()]
	building_template = building_templates[random_template_key]
	
	# Generate building at origin
	var building_position = Vector3.ZERO
	var zone_config = _get_test_zone_config()
	
	# Create the building structure
	current_building = _create_complete_building(building_template, building_position, zone_config)
	
	if current_building:
		add_child(current_building)
		
		# Generate all apartment interiors
		_generate_all_apartment_interiors()
	else:
		print("ERROR: Failed to generate test building")

func _get_test_zone_config() -> Dictionary:
	"""Get test zone configuration"""
	return {
		"height_restrictions": {"min": 12, "max": 20},
		"building_types": ["mixed_use_tower", "high_rise_residential", "modern_glass_tower"],
		"building_distribution": {
			"mixed_use_tower": 0.4,
			"high_rise_residential": 0.4,
			"modern_glass_tower": 0.2
		}
	}

func _create_complete_building(template: Dictionary, building_pos: Vector3, zone_config: Dictionary) -> Node3D:
	"""Create a complete building with collision and structure"""
	
	# Create main building node
	var building = Node3D.new()
	building.name = "TestBuilding"
	building.position = building_pos
	
	# Generate building parameters
	building_parameters = building_spawner._generate_optimized_building_parameters(template, zone_config)
	
	# Create building structure (exterior shell)
	var structure = _create_building_shell(building_parameters)
	if structure:
		building.add_child(structure)
	
	# Create floor slabs (collision floors between apartments)
	var floors = _create_building_floors(building_parameters)
	if floors:
		building.add_child(floors)
	
	# Create exterior windows and facade
	var exterior = building_spawner._create_minimal_exterior(building_parameters)
	if exterior:
		building.add_child(exterior)
	
	# Add building metadata
	building.set_meta("building_type", template.get("id", "unknown"))
	building.set_meta("floors", building_parameters.floors)
	building.set_meta("apartments_total", building_parameters.apartments_total)
	building.set_meta("apartments_per_floor", building_parameters.apartments_per_floor)
	building.set_meta("footprint", building_parameters.footprint)
	building.set_meta("template", template)
	
	return building

func _create_building_shell(params: Dictionary) -> Node3D:
	"""Create building exterior shell with collision"""
	
	var shell = Node3D.new()
	shell.name = "BuildingShell"
	
	var footprint = params.get("footprint", {"width": 40, "depth": 30})
	var height = params.get("building_height", 50)
	var _building_type = params.get("building_type", "unknown")
	
	# Create ground floor (lobby level)
	var ground_floor = _create_floor_slab(footprint, 0.0, "GroundFloor")
	shell.add_child(ground_floor)
	
	# Create roof
	var roof = _create_floor_slab(footprint, height, "Roof")
	shell.add_child(roof)
	
	# Note: Exterior walls removed to see apartment interiors
	return shell

func _create_exterior_walls_with_collision(footprint: Dictionary, height: float) -> Node3D:
	"""Create exterior walls with proper collision"""
	
	var walls = Node3D.new()
	walls.name = "ExteriorWalls"
	
	var width = footprint.get("width", 40)
	var depth = footprint.get("depth", 30)
	var wall_thickness = 0.5
	
	# Front wall
	var front_wall = _create_wall_with_collision(width, height, wall_thickness)
	front_wall.position = Vector3(0, height/2, depth/2)
	front_wall.name = "FrontWall"
	walls.add_child(front_wall)
	
	# Back wall  
	var back_wall = _create_wall_with_collision(width, height, wall_thickness)
	back_wall.position = Vector3(0, height/2, -depth/2)
	back_wall.name = "BackWall"
	walls.add_child(back_wall)
	
	# Left wall
	var left_wall = _create_wall_with_collision(wall_thickness, height, depth)
	left_wall.position = Vector3(-width/2, height/2, 0)
	left_wall.name = "LeftWall"
	walls.add_child(left_wall)
	
	# Right wall
	var right_wall = _create_wall_with_collision(wall_thickness, height, depth)
	right_wall.position = Vector3(width/2, height/2, 0)
	right_wall.name = "RightWall"
	walls.add_child(right_wall)
	
	return walls

func _create_wall_with_collision(width: float, height: float, depth: float) -> StaticBody3D:
	"""Create a wall with visual mesh and collision"""
	
	var wall = StaticBody3D.new()
	
	# Visual mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, height, depth)
	mesh_instance.mesh = box_mesh
	
	# Wall material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.75)
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	wall.add_child(mesh_instance)
	
	# Collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, depth)
	collision_shape.shape = box_shape
	wall.add_child(collision_shape)
	
	return wall

func _create_building_floors(params: Dictionary) -> Node3D:
	"""Create collision floors for each level"""
	
	var floors_container = Node3D.new()
	floors_container.name = "BuildingFloors"
	
	var footprint = params.get("footprint", {"width": 40, "depth": 30})
	var floor_height = params.get("floor_height", 3.2)
	var floors = params.get("floors", 12)
	
	# Create a floor slab for each level
	for floor_num in range(1, floors):  # Skip ground floor (already created)
		var floor_y = floor_num * floor_height
		var floor_slab = _create_floor_slab(footprint, floor_y, "Floor_%d" % floor_num)
		floors_container.add_child(floor_slab)
	
	return floors_container

func _create_floor_slab(footprint: Dictionary, y_position: float, slab_name: String) -> StaticBody3D:
	"""Create a floor slab with collision"""
	
	var floor_slab = StaticBody3D.new()
	floor_slab.name = slab_name
	floor_slab.position.y = y_position
	
	var width = footprint.get("width", 40)
	var depth = footprint.get("depth", 30)
	var slab_thickness = 0.3
	
	# Visual mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, slab_thickness, depth)
	mesh_instance.mesh = box_mesh
	
	# Floor material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7)
	material.roughness = 0.6
	mesh_instance.material_override = material
	
	floor_slab.add_child(mesh_instance)
	
	# Collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, slab_thickness, depth)
	collision_shape.shape = box_shape
	floor_slab.add_child(collision_shape)
	
	return floor_slab

func _generate_all_apartment_interiors():
	"""Generate apartment interiors using floor-by-floor approach for proper spacing"""
	
	if not current_building:
		print("ERROR: No building to generate apartments for")
		return
	
	var floors = building_parameters.get("floors", 12)
	var apartments_per_floor = building_parameters.get("apartments_per_floor", 6)
	var floor_height = building_parameters.get("floor_height", 3.2)
	var footprint = building_parameters.get("footprint", {"width": 40, "depth": 30})
	
	# Track apartment types for summary
	var apartment_counts = {"studio": 0, "one_bedroom": 0, "two_bedroom": 0, "penthouse": 0}
	
	# Create apartments container
	var apartments_container = Node3D.new()
	apartments_container.name = "AllApartments"
	current_building.add_child(apartments_container)
	
	# Generate floor by floor for consistency and proper spacing
	for floor_num in range(1, floors):  # Skip ground floor (lobby)
		var floor_result = _generate_floor_with_layout_planning(floor_num, footprint, floor_height, apartments_per_floor)
		if floor_result.container:
			apartments_container.add_child(floor_result.container)
			# Add to apartment counts
			for apt_type in floor_result.counts.keys():
				apartment_counts[apt_type] += floor_result.counts[apt_type]
	
	# Print single informative summary
	var total_apartments = apartment_counts.studio + apartment_counts.one_bedroom + apartment_counts.two_bedroom + apartment_counts.penthouse
	print("🏢 Building completed: %d apartments total | Studios: %d | 1BR: %d | 2BR: %d | Penthouses: %d" % [
		total_apartments, apartment_counts.studio, apartment_counts.one_bedroom, 
		apartment_counts.two_bedroom, apartment_counts.penthouse
	])

func _generate_floor_with_layout_planning(floor_num: int, building_footprint: Dictionary, floor_height: float, apartments_per_floor: int) -> Dictionary:
	"""Generate all apartments for a single floor with proper spatial planning"""
	
	var floor_container = Node3D.new()
	floor_container.name = "Floor_%d_Apartments" % floor_num
	
	var building_width = building_footprint.get("width", 40)
	var building_depth = building_footprint.get("depth", 30)
	
	# Track apartment types for this floor
	var floor_counts = {"studio": 0, "one_bedroom": 0, "two_bedroom": 0, "penthouse": 0}
	
	# Calculate optimal apartment layout for this floor
	var layout_plan = _calculate_optimal_floor_layout(building_width, building_depth, apartments_per_floor, floor_num)
	
	# Generate each apartment according to the layout plan
	for i in range(min(apartments_per_floor, layout_plan.size())):
		var apt_config = layout_plan[i]
		var apartment = _generate_apartment_from_config(floor_num, i + 1, apt_config, floor_height)
		if apartment:
			floor_container.add_child(apartment)
			var apt_type = apt_config.get("type", "studio")
			floor_counts[apt_type] += 1
	
	return {"container": floor_container, "counts": floor_counts}

func _calculate_optimal_floor_layout(building_width: float, building_depth: float, apartments_count: int, floor_num: int) -> Array:
	"""Calculate optimal apartment placement to prevent overlapping and respect building dimensions"""
	
	var layout_plan = []
	
	# Get apartment type distribution
	var apartment_layouts = city_generator.apartment_layouts.get("apartment_layouts", {})
	var apartment_types = ["studio", "one_bedroom", "two_bedroom"]
	
	# Special handling for top floors (penthouses)
	var total_floors = building_parameters.get("floors", 12)
	var is_penthouse_floor = floor_num >= total_floors - 2 and apartment_layouts.has("penthouse")
	
	if is_penthouse_floor:
		apartment_types = ["penthouse"]
		apartments_count = min(2, apartments_count)  # Limit penthouses
	
	# Calculate grid layout
	var sqrt_count = sqrt(apartments_count)
	var grid_cols = int(ceil(sqrt_count))
	var grid_rows = int(ceil(float(apartments_count) / float(grid_cols)))
	
	# Ensure we don't exceed building dimensions
	var max_cols_by_width = max(1, int(building_width / 6))  # Min 6m per apartment
	var max_rows_by_depth = max(1, int(building_depth / 8))  # Min 8m per apartment
	
	grid_cols = min(grid_cols, max_cols_by_width)
	grid_rows = min(grid_rows, max_rows_by_depth)
	
	# Recalculate apartments count if we had to reduce grid
	apartments_count = min(apartments_count, grid_cols * grid_rows)
	
	# Calculate cell dimensions with padding
	var padding = 0.5  # 0.5m padding between apartments
	var usable_width = building_width - (padding * (grid_cols + 1))
	var usable_depth = building_depth - (padding * (grid_rows + 1))
	var cell_width = usable_width / grid_cols
	var cell_depth = usable_depth / grid_rows
	
	# Generate apartment configurations
	for apt_index in range(apartments_count):
		var col = apt_index % grid_cols
		var row = int(apt_index / grid_cols)
		
		# Select apartment type
		var apt_type = apartment_types[apt_index % apartment_types.size()]
		var apt_layout = apartment_layouts.get(apt_type, {})
		var apt_size = apt_layout.get("size", {"width": 8, "depth": 10})
		
		# Calculate scale to fit in cell (with some margin)
		var scale_x = (cell_width * 0.95) / apt_size.get("width", 8)
		var scale_z = (cell_depth * 0.95) / apt_size.get("depth", 10)
		var uniform_scale = min(scale_x, scale_z, 1.0)  # Don't scale up, only down
		
		# Calculate position (center of cell)
		var apt_x = -(building_width / 2.0) + padding + (col * (cell_width + padding)) + (cell_width / 2.0)
		var apt_z = -(building_depth / 2.0) + padding + (row * (cell_depth + padding)) + (cell_depth / 2.0)
		
		layout_plan.append({
			"type": apt_type,
			"position": Vector3(apt_x, 0, apt_z),
			"scale": uniform_scale,
			"cell_info": {"width": cell_width, "depth": cell_depth, "col": col, "row": row}
		})
	
	return layout_plan

func _generate_apartment_from_config(floor_num: int, apt_num: int, config: Dictionary, floor_height: float) -> Node3D:
	"""Generate a single apartment using the calculated configuration"""
	
	var apartment_type = config.get("type", "studio")
	var base_position = config.get("position", Vector3.ZERO)
	var scale_factor = config.get("scale", 1.0)
	
	# Calculate final position (add floor height)
	var final_position = base_position + Vector3(0, floor_num * floor_height + 0.15, 0)
	
	# Generate apartment interior
	var apartment_interior = apartment_generator.generate_apartment_interior(apartment_type, final_position)
	
	if apartment_interior:
		apartment_interior.name = "Apartment_%d%02d_%s" % [floor_num, apt_num, apartment_type]
		
		# Apply calculated scale to fit in allocated space
		apartment_interior.scale = Vector3(scale_factor, 1.0, scale_factor)
		
		return apartment_interior
	
	return null

func _input(event):
	"""Handle input for building test"""
	
	# Check input cooldown
	if input_cooldown > 0:
		return
	
	if event.is_action_pressed("ui_accept"):  # Enter key
		_clear_current_building()
		_generate_test_building()
		input_cooldown = cooldown_time
	
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_clear_current_building()
		input_cooldown = cooldown_time

func _clear_current_building():
	"""Clear the current building"""
	if current_building:
		current_building.queue_free()
		current_building = null

func _on_building_info_requested():
	"""Print building information"""
	if not current_building:
		# No building generated yet
		return
	
	# Debug info removed for cleaner console output
	pass
