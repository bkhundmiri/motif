extends Resource

## Stable, deterministic description of an NPC generated from the city seed.

@export var id: String = ""
@export var name_first: String = ""
@export var name_last: String = ""

# Visual traits used for recognition & evidence/witness statements
@export var traits := {
	"height_cm": 175,
	"build": "average",                # "slim","average","heavy","muscular"
	"skin_tone": "med",
	"hair": {"style": "short", "color": "brown"},
	"eyes": "brown",
	"glasses": false,
	"facial_hair": "none",            # "none","stubble","mustache","beard"
	"scars": []                        # e.g., ["left_cheek_slash"]
}

# Forensics link (synthetic fingerprint template id/hash)
@export var fingerprint_template_hash: String = ""

# Daily routine waypoints (lightweight for MVP)
# [{hour:int, place_uid:String, activity:String}]
@export var routine: Array[Dictionary] = []

# Social/Noir hooks
@export var affiliations: PackedStringArray = []   # e.g., ["dockworkers_union","police","crime_family"]

func get_display_name() -> String:
	return ("%s %s" % [name_first, name_last]).strip_edges()
