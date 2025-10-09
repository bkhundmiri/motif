extends FurnitureItem
class_name BedFurniture

## Bed furniture item with specific bed functionality and sleep interaction

@export var interaction_distance: float = 3.0

# Sleep functionality
var player_in_range: bool = false
var interaction_area: Area3D
var game_manager: GameManager

func _ready():
	# Set bed-specific properties
	furniture_type = "bed"
	placement_rules = ["against_wall", "center_room"]
	room_type = "bedroom"
	
	# Get game manager reference if it exists
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	else:
		print("GameManager not found - running in test environment")
		game_manager = null
	
	# Set up sleep interaction area
	_setup_sleep_interaction()
	
	# Call parent setup
	super._ready()

func _setup_sleep_interaction():
	"""Set up Area3D for sleep interaction detection"""
	# Check if there's already an InteractionArea node in the scene
	if has_node("InteractionArea"):
		interaction_area = $InteractionArea
		print("Using existing InteractionArea for sleep interaction")
	else:
		# Create interaction area for sleep functionality
		interaction_area = Area3D.new()
		interaction_area.name = "InteractionArea"
		add_child(interaction_area)
		
		# Create collision shape for interaction area
		var interaction_collision = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = interaction_distance
		interaction_collision.shape = sphere_shape
		interaction_area.add_child(interaction_collision)
		print("Created new InteractionArea for sleep interaction")
	
	# Connect area signals
	interaction_area.body_entered.connect(_on_player_entered_area)
	interaction_area.body_exited.connect(_on_player_exited_area)

func _on_player_entered_area(body):
	"""Called when player enters interaction area"""
	if body.has_method("is_player") and body.is_player():
		player_in_range = true
		_show_interaction_prompt()

func _on_player_exited_area(body):
	"""Called when player exits interaction area"""
	if body.has_method("is_player") and body.is_player():
		player_in_range = false
		_hide_interaction_prompt()

func _input(event):
	"""Handle input for sleep interaction"""
	if player_in_range and event.is_action_pressed("interact"):
		interact()

func _show_interaction_prompt():
	"""Show sleep interaction prompt"""
	if game_manager and game_manager.has_method("show_interaction_prompt"):
		game_manager.show_interaction_prompt("Press E to sleep")

func _hide_interaction_prompt():
	"""Hide sleep interaction prompt"""
	if game_manager and game_manager.has_method("hide_interaction_prompt"):
		game_manager.hide_interaction_prompt()

func interact():
	"""Handle sleep interaction"""
	if not player_in_range:
		return
	
	print("Player wants to sleep")
	_hide_interaction_prompt()
	_open_sleep_dialog()

func _open_sleep_dialog():
	"""Open the sleep dialog"""
	if not game_manager:
		print("No game manager found!")
		return
	
	# Pause the game and show cursor
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Load and show sleep dialog
	var sleep_dialog_scene = preload("res://scenes/ui/sleep_dialog.tscn")
	var sleep_dialog = sleep_dialog_scene.instantiate()
	
	# Add to tree and connect signals
	get_tree().current_scene.add_child(sleep_dialog)
	
	# Connect dialog signals
	if sleep_dialog.has_signal("sleep_confirmed"):
		sleep_dialog.sleep_confirmed.connect(_on_sleep_confirmed)
	if sleep_dialog.has_signal("dialog_closed"):
		sleep_dialog.dialog_closed.connect(_on_sleep_dialog_closed)

func _on_sleep_confirmed(hours: int):
	"""Handle sleep confirmation from dialog"""
	print("Sleeping for %d hours" % hours)
	
	# Advance time through game manager
	if game_manager and game_manager.has_method("advance_time"):
		game_manager.advance_time(hours)
	
	# Resume normal gameplay
	_resume_game()

func _on_sleep_dialog_closed():
	"""Handle sleep dialog being closed without sleeping"""
	print("Sleep dialog closed")
	_resume_game()

func _resume_game():
	"""Resume normal gameplay after sleep dialog"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Show interaction prompt again if player still in range
	if player_in_range:
		_show_interaction_prompt()

func investigate_furniture():
	"""Bed-specific investigation for detective gameplay"""
	print("Examining bed for evidence...")
	# Could find:
	# - Hair samples
	# - Fabric fibers
	# - Hidden items under mattress
	# - Signs of struggle
	# - Personal belongings
	
	# Example evidence discovery
	var evidence_found = _check_for_evidence()
	if evidence_found.size() > 0:
		print("Evidence found in bed: %s" % evidence_found)
	else:
		print("No evidence found in this bed")

func _check_for_evidence() -> Array:
	"""Check for crime scene evidence in/around bed"""
	var possible_evidence = []
	
	# Random chance for evidence (this would be more sophisticated in actual game)
	if randf() < 0.3:  # 30% chance
		var evidence_types = ["hair_sample", "fabric_fiber", "hidden_note", "jewelry"]
		possible_evidence.append(evidence_types[randi() % evidence_types.size()])
	
	return possible_evidence

func can_place_at(_check_position: Vector3, check_room_type: String) -> bool:
	"""Beds can only be placed in bedrooms and studios"""
	var valid_rooms = ["bedroom", "studio", "master_bedroom", "guest_bedroom"]
	return check_room_type in valid_rooms

func get_sleep_quality() -> String:
	"""Return sleep quality based on luxury level (for NPC behavior)"""
	match luxury_level:
		"luxury":
			return "excellent"
		"standard":
			return "good"
		_:
			return "basic"
