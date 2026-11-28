extends RefCounted
## Benchmark-only policies. No access to future RNG, hidden drops, or gameplay writes.
const Model = preload("res://gameplay/run.gd")
const World = preload("res://gameplay/dungeon_world.gd")
const Genetics = preload("res://domain/genetics.gd")
const VERSION := "advanced-v1"
const VISION := 140.0
const HORIZON := 0.40
const ANGLES := [0.0,0.55,-0.55,1.10,-1.10,1.65,-1.65,PI]

# Sample actual founders or fusions, never edit their traits to fit a cell.
# Independent from world/combat RNG. Returns provenance for reproduction.
static func generated(affinity: String,body: String,seed: int) -> Dictionary:
	var rng := Genetics.SeededRandom.new(seed+630291)
	for attempt in range(2048):
		var a := rng.next_int(1000000000)
		var b := rng.next_int(1000000000)
		var c := rng.next_int(1000000000)
		var parents: Array=[]
		var g := Genetics.founder(a)
		# Mix legal tier-I and tier-II phenotypes where the cell permits both.
		if body=="hybrid" or affinity=="steam" or attempt%2==0:
			if a==b: continue
			g=Genetics.fuse(g,Genetics.founder(b),c)
			parents=[a,b]
		var p := Genetics.express(g)
		if p.affinity==affinity and p.body==body:
			return {"phenotype":p,"genome":g,"parent_seeds":parents,"sample_seed":seed}
	return {}

static func visible(run: Variant,point: Vector2) -> bool:
	return run.player.distance_squared_to(point)<=VISION*VISION

static func targets(run: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for e in run.enemies:
		if e.hp>0 and visible(run,e.pos): result.append(e)
	return result

static func danger(run: Variant,point: Vector2,near: Array[Dictionary]) -> float:
	var risk := 0.0
	for e in near:
		var position: Vector2=e.pos
		var radius := float(e.radius)+Model.PLAYER_RADIUS
		var distance := position.distance_to(point)
		# Contact risk includes a short approach margin, not an enemy's hidden future.
		risk+=maxf(0.0,radius+18.0-distance)*0.16
		var state: String=e.attack
		var remaining := float(e.attack_time)
		if state in ["breath","web"]:
			var center: Vector2=e.attack_target
			var reach := (Model.EnemyAI.BREATH_RADIUS if state=="breath" else Model.EnemyAI.WEB_RADIUS)+Model.PLAYER_RADIUS
			var urgency := 1.0 if remaining<=HORIZON else 0.55
			risk+=maxf(0.0,reach+10.0-center.distance_to(point))*urgency*(0.45 if state=="breath" else 0.16)
		elif state in ["charge_windup","charge","bolt"]:
			if state=="charge" and e.attack_hit: continue
			var direction: Vector2=e.attack_dir
			var length := 145.0*1.8 if state=="bolt" else (Model.EnemyAI.BOSS_CHARGE_SPEED if int(e.kind)==3 else Model.EnemyAI.CHARGE_SPEED)*(remaining if state=="charge" else Model.EnemyAI.CHARGE_TIME)
			var end := position+direction*length
			var closest := Geometry2D.get_closest_point_to_segment(point,position,end)
			var margin := 13.0 if state=="bolt" else radius+8.0
			risk+=maxf(0.0,margin+8.0-point.distance_to(closest))*(0.50 if state=="charge" else 0.34)
	for bolt in run.enemy_bolts:
		if not visible(run,bolt.pos): continue
		var start: Vector2=bolt.pos
		var end: Vector2=start+bolt.vel*minf(HORIZON,float(bolt.life))
		var closest := Geometry2D.get_closest_point_to_segment(point,start,end)
		risk+=maxf(0.0,18.0-point.distance_to(closest))*0.65
	for web in run.webs:
		if visible(run,web.pos): risk+=maxf(0.0,float(web.radius)+Model.PLAYER_RADIUS-point.distance_to(web.pos))*0.08
	return risk

static func goal(run: Variant,strategy: String,near: Array[Dictionary],previous: Vector2) -> Dictionary:
	var focus: Dictionary={}
	var best := INF
	for e in near:
		var distance: float=run.player.distance_to(e.pos)
		var priority := distance
		if int(e.kind)==3 or (run.trial_index>=0 and e.get("trial",-1)==run.trial_index): priority-=180.0
		elif not run.active_encounter.is_empty() and e.get("encounter","")==run.active_encounter.id: priority-=110.0
		if priority<best:
			best=priority
			focus=e
	var combat: Dictionary={}
	if not focus.is_empty():
		var distance := 54.0 if strategy=="aggressive" else (105.0 if strategy=="kiting" else 85.0)
		if run.trial_index>=0: distance=minf(distance,85.0)
		if int(focus.kind)==3: distance=minf(distance,105.0)
		combat={"pos":focus.pos,"range":distance,"weight":1.0,"kind":"combat"}
	# Mandatory marked targets and final boss take precedence over loot.
	if run.trial_index>=0 or run.boss_spawned:
		if not combat.is_empty(): return combat
		if run.trial_index>=0: return {"pos":run.trial_center,"range":0.0,"weight":1.0,"kind":"search"}
		return {}
	if not run.active_encounter.is_empty() and run._guards_remaining()==0 and visible(run,run.active_encounter.pos):
		return {"pos":run.active_encounter.pos,"range":0.0,"weight":1.4,"kind":"site"}
	var loot: Dictionary={}
	var value := 0.0
	for item in run.mana.drops:
		if not visible(run,item.pos) or run.player.distance_to(item.pos)<=Model.Mana.COLLECT_RADIUS: continue
		var distance: float=run.player.distance_to(item.pos)
		var score := float(item.value)/maxf(24.0,distance)
		if score>value:
			value=score
			loot={"pos":item.pos,"range":0.0,"weight":1.0,"kind":"mana"}
	# Site information is restricted to nearby map objects, not a search of distant chunks.
	var origin := World.chunk_at(run.player)
	for y in range(origin.y-1,origin.y+2):
		for x in range(origin.x-1,origin.x+2):
			var site := World.site(run.world_seed,Vector2i(x,y))
			if site.is_empty() or run.claimed_sites.has(site.id) or not visible(run,site.pos): continue
			if site.kind=="guarded" and (run.expedition_time()<60.0 or not run.active_encounter.is_empty()): continue
			if site.kind=="healing" and run.hp>run.max_hp-10: continue
			var worth := 8.0 if strategy=="explorer" else 3.0
			if site.kind=="healing" and run.hp<run.max_hp*0.7: worth+=12.0
			if run.artifact_available(site): worth+=12.0 if strategy=="explorer" else 6.0
			var score := worth/maxf(24.0,run.player.distance_to(site.pos))
			if score>value:
				value=score
				loot={"pos":site.pos,"range":0.0,"weight":1.2,"kind":"site"}
	if not loot.is_empty() and (combat.is_empty() or strategy=="explorer" or value>=0.035): return loot
	return combat

static func steering(run: Variant,strategy: String,previous: Vector2,rng: Variant) -> Dictionary:
	if strategy=="stationary": return {"move":Vector2.ZERO,"dodge":false,"goal":"stationary"}
	var near := targets(run)
	var objective := goal(run,strategy,near,previous)
	var desired := previous
	if not objective.is_empty():
		var delta: Vector2=objective.pos-run.player
		var distance := delta.length()
		var direction := delta.normalized()
		if objective.kind=="combat":
			var radius := float(objective.range)
			desired=direction if distance>radius+12.0 else (-direction if distance<radius-12.0 else direction.orthogonal())
		else: desired=direction
	elif previous.is_zero_approx() or rng.next_int(20)==0:
		desired=Vector2.from_angle(float(rng.next_int(360))*PI/180.0)
	if desired.is_zero_approx(): desired=Vector2.RIGHT
	var pos: Vector2=run.player
	var travel := float(run.speed)*HORIZON*(0.5 if run.webbed else 1.0)
	var chosen := Vector2.ZERO
	var best := -INF
	var preferred_risk := INF
	var chosen_risk := INF
	for angle in ANGLES+[0.0]:
		# Last candidate is stationary; no simulated lookahead or future state.
		var index_is_stop := angle==0.0 and preferred_risk!=INF
		var direction := Vector2.ZERO if index_is_stop else desired.rotated(float(angle))
		var point := pos+direction*travel
		if run.trial_index>=0 and point.distance_to(run.trial_center)>Model.Trials.RADIUS: continue
		if not World.line_clear(run.world_seed,pos,point,Model.PLAYER_RADIUS): continue
		var risk := danger(run,point,near)
		if angle==0.0 and not index_is_stop: preferred_risk=risk
		var score := direction.dot(desired)*1.5-risk
		if not objective.is_empty():
			var old := absf(pos.distance_to(objective.pos)-float(objective.range))
			var new := absf(point.distance_to(objective.pos)-float(objective.range))
			score+=(old-new)/maxf(1.0,travel)*3.0*float(objective.weight)
		if score>best:
			best=score
			chosen=direction
			chosen_risk=risk
	return {"move":chosen,"dodge":preferred_risk!=INF and chosen_risk+0.5<preferred_risk,"goal":str(objective.get("kind","search"))}

static func choose_upgrade(run: Variant,strategy: String) -> int:
	var best := -INF
	var index := 0
	var health := float(run.hp)/float(run.max_hp)
	for i in range(run.upgrade_offer.size()):
		var id: String=run.upgrade_offer[i]
		var score := 1.0
		match id:
			"vitality","stone","hybrid","relic_heart": score=8.0 if health<0.45 else (3.0 if health<0.75 else 1.5)
			"power","focus","relic_power": score=4.0
			"haste","rapid": score=4.4 if strategy!="kiting" else 3.8
			"flow","relic_focus": score=4.0 if strategy=="aggressive" else 2.6
			"stride","fae": score=3.5 if strategy in ["explorer","kiting"] else 2.0
			"artifact_magnet": score=5.0 if strategy!="aggressive" else 3.5
			"artifact_blood": score=7.0 if health<0.75 or "artifact_magnet" in run.artifacts_owned else 4.0
			"artifact_ward": score=5.0 if strategy=="aggressive" else 3.0
			"artifact_echo": score=3.5+float(run.upgrade_ranks.get("flow",0))*0.5
			"artifact_pierce": score=5.0 if run.phenotype.affinity!="ice" or run.evolution_branch=="evo_ice_volley" else 3.0
			"artifact_stride": score=4.0 if strategy=="explorer" else 2.5
			_:
				var d: Dictionary=Model.Upgrades.DEFINITIONS[id]
				if d.get("evolution",false):
					score=5.0+Model.Evolution.resonance_bonus(run.phenotype,id)*15.0
					if id=="evo_steam_mantle" and strategy=="aggressive": score+=1.0
					if id in ["evo_fire_fan","evo_ice_volley"] and strategy=="explorer": score+=0.6
				elif d.get("affinity","")==run.phenotype.affinity: score=3.8
				elif d.category in ["Mutation","Talent"]: score=3.2
		if score>best:
			best=score
			index=i
	return index

static func cast_special(run: Variant,strategy: String) -> bool:
	if run.special_cd>0: return false
	var count := 0
	var radius := float(run.kit.special.radius)
	for e in run.enemies:
		if e.hp<=0 or not visible(run,e.pos) or run.player.distance_to(e.pos)>radius: continue
		count+=1
		if int(e.kind)==3 or (run.trial_index>=0 and e.get("elite",false)): return true
		if run.phenotype.affinity=="ice" and e.attack in ["charge_windup","charge","bolt","breath"]: return true
	return count>=(1 if strategy=="aggressive" or run.hp<run.max_hp*0.4 else 2)
