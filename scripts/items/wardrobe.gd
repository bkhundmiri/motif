extends StaticBody3D
class_name Wardrobe

## Modern wardrobe/closet for storing clothing items

@export var interaction_distance: float = 2.0
@export var storage_capacity: int = 20

# Node references
var game_manager
var interaction_manager
var player

# State
var is_open: bool = false
var stored_items: Array = []
var player_in_range: bool = false

func _ready():
	# Get manager references
	game_manager = get_node("/root/GameManagerUI")
	interaction_manager = get_node("/root/InteractionManagerUI")
	
	# Set up interaction area
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
		player = body
		_show_interaction_prompt()

func _on_body_exited(body):
	"""Called when player exits interaction range"""
	if body == player:
		player_in_range = false
		player = null
		_hide_interaction_prompt()

func _show_interaction_prompt():
	"""Show interaction UI prompt"""
	if interaction_manager:
		interaction_manager.show_prompt("Open Wardrobe", "E")

func _hide_interaction_prompt():
	"""Hide interaction UI prompt"""
	if interaction_manager:
		interaction_manager.hide_prompt()

func _input(event):
	"""Handle player input for interaction"""
	if not player_in_range:
		return
		
	if event.is_action_pressed("interact"):
		_interact()

func _interact():
	"""Handle wardrobe interaction"""
	if is_open:
		_close_wardrobe()
	else:
		_open_wardrobe()

func _open_wardrobe():
	"""Open the wardrobe"""
	is_open = true
	print("🚪 Wardrobe opened")
	# TODO: Show storage interface
	_animate_doors_open()

func _close_wardrobe():
	"""Close the wardrobe"""
	is_open = false
	print("🚪 Wardrobe closed")
	_animate_doors_close()

func _animate_doors_open():
	"""Animate wardrobe doors opening"""
	# Simple rotation animation for door effect
	var tween = create_tween()
	var door_line = get_node("DoorLine")
	if door_line:
		tween.tween_property(door_line, "rotation_degrees:y", 45, 0.3)

func _animate_doors_close():
	"""Animate wardrobe doors closing"""
	var tween = create_tween()
	var door_line = get_node("DoorLine")
	if door_line:
		tween.tween_property(door_line, "rotation_degrees:y", 0, 0.3)

func add_item(item_name: String) -> bool:
	"""Add an item to the wardrobe storage"""
	if stored_items.size() >= storage_capacity:
		print("⚠️ Wardrobe is full!")
		return false
	
	stored_items.append(item_name)
	print("📦 Added %s to wardrobe" % item_name)
	return true

func remove_item(item_name: String) -> bool:
	"""Remove an item from the wardrobe storage"""
	var index = stored_items.find(item_name)
	if index >= 0:
		stored_items.remove_at(index)
		print("📤 Removed %s from wardrobe" % item_name)
		return true
	
	print("❌ Item %s not found in wardrobe" % item_name)
	return false

func get_storage_info() -> Dictionary:
	"""Get information about wardrobe storage"""
	return {
		"capacity": storage_capacity,
		"used": stored_items.size(),
		"available": storage_capacity - stored_items.size(),
		"items": stored_items.duplicate()
	}