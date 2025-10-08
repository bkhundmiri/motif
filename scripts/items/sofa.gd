extends StaticBody3D
class_name Sofa

## Living room sofa for seating

func _ready():
	print("🛋️ Sofa initialized")

func get_furniture_info() -> Dictionary:
	"""Get information about this furniture piece"""
	return {
		"name": "Sofa",
		"type": "sofa",
		"style": "modern",
		"size": Vector3(2.0, 0.8, 0.9),
		"placement_type": "wall_adjacent"
	}