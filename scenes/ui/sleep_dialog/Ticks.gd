extends Control

@export var steps: int = 48  # 48 steps (24h / 0.5h increments)

func _draw() -> void:
	if steps <= 0:
		return

	var w := size.x
	var h := size.y
	var step_w := w / steps

	for i in range(steps + 1):
		var x := i * step_w
		var is_hour := (i % 2 == 0)  # every 2nd step = full hour

		var line_h := h if is_hour else h * 0.5
		draw_line(Vector2(x, h), Vector2(x, h - line_h), Color.WHITE, 1.0)
