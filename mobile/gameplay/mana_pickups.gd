extends RefCounted
## Bounded deterministic combat-XP pickups. No permanent currency or random rolls.
const LIMIT := 160
const LIFETIME := 75.0
const MAGNET_RADIUS := 64.0
const COLLECT_RADIUS := 24.0
const PULL_SPEED := 240.0
const MERGE_RADIUS := 12.0
const FAR_DISTANCE := 740.0
var drops: Array[Dictionary] = []
var generated := 0
var collected := 0
var lost := 0
var collections := 0
var first_collection := -1.0
var peak := 0

func drop(point: Vector2,amount: int,now: float,seed: int) -> void:
	if amount<=0: return
	generated+=amount
	for item in drops:
		if point.distance_squared_to(item.pos)<=MERGE_RADIUS*MERGE_RADIUS and RunWorld.line_clear(seed,point,item.pos,2.0):
			item.value+=amount
			# Do not indefinitely refresh the age of existing mana.
			return
	if drops.size()>=LIMIT:
		lost+=int(drops[0].value)
		drops.pop_front()
	drops.append({"pos":point,"value":amount,"born":now})
	peak=maxi(peak,drops.size())

const RunWorld = preload("res://gameplay/dungeon_world.gd")

func tick(player: Vector2,now: float,dt: float,seed: int) -> int:
	var total := 0
	for i in range(drops.size()-1,-1,-1):
		var item: Dictionary=drops[i]
		var point: Vector2=item.pos
		var distance := point.distance_squared_to(player)
		if now-float(item.born)>=LIFETIME or distance>FAR_DISTANCE*FAR_DISTANCE:
			lost+=int(item.value)
			drops.remove_at(i)
			continue
		if distance>MAGNET_RADIUS*MAGNET_RADIUS: continue
		if not RunWorld.line_clear(seed,point,player,2.0): continue
		if distance>COLLECT_RADIUS*COLLECT_RADIUS:
			item.pos=point.move_toward(player,PULL_SPEED*dt)
		if item.pos.distance_squared_to(player)<=COLLECT_RADIUS*COLLECT_RADIUS:
			total+=int(item.value)
			collections+=1
			if first_collection<0: first_collection=now
			drops.remove_at(i)
	collected+=total
	return total

func metrics() -> Dictionary:
	return {"generated":generated,"collected":collected,"lost":lost,"remaining":generated-collected-lost,
		"collections":collections,"first_collection":first_collection,"peak_pickups":peak}
