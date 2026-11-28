extends RefCounted
## Generate only visible 256px chunks, and immediately evict distant textures.
const World = preload("res://gameplay/dungeon_world.gd")
const Artifacts = preload("res://gameplay/artifact_catalog.gd")
const MAX_CACHED := 12
var cache: Dictionary = {}
var seed := 0

func reset(new_seed: int) -> void:
	seed = new_seed
	cache.clear()

## Visual districts are purely cosmetic and use a separate sample channel.
static func district(world_seed: int, chunk: Vector2i) -> int:
	return World.sample(world_seed,Vector2i(floori(chunk.x/3.0),floori(chunk.y/3.0)).x,Vector2i(floori(chunk.x/3.0),floori(chunk.y/3.0)).y,71)%3

static func chunk_image(world_seed: int, chunk: Vector2i) -> Image:
	var image := Image.create_empty(World.CHUNK,World.CHUNK,false,Image.FORMAT_RGBA8)
	image.fill(Color("#17151e"))
	var palettes := [
		[Color("#302c38"),Color("#37313d"),Color("#292632"),Color("#443c48"),Color("#201e29")],
		[Color("#2e3339"),Color("#363b40"),Color("#292d34"),Color("#444950"),Color("#20242b")],
		[Color("#343037"),Color("#3c353c"),Color("#2d292f"),Color("#4b4148"),Color("#242028")]
	]
	var palette: Array = palettes[district(world_seed,chunk)]
	for y in range(0,World.CHUNK,World.TILE):
		for x in range(0,World.CHUNK,World.TILE):
			var tx := chunk.x*16+floori(x/16.0)
			var ty := chunk.y*16+floori(y/16.0)
			var n := World.sample(world_seed,tx,ty,72)
			var detail := World.sample(world_seed,tx,ty,73)
			var base: Color = palette[n%3]
			image.fill_rect(Rect2i(x+1,y+1,15,15),base)
			image.fill_rect(Rect2i(x+1,y+1,14,1),palette[3])
			image.fill_rect(Rect2i(x+1,y+2,1,12),base.lightened(0.08))
			image.fill_rect(Rect2i(x+2,y+15,14,1),palette[4])
			image.fill_rect(Rect2i(x+15,y+2,1,13),palette[4])
			for i in range(3):
				var px := 3+posmod(detail+i*7,11)
				var py := 3+posmod(floori(detail/31.0)+i*3,11)
				image.set_pixel(x+px,y+py,base.lightened(0.06) if i%2==0 else base.darkened(0.14))
			if n%7==0:
				var cx := 4+detail%5
				for i in range(5):
					image.set_pixel(x+cx+i,y+5+floori(i/2.0),palette[4])
			if n%23==0:
				# Flat moss and worn stone fragments, not solid obstacles.
				var moss := Color("#3d4a42") if district(world_seed,chunk)==1 else Color("#414039")
				image.fill_rect(Rect2i(x+2,y+10,5,2),moss)
				image.fill_rect(Rect2i(x+3,y+8,2,3),moss.darkened(0.10))
				image.set_pixel(x+7,y+11,moss.lightened(0.10))
			if posmod(tx,8)==0 or posmod(ty,8)==0:
				image.fill_rect(Rect2i(x+2,y+2,12,1),base.lightened(0.12))
				image.fill_rect(Rect2i(x+2,y+13,12,1),base.darkened(0.15))
			if n%53==0:
				var rune := Color("#64536c")
				image.fill_rect(Rect2i(x+7,y+4,2,8),rune)
				image.fill_rect(Rect2i(x+4,y+7,8,2),rune)
				image.set_pixel(x+4,y+4,rune)
				image.set_pixel(x+11,y+11,rune)
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
		draw_pillar(canvas,p,World.sample(seed,key.x,key.y,74)%3)

## Short octagonal ruined columns; base footprint remains the existing radius 12.
static func draw_pillar(canvas: CanvasItem,p: Vector2,variant: int) -> void:
	var shadow := PackedVector2Array([p+Vector2(-12,5),p+Vector2(8,0),p+Vector2(21,11),p+Vector2(10,19),p+Vector2(-10,13)])
	canvas.draw_colored_polygon(shadow,Color(0.05,0.04,0.08,0.58))
	var base := PackedVector2Array([p+Vector2(-7,-12),p+Vector2(7,-12),p+Vector2(12,-7),p+Vector2(12,7),p+Vector2(7,12),p+Vector2(-7,12),p+Vector2(-12,7),p+Vector2(-12,-7)])
	canvas.draw_colored_polygon(base,Color("#24202c"))
	canvas.draw_polyline(PackedVector2Array([base[0],base[1],base[2],base[3],base[4],base[5],base[6],base[7],base[0]]),Color("#655a66"),1)
	canvas.draw_rect(Rect2(p+Vector2(-8,-15),Vector2(16,21)),Color("#4a424e"))
	canvas.draw_rect(Rect2(p+Vector2(-8,-15),Vector2(4,21)),Color("#635965"))
	canvas.draw_rect(Rect2(p+Vector2(4,-15),Vector2(4,21)),Color("#35303d"))
	canvas.draw_rect(Rect2(p+Vector2(-9,5),Vector2(18,4)),Color("#766874"))
	var top := PackedVector2Array([p+Vector2(-9,-15),p+Vector2(-5,-19),p+Vector2(5,-19),p+Vector2(9,-15),p+Vector2(5,-11),p+Vector2(-5,-11)])
	canvas.draw_colored_polygon(top,Color("#80727c"))
	canvas.draw_line(p+Vector2(-8,-15),p+Vector2(7,-15),Color("#a09599"),1)
	canvas.draw_line(p+Vector2(-3,-17),p+Vector2(2,-13),Color("#3c3444"),1)
	if variant==1:
		canvas.draw_rect(Rect2(p+Vector2(-5,-5),Vector2(2,8)),Color("#6f617b"))
		canvas.draw_rect(Rect2(p+Vector2(-7,-2),Vector2(6,2)),Color("#6f617b"))
	elif variant==2:
		canvas.draw_line(p+Vector2(-5,-8),p+Vector2(1,-4),Color("#211e28"),1)
		canvas.draw_line(p+Vector2(1,-4),p+Vector2(-2,4),Color("#211e28"),1)

## Render only sites belonging to the existing visible chunk cache.
func draw_sites(canvas: CanvasItem, claimed: Dictionary, encounter: Dictionary, remaining: int, elapsed: float, artifacts_enabled: bool = false) -> void:
	for chunk in cache.keys():
		var site := World.site(seed, chunk)
		if site.is_empty(): continue
		var p: Vector2 = site.pos
		var used: bool = claimed.has(site.id)
		var color := Color("#e4bb6e") if site.kind == "treasure" else (Color("#80d4ae") if site.kind == "healing" else (Color("#ae98e8") if site.kind == "arcane" else Color("#e18b66")))
		if artifacts_enabled and not used and Artifacts.is_cache(seed,site):
			color=Color("#d8a4ff")
			canvas.draw_arc(p,22,0,TAU,32,color,1.5)
			canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-29),p+Vector2(4,-23),p+Vector2(0,-17),p+Vector2(-4,-23)]),color)
		if used: color = Color("#625969")
		if not used:
			var pulse := 0.5 + 0.5 * sin(elapsed * 3.0)
			canvas.draw_circle(p, 18, Color(color, 0.06 + pulse * 0.05))
		if site.kind in ["treasure","guarded"]:
			canvas.draw_rect(Rect2(p+Vector2(-12,5),Vector2(27,7)),Color(0.05,0.04,0.08,0.65))
			canvas.draw_rect(Rect2(p-Vector2(12,8),Vector2(24,16)),Color("#17151e"))
			canvas.draw_rect(Rect2(p-Vector2(10,5),Vector2(20,12)),Color("#684638") if not used else Color("#39323d"))
			canvas.draw_rect(Rect2(p-Vector2(10,7),Vector2(20,6)),Color("#966746") if not used else Color("#4a414c"))
			for band in [-8,6]:
				canvas.draw_rect(Rect2(p+Vector2(band,-7),Vector2(2,14)),color.darkened(0.22))
			canvas.draw_rect(Rect2(p-Vector2(10,1),Vector2(20,2)),color.darkened(0.35))
			canvas.draw_rect(Rect2(p-Vector2(2,3),Vector2(4,6)),color)
			canvas.draw_rect(Rect2(p+Vector2(0,-1),Vector2(1,2)),Color("#1c1924"))
			if used:
				canvas.draw_rect(Rect2(p-Vector2(9,5),Vector2(18,5)),Color("#17151e"))
			else:
				canvas.draw_rect(Rect2(p+Vector2(-9,-7),Vector2(16,1)),color.lightened(0.18))
				if site.kind=="guarded":
					canvas.draw_arc(p,18,0,TAU,24,Color(color,0.8),1.0)
					if not encounter.is_empty() and encounter.id==site.id:
						for i in range(remaining):
							canvas.draw_rect(Rect2(p+Vector2(-7+i*6,-15),Vector2(4,3)),color)
		else:
			canvas.draw_rect(Rect2(p+Vector2(-11,6),Vector2(25,7)),Color(0.05,0.04,0.08,0.65))
			canvas.draw_rect(Rect2(p-Vector2(10,5),Vector2(20,16)),Color("#201c28"))
			canvas.draw_rect(Rect2(p-Vector2(8,3),Vector2(16,12)),Color("#5e5363"))
			canvas.draw_rect(Rect2(p-Vector2(6,6),Vector2(12,7)),Color("#837687"))
			canvas.draw_rect(Rect2(p+Vector2(-7,7),Vector2(14,2)),Color("#393340"))
			if site.kind=="healing":
				canvas.draw_rect(Rect2(p-Vector2(3,11),Vector2(6,13)),color)
				canvas.draw_rect(Rect2(p-Vector2(7,7),Vector2(14,5)),color)
				canvas.draw_rect(Rect2(p-Vector2(2,10),Vector2(2,10)),color.lightened(0.35))
			else:
				var hover := -floorf(1.5+1.5*sin(elapsed*3.0)) if not used else 0.0
				var c := p+Vector2(0,-7+hover)
				canvas.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-10),c+Vector2(6,0),c+Vector2(0,8),c+Vector2(-6,0)]),color)
				canvas.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-10),c,c+Vector2(-6,0)]),color.lightened(0.35))
				canvas.draw_colored_polygon(PackedVector2Array([c,c+Vector2(6,0),c+Vector2(0,8)]),color.darkened(0.35))
		if not used:
			var shimmer := int(elapsed*6.0+float(chunk.x+chunk.y))%4
			var sparkle := p+Vector2(-13+posmod(shimmer*9,27),-12-posmod(shimmer*5,8))
			canvas.draw_rect(Rect2(sparkle,Vector2(2,2)),color.lightened(0.25))
