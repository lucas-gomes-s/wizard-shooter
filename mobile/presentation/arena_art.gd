extends RefCounted
## Original 16x16 pixel matrices. Cached once, no per-frame texture allocation.
const PATTERNS := [["................",".......o....o...",".....ogo..ogo...","....oggggggggo..","....oglhhhlggo..","......ogegego...",".....oggggggo...",".......ogttgo...",".......oaaaao...",".....oaaadaao...","....ogoaadaogo..","....ogoaadaogo..",".......oaaoao...",".......ob..bo...",".....obb..bbo...","................"],["................","....o........o..","...obo......obo.","....obo....obo..","..o...oboooobo..","..ob..obbbbbbo..","....oobbhhbbbo..",".....obberebbo..","....oobbrrrrbo..","..ob..obbbbbbo..","..o..oobbbbooo..","....obo....obo..","....obo....obo..",".....o......o...","................","................"],[".......oooooo...","......oggggggo..",".....oghhhhhgo..","...ogggggggggo..","....ogeggggego..","....ogtggggtgo..",".....oggggggo...","....ooaaaaaaoo..","...ogaaaadaago..","...ogaaaddaago..","..oggoaaddaoggo.","..oggoaaaaoggo..",".....oaaaoaaao..",".....obboobbo...","....obbb..bbbo..","................"],["...o..........o.","...oro......oro.","...orro....orro.","....orro..orro..",".....oroooooro..","...oorrhhhrroo..","...orrrererrro..","..orrrrrrrrrrro.",".orrrrortrorrro.","orrrorrrrrorrro.","..oroorrrrroro..","...o..orrro..o..","........orrro...","......orotoro...",".....ooo...ooo..","................"]]
const PALETTES := [
	{"o":"#17171f","g":"#65844c","h":"#a5b96c","l":"#445a38","e":"#ffdf91","t":"#ded2a3","a":"#594438","d":"#a18151","b":"#383039"},
	{"o":"#17151f","b":"#785064","h":"#9c7281","e":"#ffca78","r":"#c25b61"},
	{"o":"#17171f","g":"#72804f","h":"#a7aa67","e":"#f2d48a","t":"#ebd6aa","a":"#575866","d":"#96939b","b":"#3b3438"},
	{"o":"#211821","r":"#a84c4c","h":"#d67857","e":"#ffdf85","t":"#f1d49e"}
]
var enemies: Array[Texture2D] = []
var floor_texture: Texture2D
var projectiles: Dictionary = {}

func _init() -> void:
	for i in range(PATTERNS.size()):
		enemies.append(ImageTexture.create_from_image(enemy_image(i)))
	floor_texture = ImageTexture.create_from_image(floor_image())
	for affinity in ["fire", "ice", "steam"]:
		projectiles[affinity] = ImageTexture.create_from_image(projectile_image(affinity))

static func enemy_image(kind: int) -> Image:
	var image := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var rows: Array = PATTERNS[kind]
	var palette: Dictionary = PALETTES[kind]
	assert(rows.size() == 16)
	for y in range(16):
		var row: String = rows[y]
		assert(row.length() == 16)
		for x in range(16):
			var token := row.substr(x, 1)
			if token == ".": continue
			assert(palette.has(token))
			image.set_pixel(x, y, Color(palette[token]))
	return image

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
	var bob := -1.0 if int(elapsed * 8.0 + pos.x * 0.1) % 2 == 0 else 0.0
	var tint := Color.WHITE
	if enemy.slow > 0: tint = Color("#a8ddff")
	if enemy.burn > 0: tint = tint.lerp(Color("#ffaf83"), 0.4)
	canvas.draw_texture_rect(enemies[kind], Rect2(pos - Vector2(size, size) / 2.0 + Vector2(0, bob), Vector2(size, size)), false, tint)
	if kind == 3:
		var bar := Rect2(pos + Vector2(-20, -size / 2.0 - 6), Vector2(40, 3))
		canvas.draw_rect(bar, Color("#452934"))
		var fraction := clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
		canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, 3)), Color("#df7265"))
