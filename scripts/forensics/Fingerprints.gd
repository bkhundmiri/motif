extends Node

static func generate_template(seed: int, quality: float = 0.9) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var q: float = clamp(quality, 0.0, 1.0)
	var count: int = 25 + int(q * 25.0)
	var points: Array[Vector3] = []
	for _i in range(count):
		points.append(Vector3(r.randf(), r.randf(), r.randf() * TAU)) # x,y in [0,1], theta in [0,2π]
	return {
		"template_hash": "%s_%s" % [seed, count],
		"minutiae": points
	}

static func match_score(a: Dictionary, b: Dictionary) -> float:
	if a.is_empty() or b.is_empty():
		return 0.0
	var a_pts: Array = a.has("minutiae") ? a["minutiae"] : []
	var b_pts: Array = b.has("minutiae") ? b["minutiae"] : []
	if a_pts.is_empty() or b_pts.is_empty():
		return 0.0

	var mins: Array[float] = []
	for p_a in a_pts:
		var pa: Vector3 = p_a
		var best: float = 1e9
		for p_b in b_pts:
			var pb: Vector3 = p_b
			var d_xy: float = Vector2(pa.x, pa.y).distance_to(Vector2(pb.x, pb.y))
			var d_t: float = abs(wrapf(pa.z - pb.z, -PI, PI))
			var d: float = d_xy * 2.0 + d_t * 0.25
			if d < best:
				best = d
		mins.append(best)

	var avg: float = 0.0
	for val in mins:
		avg += val
	if mins.size() > 0:
		avg /= float(mins.size())

	return clamp(1.0 - avg, 0.0, 1.0)
