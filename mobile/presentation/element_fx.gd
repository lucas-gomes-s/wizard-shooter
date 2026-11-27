extends RefCounted
## Stateless visual geometry plus one short-lived cast snapshot. No gameplay RNG.
## All area boundaries are based on actual combat radii, not particle extents.
const FIRE := Color("#ef8052")
const ICE := Color("#84d7e8")
const STEAM := Color("#c7b7d8")
const GOLD := Color("#ffe4a4")
const COLD := Color("#e1faff")
const MAX_SPARKS := 12
const CAST_LIFE := 0.35
var cast: Dictionary = {}

func reset() -> void:
	cast.clear()

func capture(run: Variant) -> void:
	# Player movement precedes casting in RunModel.step. Snapshot the cast origin
	# so subsequent player motion cannot drag an already-cast area along.
	cast={"pos":run.player,"radius":float(run.kit.special.radius),"affinity":str(run.phenotype.affinity),"at":float(run.elapsed)}

static func intersects(view: Rect2,point: Vector2,radius: float) -> bool:
	return view.intersects(Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2.0),true)

static func hue(element: String) -> Color:
	return FIRE if element=="fire" else (ICE if element=="ice" else STEAM)

static func diamond(canvas: CanvasItem,p: Vector2,forward: Vector2,length: float,width: float,color: Color) -> void:
	var normal := forward.orthogonal()
	canvas.draw_colored_polygon(PackedVector2Array([p+forward*length,p+normal*width,p-forward*length,p-normal*width]),color)

static func shard(canvas: CanvasItem,p: Vector2,direction: Vector2,length: float,width: float,alpha: float) -> void:
	diamond(canvas,p,direction,length,width,Color("#458aa9",alpha))
	diamond(canvas,p+direction*length*0.2,direction,length*0.72,width*0.62,Color(ICE,alpha))
	canvas.draw_line(p-direction*length*0.38,p+direction*length*0.68,Color(COLD,alpha),1.0)

static func projectile(canvas: CanvasItem,shot: Dictionary,elapsed: float) -> void:
	var p: Vector2 = shot.pos
	var heading: Vector2 = shot.vel.normalized()
	if heading.is_zero_approx(): heading=Vector2.UP
	var side := heading.orthogonal()
	match str(shot.affinity):
		"fire":
			# Hot core, tapering wake and three drifting embers.
			canvas.draw_line(p-heading*16,p-heading*3,Color("#a83c32",0.65),5)
			canvas.draw_line(p-heading*10,p,Color("#ef8052",0.85),3)
			diamond(canvas,p,heading,5,4,Color("#f4a04f"))
			diamond(canvas,p+heading,heading,3,2,GOLD)
			for i in range(3):
				var t := fposmod(elapsed*6.0+float(i)/3.0+float(shot.life),1.0)
				var q := p-heading*(5+12*t)+side*sin(t*TAU+i*2.1)*3.0
				canvas.draw_rect(Rect2(q.round(),Vector2(2,2)),Color(FIRE,(1-t)*0.72))
		"ice":
			canvas.draw_line(p-heading*18,p-heading*4,Color(ICE,0.32),2)
			shard(canvas,p-heading*2,heading,8,3,1.0)
			canvas.draw_line(p-heading*10+side*3,p-heading*15+side*3,Color(COLD,0.5),1)
		_:
			canvas.draw_circle(p-heading*8,5,Color(STEAM,0.18))
			canvas.draw_circle(p-heading*3,6,Color(STEAM,0.36))
			canvas.draw_circle(p,5,Color("#8d7ba6"))
			canvas.draw_arc(p,5,elapsed*5.0,elapsed*5.0+PI*1.5,12,Color("#e0d6e8",0.85),2)
			canvas.draw_circle(p+side*2,2,Color("#f1e9ed"))

static func cloud(canvas: CanvasItem,area: Dictionary,elapsed: float) -> void:
	var p: Vector2 = area.pos
	var radius := float(area.radius)
	var alpha := clampf(float(area.life)*3.0,0,1)
	var element := str(area.affinity)
	var color := hue(element)
	# The outline is the actual gameplay radius; interior effects never obscure enemies.
	canvas.draw_circle(p,radius,Color(color,0.075*alpha))
	canvas.draw_arc(p,radius,0,TAU,32,Color(color,0.42*alpha),1)
	if element=="fire":
		for i in range(8):
			var phase := fposmod(elapsed*1.8+float(i)*0.173,1.0)
			var direction := Vector2.from_angle(i*TAU/8.0)
			var q := p+direction*radius*(0.35+0.48*phase)
			canvas.draw_rect(Rect2(q.round(),Vector2(2,3)),Color(FIRE,(1-phase)*0.7*alpha))
	else:
		for i in range(3):
			var rotation := elapsed*0.9+float(i)*TAU/3.0
			canvas.draw_arc(p,radius*(0.40+0.20*i),rotation,rotation+PI*1.15,18,Color(STEAM,0.24*alpha),2)
		for i in range(6):
			var angle := i*TAU/6.0+elapsed*0.65
			var q := p+Vector2.from_angle(angle)*radius*0.62
			canvas.draw_circle(q,3+radius*0.045,Color(STEAM,0.13*alpha))

static func burst(canvas: CanvasItem,p: Vector2,radius: float,element: String,progress: float,large: bool) -> void:
	var u := clampf(progress,0,1)
	var alpha := 1.0-u
	var color := hue(element)
	var ring := radius*lerpf(0.30,1.0,smoothstep(0.0,0.8,u))
	# Brief, thin true-radius boundary plus distinct inner shapes.
	canvas.draw_arc(p,radius,0,TAU,40,Color(color,alpha*0.48),1)
	match element:
		"fire":
			canvas.draw_circle(p,ring,Color(FIRE,alpha*0.085))
			canvas.draw_arc(p,ring,0,TAU,36,Color("#d85c41",alpha*0.85),3 if large else 2)
			canvas.draw_arc(p,ring*0.84,0,TAU,36,Color(GOLD,alpha*0.62),1)
			for i in range(MAX_SPARKS if large else 6):
				var d := Vector2.from_angle(i*TAU/(MAX_SPARKS if large else 6)+0.17)
				var q := p+d*ring*0.88
				canvas.draw_line(q-d*radius*0.12,q,Color(FIRE,alpha),2)
				canvas.draw_rect(Rect2(q.round()-Vector2.ONE,Vector2(2,2)),Color(GOLD,alpha))
		"ice":
			canvas.draw_arc(p,ring,0,TAU,24,Color(ICE,alpha*0.55),1)
			for i in range(8 if large else 5):
				var d := Vector2.from_angle(i*TAU/(8 if large else 5))
				var q := p+d*ring*0.77
				canvas.draw_line(p+d*ring*0.16,q,Color(ICE,alpha*0.52),1)
				shard(canvas,q,d,maxf(3,radius*0.12)*alpha+2,3 if large else 2,alpha)
			diamond(canvas,p,Vector2.UP,ring*0.24,ring*0.16,Color(COLD,alpha*0.22))
		_:
			for i in range(3):
				var angle := u*PI*2.0+i*TAU/3.0
				canvas.draw_arc(p,ring*(0.52+0.19*i),angle,angle+PI*1.25,24,Color(STEAM,alpha*0.68),2)
			for i in range(6):
				var q := p+Vector2.from_angle(i*TAU/6+u*PI)*ring*0.80
				canvas.draw_circle(q,3+u*3,Color(STEAM,alpha*0.20))

func draw_cast(canvas: CanvasItem,view: Rect2,elapsed: float) -> void:
	if cast.is_empty(): return
	var age := elapsed-float(cast.at)
	if age<0 or age>=CAST_LIFE: return
	if intersects(view,cast.pos,float(cast.radius)):
		burst(canvas,cast.pos,float(cast.radius),str(cast.affinity),age/CAST_LIFE,true)

static func impact(canvas: CanvasItem,event: Dictionary,progress: float) -> void:
	var u := clampf(progress,0,1)
	var alpha := 1.0-u
	var p: Vector2 = event.pos
	var element := str(event.affinity)
	var death: bool = event.kind=="defeat"
	var count := 6 if death else 3
	if not death and u>0.48: return
	for i in range(count):
		var direction := Vector2.from_angle(i*TAU/count+0.7)
		var q := p+direction*(4.0+u*(17.0 if death else 10.0))
		if event.kind=="hurt":
			canvas.draw_line(q,q+direction*3,Color("#ff9c87",alpha),2)
		elif element=="ice":
			shard(canvas,q,direction,3.0,1.5,alpha)
		elif element=="fire":
			canvas.draw_rect(Rect2(q.round(),Vector2(2,3)),Color(FIRE,alpha))
			canvas.draw_rect(Rect2(q.round(),Vector2(1,1)),Color(GOLD,alpha))
		else:
			canvas.draw_circle(q,2.0+u*2.0,Color(STEAM,alpha*0.48))

static func enemy_status(canvas: CanvasItem,e: Dictionary,elapsed: float) -> void:
	var p: Vector2 = e.pos
	var r := float(e.radius)
	if float(e.get("freeze",0))>0:
		for i in range(4):
			var d := Vector2.from_angle(i*TAU/4+PI/4)
			shard(canvas,p+d*r*0.76,d,3.0,1.8,0.92)
	elif float(e.get("chill",0))>0:
		canvas.draw_arc(p,r+2,PI*0.12,PI*0.88,12,Color(ICE,0.72),1)
	if float(e.get("burn",0))>0:
		for i in range(2):
			var phase := fposmod(elapsed*2.5+i*0.5,1.0)
			var q := p+Vector2((-1.0 if i==0 else 1.0)*r*0.55,-r*0.35-phase*9.0)
			canvas.draw_rect(Rect2(q.round(),Vector2(2,3)),Color(FIRE,(1-phase)*0.8))
