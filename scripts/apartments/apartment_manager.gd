extends Node

## Apartment Manager Singleton
## Manages apartment scene navigation and shared state

var selector_scene: Control = null
var current_apartment_type: String = ""
var current_apartment_data: Dictionary = {}

func return_to_selector():
	"""Return to apartment selector from any apartment scene"""
	print("Returning to apartment selector")
	get_tree().change_scene_to_file("res://scenes/apartments/apartment_selector.tscn")

func load_apartment_scene(apartment_key: String, apartment_data: Dictionary):
	"""Load a specific apartment scene with data"""
	current_apartment_type = apartment_key
	current_apartment_data = apartment_data
	print("Loading apartment scene: %s" % apartment_key)