extends Node
class_name GameManager

## Game Manager for Motif Detective Game
## Handles game state, time progression, and core systems

# Game time settings
@export var time_scale: float = 6.0  # 10 real minutes = 1 game hour (60/10 = 6)
@export var start_hour: int = 9      # Game starts at 9:00 AM
@export var start_minute: int = 0

# Game state
var current_day: int = 1
var current_hour: int
var current_minute: int
var is_sleeping: bool = false
var game_paused: bool = false
var ui_open: bool = false  # Track if any UI is open

# Signals for time changes
signal time_changed(day: int, hour: int, minute: int)
signal day_changed(day: int)
signal sleep_started()
signal sleep_ended()
signal ui_opened()
signal ui_closed()

# Internal time tracking
var real_time_elapsed: float = 0.0

# Auto-save system
var auto_save_timer: Timer
var auto_save_interval: float = 300.0  # 5 minutes
var game_save_path: String = "user://game_state.json"

func _ready():
	# Initialize game time
	current_hour = start_hour
	current_minute = start_minute
	
	# Set this as an autoload singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set up auto-save timer
	_setup_auto_save_timer()
	
	# Load saved game state
	_load_game_state()
	
	print("Game Manager initialized - Starting time: Day %d, %02d:%02d" % [current_day, current_hour, current_minute])
	emit_signal("time_changed", current_day, current_hour, current_minute)

func _process(delta):
	if game_paused or is_sleeping or ui_open:
		return
	
	# Accumulate real time
	real_time_elapsed += delta
	
	# Check if we should advance game time (every 10 real seconds = 1 game minute)
	var minutes_to_add = int(real_time_elapsed * time_scale / 60.0)
	
	if minutes_to_add > 0:
		advance_time(minutes_to_add)
		real_time_elapsed = 0.0

func advance_time(minutes: int):
	"""Advance the game time by the specified number of minutes"""
	current_minute += minutes
	
	# Handle minute overflow
	while current_minute >= 60:
		current_minute -= 60
		current_hour += 1
		
		# Handle hour overflow
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			emit_signal("day_changed", current_day)
	
	# Emit time change signal
	emit_signal("time_changed", current_day, current_hour, current_minute)

func _setup_auto_save_timer():
	"""Set up the 5-minute auto-save timer for game state"""
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	auto_save_timer.autostart = true
	add_child(auto_save_timer)
	print("GameManager auto-save timer set to %d minutes" % (auto_save_interval / 60))

func _on_auto_save_timer_timeout():
	"""Auto-save game state every 5 minutes"""
	_save_game_state()
	print("GameManager auto-save: %s" % get_full_time_string())

func get_time_string() -> String:
	"""Get formatted time string"""
	var period = "AM"
	var display_hour = current_hour
	
	# Convert to 12-hour format
	if current_hour == 0:
		display_hour = 12
	elif current_hour > 12:
		display_hour = current_hour - 12
		period = "PM"
	elif current_hour == 12:
		period = "PM"
	
	return "%d:%02d %s" % [display_hour, current_minute, period]

func get_day_string() -> String:
	"""Get formatted day string"""
	return "Day %d" % current_day

func get_full_time_string() -> String:
	"""Get full formatted time string"""
	return "%s - %s" % [get_day_string(), get_time_string()]

func sleep(hours: int = 8):
	"""Start sleep sequence"""
	if is_sleeping:
		return
	
	is_sleeping = true
	emit_signal("sleep_started")
	
	print("Sleeping for %d hours..." % hours)
	
	# Advance time by sleep duration
	advance_time(hours * 60)  # Convert hours to minutes
	
	# Complete sleep
	is_sleeping = false
	emit_signal("sleep_ended")
	
	print("Woke up at: %s" % get_full_time_string())

func pause_game():
	"""Pause the game time progression"""
	game_paused = true

func resume_game():
	"""Resume the game time progression"""
	game_paused = false

func open_ui():
	"""Called when any UI dialog opens"""
	ui_open = true
	emit_signal("ui_opened")

func close_ui():
	"""Called when any UI dialog closes"""
	ui_open = false
	emit_signal("ui_closed")

func sleep_with_duration(hours: float):
	"""Sleep for a specific duration with fast-forward effect"""
	if is_sleeping:
		return
	
	is_sleeping = true
	emit_signal("sleep_started")
	
	print("Sleeping for %.1f hours..." % hours)
	
	# Start fast-forward effect (5 seconds regardless of duration)
	_start_fast_forward_sleep(hours)

func _start_fast_forward_sleep(hours: float):
	"""Start the 5-second fast-forward sleep effect"""
	var minutes_to_advance = int(hours * 60)
	var fast_forward_duration = 5.0  # Always 5 seconds
	
	# Start the fast-forward timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.1  # Update every 0.1 seconds
	timer.timeout.connect(_on_fast_forward_tick.bind(minutes_to_advance, fast_forward_duration, timer))
	timer.start()
	
	# Track progress
	fast_forward_start_time = Time.get_time_dict_from_system()
	fast_forward_total_minutes = minutes_to_advance
	fast_forward_duration_seconds = fast_forward_duration
	fast_forward_timer = timer

# Variables for fast-forward tracking
var fast_forward_start_time: Dictionary
var fast_forward_total_minutes: int
var fast_forward_duration_seconds: float
var fast_forward_timer: Timer
var fast_forward_minutes_advanced: int = 0

func _on_fast_forward_tick(total_minutes: int, duration: float, timer: Timer):
	"""Handle each tick of the fast-forward effect"""
	var current_time = Time.get_time_dict_from_system()
	var elapsed_seconds = _calculate_elapsed_seconds(fast_forward_start_time, current_time)
	
	# Calculate how many minutes should have been advanced by now
	var target_minutes = int((elapsed_seconds / duration) * total_minutes)
	
	# Advance any remaining minutes
	if target_minutes > fast_forward_minutes_advanced:
		var minutes_to_add = target_minutes - fast_forward_minutes_advanced
		advance_time(minutes_to_add)
		fast_forward_minutes_advanced = target_minutes
	
	# Check if fast-forward is complete
	if elapsed_seconds >= duration:
		timer.queue_free()
		fast_forward_minutes_advanced = 0
		_complete_sleep()

func _calculate_elapsed_seconds(start_time: Dictionary, current_time: Dictionary) -> float:
	"""Calculate elapsed seconds between two time dictionaries"""
	var start_total = start_time.hour * 3600 + start_time.minute * 60 + start_time.second
	var current_total = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	# Handle day rollover
	if current_total < start_total:
		current_total += 24 * 3600
	
	return float(current_total - start_total)

func _complete_sleep():
	"""Complete the sleep sequence"""
	is_sleeping = false
	emit_signal("sleep_ended")
	print("Woke up at: %s" % get_full_time_string())

func set_time(day: int, hour: int, minute: int):
	"""Set the current game time"""
	current_day = day
	current_hour = hour
	current_minute = minute
	emit_signal("time_changed", current_day, current_hour, current_minute)

func _save_game_state():
	"""Save game state to disk"""
	var game_data = {
		"game_time": {
			"current_day": current_day,
			"current_hour": current_hour,
			"current_minute": current_minute
		},
		"version": 1,
		"saved_at": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(game_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_data))
		file.close()
	else:
		print("Error: Could not save game state")

func _load_game_state():
	"""Load game state from disk"""
	if not FileAccess.file_exists(game_save_path):
		print("No game state save file found, using defaults")
		return
	
	var file = FileAccess.open(game_save_path, FileAccess.READ)
	if not file:
		print("Error: Could not open game state file")
		return
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result != OK:
		print("Error: Could not parse game state file")
		return
	
	var game_data = json.data
	
	if game_data.has("game_time"):
		var time_data = game_data["game_time"]
		current_day = time_data.get("current_day", 1)
		current_hour = time_data.get("current_hour", 9)
		current_minute = time_data.get("current_minute", 0)
		print("Game state loaded from save file")

# Debug functions
func skip_to_time(hour: int, minute: int = 0):
	"""Skip to a specific time today (for testing)"""
	var target_minutes = hour * 60 + minute
	var current_minutes = current_hour * 60 + current_minute
	
	if target_minutes > current_minutes:
		advance_time(target_minutes - current_minutes)
	else:
		# Next day
		advance_time((24 * 60) - current_minutes + target_minutes)
