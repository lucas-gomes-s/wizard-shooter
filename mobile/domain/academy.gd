extends RefCounted
## Session-only collection prototype. Durable transactions are a later milestone.
const Genetics = preload("res://domain/genetics.gd")
const MATURE_XP := 40 # accelerated test pacing
var roster: Array[Dictionary] = []
var archive: Array[Dictionary] = []
var essence := 10
var next_seed: int
var settled_runs: Dictionary = {}

func _init(seed: int = 42) -> void:
	next_seed = seed
	_add(Genetics.founder(_seed()))
	_add(Genetics.founder(_seed()))

func _seed() -> int:
	next_seed += 7919
	return next_seed

func _add(genome: Dictionary, parents: Array = []) -> Dictionary:
	var c := {"id": "W%06d" % int(genome.seed), "genome": genome, "phenotype": Genetics.express(genome), "xp": 0, "parents": parents}
	roster.append(c)
	return c

func summon() -> bool:
	if essence < 10: return false
	essence -= 10
	_add(Genetics.founder(_seed()))
	return true

func eligible(a: Dictionary, b: Dictionary) -> bool:
	return a.id != b.id and roster.has(a) and roster.has(b) and int(a.genome.tier) == 1 and int(b.genome.tier) == 1 and int(a.xp) >= MATURE_XP and int(b.xp) >= MATURE_XP

func fuse(a: Dictionary, b: Dictionary) -> Dictionary:
	if not eligible(a, b): return {}
	var child := Genetics.fuse(a.genome, b.genome, _seed())
	if child.is_empty(): return {}
	roster.erase(a)
	roster.erase(b)
	archive.append(a)
	archive.append(b)
	return _add(child, [a.id, b.id])

func reward(run_id: int, active: Dictionary, apprentice: Dictionary, earned: int, victory: bool) -> bool:
	if settled_runs.has(run_id) or not roster.has(active): return false
	settled_runs[run_id] = true
	var amount := maxi(0, earned)
	active.xp += amount
	if not apprentice.is_empty() and apprentice.id != active.id and roster.has(apprentice):
		apprentice.xp += floori(amount * 0.25)
	essence += floori(amount / 8.0)
	if victory:
		essence += 10
		_add(Genetics.founder(_seed()))
	return true
