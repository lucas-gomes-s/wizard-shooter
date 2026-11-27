extends RefCounted
## Two alternating, checksummed complete snapshots. Never truncate the current slot.
## Single-writer, local-only. A partially written inactive slot cannot invalidate the current slot.
const SCHEMA := 1
var prefix: String
var revision := 0
var current_slot := -1
var error := ""
var recovered := false

func _init(path_prefix: String = "user://wizard_profile") -> void:
	prefix = path_prefix

func slot_path(slot: int) -> String:
	return "%s.%d.json" % [prefix, slot]

static func integer(value: Variant, minimum: int = 0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= 9007199254740991.0

static func valid_record(c: Variant) -> bool:
	if not c is Dictionary: return false
	for k in ["id", "genome", "phenotype", "xp", "parents", "locked"]:
		if not c.has(k): return false
	if not c.id is String or c.id.is_empty() or not integer(c.xp) or not c.parents is Array or not c.locked is bool: return false
	if not c.genome is Dictionary or not c.phenotype is Dictionary: return false
	var g: Dictionary = c.genome
	var p: Dictionary = c.phenotype
	for k in ["version", "tier", "seed", "species", "core", "ancestry", "hat", "robe", "staff", "mutation", "power"]:
		if not g.has(k): return false
	if not integer(g.seed) or g.version != 1 or not g.tier in [1, 2]: return false
	if c.id != "W%06d" % int(g.seed): return false
	if not g.species is Array or g.species.size() != 2 or not g.core is Array or g.core.size() != 2: return false
	for v in g.species:
		if not v in ["stoneborn", "fae"]: return false
	for v in g.core:
		if not v in ["fire", "ice"]: return false
	if not g.ancestry is Dictionary or not integer(g.ancestry.get("stoneborn", -1)) or not integer(g.ancestry.get("fae", -1)): return false
	if int(g.ancestry.stoneborn) + int(g.ancestry.fae) != 10000: return false
	for k in ["hat", "robe", "staff"]:
		if not integer(g[k]) or int(g[k]) > 2: return false
	if not g.mutation in ["none", "crystal_wings", "living_flame"] or not integer(g.power, 85) or int(g.power) > 115: return false
	for k in ["body", "affinity", "tier", "mutation", "hat", "robe", "staff", "health", "speed", "damage", "interval", "special"]:
		if not p.has(k): return false
	if p.tier != g.tier or not p.body in ["stoneborn", "fae", "hybrid"] or not p.affinity in ["fire", "ice", "steam"]: return false
	if not p.mutation in ["none", "crystal_wings", "living_flame"] or not p.special is String: return false
	for k in ["hat", "robe", "staff"]:
		if not integer(p[k]) or int(p[k]) > 2: return false
	for k in ["health", "speed", "damage", "interval"]:
		if not (p[k] is int or p[k] is float) or not is_finite(float(p[k])) or float(p[k]) <= 0: return false
	if p.tier == 1 and (p.body == "hybrid" or p.affinity == "steam" or p.mutation != "none"): return false
	if p.mutation == "crystal_wings" and p.body == "fae": return false
	if p.mutation == "living_flame" and p.affinity == "ice": return false
	if c.parents.size() != (0 if g.tier == 1 else 2): return false
	return true

static func valid_profile(p: Variant) -> bool:
	if not p is Dictionary: return false
	for k in ["roster", "archive", "essence", "next_seed", "next_run_id", "settled_runs"]:
		if not p.has(k): return false
	if not p.roster is Array or p.roster.is_empty() or not p.archive is Array or not p.settled_runs is Dictionary: return false
	if not integer(p.essence) or not integer(p.next_seed) or not integer(p.next_run_id, 1): return false
	var records: Dictionary = {}
	var retired: Dictionary = {}
	for c in p.roster + p.archive:
		if not valid_record(c) or records.has(c.id) or int(c.genome.seed) > int(p.next_seed): return false
		records[c.id] = c
	for c in p.archive:
		retired[c.id] = true
	for c in records.values():
		if c.parents.size() == 2:
			if c.parents[0] == c.parents[1]: return false
			for id in c.parents:
				if not id is String or not retired.has(id): return false
				if int(records[id].genome.tier) != int(c.genome.tier) - 1: return false
	var used_parents: Dictionary = {}
	for c in records.values():
		for id in c.parents:
			if used_parents.has(id): return false
			used_parents[id] = true
	if used_parents.size() != retired.size(): return false
	for id in p.settled_runs:
		if not id is String or not id.is_valid_int() or int(id) < 1 or int(id) >= int(p.next_run_id) or p.settled_runs[id] != true: return false
	return true

func _read(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path): return {"status": "missing"}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary: return {"status": "invalid"}
	if not raw.get("payload") is String or not raw.get("checksum") is String: return {"status": "invalid"}
	var payload: String = raw.payload
	if payload.sha256_text() != raw.checksum: return {"status": "invalid"}
	var decoded: Variant = JSON.parse_string(payload)
	if not decoded is Dictionary or not integer(decoded.get("revision"), 1) or not integer(decoded.get("schema"), 1): return {"status": "invalid"}
	if int(decoded.schema) != SCHEMA: return {"status": "unsupported"}
	if not valid_profile(decoded.get("profile")): return {"status": "invalid"}
	return {"status": "ok", "revision": int(decoded.revision), "profile": decoded.profile, "slot": slot}

func load_profile() -> Dictionary:
	error = ""
	recovered = false
	var a := _read(0)
	var b := _read(1)
	# A valid future-version save must not be silently replaced by an older one.
	if a.status == "unsupported" or b.status == "unsupported":
		error = "Save version unsupported. Update the game; existing files were not changed."
		return {"status": "blocked"}
	var chosen: Dictionary = {}
	for entry in [a, b]:
		if entry.status == "ok" and (chosen.is_empty() or int(entry.revision) > int(chosen.revision)):
			chosen = entry
	if chosen.is_empty():
		if a.status == "missing" and b.status == "missing":
			revision = 0
			current_slot = -1
			return {"status": "new"}
		error = "No valid save copy. Existing files preserved; restore a backup before playing."
		return {"status": "blocked"}
	recovered = a.status == "invalid" or b.status == "invalid"
	revision = int(chosen.revision)
	current_slot = int(chosen.slot)
	return {"status": "ok", "profile": chosen.profile}

func commit(profile: Dictionary) -> bool:
	error = ""
	if not valid_profile(profile):
		error = "Invalid profile; save refused."
		return false
	var next_slot := 0 if current_slot == -1 else 1 - current_slot
	var payload := JSON.stringify({"schema": SCHEMA, "revision": revision + 1, "profile": profile})
	var envelope := JSON.stringify({"payload": payload, "checksum": payload.sha256_text()})
	var file := FileAccess.open(slot_path(next_slot), FileAccess.WRITE)
	if file == null:
		error = "Cannot open save file. Check available storage."
		return false
	file.store_string(envelope)
	file.flush()
	file.close()
	# Verify exact bytes and invariants before acknowledging a transaction.
	var verified := _read(next_slot)
	if verified.status != "ok" or int(verified.get("revision", -1)) != revision + 1 or FileAccess.get_file_as_string(slot_path(next_slot)) != envelope:
		error = "Save verification failed. Last valid copy was preserved."
		return false
	current_slot = next_slot
	revision += 1
	return true
