extends Node

# ApartmentRoomUI - Global autoload for apartment room UI management
# This provides global access to apartment room functionality and UI helpers

signal room_selected(room_data)
signal layout_changed(layout_data)

var current_layout = null
var selected_room = null

func _ready():
	print("ApartmentRoomUI autoload initialized")

# Helper function to create room UI representations
func create_room_ui_data(room_name: String, min_pos: Vector3, max_pos: Vector3, 
                        room_type: String, is_private: bool, entry_accessible: bool) -> Dictionary:
	return {
		"name": room_name,
		"min_pos": min_pos,
		"max_pos": max_pos,
		"room_type": room_type,
		"is_private": is_private,
		"entry_accessible": entry_accessible,
		"size": max_pos - min_pos,
		"center": (min_pos + max_pos) / 2.0,
		"area": (max_pos.x - min_pos.x) * (max_pos.z - min_pos.z)
	}

# Global room selection management
func select_room(room_data):
	selected_room = room_data
	room_selected.emit(room_data)
	print("Room selected: ", room_data.name if room_data else "None")

func get_selected_room():
	return selected_room

# Layout management
func set_current_layout(layout_data):
	current_layout = layout_data
	layout_changed.emit(layout_data)
	print("Layout changed to: ", layout_data.layout_type if layout_data else "None")

func get_current_layout():
	return current_layout

# UI utility functions
func format_room_info(room_data) -> String:
	if not room_data:
		return "No room selected"
	
	var info = "Room: %s\n" % room_data.name
	info += "Type: %s\n" % room_data.room_type
	info += "Size: %.1f x %.1f\n" % [room_data.size.x, room_data.size.z]
	info += "Area: %.1f sq units\n" % room_data.area
	info += "Private: %s\n" % ("Yes" if room_data.is_private else "No")
	info += "Entry Access: %s" % ("Yes" if room_data.entry_accessible else "No")
	
	return info

# Room validation helpers
func validate_room_placement(room_data, layout_rooms: Array) -> Dictionary:
	var validation = {
		"valid": true,
		"warnings": [],
		"errors": []
	}
	
	if not room_data:
		validation.valid = false
		validation.errors.append("No room data provided")
		return validation
	
	# Check for overlaps with other rooms
	for other_room in layout_rooms:
		if other_room == room_data:
			continue
		
		if _rooms_overlap(room_data, other_room):
			validation.valid = false
			validation.errors.append("Room overlaps with: " + other_room.name)
	
	# Check minimum size requirements
	if room_data.area < 4.0:  # Minimum 2x2 room
		validation.warnings.append("Room is very small (< 4 sq units)")
	
	return validation

func _rooms_overlap(room1, room2) -> bool:
	return not (room1.max_pos.x <= room2.min_pos.x or 
	           room1.min_pos.x >= room2.max_pos.x or
	           room1.max_pos.z <= room2.min_pos.z or
	           room1.min_pos.z >= room2.max_pos.z)