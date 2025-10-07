extends CharacterBody3D
class_name FirstPersonController

## First Person Controller for Motif Detective Game
## Handles movement, camera rotation, and basic interactions

# Movement properties
@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera properties
@export var camera_min_angle: float = -80.0
@export var camera_max_angle: float = 80.0

# Internal variables
var current_speed: float
var camera_rotation_x: float = 0.0

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

# UI references
var esc_menu: EscMenu

# Manager references
var game_manager

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Add player to group for interaction detection
	add_to_group("player")
	
	# Get game manager reference
	game_manager = get_node("/root/GameManagerUI")
	
	# Create and setup ESC menu
	_setup_esc_menu()
	
	# Capture mouse cursor for first-person experience
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set initial camera position
	if camera_pivot:
		camera_pivot.position = Vector3.ZERO

func _setup_esc_menu():
	"""Create and setup the ESC menu overlay"""
	esc_menu = preload("res://scripts/ui/esc_menu.gd").new()
	
	# Add to the scene tree at a high level (so it appears over everything)
	get_tree().current_scene.add_child.call_deferred(esc_menu)
	esc_menu.z_index = 1000  # Ensure it's on top

func _input(event):
	# Block input when UI is open (except escape key)
	if game_manager and game_manager.ui_open:
		# Only allow escape key when UI is open
		if event.is_action_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	# Handle mouse movement for camera rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate player body horizontally (Y-axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically (X-axis) with constraints
		camera_rotation_x -= event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(camera_min_angle), deg_to_rad(camera_max_angle))
		
		if camera_pivot:
			camera_pivot.rotation.x = camera_rotation_x

func _unhandled_input(event):
	"""Handle ESC key only when no other UI has handled it, and other unhandled input"""
	# Handle ESC key for game menu (only when no UI is open and no other UI handled it)
	if event.is_action_pressed("ui_cancel"):
		if not (game_manager and game_manager.ui_open):
			if esc_menu and is_instance_valid(esc_menu):
				esc_menu.open_menu()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Show cursor for menu
				get_viewport().set_input_as_handled()  # Mark as handled
		return
	
	# Block interaction input when UI is open
	if game_manager and game_manager.ui_open:
		return
	
	# Additional input handling for detective-specific actions
	if event.is_action_pressed("interact"):
		interact_with_object()
	
	if event.is_action_pressed("inventory"):
		toggle_inventory()

func _physics_process(delta):
	# Block movement when UI is open
	if game_manager and game_manager.ui_open:
		# Stop all movement when UI is open
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		# Still apply gravity
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle movement speed (walk/run)
	if Input.is_action_pressed("run"):
		current_speed = run_speed
	else:
		current_speed = walk_speed
	
	# Get input direction for movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	# Move the character
	move_and_slide()

func interact_with_object():
	# Placeholder for interaction system
	# Will be expanded for examining clues, evidence, etc.
	print("Interaction detected - ready for clue examination system")

func toggle_inventory():
	# Placeholder for inventory system
	# Will be expanded for case files, evidence management
	print("Inventory toggled - ready for evidence management system")