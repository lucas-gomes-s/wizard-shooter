extends RefCounted
## Directional pose composer using existing independent inherited pixel layers.
## 32x32 canvas, common feet anchor (15,29). South retains the original art.
const INK := Color("#191923")
const PALETTES := {
	"fire":[Color("#522d3c"),Color("#a34441"),Color("#ed7950"),Color("#ffce82")],
	"ice":[Color("#293d57"),Color("#416c88"),Color("#76b9d2"),Color("#c9f4f1")],
	"steam":[Color("#453950"),Color("#766681"),Color("#a3a5b5"),Color("#e0e9e5")]
}
const DIRECTIONS := ["south","north","east","west"]
const SIZE := 32
const FEET := Vector2(15,29)

static func facing(delta: Vector2,previous: String = "south") -> String:
	if delta.length_squared()<0.0025: return previous
	# Small hysteresis at diagonal boundaries prevents flickering between poses.
	var ax := absf(delta.x)
	var ay := absf(delta.y)
	if ax>ay*1.12: return "east" if delta.x>0 else "west"
	if ay>ax*1.12: return "south" if delta.y>0 else "north"
	if previous in ["east","west"]: return "east" if delta.x>0 else "west"
	return "south" if delta.y>0 else "north"

static func blank() -> Image:
	var im := Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	return im

static func rect(im: Image,x: int,y: int,w: int,h: int,c: Color) -> void:
	im.fill_rect(Rect2i(x,y,w,h),c)

static func over(dst: Image,src: Image,offset: Vector2i = Vector2i.ZERO) -> void:
	# Explicitly clip offsets so casting pose offsets stay inside the common tile.
	var start := Vector2i(maxi(0,-offset.x),maxi(0,-offset.y))
	var end := Vector2i(mini(SIZE,SIZE-offset.x),mini(SIZE,SIZE-offset.y))
	if end.x>start.x and end.y>start.y:
		dst.blend_rect(src,Rect2i(start,end-start),start+offset)

static func narrow(src: Image,width: int,center: int = 15) -> Image:
	var im := src.duplicate() as Image
	im.resize(width,SIZE,Image.INTERPOLATE_NEAREST)
	var result := blank()
	result.blit_rect(im,Rect2i(0,0,width,SIZE),Vector2i(center-width/2,0))
	return result

static func profile_head(p: Dictionary) -> Image:
	var im := blank()
	var skin := Color("#d3bca3") if p.body=="fae" else Color("#9799a3")
	var shade := Color("#9a796d") if p.body=="fae" else Color("#6c6875")
	var palette: Array = PALETTES[p.affinity]
	# Right-facing nose and jaw; visible rear ear for fae/hybrid.
	rect(im,11,9,10,9,INK)
	rect(im,12,10,8,7,skin)
	rect(im,20,12,3,4,INK)
	rect(im,20,13,2,2,skin)
	rect(im,14,17,6,2,INK)
	rect(im,14,17,5,1,skin)
	rect(im,12,15,3,2,shade)
	if p.body!="stoneborn":
		rect(im,7,10,5,3,INK)
		rect(im,8,11,5,2,skin)
		rect(im,10,13,3,2,skin)
	else:
		rect(im,13,11,1,3,palette[1])
		rect(im,14,13,1,1,palette[1])
	rect(im,18,13,2,2,INK)
	rect(im,18,13,1,1,palette[3])
	return im

static func rear_head(p: Dictionary,original: Image) -> Image:
	var im := original.duplicate() as Image
	var skin := Color("#d3bca3") if p.body=="fae" else Color("#9799a3")
	var shade := Color("#9a796d") if p.body=="fae" else Color("#6c6875")
	# Keep the exact head/ear outline; remove both eyes and add rear shading.
	rect(im,10,12,11,5,skin)
	rect(im,11,16,9,1,shade)
	if p.body!="fae":
		var palette: Array=PALETTES[p.affinity]
		rect(im,12,12,1,3,palette[1])
		rect(im,13,14,2,1,palette[1])
		rect(im,18,13,1,2,palette[1])
	return im

static func rear_robe(p: Dictionary,original: Image) -> Image:
	var im := original.duplicate() as Image
	var palette: Array=PALETTES[p.affinity]
	# Replace front-facing trim and belt with a back seam or mantle, preserving variant.
	rect(im,10,17,11,9,palette[0])
	match int(p.robe):
		0:
			rect(im,14,17,3,9,palette[1])
			rect(im,15,18,1,7,palette[2])
		1:
			rect(im,10,17,11,3,palette[1])
			rect(im,12,20,7,2,palette[1])
			rect(im,14,22,3,3,palette[2])
		_:
			rect(im,10,19,11,2,palette[1])
			rect(im,10,25,11,1,palette[1])
	return im

static func compose(p: Dictionary,layers: Dictionary,direction: String,casting: bool) -> Image:
	assert(direction in DIRECTIONS)
	var out := blank()
	var staff_offset := Vector2i(0,-2) if casting else Vector2i.ZERO
	if direction=="south":
		for slot in ["wings","body","robe","head","hat","staff","mutation"]:
			over(out,layers[slot],staff_offset if slot=="staff" else Vector2i.ZERO)
	elif direction=="north":
		over(out,layers.staff,staff_offset)
		over(out,layers.body)
		over(out,rear_robe(p,layers.robe))
		over(out,layers.wings)
		over(out,rear_head(p,layers.head))
		over(out,layers.hat)
		over(out,layers.mutation)
	else:
		over(out,narrow(layers.wings,24))
		over(out,narrow(layers.body,22))
		over(out,narrow(layers.robe,24))
		over(out,profile_head(p))
		over(out,narrow(layers.hat,27,16))
		over(out,layers.staff,staff_offset)
		over(out,layers.mutation)
		if direction=="west":
			# Reflect about the common x=15 anchor (not 15.5).
			out.flip_x()
			var aligned := blank()
			over(aligned,out,Vector2i(-1,0))
			out=aligned
	return out
