extends RefCounted
class_name ApartmentRoom

## Individual room within an apartment layout
## Contains boundaries, type classification, and accessibility properties

var name: String
var min_pos: Vector3
var max_pos: Vector3
var room_type: String  # "bathroom", "kitchen", "bedroom", "living", "dining", "closet", "office"
var is_private: bool   # true for bedrooms/bathrooms, false for common areas
var connects_to_entry: bool  # true if accessible from apartment entrance

func _init(room_name: String, minimum_pos: Vector3, maximum_pos: Vector3, type: String, private: bool, entry_connected: bool):
	name = room_name
	min_pos = minimum_pos
	max_pos = maximum_pos
	room_type = type
	is_private = private
	connects_to_entry = entry_connected

func get_center() -> Vector3:
	"""Get the center point of the room"""
	return (min_pos + max_pos) * 0.5

func get_size() -> Vector3:
	"""Get the dimensions of the room"""
	return max_pos - min_pos

func get_area() -> float:
	"""Get the floor area of the room"""
	var size = get_size()
	return size.x * size.z

func contains_point(point: Vector3) -> bool:
	"""Check if a point is within this room"""
	return (point.x >= min_pos.x and point.x <= max_pos.x and 
			point.z >= min_pos.z and point.z <= max_pos.z)

func overlaps_with(other_room: ApartmentRoom) -> bool:
	"""Check if this room overlaps with another room"""
	return not (max_pos.x <= other_room.min_pos.x or 
				min_pos.x >= other_room.max_pos.x or
				max_pos.z <= other_room.min_pos.z or 
				min_pos.z >= other_room.max_pos.z)

func get_wall_length(wall_direction: String) -> float:
	"""Get the length of a specific wall"""
	match wall_direction.to_lower():
		"north", "south":
			return max_pos.x - min_pos.x
		"east", "west":
			return max_pos.z - min_pos.z
		_:
			return 0.0

func _to_string() -> String:
	"""String representation for debugging"""
	return "Room[%s] %s (%s) - Private: %s, Entry: %s, Area: %.1fm²" % [
		room_type, name, min_pos, is_private, connects_to_entry, get_area()
	]