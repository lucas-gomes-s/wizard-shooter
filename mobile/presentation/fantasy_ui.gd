extends RefCounted
## Shared pixel-inspired fantasy UI, independent of gameplay and save state.
const INK := Color("#100e17")
const STONE := Color("#282331")
const BRONZE := Color("#92734d")
const GOLD := Color("#e2c28a")
const IVORY := Color("#f2e7d4")
const MUTED := Color("#b9a9be")
const HP := Color("#ae394e")
const XP := Color("#7760c9")

static func style(fill: Color, edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(2)
	s.border_width_bottom = 3
	s.set_corner_radius_all(2)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	s.shadow_color = Color("#100e17")
	s.shadow_size = 2
	s.shadow_offset = Vector2(0,2)
	return s

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14
	for type in ["Button","OptionButton"]:
		t.set_stylebox("normal",type,style(Color("#352c40"),Color("#826b51")))
		t.set_stylebox("hover",type,style(Color("#4a3b55"),GOLD))
		t.set_stylebox("pressed",type,style(Color("#241e30"),Color("#c4a477")))
		t.set_stylebox("disabled",type,style(Color("#23212b"),Color("#48404a")))
		t.set_color("font_color",type,IVORY)
		t.set_color("font_hover_color",type,Color("#fff1cb"))
		t.set_color("font_pressed_color",type,GOLD)
		t.set_color("font_disabled_color",type,Color("#827989"))
	t.set_color("font_color","Label",IVORY)
	t.set_stylebox("panel","PopupPanel",style(STONE,BRONZE))
	t.set_stylebox("panel","PopupMenu",style(STONE,BRONZE))
	t.set_stylebox("hover","PopupMenu",style(Color("#453751"),GOLD))
	t.set_color("font_color","PopupMenu",IVORY)
	return t

static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal",style(Color("#514063"),Color("#c7a56e")))
	button.add_theme_stylebox_override("hover",style(Color("#665078"),GOLD))
	button.add_theme_stylebox_override("pressed",style(Color("#342840"),GOLD))

static func frame(canvas: CanvasItem, r: Rect2, accent: Color = BRONZE) -> void:
	canvas.draw_rect(Rect2(r.position+Vector2(2,3),r.size),INK)
	canvas.draw_rect(r,Color("#1c1726"))
	canvas.draw_rect(r.grow(-2),STONE)
	canvas.draw_rect(r,accent,false,1.0)
	canvas.draw_rect(r.grow(-4),Color("#494052"),false,1.0)
	for corner in [r.position,Vector2(r.end.x-5,r.position.y),Vector2(r.position.x,r.end.y-5),r.end-Vector2(5,5)]:
		canvas.draw_rect(Rect2(corner,Vector2(5,5)),accent)
		canvas.draw_rect(Rect2(corner+Vector2(1,1),Vector2(2,2)),GOLD)

static func fraction(value: float, maximum: float) -> float:
	return clampf(value / maximum,0.0,1.0) if maximum > 0 else 0.0

static func bar(canvas: CanvasItem,r: Rect2,value: float,maximum: float,hue: Color,trail: float = -1.0,flash: float = 0.0) -> void:
	canvas.draw_rect(r,INK)
	canvas.draw_rect(r.grow(-2),Color("#393042"))
	canvas.draw_rect(r,BRONZE,false,1.0)
	var inner := r.grow(-3)
	if trail >= 0:
		canvas.draw_rect(Rect2(inner.position,Vector2(inner.size.x*clampf(trail,0,1),inner.size.y)),hue.lightened(0.5))
	var width := floorf(inner.size.x*fraction(value,maximum))
	if width > 0:
		canvas.draw_rect(Rect2(inner.position,Vector2(width,inner.size.y)),hue)
		canvas.draw_rect(Rect2(inner.position,Vector2(width,2)),hue.lightened(0.4))
		canvas.draw_rect(Rect2(inner.position+Vector2(0,inner.size.y-2),Vector2(width,2)),hue.darkened(0.3))
	if flash>0: canvas.draw_rect(r.grow(-1),Color(GOLD,clampf(flash,0,1)),false,1.0)

static func text_at(canvas: CanvasItem,value: String,pos: Vector2,size: int,color: Color = IVORY,center: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var origin := pos
	if center: origin.x -= font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2.0
	canvas.draw_string(font,origin+Vector2(1,1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,INK)
	canvas.draw_string(font,origin,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

static func hall(canvas: CanvasItem,t: float) -> void:
	# Original procedural architecture, no external art or per-frame textures.
	canvas.draw_rect(Rect2(0,0,360,640),Color("#15121e"))
	for y in range(0,400,24):
		for x in range(-24,360,48):
			var p := Vector2(x+(24 if (y/24)%2==1 else 0),y)
			canvas.draw_rect(Rect2(p+Vector2(1,1),Vector2(46,22)),Color("#211c2b") if (x+y)%96==0 else Color("#1e1927"))
	for x in [12,314]:
		canvas.draw_rect(Rect2(x,20,34,354),Color("#100e17"))
		canvas.draw_rect(Rect2(x+4,22,26,350),Color("#322939"))
		canvas.draw_rect(Rect2(x+7,22,3,350),Color("#51424e"))
		for y in [22,350,365]:
			canvas.draw_rect(Rect2(x-4,y,42,9),Color("#625044"))
	for x in [76,284]:
		canvas.draw_rect(Rect2(x-18,28,36,88),Color("#4a2e51"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-18,116),Vector2(x,132),Vector2(x+18,116)]),Color("#4a2e51"))
		canvas.draw_line(Vector2(x-18,28),Vector2(x+18,28),BRONZE,3)
		canvas.draw_arc(Vector2(x,68),10,0,TAU,12,BRONZE,1)
	canvas.draw_rect(Rect2(0,350,360,290),Color("#191521"))
	for y in range(356,640,24):
		canvas.draw_line(Vector2(0,y),Vector2(360,y),Color("#282132"),1)
	var center := Vector2(180,292)
	canvas.draw_circle(center,76,Color(0.48,0.30,0.67,0.10))
	canvas.draw_arc(center,68,0,TAU,48,Color("#5c466f"),2)
	canvas.draw_arc(center,56,0,TAU,48,Color("#9776ad"),1)
	for i in range(12):
		var angle := i*TAU/12
		var p := center+Vector2.from_angle(angle)*63
		canvas.draw_rect(Rect2(p-Vector2(2,2),Vector2(4,4)),Color("#c09cdb"))
	for i in range(18):
		var point := Vector2(40+posmod(i*73,280),160+fposmod(float(i*47)-t*(7+i%3),175.0))
		canvas.draw_rect(Rect2(point,Vector2(2,2)),Color(0.78,0.60,0.94,0.2+0.2*sin(t*2+i)))
