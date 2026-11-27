extends RefCounted
## Generate only visible 256px chunks, and immediately evict distant textures.
const World = preload("res://gameplay/dungeon_world.gd")
const MAX_CACHED := 12
var cache: Dictionary = {}
var seed := 0

func reset(new_seed: int) -> void:
	seed = new_seed
	cache.clear()

static func chunk_image(world_seed: int, chunk: Vector2i) -> Image:
	var image := Image.create_empty(World.CHUNK, World.CHUNK, false, Image.FORMAT_RGBA8)
	image.fill(Color("#201d29"))
	for y in range(0, World.CHUNK, World.TILE):
		for x in range(0, World.CHUNK, World.TILE):
			var tx := chunk.x * 16 + floori(x / 16.0)
			var ty := chunk.y * 16 + floori(y / 16.0)
			var n := World.sample(world_seed, tx, ty)
			var base := Color("#302b38") if n % 3 == 0 else Color("#2b2733")
			image.fill_rect(Rect2i(x + 1, y + 1, 15, 15), base)
			image.fill_rect(Rect2i(x + 1, y + 1, 14, 1), Color("#383240"))
			if n % 7 == 0:
				image.set_pixel(x + 6, y + 7, Color("#211e29"))
				image.set_pixel(x + 7, y + 8, Color("#211e29"))
				image.set_pixel(x + 8, y + 8, Color("#211e29"))
			if n % 53 == 0:
				# Subtle decorative inlaid rune. It has no gameplay effect yet.
				image.fill_rect(Rect2i(x + 7, y + 4, 2, 8), Color("#594451"))
				image.fill_rect(Rect2i(x + 4, y + 7, 8, 2), Color("#594451"))
	return image

func prepare(view: Rect2) -> Array[Vector2i]:
	var first := World.chunk_at(view.position)
	var last := World.chunk_at(view.end - Vector2(0.01, 0.01))
	var keys: Array[Vector2i] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			keys.append(Vector2i(x, y))
	# Evict before creating new textures. Actual 360x448 viewport needs at most nine.
	for key in cache.keys():
		if not key in keys: cache.erase(key)
	for key in keys:
		if not cache.has(key):
			cache[key] = ImageTexture.create_from_image(chunk_image(seed, key))
	assert(cache.size() <= MAX_CACHED)
	return keys

func draw_world(canvas: CanvasItem, view: Rect2) -> void:
	var keys := prepare(view)
	for key in keys:
		var origin := Vector2(key) * World.CHUNK
		canvas.draw_texture(cache[key], origin)
	for key in keys:
		var obstacle := World.pillar(seed, key)
		if obstacle.is_empty(): continue
		var p: Vector2 = obstacle.pos
		canvas.draw_rect(Rect2(p + Vector2(-14, 4), Vector2(30, 13)), Color(0.07, 0.06, 0.10, 0.65))
		canvas.draw_rect(Rect2(p - Vector2(12, 12), Vector2(24, 24)), Color("#1b1922"))
		canvas.draw_rect(Rect2(p - Vector2(10, 10), Vector2(20, 20)), Color("#4d4654"))
		canvas.draw_rect(Rect2(p - Vector2(9, 9), Vector2(17, 4)), Color("#77707b"))
		canvas.draw_rect(Rect2(p + Vector2(6, -5), Vector2(3, 13)), Color("#34303d"))
		canvas.draw_rect(Rect2(p + Vector2(-8, 7), Vector2(16, 2)), Color("#302a36"))
