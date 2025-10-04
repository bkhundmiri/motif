extends Resource

## Minimal crime model; generation fills this, gameplay mutates it.

@export var id: String = ""
@export var type: String = ""             # "theft","burglary","assault","murder"
@export_range(1, 5, 1) var severity: int = 1

@export var culprit_npc_id: String = ""
@export var victim_npc_id: String = ""

@export var location_anchor: String = ""  # e.g., building/room anchor
@export var time_window := { "start": 0, "end": 0 } # game minutes

@export var evidence_ids: PackedStringArray = []
@export var status: String = "open"       # "open","solved","failed"

@export var seed: int = 0

func is_active(now_min: int) -> bool:
	return now_min >= int(time_window.get("start", 0)) and (int(time_window.get("end", 0)) == 0 or now_min <= int(time_window.get("end", 0)))
