extends Camera3D
class_name FreeLookCamera

## Free Look Camera for inspecting generated city

@export var move_speed: float = 50.0
@export var look_sensitivity: float = 0.003
@export var zoom_speed: float = 10.0

var is_rotating: bool = false
var rotation_x: float = 0.0

func _ready():
	# Position camera for apartment building inspection (close to origin)
	# The initial position is set in the scene file, so we don't override here
	pass

func _input(event):
	# Handle mouse rotation
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			if is_rotating:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	elif event is InputEventMouseMotion and is_rotating:
		# Rotate camera
		rotate_y(-event.relative.x * look_sensitivity)
		rotation_x -= event.relative.y * look_sensitivity
		rotation_x = clamp(rotation_x, -PI/2, PI/2)
		rotation.x = rotation_x
	
	# Handle zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			translate_object_local(Vector3(0, 0, -zoom_speed))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			translate_object_local(Vector3(0, 0, zoom_speed))

func _physics_process(delta):
	# Handle movement
	var input_vector = Vector3()
	
	# Forward/backward
	if Input.is_action_pressed("move_forward"):
		input_vector -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_vector += transform.basis.z
	
	# Left/right
	if Input.is_action_pressed("move_left"):
		input_vector -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_vector += transform.basis.x
	
	# Up/down
	if Input.is_action_pressed("move_up"):  # Space key
		input_vector += Vector3.UP
	if Input.is_action_pressed("move_down"):  # Shift key for down
		input_vector -= Vector3.UP
	
	# Apply movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		position += input_vector * move_speed * delta