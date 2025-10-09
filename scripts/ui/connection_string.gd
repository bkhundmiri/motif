extends Control
class_name ConnectionString

## Visual connection string between two sticky notes
## Renders as a red line with connection points

# Connection properties
var source_note: StickyNote
var target_note: StickyNote
var connection_color: Color = Color.RED
var line_width: float = 5.0  # Thicker line
var hover_width: float = 8.0  # Even thicker on hover
var is_hovered: bool = false

# Drawing and interaction
var source_point: Vector2
var target_point: Vector2
var control_points: Array[Vector2] = []  # For curve
var hover_tooltip: Label

# Dynamic manipulation system
var control_nodes: Array[Control] = []  # Interactive control nodes
var is_being_manipulated: bool = false
var manipulation_timer: Timer
var curve_segments: Array[Vector2] = []  # Cached curve points for hit detection
var min_segment_distance: float = 50.0  # Minimum distance between control nodes

# Immediate dragging state
var currently_dragging_node: Control = null
var drag_start_offset: Vector2 = Vector2.ZERO
var is_immediate_dragging: bool = false

# Anchor update cooldown to prevent jitter
var anchor_update_cooldown: bool = false

func _ready():
	# Make sure this draws above other elements but below UI
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_PASS  # Allow mouse interaction
	
	# Set up hover tooltip
	_setup_tooltip()
	
	# Set up manipulation system
	_setup_manipulation_system()

func _exit_tree():
	"""Cleanup when the connection string is being destroyed"""
	_cleanup_all_control_nodes()

func _setup_tooltip():
	"""Set up hover tooltip with dark styling"""
	hover_tooltip = Label.new()
	hover_tooltip.text = "Left-click: add control node | Right-click: delete"
	hover_tooltip.visible = false
	hover_tooltip.z_index = 1000
	
	# Create dark background style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.9)  # Dark semi-transparent
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	style_box.content_margin_left = 8
	style_box.content_margin_right = 8
	style_box.content_margin_top = 4
	style_box.content_margin_bottom = 4
	
	hover_tooltip.add_theme_stylebox_override("normal", style_box)
	hover_tooltip.add_theme_color_override("font_color", Color.WHITE)
	hover_tooltip.add_theme_color_override("font_shadow_color", Color.BLACK)
	hover_tooltip.add_theme_constant_override("shadow_offset_x", 1)
	hover_tooltip.add_theme_constant_override("shadow_offset_y", 1)
	
	add_child(hover_tooltip)

func _setup_manipulation_system():
	"""Set up the dynamic manipulation system"""
	manipulation_timer = Timer.new()
	manipulation_timer.wait_time = 2.0  # Hide nodes after 2 seconds of no interaction
	manipulation_timer.one_shot = true
	manipulation_timer.timeout.connect(_end_manipulation_mode)
	add_child(manipulation_timer)

func setup_connection(from_note: StickyNote, to_note: StickyNote):
	"""Set up connection between two notes"""
	print("setup_connection called: from='%s' (ID: %s) to='%s' (ID: %s)" % [
		from_note.get_note_text() if from_note else "null", 
		from_note.note_id if from_note else "null",
		to_note.get_note_text() if to_note else "null",
		to_note.note_id if to_note else "null"
	])
	
	source_note = from_note
	target_note = to_note
	
	# Connect to note movement signals to update connection
	if source_note:
		source_note.connect("note_moved", _on_note_moved)
		source_note.connect("note_deleted", _on_note_deleted)
	
	if target_note:
		target_note.connect("note_moved", _on_note_moved)
		target_note.connect("note_deleted", _on_note_deleted)
	
	# Initial update
	_update_connection_points()
	print("setup_connection completed, connection points updated")

func _update_connection_points():
	"""Update the connection points based on note positions"""
	if not source_note or not target_note:
		print("_update_connection_points: Missing notes (source: %s, target: %s)" % [source_note != null, target_note != null])
		return
	
	# Get the closest anchor points between the two notes in parent coordinate space
	var source_center = source_note.position + (source_note.size / 2.0)
	var target_center = target_note.position + (target_note.size / 2.0)
	
	# Get anchor points in parent's coordinate system
	source_point = source_note.get_closest_anchor_point(target_center)
	target_point = target_note.get_closest_anchor_point(source_center)
	
	# Calculate curve control points for string-like appearance
	_calculate_curve_points()
	
	# Update collision area for mouse detection
	_update_collision_area()
	
	# Force redraw
	queue_redraw()

func update_on_note_movement():
	"""Update connection when source or target notes are moved"""
	if not source_note or not target_note:
		return
	
	# Use unified anchor update logic but only for basic movement without control nodes
	if control_nodes.size() == 0:
		# Simple case: no control nodes, use center-to-center logic
		var source_center = source_note.position + (source_note.size / 2.0)
		var target_center = target_note.position + (target_note.size / 2.0)
		
		source_point = source_note.get_closest_anchor_point(target_center)
		target_point = target_note.get_closest_anchor_point(source_center)
		
		# Simple recalculation for basic connections
		_calculate_curve_points()
	else:
		# Complex case: has control nodes, use smart anchor updates
		_update_anchors_intelligently(false)  # false = not from curve reshaping
	
	# Update collision and redraw
	_update_collision_area()
	queue_redraw()

func _calculate_curve_points():
	"""Calculate control points for curved connection with dynamic nodes"""
	control_points.clear()
	curve_segments.clear()
	
	# Always start with source point
	control_points.append(source_point)
	
	# Add any intermediate control nodes
	for node in control_nodes:
		if is_instance_valid(node):
			control_points.append(node.position)
	
	# Always end with target point
	control_points.append(target_point)
	
	# Generate smooth curve segments for drawing and hit detection
	_generate_curve_segments()
	
	# Apply anti-looping and malformation protection
	_apply_curve_protection()
	
	# Force redraw after curve calculation
	queue_redraw()

func _generate_curve_segments():
	"""Generate smooth curve segments for drawing"""
	if control_points.size() < 2:
		return
	
	curve_segments.clear()
	var total_segments = 50  # High resolution for smooth curves
	
	for i in range(total_segments + 1):
		var t = float(i) / float(total_segments)
		var point = _calculate_curve_point_at_t(t)
		curve_segments.append(point)

func _calculate_curve_point_at_t(t: float) -> Vector2:
	"""Calculate point on curve at parameter t using B-spline interpolation"""
	if control_points.size() < 2:
		return Vector2.ZERO
	
	if control_points.size() == 2:
		# Linear interpolation for 2 points
		return control_points[0].lerp(control_points[1], t)
	
	if control_points.size() == 3:
		# Quadratic Bezier for 3 points
		return _bezier_curve(control_points, t)
	
	# For more points, use Catmull-Rom spline
	return _catmull_rom_spline(control_points, t)

func _catmull_rom_spline(points: Array[Vector2], t: float) -> Vector2:
	"""Calculate point on Catmull-Rom spline"""
	var num_segments = points.size() - 1
	var segment_t = t * num_segments
	var segment_index = int(segment_t)
	var local_t = segment_t - segment_index
	
	if segment_index >= num_segments:
		return points[-1]
	
	# Get control points for this segment
	var p0 = points[max(0, segment_index - 1)]
	var p1 = points[segment_index]
	var p2 = points[min(points.size() - 1, segment_index + 1)]
	var p3 = points[min(points.size() - 1, segment_index + 2)]
	
	# Catmull-Rom formula
	var t2 = local_t * local_t
	var t3 = t2 * local_t
	
	return 0.5 * (
		(2 * p1) +
		(-p0 + p2) * local_t +
		(2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
		(-p0 + 3 * p1 - 3 * p2 + p3) * t3
	)

func _apply_curve_protection():
	"""Apply anti-looping and malformation protection"""
	# Check for self-intersections and tight loops
	var intersection_found = false
	for i in range(curve_segments.size() - 1):
		for j in range(i + 2, curve_segments.size() - 1):
			var p1 = curve_segments[i]
			var p2 = curve_segments[i + 1]
			var p3 = curve_segments[j]
			var p4 = curve_segments[j + 1]
			
			if _lines_intersect(p1, p2, p3, p4):
				_fix_curve_intersection(i, j)
				intersection_found = true
				break
		if intersection_found:
			break
	
	# Check for sharp angles and overly tight curves
	_fix_sharp_angles()

func _lines_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	"""Check if two line segments intersect"""
	var d = (a2.x - a1.x) * (b2.y - b1.y) - (a2.y - a1.y) * (b2.x - b1.x)
	if abs(d) < 0.001:  # Lines are parallel
		return false
	
	var ua = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / d
	var ub = ((a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x)) / d
	
	return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1

func _fix_curve_intersection(seg1: int, seg2: int):
	"""Fix curve intersection by adjusting control points"""
	if control_nodes.size() == 0:
		return
	
	# Find the control node that's causing the intersection
	var problematic_node_index = _find_problematic_control_node(seg1, seg2)
	if problematic_node_index >= 0 and problematic_node_index < control_nodes.size():
		var node = control_nodes[problematic_node_index]
		if is_instance_valid(node):
			# Calculate a safe position that avoids intersection
			var safe_position = _calculate_safe_position(node.position)
			node.position = safe_position
			
			# Regenerate curve after adjustment
			_generate_curve_segments()

func _find_problematic_control_node(seg1: int, seg2: int) -> int:
	"""Find which control node is likely causing the intersection"""
	var mid_segment = (seg1 + seg2) / 2.0
	var segments_per_control_node = float(curve_segments.size()) / float(control_points.size())
	var node_index = int(mid_segment / segments_per_control_node) - 1  # -1 because first point is source
	return clamp(node_index, 0, control_nodes.size() - 1)

func _calculate_safe_position(current_pos: Vector2) -> Vector2:
	"""Calculate a safe position that doesn't cause intersections"""
	# Calculate the line between source and target
	var line_direction = (target_point - source_point).normalized()
	var line_length = source_point.distance_to(target_point)
	
	# Project current position onto the line to find the closest point
	var to_current = current_pos - source_point
	var projection_length = to_current.dot(line_direction)
	var projected_point = source_point + line_direction * projection_length
	
	# Calculate perpendicular distance from the line
	var perpendicular_direction = (current_pos - projected_point).normalized()
	if perpendicular_direction.length() < 0.1:  # If too close to line, use default perpendicular
		perpendicular_direction = Vector2(-line_direction.y, line_direction.x)
	
	# Ensure minimum offset from the main line (prevent self-kissing) - reduced for better shaping
	var min_offset = max(40.0, line_length * 0.08)  # At least 40px or 8% of line length (reduced from 80px/15%)
	var safe_position = projected_point + perpendicular_direction * min_offset
	
	# Ensure minimum distance from endpoints - reduced for better flexibility
	var min_endpoint_distance = 35.0  # Reduced from 60.0
	if safe_position.distance_to(source_point) < min_endpoint_distance:
		safe_position = source_point + (safe_position - source_point).normalized() * min_endpoint_distance
	if safe_position.distance_to(target_point) < min_endpoint_distance:
		safe_position = target_point + (safe_position - target_point).normalized() * min_endpoint_distance
	
	return safe_position

func _update_anchors_intelligently(from_curve_reshaping: bool = true):
	"""Intelligently update anchor points based on curve shape with less aggressive snapping"""
	if not source_note or not target_note or curve_segments.size() < 2:
		return
	
	# Calculate current curve directions
	var source_center = source_note.position + source_note.size / 2.0
	var target_center = target_note.position + target_note.size / 2.0
	
	# Get curve direction from source (where the curve is heading)
	var curve_direction_from_source: Vector2
	if curve_segments.size() >= 5:  # Need more segments for reliable direction
		# Use more segments for better direction calculation
		curve_direction_from_source = (curve_segments[4] - curve_segments[0]).normalized()
	elif curve_segments.size() >= 3:
		curve_direction_from_source = (curve_segments[2] - curve_segments[0]).normalized()
	else:
		# Fallback to simple direction
		curve_direction_from_source = (target_center - source_center).normalized()
	
	# Get curve direction to target (where the curve is coming from)
	var curve_direction_to_target: Vector2
	var last_idx = curve_segments.size() - 1
	if curve_segments.size() >= 5:
		curve_direction_to_target = (curve_segments[last_idx] - curve_segments[last_idx - 4]).normalized()
	elif curve_segments.size() >= 3:
		curve_direction_to_target = (curve_segments[last_idx] - curve_segments[last_idx - 2]).normalized()
	else:
		curve_direction_to_target = (target_center - source_center).normalized()
	
	# Calculate ideal anchor positions
	var ideal_source_pos = source_center + curve_direction_from_source * 100
	var ideal_target_pos = target_center - curve_direction_to_target * 100
	
	# Get potential new anchors
	var new_source_anchor = source_note.get_closest_anchor_point(ideal_source_pos)
	var new_target_anchor = target_note.get_closest_anchor_point(ideal_target_pos)
	
	# Determine update thresholds based on context
	var update_threshold: float
	if from_curve_reshaping:
		# More conservative when reshaping curves
		update_threshold = 25.0  # Only update if significantly different
	else:
		# More responsive when moving notes
		update_threshold = 15.0
	
	# Update source anchor if change is significant enough
	var source_distance = new_source_anchor.distance_to(source_point)
	if source_distance > update_threshold:
		# Additional check: ensure the new anchor is actually better
		var current_source_quality = _calculate_anchor_quality(source_point, source_center, curve_direction_from_source)
		var new_source_quality = _calculate_anchor_quality(new_source_anchor, source_center, curve_direction_from_source)
		
		if new_source_quality > current_source_quality + 0.2:  # Require significant improvement
			source_point = new_source_anchor
	
	# Update target anchor if change is significant enough
	var target_distance = new_target_anchor.distance_to(target_point)
	if target_distance > update_threshold:
		# Additional check: ensure the new anchor is actually better
		var current_target_quality = _calculate_anchor_quality(target_point, target_center, -curve_direction_to_target)
		var new_target_quality = _calculate_anchor_quality(new_target_anchor, target_center, -curve_direction_to_target)
		
		if new_target_quality > current_target_quality + 0.2:  # Require significant improvement
			target_point = new_target_anchor
	
	# Recalculate curve after any anchor updates
	_calculate_curve_points()

func _calculate_anchor_quality(anchor_pos: Vector2, note_center: Vector2, desired_direction: Vector2) -> float:
	"""Calculate how good an anchor point is for the desired direction (0.0 to 1.0)"""
	var anchor_direction = (anchor_pos - note_center).normalized()
	var alignment = anchor_direction.dot(desired_direction)
	# Convert from -1..1 to 0..1 range
	return (alignment + 1.0) / 2.0

# Keep the old function name for compatibility but redirect to the new system
func _update_dynamic_anchor_points():
	"""Legacy function - redirects to intelligent anchor updates"""
	_update_anchors_intelligently(true)

func _fix_sharp_angles():
	"""Fix overly sharp angles in the curve"""
	if control_nodes.size() < 1:
		return
	
	for i in range(control_nodes.size()):
		var node = control_nodes[i]
		if not is_instance_valid(node):
			continue
		
		# Get previous and next points for angle calculation
		var prev_point = source_point if i == 0 else control_nodes[i-1].position
		var current_point = node.position
		var next_point = target_point if i == control_nodes.size()-1 else control_nodes[i+1].position
		
		# Calculate angle
		var vec1 = (prev_point - current_point).normalized()
		var vec2 = (next_point - current_point).normalized()
		var angle = vec1.angle_to(vec2)
		
		# If angle is too sharp (less than 45 degrees), adjust position
		if abs(angle) < deg_to_rad(45):
			# Calculate the midpoint between previous and next
			var midpoint = (prev_point + next_point) / 2.0
			var line_direction = (next_point - prev_point).normalized()
			var perpendicular = Vector2(-line_direction.y, line_direction.x)
			
			# Move node away from the sharp angle with larger offset
			var offset_distance = 60.0
			# Choose direction that moves away from the angle
			var current_to_mid = (midpoint - current_point).normalized()
			var perp_dot = perpendicular.dot(current_to_mid)
			
			if perp_dot > 0:
				node.position = midpoint + perpendicular * offset_distance
			else:
				node.position = midpoint - perpendicular * offset_distance

func _end_manipulation_mode():
	"""End manipulation mode and clean up unused nodes"""
	is_being_manipulated = false
	
	# Only hide nodes if we're not hovering
	if not is_hovered:
		_hide_control_nodes()
	
	# Clean up unused nodes
	_cleanup_unused_nodes()

func _cleanup_all_control_nodes():
	"""Remove all control nodes when connection is being deleted"""
	for node in control_nodes:
		if is_instance_valid(node):
			node.queue_free()
	control_nodes.clear()

func _cleanup_unused_nodes():
	"""Remove control nodes that haven't been moved"""
	var nodes_to_remove: Array[Control] = []
	
	for node in control_nodes:
		if is_instance_valid(node) and node.has_method("cleanup_if_unused") and node.cleanup_if_unused():
			nodes_to_remove.append(node)
	
	for node in nodes_to_remove:
		control_nodes.erase(node)
		node.queue_free()
	
	# Recalculate curve and collision area after cleanup
	if nodes_to_remove.size() > 0:
		_calculate_curve_points()
		_update_collision_area()

func _update_collision_area():
	"""Update the mouse collision area"""
	# Calculate bounds based on control points
	if control_points.size() < 2:
		return
		
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for point in control_points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	# Add padding for easier mouse interaction
	var padding = 20.0
	position = Vector2(min_x - padding, min_y - padding)
	size = Vector2(max_x - min_x + 2 * padding, max_y - min_y + 2 * padding)

func _draw():
	"""Draw the connection string with curve and hover effects"""
	if curve_segments.size() < 2:
		return
	
	# Determine line properties based on hover state
	var current_width = hover_width if is_hovered else line_width
	var current_color = connection_color
	if is_hovered:
		current_color = connection_color.lightened(0.3)  # Glow effect
	
	# Draw curved line using generated segments
	for i in range(curve_segments.size() - 1):
		var point1 = curve_segments[i] - position
		var point2 = curve_segments[i + 1] - position
		draw_line(point1, point2, current_color, current_width, true)
	
	# Draw connection points at start and end
	if curve_segments.size() > 0:
		var circle_radius = 8.0 if is_hovered else 6.0
		var start_point = curve_segments[0] - position
		var end_point = curve_segments[-1] - position
		draw_circle(start_point, circle_radius, current_color)
		draw_circle(end_point, circle_radius, current_color)

func _bezier_curve(points: Array[Vector2], t: float) -> Vector2:
	"""Calculate point on quadratic bezier curve"""
	if points.size() != 3:
		return Vector2.ZERO
	
	var u = 1.0 - t
	return u * u * points[0] + 2 * u * t * points[1] + t * t * points[2]

func _gui_input(event):
	"""Handle mouse input for hover, deletion, and dynamic manipulation"""
	if event is InputEventMouseMotion:
		# Handle immediate dragging if active
		if is_immediate_dragging and currently_dragging_node:
			_handle_immediate_drag_motion(event)
			return
		
		var local_mouse = event.position
		var mouse_over = _is_mouse_over_connection(local_mouse)
		
		if mouse_over:
			if not is_hovered:
				is_hovered = true
				hover_tooltip.visible = true
				hover_tooltip.position = local_mouse + Vector2(10, -20)
				_show_control_nodes()
				queue_redraw()
		else:
			if is_hovered:
				is_hovered = false
				hover_tooltip.visible = false
				_hide_control_nodes()
				queue_redraw()
	
	elif event is InputEventMouseButton:
		if is_immediate_dragging and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# End immediate dragging
			_end_immediate_drag()
			return
		
		if event.pressed:
			var local_mouse = event.position
			if _is_mouse_over_connection(local_mouse):
				if event.button_index == MOUSE_BUTTON_RIGHT:
					# Delete this connection and cleanup control nodes
					_cleanup_all_control_nodes()
					queue_free()
					get_viewport().set_input_as_handled()
				elif event.button_index == MOUSE_BUTTON_LEFT:
					# Create control node for manipulation and start immediate dragging
					_create_control_node_at_position(local_mouse)
					get_viewport().set_input_as_handled()

func _show_control_nodes():
	"""Show all control nodes when hovering over connection"""
	for node in control_nodes:
		if is_instance_valid(node):
			node.visible = true

func _hide_control_nodes():
	"""Hide all control nodes when not hovering"""
	for node in control_nodes:
		if is_instance_valid(node):
			node.visible = false

func _create_control_node_at_position(local_pos: Vector2):
	"""Create a new control node at the clicked position on the curve"""
	# Find the exact position on the curve where the user clicked
	var curve_click_pos = _find_exact_curve_click_position(local_pos)
	
	# Create new control node
	var control_node = preload("res://scripts/ui/control_node.gd").new()
	control_node.position = curve_click_pos
	control_node.visible = true  # Always visible when created
	control_node.connect("node_moved", _on_control_node_moved)
	control_node.connect("node_released", _on_control_node_released)
	
	# Add to parent and our control nodes array
	get_parent().add_child(control_node)
	control_nodes.append(control_node)
	
	# Insert node at correct position in the curve sequence
	_insert_control_node_in_sequence(control_node, curve_click_pos)
	
	# Ensure all control nodes are visible since we're interacting
	_show_control_nodes()
	
	# Enter manipulation mode to reset timer
	_enter_manipulation_mode()
	
	# Recalculate curve and update collision area
	_calculate_curve_points()
	_update_collision_area()
	
	# Start immediate dragging
	_start_immediate_drag(control_node, local_pos)

func _start_immediate_drag(control_node: Control, _click_pos: Vector2):
	"""Start immediate dragging of a newly created control node"""
	currently_dragging_node = control_node
	is_immediate_dragging = true
	
	# Calculate offset from current mouse position to node position
	# This ensures the node doesn't jump when dragging starts
	var current_mouse_global = get_global_mouse_position()
	drag_start_offset = current_mouse_global - control_node.position
	
	# Mark the node as being moved to prevent cleanup
	if control_node.has_method("set_has_been_moved"):
		control_node.set_has_been_moved(true)

func _handle_immediate_drag_motion(_event: InputEventMouseMotion):
	"""Handle mouse motion during immediate dragging"""
	if not currently_dragging_node or not is_instance_valid(currently_dragging_node):
		_end_immediate_drag()
		return
	
	# Calculate new position based on mouse movement
	var global_mouse_pos = get_global_mouse_position()
	var new_position = global_mouse_pos - drag_start_offset
	
	# Update control node position
	currently_dragging_node.position = new_position
	
	# Update curve in real-time
	_calculate_curve_points()
	_update_collision_area()
	
	# Reset manipulation timer
	manipulation_timer.start()
	
	print("Dragging node to: ", new_position)

func _end_immediate_drag():
	"""End immediate dragging mode"""
	if currently_dragging_node and is_instance_valid(currently_dragging_node):
		# Final curve update
		_calculate_curve_points()
		_update_collision_area()
		print("Ended immediate drag for control node")
	
	currently_dragging_node = null
	is_immediate_dragging = false
	drag_start_offset = Vector2.ZERO

func _find_exact_curve_click_position(local_pos: Vector2) -> Vector2:
	"""Find the exact position on the curve where the user clicked using interpolation for accuracy"""
	if curve_segments.size() < 2:
		# Fallback to midpoint between source and target
		return (source_point + target_point) / 2.0
	
	# Convert local click position to global
	var global_click_pos = position + local_pos
	
	# Find the closest segment and interpolate for better accuracy
	var closest_pos = curve_segments[0]
	var min_distance = INF
	var best_segment_index = 0
	
	for i in range(curve_segments.size()):
		var segment_pos = curve_segments[i]
		var distance = global_click_pos.distance_to(segment_pos)
		if distance < min_distance:
			min_distance = distance
			closest_pos = segment_pos
			best_segment_index = i
	
	# If we have adjacent segments, interpolate between them for smoother positioning
	if best_segment_index > 0 and best_segment_index < curve_segments.size() - 1:
		var prev_seg = curve_segments[best_segment_index - 1]
		var next_seg = curve_segments[best_segment_index + 1]
		
		# Project click onto the line between adjacent segments
		var seg_dir = (next_seg - prev_seg).normalized()
		var to_click = global_click_pos - prev_seg
		var projection_length = to_click.dot(seg_dir)
		var projected = prev_seg + seg_dir * clamp(projection_length, 0, prev_seg.distance_to(next_seg))
		
		# Use interpolated position if it's closer to the click
		if global_click_pos.distance_to(projected) < min_distance * 1.2:  # Allow some tolerance
			closest_pos = projected
	
	return closest_pos

func _find_closest_curve_position(target_pos: Vector2) -> Vector2:
	"""Find the position on the curve closest to the target position"""
	if curve_segments.size() < 2:
		# Fallback to midpoint between source and target
		return (source_point + target_point) / 2.0
	
	var closest_pos = curve_segments[0]
	var min_distance = INF
	
	for segment_pos in curve_segments:
		var distance = target_pos.distance_to(segment_pos)
		if distance < min_distance:
			min_distance = distance
			closest_pos = segment_pos
	
	return closest_pos

func _insert_control_node_in_sequence(new_node: Control, node_position: Vector2):
	"""Insert control node at the correct position in the sequence along the curve"""
	if control_nodes.size() <= 1:
		return  # Only one node, no need to sort
	
	# Calculate position along the source-target line for ordering
	var line_direction = (target_point - source_point).normalized()
	var node_projection = line_direction.dot(node_position - source_point)
	
	# Find correct insertion point
	var inserted = false
	for i in range(control_nodes.size() - 1):  # Exclude the just-added node
		var other_node = control_nodes[i]
		if other_node == new_node:
			continue
		
		var other_projection = line_direction.dot(other_node.position - source_point)
		if node_projection < other_projection:
			# Insert before this node
			control_nodes.erase(new_node)
			control_nodes.insert(i, new_node)
			inserted = true
			break
	
	# If not inserted, it goes at the end (but before the last position which is always end)
	if not inserted and control_nodes.size() > 1:
		control_nodes.erase(new_node)
		control_nodes.insert(control_nodes.size(), new_node)

func _find_closest_curve_parameter(target_pos: Vector2) -> float:
	"""Find the curve parameter t closest to the target position"""
	var closest_t = 0.0
	var min_distance = INF
	
	for i in range(curve_segments.size()):
		var segment_pos = curve_segments[i] - position  # Convert to local
		var distance = target_pos.distance_to(segment_pos)
		if distance < min_distance:
			min_distance = distance
			closest_t = float(i) / float(curve_segments.size() - 1)
	
	return closest_t

func _sort_control_nodes():
	"""Sort control nodes by their position along the source-target line"""
	if control_nodes.size() <= 1:
		return
	
	var line_direction = (target_point - source_point).normalized()
	
	control_nodes.sort_custom(func(a, b):
		var a_projection = line_direction.dot(a.position - source_point)
		var b_projection = line_direction.dot(b.position - source_point)
		return a_projection < b_projection
	)

func _enter_manipulation_mode():
	"""Enter manipulation mode (now handled by hover visibility)"""
	is_being_manipulated = true
	# Ensure all control nodes are visible during manipulation
	_show_control_nodes()
	# Reset manipulation timer with longer delay during active manipulation
	manipulation_timer.wait_time = 5.0  # Longer delay when actively manipulating
	manipulation_timer.start()

func _on_control_node_moved(_node: Control, _new_position: Vector2):
	"""Handle control node movement"""
	# Recalculate curve in real-time
	_calculate_curve_points()
	# Update collision area for hover detection
	_update_collision_area()
	# Keep nodes visible during movement
	_show_control_nodes()
	# Reset manipulation timer with longer delay
	manipulation_timer.wait_time = 5.0
	manipulation_timer.start()
	
	# Only update anchors occasionally during movement to prevent jitter
	if not anchor_update_cooldown:
		anchor_update_cooldown = true
		# Use a short timer to prevent too frequent updates
		get_tree().create_timer(0.2).timeout.connect(_on_anchor_update_cooldown_finished)

func _on_control_node_released(_node: Control):
	"""Handle control node release"""
	# Remove any clustered anchors first
	_remove_clustered_anchors()
	
	# Update anchors intelligently after release
	_update_anchors_intelligently(true)  # true = from curve reshaping
	
	# Update collision area for hover detection (curve already calculated in intelligent update)
	_update_collision_area()
	# Keep nodes visible after release
	_show_control_nodes()
	# Reset manipulation timer back to normal delay
	manipulation_timer.wait_time = 2.0
	manipulation_timer.start()

func _is_mouse_over_connection(local_pos: Vector2) -> bool:
	"""Check if mouse is over the connection line using cached curve segments"""
	if curve_segments.size() < 2:
		# Fallback: check direct line between source and target if no curve segments
		if control_points.size() >= 2:
			var start_local = control_points[0] - position
			var end_local = control_points[-1] - position
			var distance = _distance_to_line_segment(local_pos, start_local, end_local)
			return distance <= (hover_width + 5.0)
		return false
	
	# Check distance to cached curve segments
	var min_distance = INF
	for segment_point in curve_segments:
		var local_segment_point = segment_point - position
		var distance = local_pos.distance_to(local_segment_point)
		min_distance = min(min_distance, distance)
		
		# Early exit if we're close enough
		if min_distance <= (hover_width + 5.0):
			return true
	
	# Consider it a hit if within reasonable distance
	return min_distance <= (hover_width + 5.0)

func _on_anchor_update_cooldown_finished():
	"""Called when anchor update cooldown expires"""
	anchor_update_cooldown = false
	# Only update anchors if we still have control nodes
	if control_nodes.size() > 0:
		_update_anchors_intelligently(true)
		_calculate_curve_points()
		_update_collision_area()
		queue_redraw()

func _distance_to_line_segment(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	"""Calculate distance from point to line segment"""
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_length_sq = line_vec.length_squared()
	
	if line_length_sq == 0:
		return point.distance_to(line_start)
	
	var t = clamp(point_vec.dot(line_vec) / line_length_sq, 0.0, 1.0)
	var projection = line_start + t * line_vec
	return point.distance_to(projection)

func _on_note_moved(_note: StickyNote, _new_position: Vector2):
	"""Handle when connected notes are moved"""
	_update_connection_points()

func _on_note_deleted(_note: StickyNote):
	"""Handle when a connected note is deleted"""
	# Cleanup control nodes before removing connection
	_cleanup_all_control_nodes()
	# Remove this connection when either note is deleted
	queue_free()

func get_save_data() -> Dictionary:
	"""Get data for saving this connection"""
	var control_node_data = []
	for node in control_nodes:
		if is_instance_valid(node):
			control_node_data.append({
				"x": node.position.x,
				"y": node.position.y
			})
	
	return {
		"source_id": source_note.note_id if source_note else "",
		"target_id": target_note.note_id if target_note else "",
		"color": {
			"r": connection_color.r,
			"g": connection_color.g,
			"b": connection_color.b,
			"a": connection_color.a
	},
	"control_nodes": control_node_data
}

func load_from_data(data: Dictionary, notes_by_id: Dictionary):
	"""Load connection from saved data"""
	print("ConnectionString.load_from_data called with data: %s" % str(data))
	
	if data.has("source_id") and data.has("target_id"):
		var source_id = data["source_id"]
		var target_id = data["target_id"]
		
		print("Looking for notes: source_id=%s, target_id=%s" % [source_id, target_id])
		print("Available note IDs: %s" % str(notes_by_id.keys()))
		
		if notes_by_id.has(source_id) and notes_by_id.has(target_id):
			var src_note = notes_by_id[source_id]
			var tgt_note = notes_by_id[target_id]
			print("Found both notes: source='%s', target='%s'" % [src_note.get_note_text(), tgt_note.get_note_text()])
			setup_connection(src_note, tgt_note)
		else:
			print("ERROR: Could not find one or both notes for connection")
			if not notes_by_id.has(source_id):
				print("  Missing source note with ID: %s" % source_id)
			if not notes_by_id.has(target_id):
				print("  Missing target note with ID: %s" % target_id)
			return
	
	if data.has("color"):
		var color_data = data["color"]
		connection_color = Color(color_data.r, color_data.g, color_data.b, color_data.a)
	
	# Restore control nodes
	if data.has("control_nodes"):
		print("Restoring %d control nodes" % data["control_nodes"].size())
		for node_data in data["control_nodes"]:
			var node_pos = Vector2(node_data.x, node_data.y)
			_create_control_node_at_position_direct(node_pos)
		
		# Recalculate curve after loading all nodes
		_calculate_curve_points()
		_update_collision_area()
	
	# Force a redraw to ensure the connection is visible
	queue_redraw()
	print("Connection loading completed and redraw queued")

func _create_control_node_at_position_direct(node_pos: Vector2):
	"""Create a control node directly at a position (used for loading)"""
	var control_node = preload("res://scripts/ui/control_node.gd").new()
	control_node.position = node_pos
	control_node.visible = false  # Hidden by default
	control_node.connect("node_moved", _on_control_node_moved)
	control_node.connect("node_released", _on_control_node_released)
	
	# Add to parent and our control nodes array
	get_parent().add_child(control_node)
	control_nodes.append(control_node)
	
	# Insert node at correct position in the curve sequence
	_insert_control_node_in_sequence(control_node, node_pos)

func _remove_clustered_anchors():
	"""Remove control nodes that are too close to each other to prevent malformation"""
	if control_nodes.size() < 2:
		return
	
	var min_cluster_distance = 40.0  # Minimum distance between control nodes
	var nodes_to_remove: Array[Control] = []
	
	# Check each pair of nodes for clustering
	for i in range(control_nodes.size()):
		for j in range(i + 1, control_nodes.size()):
			var node_a = control_nodes[i]
			var node_b = control_nodes[j]
			
			if is_instance_valid(node_a) and is_instance_valid(node_b):
				var distance = node_a.position.distance_to(node_b.position)
				if distance < min_cluster_distance:
					# Remove the node that was added later (higher index)
					if node_b not in nodes_to_remove:
						nodes_to_remove.append(node_b)
	
	# Remove clustered nodes
	for node in nodes_to_remove:
		control_nodes.erase(node)
		node.queue_free()
	
	# Recalculate curve if nodes were removed
	if nodes_to_remove.size() > 0:
		print("Removed %d clustered control nodes" % nodes_to_remove.size())
		_calculate_curve_points()
		_update_collision_area()
