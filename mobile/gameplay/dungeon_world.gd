extends RefCounted
## Deterministic unbounded dungeon geometry. No persistent chunk state is needed.
const CHUNK := 256
const TILE := 16
const PILLAR_RADIUS := 12.0
const MODULUS := 2147483647

static func chunk_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CHUNK), floori(point.y / CHUNK))

static func sample(seed: int, x: int, y: int, channel: int = 0) -> int:
	# Reduce coordinates before multiplying to keep all arithmetic in signed int64.
	var n: int = posmod(posmod(seed, MODULUS) + posmod(x, MODULUS) * 73856093 + posmod(y, MODULUS) * 19349663 + channel * 83492791, MODULUS)
	n = posmod(n * 48271 + 1, MODULUS)
	n = posmod(n * 48271 + 17, MODULUS)
	return n

static func pillar(seed: int, chunk: Vector2i) -> Dictionary:
	# Sparse pillars, at least 48px from every chunk edge; all chunk borders stay traversable.
	if sample(seed, chunk.x, chunk.y, 1) % 100 >= 60:
		return {}
	var offset := Vector2(48 + sample(seed, chunk.x, chunk.y, 2) % 161, 48 + sample(seed, chunk.x, chunk.y, 3) % 161)
	return {"pos": Vector2(chunk) * CHUNK + offset, "radius": PILLAR_RADIUS}

static func clear_at(seed: int, point: Vector2, radius: float) -> bool:
	var first := chunk_at(point - Vector2.ONE * (radius + PILLAR_RADIUS))
	var last := chunk_at(point + Vector2.ONE * (radius + PILLAR_RADIUS))
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var obstacle := pillar(seed, Vector2i(x, y))
			if not obstacle.is_empty() and point.distance_squared_to(obstacle.pos) < pow(radius + PILLAR_RADIUS, 2):
				return false
	return true

static func move(seed: int, point: Vector2, displacement: Vector2, radius: float) -> Vector2:
	# Axis sliding is sufficient for sparse circular obstacles at a fixed 60Hz step.
	var result := point
	var next := result + Vector2(displacement.x, 0)
	if clear_at(seed, next, radius): result = next
	next = result + Vector2(0, displacement.y)
	if clear_at(seed, next, radius): result = next
	return result

static func enemy_move(seed: int, point: Vector2, displacement: Vector2, radius: float, steer_sign: float) -> Vector2:
	var result := move(seed, point, displacement, radius)
	if result.distance_squared_to(point) < displacement.length_squared() * 0.20:
		# Slide around a pillar rather than staying stuck when walking directly into it.
		var tangent := displacement.orthogonal() * steer_sign
		result = move(seed, point, tangent, radius)
		if result.distance_squared_to(point) < displacement.length_squared() * 0.05:
			result = move(seed, point, -tangent, radius)
	return result
