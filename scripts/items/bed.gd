extends StaticBody3D
class_name Bed

## Bed entity that can be interacted with to sleep

@export var interaction_distance: float = 2.0

# Node references
var game_manager
var interaction_manager
var player
var sleep_dialog

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
		interaction_manager.show_interaction_prompt("Press E to Sleep", self)

func _hide_interaction_prompt():
	"""Hide interaction prompt"""
	if interaction_manager:
		interaction_manager.hide_interaction_prompt(self)

func _input(event):
	"""Handle interaction input"""
	if event.is_action_pressed("interact") and player_in_range:
		interact()

func interact():
	"""Handle bed interaction - open sleep dialog"""
	if sleep_dialog:
		return  # Dialog already open
	
	# Hide the interaction prompt
	_hide_interaction_prompt()
	
	_open_sleep_dialog()

func _open_sleep_dialog():
	"""Open the sleep dialog UI"""
	# Pause the game clock
	if game_manager:
		game_manager.open_ui()
	
	# Create and show sleep dialog
	var sleep_dialog_scene = load("res://scenes/ui/sleep_dialog.tscn")
	sleep_dialog = sleep_dialog_scene.instantiate()
	get_tree().current_scene.add_child(sleep_dialog)
	
	# Connect to dialog signals
	sleep_dialog.connect("sleep_confirmed", _on_sleep_confirmed)
	sleep_dialog.connect("dialog_closed", _on_dialog_closed)
	
	# Capture mouse for dialog interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_sleep_confirmed(hours: float):
	"""Called when player confirms sleep duration"""
	print("Sleeping for %.1f hours" % hours)
	
	# Close dialog first
	_close_dialog()
	
	# Start sleep sequence with fast-forward effect
	if game_manager:
		game_manager.sleep_with_duration(hours)

func _on_dialog_closed():
	"""Called when dialog is closed without sleeping"""
	_close_dialog()

func _close_dialog():
	"""Clean up and close the sleep dialog"""
	if sleep_dialog:
		sleep_dialog.queue_free()
		sleep_dialog = null
	
	# Resume game clock
	if game_manager:
		game_manager.close_ui()
	
	# Return mouse control to player
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Show interaction prompt again if player is still in range
	if player_in_range:
		_show_interaction_prompt()
