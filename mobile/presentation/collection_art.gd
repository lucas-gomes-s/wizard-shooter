extends RefCounted
## Public phenotype-only collection formatting and page layout.
const Fantasy = preload("res://presentation/fantasy_ui.gd")
const Icons = preload("res://presentation/pixel_ui_art.gd")
const Abilities = preload("res://gameplay/ability_catalog.gd")
const Academy = preload("res://domain/academy.gd")
const PAGE_SIZE := 6
const FIRE := Color("#ef8052")
const ICE := Color("#84d7e8")
const STEAM := Color("#c7b7d8")

static func hue(p: Dictionary) -> Color:
	return FIRE if p.affinity=="fire" else (ICE if p.affinity=="ice" else STEAM)

static func pages(count: int) -> int:
	return maxi(1,ceili(float(count)/PAGE_SIZE))

static func card_rect(slot: int) -> Rect2:
	return Rect2(12+(slot%2)*174,59+floori(slot/2.0)*151,162,140)

static func title(record: Dictionary) -> String:
	var p: Dictionary = record.phenotype
	return "%s %s" % [str(p.affinity).capitalize(),str(p.body).capitalize()]

static func training(record: Dictionary) -> String:
	if int(record.phenotype.tier)>1: return "%d training XP" % int(record.xp)
	return "Mature" if int(record.xp)>=Academy.MATURE_XP else "%d / %d XP" % [record.xp,Academy.MATURE_XP]

static func role(index: int,active_index: int,partner: int) -> String:
	if index==active_index: return "ACTIVE"
	if index==partner: return "APPRENTICE"
	return "RESERVE"

static func hero(canvas: CanvasItem,sprites: Variant,record: Dictionary,tag: String = "ACTIVE WIZARD") -> void:
	var p: Dictionary = record.phenotype
	var c := hue(p)
	var kit := Abilities.compile(p)
	Fantasy.frame(canvas,Rect2(12,54,336,161),c.darkened(0.25))
	canvas.draw_circle(Vector2(76,127),48,Color(c,0.10))
	canvas.draw_arc(Vector2(76,127),44,0,TAU,32,Color(c,0.34),1)
	sprites.draw_wizard(canvas,p,Vector2(76,174),0,3.2)
	Fantasy.text_at(canvas,tag,Vector2(76,199),10,Fantasy.GOLD,true)
	Fantasy.text_at(canvas,title(record),Vector2(142,77),16,c)
	Fantasy.text_at(canvas,"TIER %d   %s" % [p.tier,"LOCKED" if record.locked else "UNLOCKED"],Vector2(142,96),10,Fantasy.MUTED)
	Fantasy.text_at(canvas,"HP %d   SPD %d" % [int(p.health),int(p.speed)],Vector2(142,117),13,Fantasy.IVORY)
	Fantasy.text_at(canvas,"POWER %.1f" % (float(p.damage)*float(kit.modifiers.damage)),Vector2(142,135),12,Fantasy.IVORY)
	Fantasy.text_at(canvas,str(kit.special.name),Vector2(142,153),12,c)
	Fantasy.bar(canvas,Rect2(142,165,192,13),float(record.xp),Academy.MATURE_XP,c)
	Fantasy.text_at(canvas,training(record),Vector2(238,193),11,Fantasy.MUTED,true)

static func apprentice(canvas: CanvasItem,sprites: Variant,record: Dictionary) -> void:
	Fantasy.frame(canvas,Rect2(12,224,336,63))
	if record.is_empty():
		Fantasy.text_at(canvas,"NO APPRENTICE",Vector2(27,247),12,Fantasy.MUTED)
		Fantasy.text_at(canvas,"Assign a reserve wizard to share XP.",Vector2(27,266),11,Fantasy.MUTED)
		return
	var p: Dictionary = record.phenotype
	sprites.draw_wizard(canvas,p,Vector2(42,276),0,1.5)
	Fantasy.text_at(canvas,title(record),Vector2(69,246),13,hue(p))
	Fantasy.text_at(canvas,"APPRENTICE   +25% XP",Vector2(69,262),10,Fantasy.GOLD)
	Fantasy.text_at(canvas,training(record),Vector2(69,277),10,Fantasy.MUTED)

static func details(record: Dictionary) -> String:
	var p: Dictionary = record.phenotype
	var kit := Abilities.compile(p)
	var mutation := "None expressed" if p.mutation=="none" else str(p.mutation).replace("_"," ").capitalize()
	return "Basic: %s\nSpecial: %s  |  %.1fs cooldown\nTalents: %s\nMutation: %s\nTraining: %s" % [kit.basic.name,kit.special.name,float(kit.special.cooldown),Abilities.passive_names(p),mutation,training(record)]

static func tile(canvas: CanvasItem,sprites: Variant,record: Dictionary,r: Rect2,tag: String) -> void:
	var p: Dictionary = record.phenotype
	var c := hue(p)
	Fantasy.frame(canvas,r,Fantasy.GOLD if tag=="ACTIVE" else c.darkened(0.30))
	Fantasy.text_at(canvas,tag,Vector2(r.get_center().x,r.position.y+15),10,Fantasy.GOLD if tag=="ACTIVE" else Fantasy.MUTED,true)
	canvas.draw_circle(r.position+Vector2(81,55),30,Color(c,0.12))
	sprites.draw_wizard(canvas,p,r.position+Vector2(81,81),0,2.0)
	Fantasy.text_at(canvas,"%s · T%d" % [str(p.affinity).capitalize(),p.tier],r.position+Vector2(81,96),13,c,true)
	Fantasy.text_at(canvas,str(p.body).capitalize()+(" / Locked" if record.locked else ""),r.position+Vector2(81,111),11,Fantasy.MUTED,true)
	Fantasy.bar(canvas,Rect2(r.position+Vector2(12,116),Vector2(138,9)),float(record.xp),Academy.MATURE_XP,c)
	Fantasy.text_at(canvas,training(record),r.position+Vector2(81,136),9,Fantasy.MUTED,true)
