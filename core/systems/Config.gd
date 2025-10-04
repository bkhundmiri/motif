extends Node

var city_seed: int = 0
var start_time_min: int = 8
var neighborhood_name: String = "Unknown"
var blocks: int = 16

func _ready():
	var ok := _load_seed("res://data/seeds/default_city_seed.json")
	if ok:
		Rand.seed_from_int(city_seed)
		print("[Config] Seed loaded:", city_seed, " | Blocks:", blocks, " | Start:", start_time_min, " | Hood:", neighborhood_name)
	else:
		push_warning("[Config] Failed to load seed. Using defaults.")
		Rand.seed_from_int(123456)
	
func _load_seed(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return false
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY: return false
	city_seed = int(d.get("city_seed", 123456))
	blocks = int(d.get("blocks", 16))
	start_time_min = int(d.get("start_time_min", 8))
	neighborhood_name = str(d.get("neighborhood_name", "Halcyon Ward"))
	return true
