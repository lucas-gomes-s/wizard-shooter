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
var active_id := ""
var apprentice_id := ""
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
	active_id=str(roster[0].id)
	apprentice_id=str(roster[1].id)
	if store != null and not store.commit(snapshot()):
		blocked = true
		error = store.error

func snapshot() -> Dictionary:
	return {"roster": roster.duplicate(true), "archive": archive.duplicate(true), "essence": essence,
		"next_seed": next_seed, "next_run_id": next_run_id, "settled_runs": settled_runs.duplicate(true),
		"active_id":active_id,"apprentice_id":apprentice_id}

func _restore(p: Dictionary) -> void:
	roster.clear()
	archive.clear()
	for c in p.roster:
		var record: Dictionary = c.duplicate(true)
		_normalize_record(record)
		roster.append(record)
	for c in p.archive:
		var record: Dictionary = c.duplicate(true)
		_normalize_record(record)
		archive.append(record)
	essence = int(p.essence)
	next_seed = int(p.next_seed)
	next_run_id = int(p.next_run_id)
	settled_runs = p.settled_runs.duplicate(true)
	# Schema 1 profiles written before assignment persistence have neither field.
	active_id=str(p.get("active_id",roster[0].id))
	apprentice_id=str(p.get("apprentice_id",roster[1].id if roster.size()>1 else ""))

func _normalize_record(record: Dictionary) -> void:
	record.xp = int(record.xp)
	var g: Dictionary = record.genome
	for k in ["version", "tier", "seed", "hat", "robe", "staff", "power"]:
		g[k] = int(g[k])
	for k in ["stoneborn", "fae"]:
		g.ancestry[k] = int(g.ancestry[k])
	for k in ["tier", "hat", "robe", "staff"]:
		record.phenotype[k] = int(record.phenotype[k])
	# Old saves receive stable, seed-derived talent alleles; existing base stats stay unchanged.
	g.talents = Genetics.talents_for(g)
	record.phenotype.passives = Genetics.expressed_talents(g)

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

func assign(active: String, apprentice: String) -> bool:
	if blocked or find_active(active).is_empty() or active==apprentice or (not apprentice.is_empty() and find_active(apprentice).is_empty()):
		error="Invalid wizard assignment."
		return false
	if active==active_id and apprentice==apprentice_id:
		error=""
		return true
	var before := snapshot()
	active_id=active
	apprentice_id=apprentice
	return _commit(before)

func restore_backup(profile: Dictionary) -> bool:
	# Import is a full replacement, never a merge. No live state changes before durable commit.
	if not Store.valid_profile(profile):
		error="Invalid backup profile."
		return false
	if store!=null and not store.restore_profile(profile):
		error=store.error
		return false
	_restore(profile)
	blocked=false
	error=""
	notice="Backup restored."
	return true

func summon() -> bool:
	if blocked: return false
	if essence < 10:
		error = "Not enough essence."
		return false
	var before := snapshot()
	essence -= 10
	var newcomer := _add(Genetics.founder(_seed()))
	active_id=str(newcomer.id)
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
	active_id=str(result.id)
	apprentice_id=""
	if not _commit(before): return {}
	return result

func allocate_run() -> int:
	if blocked: return -1
	var before := snapshot()
	var id := next_run_id
	next_run_id += 1
	return id if _commit(before) else -1

func reward(run_id: int, active: Dictionary, apprentice: Dictionary, earned: int, victory: bool, exploration_essence: int = 0) -> bool:
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
	essence += floori(amount / 8.0) + maxi(0, exploration_essence)
	if victory:
		essence += 10
		_add(Genetics.founder(_seed()))
	return _commit(before)

## Public phenotype-only hints. No raw alleles or exact probabilities exposed.
func fusion_hint(a: Dictionary, b: Dictionary) -> String:
	if a.is_empty() or b.is_empty(): return "Select two wizards."
	if not eligible(a, b):
		return "Both parents must be unlocked, mature Tier I wizards (40 XP each)."
	var hints := PackedStringArray()
	hints.append("Mixed anatomy is possible." if a.phenotype.body != b.phenotype.body else "Shared ancestry may persist.")
	hints.append("Their elements may combine." if a.phenotype.affinity != b.phenotype.affinity else "Their shared element may persist, or dormant magic may emerge.")
	hints.append("Unexpected mutations are possible.")
	hints.append("A Tier II descendant is guaranteed. Both parents retire permanently.")
	return "\n".join(hints)

func parents_of(c: Dictionary) -> Array[Dictionary]:
	var parents: Array[Dictionary] = []
	for id in c.get("parents", []):
		for record in archive:
			if record.id == id:
				parents.append(record)
				break
	return parents
