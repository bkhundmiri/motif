extends StaticBody3D
class_name CaseBoard

## Case Board entity for detective investigation
## Interactive whiteboard for organizing case evidence and connections

@export var interaction_distance: float = 2.5

# Node references
var game_manager
var interaction_manager
var player
var case_board_ui

# Interaction state
var player_in_range: bool = false

func _ready():
	# Get manager references
	game_manager = get_node("/root/GameManagerUI")
	interaction_manager = get_node("/root/InteractionManagerUI")
	
	# Set up interaction area
	_setup_interaction()

func _setup_interaction():
	"""Set up the interaction detection area"""
	# Create an Area3D for interaction detection
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
		player = body
		_show_interaction_prompt()

func _on_body_exited(body):
	"""Called when player exits interaction range"""
	if body == player:
		player_in_range = false
		player = null
		_hide_interaction_prompt()

func _show_interaction_prompt():
	"""Show interaction prompt to player"""
	if interaction_manager:
		interaction_manager.show_interaction_prompt("Press E to Use Case Board", self)

func _hide_interaction_prompt():
	"""Hide interaction prompt"""
	if interaction_manager:
		interaction_manager.hide_interaction_prompt(self)

func _input(event):
	"""Handle interaction input"""
	if event.is_action_pressed("interact") and player_in_range:
		interact()

func interact():
	"""Handle case board interaction - open case board UI"""
	if case_board_ui:
		return  # Case board already open
	
	# Hide the interaction prompt
	_hide_interaction_prompt()
	
	_open_case_board()

func _open_case_board():
	"""Open the case board UI"""
	# Pause the game clock
	if game_manager:
		game_manager.open_ui()
	
	# Create and show case board UI
	var case_board_scene = load("res://scenes/ui/case_board_ui.tscn")
	case_board_ui = case_board_scene.instantiate()
	get_tree().current_scene.add_child(case_board_ui)
	
	# Connect to case board signals
	case_board_ui.connect("case_board_closed", _on_case_board_closed)
	
	# Capture mouse for case board interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_case_board_closed():
	"""Called when case board is closed"""
	_close_case_board()

func _close_case_board():
	"""Clean up and close the case board"""
	if case_board_ui:
		case_board_ui.queue_free()
		case_board_ui = null
	
	# Resume game clock
	if game_manager:
		game_manager.close_ui()
	
	# Return mouse control to player
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Show interaction prompt again if player is still in range
	if player_in_range:
		_show_interaction_prompt()