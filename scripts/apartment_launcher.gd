extends Control

## Quick launcher for apartment testing
## Add this as the main scene temporarily for testing

func _ready():
	# Connect the button signal
	$CenterContainer/VBoxContainer/LaunchButton.pressed.connect(_launch_apartment_selector)

func _launch_apartment_selector():
	"""Launch the apartment selector scene"""
	print("Launching apartment selector...")
	get_tree().change_scene_to_file("res://scenes/apartments/apartment_selector.tscn")