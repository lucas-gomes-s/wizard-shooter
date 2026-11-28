extends RefCounted
## Run-only, finite optional rewards; independent from combat and upgrade RNG.
const World = preload("res://gameplay/dungeon_world.gd")
const Genetics = preload("res://domain/genetics.gd")
const LIMIT := 3
const UNLOCK := 45.0
const IDS: Array[String]=["artifact_magnet","artifact_blood","artifact_ward","artifact_echo","artifact_pierce","artifact_stride"]

static func is_cache(seed: int,site: Dictionary) -> bool:
	if site.is_empty(): return false
	if site.kind not in ["treasure","guarded"]: return false
	var chunk := World.chunk_at(site.pos)
	var salt := World.sample(seed,chunk.x,chunk.y,83)
	return World.sample(salt,chunk.x,chunk.y,84)%100 < (65 if site.kind=="guarded" else 25)

static func offer(seed: int,site: Dictionary,owned: Array[String]) -> Array[String]:
	var chunk := World.chunk_at(site.pos)
	var rng := Genetics.SeededRandom.new(World.sample(World.sample(seed,chunk.x,chunk.y,85),chunk.x,chunk.y,86)+seed)
	var pool: Array[String]=[]
	for id in IDS:
		if id not in owned: pool.append(id)
	var result: Array[String]=[]
	while result.size()<3 and not pool.is_empty():
		var i := rng.next_int(pool.size())
		result.append(pool[i])
		pool.remove_at(i)
	return result
