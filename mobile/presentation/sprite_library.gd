extends RefCounted
## Resolve independent atlas tiles using only the relevant expressed attributes.
const ATLAS = preload("res://assets/characters/prototype/layers.png")
const MANIFEST = "res://assets/characters/prototype/manifest.json"
const Rig = preload("res://presentation/directional_rig.gd")
const MAX_POSES := 96
var atlas_pixels: Image
var pose_cache: Dictionary = {}
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
	atlas_pixels = ATLAS.get_image()
	atlas_pixels.convert(Image.FORMAT_RGBA8)

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

func pose_image(p: Dictionary,frame: int,direction: String,casting: bool = false) -> Image:
	var layers: Dictionary = {}
	var indices := tiles(p,frame)
	for i in range(layer_order.size()):
		var n := int(indices[i])
		var source := Rect2i(Vector2i(n%8,floori(n/8.0))*32,Vector2i(32,32))
		layers[str(layer_order[i])]=atlas_pixels.get_region(source)
	return Rig.compose(p,layers,direction,casting)

func pose_texture(p: Dictionary,frame: int,direction: String,casting: bool = false) -> Texture2D:
	# Key by resolved atlas indices and phenotype inputs used by the rear/profile composer.
	var key := "%s|%s|%s|%s|%s|%s" % [str(tiles(p,frame)),p.body,p.affinity,p.robe,direction,casting]
	if pose_cache.has(key): return pose_cache[key]
	if pose_cache.size()>=MAX_POSES: pose_cache.erase(pose_cache.keys()[0])
	var texture := ImageTexture.create_from_image(pose_image(p,frame,direction,casting))
	pose_cache[key]=texture
	return texture

func draw_actor(canvas: CanvasItem,p: Dictionary,feet: Vector2,frame: int,direction: String,casting: bool,scale_factor: float = 1.0) -> void:
	var texture := pose_texture(p,frame,direction,casting)
	var destination := Rect2(feet-Rig.FEET*scale_factor,Vector2.ONE*32.0*scale_factor)
	canvas.draw_texture_rect(texture,destination,false)
