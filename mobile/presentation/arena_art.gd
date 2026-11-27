extends RefCounted
## Original 16x16 pixel matrices. Cached once, no per-frame texture allocation.
const PATTERNS := [["................",".......o....o...",".....ogo..ogo...","....oggggggggo..","....oglhhhlggo..","......ogegego...",".....oggggggo...",".......ogttgo...",".......oaaaao...",".....oaaadaao...","....ogoaadaogo..","....ogoaadaogo..",".......oaaoao...",".......ob..bo...",".....obb..bbo...","................"],["................","....o........o..","...obo......obo.","....obo....obo..","..o...oboooobo..","..ob..obbbbbbo..","....oobbhhbbbo..",".....obberebbo..","....oobbrrrrbo..","..ob..obbbbbbo..","..o..oobbbbooo..","....obo....obo..","....obo....obo..",".....o......o...","................","................"],[".......oooooo...","......oggggggo..",".....oghhhhhgo..","...ogggggggggo..","....ogeggggego..","....ogtggggtgo..",".....oggggggo...","....ooaaaaaaoo..","...ogaaaadaago..","...ogaaaddaago..","..oggoaaddaoggo.","..oggoaaaaoggo..",".....oaaaoaaao..",".....obboobbo...","....obbb..bbbo..","................"],["...o..........o.","...oro......oro.","...orro....orro.","....orro..orro..",".....oroooooro..","...oorrhhhrroo..","...orrrererrro..","..orrrrrrrrrrro.",".orrrrortrorrro.","orrrorrrrrorrro.","..oroorrrrroro..","...o..orrro..o..","........orrro...","......orotoro...",".....ooo...ooo..","................"]]
const WARLOCK := ["................",".......oo.......","......ovvo......",".....ovvvvo.....","....ovvvvvvo....","....ovveevvo....",".....ovvvvo.....","......oooo......",".....ovvvvo...o.","....ovvhhvvo.oeo","....ovvvvvvo..o.","...ovvvhvvvvo.o.","...ovvvvvvvvo.o.",".....oooooo...o.",".....oo..oo...o.","................"]
const PALETTES := [
	{"o":"#17171f","g":"#65844c","h":"#a5b96c","l":"#445a38","e":"#ffdf91","t":"#ded2a3","a":"#594438","d":"#a18151","b":"#383039"},
	{"o":"#17151f","b":"#785064","h":"#9c7281","e":"#ffca78","r":"#c25b61"},
	{"o":"#17171f","g":"#72804f","h":"#a7aa67","e":"#f2d48a","t":"#ebd6aa","a":"#575866","d":"#96939b","b":"#3b3438"},
	{"o":"#211821","r":"#a84c4c","h":"#d67857","e":"#ffdf85","t":"#f1d49e"}
]
var enemies: Array[Texture2D] = []
var walk_frames: Array[Texture2D] = []
var poses: Dictionary = {}
var floor_texture: Texture2D
var projectiles: Dictionary = {}

func _init() -> void:
	for i in range(PATTERNS.size() + 1):
		enemies.append(ImageTexture.create_from_image(enemy_image(i)))
		walk_frames.append(ImageTexture.create_from_image(enemy_image(i,1)))
	floor_texture = ImageTexture.create_from_image(floor_image())
	for affinity in ["fire", "ice", "steam"]:
		projectiles[affinity] = ImageTexture.create_from_image(projectile_image(affinity))

static func enemy_image(kind: int,frame: int = 0) -> Image:
	var image := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var rows: Array = WARLOCK if kind == 4 else PATTERNS[kind]
	var palette: Dictionary = {"o":"#18131e","v":"#766091","h":"#ae8fc5","e":"#f7ce8c"} if kind == 4 else PALETTES[kind]
	assert(rows.size() == 16)
	for y in range(16):
		var row: String = rows[y]
		assert(row.length() == 16)
		for x in range(16):
			var token := row.substr(x, 1)
			if token == ".": continue
			assert(palette.has(token))
			image.set_pixel(x, y, Color(palette[token]))
	if frame==0: return image
	# Move separate limb/wing/robe regions one pixel, preserving the body silhouette.
	var animated := Image.create_empty(16,16,false,Image.FORMAT_RGBA8)
	animated.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			var pixel := image.get_pixel(x,y)
			if pixel.a==0: continue
			var dy := 0
			match kind:
				0,2:
					if y>=13: dy=-1 if x<8 else 1
				1:
					if x<5 or x>10: dy=-1 if x<8 else 1
				3:
					if x<5 or x>10: dy=-1
					elif y>=13: dy=1
				4:
					if y>=12 and x<13: dy=-1 if x<8 else 1
			animated.set_pixel(x,clampi(y+dy,0,15),pixel)
	return animated

## Motion state belongs only to presentation. Track actual traveled distance.
func reset_motion() -> void:
	poses.clear()

func update_motion(current: Array[Dictionary]) -> void:
	var next: Dictionary = {}
	for e in current:
		var uid: int = int(e.uid)
		var pos: Vector2 = e.pos
		var old: Dictionary = poses.get(uid,{"pos":pos,"distance":0.0})
		var previous: Vector2 = old.pos
		var distance := previous.distance_to(pos)
		# A relocated enemy restarts its walk cycle instead of appearing to sprint.
		var phase := fposmod(float(old.distance)+distance,16.0) if distance<32.0 else 0.0
		next[uid]={"pos":pos,"distance":phase,"moving":distance>0.05 and distance<32.0}
	poses=next

static func floor_image() -> Image:
	# A single cached arena-sized image, built from repeating 16px stone tiles.
	var image := Image.create_empty(360, 448, false, Image.FORMAT_RGBA8)
	image.fill(Color("#201d29"))
	for y in range(0, 448, 16):
		for x in range(0, 360, 16):
			var index := floori(x / 16.0) + 3 * floori(y / 16.0)
			var base := Color("#302b38") if index % 3 == 0 else Color("#2b2733")
			image.fill_rect(Rect2i(x + 1, y + 1, mini(15, 359 - x), 15), base)
			image.fill_rect(Rect2i(x + 1, y + 1, mini(14, 359 - x), 1), Color("#383240"))
			if index % 7 == 0 and x + 12 < 360:
				image.set_pixel(x + 6, y + 7, Color("#211e29"))
				image.set_pixel(x + 7, y + 8, Color("#211e29"))
				image.set_pixel(x + 8, y + 8, Color("#211e29"))
	return image

static func projectile_image(affinity: String) -> Image:
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var edge := Color("#aa4740") if affinity == "fire" else (Color("#4684a0") if affinity == "ice" else Color("#7d688c"))
	var bright := Color("#ffad5c") if affinity == "fire" else (Color("#9ce6ee") if affinity == "ice" else Color("#c9bddc"))
	var core := Color("#fff1c0") if affinity == "fire" else Color("#edfaff")
	for y in range(8):
		for x in range(8):
			var d := absi(x - 3) + absi(y - 3)
			if d <= 4:
				image.set_pixel(x, y, edge if d >= 3 else (bright if d == 2 else core))
	if affinity == "fire":
		image.set_pixel(0, 5, bright)
		image.set_pixel(1, 5, edge)
	elif affinity == "ice":
		image.set_pixel(3, 0, core)
		image.set_pixel(3, 7, bright)
	else:
		image.set_pixel(7, 2, bright)
		image.set_pixel(0, 6, bright)
	return image

func draw_enemy(canvas: CanvasItem, enemy: Dictionary, elapsed: float) -> void:
	var kind := int(enemy.kind)
	var pos: Vector2 = enemy.pos
	var radius := float(enemy.radius)
	var size := radius * 2.7
	var shadow := Rect2(pos + Vector2(-radius, radius * 0.35), Vector2(radius * 2, radius * 0.65))
	canvas.draw_rect(shadow, Color(0.06, 0.05, 0.09, 0.5))
	var pose: Dictionary = poses.get(int(enemy.uid),{})
	var moving: bool = bool(pose.get("moving",false)) and float(enemy.get("freeze",0.0))<=0
	var alternate := moving and float(pose.get("distance",0.0))>=8.0
	var bob := -1.0 if alternate else 0.0
	var tint := Color.WHITE
	if enemy.slow > 0: tint = Color("#a8ddff")
	if float(enemy.get("freeze", 0.0)) > 0: tint = Color("#c4f5ff")
	if enemy.burn > 0: tint = tint.lerp(Color("#ffaf83"), 0.4)
	if enemy.attack == "charge": tint = tint.lerp(Color("#f9bd86"), 0.45)
	if elapsed < float(enemy.get("hit_until", 0.0)): tint = tint.lerp(Color("#fff3cb"), 0.75)
	var texture := walk_frames[kind] if alternate else enemies[kind]
	canvas.draw_texture_rect(texture, Rect2(pos - Vector2(size, size) / 2.0 + Vector2(0, bob), Vector2(size, size)), false, tint)
	if enemy.attack in ["web","bolt","breath","charge_windup"]:
		var glow := Color("#f3a35f")
		canvas.draw_arc(pos,radius+3,0,TAU,20,Color(glow,0.55),1.0)
	if enemy.burn > 0:
		var ember := pos+Vector2(radius*0.65,-radius*0.7-2*sin(elapsed*8.0))
		canvas.draw_rect(Rect2(ember,Vector2(2,3)),Color("#f7aa63"))
	if float(enemy.get("freeze", 0.0)) > 0:
		canvas.draw_arc(pos, radius + 4, 0, TAU, 12, Color("#bcecfb"), 1.5)
	if kind == 3:
		var bar := Rect2(pos + Vector2(-20, -size / 2.0 - 6), Vector2(40, 3))
		canvas.draw_rect(bar, Color("#452934"))
		var fraction := clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
		canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, 3)), Color("#df7265"))
