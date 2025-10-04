extends Node
const Types    = preload("res://core/data/Types.gd")
const Evidence = preload("res://core/data/Evidence.gd")

# Local fingerprint generator (no external preload needed)
static func _generate_fingerprint_template(fingerSeed: int, quality: float = 0.9) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = fingerSeed
	var q: float = clamp(quality, 0.0, 1.0)
	var count: int = 25 + int(q * 25.0)
	var points: Array[Vector3] = []
	for _i in range(count):
		points.append(Vector3(r.randf(), r.randf(), r.randf() * TAU)) # x,y∈[0,1], theta∈[0,2π]
	return {
		"template_hash": "%s_%s" % [seed, count],
		"minutiae": points
	}

func make_fingerprint_evidence(npc_id: String, location_uid: String, quality: float, case_id: String) -> Evidence:
	var ev: Evidence = Evidence.new()
	ev.id = "ev_fgr_%s" % str(Time.get_unix_time_from_system())
	ev.case_id = case_id
	ev.type = Types.EVIDENCE_FINGERPRINT
	ev.location = location_uid
	ev.created_at_game_min = 0

	var t_now: int = int(Time.get_unix_time_from_system())
	var fingerSeed: int = hash(npc_id) ^ (t_now & 0x7fffffff)

	ev.metadata = {
		"npc_id": npc_id,
		"template": _generate_fingerprint_template(fingerSeed, quality),
		"quality": quality,
		"source_surface": "weapon_handle",
		"lift_method": "powder_lift"
	}
	return ev

func make_weapon_evidence(weapon_res: Resource, location_uid: String, case_id: String, fingerprint_ids: PackedStringArray) -> Evidence:
	var ev: Evidence = Evidence.new()
	ev.id = "ev_wpn_%s" % str(Time.get_unix_time_from_system())
	ev.case_id = case_id
	ev.type = Types.EVIDENCE_WEAPON
	ev.location = location_uid
	ev.created_at_game_min = 0

	var w_id := "wpn_unknown"
	var w_type := "unknown"
	var w_name := "Weapon"
	var w_serial := ""
	var w_blood := false

	if weapon_res:
		var vid = weapon_res.get("id")
		var vtype = weapon_res.get("weapon_type")
		var vname = weapon_res.get("display_name")
		var vserial = weapon_res.get("serial")
		var vblood = weapon_res.get("blood_trace")

		if vid != null:     w_id     = str(vid)
		if vtype != null:   w_type   = str(vtype)
		if vname != null:   w_name   = str(vname)
		if vserial != null: w_serial = str(vserial)
		if vblood != null:  w_blood  = bool(vblood)

	ev.metadata = {
		"weapon_id": w_id,
		"weapon_type": w_type,
		"display_name": w_name,
		"serial": w_serial,
		"blood_trace": w_blood,
		"fingerprints": fingerprint_ids
	}
	return ev
