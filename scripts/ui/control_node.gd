extends Control
class_name ControlNode

## Interactive control node for manipulating connection string curves

signal node_moved(node: ControlNode, new_position: Vector2)
signal node_released(node: ControlNode)

var is_dragging: bool = false
var drag_offset: Vector2
var original_position: Vector2
var has_been_moved: bool = false
var node_radius: float = 8.0

func _ready():
	# Set up the control node
	custom_minimum_size = Vector2(node_radius * 2, node_radius * 2)
	size = Vector2(node_radius * 2, node_radius * 2)
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 150  # Above connection strings
	visible = false  # Start hidden, will be shown on hover
	
	# Store original position for cleanup detection
	original_position = position

func _draw():
	"""Draw the control node as a small circle"""
	var center = size / 2.0
	var color = Color.WHITE if not is_dragging else Color.YELLOW
	var border_color = Color.BLACK
	
	# Draw border
	draw_circle(center, node_radius + 1, border_color)
	# Draw fill
	draw_circle(center, node_radius, color)

func _gui_input(event):
	"""Handle mouse input for dragging the control node"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = event.position
				move_to_front()
				queue_redraw()
			else:
				if is_dragging:
					is_dragging = false
					has_been_moved = position.distance_to(original_position) > 5.0
					emit_signal("node_released", self)
					queue_redraw()
	
	elif event is InputEventMouseMotion and is_dragging:
		var global_mouse_pos = get_global_mouse_position()
		var parent_node = get_parent()
		
		if parent_node:
			# Convert global mouse position to parent's local coordinate space
			var parent_transform = parent_node.get_global_transform()
			var local_mouse_pos = parent_transform.affine_inverse() * global_mouse_pos
			position = local_mouse_pos - drag_offset
			emit_signal("node_moved", self, position)
			queue_redraw()

func set_node_position(new_pos: Vector2):
	"""Set the node position programmatically"""
	position = new_pos
	queue_redraw()

func set_has_been_moved(moved: bool):
	"""Mark this node as having been moved"""
	has_been_moved = moved

func start_immediate_drag(local_click_offset: Vector2):
	"""Start dragging immediately with the given click offset"""
	is_dragging = true
	drag_offset = local_click_offset
	has_been_moved = true  # Mark as moved immediately to prevent cleanup
	move_to_front()
	queue_redraw()

func cleanup_if_unused() -> bool:
	"""Check if this node should be cleaned up (not moved from original position)"""
	# Only cleanup if the node hasn't been moved at all
	return not has_been_moved