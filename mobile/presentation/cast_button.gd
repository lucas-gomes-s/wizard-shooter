extends Button
const Art = preload("res://presentation/pixel_ui_art.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
var glyph: Texture2D
var hue := Fantasy.GOLD
var remaining := 0.0
var duration := 1.0
var title := ""
var affinity := ""
var blocked := false

func configure(element: String,label: String,cooldown: float,maximum: float,is_blocked: bool) -> void:
	if affinity!=element:
		affinity=element
		hue=Color("#ef8052") if element=="fire" else (Color("#84d7e8") if element=="ice" else Color("#c7b7d8"))
		glyph=Art.icon(element,hue)
		add_theme_stylebox_override("normal",Fantasy.style(Color("#342a40"),hue.darkened(0.25)))
		add_theme_stylebox_override("hover",Fantasy.style(Color("#493750"),hue))
		add_theme_stylebox_override("pressed",Fantasy.style(Color("#231c2d"),hue))
	title=label
	remaining=maxf(0,cooldown)
	duration=maxf(0.01,maximum)
	blocked=is_blocked
	disabled=blocked or remaining>0
	tooltip_text=title
	queue_redraw()

func _draw() -> void:
	if glyph==null: return
	var center := Vector2(size.x/2.0,23)
	var tint := Color(1,1,1,0.4) if disabled else Color.WHITE
	draw_texture_rect(glyph,Rect2(center-Vector2(13.5,13.5),Vector2(27,27)),false,tint)
	draw_arc(center,19,-PI/2,-PI/2+TAU*Fantasy.fraction(duration-remaining,duration),32,hue if not blocked else hue.darkened(0.45),2)
	var line := "%.1fs" % remaining if remaining>0 else ("PAUSED" if blocked else "CAST")
	Fantasy.text_at(self,line,Vector2(size.x/2,49),11,Fantasy.IVORY if not disabled else Fantasy.MUTED,true)
