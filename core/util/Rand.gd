extends Node
# Note: no `class_name` here to avoid global class registration/collision.

var rng := RandomNumberGenerator.new()

func seed_from_int(i: int) -> void:
	rng.seed = int(i)

func choice(arr: Array):
	if arr.is_empty(): return null
	return arr[rng.randi() % arr.size()]

func rangef(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func rangei(a: int, b: int) -> int:
	return rng.randi_range(a, b)

func chance(p: float) -> bool:
	return rng.randf() < clamp(p, 0.0, 1.0)
