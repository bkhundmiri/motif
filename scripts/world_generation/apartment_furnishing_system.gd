extends RefCounted
class_name ApartmentFurnishingSystem

## Dynamic Apartment Furnishing System
## Creates furniture and interactables based on room types and dimensions
## Designed for maximum reusability across all apartment layouts

# Furniture placement strategies
enum PlacementStrategy {
	WALL_ADJACENT,    # Against walls (beds, counters, etc.)
	CENTER_FOCUS,     # Central focal points (dining tables, coffee tables)
	CORNER_FILL,      # Corner placements (reading chairs, plants)
	PERIMETER_FLOW,   # Around room edges (storage, decor)
	FUNCTIONAL_ZONE   # Specific activity areas (workspace, cooking zone)
}

# Room function definitions with required furniture categories
const ROOM_FUNCTIONS = {
	"bathroom": {
		"essential": ["toilet", "sink", "shower_tub"],
		"optional": ["mirror", "storage", "towel_rack"],
		"style_variants": ["modern", "traditional", "minimalist"]
	},
	"kitchen": {
		"essential": ["stove", "refrigerator", "sink", "counter"],
		"optional": ["dishwasher", "microwave", "pantry", "island"],
		"style_variants": ["modern", "farmhouse", "industrial"]
	},
	"living": {
		"essential": ["sofa", "coffee_table"],
		"optional": ["tv_stand", "bookshelf", "plants", "art"],
		"style_variants": ["contemporary", "cozy", "minimalist"]
	},
	"studio_living": {
		"essential": ["bed", "coffee_table", "stove"],
		"optional": ["sofa", "tv_stand", "dresser", "nightstand"],
		"style_variants": ["modern", "minimalist", "compact"]
	},
	"bedroom": {
		"essential": ["bed", "dresser", "lighting"],
		"optional": ["nightstand", "closet", "desk", "chair"],
		"style_variants": ["modern", "rustic", "elegant"]
	},
	"dining": {
		"essential": ["table", "chairs"],
		"optional": ["buffet", "lighting", "art"],
		"style_variants": ["formal", "casual", "bistro"]
	}
}

# Furniture asset definitions with dimensions and placement rules
const FURNITURE_CATALOG = {
	# Bathroom Furniture
	"toilet": {
		"size": Vector3(0.4, 0.8, 0.6),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.8, 0, 1.0),
		"wall_distance": 0.1,
		"scene_path": "res://scenes/items/toilet.tscn"
	},
	"sink": {
		"size": Vector3(0.5, 0.9, 0.4),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.8, 0, 0.8),
		"wall_distance": 0.05,
		"scene_path": "res://scenes/items/sink.tscn"
	},
	"shower_tub": {
		"size": Vector3(1.5, 2.0, 0.8),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.8, 0, 0.0),
		"wall_distance": 0.0
	},
	
	# Kitchen Furniture
	"stove": {
		"size": Vector3(0.6, 0.9, 0.6),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(1.0, 0, 1.2),
		"wall_distance": 0.05,
		"scene_path": "res://scenes/items/stove.tscn"
	},
	"refrigerator": {
		"size": Vector3(0.7, 1.8, 0.7),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(1.0, 0, 1.0),
		"wall_distance": 0.05
	},
	"counter": {
		"size": Vector3(2.0, 0.9, 0.6),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.0, 0, 1.2),
		"wall_distance": 0.05
	},
	
	# Living Room Furniture
	"sofa": {
		"size": Vector3(2.0, 0.8, 0.9),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.3, 0, 1.5),
		"wall_distance": 0.2,
		"scene_path": "res://scenes/items/sofa.tscn"
	},
	"coffee_table": {
		"size": Vector3(1.2, 0.4, 0.6),
		"placement": PlacementStrategy.CENTER_FOCUS,
		"required_clearance": Vector3(0.8, 0, 0.8),
		"wall_distance": 0.0,
		"scene_path": "res://scenes/items/coffee_table.tscn"
	},
	"tv_stand": {
		"size": Vector3(1.5, 0.5, 0.4),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.2, 0, 2.5),
		"wall_distance": 0.1
	},
	
	# Bedroom Furniture
	"bed": {
		"size": Vector3(2.1, 0.8, 1.1),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.8, 0, 0.8),
		"wall_distance": 0.1,
		"scene_path": "res://scenes/items/bed.tscn"
	},
	"dresser": {
		"size": Vector3(1.2, 2.0, 0.6),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.5, 0, 1.0),
		"wall_distance": 0.1,
		"scene_path": "res://scenes/items/wardrobe.tscn"
	},
	"nightstand": {
		"size": Vector3(0.4, 0.6, 0.4),
		"placement": PlacementStrategy.WALL_ADJACENT,
		"required_clearance": Vector3(0.3, 0, 0.5),
		"wall_distance": 0.1
	}
}

func furnish_room(room, parent: Node3D, style_preference: String = "modern") -> Array:
	"""
	Main function to furnish a room based on its type and dimensions
	room: ApartmentRoom object
	Returns array of created furniture nodes for tracking
	"""
	var furniture_nodes = []
	var room_function = _determine_room_function(room)
	
	print("🪑 Furnishing room: %s (Function: %s, Style: %s)" % [room.name, room_function, style_preference])
	print("  Room bounds: %s to %s" % [room.min_pos, room.max_pos])
	
	if not ROOM_FUNCTIONS.has(room_function):
		print("⚠️  Unknown room function: %s" % room_function)
		return furniture_nodes
	
	var room_config = ROOM_FUNCTIONS[room_function]
	var available_space = _calculate_available_space(room)
	
	# Place essential furniture first
	for furniture_type in room_config["essential"]:
		print("  🔍 Placing essential: %s" % furniture_type)
		var placed_furniture = _place_furniture_item(furniture_type, room, parent, available_space, style_preference)
		if placed_furniture:
			furniture_nodes.append(placed_furniture)
			_update_available_space(available_space, placed_furniture)
	
	# Place optional furniture based on remaining space
	for furniture_type in room_config["optional"]:
		if _has_space_for_furniture(furniture_type, available_space):
			var placed_furniture = _place_furniture_item(furniture_type, room, parent, available_space, style_preference)
			if placed_furniture:
				furniture_nodes.append(placed_furniture)
				_update_available_space(available_space, placed_furniture)
	
	print("✅ Furnished %s with %d items" % [room.name, furniture_nodes.size()])
	return furniture_nodes

func _determine_room_function(room) -> String:
	"""Determine the primary function of a room based on its type and name"""
	# Direct mapping from room type
	if ROOM_FUNCTIONS.has(room.room_type):
		print("  🏠 Room %s mapped to function: %s" % [room.name, room.room_type])
		return room.room_type
	
	# Handle open concept spaces (studio apartments)
	if "living" in room.name.to_lower() and "kitchen" in room.name.to_lower():
		print("  🏠 Room %s mapped to function: studio_living" % room.name)
		return "studio_living"  # Special case for studio apartments
	elif "living" in room.name.to_lower():
		print("  🏠 Room %s mapped to function: living" % room.name)
		return "living"
	elif "kitchen" in room.name.to_lower():
		return "kitchen"
	elif "open" in room.name.to_lower():
		return "living"  # Default open spaces to living room function
	
	# Fallback
	return "living"

func _calculate_available_space(room) -> Dictionary:
	"""Calculate available placement zones within a room"""
	var room_size = room.max_pos - room.min_pos
	
	return {
		"total_area": room_size.x * room_size.z,
		"usable_area": (room_size.x - 0.6) * (room_size.z - 0.6),  # Account for clearances
		"wall_segments": _identify_wall_segments(room),
		"center_zones": _identify_center_zones(room),
		"corner_zones": _identify_corner_zones(room),
		"occupied_zones": []  # Will be populated as furniture is placed
	}

func _identify_wall_segments(room) -> Array:
	"""Identify available wall segments for furniture placement"""
	var segments = []
	var room_size = room.max_pos - room.min_pos
	
	# North wall (front)
	segments.append({
		"wall": "north",
		"start": Vector3(room.min_pos.x + 0.3, room.min_pos.y, room.min_pos.z + 0.1),
		"end": Vector3(room.max_pos.x - 0.3, room.min_pos.y, room.min_pos.z + 0.1),
		"length": room_size.x - 0.6,
		"direction": Vector3.BACK,  # Furniture faces into room
		"tangent": Vector3.RIGHT,   # Along wall direction
		"available": true
	})
	
	# South wall (back)
	segments.append({
		"wall": "south",
		"start": Vector3(room.min_pos.x + 0.3, room.min_pos.y, room.max_pos.z - 0.1),
		"end": Vector3(room.max_pos.x - 0.3, room.min_pos.y, room.max_pos.z - 0.1),
		"length": room_size.x - 0.6,
		"direction": Vector3.FORWARD,  # Furniture faces into room
		"tangent": Vector3.RIGHT,      # Along wall direction
		"available": true
	})
	
	# East wall (right)
	segments.append({
		"wall": "east",
		"start": Vector3(room.max_pos.x - 0.1, room.min_pos.y, room.min_pos.z + 0.3),
		"end": Vector3(room.max_pos.x - 0.1, room.min_pos.y, room.max_pos.z - 0.3),
		"length": room_size.z - 0.6,
		"direction": Vector3.LEFT,     # Furniture faces into room
		"tangent": Vector3.BACK,       # Along wall direction
		"available": true
	})
	
	# West wall (left)
	segments.append({
		"wall": "west",
		"start": Vector3(room.min_pos.x + 0.1, room.min_pos.y, room.min_pos.z + 0.3),
		"end": Vector3(room.min_pos.x + 0.1, room.min_pos.y, room.max_pos.z - 0.3),
		"length": room_size.z - 0.6,
		"direction": Vector3.RIGHT,    # Furniture faces into room
		"tangent": Vector3.BACK,       # Along wall direction
		"available": true
	})
	
	return segments

func _identify_center_zones(room) -> Array:
	"""Identify central placement zones for focal furniture"""
	var room_center = (room.min_pos + room.max_pos) * 0.5
	var room_size = room.max_pos - room.min_pos
	
	return [{
		"position": room_center,
		"size": Vector3(room_size.x * 0.4, 0, room_size.z * 0.4),
		"available": true
	}]

func _identify_corner_zones(room) -> Array:
	"""Identify corner zones for accent furniture"""
	var corners = []
	var offset = Vector3(0.4, 0, 0.4)
	
	# Four corners with slight inset
	corners.append({"position": room.min_pos + offset, "available": true})
	corners.append({"position": Vector3(room.max_pos.x - offset.x, room.min_pos.y, room.min_pos.z + offset.z), "available": true})
	corners.append({"position": Vector3(room.min_pos.x + offset.x, room.min_pos.y, room.max_pos.z - offset.z), "available": true})
	corners.append({"position": room.max_pos - offset, "available": true})
	
	return corners

func _place_furniture_item(furniture_type: String, room, parent: Node3D, available_space: Dictionary, style: String) -> Node3D:
	"""Place a single furniture item in the optimal location"""
	print("    🛋️ Attempting to place: %s" % furniture_type)
	
	if not FURNITURE_CATALOG.has(furniture_type):
		print("    ⚠️  Unknown furniture type: %s" % furniture_type)
		return null
	
	var furniture_config = FURNITURE_CATALOG[furniture_type]
	print("    📋 Furniture config: placement=%s, size=%s" % [furniture_config["placement"], furniture_config["size"]])
	
	var placement_position = _find_optimal_placement(furniture_config, available_space)
	
	if placement_position == Vector3.ZERO:
		print("    ❌ No space found for %s in room %s" % [furniture_type, room.name])
		return null
	
	# Create furniture node
	var furniture_node = _create_furniture_mesh(furniture_type, furniture_config, style)
	
	# Ensure furniture is placed on the floor (Y = 0)
	placement_position.y = 0
	furniture_node.position = placement_position
	furniture_node.name = "%s_%s" % [room.name, furniture_type]
	
	parent.add_child(furniture_node)
	print("    ✅ Placed %s at %s" % [furniture_type, placement_position])
	
	return furniture_node

func _find_optimal_placement(furniture_config: Dictionary, available_space: Dictionary) -> Vector3:
	"""Find the best placement position for furniture based on its strategy"""
	match furniture_config["placement"]:
		PlacementStrategy.WALL_ADJACENT:
			return _find_wall_placement(furniture_config, available_space)
		PlacementStrategy.CENTER_FOCUS:
			return _find_center_placement(furniture_config, available_space)
		PlacementStrategy.CORNER_FILL:
			return _find_corner_placement(furniture_config, available_space)
		_:
			return _find_wall_placement(furniture_config, available_space)  # Default

func _find_wall_placement(furniture_config: Dictionary, available_space: Dictionary) -> Vector3:
	"""Find placement along walls with proper clearance"""
	for wall_segment in available_space["wall_segments"]:
		if not wall_segment["available"]:
			continue
		
		var furniture_size = furniture_config["size"]
		var furniture_length = max(furniture_size.x, furniture_size.z)
		var wall_distance = furniture_config.get("wall_distance", 0.1)
		
		if wall_segment["length"] >= furniture_length:
			# Calculate position with proper wall offset
			var placement_pos = wall_segment["start"]
			
			# Offset from wall based on wall direction
			var wall_direction = wall_segment.get("direction", Vector3.FORWARD)
			placement_pos += wall_direction * (wall_distance + furniture_size.z * 0.5)
			
			# Also move inward from the edge of the wall segment
			var wall_tangent = wall_segment.get("tangent", Vector3.RIGHT)
			placement_pos += wall_tangent * (furniture_length * 0.5)
			
			wall_segment["available"] = false  # Mark as used
			print("    📍 Wall placement at: %s (offset: %s)" % [placement_pos, wall_distance])
			return placement_pos
	
	print("    ❌ No suitable wall space found")
	return Vector3.ZERO  # No suitable wall space found

func _find_center_placement(_furniture_config: Dictionary, available_space: Dictionary) -> Vector3:
	"""Find placement in center zones"""
	for center_zone in available_space["center_zones"]:
		if center_zone["available"]:
			center_zone["available"] = false
			return center_zone["position"]
	
	return Vector3.ZERO

func _find_corner_placement(_furniture_config: Dictionary, available_space: Dictionary) -> Vector3:
	"""Find placement in corner zones"""
	for corner_zone in available_space["corner_zones"]:
		if corner_zone["available"]:
			corner_zone["available"] = false
			return corner_zone["position"]
	
	return Vector3.ZERO

func _create_furniture_mesh(furniture_type: String, config: Dictionary, style: String) -> Node3D:
	"""Create the actual 3D mesh for furniture"""
	var furniture_node: Node3D = null
	
	print("    🔧 Creating furniture: %s" % furniture_type)
	
	# Check if we have a scene file for this furniture type
	if config.has("scene_path"):
		var scene_path = config["scene_path"]
		print("    📁 Loading scene: %s" % scene_path)
		
		if ResourceLoader.exists(scene_path):
			var furniture_scene = load(scene_path)
			if furniture_scene:
				furniture_node = furniture_scene.instantiate()
				print("    ✅ Loaded furniture scene: %s" % scene_path)
			else:
				print("    ⚠️ Failed to instantiate scene: %s" % scene_path)
		else:
			print("    ❌ Scene file does not exist: %s" % scene_path)
	
	# Fallback to placeholder if scene loading fails
	if not furniture_node:
		print("    📦 Creating placeholder for: %s" % furniture_type)
		furniture_node = _create_placeholder_furniture(furniture_type, config, style)
	
	# Set the name for debugging
	furniture_node.name = furniture_type.capitalize()
	
	# Add interaction capabilities (for future interactables)
	_add_interaction_component(furniture_node, furniture_type)
	
	return furniture_node

func _create_placeholder_furniture(furniture_type: String, config: Dictionary, style: String) -> Node3D:
	"""Create placeholder furniture when scene file is not available"""
	var furniture_node = Node3D.new()
	
	# Create visual representation (placeholder box)
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = config["size"]
	mesh_instance.mesh = box_mesh
	
	# Create material based on furniture type and style
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_furniture_color(furniture_type, style)
	mesh_instance.material_override = material
	
	furniture_node.add_child(mesh_instance)
	
	return furniture_node

func _get_furniture_color(furniture_type: String, style: String) -> Color:
	"""Get appropriate color for furniture based on type and style"""
	var color_schemes = {
		"modern": {
			"default": Color.WHITE,
			"wood": Color(0.8, 0.6, 0.4),
			"metal": Color(0.7, 0.7, 0.8)
		},
		"traditional": {
			"default": Color(0.6, 0.4, 0.3),
			"wood": Color(0.5, 0.3, 0.2),
			"fabric": Color(0.7, 0.6, 0.5)
		}
	}
	
	var scheme = color_schemes.get(style, color_schemes["modern"])
	
	# Furniture-specific colors
	match furniture_type:
		"bed_double", "dresser", "coffee_table":
			return scheme.get("wood", scheme["default"])
		"refrigerator", "stove":
			return scheme.get("metal", Color.WHITE)
		"sofa":
			return scheme.get("fabric", Color.GRAY)
		_:
			return scheme["default"]

func _add_interaction_component(furniture_node: Node3D, furniture_type: String):
	"""Add interaction capabilities to furniture for future gameplay"""
	# Add metadata for interaction system
	furniture_node.set_meta("furniture_type", furniture_type)
	furniture_node.set_meta("interactable", true)
	
	# Add collision for interaction detection
	var collision_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = FURNITURE_CATALOG[furniture_type]["size"]
	collision_shape.shape = box_shape
	
	collision_body.add_child(collision_shape)
	furniture_node.add_child(collision_body)

func _has_space_for_furniture(furniture_type: String, available_space: Dictionary) -> bool:
	"""Check if there's sufficient space for a furniture item"""
	if not FURNITURE_CATALOG.has(furniture_type):
		return false
	
	var required_area = FURNITURE_CATALOG[furniture_type]["size"].x * FURNITURE_CATALOG[furniture_type]["size"].z
	var clearance_area = FURNITURE_CATALOG[furniture_type]["required_clearance"].x * FURNITURE_CATALOG[furniture_type]["required_clearance"].z
	
	return available_space["usable_area"] >= (required_area + clearance_area)

func _update_available_space(available_space: Dictionary, placed_furniture: Node3D):
	"""Update available space tracking after placing furniture"""
	var furniture_type = placed_furniture.get_meta("furniture_type")
	if FURNITURE_CATALOG.has(furniture_type):
		var furniture_area = FURNITURE_CATALOG[furniture_type]["size"].x * FURNITURE_CATALOG[furniture_type]["size"].z
		available_space["usable_area"] -= furniture_area
