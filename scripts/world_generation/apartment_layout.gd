extends RefCounted
class_name ApartmentLayout

## Container for apartment room collection with entry zone definition
## Represents the complete layout structure of an apartment

var layout_type: String  # "studio", "one_bedroom", "two_bedroom", "penthouse"
var rooms: Array = []  # Array of ApartmentRoom objects
var entry_zone: Vector3  # Position and size of entry area
var corridors: Array = []  # Optional corridor definitions

func _init(type: String):
	layout_type = type

func add_room(room):  # ApartmentRoom type
	"""Add a room to this layout"""
	rooms.append(room)

func get_room_by_type(room_type: String):  # Returns ApartmentRoom or null
	"""Get the first room of a specific type"""
	for room in rooms:
		if room.room_type == room_type:
			return room
	return null

func get_rooms_by_type(room_type: String) -> Array:  # Array of ApartmentRoom
	"""Get all rooms of a specific type"""
	var matching_rooms = []
	for room in rooms:
		if room.room_type == room_type:
			matching_rooms.append(room)
	return matching_rooms

func get_total_area() -> float:
	"""Calculate total floor area of all rooms"""
	var total = 0.0
	for room in rooms:
		total += room.get_area()
	return total

func get_private_rooms() -> Array:  # Array of ApartmentRoom
	"""Get all private rooms (bedrooms, bathrooms)"""
	var private_rooms = []
	for room in rooms:
		if room.is_private:
			private_rooms.append(room)
	return private_rooms

func get_common_rooms() -> Array:  # Array of ApartmentRoom
	"""Get all common/public rooms (living, kitchen, dining)"""
	var common_rooms = []
	for room in rooms:
		if not room.is_private:
			common_rooms.append(room)
	return common_rooms

func get_entry_accessible_rooms() -> Array:  # Array of ApartmentRoom
	"""Get all rooms accessible from the entry"""
	var accessible_rooms = []
	for room in rooms:
		if room.connects_to_entry:
			accessible_rooms.append(room)
	return accessible_rooms

func validate_layout() -> bool:
	"""Validate the layout for architectural correctness"""
	var issues = []
	
	# Check for room overlaps
	for i in range(rooms.size()):
		for j in range(i + 1, rooms.size()):
			if rooms[i].overlaps_with(rooms[j]):
				issues.append("Rooms overlap: %s and %s" % [rooms[i].name, rooms[j].name])
	
	# Check entry accessibility
	var entry_accessible = get_entry_accessible_rooms()
	if entry_accessible.is_empty():
		issues.append("No rooms accessible from entry")
	
	# Check for private rooms at entry
	for room in entry_accessible:
		if room.is_private:
			issues.append("Private room (%s) at entry - bad flow" % room.name)
	
	if not issues.is_empty():
		print("Layout validation issues:")
		for issue in issues:
			print("  ⚠️  %s" % issue)
		return false
	
	return true

func get_bounds() -> Dictionary:
	"""Get the overall bounds of the entire layout"""
	if rooms.is_empty():
		return {"min": Vector3.ZERO, "max": Vector3.ZERO}
	
	var min_pos = rooms[0].min_pos
	var max_pos = rooms[0].max_pos
	
	for room in rooms:
		min_pos.x = min(min_pos.x, room.min_pos.x)
		min_pos.z = min(min_pos.z, room.min_pos.z)
		max_pos.x = max(max_pos.x, room.max_pos.x)
		max_pos.z = max(max_pos.z, room.max_pos.z)
	
	return {"min": min_pos, "max": max_pos}

func _to_string() -> String:
	"""String representation for debugging"""
	return "ApartmentLayout[%s] - %d rooms, %.1fm² total" % [
		layout_type, rooms.size(), get_total_area()
	]