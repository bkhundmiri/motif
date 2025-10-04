extends GraphNode
class_name StickyNoteUI

@onready var text_edit: TextEdit = $Text
@onready var close_btn: Button = $CloseBtn

func _ready() -> void:
	# Drag from anywhere on the card.
	draggable = false
	resizable = false

	# ---- Enable an invisible port on BOTH sides at slot index 0 ----
	clear_all_slots()
	set_slot(0, true, 1, Color.WHITE, true, 1, Color.WHITE)

	var LINE := Color(0.84, 0.11, 0.11, 1.0)
	set_slot_color_left(0,  LINE)
	set_slot_color_right(0, LINE)

	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) 
	var invisible := ImageTexture.create_from_image(img)
	set_slot_custom_icon_left(0,  invisible)
	set_slot_custom_icon_right(0, invisible)
	set_slot_draw_stylebox(0, false)

	# Hide the little slot background:
	set_slot_draw_stylebox(0, true)

	# Close button
	if close_btn:
		close_btn.pressed.connect(func() -> void:
			queue_free()
		)

	var clear := StyleBoxEmpty.new()
	text_edit.add_theme_stylebox_override("normal", clear)
	text_edit.add_theme_stylebox_override("focus", clear)
	text_edit.add_theme_color_override("font_color", Color.BLACK)
	text_edit.add_theme_color_override("font_placeholder_color", Color(0,0,0,0.45))
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.placeholder_text = "New note"

# -------- Dragging from anywhere helpers --------
var _dragging := false
var _drag_offset := Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = get_local_mouse_position()
				accept_event()
			else:
				_dragging = false
				accept_event()

	elif event is InputEventMouseMotion and _dragging:
		# Move node with the mouse
		position_offset += event.relative
		accept_event()

# -------- Textbox helpers --------

func set_text(t: String) -> void:
	if text_edit:
		text_edit.text = t

func get_text() -> String:
	return text_edit.text if text_edit else ""

func serialize() -> Dictionary:
	return {
		"type": "note",
		"id":   name,
		"pos":  position_offset,
		"text": get_text(),
	}
