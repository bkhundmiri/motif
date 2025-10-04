extends Resource

@export var id: String = ""
@export var weapon_type: String = "knife"     # "knife","pistol","bat",...
@export var display_name: String = "Knife"
@export var serial: String = ""               # keep empty if unknown
@export var owner_npc_id: String = ""         # unknown for most crimes
@export var blood_trace: bool = false
@export var fingerprint_ids: PackedStringArray = [] # Evidence ids for prints attached
@export var ballistics_profile: String = ""   # future use for firearms
