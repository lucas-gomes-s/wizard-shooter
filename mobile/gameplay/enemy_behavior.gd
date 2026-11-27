extends RefCounted
## Enemy state machine, independent of rendering. Attack targets lock at windup.
const World = preload("res://gameplay/dungeon_world.gd")
const WEB_RADIUS := 29.0
const BREATH_RADIUS := 44.0
const MAX_WEBS := 16
const MAX_BOLTS := 48
const CHARGE_SPEED := 175.0
const BOSS_CHARGE_SPEED := 195.0
const CHARGE_TIME := 0.65

static func initialize(e: Dictionary) -> void:
	e.attack = "chase"
	e.attack_time = 0.0
	e.attack_total = 0.0
	e.attack_cd = 1.2 + float(int(e.uid) % 5) * 0.20
	e.attack_target = e.pos
	e.attack_dir = Vector2.ZERO
	e.attack_hit = false
	e.attack_index = 0

static func recover(e: Dictionary, cooldown: float) -> void:
	e.attack = "recover"
	e.attack_time = 0.55
	e.attack_total = 0.55
	e.attack_cd = cooldown

static func windup(e: Dictionary, kind: String, target: Vector2, seconds: float) -> void:
	e.attack = kind
	e.attack_time = seconds
	e.attack_total = seconds
	e.attack_target = target
	var start: Vector2 = e.pos
	e.attack_dir = start.direction_to(target)
	if e.attack_dir == Vector2.ZERO: e.attack_dir = Vector2.RIGHT
	e.attack_hit = false

static func tick(run: Variant, e: Dictionary, dt: float, slow: float, frozen: bool) -> void:
	if frozen:
		# Freeze interrupts a telegraphed attack, including a charge.
		if e.attack not in ["chase","recover"]: recover(e, 1.0)
		return
	var pos: Vector2 = e.pos
	var target: Vector2 = run.player
	var distance := pos.distance_to(target)
	var direction := pos.direction_to(target)
	e.attack_cd = maxf(0, float(e.attack_cd) - dt)
	e.attack_time = maxf(0, float(e.attack_time) - dt)
	match str(e.attack):
		"recover":
			if e.attack_time <= 0: e.attack = "chase"
			return
		"web":
			if e.attack_time <= 0:
				run.add_web(e.attack_target)
				recover(e, 4.2)
			return
		"bolt":
			if e.attack_time <= 0:
				run.add_enemy_bolt(pos, e.attack_dir, float(e.damage))
				recover(e, 2.6)
			return
		"breath":
			if e.attack_time <= 0:
				var center: Vector2 = e.attack_target
				run.add_danger_flash(center, BREATH_RADIUS)
				if center.distance_to(target) <= BREATH_RADIUS + run.PLAYER_RADIUS and World.line_clear(run.world_seed, pos, target, 1.0):
					run.take_hit(float(e.damage) * 1.25, "Dragon breath")
				recover(e, 2.8)
			return
		"charge_windup":
			if e.attack_time <= 0:
				e.attack = "charge"
				e.attack_time = CHARGE_TIME
				e.attack_total = CHARGE_TIME
			return
		"charge":
			var charge_speed := BOSS_CHARGE_SPEED if int(e.kind) == 3 else CHARGE_SPEED
			var delta: Vector2 = e.attack_dir * charge_speed * slow * dt
			var next := World.move(run.world_seed, pos, delta, float(e.radius))
			e.pos = next
			if not e.attack_hit and Geometry2D.get_closest_point_to_segment(target, pos, next).distance_to(target) <= float(e.radius) + run.PLAYER_RADIUS:
				e.attack_hit = true
				run.take_hit(float(e.damage) * 1.35, str(e.name) + " charge")
			if e.attack_time <= 0 or (delta.length_squared() > 0.0 and next.distance_squared_to(pos) < delta.length_squared() * 0.2):
				recover(e, 2.5)
			return
	# A 125px activation distance stays inside the narrowest portrait half-view
	# even with the maximum 24px camera lag. Attacks never aim at an unseen player.
	var visible := distance <= 125.0
	var can_attack: bool = visible and e.attack_cd <= 0 and World.line_clear(run.world_seed, pos, target, 2.0)
	if can_attack:
		match int(e.kind):
			1:
				if distance >= 25.0:
					windup(e, "web", target, 0.65)
					return
			2:
				if distance >= 28.0:
					windup(e, "charge_windup", target, 0.75)
					return
			3:
				if int(e.attack_index) % 2 == 0:
					windup(e, "breath", target, 1.05)
				else:
					windup(e, "charge_windup", target, 0.90)
				e.attack_index += 1
				return
			4:
				windup(e, "bolt", target, 0.70)
				return
	# Ranged casters maintain a standoff distance instead of rushing into melee.
	if int(e.kind) == 4:
		if distance < 78.0: direction = -direction
		elif distance <= 115.0 and World.line_clear(run.world_seed, pos, target, 2.0): direction = Vector2.ZERO
	var delta := direction * float(e.speed) * slow * dt
	e.pos = World.enemy_move(run.world_seed, pos, delta, float(e.radius), float(e.steer))
