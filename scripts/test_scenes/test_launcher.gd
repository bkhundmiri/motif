extends Node3D

# Quick test launcher
# Use this to easily switch between different test scenes

@onready var ui_panel: Control = $UI
@onready var apartment_test_button: Button = $UI/Panel/VBoxContainer/ApartmentTestButton
@onready var building_test_button: Button = $UI/Panel/VBoxContainer/BuildingTestButton
@onready var layouts_test_button: Button = $UI/Panel/VBoxContainer/LayoutsTestButton
@onready var city_test_button: Button = $UI/Panel/VBoxContainer/CityTestButton

func _ready():
	print("TestLauncher initialized")
	
	# Connect buttons
	apartment_test_button.pressed.connect(_load_apartment_test)
	building_test_button.pressed.connect(_load_building_test)
	layouts_test_button.pressed.connect(_load_layouts_test)
	city_test_button.pressed.connect(_load_city_test)

func _load_apartment_test():
	print("Loading apartment test scene...")
	get_tree().change_scene_to_file("res://scenes/environments/apartment.tscn")

func _load_building_test():
	print("Loading building test scene...")
	get_tree().change_scene_to_file("res://scenes/apartment_building_test.tscn")

func _load_layouts_test():
	print("Loading apartment layouts test scene...")
	get_tree().change_scene_to_file("res://scenes/test_scenes/apartment_layouts_test.tscn")

func _load_city_test():
	print("Loading city generation test scene...")
	get_tree().change_scene_to_file("res://scenes/city_generation_test.tscn")