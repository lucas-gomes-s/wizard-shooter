extends RefCounted
## Fixed-step unbounded world simulation. Camera and terrain rendering are presentation-only.
const World = preload("res://gameplay/dungeon_world.gd")
const Abilities = preload("res://gameplay/ability_catalog.gd")
const Upgrades = preload("res://gameplay/upgrade_catalog.gd")
const EnemyAI = preload("res://gameplay/enemy_behavior.gd")
const Balance = preload("res://gameplay/balance_config.gd")
const DESPAWN_DISTANCE := 740.0
const BOSS_RELOCATE_DISTANCE := 950.0
const TARGET_RANGE := 350.0
const SPAWN_HALF := Vector2(260, 304)
const PLAYER_RADIUS := 7.0
const MAX_ENEMIES := 120
const ENEMY_DATA := [
	{"name": "Goblin", "hp": 23.0, "speed": 34.0, "damage": 7.0, "radius": 7.0, "xp": 2},
	{"name": "Spider", "hp": 13.0, "speed": 61.0, "damage": 5.0, "radius": 6.0, "xp": 2},
	{"name": "Orc", "hp": 62.0, "speed": 22.0, "damage": 12.0, "radius": 11.0, "xp": 5},
	{"name": "Dragon", "hp": 440.0, "speed": 42.0, "damage": 18.0, "radius": 19.0, "xp": 30},
	{"name": "Warlock", "hp": 32.0, "speed": 44.0, "damage": 9.0, "radius": 8.0, "xp": 4}
]
const FINITE_SECONDS := 90.0 # accelerated playtest, not final dungeon length
const Genetics = preload("res://domain/genetics.gd")
var phenotype: Dictionary
var rng: Variant
var player := Vector2.ZERO
var world_seed: int
var travel_direction := Vector2.ZERO
var despawned := 0
var claimed_sites: Dictionary = {}
var exploration_xp := 0
var exploration_essence := 0
var treasure_count := 0
var shrine_count := 0
var encounters_cleared := 0
var blessing := 0.0
var site_notice := ""
var site_notice_time := 0.0
var active_encounter: Dictionary = {}
const GUARD_COUNT := 3
const ENCOUNTER_LEASH := 580.0
var hp: float
var max_hp: float
var speed: float
var damage: float
var interval: float
var auto_cd := 0.0
var special_cd := 0.0
var special_fx := 0.0
var spawn_cd := 0.0
var hurt_cd := 0.0
var elapsed := 0.0
var kills := 0
var xp := 0
var run_level := 1
var next_xp := 8
var pending_upgrades := 0
var boss_spawned := false
var boss_defeated := false
var endless: bool
var difficulty: int
var outcome := ""
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var kit: Dictionary
var ward := 0.0
var trail := 0.0
var trail_cd := 0.0
var next_enemy_id := 1
var upgrade_rng: Variant
var upgrade_ranks: Dictionary = {}
var upgrade_offer: Array[String] = []
var burst_radius := 36.0
var burst_power := 0.55
var trail_rate := 0.30
var webs: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var danger_flashes: Array[Dictionary] = []
var webbed := false
var last_hit := ""
var total_damage_dealt := 0.0
var total_damage_taken := 0.0
var basic_casts := 0
# Presentation telemetry only; never read by simulation decisions.
var last_basic_direction := Vector2.DOWN
var special_casts := 0
var total_run_xp := 0
var peak_enemies := 0
var hit_fx: Array[Dictionary] = []
const MAX_HIT_FX := 40
var player_hit_fx := 0.0
var balance: Dictionary
var first_upgrade_time := -1.0
var level_times: Array[float] = []
var boss_spawn_time := -1.0

func _init(p: Dictionary, is_endless: bool, level: int, seed: int, parameters: Dictionary = {}) -> void:
	balance = Balance.validated(parameters)
	assert(not balance.is_empty(), "Invalid balance parameters")
	phenotype = p.duplicate(true)
	kit = Abilities.compile(phenotype)
	rng = Genetics.SeededRandom.new(seed)
	upgrade_rng = Genetics.SeededRandom.new(seed + 937621)
	world_seed = seed
	endless = is_endless
	difficulty = clampi(level, 1, 3)
	max_hp = float(p.health)
	hp = max_hp
	speed = float(p.speed)
	damage = float(p.damage) * float(balance[str(p.affinity) + "_damage"])
	interval = float(p.interval) * float(kit.modifiers.interval)

func step(dt: float, movement: Vector2, special: bool) -> void:
	if outcome != "" or pending_upgrades > 0:
		return
	elapsed += dt
	travel_direction = movement.limit_length()
	webbed = false
	for web in webs:
		if web.life > 0 and player.distance_to(web.pos) <= float(web.radius) + PLAYER_RADIUS: webbed = true
	player = World.move(world_seed, player, travel_direction * speed * (0.50 if webbed else 1.0) * dt, PLAYER_RADIUS)
	_abandon_far_encounter()
	_recycle_far_enemies()
	blessing = maxf(0, blessing - dt)
	site_notice_time = maxf(0, site_notice_time - dt)
	auto_cd = maxf(0, auto_cd - dt)
	special_cd = maxf(0, special_cd - dt)
	hurt_cd = maxf(0, hurt_cd - dt)
	player_hit_fx = maxf(0, player_hit_fx - dt)
	for i in range(hit_fx.size() - 1, -1, -1):
		hit_fx[i].life -= dt
		if hit_fx[i].life <= 0: hit_fx.remove_at(i)
	special_fx = maxf(0, special_fx - dt)
	ward = maxf(0, ward - dt)
	trail = maxf(0, trail - dt)
	trail_cd = maxf(0, trail_cd - dt)
	if trail > 0 and trail_cd <= 0 and travel_direction.length_squared() > 0.1:
		_add_cloud(player, 23.0, 1.3, trail_rate, "fire")
		trail_cd = 0.32
	spawn_cd -= dt
	var normal_limit := MAX_ENEMIES - GUARD_COUNT - (1 if not endless and not boss_spawned else 0)
	if spawn_cd <= 0 and enemies.size() < normal_limit:
		var kind := 0
		if elapsed >= 12 and rng.next_int(100) < 35: kind = 1
		if elapsed >= 28 and rng.next_int(100) < 28: kind = 2
		if elapsed >= 42 and rng.next_int(100) < 20: kind = 4
		_spawn(kind)
		spawn_cd = Balance.spawn_delay(elapsed, difficulty, boss_spawned, balance)
	if not endless and elapsed >= FINITE_SECONDS and not boss_spawned:
		boss_spawned = true
		boss_spawn_time = elapsed
		_spawn(3)
	peak_enemies = maxi(peak_enemies, enemies.size())
	if auto_cd <= 0:
		if _cast_basic(): auto_cd = interval
	if special and special_cd <= 0:
		_cast_special()
	_update_shots(dt)
	_update_clouds(dt)
	_update_enemy_hazards(dt)
	for i in range(flashes.size() - 1, -1, -1):
		flashes[i].life -= dt
		if flashes[i].life <= 0: flashes.remove_at(i)
	for enemy in enemies:
		if enemy.hp <= 0: continue
		if enemy.burn > 0:
			_damage_enemy(enemy, float(enemy.get("burn_dps", effective_damage() * 0.20)) * dt, "fire", false)
			enemy.burn = maxf(0, enemy.burn - dt)
		if enemy.hp <= 0: continue
		var frozen: bool = float(enemy.get("freeze", 0.0)) > 0
		var slow_factor: float = 0.0 if frozen else (0.55 if enemy.slow > 0 else 1.0)
		enemy.slow = maxf(0, enemy.slow - dt)
		enemy.freeze = maxf(0, float(enemy.get("freeze", 0.0)) - dt)
		enemy.chill = maxf(0, float(enemy.get("chill", 0.0)) - dt)
		EnemyAI.tick(self, enemy, dt, slow_factor, frozen)
		if not frozen and enemy.attack == "chase" and player.distance_to(enemy.pos) <= float(enemy.radius) + PLAYER_RADIUS:
			take_hit(float(enemy.damage), str(enemy.name))
	if phenotype.affinity == "fire": _burn_death_bursts()
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			var dead: Dictionary = enemies[i]
			if str(dead.get("encounter", "")) == "":
				kills += 1
				_gain_xp(int(dead.xp))
			_add_hit_fx(dead.pos, 0.0, str(phenotype.affinity), "defeat")
			if dead.kind == 3: boss_defeated = true
			enemies.remove_at(i)
	if hp <= 0:
		outcome = "Defeated"
	elif boss_defeated:
		outcome = "Victory"
	else:
		_update_sites()
		while xp >= next_xp:
			xp -= next_xp
			run_level += 1
			next_xp = roundi(next_xp * float(balance.xp_growth) + float(balance.xp_increment))
			if first_upgrade_time < 0: first_upgrade_time = elapsed
			level_times.append(elapsed)
			pending_upgrades += 1
		if pending_upgrades > 0: ensure_upgrade_offer()

func ensure_upgrade_offer() -> void:
	if pending_upgrades > 0 and upgrade_offer.is_empty() and outcome == "":
		upgrade_offer = Upgrades.offer(phenotype, upgrade_ranks, upgrade_rng)

func upgrade(choice: int) -> void:
	if pending_upgrades <= 0 or outcome != "": return
	ensure_upgrade_offer()
	if choice < 0 or choice >= upgrade_offer.size(): return
	var id: String = upgrade_offer[choice]
	if not Upgrades.eligible(id, phenotype, upgrade_ranks): return
	_apply_upgrade(id)
	upgrade_ranks[id] = int(upgrade_ranks.get(id, 0)) + 1
	pending_upgrades -= 1
	upgrade_offer.clear()
	ensure_upgrade_offer()

func _heal_upgrade(amount: float, heal: float) -> void:
	max_hp += amount
	hp = minf(max_hp, hp + heal)

func _modify_effect(spec: Dictionary, kind: String, field: String, amount: float, multiply: bool = false) -> void:
	for effect in spec.effects:
		if effect.kind == kind:
			effect[field] = float(effect[field]) * amount if multiply else float(effect[field]) + amount

func _apply_upgrade(id: String) -> void:
	match id:
		"vitality": _heal_upgrade(12.0, 20.0)
		"power": damage *= 1.10
		"haste": interval = maxf(0.16, interval * 0.90)
		"stride": speed += 6.0
		"kindle":
			for spec in [kit.basic, kit.special]:
				_modify_effect(spec, "burn", "rate", 1.25, true)
				_modify_effect(spec, "burn", "duration", 0.5)
		"wildfire":
			burst_radius += 10.0
			burst_power *= 1.20
		"inferno":
			kit.special.radius += 12.0
			kit.special.power *= 1.15
		"pierce": kit.basic.pierce += 1
		"shatter": _modify_effect(kit.special, "shatter", "power", 1.35, true)
		"permafrost":
			_modify_effect(kit.special, "freeze", "duration", 0.3)
			_modify_effect(kit.basic, "chill", "duration", 0.5)
			for spec in [kit.basic, kit.special]: _modify_effect(spec, "slow", "duration", 0.5)
		"mist":
			_modify_effect(kit.basic, "cloud", "radius", 8.0)
			_modify_effect(kit.basic, "cloud", "duration", 0.5)
		"pressure":
			_modify_effect(kit.basic, "cloud", "rate", 1.20, true)
			kit.special.rate *= 1.20
		"vortex":
			kit.special.radius += 12.0
			kit.special.duration += 0.6
		"wingward":
			kit.special.ward += 0.5
			kit.special.radius += 8.0
		"flametrail":
			kit.special.trail += 0.6
			trail_rate *= 1.20
		"fortify": kit.modifiers.incoming *= 0.92
		"rapid": interval = maxf(0.16, interval * 0.88)
		"focus": damage *= 1.12
		"flow": kit.special.cooldown = maxf(2.5, float(kit.special.cooldown) * 0.88)
		"stone": _heal_upgrade(20.0, 20.0)
		"fae": speed += 10.0
		"hybrid":
			speed += 6.0
			_heal_upgrade(10.0, 10.0)

func extract() -> void:
	if endless and elapsed >= 30 and outcome == "":
		outcome = "Extracted"

## Spawn outside the entire camera view including the bounded 24px camera lag.
func _spawn_position(radius: float) -> Vector2:
	var side: int = rng.next_int(4)
	# A minority of new enemies spawn ahead of moving players, keeping travel meaningful.
	if travel_direction.length_squared() > 0.1 and rng.next_int(100) < 40:
		if absf(travel_direction.x) > absf(travel_direction.y):
			side = 1 if travel_direction.x > 0 else 0
		else:
			side = 3 if travel_direction.y > 0 else 2
	var offset := Vector2.ZERO
	var outward := Vector2.ZERO
	match side:
		0:
			offset = Vector2(-SPAWN_HALF.x, rng.next_int(609) - 304)
			outward = Vector2.LEFT
		1:
			offset = Vector2(SPAWN_HALF.x, rng.next_int(609) - 304)
			outward = Vector2.RIGHT
		2:
			offset = Vector2(rng.next_int(521) - 260, -SPAWN_HALF.y)
			outward = Vector2.UP
		3:
			offset = Vector2(rng.next_int(521) - 260, SPAWN_HALF.y)
			outward = Vector2.DOWN
	var candidate := player + offset
	for attempt in range(5):
		if World.clear_at(world_seed, candidate, radius): return candidate
		candidate += outward * 28.0
	# Chunk boundaries are guaranteed free of pillars.
	if outward.x != 0: candidate.y = roundf(candidate.y / World.CHUNK) * World.CHUNK
	else: candidate.x = roundf(candidate.x / World.CHUNK) * World.CHUNK
	return candidate

func _recycle_far_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		var distance := player.distance_squared_to(e.pos)
		if int(e.kind) == 3:
			# Never delete the dungeon boss. Re-enter offscreen, retaining HP/status.
			if distance > BOSS_RELOCATE_DISTANCE * BOSS_RELOCATE_DISTANCE:
				e.pos = _spawn_position(float(e.radius))
				EnemyAI.recover(e, 1.5)
		elif str(e.get("encounter", "")) == "" and distance > DESPAWN_DISTANCE * DESPAWN_DISTANCE:
			enemies.remove_at(i)
			despawned += 1

func _spawn(kind: int) -> void:
	var d: Dictionary = ENEMY_DATA[kind].duplicate()
	d.kind = kind
	d.pos = _spawn_position(float(d.radius))
	d.steer = -1.0 if rng.next_int(2) == 0 else 1.0
	d.hp *= (1.0 + (difficulty - 1) * 0.25) * float(balance.enemy_hp) * (float(balance.boss_hp) if int(d.kind) == 3 else 1.0)
	d.max_hp = d.hp
	d.damage *= (1.0 + (difficulty - 1) * 0.18) * float(balance.enemy_damage) * (float(balance.boss_damage) if int(d.kind) == 3 else 1.0)
	d.slow = 0.0
	d.burn = 0.0
	d.chill = 0.0
	d.freeze = 0.0
	d.uid = next_enemy_id
	next_enemy_id += 1
	EnemyAI.initialize(d)
	enemies.append(d)

func effective_damage() -> float:
	return damage * float(kit.modifiers.damage) * (1.25 if blessing > 0 else 1.0)

func _announce(message: String) -> void:
	site_notice = message
	site_notice_time = 3.0

func _claim(site: Dictionary) -> void:
	var id: String = site.id
	if claimed_sites.has(id): return
	match str(site.kind):
		"treasure":
			treasure_count += 1
			_gain_xp(6)
			exploration_xp += 4
			exploration_essence += 2
			_announce("Treasure: +6 run XP, +2 essence")
		"healing":
			if max_hp - hp < 10.0: return
			var healed := minf(max_hp - hp, max_hp * 0.35)
			hp += healed
			shrine_count += 1
			_announce("Healing shrine: +%d HP" % roundi(healed))
		"arcane":
			# Refresh, never multiply the blessing.
			blessing = 20.0
			shrine_count += 1
			_announce("Arcane blessing: +25% damage for 20s")
		"guarded":
			if active_encounter.is_empty() or active_encounter.id != id or _guards_remaining() > 0: return
			encounters_cleared += 1
			treasure_count += 1
			_gain_xp(12)
			exploration_xp += 8
			exploration_essence += 4
			active_encounter = {}
			_announce("Guarded cache: +12 run XP, +4 essence")
		_: return
	claimed_sites[id] = true

func _guards_remaining() -> int:
	if active_encounter.is_empty(): return 0
	var count := 0
	for enemy in enemies:
		if enemy.get("encounter", "") == active_encounter.id and enemy.hp > 0: count += 1
	return count

func _abandon_far_encounter() -> void:
	if active_encounter.is_empty(): return
	if player.distance_to(active_encounter.pos) <= ENCOUNTER_LEASH: return
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].get("encounter", "") == active_encounter.id: enemies.remove_at(i)
	active_encounter = {}
	_announce("Guarded cache abandoned")

func _start_encounter(site: Dictionary) -> void:
	var reserve := 1 if not endless and not boss_spawned else 0
	if not active_encounter.is_empty() or claimed_sites.has(site.id) or enemies.size() + GUARD_COUNT + reserve > MAX_ENEMIES: return
	active_encounter = site.duplicate()
	# Explicit deterministic local spawns; no regular spawn RNG consumed.
	var center: Vector2 = site.pos
	for i in range(GUARD_COUNT):
		var kind := 2 if i == 0 else 0
		var d: Dictionary = ENEMY_DATA[kind].duplicate()
		var angle := TAU * i / GUARD_COUNT
		var point := center + Vector2.from_angle(angle) * 75.0
		for attempt in range(12):
			point = center + Vector2.from_angle(angle + attempt * TAU / 12.0) * 75.0
			if World.clear_at(world_seed, point, float(d.radius)) and point.distance_to(player) > 32.0: break
		if not World.clear_at(world_seed, point, float(d.radius)) or point.distance_to(player) <= 32.0:
			point = _spawn_position(float(d.radius))
		d.kind = kind
		d.pos = point
		d.steer = 1.0 if i % 2 == 0 else -1.0
		d.hp *= (1.0 + (difficulty - 1) * 0.25) * float(balance.enemy_hp) * (float(balance.boss_hp) if int(d.kind) == 3 else 1.0)
		d.max_hp = d.hp
		d.damage *= (1.0 + (difficulty - 1) * 0.18) * float(balance.enemy_damage) * (float(balance.boss_damage) if int(d.kind) == 3 else 1.0)
		d.xp = 0
		d.slow = 0.0
		d.burn = 0.0
		d.chill = 0.0
		d.freeze = 0.0
		d.uid = next_enemy_id
		next_enemy_id += 1
		d.encounter = site.id
		EnemyAI.initialize(d)
		enemies.append(d)
	_announce("Ambush! Defeat the three guardians.")

func _update_sites() -> void:
	var site := World.site(world_seed, World.chunk_at(player))
	if site.is_empty() or claimed_sites.has(site.id): return
	var distance := player.distance_to(site.pos)
	if site.kind == "guarded":
		if distance <= 48.0 and active_encounter.is_empty(): _start_encounter(site)
		if distance <= 20.0 and not active_encounter.is_empty() and active_encounter.id == site.id and _guards_remaining() == 0:
			_claim(site)
	elif distance <= 20.0:
		_claim(site)

func training_reward() -> int:
	return floori(elapsed / 4.0) + kills * 2 + exploration_xp

func _cast_basic() -> bool:
	var spec: Dictionary = kit.basic
	if shots.size() >= Abilities.MAX_SHOTS: return false
	var target: Dictionary = {}
	var best := float(spec.range) * float(spec.range)
	for e in enemies:
		if e.hp <= 0: continue
		var d := player.distance_squared_to(e.pos)
		if d <= best and World.line_clear(world_seed, player, e.pos, 2.0):
			best = d
			target = e
	if target.is_empty(): return false
	var direction := player.direction_to(target.pos)
	if direction == Vector2.ZERO: direction = Vector2.UP
	shots.append({"pos":player,"vel":direction * float(spec.speed),"life":float(spec.life),
		"damage":effective_damage() * float(spec.power),"pierce":int(spec.pierce),"hit":{},
		"effects":spec.effects.duplicate(true),"affinity":phenotype.affinity})
	last_basic_direction = direction
	basic_casts += 1
	return true

func _cast_special() -> void:
	var spec: Dictionary = kit.special
	special_cd = float(spec.cooldown)
	special_casts += 1
	special_fx = 0.35
	ward = float(spec.get("ward", 0.0))
	trail = float(spec.get("trail", 0.0))
	trail_cd = 0.0
	if spec.delivery == "cloud":
		_add_cloud(player, float(spec.radius), float(spec.duration), float(spec.rate), "steam")
	else:
		for enemy in enemies:
			if enemy.hp <= 0 or player.distance_to(enemy.pos) > float(spec.radius): continue
			_damage_enemy(enemy, effective_damage() * float(spec.power), str(phenotype.affinity))
			_apply_effects(enemy, spec.effects, effective_damage())

func _apply_effects(enemy: Dictionary, effects: Array, source_damage: float) -> void:
	for effect in effects:
		match str(effect.kind):
			"burn":
				# Refresh strongest active burn; no multiplicative stacking.
				var rate := source_damage * float(effect.rate)
				enemy.burn_dps = maxf(rate, float(enemy.get("burn_dps", 0.0)) if enemy.burn > 0 else 0.0)
				enemy.burn = maxf(float(enemy.burn), float(effect.duration))
			"slow":
				enemy.slow = maxf(float(enemy.slow), float(effect.duration))
			"chill":
				enemy.chill = maxf(float(enemy.get("chill", 0.0)), float(effect.duration))
			"freeze":
				# Boss control resistance prevents permanent stun.
				var duration := float(effect.duration) * (0.25 if int(enemy.kind) == 3 else 1.0)
				enemy.freeze = maxf(float(enemy.get("freeze", 0.0)), duration)
			"shatter":
				if float(enemy.get("chill", 0.0)) > 0:
					_damage_enemy(enemy, source_damage * float(effect.power), "ice")
					enemy.chill = 0.0
					_flash(enemy.pos, 19.0, "ice")
			"cloud":
				_add_cloud(enemy.pos, float(effect.radius), float(effect.duration), float(effect.rate), "steam")

func _update_shots(dt: float) -> void:
	for shot in shots:
		shot.pos += shot.vel * dt
		shot.life -= dt
		if shot.life <= 0 or not World.clear_at(world_seed, shot.pos, 2.0):
			shot.life = 0.0
			continue
		for enemy in enemies:
			if enemy.hp <= 0 or shot.hit.has(enemy.uid): continue
			if shot.pos.distance_to(enemy.pos) > float(enemy.radius) + 3.0: continue
			shot.hit[enemy.uid] = true
			_damage_enemy(enemy, float(shot.damage), str(shot.affinity))
			_apply_effects(enemy, shot.effects, float(shot.damage))
			if int(shot.pierce) <= 0:
				shot.life = 0.0
				break
			shot.pierce -= 1
	for i in range(shots.size() - 1, -1, -1):
		if shots[i].life <= 0: shots.remove_at(i)

func _add_cloud(point: Vector2, radius: float, duration: float, rate: float, affinity: String) -> void:
	if clouds.size() >= Abilities.MAX_CLOUDS: clouds.pop_front()
	clouds.append({"pos":point,"radius":radius,"life":duration,"dps":effective_damage() * rate,"affinity":affinity})

func _update_clouds(dt: float) -> void:
	# Overlapping clouds of the same element use the strongest DPS, not the sum.
	for enemy in enemies:
		if enemy.hp <= 0: continue
		var fire := 0.0
		var steam := 0.0
		for cloud in clouds:
			if cloud.life <= 0 or enemy.pos.distance_to(cloud.pos) > float(cloud.radius): continue
			if cloud.affinity == "fire": fire = maxf(fire, float(cloud.dps))
			else: steam = maxf(steam, float(cloud.dps))
		if steam > 0:
			enemy.slow = maxf(float(enemy.slow), 0.4)
			# Existing burning targets take additional steam pressure.
			if enemy.burn > 0: steam *= 1.25
		_damage_enemy(enemy, (fire + steam) * dt, "steam", false)
	for i in range(clouds.size() - 1, -1, -1):
		clouds[i].life -= dt
		if clouds[i].life <= 0: clouds.remove_at(i)

func _flash(point: Vector2, radius: float, affinity: String) -> void:
	if flashes.size() >= Abilities.MAX_FLASHES: flashes.pop_front()
	flashes.append({"pos":point,"radius":radius,"life":0.24,"affinity":affinity})

func _burn_death_bursts() -> void:
	var centers: Array[Vector2] = []
	for enemy in enemies:
		if enemy.hp <= 0 and enemy.burn > 0:
			centers.append(enemy.pos)
			if centers.size() >= 8: break
	for center in centers:
		_flash(center, burst_radius, "fire")
		for enemy in enemies:
			if enemy.hp > 0 and center.distance_to(enemy.pos) <= burst_radius:
				_damage_enemy(enemy, effective_damage() * burst_power, "fire")

func take_hit(amount: float, source: String) -> bool:
	if hurt_cd > 0 or hp <= 0: return false
	var before := hp
	hp = maxf(0, hp - amount * float(kit.modifiers.incoming) * (0.45 if ward > 0 else 1.0))
	total_damage_taken += before - hp
	player_hit_fx = 0.20
	_add_hit_fx(player, before - hp, "hostile", "hurt")
	hurt_cd = 0.45
	last_hit = source
	return true

func add_web(point: Vector2) -> void:
	if webs.size() >= EnemyAI.MAX_WEBS: webs.pop_front()
	webs.append({"pos":point,"radius":EnemyAI.WEB_RADIUS,"life":4.0})

func add_enemy_bolt(point: Vector2, direction: Vector2, amount: float) -> void:
	if enemy_bolts.size() >= EnemyAI.MAX_BOLTS: return
	enemy_bolts.append({"pos":point,"vel":direction.normalized() * 145.0,"damage":amount,"life":1.8})

func add_danger_flash(point: Vector2, radius: float) -> void:
	if danger_flashes.size() >= 12: danger_flashes.pop_front()
	danger_flashes.append({"pos":point,"radius":radius,"life":0.30})

func _update_enemy_hazards(dt: float) -> void:
	for i in range(webs.size() - 1, -1, -1):
		webs[i].life -= dt
		if webs[i].life <= 0: webs.remove_at(i)
	for i in range(enemy_bolts.size() - 1, -1, -1):
		var bolt := enemy_bolts[i]
		var before: Vector2 = bolt.pos
		var after: Vector2 = before + bolt.vel * dt
		bolt.life -= dt
		if bolt.life <= 0 or not World.line_clear(world_seed, before, after, 3.0):
			enemy_bolts.remove_at(i)
			continue
		bolt.pos = after
		if Geometry2D.get_closest_point_to_segment(player, before, after).distance_to(player) <= PLAYER_RADIUS + 4.0:
			take_hit(float(bolt.damage), "Warlock bolt")
			enemy_bolts.remove_at(i)
	for i in range(danger_flashes.size() - 1, -1, -1):
		danger_flashes[i].life -= dt
		if danger_flashes[i].life <= 0: danger_flashes.remove_at(i)

func _gain_xp(amount: int) -> void:
	xp += amount
	total_run_xp += amount

func _damage_enemy(enemy: Dictionary, amount: float, affinity: String, visual: bool = true) -> void:
	if enemy.hp <= 0 or amount <= 0: return
	var previous: float = enemy.hp
	enemy.hp -= amount
	total_damage_dealt += minf(previous, amount)
	if visual:
		enemy.hit_until = elapsed + 0.10
		_add_hit_fx(enemy.pos, minf(previous, amount), affinity, "hit")

func _add_hit_fx(point: Vector2, amount: float, affinity: String, kind: String) -> void:
	if hit_fx.size() >= MAX_HIT_FX: hit_fx.pop_front()
	hit_fx.append({"pos":point,"amount":amount,"affinity":affinity,"kind":kind,"life":0.55})
