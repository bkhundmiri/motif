extends Control
class_name InteractionPrompt

## Reusable interaction prompt with semi-circular shadow overlay
## Shows interaction hints like "Press E to Sleep"

@onready var background: Panel = $Background
@onready var prompt_label: Label = $PromptLabel

# Animation properties
var fade_duration: float = 0.3
var prompt_visible: bool = false

func _ready():
	# Start hidden
	modulate.a = 0.0
	prompt_visible = false
	
	# Set up the semi-circular background
	_setup_background()

func _setup_background():
	"""Configure the semi-circular shadow background"""
	# Position at bottom center of screen using proper anchoring
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	
	# Set responsive size and positioning
	custom_minimum_size = Vector2(300, 80)
	
	# Center horizontally and position at bottom
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	
	# Offset to center the prompt and position it properly at bottom
	offset_left = -150  # Half of width (300/2)
	offset_right = 150   # Half of width (300/2)
	offset_top = -100    # Move up from bottom edge
	offset_bottom = -20  # Small margin from bottom

func show_prompt(text: String):
	"""Show the interaction prompt with text"""
	if prompt_visible:
		return
	
	prompt_label.text = text
	prompt_visible = true
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func hide_prompt():
	"""Hide the interaction prompt"""
	if not prompt_visible:
		return
	
	prompt_visible = false
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)

func update_text(text: String):
	"""Update the prompt text without hiding/showing"""
	prompt_label.text = text
