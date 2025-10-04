extends Node

var day: int = 1
var hour: int = 8
var minute: int = 0

# 1 game minute = 10 real seconds (normal pace). Adjust as you like.
var real_seconds_per_game_minute: float = 10.0

var time_multiplier: float = 1.0
var _accum: float = 0.0
var paused: bool = false

signal time_changed(day: int, hour: int, minute: int)
signal fast_forward_started()
signal fast_forward_completed()

# ---- New, simpler FF model: count down minutes remaining ----
var _ff_active: bool = false
var _ff_minutes_remaining: int = 0

func _ready() -> void:
	emit_signal("time_changed", day, hour, minute)
	set_process(true)

func _process(delta: float) -> void:
	# Pause stops normal time; still advance during fast-forward.
	if paused and not _ff_active:
		return

	_accum += delta
	var sec_per_min: float = real_seconds_per_game_minute / max(0.1, time_multiplier)
	while _accum >= sec_per_min:
		_accum -= sec_per_min
		_advance_one_minute()

func _advance_one_minute() -> void:
	advance_minutes(1)

	if _ff_active:
		_ff_minutes_remaining -= 1
		if _ff_minutes_remaining <= 0:
			_ff_active = false
			reset_multiplier()
			emit_signal("fast_forward_completed")

# ---- Public clock API ----
func set_time(d: int, h: int, m: int) -> void:
	day = max(1, d)
	hour = clamp(h, 0, 23)
	minute = clamp(m, 0, 59)
	emit_signal("time_changed", day, hour, minute)

func advance_minutes(m: int) -> void:
	var add = max(0, m)
	var total = hour * 60 + minute + add
	day += int(total / 1440)
	total = total % 1440
	hour = int(total / 60)
	minute = total % 60
	emit_signal("time_changed", day, hour, minute)

func set_time_multiplier(mult: float) -> void:
	time_multiplier = max(0.1, mult)

func reset_multiplier() -> void:
	time_multiplier = 1.0

# Example: start_fast_forward_offset(30, 5.0) => skip 30 in-game minutes over 5 real seconds.
func start_fast_forward_offset(minutes_ahead: int, desired_seconds: float = 5.0) -> void:
	var mins = clamp(minutes_ahead, 1, 24 * 60)  # clamp to [1, 1440]
	_ff_minutes_remaining = mins
	_ff_active = true

	# total_real_time = mins * real_seconds_per_game_minute / time_multiplier  => set to desired_seconds
	var mult = (mins * real_seconds_per_game_minute) / max(0.05, desired_seconds)
	set_time_multiplier(mult)

	emit_signal("fast_forward_started")

func is_fast_forwarding() -> bool:
	return _ff_active
