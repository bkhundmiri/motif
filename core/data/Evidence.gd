extends Resource

## Generic evidence container used by the case board and inventory.
## Type-specific data goes in `metadata`.

@export var id: String = ""
@export var case_id: String = ""
@export var type: String = ""        # e.g., "fingerprint", "weapon", "note", "dna"
@export var location: String = ""    # world uid: "block_03:apt_2b:kitchen"
@export var created_at_game_min: int = 0

# Arbitrary payload per evidence type (see docs per type)
@export var metadata: Dictionary = {}

# Chain of custody entries: [{who:String, when:int, action:String}]
@export var chain_of_custody: Array[Dictionary] = []

func add_custody_entry(who: String, when_min: int, action: String) -> void:
	chain_of_custody.append({
		"who": who,
		"when": when_min,
		"action": action
	})
