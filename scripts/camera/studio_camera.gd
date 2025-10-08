extends Camera3D
class_name StudioCamera

## Simple camera controller for the studio apartment scene

@export var move_speed: float = 8.0
@export var rotation_speed: float = 2.0
@export var zoom_speed: float = 5.0

var mouse_sensitivity: float = 0.002
var is_rotating: bool = false

func _ready():
	# Position camera initially to get a good view of the apartment
	global_position = Vector3(8, 6, 8)
	look_at(Vector3(4, 1, 3), Vector3.UP)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
			if is_rotating:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1)
	
	elif event is InputEventMouseMotion and is_rotating:
		_rotate_camera(event.relative)
	
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			is_rotating = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	"""Handle WASD movement"""
	var movement = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		movement -= global_transform.basis.z
	if Input.is_action_pressed("move_backward"):
		movement += global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		movement -= global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		movement += global_transform.basis.x
	if Input.is_action_pressed("move_up"):
		movement += Vector3.UP
	if Input.is_action_pressed("move_down"):
		movement -= Vector3.UP
	
	if movement.length() > 0:
		movement = movement.normalized() * move_speed * delta
		global_position += movement

func _rotate_camera(mouse_delta: Vector2):
	"""Rotate camera with mouse"""
	# Rotate around Y axis (horizontal movement)
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	
	# Rotate around local X axis (vertical movement)
	var x_rotation = -mouse_delta.y * mouse_sensitivity
	var camera_transform = global_transform
	camera_transform = camera_transform.rotated_local(Vector3.RIGHT, x_rotation)
	
	# Clamp vertical rotation
	var forward = -camera_transform.basis.z
	var up_dot = forward.dot(Vector3.UP)
	if up_dot > 0.95 or up_dot < -0.95:
		return  # Don't allow flipping
	
	global_transform = camera_transform

func _zoom(direction: int):
	"""Zoom camera by moving forward/backward"""
	var zoom_amount = direction * zoom_speed * 0.5
	global_position += global_transform.basis.z * zoom_amount

func focus_on_apartment():
	"""Reset camera to focus on the apartment"""
	global_position = Vector3(8, 6, 8)
	look_at(Vector3(4, 1, 3), Vector3.UP)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE