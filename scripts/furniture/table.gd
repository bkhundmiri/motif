extends FurnitureItem
class_name TableFurniture

## Table furniture item with specific table functionality

func _ready():
	# Set table-specific properties
	furniture_type = "table"
	placement_rules = ["center_room", "against_wall"]
	
	# Call parent setup
	super._ready()

func investigate_furniture():
	"""Table-specific investigation for detective gameplay"""
	print("Examining table surface and drawers...")
	# Could find:
	# - Documents left on surface
	# - Stains or residue
	# - Hidden compartments
	# - Scratches or damage
	# - Items in drawers
	
	var evidence_found = _check_table_evidence()
	if evidence_found.size() > 0:
		print("Evidence found on/in table: %s" % evidence_found)
	else:
		print("No evidence found on this table")

func _check_table_evidence() -> Array:
	"""Check for evidence on table surface or in drawers"""
	var possible_evidence = []
	
	# Check surface
	if randf() < 0.25:  # 25% chance
		var surface_evidence = ["document", "stain", "fingerprints", "scratch_marks"]
		possible_evidence.append(surface_evidence[randi() % surface_evidence.size()])
	
	# Check drawers (if has drawers)
	if has_drawers() and randf() < 0.20:  # 20% chance
		var drawer_evidence = ["hidden_key", "receipt", "photo", "letter"]
		possible_evidence.append(drawer_evidence[randi() % drawer_evidence.size()])
	
	return possible_evidence

func has_drawers() -> bool:
	"""Check if this table type has drawers"""
	return furniture_id.begins_with("office_desk") or "drawer" in furniture_id

func can_place_at(_check_position: Vector3, check_room_type: String) -> bool:
	"""Tables can be placed in most rooms"""
	var restricted_rooms = ["bathroom", "closet"]
	return not check_room_type in restricted_rooms

func get_surface_area() -> float:
	"""Get usable surface area for placing items"""
	# Calculate based on table size
	return item_size.x * item_size.z * 0.8  # 80% of total area is usable

func can_seat_people() -> int:
	"""Return how many people can sit at this table"""
	match furniture_id:
		"dining_table_small":
			return 2
		"dining_table_large":
			return 6
		"coffee_table":
			return 0  # Not for seating
		"office_desk":
			return 1
		_:
			return 2  # Default for most tables