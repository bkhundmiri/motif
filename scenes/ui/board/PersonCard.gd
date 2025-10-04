extends GraphNode

@onready var name_edit: LineEdit = $VBox/Name
@onready var dob_edit:  LineEdit = $VBox/DOB
@onready var close_btn: Button  = $CloseBtn

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func() -> void:
			queue_free()
		)

func set_person(name: String, dob: String) -> void:
	name_edit.text = name
	dob_edit.text = dob

func serialize() -> Dictionary:
	return {
		"type": "person",
		"id": name,
		"name": name_edit.text,
		"dob": dob_edit.text,
		"pos": position_offset,
	}
