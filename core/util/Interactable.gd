extends Area3D
class_name Interactable

@export var prompt: String = "Interact"
@export var action_id: String = ""  # e.g., "open_board" / "open_stash"

# Optional: visual focus feedback
func set_focused(f: bool) -> void:
	if has_node("Highlight"):
		$Highlight.visible = f
