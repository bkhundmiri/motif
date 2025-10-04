# res://scenes/world/apartment/Apartment.gd
extends Node3D

const Interactable := preload("res://core/util/Interactable.gd")
const BoardWindow  := preload("res://scenes/ui/apartment/BoardWindow.tscn")
const StashWindow  := preload("res://scenes/ui/apartment/StashWindow.tscn")
const SleepDialog  := preload("res://scenes/ui/sleep_dialog/SleepDialog.tscn")

@onready var player: CharacterBody3D = $Player
@onready var cam: Camera3D           = $Player/Camera3D
@onready var ray: RayCast3D          = $Player/Camera3D/Ray
@onready var prompt_label: Label     = $UI/PromptLabel
@onready var _sleep: ConfirmationDialog = null

var _board: Window
var _stash: Window

var _look_sens: float = 0.08
var _speed: float = 5.0
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _pitch: float = 0.0
var _yaw: float = 0.0
var _focused_last: Node3D = null

func _ready() -> void:
	_ensure_input()

	_board = BoardWindow.instantiate()
	_board.hide()
	_board.close_requested.connect(_on_window_closed)
	add_child(_board)

	_stash = StashWindow.instantiate()
	_stash.hide()
	_stash.close_requested.connect(_on_window_closed)
	add_child(_stash)

	_sleep = SleepDialog.instantiate()
	add_child(_sleep)
	if _sleep:
		_sleep.canceled.connect(_on_window_closed)
		_sleep.confirmed.connect(_on_window_closed)
		_sleep.close_requested.connect(_on_window_closed)

	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	ray.enabled = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	ray.target_position = Vector3(0, 0, -2.5)
	prompt_label.visible = false

func _on_window_closed() -> void:
	# If nothing visible, recapture mouse
	var any_open := false
	if _board and _board.visible: any_open = true
	if _stash and _stash.visible: any_open = true
	if _sleep and _sleep.visible: any_open = true
	if not any_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ensure_input() -> void:
	_ensure_action_with_key("move_forward",  KEY_W)
	_ensure_action_with_key("move_backward", KEY_S)
	_ensure_action_with_key("move_left",     KEY_A)
	_ensure_action_with_key("move_right",    KEY_D)
	_ensure_action_with_key("interact",      KEY_E)

	if not InputMap.has_action("toggle_mouse"):
		InputMap.add_action("toggle_mouse")
	if InputMap.action_get_events("toggle_mouse").is_empty():
		var ev := InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		InputMap.action_add_event("toggle_mouse", ev)

func _ensure_action_with_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		var ev := InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action, ev)

func _input(event: InputEvent) -> void:
	# block look/interaction while UI is up
	if _any_ui_open():
		return
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_rotate_camera(mm.relative)
	elif event.is_action_pressed("toggle_mouse"):
		var mode := Input.get_mouse_mode()
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		)
	elif event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	if _any_ui_open():
		return
	_handle_move(delta)
	_update_prompt()

func _rotate_camera(rel: Vector2) -> void:
	_yaw   -= rel.x * _look_sens * 0.01
	_pitch  = clamp(_pitch - rel.y * _look_sens * 0.01, deg_to_rad(-85.0), deg_to_rad(85.0))
	player.rotation.y = _yaw
	cam.rotation.x = _pitch

func _handle_move(delta: float) -> void:
	var dir_local := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):  dir_local.z -= 1.0
	if Input.is_action_pressed("move_backward"): dir_local.z += 1.0
	if Input.is_action_pressed("move_left"):     dir_local.x -= 1.0
	if Input.is_action_pressed("move_right"):    dir_local.x += 1.0
	if dir_local != Vector3.ZERO:
		dir_local = dir_local.normalized()

	# yaw-only transform (player holds yaw)
	var dir_world: Vector3 = (player.global_transform.basis * dir_local)
	dir_world.y = 0.0
	if dir_world != Vector3.ZERO:
		dir_world = dir_world.normalized()

	var v: Vector3 = player.velocity
	v.x = dir_world.x * _speed
	v.z = dir_world.z * _speed
	if not player.is_on_floor():
		v.y -= _gravity * delta
	else:
		v.y = 0.0
	player.velocity = v
	player.move_and_slide()

func _current_interactable() -> Interactable:
	if not ray.is_colliding():
		return null
	var obj: Object = ray.get_collider()
	return obj as Interactable

func _update_prompt() -> void:
	var i := _current_interactable()
	# unfocus previous
	if _focused_last and _focused_last != i:
		if _focused_last.has_method("set_focused"):
			_focused_last.call("set_focused", false)
		_focused_last = null

	if i:
		prompt_label.visible = true
		prompt_label.text = "E — %s" % (i.prompt if i.prompt != "" else "Interact")
		i.set_focused(true)
		_focused_last = i
	else:
		prompt_label.visible = false

func _try_interact() -> void:
	var i := _current_interactable()
	if i == null:
		return
	match i.action_id:
		"open_board":
			(_board as Window).call("open_board")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		"open_stash":
			(_stash as Window).call("open_stash")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		"sleep_bed":
			if _sleep:
				(_sleep as SleepDialogUI).open_dialog()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_:
			pass

func _any_ui_open() -> bool:
	return (_board and _board.visible) \
		or (_stash and _stash.visible) \
		or (_sleep and _sleep.visible)
