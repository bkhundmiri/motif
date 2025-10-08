extends StaticBody3D
class_name Sink

## Bathroom sink fixture

func _ready():
	print("🚿 Sink initialized")

func get_furniture_info() -> Dictionary:
	"""Get information about this furniture piece"""
	return {
		"name": "Sink",
		"type": "sink",
		"style": "modern",
		"size": Vector3(0.5, 0.9, 0.4),
		"placement_type": "wall_adjacent"
	}