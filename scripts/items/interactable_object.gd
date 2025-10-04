extends StaticBody3D
class_name InteractableObject

## Base class for all interactable objects in the game
## Provides common interaction functionality

@export var interaction_distance: float = 2.0
@export var interaction_text: String = "Press E to Interact"

# Node references
var game_manager
var interaction_manager
var player

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
		interaction_manager.show_interaction_prompt(interaction_text, self)

func _hide_interaction_prompt():
	"""Hide interaction prompt"""
	if interaction_manager:
		interaction_manager.hide_interaction_prompt(self)

func _input(event):
	"""Handle interaction input"""
	if event.is_action_pressed("interact") and player_in_range:
		interact()

# Override this method in child classes
func interact():
	"""Handle interaction - override in child classes"""
	print("Interacted with %s" % name)
