extends StaticBody3D
class_name Stove

## Kitchen stove appliance

@export var interaction_distance: float = 2.0

# State
var is_on: bool = false
var burners_on: Array[bool] = [false, false, false, false]
var player_in_range: bool = false

func _ready():
	print("🔥 Stove initialized")
	_setup_interaction()

func _setup_interaction():
	"""Set up the interaction detection area"""
	var area = Area3D.new()
	add_child(area)
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = interaction_distance
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	
	# Connect signals
	area.connect("body_entered", _on_body_entered)
	area.connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	"""Called when player enters interaction range"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	"""Called when player exits interaction range"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false

func toggle_burner(burner_index: int):
	"""Toggle a specific burner on/off"""
	if burner_index < 0 or burner_index >= 4:
		return
	
	burners_on[burner_index] = !burners_on[burner_index]
	print("🔥 Burner %d: %s" % [burner_index + 1, "ON" if burners_on[burner_index] else "OFF"])
	
	# Update visual state
	_update_burner_visual(burner_index)

func _update_burner_visual(burner_index: int):
	"""Update the visual state of a burner"""
	var burner_node = get_node("Burners/Burner%d" % (burner_index + 1))
	if burner_node and burner_node is MeshInstance3D:
		var material = burner_node.get_surface_override_material(0)
		if material and material is StandardMaterial3D:
			if burners_on[burner_index]:
				# Glowing red when on
				material.albedo_color = Color(0.8, 0.2, 0.1, 1)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.3, 0.1, 1)
			else:
				# Dark when off
				material.albedo_color = Color(0.05, 0.05, 0.05, 1)
				material.emission_enabled = false

func get_furniture_info() -> Dictionary:
	"""Get information about this furniture piece"""
	return {
		"name": "Stove",
		"type": "stove",
		"style": "modern",
		"size": Vector3(0.6, 0.9, 0.6),
		"placement_type": "wall_adjacent"
	}