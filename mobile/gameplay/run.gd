extends RefCounted
## Small fixed-step arena simulation; dictionaries are runtime state, not content definitions.
const LIMITS := Rect2(14, 100, 332, 420)
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
var player := Vector2(180, 310)
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
	player += movement.limit_length() * speed * dt
	player = player.clamp(LIMITS.position, LIMITS.end)
	auto_cd = maxf(0, auto_cd - dt)
	special_cd = maxf(0, special_cd - dt)
	hurt_cd = maxf(0, hurt_cd - dt)
	special_fx = maxf(0, special_fx - dt)
	spawn_cd -= dt
	if spawn_cd <= 0 and enemies.size() < MAX_ENEMIES:
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
				enemy.hp -= damage * 2.5
				if phenotype.affinity != "fire":
					enemy.slow = 2.5
				else:
					enemy.burn = 2.0
	for shot in shots:
		shot.pos += shot.vel * dt
		shot.life -= dt
		for enemy in enemies:
			if enemy.hp > 0 and shot.pos.distance_to(enemy.pos) <= float(enemy.radius) + 3.0:
				enemy.hp -= damage
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
			enemy.hp -= damage * 0.20 * dt
			enemy.burn = maxf(0, enemy.burn - dt)
		if enemy.hp <= 0: continue
		var slow_factor: float = 0.55 if enemy.slow > 0 else 1.0
		enemy.slow = maxf(0, enemy.slow - dt)
		enemy.pos += enemy.pos.direction_to(player) * float(enemy.speed) * slow_factor * dt
		if player.distance_to(enemy.pos) <= float(enemy.radius) + 7.0 and hurt_cd <= 0:
			hp = maxf(0, hp - float(enemy.damage))
			hurt_cd = 0.45
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			var dead: Dictionary = enemies[i]
			kills += 1
			xp += int(dead.xp)
			if dead.kind == 3: boss_defeated = true
			enemies.remove_at(i)
	if hp <= 0:
		outcome = "Defeated"
	elif boss_defeated:
		outcome = "Victory"
	else:
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

func _spawn(kind: int) -> void:
	var d: Dictionary = ENEMY_DATA[kind].duplicate()
	var side: int = rng.next_int(4)
	var pos := Vector2.ZERO
	match side:
		0: pos = Vector2(8, 100 + rng.next_int(421))
		1: pos = Vector2(352, 100 + rng.next_int(421))
		2: pos = Vector2(14 + rng.next_int(333), 94)
		3: pos = Vector2(14 + rng.next_int(333), 526)
	d.kind = kind
	d.pos = pos
	d.hp *= 1.0 + (difficulty - 1) * 0.25
	d.damage *= 1.0 + (difficulty - 1) * 0.18
	d.slow = 0.0
	d.burn = 0.0
	enemies.append(d)
