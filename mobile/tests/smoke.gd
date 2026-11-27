extends SceneTree
## Run: godot --headless --path mobile --script tests/smoke.gd
const Genetics = preload("res://domain/genetics.gd")
const Academy = preload("res://domain/academy.gd")
const RunModel = preload("res://gameplay/run.gd")
const Sprites = preload("res://presentation/sprite_library.gd")
const ArenaArt = preload("res://presentation/arena_art.gd")
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
	print("Wizard Shooter smoke: %d failures; 1000 founder/fusion samples" % failures)
	quit(0 if failures == 0 else 1)
