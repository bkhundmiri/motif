extends FurnitureItem
class_name ChairFurniture

## Chair furniture item with specific seating functionality

func _ready():
	# Set chair-specific properties
	furniture_type = "chair"
	placement_rules = ["desk_pairing", "table_pairing", "against_wall"]
	
	# Call parent setup
	super._ready()

func investigate_furniture():
	"""Chair-specific investigation for detective gameplay"""
	print("Examining chair for evidence...")
	# Could find:
	# - Fabric fibers
	# - Hair samples
	# - Wear patterns (indicating frequent use)
	# - Hidden items in cushions
	# - Damage or stains
	
	var evidence_found = _check_chair_evidence()
	if evidence_found.size() > 0:
		print("Evidence found on chair: %s" % evidence_found)
	else:
		print("No evidence found on this chair")

func _check_chair_evidence() -> Array:
	"""Check for evidence on chair"""
	var possible_evidence = []
	
	# Check seat and back
	if randf() < 0.30:  # 30% chance
		var fabric_evidence = ["hair_sample", "fabric_fiber", "stain", "wear_pattern"]
		possible_evidence.append(fabric_evidence[randi() % fabric_evidence.size()])
	
	# Check cushions (if applicable)
	if has_cushions() and randf() < 0.15:  # 15% chance
		var hidden_items = ["coin", "paper_scrap", "button", "jewelry"]
		possible_evidence.append(hidden_items[randi() % hidden_items.size()])
	
	return possible_evidence

func has_cushions() -> bool:
	"""Check if chair has removable cushions"""
	var cushioned_chairs = ["sofa", "armchair", "luxury"]
	for chair_type in cushioned_chairs:
		if chair_type in furniture_id.to_lower():
			return true
	return false

func can_place_at(_check_position: Vector3, check_room_type: String) -> bool:
	"""Chairs can be placed in most rooms except bathrooms"""
	var restricted_rooms = ["bathroom", "closet"]
	return not check_room_type in restricted_rooms

func is_office_chair() -> bool:
	"""Check if this is an office/desk chair"""
	return "office" in furniture_id or "executive" in furniture_id or "desk" in furniture_id

func get_comfort_level() -> String:
	"""Return comfort level for NPC behavior"""
	if is_office_chair():
		match luxury_level:
			"luxury":
				return "very_comfortable"
			"standard":
				return "comfortable"
			_:
				return "basic"
	else:
		match luxury_level:
			"luxury":
				return "luxurious"
			"standard":
				return "comfortable"
			_:
				return "adequate"

func can_pair_with_furniture(other_furniture: FurnitureItem) -> bool:
	"""Check if this chair can be paired with other furniture"""
	if not other_furniture:
		return false
	
	match other_furniture.furniture_type:
		"table":
			return true
		"desk":
			return is_office_chair()
		_:
			return false