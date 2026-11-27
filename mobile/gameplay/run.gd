extends RefCounted
## Fixed-step unbounded world simulation. Camera and terrain rendering are presentation-only.
const World = preload("res://gameplay/dungeon_world.gd")
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
	{"name": "Dragon", "hp": 440.0, "speed": 29.0, "damage": 18.0, "radius": 19.0, "xp": 30}
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

func _init(p: Dictionary, is_endless: bool, level: int, seed: int) -> void:
	phenotype = p.duplicate(true)
	rng = Genetics.SeededRandom.new(seed)
	world_seed = seed
	endless = is_endless
	difficulty = clampi(level, 1, 3)
	max_hp = float(p.health)
	hp = max_hp
	speed = float(p.speed)
	damage = float(p.damage)
	interval = float(p.interval)

func step(dt: float, movement: Vector2, special: bool) -> void:
	if outcome != "" or pending_upgrades > 0:
		return
	elapsed += dt
	travel_direction = movement.limit_length()
	player = World.move(world_seed, player, travel_direction * speed * dt, PLAYER_RADIUS)
	_abandon_far_encounter()
	_recycle_far_enemies()
	blessing = maxf(0, blessing - dt)
	site_notice_time = maxf(0, site_notice_time - dt)
	auto_cd = maxf(0, auto_cd - dt)
	special_cd = maxf(0, special_cd - dt)
	hurt_cd = maxf(0, hurt_cd - dt)
	special_fx = maxf(0, special_fx - dt)
	spawn_cd -= dt
	var normal_limit := MAX_ENEMIES - GUARD_COUNT - (1 if not endless and not boss_spawned else 0)
	if spawn_cd <= 0 and enemies.size() < normal_limit:
		var kind := 0
		if elapsed >= 12 and rng.next_int(100) < 35: kind = 1
		if elapsed >= 28 and rng.next_int(100) < 28: kind = 2
		_spawn(kind)
		spawn_cd = maxf(0.24, 1.15 - elapsed * 0.007 - (difficulty - 1) * 0.13)
	if not endless and elapsed >= FINITE_SECONDS and not boss_spawned:
		boss_spawned = true
		_spawn(3)
	if auto_cd <= 0 and not enemies.is_empty():
		var nearest: Dictionary = enemies[0]
		for enemy in enemies:
			if player.distance_squared_to(enemy.pos) < player.distance_squared_to(nearest.pos):
				nearest = enemy
		if player.distance_squared_to(nearest.pos) <= TARGET_RANGE * TARGET_RANGE:
			var direction: Vector2 = player.direction_to(nearest.pos)
			if direction == Vector2.ZERO: direction = Vector2.UP
			shots.append({"pos": player, "vel": direction * 245.0, "life": 1.6})
			auto_cd = interval
	if special and special_cd <= 0:
		special_cd = 7.0
		special_fx = 0.35
		for enemy in enemies:
			var radius: float = 82.0 if phenotype.mutation == "crystal_wings" else 66.0
			if player.distance_to(enemy.pos) <= radius:
				enemy.hp -= effective_damage() * 2.5
				if phenotype.affinity != "fire":
					enemy.slow = 2.5
				else:
					enemy.burn = 2.0
	for shot in shots:
		shot.pos += shot.vel * dt
		shot.life -= dt
		if not World.clear_at(world_seed, shot.pos, 2.0):
			shot.life = 0.0
			continue
		for enemy in enemies:
			if enemy.hp > 0 and shot.pos.distance_to(enemy.pos) <= float(enemy.radius) + 3.0:
				enemy.hp -= effective_damage()
				if phenotype.affinity == "fire" or phenotype.affinity == "steam":
					enemy.burn = 1.8
				if phenotype.affinity == "ice" or phenotype.affinity == "steam":
					enemy.slow = 1.4
				shot.life = 0.0
				break
	for i in range(shots.size() - 1, -1, -1):
		if shots[i].life <= 0: shots.remove_at(i)
	for enemy in enemies:
		if enemy.hp <= 0: continue
		if enemy.burn > 0:
			enemy.hp -= effective_damage() * 0.20 * dt
			enemy.burn = maxf(0, enemy.burn - dt)
		if enemy.hp <= 0: continue
		var slow_factor: float = 0.55 if enemy.slow > 0 else 1.0
		enemy.slow = maxf(0, enemy.slow - dt)
		var delta: Vector2 = enemy.pos.direction_to(player) * float(enemy.speed) * slow_factor * dt
		enemy.pos = World.enemy_move(world_seed, enemy.pos, delta, float(enemy.radius), float(enemy.steer))
		if player.distance_to(enemy.pos) <= float(enemy.radius) + 7.0 and hurt_cd <= 0:
			hp = maxf(0, hp - float(enemy.damage))
			hurt_cd = 0.45
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			var dead: Dictionary = enemies[i]
			if str(dead.get("encounter", "")) == "":
				kills += 1
				xp += int(dead.xp)
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
			next_xp = roundi(next_xp * 1.25) + 2
			pending_upgrades += 1

func upgrade(choice: int) -> void:
	if pending_upgrades <= 0 or outcome != "": return
	match choice:
		0: damage *= 1.20
		1: interval = maxf(0.16, interval * 0.85)
		2:
			max_hp += 15.0
			hp = minf(max_hp, hp + 25.0)
		_: return
	pending_upgrades -= 1

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
		elif str(e.get("encounter", "")) == "" and distance > DESPAWN_DISTANCE * DESPAWN_DISTANCE:
			enemies.remove_at(i)
			despawned += 1

func _spawn(kind: int) -> void:
	var d: Dictionary = ENEMY_DATA[kind].duplicate()
	d.kind = kind
	d.pos = _spawn_position(float(d.radius))
	d.steer = -1.0 if rng.next_int(2) == 0 else 1.0
	d.hp *= 1.0 + (difficulty - 1) * 0.25
	d.max_hp = d.hp
	d.damage *= 1.0 + (difficulty - 1) * 0.18
	d.slow = 0.0
	d.burn = 0.0
	enemies.append(d)

func effective_damage() -> float:
	return damage * (1.25 if blessing > 0 else 1.0)

func _announce(message: String) -> void:
	site_notice = message
	site_notice_time = 3.0

func _claim(site: Dictionary) -> void:
	var id: String = site.id
	if claimed_sites.has(id): return
	match str(site.kind):
		"treasure":
			treasure_count += 1
			xp += 6
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
			xp += 12
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
		d.hp *= 1.0 + (difficulty - 1) * 0.25
		d.max_hp = d.hp
		d.damage *= 1.0 + (difficulty - 1) * 0.18
		d.xp = 0
		d.slow = 0.0
		d.burn = 0.0
		d.encounter = site.id
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
