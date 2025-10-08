extends StaticBody3D
class_name CoffeeTable

## Modern coffee table for living room areas

func _ready():
	print("☕ Coffee table initialized")

func get_furniture_info() -> Dictionary:
	"""Get information about this furniture piece"""
	return {
		"name": "Coffee Table",
		"type": "table",
		"style": "modern",
		"size": Vector3(1.2, 0.5, 0.6),
		"placement_type": "center_focus"
	}