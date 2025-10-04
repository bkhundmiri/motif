extends Window
class_name StashWindowUI

@onready var header: Label = $VBoxContainer/Header
@onready var body: RichTextLabel = $VBoxContainer/Body

func _ready() -> void:
	hide()
	close_requested.connect(hide)

func open_stash() -> void:
	header.text = "Stash / Loadout"
	body.text = "- Flashlight\n- UV Powder Kit\n- Camera\n\n(Equip/weight/legalities later)"
	popup_centered()
