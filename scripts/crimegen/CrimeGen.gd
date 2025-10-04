extends Node
const Crime = preload("res://core/data/Crime.gd")

var templates: Array[Dictionary] = []  # set this from JSON array

func plan_crime(npc_ids: Array[String], location_ids: Array[String], seedGen: int) -> Resource:
	var r := RandomNumberGenerator.new()
	r.seed = seedGen

	if templates.is_empty():
		push_warning("[CrimeGen] No templates loaded.")
		return null

	var tpl: Dictionary = templates[r.randi() % templates.size()]

	var c := Crime.new()
	c.id = "crime_%d" % seedGen
	c.type = str(tpl.get("type", "theft"))
	c.severity = int(tpl.get("severity", 1))

	if npc_ids.is_empty():
		c.culprit_npc_id = ""
		c.victim_npc_id = ""
	else:
		c.culprit_npc_id = npc_ids[r.randi() % npc_ids.size()]
		c.victim_npc_id  = npc_ids[r.randi() % npc_ids.size()]

	c.location_anchor = location_ids[r.randi() % max(1, location_ids.size())] if not location_ids.is_empty() else "bldg_0:0:0"
	c.time_window = {"start": 60, "end": 0}
	c.seed = seedGen
	return c
