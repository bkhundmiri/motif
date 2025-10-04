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

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Add player to group for interaction detection
	add_to_group("player")
	
	# Capture mouse cursor for first-person experience
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set initial camera position
	if camera_pivot:
		camera_pivot.position = Vector3.ZERO

func _input(event):
	# Handle mouse movement for camera rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate player body horizontally (Y-axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically (X-axis) with constraints
		camera_rotation_x -= event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(camera_min_angle), deg_to_rad(camera_max_angle))
		
		if camera_pivot:
			camera_pivot.rotation.x = camera_rotation_x
	
	# Handle escape key to release mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
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

func _unhandled_input(event):
	# Additional input handling for detective-specific actions
	if event.is_action_pressed("interact"):
		interact_with_object()
	
	if event.is_action_pressed("inventory"):
		toggle_inventory()

func interact_with_object():
	# Placeholder for interaction system
	# Will be expanded for examining clues, evidence, etc.
	print("Interaction detected - ready for clue examination system")

func toggle_inventory():
	# Placeholder for inventory system
	# Will be expanded for case files, evidence management
	print("Inventory toggled - ready for evidence management system")