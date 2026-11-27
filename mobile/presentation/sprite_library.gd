extends RefCounted
## Resolve independent atlas tiles using only the relevant expressed attributes.
const ATLAS = preload("res://assets/characters/prototype/layers.png")
const MANIFEST = "res://assets/characters/prototype/manifest.json"
var data: Dictionary
var entries: Array
var layer_order: Array
var cache: Dictionary = {}

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	assert(parsed is Dictionary)
	data = parsed
	entries = data.characters
	layer_order = data.layer_order

func tiles(p: Dictionary, frame: int) -> Array:
	var key := "%s|%s|%s|%s|%s|%s|%s" % [p.body, p.affinity, p.mutation, p.hat, p.robe, p.staff, frame]
	if cache.has(key):
		return cache[key]
	var result: Array = []
	for slot in layer_order:
		var tile := _find(p, str(slot), frame)
		assert(tile >= 0, "No matching sprite layer: %s / %s" % [slot, p])
		if tile >= 0:
			result.append(tile)
	cache[key] = result
	return result

func _find(p: Dictionary, slot: String, frame: int) -> int:
	# Stoneborn/hybrid share body and robe. Fae Steam robe 2 is absent
	# from the sampled atlas: choose robe 0 explicitly as a cosmetic fallback.
	var robe_variant := int(p.robe)
	if p.body == "fae" and p.affinity == "steam" and robe_variant == 2:
		robe_variant = 0
	for entry in entries:
		var q: Dictionary = entry.phenotype
		var same_rig: bool = (q.body == "fae") == (p.body == "fae")
		var same_affinity: bool = q.affinity == p.affinity
		var match_slot := false
		match slot:
			"body": match_slot = same_rig
			"head": match_slot = q.body == p.body and same_affinity
			"robe": match_slot = same_rig and same_affinity and int(q.robe) == robe_variant
			"hat": match_slot = same_affinity and int(q.hat) == int(p.hat)
			"staff": match_slot = same_affinity and int(q.staff) == int(p.staff)
			"wings": match_slot = same_affinity and (q.mutation == "crystal_wings") == (p.mutation == "crystal_wings")
			"mutation": match_slot = same_affinity and (q.mutation == "living_flame") == (p.mutation == "living_flame")
		if match_slot:
			return int(entry.frames[frame][slot])
	return -1

func draw_wizard(canvas: CanvasItem, p: Dictionary, feet: Vector2, frame: int, scale_factor: float = 1.0) -> void:
	var size := 32.0 * scale_factor
	var dst := Rect2(feet - Vector2(15, 29) * scale_factor, Vector2(size, size))
	for tile in tiles(p, frame):
		var n := int(tile)
		var source := Rect2(Vector2(n % 8, floori(n / 8.0)) * 32, Vector2(32, 32))
		canvas.draw_texture_rect_region(ATLAS, dst, source)
