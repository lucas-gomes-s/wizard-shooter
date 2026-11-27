extends SceneTree
## Run: godot --headless --path mobile --script tests/smoke.gd
const Genetics = preload("res://domain/genetics.gd")
const Academy = preload("res://domain/academy.gd")
const RunModel = preload("res://gameplay/run.gd")
const Sprites = preload("res://presentation/sprite_library.gd")
const ArenaArt = preload("res://presentation/arena_art.gd")
const World = preload("res://gameplay/dungeon_world.gd")
const DungeonArt = preload("res://presentation/dungeon_art.gd")
const Abilities = preload("res://gameplay/ability_catalog.gd")
const Upgrades = preload("res://gameplay/upgrade_catalog.gd")
const EnemyAI = preload("res://gameplay/enemy_behavior.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var library := Sprites.new()
	for kind in range(5):
		var image := ArenaArt.enemy_image(kind)
		check(image.get_size() == Vector2i(16, 16), "Enemy sprite dimensions")
		check(image.get_used_rect().get_area() > 0, "Enemy sprite nonempty")
	for affinity in ["fire", "ice", "steam"]:
		check(ArenaArt.projectile_image(affinity).get_used_rect().get_area() > 0, "Spell sprite nonempty")
	check(ArenaArt.floor_image().get_size() == Vector2i(360, 448), "Floor dimensions")
	var bodies: Dictionary = {}
	var affinities: Dictionary = {}
	for i in range(1000):
		var a := Genetics.founder(i)
		var b := Genetics.founder(i + 5000)
		var c := Genetics.fuse(a, b, i + 10000)
		check(a == Genetics.founder(i), "Founder determinism")
		check(c == Genetics.fuse(b, a, i + 10000), "Parent symmetry")
		check(int(c.ancestry.stoneborn) + int(c.ancestry.fae) == 10000, "Ancestry invariant")
		var p := Genetics.express(c)
		check(float(p.health) > 0 and float(p.speed) > 0, "Playable phenotype")
		check(library.tiles(p, 0).size() == 7 and library.tiles(p, 1).size() == 7, "Layer coverage")
		bodies[p.body] = true
		affinities[p.affinity] = true
	check(bodies.size() == 3, "All body types sampled")
	check(affinities.size() == 3, "All affinities sampled")
	var academy := Academy.new()
	var a: Dictionary = academy.roster[0]
	var b: Dictionary = academy.roster[1]
	check(not academy.eligible(a, b), "Immature parents cannot fuse")
	check(academy.fusion_hint(a, b).contains("mature"), "Ineligible fusion hint")
	check(academy.reward(1, a, b, 160, false), "First reward")
	check(not academy.reward(1, a, b, 160, false), "Duplicate reward rejected")
	check(int(b.xp) == 40, "Shared XP")
	check(academy.fusion_hint(a, b).contains("guaranteed"), "Eligible fusion hint")
	var child: Dictionary = academy.fuse(a, b)
	check(not child.is_empty() and academy.archive.size() == 2 and academy.roster.size() == 1, "Fusion retires parents")
	check(not academy.eligible(a, b), "Retired parents not reusable")
	check(academy.parents_of(child).size() == 2, "Lineage resolves archived parents")
	var p: Dictionary = child.phenotype
	var run := RunModel.new(p, true, 1, 7)
	var start: Vector2 = run.player
	run.step(1.0 / 60.0, Vector2(1, 1), false)
	check(absf(start.distance_to(run.player) - float(p.speed) / 60.0) < 0.001, "Normalized diagonal movement")
	run.step(1.0 / 60.0, Vector2.ZERO, true)
	check(run.special_cd > 0, "Manual spell cooldown")
	run.pending_upgrades = 1
	var t: float = run.elapsed
	run.step(1.0 / 60.0, Vector2.RIGHT, false)
	check(run.elapsed == t, "Upgrade pauses time")
	run.ensure_upgrade_offer()
	var chosen: String = run.upgrade_offer[0]
	run.upgrade(0)
	check(run.pending_upgrades == 0 and int(run.upgrade_ranks.get(chosen, 0)) == 1, "Upgrade applied")
	run.hp = 0
	run.step(1.0 / 60.0, Vector2.ZERO, false)
	check(run.outcome == "Defeated", "Death ends run")
	_test_world(p)
	_test_sites(p)
	_test_abilities(p)
	_test_upgrades(p)
	_test_enemies(p)
	print("Wizard Shooter smoke: %d failures; 1000 founder/fusion samples" % failures)
	quit(0 if failures == 0 else 1)

func _test_world(p: Dictionary) -> void:
	check(World.chunk_at(Vector2(-1, -257)) == Vector2i(-1, -2), "Negative chunk coordinates")
	var chunk := Vector2i(-3, 6)
	var first := DungeonArt.chunk_image(7, chunk)
	var second := DungeonArt.chunk_image(7, chunk)
	check(first.get_data() == second.get_data(), "Chunk regeneration deterministic")
	check(first.get_data() != DungeonArt.chunk_image(8, chunk).get_data(), "World seed varies terrain")
	var art := DungeonArt.new()
	art.reset(7)
	for i in range(16):
		art.prepare(Rect2(Vector2(i * 1024, -i * 512), Vector2(360, 448)))
		check(art.cache.size() <= 9, "Chunk cache bounded while exploring")
	var found := false
	for x in range(-4, 5):
		var pillar := World.pillar(7, Vector2i(x, 0))
		if pillar.is_empty(): continue
		found = true
		var pos: Vector2 = pillar.pos
		check(not World.clear_at(7, pos, 7), "Pillar collision center")
		var from := pos - Vector2(19, 0)
		var moved := World.move(7, from, Vector2(2, 0), 7)
		check(moved == from, "Cannot walk through pillar")
		break
	check(found, "Pillar fixture exists")
	var exploration := RunModel.new(p, true, 1, 7)
	exploration.spawn_cd = 100000.0
	for y in range(-10, 2):
		for x in range(-10, 2):
			var site := World.site(7, Vector2i(x, y))
			if not site.is_empty(): exploration.claimed_sites[site.id] = true
	for i in range(600):
		exploration.step(1.0 / 60.0, Vector2.LEFT, false)
	check(exploration.player.x < -500, "Unbounded westward travel")
	for i in range(600):
		exploration.step(1.0 / 60.0, Vector2.UP, false)
	check(exploration.player.y < -500, "Unbounded northward travel")
	for i in range(40):
		exploration._spawn(i % 3)
		var enemy: Dictionary = exploration.enemies.back()
		var offset: Vector2 = enemy.pos - exploration.player
		check(absf(offset.x) >= 260 or absf(offset.y) >= 304, "Enemies spawn outside camera")
		check(World.clear_at(7, enemy.pos, float(enemy.radius)), "Spawn clear of obstacles")
	var previous_kills := exploration.kills
	exploration.player += Vector2(4000, 4000)
	exploration._recycle_far_enemies()
	check(exploration.enemies.is_empty() and exploration.kills == previous_kills, "No rewards for recycling distant enemies")
	exploration._spawn(3)
	exploration.enemies[0].hp = 123.0
	exploration.player += Vector2(4000, 4000)
	exploration._recycle_far_enemies()
	check(exploration.enemies.size() == 1 and exploration.enemies[0].hp == 123.0, "Boss relocates without resetting health")
	check(exploration.player.distance_to(exploration.enemies[0].pos) < RunModel.BOSS_RELOCATE_DISTANCE, "Boss remains reachable")
	print("Infinite world checks complete")

func _test_sites(p: Dictionary) -> void:
	var samples: Dictionary = {}
	for y in range(-8, 9):
		for x in range(-8, 9):
			var chunk := Vector2i(x,y)
			var site := World.site(7, chunk)
			check(site == World.site(7, chunk), "Site generation deterministic")
			if site.is_empty(): continue
			check(World.clear_at(7, site.pos, 28), "Site clear of pillar")
			check(World.chunk_at(site.pos) == chunk, "Site stays in its chunk")
			samples[site.kind] = site
	check(samples.size() == 4, "All four site types generated")
	if samples.size() != 4: return
	var run := RunModel.new(p, true, 1, 7)
	run.spawn_cd = 100000.0
	var treasure: Dictionary = samples.treasure
	run.player = treasure.pos
	run._update_sites()
	check(run.xp == 6 and run.exploration_xp == 4 and run.exploration_essence == 2, "Treasure rewards")
	run._update_sites()
	check(run.xp == 6 and run.treasure_count == 1, "Treasure cannot be claimed twice")
	var healing: Dictionary = samples.healing
	run.player = healing.pos
	run._update_sites()
	check(not run.claimed_sites.has(healing.id), "Full health does not waste shrine")
	run.hp = run.max_hp * 0.5
	run._update_sites()
	check(absf(run.hp - run.max_hp * 0.85) < 0.001, "Healing shrine restores 35 percent")
	var arcane: Dictionary = samples.arcane
	run.player = arcane.pos
	var baseline_damage := run.effective_damage()
	run._update_sites()
	check(run.blessing == 20.0 and absf(run.effective_damage() - baseline_damage * 1.25) < 0.001, "Arcane buff applies")
	run.blessing = 0.0
	run._update_sites()
	check(run.blessing == 0.0, "Arcane shrine cannot refresh by revisiting")
	var guarded: Dictionary = samples.guarded
	run.player = guarded.pos
	run._update_sites()
	check(run._guards_remaining() == 3 and not run.claimed_sites.has(guarded.id), "Guarded cache starts one ambush")
	run._update_sites()
	check(run._guards_remaining() == 3, "Ambush cannot spawn duplicates")
	run.player += Vector2(1000,0)
	run._abandon_far_encounter()
	check(run.active_encounter.is_empty() and run.enemies.is_empty() and run.exploration_essence == 2, "Abandonment cannot grant rewards")
	run.player = guarded.pos
	run._update_sites()
	for enemy in run.enemies: enemy.hp = 0
	run.step(1.0 / 60.0, Vector2.ZERO, false)
	check(run.encounters_cleared == 1 and run.exploration_essence == 6 and run.kills == 0, "Guardians grant cache once, no duplicate kill reward")
	run._update_sites()
	check(run.encounters_cleared == 1, "Guarded cache remains claimed")
	var academy := Academy.new()
	var active: Dictionary = academy.roster[0]
	var partner: Dictionary = academy.roster[1]
	var before := academy.essence
	var earned := run.training_reward()
	check(academy.reward(1, active, partner, earned, false, run.exploration_essence), "Exploration rewards settled")
	check(academy.essence == before + floori(earned / 8.0) + 6, "Exploration essence granted exactly once")
	check(not academy.reward(1, active, partner, earned, false, 6), "Duplicate exploration settlement rejected")
	print("Exploration checks complete")

func _test_abilities(base: Dictionary) -> void:
	var p := base.duplicate(true)
	p.mutation = "none"
	p.passives = []
	for affinity in ["fire","ice","steam"]:
		p.affinity = affinity
		var run := RunModel.new(p, true, 1, 7)
		run._spawn(0)
		run.enemies[0].pos = Vector2(15,0)
		check(run._cast_basic(), "Basic spell targets")
		var shot: Dictionary = run.shots[0]
		shot.pos = run.enemies[0].pos
		shot.vel = Vector2.ZERO
		run._update_shots(0.01)
		var e: Dictionary = run.enemies[0]
		if affinity == "fire":
			check(e.burn > 0 and e.burn_dps > 0, "Fire burn")
		elif affinity == "ice":
			check(e.chill > 0 and e.slow > 0 and run.shots.size() == 1, "Ice lance pierces and chills")
			var hp_before: float = e.hp
			run._update_shots(0.01)
			check(e.hp == hp_before, "Piercing shot cannot hit same target twice")
			run._cast_special()
			check(e.chill == 0 and e.freeze > 0, "Frost shatters chill and freezes")
		else:
			check(run.clouds.size() == 1, "Steam orb creates cloud")
			run._cast_special()
			check(run.clouds.size() == 2, "Steam special creates persistent cloud")
			for i in range(20): run._add_cloud(Vector2.ZERO, 42, 2, 0.3, "steam")
			check(run.clouds.size() == Abilities.MAX_CLOUDS, "Cloud cap")
			var before: float = e.hp
			run._update_clouds(0.1)
			check(before > e.hp and absf(before - float(e.hp) - run.effective_damage() * 0.3 * 0.1) < 0.001, "Clouds do not stack")
	p.affinity = "fire"
	p.passives = ["focused"]
	var focused := RunModel.new(p, true, 1, 7)
	check(absf(focused.effective_damage() - float(p.damage) * 1.12) < 0.001, "Focused passive damage")
	p.passives = ["resilient"]
	check(float(Abilities.compile(p).modifiers.incoming) < 1.0, "Resilient passive")
	p.passives = ["quickcast"]
	check(float(Abilities.compile(p).modifiers.interval) < 1.0, "Quickcast passive")
	p.passives = ["flow"]
	check(float(Abilities.compile(p).special.cooldown) < 7.0, "Flow passive")
	p.mutation = "crystal_wings"
	check(Abilities.compile(p).special.has("ward"), "Wing mutation ward")
	p.mutation = "living_flame"
	check(Abilities.compile(p).special.has("trail"), "Flame mutation trail")
	var a := Genetics.founder(42)
	var b := Genetics.founder(43)
	var child := Genetics.fuse(a,b,44)
	check(child.talents.size() == 2, "Inherited talent pair")
	check(child == Genetics.fuse(b,a,44), "Talent inheritance symmetric")
	a.erase("talents")
	check(Genetics.talents_for(a) == Genetics.talents_for(a), "Legacy talents deterministic")
	print("Ability checks complete")

func _test_upgrades(base: Dictionary) -> void:
	var p := base.duplicate(true)
	p.affinity = "fire"
	p.mutation = "living_flame"
	p.passives = ["focused"]
	var a := RunModel.new(p, true, 1, 42)
	var b := RunModel.new(p, true, 1, 42)
	a.pending_upgrades = 2
	b.pending_upgrades = 2
	a.ensure_upgrade_offer()
	b.ensure_upgrade_offer()
	check(a.upgrade_offer == b.upgrade_offer and a.upgrade_offer.size() == 3, "Seeded upgrade offer")
	var initial: Array[String] = a.upgrade_offer.duplicate()
	a.ensure_upgrade_offer()
	check(initial == a.upgrade_offer, "Offer cannot reroll on refresh")
	check(Upgrades.DEFINITIONS[initial[0]].category == "Universal", "Guaranteed universal")
	check(Upgrades.DEFINITIONS[initial[1]].affinity == "fire", "Guaranteed matching affinity")
	check(Upgrades.DEFINITIONS[initial[2]].category in ["Species","Talent","Mutation"], "Guaranteed genetic option")
	a.upgrade(-1)
	a.upgrade(3)
	check(a.pending_upgrades == 2 and initial == a.upgrade_offer, "Invalid choices do not spend upgrade")
	a.upgrade(1)
	check(a.pending_upgrades == 1 and int(a.upgrade_ranks.get(initial[1],0)) == 1 and a.upgrade_offer.size() == 3, "Queued upgrade gets fresh offer")
	var allowed := true
	for id in a.upgrade_offer:
		allowed = allowed and Upgrades.eligible(id, p, a.upgrade_ranks)
	check(allowed, "Every offered upgrade eligible")
	check(not Upgrades.eligible("pierce", p, {}) and not Upgrades.eligible("wingward", p, {}) and not Upgrades.eligible("fortify", p, {}), "Foreign affinity and unexpressed genetics excluded")
	check(not Upgrades.eligible("kindle", p, {"kindle":4}), "Rank cap")
	var snapshot := p.duplicate(true)
	a._apply_upgrade("wildfire")
	check(a.burst_radius == 46.0 and absf(a.burst_power - 0.66) < 0.001, "Wildfire actual effect")
	var burn_before: float = a.kit.basic.effects[0].rate
	a._apply_upgrade("kindle")
	check(absf(float(a.kit.basic.effects[0].rate) - burn_before * 1.25) < 0.001, "Kindle modifies effect")
	check(p == snapshot, "No permanent phenotype changes")
	var capped: Dictionary = {}
	for id in Upgrades.DEFINITIONS:
		var cap := int(Upgrades.DEFINITIONS[id].cap)
		if cap > 0: capped[id] = cap
	check(Upgrades.offer(p, capped, a.upgrade_rng) == ["vitality"], "Endless cap fallback")
	p.affinity = "ice"
	p.mutation = "none"
	var ice := RunModel.new(p, true, 1, 42)
	ice._apply_upgrade("pierce")
	check(ice.kit.basic.pierce == 3, "Pierce upgrade changes projectile")
	p.affinity = "steam"
	var steam := RunModel.new(p, true, 1, 42)
	steam._apply_upgrade("mist")
	check(steam.kit.basic.effects[0].radius == 50.0, "Mist upgrade changes cloud radius")
	steam._apply_upgrade("pressure")
	check(absf(float(steam.kit.special.rate) - 0.78) < 0.001, "Pressure upgrade changes vortex")
	print("Character-specific upgrade checks complete")

func _test_enemies(base: Dictionary) -> void:
	var p := base.duplicate(true)
	p.passives = []
	p.mutation = "none"
	var run := RunModel.new(p, true, 1, 7)
	run.spawn_cd = 100000.0
	run._spawn(1)
	var spider: Dictionary = run.enemies[0]
	spider.pos = Vector2(60,0)
	spider.attack_cd = 0.0
	EnemyAI.tick(run, spider, 0.01, 1.0, false)
	check(spider.attack == "web" and run.webs.is_empty(), "Web has readable windup")
	run.player = Vector2(0,80)
	EnemyAI.tick(run, spider, 0.7, 1.0, false)
	check(run.webs.size() == 1 and run.webs[0].pos == Vector2.ZERO, "Web target locks")
	run.enemies.clear()
	run.player = Vector2.ZERO
	run.step(1.0 / 60.0, Vector2.RIGHT, false)
	check(run.webbed and absf(run.player.x - run.speed / 120.0) < 0.001, "Web slows player")
	run.webs.clear()
	run.player = Vector2.ZERO
	run._spawn(2)
	var orc: Dictionary = run.enemies[0]
	orc.pos = Vector2(75,0)
	orc.attack_cd = 0.0
	EnemyAI.tick(run, orc, 0.01, 1.0, false)
	check(orc.attack == "charge_windup", "Orc charge windup")
	var hp_before := run.hp
	run.player = Vector2(0,80)
	EnemyAI.tick(run, orc, 0.8, 1.0, false)
	for i in range(40): EnemyAI.tick(run, orc, 1.0/60.0, 1.0, false)
	check(run.hp == hp_before, "Dodging locked charge avoids damage")
	EnemyAI.windup(orc,"charge_windup",run.player,0.7)
	EnemyAI.tick(run,orc,0.1,0.0,true)
	check(orc.attack == "recover", "Freeze interrupts charge windup")
	run.enemies.clear()
	run.player = Vector2.ZERO
	run._spawn(4)
	var caster: Dictionary = run.enemies[0]
	caster.pos = Vector2(100,0)
	caster.attack_cd = 0.0
	EnemyAI.tick(run,caster,0.01,1.0,false)
	check(caster.attack == "bolt" and run.enemy_bolts.is_empty(), "Warlock telegraphs bolt")
	EnemyAI.tick(run,caster,0.8,1.0,false)
	check(run.enemy_bolts.size() == 1, "Warlock fires once")
	run.hurt_cd = 0.0
	hp_before = run.hp
	for i in range(60): run._update_enemy_hazards(1.0/60.0)
	check(run.hp < hp_before and run.enemy_bolts.is_empty(), "Bolt collision damages once")
	for i in range(70): run.add_enemy_bolt(Vector2.ZERO,Vector2.RIGHT,1.0)
	check(run.enemy_bolts.size() == EnemyAI.MAX_BOLTS, "Enemy bolt budget")
	for i in range(40): run.add_web(Vector2.ZERO)
	check(run.webs.size() == EnemyAI.MAX_WEBS, "Web budget")
	run.enemies.clear()
	run.enemy_bolts.clear()
	run.webs.clear()
	run._spawn(3)
	var dragon: Dictionary = run.enemies[0]
	dragon.pos = Vector2(90,0)
	dragon.attack_cd = 0.0
	EnemyAI.tick(run,dragon,0.01,1.0,false)
	check(dragon.attack == "breath", "Boss first attack breath")
	run.player = Vector2(0,80)
	run.hurt_cd = 0.0
	hp_before = run.hp
	EnemyAI.tick(run,dragon,1.1,1.0,false)
	check(run.hp == hp_before and run.danger_flashes.size() == 1, "Breath can be dodged")
	dragon.attack = "chase"
	dragon.attack_cd = 0.0
	run.player = Vector2.ZERO
	EnemyAI.tick(run,dragon,0.01,1.0,false)
	check(dragon.attack == "charge_windup", "Boss alternates attacks")
	for x in range(-4,5):
		var pillar := World.pillar(7,Vector2i(x,0))
		if pillar.is_empty(): continue
		var center: Vector2 = pillar.pos
		check(not World.line_clear(7,center-Vector2(25,0),center+Vector2(25,0),2.0), "Pillar blocks line of sight")
		break
	print("Enemy behavior checks complete")
