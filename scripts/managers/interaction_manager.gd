extends Node
class_name InteractionManager

## Singleton manager for interaction prompts
## Handles showing/hiding interaction hints across the game

# Reference to the prompt UI
var interaction_prompt
var current_interactable: Node = null

func _ready():
	# Set as autoload singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create the interaction prompt UI
	_create_prompt_ui()

func _create_prompt_ui():
	"""Create and add the interaction prompt to the scene tree"""
	var prompt_scene = load("res://scenes/ui/interaction_prompt.tscn")
	interaction_prompt = prompt_scene.instantiate()
	
	# Add to a CanvasLayer so it appears above everything
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to appear on top
	add_child(canvas_layer)
	canvas_layer.add_child(interaction_prompt)

func show_interaction_prompt(text: String, interactable: Node = null):
	"""Show an interaction prompt with the given text"""
	if interaction_prompt:
		current_interactable = interactable
		interaction_prompt.show_prompt(text)

func hide_interaction_prompt(interactable: Node = null):
	"""Hide the interaction prompt"""
	# Only hide if this interactable is the current one (prevents conflicts)
	if interaction_prompt and (interactable == null or current_interactable == interactable):
		current_interactable = null
		interaction_prompt.hide_prompt()

func update_interaction_text(text: String):
	"""Update the prompt text without hiding/showing"""
	if interaction_prompt:
		interaction_prompt.update_text(text)

func is_prompt_visible() -> bool:
	"""Check if an interaction prompt is currently visible"""
	return interaction_prompt != null and interaction_prompt.prompt_visible
