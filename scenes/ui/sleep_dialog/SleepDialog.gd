extends ConfirmationDialog
class_name SleepDialogUI

@onready var now_lbl:    Label   = $VBoxContainer/NowLbl
@onready var amount_lbl: Label   = $VBoxContainer/Row/AmountLbl
@onready var target_lbl: Label   = $VBoxContainer/TargetLbl
@onready var slider:     HSlider = $VBoxContainer/Row/Slider
@onready var ticks:      Control = $VBoxContainer/Row/Slider/Ticks if has_node("VBoxContainer/HBoxContainer/Ticks") else null

const PHASE_SELECT := 0
const PHASE_SLEEP  := 1
const PHASE_DONE   := 2
var _phase: int = PHASE_SELECT

var _target_day:  int
var _target_hour: int
var _target_min:  int

func make_sb(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	# Button padding
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _style_buttons() -> void:
	# Noir palette
	var c_bg      := Color(0.17, 0.18, 0.20)
	var c_bg_hov  := Color(0.22, 0.23, 0.26)
	var c_bg_pr   := Color(0.14, 0.15, 0.17)
	var c_border  := Color(0.36, 0.37, 0.42)
	var c_focus   := Color(0.83, 0.75, 0.56) # warm highlight
	var c_text    := Color(0.92, 0.93, 0.96)

	var sb_norm := make_sb(c_bg,     c_border, 1)
	var sb_hov  := make_sb(c_bg_hov, c_border, 1)
	var sb_pr   := make_sb(c_bg_pr,  c_border, 1)
	var sb_foc  := make_sb(c_bg,     c_focus,  2)

	for b in [get_ok_button(), get_cancel_button()]:
		if b == null:
			continue
		b.custom_minimum_size = Vector2(108, 36)

		# Styleboxes
		b.add_theme_stylebox_override("normal",  sb_norm)
		b.add_theme_stylebox_override("hover",   sb_hov)
		b.add_theme_stylebox_override("pressed", sb_pr)
		b.add_theme_stylebox_override("focus",   sb_foc)

		# Text colors
		b.add_theme_color_override("font_color",           c_text)
		b.add_theme_color_override("font_hover_color",     Color.WHITE)
		b.add_theme_color_override("font_pressed_color",   Color.WHITE)
		b.add_theme_color_override("font_focus_color",     Color.WHITE)
		b.add_theme_color_override("font_disabled_color",  Color(0.60, 0.62, 0.66))

func _ready() -> void:
	dialog_hide_on_ok = false
	min_size = Vector2(560, 180)  # a bit wider for clearer ticks

	hide()
	canceled.connect(_on_closed)
	close_requested.connect(_on_closed)
	confirmed.connect(_on_confirmed)

	# Slider: 30-min steps up to 24h
	slider.min_value = 1
	slider.max_value = 48
	slider.step = 1
	slider.value = 16
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Optional built-in ticks (we draw custom ones anyway)
	slider.tick_count = 0
	slider.ticks_on_borders = false
	slider.value_changed.connect(_on_slider_changed)

	# Keep the amount label from reflowing when “30m” → “8h 0m” etc.
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_lbl.custom_minimum_size = Vector2(90, 0) # fixed width envelope

	# Live updates while dialog is shown
	GameState.time_changed.connect(_on_time_changed)
	GameState.fast_forward_completed.connect(_on_ff_done)
	
	# Style the buttons
	_style_buttons()
	
	# Align custom tick overlay with the slider's drawable area.
	if ticks:
		ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := slider.get_theme_stylebox("slider")
		if sb:
			# compensate for trough insets so ticks line up with handle travel
			ticks.set("pad_left",  int(sb.get_margin(SIDE_LEFT)))
			ticks.set("pad_right", int(sb.get_margin(SIDE_RIGHT)))

	_refresh_labels()

func open_dialog() -> void:
	_phase = PHASE_SELECT
	var ok := get_ok_button()
	var cancel := get_cancel_button()
	ok.text = "Sleep"
	ok.disabled = false
	cancel.disabled = false
	cancel.visible = true
	slider.editable = true
	GameState.paused = true
	_refresh_labels()
	popup_centered()

func _on_confirmed() -> void:
	match _phase:
		PHASE_SELECT:
			_start_sleep()
		PHASE_SLEEP:
			pass
		PHASE_DONE:
			_phase = PHASE_SELECT
			GameState.paused = false
			hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _start_sleep() -> void:
	_phase = PHASE_SLEEP
	get_ok_button().text = "Sleeping…"
	get_ok_button().disabled = true
	get_cancel_button().disabled = true
	get_cancel_button().visible = false
	slider.editable = false

	var d := GameState.day
	var h := GameState.hour
	var m := GameState.minute
	var minutes_ahead := int(slider.value) * 30

	var total := h * 60 + m + minutes_ahead
	_target_day  = d + int(total / 1440)
	var tgt_total := total % 1440
	_target_hour = int(tgt_total / 60)
	_target_min  = tgt_total % 60

	# <<< constant 5s skip, regardless of minutes_ahead
	GameState.start_fast_forward_offset(minutes_ahead, 5.0)

func _on_closed() -> void:
	# If user cancels while selecting, just unpause.
	# If they cancel during/after sleep, also unpause (graceful exit).
	GameState.paused = false
	get_cancel_button().visible = true
	hide()
	_phase = PHASE_SELECT

func _on_ff_done() -> void:
	_phase = PHASE_DONE
	get_ok_button().text = "Continue"
	get_ok_button().disabled = false
	get_cancel_button().visible = false
	# Keep dialog visible until the player confirms.

func _on_time_changed(d: int, h: int, m: int) -> void:
	if visible:
		now_lbl.text = "Now:   Day %d — %02d:%02d" % [d, h, m]
		target_lbl.text = "Until: Day %d — %02d:%02d" % [_target_day, _target_hour, _target_min]

func _on_slider_changed(_v: float) -> void:
	_refresh_labels()

func _refresh_labels() -> void:
	var d := GameState.day
	var h := GameState.hour
	var m := GameState.minute
	now_lbl.text = "Now:   Day %d — %02d:%02d" % [d, h, m]

	var steps := int(slider.value)
	var mins_ahead := steps * 30
	var total := (h * 60 + m + mins_ahead)
	var day_add := int(total / 1440)
	var tgt_total := total % 1440
	var th := int(tgt_total / 60)
	var tm := tgt_total % 60

	var ah := int(mins_ahead / 60)
	var am := mins_ahead % 60
	# zero-pad to keep the label width stable (works with our fixed min size)
	amount_lbl.text = "%02dh %02dm" % [ah, am]
	target_lbl.text = "Until: Day %d — %02d:%02d" % [d + day_add, th, tm]
