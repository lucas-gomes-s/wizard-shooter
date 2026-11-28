extends SceneTree
## Run with --script tools/balance_benchmark.gd -- --seeds=2 --seconds=120 --output=/tmp/balance.json
## Uses the actual fixed-step model, no rendering, purchases, save writes or human input.
const RunModel = preload("res://gameplay/run.gd")
const Genetics = preload("res://domain/genetics.gd")
const World = preload("res://gameplay/dungeon_world.gd")
const DT := 1.0 / 60.0
const STRATEGIES := ["stationary","aggressive","kiting","explorer"]
const AFFINITIES := ["fire","ice","steam"]
var seed_count := 2
var seconds := 120
var output := "user://balance.json"
var seed_start := 7001
var parameters: Dictionary = {}
var preset_name := ""
var config_supplied := false
var bodies: Array[String] = ["stoneborn"]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seed_count = clampi(int(arg.get_slice("=",1)),1,100)
		if arg.begins_with("--seconds="): seconds = clampi(int(arg.get_slice("=",1)),10,900)
		if arg.begins_with("--output="): output = arg.get_slice("=",1)
		if arg.begins_with("--seed-start="): seed_start = int(arg.get_slice("=",1))
		if arg == "--all-bodies": bodies = ["stoneborn","fae","hybrid"]
		if arg.begins_with("--preset="): preset_name=arg.get_slice("=",1)
		if arg.begins_with("--config="):
			config_supplied=true
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(arg.get_slice("=",1)))
			if not parsed is Dictionary:
				push_error("Invalid configuration JSON"); quit(2); return
			parameters = RunModel.Balance.validated(parsed)
			if parameters.is_empty():
				push_error("Unknown or out-of-bounds configuration"); quit(2); return
	if not preset_name.is_empty():
		if config_supplied:
			push_error("Choose preset or config, not both"); quit(2); return
		parameters=RunModel.Balance.preset(preset_name)
		if parameters.is_empty():
			push_error("Unknown preset"); quit(2); return
	if preset_name in [RunModel.Balance.LONG,RunModel.Balance.MANA] and seconds<=int(RunModel.Phases.BOSS_AT):
		push_error("Six-minute expedition needs a benchmark horizon above 360 seconds"); quit(2); return
	var rows: Array[Dictionary] = []
	var started := Time.get_ticks_msec()
	for body in bodies:
		for affinity in AFFINITIES:
			var p := fixture(affinity,body)
			for difficulty in range(1,4):
				for strategy in STRATEGIES:
					for i in range(seed_count):
						rows.append(simulate(p,difficulty,strategy,seed_start+i*7919))
	var groups := summarize(rows)
	var elapsed_ms := Time.get_ticks_msec()-started
	var result := {"schema":1,"seeds_per_cell":seed_count,"horizon_seconds":seconds,"physics_hz":60,"economy":RunModel.Economy.VERSION,"profile":"controlled bodies/power 100/no mutation or talents; hybrids and steam tier II","parameters":RunModel.Balance.validated(parameters),"seed_start":seed_start,"preset":preset_name,"frost_rules":preset_name in [RunModel.Balance.FROST,RunModel.Balance.LONG,RunModel.Balance.MANA],"phased_expedition":preset_name in [RunModel.Balance.LONG,RunModel.Balance.MANA],"mana_rules":preset_name==RunModel.Balance.MANA,"runs":rows,"groups":groups,"wall_ms":elapsed_ms}
	var file := FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write benchmark output: "+output)
		quit(1)
		return
	file.store_string(JSON.stringify(result,"  "))
	file.close()
	for group in groups:
		print("BALANCE %s D%d %s n=%d win=%d death=%d timeout=%d survival=%.1fs kills=%.1f lv=%.1f damage=%.1f taken=%.1f training=%.1f caches=%.1f" % [group.affinity,group.difficulty,group.strategy,group.n,group.wins,group.deaths,group.timeouts,group.mean_seconds,group.mean_kills,group.mean_level,group.mean_damage,group.mean_taken,group.mean_training,group.mean_caches])
	print("BENCHMARK COMPLETE: %d runs in %d ms; %s" % [rows.size(),elapsed_ms,output])
	quit(0)

static func fixture(affinity: String, body: String = "stoneborn") -> Dictionary:
	var g := Genetics.founder(42)
	g.species = ["stoneborn","fae"] if body=="hybrid" else [body,body]
	g.ancestry = {"stoneborn":5000,"fae":5000} if body=="hybrid" else {"stoneborn":10000 if body=="stoneborn" else 0,"fae":10000 if body=="fae" else 0}
	g.power = 100
	g.core = ["fire","ice"] if affinity=="steam" else [affinity,affinity]
	g.tier = 2 if affinity=="steam" or body=="hybrid" else 1
	g.mutation = "none"
	var p := Genetics.express(g)
	# Controlled comparison deliberately removes passive effects; not a generated legal player record.
	p.passives = []
	return p

func simulate(p: Dictionary,difficulty: int,strategy: String,seed: int) -> Dictionary:
	var run := RunModel.new(p,false,difficulty,seed,parameters,preset_name in [RunModel.Balance.FROST,RunModel.Balance.LONG,RunModel.Balance.MANA],preset_name in [RunModel.Balance.LONG,RunModel.Balance.MANA],preset_name==RunModel.Balance.MANA)
	var bot_rng := Genetics.SeededRandom.new(seed+17231)
	var move := Vector2.ZERO
	var chosen: Dictionary = {}
	var ticks := 0
	var started := Time.get_ticks_usec()
	for i in range(seconds*60):
		if run.outcome!="": break
		while run.pending_upgrades>0:
			run.ensure_upgrade_offer()
			var index := choose_upgrade(run,bot_rng)
			var id: String = run.upgrade_offer[index]
			chosen[id] = int(chosen.get(id,0))+1
			run.upgrade(index)
		# Intent changes at 5Hz, then held across normal 60Hz physics steps.
		if i%12==0:
			move = steering(run,strategy,move,bot_rng)
		var cast := false
		if run.special_cd<=0:
			for e in run.enemies:
				if run.player.distance_to(e.pos)<=float(run.kit.special.radius):
					cast = true
					break
		run.step(DT,move,cast)
		ticks += 1
	return {"seed":seed,"affinity":p.affinity,"body":p.body,"tier":p.tier,"difficulty":difficulty,"strategy":strategy,"outcome":run.outcome if run.outcome!="" else "Timeout","seconds":run.elapsed,"kills":run.kills,"level":run.run_level,"run_xp":run.total_run_xp,"training_xp":run.training_reward(),"legacy_training_xp":run.legacy_training_reward(),"apprentice_xp":run.permanent_reward().apprentice,"essence_reward":run.permanent_reward().essence,"damage":run.total_damage_dealt,"taken":run.total_damage_taken,"remaining_hp":run.hp,"basic_casts":run.basic_casts,"special_casts":run.special_casts,"frost_bonus_hits":run.frost_bonus_hits,"frost_shatters":run.frost_shatters,"phase_reached":run.phase_index(),"phase_spawns":run.phase_spawns.duplicate(),"mana":run.mana.metrics(),"caches":run.treasure_count,"shrines":run.shrine_count,"encounters":run.encounters_cleared,"despawned":run.despawned,"peak_enemies":run.peak_enemies,"last_hit":run.last_hit,"upgrades":chosen,"first_upgrade":run.first_upgrade_time,"level_times":run.level_times,"boss_reached":run.boss_spawned,"boss_spawn_time":run.boss_spawn_time,"ticks":ticks,"cpu_us":Time.get_ticks_usec()-started}

static func choose_upgrade(run: Variant,rng: Variant) -> int:
	# Same deterministic policy for all strategies. Heal when necessary; otherwise favor affinity.
	if run.hp<run.max_hp*0.45 and "vitality" in run.upgrade_offer:
		return run.upgrade_offer.find("vitality")
	for i in range(run.upgrade_offer.size()):
		var id: String = run.upgrade_offer[i]
		if RunModel.Upgrades.DEFINITIONS[id].get("affinity","")==run.phenotype.affinity: return i
	return rng.next_int(run.upgrade_offer.size())

static func steering(run: Variant,strategy: String,previous: Vector2,rng: Variant) -> Vector2:
	if strategy=="stationary": return Vector2.ZERO
	var target: Dictionary = {}
	var nearest := INF
	for e in run.enemies:
		var dist: float = run.player.distance_squared_to(e.pos)
		if strategy in ["aggressive","kiting"] and int(e.kind)==3:
			nearest=dist
			target=e
			break
		if dist<nearest:
			nearest=dist
			target=e
	var direction := previous
	if strategy=="explorer":
		var origin := World.chunk_at(run.player)
		var best := INF
		for y in range(origin.y-1,origin.y+2):
			for x in range(origin.x-1,origin.x+2):
				var site := World.site(run.world_seed,Vector2i(x,y))
				if site.is_empty() or run.claimed_sites.has(site.id): continue
				if site.kind=="healing" and run.hp>run.max_hp-10.0: continue
				var dist: float = run.player.distance_squared_to(site.pos)
				if dist<best:
					best=dist
					direction=run.player.direction_to(site.pos)
		if best==INF and (previous==Vector2.ZERO or rng.next_int(10)==0): direction=Vector2.from_angle(rng.next_int(360)*PI/180.0)
	elif not target.is_empty():
		var toward: Vector2 = run.player.direction_to(target.pos)
		var distance := sqrt(nearest)
		if strategy=="aggressive": direction=toward if distance>55.0 else -toward
		else: direction=-toward if distance<105.0 else (toward if distance>190.0 else toward.orthogonal())
	elif previous==Vector2.ZERO: direction=Vector2.RIGHT
	if run.mana_rules and not run.boss_spawned:
		var collect := mana_heading(run,strategy)
		if not collect.is_zero_approx(): direction=collect
	# Try a different heading if a pillar blocks the intended next segment.
	var pos: Vector2 = run.player
	for angle in [0.0,0.7,-0.7,1.4,-1.4,PI]:
		var candidate := direction.rotated(float(angle))
		if World.line_clear(run.world_seed,pos,pos+candidate*18.0,7.0): return candidate
	return Vector2.ZERO

# Simple risk-aware pickup detours, not a model of human behavior.
static func mana_heading(run: Variant,strategy: String) -> Vector2:
	var best := -INF
	var chosen := Vector2.ZERO
	for item in run.mana.drops:
		var delta: Vector2=item.pos-run.player
		var distance := delta.length()
		if distance<RunModel.Mana.COLLECT_RADIUS or distance>145.0: continue
		if not World.line_clear(run.world_seed,run.player,item.pos,7.0): continue
		var unsafe := false
		var approach: Vector2=run.player+delta.normalized()*minf(distance,40.0)
		for enemy in run.enemies:
			if enemy.hp<=0: continue
			if enemy.pos.distance_to(approach)<float(enemy.radius)+(35.0 if strategy=="kiting" else 22.0):
				unsafe=true
				break
		if unsafe: continue
		var score := float(item.value)/maxf(24.0,distance)
		if score>best:
			best=score
			chosen=delta.normalized()
	return chosen

static func summarize(rows: Array[Dictionary]) -> Array[Dictionary]:
	var by_key: Dictionary = {}
	for row in rows:
		var key := "%s/%s/%d/%s" % [row.body,row.affinity,row.difficulty,row.strategy]
		if not by_key.has(key):
			by_key[key]={"body":row.body,"affinity":row.affinity,"difficulty":row.difficulty,"strategy":row.strategy,"n":0,"wins":0,"deaths":0,"timeouts":0,"mean_seconds":0.0,"mean_kills":0.0,"mean_level":0.0,"mean_damage":0.0,"mean_taken":0.0,"mean_training":0.0,"mean_caches":0.0}
		var g: Dictionary = by_key[key]
		g.n+=1
		match str(row.outcome):
			"Victory": g.wins+=1
			"Defeated": g.deaths+=1
			_: g.timeouts+=1
		for pair in [["mean_seconds","seconds"],["mean_kills","kills"],["mean_level","level"],["mean_damage","damage"],["mean_taken","taken"],["mean_training","training_xp"],["mean_caches","caches"]]:
			g[pair[0]]+=float(row[pair[1]])
	var result: Array[Dictionary] = []
	for key in by_key:
		var g: Dictionary = by_key[key]
		for field in ["mean_seconds","mean_kills","mean_level","mean_damage","mean_taken","mean_training","mean_caches"]:
			g[field]/=float(g.n)
		result.append(g)
	return result
