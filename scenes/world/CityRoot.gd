extends Node

const EvidenceFactory = preload("res://scripts/forensics/EvidenceFactory.gd")
const CrimeGen        = preload("res://scripts/crimegen/CrimeGen.gd")
const Crime           = preload("res://core/data/Crime.gd")
const Evidence        = preload("res://core/data/Evidence.gd")
const WeaponRes       = preload("res://core/data/Weapon.gd")
const DebugOverlay    = preload("res://scenes/ui/DebugOverlay.tscn")
const EvidenceViewer  = preload("res://scenes/ui/EvidenceViewer.tscn")

var crimegen := CrimeGen.new()
var ev_factory := EvidenceFactory.new()

var _overlay: Control
var _crimes: Array[Crime] = []
var _last_fprint_id := ""
var _last_weapon_id := ""
var _last_location := ""
var _viewer: Window

var _npc_ids: Array[String] = ["npc_101","npc_202","npc_303"]
var _loc_ids: Array[String] = [
	"block_01:bldg_02:apt_2b:kitchen",
	"block_03:bar_1:backroom",
	"block_02:alley_5"
]

func _ready() -> void:
	set_process_input(true)

	_ensure_input_actions()
	_load_templates_with_fallback()

	# Overlay
	_overlay = DebugOverlay.instantiate()
	add_child(_overlay)
	_overlay.top_level = true
	_overlay.z_index = 1024
	# Safety: if the scene was saved without its script, attach it.
	if not _overlay.get_script():
		_overlay.set_script(load("res://scenes/ui/DebugOverlay.gd"))

	# Bootstrap: one crime so overlay has data
	_spawn_crime()
	_refresh_overlay()

func _ensure_input_actions() -> void:
	if not InputMap.has_action("spawn_crime"):
		InputMap.add_action("spawn_crime")
	if InputMap.action_get_events("spawn_crime").is_empty():
		var ev_g := InputEventKey.new()
		ev_g.keycode = KEY_G
		InputMap.action_add_event("spawn_crime", ev_g)

	if not InputMap.has_action("toggle_overlay"):
		InputMap.add_action("toggle_overlay")
	if InputMap.action_get_events("toggle_overlay").is_empty():
		var ev_h := InputEventKey.new()
		ev_h.keycode = KEY_H   # avoid F1 capture by OS/editor
		InputMap.action_add_event("toggle_overlay", ev_h)
		
	if not InputMap.has_action("open_evidence_viewer"):
		InputMap.add_action("open_evidence_viewer")
	if InputMap.action_get_events("open_evidence_viewer").is_empty():
		var ev_e := InputEventKey.new()
		ev_e.keycode = KEY_E
		InputMap.action_add_event("open_evidence_viewer", ev_e)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_crime"):
		_spawn_crime()
		_refresh_overlay()
	elif event.is_action_pressed("toggle_overlay"):
		_toggle_overlay()
	elif event.is_action_pressed("open_evidence_viewer"):
		_open_evidence_viewer()

func _toggle_overlay() -> void:
	if _overlay == null:
		return
	var new_vis := not _overlay.visible
	_overlay.visible = new_vis
	var panel := _overlay.get_node_or_null("Panel") as Panel
	if panel:
		panel.visible = new_vis
	var lbl := _overlay.get_node_or_null("Panel/Info") as Label
	if lbl:
		lbl.visible = new_vis

func _load_templates_with_fallback() -> void:
	crimegen.templates = _load_json_array("res://data/tables/crime_templates.json")
	if crimegen.templates.is_empty():
		# Silent fallback so the PoC always runs
		crimegen.templates = [
			{"type":"theft",    "severity":1, "zone_mask":["residential","commercial"]},
			{"type":"burglary", "severity":2, "zone_mask":["residential"]},
			{"type":"assault",  "severity":3, "zone_mask":["commercial","industrial"]},
			{"type":"murder",   "severity":4, "zone_mask":["residential","industrial","commercial"]}
		]

func _spawn_crime() -> void:
	var crime_res: Resource = crimegen.plan_crime(
		_npc_ids, _loc_ids, Config.city_seed + _crimes.size()
	)
	if crime_res == null:
		push_warning("[CityRoot] Could not plan crime.")
		return

	var crime: Crime = crime_res as Crime
	_last_location = crime.location_anchor

	# Culprit fingerprint + weapon evidence with that print
	var culprit: String = crime.culprit_npc_id
	var fprint: Evidence = ev_factory.make_fingerprint_evidence(
		culprit, crime.location_anchor, 0.85, crime.id
	)
	var weapon_res: WeaponRes = _make_dummy_weapon()
	var weapon_ev: Evidence = ev_factory.make_weapon_evidence(
		weapon_res, crime.location_anchor, crime.id, PackedStringArray([fprint.id])
	)

	crime.evidence_ids = [fprint.id, weapon_ev.id]
	_last_fprint_id = fprint.id
	_last_weapon_id = weapon_ev.id
	_crimes.append(crime)
	print("[CityRoot] Crime:", crime.id, crime.type, "at", crime.location_anchor, "| Evidence:", fprint.id, weapon_ev.id)
	
func _open_evidence_viewer() -> void:
	if _crimes.is_empty(): return
	var crime: Crime = _crimes[_crimes.size() - 1]

	# pull last evidence (created in _spawn_crime)
	var fprint_id := _last_fprint_id
	var weapon_id := _last_weapon_id
	if fprint_id == "" or weapon_id == "":
		push_warning("[EvidenceViewer] No evidence available.")
		return

	# Reconstruct the last evidence Resources quickly from the data we have.
	# (In a fuller system, you'd fetch from an EvidenceStore.)
	var fprint_ev := Evidence.new()
	fprint_ev.id = fprint_id
	fprint_ev.case_id = crime.id
	fprint_ev.type = "fingerprint"
	fprint_ev.location = crime.location_anchor
	fprint_ev.metadata = {
		# Use the same generator logic as EvidenceFactory
		"template": _gen_template_from_id(fprint_id, 0.85),
		"quality": 0.85
	}

	var weapon_ev := Evidence.new()
	weapon_ev.id = weapon_id
	weapon_ev.case_id = crime.id
	weapon_ev.type = "weapon"
	weapon_ev.location = crime.location_anchor
	weapon_ev.metadata = {
		"weapon_id": "wpn_knife_01",
		"weapon_type": "knife",
		"display_name": "Kitchen Knife"
	}

	# Culprit template (derived from culprit id) vs decoy template (random)
	var culprit_seed := hash(crime.culprit_npc_id) ^ int(Time.get_unix_time_from_system()) & 0x7fffffff
	var decoy_seed   := randi()

	var culprit_tpl := _gen_template_from_seed(culprit_seed, 0.9)
	var decoy_tpl   := _gen_template_from_seed(decoy_seed, 0.9)

	if _viewer == null:
		_viewer = EvidenceViewer.instantiate()
		add_child(_viewer)

	# Call the viewer
	_viewer.call("show_evidence", crime, fprint_ev, weapon_ev, culprit_tpl, decoy_tpl)

# Helpers (same math as EvidenceFactory local generator)
func _gen_template_from_seed(seed: int, quality: float) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var q: float = clamp(quality, 0.0, 1.0)
	var count := 25 + int(q * 25.0)
	var pts: Array[Vector3] = []
	for i in range(count):
		pts.append(Vector3(r.randf(), r.randf(), r.randf() * TAU))
	return {"template_hash": "%s_%s" % [seed, count], "minutiae": pts}

func _gen_template_from_id(id_str: String, quality: float) -> Dictionary:
	# simple deterministic seed based on ID string
	return _gen_template_from_seed(int(hash(id_str) & 0x7fffffff), quality)

func _refresh_overlay() -> void:
	if _overlay == null:
		return
	var lines: Array[String] = []
	lines.append("Motif  —  Debug  Overlay             (H toggles)")
	lines.append("------------------------------------------------")
	lines.append("Seed: %d      Blocks: %d   Start: %d:00   Hood: %s"
		% [Config.city_seed, Config.blocks, Config.start_time_min, Config.neighborhood_name])
	lines.append("Crimes spawned: %d" % _crimes.size())
	if _crimes.size() > 0:
		var last: Crime = _crimes[_crimes.size() - 1]
		lines.append("Last Crime: %s    Type: %s    Loc: %s" % [last.id, last.type, _last_location])
		lines.append("Evidence:  Fingerprint=%s    Weapon=%s" % [_last_fprint_id, _last_weapon_id])
	lines.append("")
	lines.append("[G]  Spawn crime      |      [H]  Toggle overlay")
	_overlay.call("set_lines", lines)  # safe even if typed differently

func _load_json_array(path: String) -> Array[Dictionary]:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	return (data as Array) if typeof(data) == TYPE_ARRAY else []

func _make_dummy_weapon() -> WeaponRes:
	var w := WeaponRes.new()
	w.id = "wpn_knife_01"
	w.weapon_type = "knife"
	w.display_name = "Kitchen Knife"
	w.serial = ""
	w.blood_trace = true
	return w
