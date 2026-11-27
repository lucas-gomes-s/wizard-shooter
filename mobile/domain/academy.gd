extends RefCounted
## Persistent collection use cases. All changes are committed before reporting success.
const Genetics = preload("res://domain/genetics.gd")
const Store = preload("res://persistence/profile_store.gd")
const MATURE_XP := 40
var roster: Array[Dictionary] = []
var archive: Array[Dictionary] = []
var essence := 10
var next_seed: int
var next_run_id := 1
var settled_runs: Dictionary = {}
var store: Variant
var blocked := false
var error := ""
var notice := ""

func _init(seed: int = 42, profile_store: Variant = null) -> void:
	store = profile_store
	if store != null:
		var loaded: Dictionary = store.load_profile()
		if loaded.status == "blocked":
			blocked = true
			error = store.error
			return
		if loaded.status == "ok":
			_restore(loaded.profile)
			if store.recovered: notice = "Recovered last valid save copy."
			return
	next_seed = seed
	_add(Genetics.founder(_seed()))
	_add(Genetics.founder(_seed()))
	if store != null and not store.commit(snapshot()):
		blocked = true
		error = store.error

func snapshot() -> Dictionary:
	return {"roster": roster.duplicate(true), "archive": archive.duplicate(true), "essence": essence,
		"next_seed": next_seed, "next_run_id": next_run_id, "settled_runs": settled_runs.duplicate(true)}

func _restore(p: Dictionary) -> void:
	roster.clear()
	archive.clear()
	for c in p.roster:
		var record: Dictionary = c.duplicate(true)
		record.xp = int(record.xp)
		roster.append(record)
	for c in p.archive:
		var record: Dictionary = c.duplicate(true)
		record.xp = int(record.xp)
		archive.append(record)
	essence = int(p.essence)
	next_seed = int(p.next_seed)
	next_run_id = int(p.next_run_id)
	settled_runs = p.settled_runs.duplicate(true)

func _commit(before: Dictionary) -> bool:
	if store == null or store.commit(snapshot()):
		error = ""
		return true
	error = store.error
	_restore(before)
	return false

func _seed() -> int:
	next_seed += 7919
	return next_seed

func _add(genome: Dictionary, parents: Array = []) -> Dictionary:
	var c := {"id": "W%06d" % int(genome.seed), "genome": genome, "phenotype": Genetics.express(genome), "xp": 0, "parents": parents, "locked": false}
	roster.append(c)
	return c

func find_active(id: String) -> Dictionary:
	for c in roster:
		if c.id == id: return c
	return {}

func summon() -> bool:
	if blocked: return false
	if essence < 10:
		error = "Not enough essence."
		return false
	var before := snapshot()
	essence -= 10
	_add(Genetics.founder(_seed()))
	return _commit(before)

func eligible(a: Dictionary, b: Dictionary) -> bool:
	return not blocked and not a.is_empty() and not b.is_empty() and a.id != b.id and roster.has(a) and roster.has(b) and not a.locked and not b.locked and int(a.genome.tier) == 1 and int(b.genome.tier) == 1 and int(a.xp) >= MATURE_XP and int(b.xp) >= MATURE_XP

func toggle_lock(id: String) -> bool:
	if blocked: return false
	var c := find_active(id)
	if c.is_empty(): return false
	var before := snapshot()
	c.locked = not c.locked
	return _commit(before)

func fuse(a: Dictionary, b: Dictionary) -> Dictionary:
	if not eligible(a, b):
		error = "Select two unlocked, mature Tier I wizards."
		return {}
	var before := snapshot()
	var child := Genetics.fuse(a.genome, b.genome, _seed())
	if child.is_empty():
		_restore(before)
		return {}
	roster.erase(a)
	roster.erase(b)
	archive.append(a)
	archive.append(b)
	var result := _add(child, [a.id, b.id])
	if not _commit(before): return {}
	return result

func allocate_run() -> int:
	if blocked: return -1
	var before := snapshot()
	var id := next_run_id
	next_run_id += 1
	return id if _commit(before) else -1

func reward(run_id: int, active: Dictionary, apprentice: Dictionary, earned: int, victory: bool) -> bool:
	if blocked or run_id < 1 or (store != null and run_id >= next_run_id):
		error = "Invalid run."
		return false
	var receipt := str(run_id)
	if settled_runs.has(receipt):
		error = "Run already settled."
		return false
	if active.is_empty() or not roster.has(active):
		error = "Active wizard no longer exists."
		return false
	var before := snapshot()
	settled_runs[receipt] = true
	# In-memory unit tests may supply an ID without allocating it.
	next_run_id = maxi(next_run_id, run_id + 1)
	var amount := maxi(0, earned)
	active.xp += amount
	if not apprentice.is_empty() and apprentice.id != active.id and roster.has(apprentice):
		apprentice.xp += floori(amount * 0.25)
	essence += floori(amount / 8.0)
	if victory:
		essence += 10
		_add(Genetics.founder(_seed()))
	return _commit(before)
