extends RefCounted
class_name BuildingSpawner

## Optimized Building Spawner - Creates buildings with performance focus
## Reduces mesh complexity and uses caching for better performance

# Building generation constants
const FLOOR_HEIGHT = 3.2
const LOBBY_HEIGHT = 4.5

# Performance optimization: Cache materials and meshes
static var material_cache: Dictionary = {}
static var mesh_cache: Dictionary = {}

func create_building(template: Dictionary, world_pos: Vector3, zone_config: Dictionary) -> Node3D:
	"""Create a performance-optimized building from template"""
	
	# Create main building node
	var building = Node3D.new()
	building.position = world_pos
	
	# Generate building parameters with optimization constraints
	var building_params = _generate_optimized_building_parameters(template, zone_config)
	
	# Create simplified building structure
	var structure = _create_optimized_building_structure(building_params)
	if structure:
		building.add_child(structure)
	
	# Create minimal exterior details
	var exterior = _create_minimal_exterior(building_params)
	if exterior:
		building.add_child(exterior)
	
	# Create apartment metadata only (no meshes)
	var apartments = _create_apartment_metadata(building_params)
	if apartments:
		building.add_child(apartments)
	
	# Add building metadata
	building.set_meta("building_type", template.get("id", "unknown"))
	building.set_meta("floors", building_params.floors)
	building.set_meta("apartments_total", building_params.apartments_total)
	building.set_meta("apartments_per_floor", building_params.apartments_per_floor)
	building.set_meta("footprint", building_params.footprint)
	building.set_meta("optimized", true)
	
	# Add entrance system for the first building (test building)
	if world_pos.x == 900 and world_pos.z == 900:
		var entrance = _create_building_entrance(building_params)
		if entrance:
			entrance.building_reference = building
			building.add_child(entrance)
	
	
	return building

func _generate_optimized_building_parameters(template: Dictionary, zone_config: Dictionary) -> Dictionary:
	"""Generate building parameters respecting template specifications"""
	
	# Get floor range from template
	var floor_range = template.get("floors", {"min": 8, "max": 20})
	var min_floors = floor_range.get("min", 8)
	var max_floors = floor_range.get("max", 20)
	
	# Respect template range but cap for performance
	min_floors = max(min_floors, 8)  # Minimum 8 for performance
	max_floors = min(max_floors, 25)  # Maximum 25 for performance
	
	var floors = randi_range(min_floors, max_floors)
	
	# Apply zone height restrictions
	var zone_height = zone_config.get("height_restrictions", {})
	if zone_height.has("min"):
		floors = max(floors, zone_height.get("min", floors))
	if zone_height.has("max"):
		floors = min(floors, zone_height.get("max", floors))
	
	# Use template apartment count but optimize
	var template_apts = template.get("apartments_per_floor", 6)
	var apartments_per_floor = min(template_apts, 8)  # Cap at 8 for performance
	var apartments_total = (floors - 1) * apartments_per_floor
	
	# Get building footprint from template
	var template_footprint = template.get("footprint", {"width": 40, "depth": 30})
	var footprint = {
		"width": min(template_footprint.get("width", 40), 60),
		"depth": min(template_footprint.get("depth", 30), 50)
	}
	
	# Get template-specific properties
	var color_schemes = template.get("color_schemes", [{"primary": "#808080"}])
	var color_scheme = color_schemes[randi() % color_schemes.size()]
	
	var construction_materials = template.get("construction_materials", ["concrete"])
	var architectural_style = template.get("architectural_style", "modern")
	var floor_height = template.get("floor_height", FLOOR_HEIGHT)
	var lobby_height = template.get("lobby_height", LOBBY_HEIGHT)
	
	return {
		"template": template,
		"floors": floors,
		"footprint": footprint,
		"apartments_per_floor": apartments_per_floor,
		"apartments_total": apartments_total,
		"floor_height": floor_height,
		"lobby_height": lobby_height,
		"color_scheme": color_scheme,
		"architectural_style": architectural_style,
		"construction_materials": construction_materials,
		"building_height": (floors - 1) * floor_height + lobby_height,
		"building_type": template.get("id", "unknown")
	}

func _create_optimized_building_structure(params: Dictionary) -> Node3D:
	"""Create building structure with type-specific variations"""
	
	var structure = Node3D.new()
	structure.name = "Structure"
	
	# Get building parameters
	var footprint = params.get("footprint", {"width": 40, "depth": 30})
	var height = params.get("building_height", 50)
	var building_type = params.get("building_type", "unknown")
	
	# Modify footprint based on building type for variety
	var width = footprint.width
	var depth = footprint.depth
	
	if building_type == "modern_glass_tower":
		# Glass towers are taller and thinner
		width *= 0.8
		depth *= 0.9
	elif building_type == "mixed_use_tower":
		# Mixed-use towers are wider at base
		width *= 1.1
		depth *= 1.0
	elif building_type == "high_rise_residential":
		# High-rise residential slightly larger
		width *= 1.0
		depth *= 1.1
	
	# Create or get cached mesh with type variation
	var cache_key = "structure_%d_%d_%d_%s" % [width, depth, height, building_type]
	
	var mesh_instance = MeshInstance3D.new()
	
	if mesh_cache.has(cache_key):
		mesh_instance.mesh = mesh_cache[cache_key]
	else:
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(width, height, depth)
		mesh_instance.mesh = box_mesh
		mesh_cache[cache_key] = box_mesh
	
	# Apply type-specific material
	mesh_instance.material_override = _get_cached_material(params)
	mesh_instance.position.y = height / 2.0
	
	# Add simplified collision shape for performance
	var collision_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, depth)
	collision_shape.shape = box_shape
	collision_shape.position.y = height / 2.0
	collision_body.add_child(collision_shape)
	structure.add_child(collision_body)
	
	structure.add_child(mesh_instance)
	
	return structure

func _create_minimal_exterior(params: Dictionary) -> Node3D:
	"""Create minimal exterior details for performance"""
	
	var exterior = Node3D.new()
	exterior.name = "Exterior"
	
	# Only create a few windows for visual appeal
	var windows = _create_minimal_windows(params)
	if windows:
		exterior.add_child(windows)
	
	return exterior

func _create_minimal_windows(params: Dictionary) -> Node3D:
	"""Create apartment windows based on template specifications"""
	
	var windows_node = Node3D.new()
	windows_node.name = "Windows"
	
	var footprint = params.get("footprint", {"width": 40, "depth": 30})
	var floors = params.get("floors", 12)
	var floor_height = params.get("floor_height", FLOOR_HEIGHT)
	var apartments_per_floor = params.get("apartments_per_floor", 6)
	var building_type = params.get("building_type", "unknown")
	
	# Adjust window style based on building type
	var window_style = "standard"
	if building_type == "modern_glass_tower":
		window_style = "floor_to_ceiling"
	elif building_type == "mixed_use_tower":
		window_style = "mixed"
	
	# Create windows and divisions for front and back faces
	for side in ["front", "back"]:
		var z_offset = (footprint.depth / 2.0 + 0.1) if side == "front" else -(footprint.depth / 2.0 + 0.1)
		
		# Create floor divisions and apartment windows
		for floor_num in range(1, floors):  # Skip ground floor (lobby)
			var y_pos = floor_num * floor_height
			
			# Create floor division line (every floor for glass towers, every 2 for others)
			var should_create_floor_line = (building_type == "modern_glass_tower") or (floor_num % 2 == 1)
			if should_create_floor_line:
				var floor_line = _create_floor_division(footprint.width)
				floor_line.position = Vector3(0, y_pos, z_offset)
				windows_node.add_child(floor_line)
			
			# Create apartment windows based on template
			var window_width = footprint.width / apartments_per_floor
			for apt_idx in range(apartments_per_floor):
				var x_offset = -(footprint.width / 2.0) + (apt_idx + 0.5) * window_width
				
				# Create apartment window with type-specific styling
				var window = _get_type_specific_window(window_style)
				window.position = Vector3(x_offset, y_pos + floor_height / 2.0, z_offset)
				windows_node.add_child(window)
				
				# Create vertical apartment divider (except for last apartment)
				if apt_idx < apartments_per_floor - 1:
					var divider = _create_apartment_divider(floor_height)
					divider.position = Vector3(x_offset + window_width / 2.0, y_pos + floor_height / 2.0, z_offset)
					windows_node.add_child(divider)
	
	return windows_node

func _get_cached_window() -> MeshInstance3D:
	"""Get or create cached window mesh"""
	
	const WINDOW_CACHE_KEY = "standard_window"
	
	if mesh_cache.has(WINDOW_CACHE_KEY):
		var cached_window = MeshInstance3D.new()
		cached_window.mesh = mesh_cache[WINDOW_CACHE_KEY]
		cached_window.material_override = _get_window_material()
		return cached_window
	
	# Create new window mesh
	var window = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(3.0, 2.0)  # Apartment-sized window
	window.mesh = quad_mesh
	window.material_override = _get_window_material()
	window.name = "Window"
	
	# Cache the mesh
	mesh_cache[WINDOW_CACHE_KEY] = quad_mesh
	
	return window

func _get_type_specific_window(window_style: String) -> MeshInstance3D:
	"""Get window based on building type"""
	
	if window_style == "floor_to_ceiling":
		# Larger windows for glass towers
		var cache_key = "glass_tower_window"
		if mesh_cache.has(cache_key):
			var cached_window = MeshInstance3D.new()
			cached_window.mesh = mesh_cache[cache_key]
			cached_window.material_override = _get_glass_window_material()
			return cached_window
		
		var window = MeshInstance3D.new()
		var quad_mesh = QuadMesh.new()
		quad_mesh.size = Vector2(4.0, 2.8)  # Larger for glass towers
		window.mesh = quad_mesh
		window.material_override = _get_glass_window_material()
		window.name = "GlassWindow"
		mesh_cache[cache_key] = quad_mesh
		return window
	
	elif window_style == "mixed":
		# Different sized windows for mixed-use
		var cache_key = "mixed_use_window"
		if mesh_cache.has(cache_key):
			var cached_window = MeshInstance3D.new()
			cached_window.mesh = mesh_cache[cache_key]
			cached_window.material_override = _get_window_material()
			return cached_window
		
		var window = MeshInstance3D.new()
		var quad_mesh = QuadMesh.new()
		quad_mesh.size = Vector2(3.5, 2.2)  # Medium sized
		window.mesh = quad_mesh
		window.material_override = _get_window_material()
		window.name = "MixedWindow"
		mesh_cache[cache_key] = quad_mesh
		return window
	
	else:
		# Standard residential window
		return _get_cached_window()

func _get_glass_window_material() -> StandardMaterial3D:
	"""Get special material for glass tower windows"""
	
	const GLASS_MATERIAL_KEY = "glass_tower_window_material"
	
	if material_cache.has(GLASS_MATERIAL_KEY):
		return material_cache[GLASS_MATERIAL_KEY]
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.05, 0.15, 0.25, 0.6)  # More transparent blue
	material.metallic = 0.9
	material.roughness = 0.05
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	material_cache[GLASS_MATERIAL_KEY] = material
	return material

func _create_floor_division(width: float) -> MeshInstance3D:
	"""Create horizontal floor division line"""
	
	var division = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, 0.1, 0.2)  # Thin horizontal line
	division.mesh = box_mesh
	division.name = "FloorDivision"
	
	# Dark material for floor lines
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	division.material_override = material
	
	return division

func _create_apartment_divider(height: float) -> MeshInstance3D:
	"""Create vertical apartment divider"""
	
	var divider = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.1, height, 0.2)  # Thin vertical line
	divider.mesh = box_mesh
	divider.name = "ApartmentDivider"
	
	# Dark material for divider lines
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4, 0.4)
	divider.material_override = material
	
	return divider

func _get_window_material() -> StandardMaterial3D:
	"""Get or create cached window material"""
	
	const WINDOW_MATERIAL_KEY = "window_glass"
	
	if material_cache.has(WINDOW_MATERIAL_KEY):
		return material_cache[WINDOW_MATERIAL_KEY]
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.2, 0.3, 0.7)
	material.metallic = 0.8
	material.roughness = 0.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	material_cache[WINDOW_MATERIAL_KEY] = material
	return material

func _get_cached_material(params: Dictionary) -> StandardMaterial3D:
	"""Get or create cached building material with type-specific variations"""
	
	var color_scheme = params.get("color_scheme", {"primary": "#808080"})
	var materials = params.get("construction_materials", ["concrete"])
	var building_type = params.get("building_type", "unknown")
	
	# Create cache key including building type for variety
	var cache_key = str(color_scheme.get("primary", "#808080")) + "_" + str(materials[0] if materials.size() > 0 else "concrete") + "_" + building_type
	
	if material_cache.has(cache_key):
		return material_cache[cache_key]
	
	var material = StandardMaterial3D.new()
	var primary_color = Color(color_scheme.get("primary", "#808080"))
	material.albedo_color = primary_color
	
	# Apply material properties based on construction materials and building type
	if "glass" in materials or building_type == "modern_glass_tower":
		material.metallic = 0.4
		material.roughness = 0.05
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.85
		# Glass towers should be more reflective
		if building_type == "modern_glass_tower":
			material.metallic = 0.6
			material.albedo_color = primary_color.lerp(Color.CYAN, 0.2)
	elif "steel" in materials or building_type == "mixed_use_tower":
		material.metallic = 0.7
		material.roughness = 0.2
		# Mixed-use towers get varied colors
		if building_type == "mixed_use_tower":
			material.albedo_color = primary_color.lerp(Color.WHITE, 0.1)
	elif "brick" in materials:
		material.roughness = 0.9
		material.albedo_color = primary_color.darkened(0.2)
	else:  # Concrete - residential buildings
		material.roughness = 0.6
		if building_type == "high_rise_residential":
			material.albedo_color = primary_color.lerp(Color.LIGHT_GRAY, 0.15)
	
	material_cache[cache_key] = material
	return material

func _create_apartment_metadata(params: Dictionary) -> Node3D:
	"""Create minimal apartment metadata for performance"""
	
	var apartments_node = Node3D.new()
	apartments_node.name = "Apartments"
	
	var floors = params.get("floors", 12)
	var apartments_per_floor = params.get("apartments_per_floor", 6)
	var floor_height = params.get("floor_height", FLOOR_HEIGHT)
	
	# Create only floor containers, no individual apartment nodes
	for floor_num in range(1, floors):
		var floor_node = Node3D.new()
		floor_node.name = "Floor_%d" % floor_num
		floor_node.position.y = floor_num * floor_height
		
		# Store metadata without creating child nodes
		floor_node.set_meta("floor_number", floor_num)
		floor_node.set_meta("apartments_count", apartments_per_floor)
		floor_node.set_meta("apartment_type", "mixed")
		
		apartments_node.add_child(floor_node)
	
	return apartments_node

# Static function to clear caches if needed
static func clear_caches():
	"""Clear material and mesh caches"""
	material_cache.clear()
	mesh_cache.clear()

func _create_building_entrance(params: Dictionary) -> Node3D:
	"""Create an interactive building entrance"""
	
	var entrance_script = load("res://scripts/world_generation/building_entrance.gd")
	var entrance = entrance_script.new()
	entrance.name = "BuildingEntrance"
	
	var footprint = params.get("footprint", {"width": 40, "depth": 30})
	
	# Position entrance at the front of the building
	entrance.position = Vector3(0, 1.0, -footprint.depth/2 - 1.0)
	
	# Create entrance visual marker
	var entrance_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2.0, 2.5, 0.3)
	entrance_mesh.mesh = box_mesh
	entrance_mesh.position = Vector3(0, 1.25, 0)
	
	# Entrance material (distinct color)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.2)  # Golden entrance
	material.metallic = 0.3
	entrance_mesh.material_override = material
	
	entrance.add_child(entrance_mesh)
	
	# Add collision shape for entrance interaction
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 2.5, 0.3)
	collision.shape = box_shape
	collision.position = Vector3(0, 1.25, 0)
	entrance.add_child(collision)
	
	return entrance