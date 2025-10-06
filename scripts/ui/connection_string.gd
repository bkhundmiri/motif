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

func _ready():
	# Make sure this draws above other elements but below UI
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_PASS  # Allow mouse interaction
	
	# Set up hover tooltip
	_setup_tooltip()

func _setup_tooltip():
	"""Set up hover tooltip"""
	hover_tooltip = Label.new()
	hover_tooltip.text = "Right-click to delete"
	hover_tooltip.add_theme_color_override("font_color", Color.WHITE)
	hover_tooltip.add_theme_color_override("font_shadow_color", Color.BLACK)
	hover_tooltip.add_theme_constant_override("shadow_offset_x", 1)
	hover_tooltip.add_theme_constant_override("shadow_offset_y", 1)
	hover_tooltip.visible = false
	hover_tooltip.z_index = 200
	add_child(hover_tooltip)

func setup_connection(from_note: StickyNote, to_note: StickyNote):
	"""Set up connection between two notes"""
	print("Setting up connection string between: ", from_note.note_id, " and ", to_note.note_id)
	source_note = from_note
	target_note = to_note
	
	# Connect to note movement signals to update connection
	if source_note:
		source_note.connect("note_moved", _on_note_moved)
		source_note.connect("note_deleted", _on_note_deleted)
		print("Connected signals for source note")
	
	if target_note:
		target_note.connect("note_moved", _on_note_moved)
		target_note.connect("note_deleted", _on_note_deleted)
		print("Connected signals for target note")
	
	# Initial update
	_update_connection_points()
	print("Connection setup complete")

func _update_connection_points():
	"""Update the connection points based on note positions"""
	if not source_note or not target_note:
		print("Missing notes for connection update")
		return
	
	print("Updating connection points. Source pos: ", source_note.position, " Target pos: ", target_note.position)
	
	# Get the closest anchor points between the two notes in parent coordinate space
	var source_center = source_note.position + (source_note.size / 2.0)
	var target_center = target_note.position + (target_note.size / 2.0)
	
	# Get anchor points in parent's coordinate system
	source_point = source_note.get_closest_anchor_point(target_center)
	target_point = target_note.get_closest_anchor_point(source_center)
	
	print("Anchor points: ", source_point, " -> ", target_point)
	
	# Calculate curve control points for string-like appearance
	_calculate_curve_points()
	
	# Update collision area for mouse detection
	_update_collision_area()
	
	print("Connection position: ", position, " size: ", size)
	
	# Force redraw
	queue_redraw()

func _calculate_curve_points():
	"""Calculate control points for curved connection"""
	control_points.clear()
	
	var distance = source_point.distance_to(target_point)
	var curve_strength = min(distance * 0.3, 100.0)  # Curve based on distance
	
	# Calculate perpendicular direction for curve
	var direction = (target_point - source_point).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Add curve control point in the middle, offset perpendicular
	var mid_point = (source_point + target_point) / 2.0
	var control_point = mid_point + perpendicular * curve_strength * 0.5
	
	# Store points relative to the connection's position (will be set in _update_collision_area)
	control_points.append(source_point)
	control_points.append(control_point)
	control_points.append(target_point)

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
	if control_points.size() < 3:
		return
	
	# Convert control points to local drawing coordinates
	var local_points: Array[Vector2] = []
	for point in control_points:
		local_points.append(point - position)
	
	# Determine line properties based on hover state
	var current_width = hover_width if is_hovered else line_width
	var current_color = connection_color
	if is_hovered:
		current_color = connection_color.lightened(0.3)  # Glow effect
	
	# Draw curved line using multiple segments
	var segments = 20
	for i in range(segments):
		var t1 = float(i) / float(segments)
		var t2 = float(i + 1) / float(segments)
		
		var point1 = _bezier_curve(local_points, t1)
		var point2 = _bezier_curve(local_points, t2)
		
		draw_line(point1, point2, current_color, current_width, true)
	
	# Draw connection points (small circles)
	var circle_radius = 8.0 if is_hovered else 6.0
	draw_circle(local_points[0], circle_radius, current_color)
	draw_circle(local_points[-1], circle_radius, current_color)

func _bezier_curve(points: Array[Vector2], t: float) -> Vector2:
	"""Calculate point on quadratic bezier curve"""
	if points.size() != 3:
		return Vector2.ZERO
	
	var u = 1.0 - t
	return u * u * points[0] + 2 * u * t * points[1] + t * t * points[2]

func _gui_input(event):
	"""Handle mouse input for hover and deletion"""
	if event is InputEventMouseMotion:
		var local_mouse = event.position
		if _is_mouse_over_connection(local_mouse):
			if not is_hovered:
				is_hovered = true
				hover_tooltip.visible = true
				hover_tooltip.position = local_mouse + Vector2(10, -20)
				queue_redraw()
		else:
			if is_hovered:
				is_hovered = false
				hover_tooltip.visible = false
				queue_redraw()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var local_mouse = event.position
			if _is_mouse_over_connection(local_mouse):
				# Delete this connection
				queue_free()

func _is_mouse_over_connection(local_pos: Vector2) -> bool:
	"""Check if mouse is over the connection line"""
	if control_points.size() < 3:
		return false
	
	# Convert control points to local space relative to this control's position
	var local_points: Array[Vector2] = []
	for point in control_points:
		local_points.append(point - position)
	
	# Check distance to curve
	var min_distance = INF
	var segments = 20
	for i in range(segments):
		var t = float(i) / float(segments)
		var curve_point = _bezier_curve(local_points, t)
		var distance = local_pos.distance_to(curve_point)
		min_distance = min(min_distance, distance)
	
	# Consider it a hit if within reasonable distance
	return min_distance <= (hover_width + 5.0)

func _on_note_moved(_note: StickyNote, _new_position: Vector2):
	"""Handle when connected notes are moved"""
	_update_connection_points()

func _on_note_deleted(_note: StickyNote):
	"""Handle when a connected note is deleted"""
	# Remove this connection when either note is deleted
	queue_free()

func get_save_data() -> Dictionary:
	"""Get data for saving this connection"""
	return {
		"source_id": source_note.note_id if source_note else "",
		"target_id": target_note.note_id if target_note else "",
		"color": {
			"r": connection_color.r,
			"g": connection_color.g,
			"b": connection_color.b,
			"a": connection_color.a
		}
	}

func load_from_data(data: Dictionary, notes_by_id: Dictionary):
	"""Load connection from saved data"""
	if data.has("source_id") and data.has("target_id"):
		var source_id = data["source_id"]
		var target_id = data["target_id"]
		
		if notes_by_id.has(source_id) and notes_by_id.has(target_id):
			setup_connection(notes_by_id[source_id], notes_by_id[target_id])
	
	if data.has("color"):
		var color_data = data["color"]
		connection_color = Color(color_data.r, color_data.g, color_data.b, color_data.a)