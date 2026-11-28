extends Button
## Native button input/focus with structured, non-interactive child content.
const Art = preload("res://presentation/pixel_ui_art.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
var icon_view: TextureRect
var category_label: Label
var name_label: Label
var detail_label: Label
var rank_label: Label
var current_key := ""

func _ready() -> void:
	text = ""
	custom_minimum_size = Vector2(324,86)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icon_view = TextureRect.new()
	icon_view.position = Vector2(13,22)
	icon_view.size = Vector2(36,36)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_view)
	category_label = _label(Vector2(62,8),Vector2(172,14),10)
	name_label = _label(Vector2(62,22),Vector2(246,21),15)
	detail_label = _label(Vector2(62,44),Vector2(248,35),12)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_label = _label(Vector2(240,7),Vector2(70,15),10)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _label(pos: Vector2,extent: Vector2,font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = extent
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	add_child(label)
	return label

func configure(id: String,d: Dictionary,rank: int,hue: Color) -> void:
	var key := id+":"+str(rank)+":"+str(d.category)
	if current_key==key: return
	current_key=key
	icon_view.texture=Art.icon(Art.upgrade_icon(id,d),hue)
	category_label.text=str(d.category).to_upper()
	category_label.add_theme_color_override("font_color",hue)
	name_label.text=str(d.name)
	name_label.add_theme_color_override("font_color",Fantasy.IVORY)
	detail_label.text=str(d.text)
	detail_label.add_theme_color_override("font_color",Fantasy.MUTED)
	rank_label.text="RANK %d/%d" % [rank+1,d.cap] if int(d.cap)>0 else "RANK %d" % (rank+1)
	rank_label.add_theme_color_override("font_color",hue)
	add_theme_stylebox_override("normal",Fantasy.style(Color("#292332").lerp(hue,0.08),hue.darkened(0.30)))
	add_theme_stylebox_override("hover",Fantasy.style(Color("#392f45").lerp(hue,0.16),hue))
	add_theme_stylebox_override("pressed",Fantasy.style(Color("#201b2a"),hue.lightened(0.25)))
	tooltip_text=str(d.name)+": "+str(d.text)+( " ("+str(d.category)+")" if str(d.category).begins_with("RESONANCE") else "")
