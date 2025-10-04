extends Control

@onready var lbl: Label = $Lbl

func _ready() -> void:
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.text = ""
	GameState.time_changed.connect(_on_time_changed)
	_on_time_changed(GameState.day, GameState.hour, GameState.minute)

func _on_time_changed(d: int, h: int, m: int) -> void:
	var hh := str(h).pad_zeros(2)
	var mm := str(m).pad_zeros(2)
	lbl.text = "Day %d  —  %s:%s" % [d, hh, mm]
