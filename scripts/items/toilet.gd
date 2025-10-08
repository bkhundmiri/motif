extends StaticBody3D
class_name Toilet

## Bathroom toilet fixture

func _ready():
	print("🚽 Toilet initialized")

func get_furniture_info() -> Dictionary:
	"""Get information about this furniture piece"""
	return {
		"name": "Toilet",
		"type": "toilet",
		"style": "modern",
		"size": Vector3(0.4, 0.8, 0.6),
		"placement_type": "wall_adjacent"
	}