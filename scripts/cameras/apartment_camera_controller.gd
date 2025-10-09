extends Node3D
class_name ApartmentCameraController

## Free-flying camera controller for inspecting apartments

@export var movement_speed: float = 5.0
@export var fast_speed_multiplier: float = 3.0
@export var slow_speed_multiplier: float = 0.3
@export var mouse_sensitivity: float = 0.002

var camera: Camera3D
var apartment_generator  # Will be ApartmentGenerator once it's available

# Camera rotation
var yaw: float = 0.0
var pitch: float = 0.0

func _ready():
	# Get camera reference
	camera = $Camera3D
	
	# Get apartment generator reference (optional for testing)
	if has_node("../ApartmentGenerator"):
		apartment_generator = get_node("../ApartmentGenerator")
	else:
		apartment_generator = null
		print("No ApartmentGenerator found - running in standalone mode")
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set initial position to overlook the apartment
	global_position = Vector3(5, 3, 5)
	look_at_apartment_center()

func _input(event):
	"""Handle input events"""
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)
	
	elif event.is_action_pressed("ui_cancel"):  # ESC key
		# In apartment testing mode, don't handle ESC here - let the apartment unit handle it
		# Toggle mouse capture only if we're not in an apartment scene
		var current_scene_path = get_tree().current_scene.scene_file_path
		if not "/apartments/" in current_scene_path:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:  # R key
		if apartment_generator:
			apartment_generator.regenerate_apartment()
			await get_tree().process_frame
			look_at_apartment_center()
		else:
			print("R key pressed - No apartment generator available")
	
	elif event is InputEventKey and event.pressed and event.keycode == KEY_L:  # L key
		if apartment_generator:
			# Toggle debug labels
			apartment_generator.show_debug_labels = !apartment_generator.show_debug_labels
			apartment_generator.toggle_debug_labels(apartment_generator.show_debug_labels)
			print("Debug labels: %s" % ("ON" if apartment_generator.show_debug_labels else "OFF"))
		else:
			print("L key pressed - No apartment generator available")
	
	elif event is InputEventKey and event.pressed and event.keycode == KEY_V:  # V key
		if apartment_generator:
			apartment_generator.regenerate_with_new_variant()
			await get_tree().process_frame
			look_at_apartment_center()

func _process(delta):
	"""Handle continuous input and movement"""
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_movement(delta)

func _handle_mouse_look(event: InputEventMouseMotion):
	"""Handle mouse look rotation"""
	yaw -= event.relative.x * mouse_sensitivity
	pitch -= event.relative.y * mouse_sensitivity
	
	# Clamp pitch to prevent over-rotation
	pitch = clamp(pitch, -PI/2, PI/2)
	
	# Apply rotation
	rotation.y = yaw
	rotation.x = pitch

func _handle_movement(delta: float):
	"""Handle WASD movement"""
	var input_vector = Vector3()
	
	# Get movement input using direct key checks to avoid InputMap issues
	if Input.is_key_pressed(KEY_W):  # Move forward
		input_vector -= transform.basis.z
	if Input.is_key_pressed(KEY_S):  # Move backward
		input_vector += transform.basis.z
	if Input.is_key_pressed(KEY_A):  # Move left
		input_vector -= transform.basis.x
	if Input.is_key_pressed(KEY_D):  # Move right
		input_vector += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE):  # Move up
		input_vector += Vector3.UP
	if Input.is_key_pressed(KEY_C):  # Move down
		input_vector -= Vector3.UP
	
	# Normalize and apply speed
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		
		var current_speed = movement_speed
		
		# Speed modifiers using direct key checks
		if Input.is_key_pressed(KEY_SHIFT):  # Move fast
			current_speed *= fast_speed_multiplier
		elif Input.is_key_pressed(KEY_CTRL):  # Move slow
			current_speed *= slow_speed_multiplier
		
		# Apply movement
		global_position += input_vector * current_speed * delta

func look_at_apartment_center():
	"""Point camera toward the center of the generated apartment"""
	if not apartment_generator:
		# In standalone mode, look at the center of the apartment space
		var apartment_center = Vector3(0, 1.5, 0)  # Eye level at apartment center
		look_at(apartment_center, Vector3.UP)
		
		# Extract yaw and pitch from the new rotation
		yaw = rotation.y
		pitch = rotation.x
		return
	
	if apartment_generator.generated_rooms.is_empty():
		return
	
	# Calculate apartment bounds
	var apartment_center = Vector3.ZERO
	var room_count = 0
	
	for room in apartment_generator.generated_rooms:
		if is_instance_valid(room):
			apartment_center += room.global_position
			room_count += 1
	
	if room_count > 0:
		apartment_center /= room_count
		apartment_center.y = 1.5  # Eye level
		
		# Look at the center
		look_at(apartment_center, Vector3.UP)
		
		# Extract yaw and pitch from the new rotation
		yaw = rotation.y
		pitch = rotation.x
