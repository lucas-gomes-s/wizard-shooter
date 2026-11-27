extends SceneTree
## Run: godot --headless --path mobile --script tests/smoke.gd
const Genetics = preload("res://domain/genetics.gd")
const Academy = preload("res://domain/academy.gd")
const RunModel = preload("res://gameplay/run.gd")
const Sprites = preload("res://presentation/sprite_library.gd")
const ArenaArt = preload("res://presentation/arena_art.gd")
const World = preload("res://gameplay/dungeon_world.gd")
const DungeonArt = preload("res://presentation/dungeon_art.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var library := Sprites.new()
	for kind in range(4):
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
	run.upgrade(1)
	check(run.pending_upgrades == 0 and run.interval < float(p.interval), "Upgrade applied")
	run.hp = 0
	run.step(1.0 / 60.0, Vector2.ZERO, false)
	check(run.outcome == "Defeated", "Death ends run")
	_test_world(p)
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
