extends RefCounted
## POC ruleset v1. Pure founder generation / expression / fusion.
## No Godot scene or persistence dependencies. Explicit seeds, stable integer RNG.
const SPECIES := ["stoneborn", "fae"]
const CORES := ["fire", "ice"]
const PASSIVES := ["resilient", "quickcast", "focused", "flow"]
const RESONANCES := ["concentrated","dispersed"]
const MODULUS := 2147483647
const VERSION := 1

class SeededRandom:
	var state: int
	func _init(seed: int) -> void:
		state = posmod(seed, 2147483646) + 1
	func next_int(bound: int) -> int:
		assert(bound > 0)
		state = (state * 48271) % 2147483647
		return state % bound
	func chance(percent: int) -> bool:
		return next_int(100) < percent

static func founder(seed: int) -> Dictionary:
	var rng := SeededRandom.new(seed)
	var species: String = SPECIES[rng.next_int(2)]
	var core: String = CORES[rng.next_int(2)]
	var other: String = CORES[rng.next_int(2)]
	return {"version": VERSION, "tier": 1, "seed": seed,
		"species": [species, species], "core": [core, other],
		"ancestry": {"stoneborn": 10000 if species == "stoneborn" else 0, "fae": 10000 if species == "fae" else 0},
		"hat": rng.next_int(3), "robe": rng.next_int(3), "staff": rng.next_int(3),
		"mutation": "none", "power": 90 + rng.next_int(21), "talents": legacy_talents(seed), "resonance": legacy_resonance(seed)}

static func fuse(a: Dictionary, b: Dictionary, seed: int) -> Dictionary:
	if int(a.tier) != 1 or int(b.tier) != 1:
		return {}
	# Canonical order makes the same parental pair + seed symmetric.
	var first: Dictionary = a
	var second: Dictionary = b
	if int(a.seed) > int(b.seed):
		first = b
		second = a
	var rng := SeededRandom.new(seed)
	var ancestry_stone := int((int(first.ancestry.stoneborn) + int(second.ancestry.stoneborn)) / 2.0)
	var body_alleles: Array = [first.species[rng.next_int(2)], second.species[rng.next_int(2)]]
	var core_alleles: Array = [first.core[rng.next_int(2)], second.core[rng.next_int(2)]]
	if rng.chance(5):
		var locus: int = rng.next_int(2)
		if locus == 0:
			body_alleles[rng.next_int(2)] = SPECIES[rng.next_int(2)]
		else:
			core_alleles[rng.next_int(2)] = CORES[rng.next_int(2)]
	var talent_rng := SeededRandom.new(seed + 456789)
	var t1 := talents_for(first)
	var t2 := talents_for(second)
	var inherited: Array = [t1[talent_rng.next_int(2)], t2[talent_rng.next_int(2)]]
	if talent_rng.chance(5): inherited[talent_rng.next_int(2)] = PASSIVES[talent_rng.next_int(4)]
	var resonance_rng := SeededRandom.new(seed + 821347)
	var ra := resonance_for(first)
	var rb := resonance_for(second)
	var resonance: Array = [ra[resonance_rng.next_int(2)], rb[resonance_rng.next_int(2)]]
	if resonance_rng.chance(5):
		var locus := resonance_rng.next_int(2)
		resonance[locus]=RESONANCES[1-RESONANCES.find(resonance[locus])]
	var mutation := "none"
	if rng.chance(30):
		mutation = "crystal_wings" if rng.chance(50) else "living_flame"
	return {"version": VERSION, "tier": 2, "seed": seed,
		"species": body_alleles, "core": core_alleles,
		"ancestry": {"stoneborn": ancestry_stone, "fae": 10000 - ancestry_stone},
		"hat": first.hat if rng.chance(50) else second.hat,
		"robe": first.robe if rng.chance(50) else second.robe,
		"staff": first.staff if rng.chance(50) else second.staff,
		"mutation": mutation, "talents": inherited, "resonance": resonance, "power": clampi(roundi((float(first.power) + float(second.power)) / 2.0) + rng.next_int(11) - 5, 85, 115)}

static func express(g: Dictionary) -> Dictionary:
	var tier := int(g.tier)
	var body: String = g.species[0]
	var affinity: String = g.core[0]
	if tier >= 2:
		if g.species[0] != g.species[1]:
			body = "hybrid"
		if g.core[0] != g.core[1]:
			affinity = "steam"
	var mutation: String = g.mutation if tier >= 2 else "none"
	if mutation == "crystal_wings" and body == "fae":
		mutation = "none"
	if mutation == "living_flame" and affinity == "ice":
		mutation = "none"
	var health := 115.0 if body == "stoneborn" else (78.0 if body == "fae" else 96.0)
	var speed := 86.0 if body == "stoneborn" else (122.0 if body == "fae" else 104.0)
	var damage := 15.0 * float(g.power) / 100.0
	var interval := 0.78 if affinity == "fire" else (0.60 if affinity == "ice" else 0.70)
	if affinity == "ice":
		damage *= 0.82
	if mutation == "crystal_wings":
		speed += 10.0
		health -= 10.0
	if mutation == "living_flame":
		damage *= 1.12
		health -= 8.0
	return {"body": body, "affinity": affinity, "tier": tier, "mutation": mutation,
		"hat": int(g.hat), "robe": int(g.robe), "staff": int(g.staff),
		"health": health, "speed": speed, "damage": damage, "interval": interval, "passives": expressed_talents(g), "resonance": expressed_resonance(g),
		"special": "Crystal burst" if mutation == "crystal_wings" else ("Flame burst" if affinity == "fire" else ("Frost pulse" if affinity == "ice" else "Steam shock"))}

static func legacy_talents(seed: int) -> Array:
	# Separate substream preserves the existing species, appearance and power RNG.
	var rng := SeededRandom.new(seed + 456789)
	return [PASSIVES[rng.next_int(4)], PASSIVES[rng.next_int(4)]]

static func talents_for(g: Dictionary) -> Array:
	return g.get("talents", legacy_talents(int(g.seed)))

static func expressed_talents(g: Dictionary) -> Array:
	var alleles := talents_for(g)
	var expressed: Array = [alleles[0]]
	if int(g.tier) >= 2 and alleles[1] != alleles[0]: expressed.append(alleles[1])
	return expressed

static func legacy_resonance(seed: int) -> Array:
	# Independent substream: existing species, talents, cosmetics and power remain stable.
	var rng := SeededRandom.new(seed+821347)
	return [RESONANCES[rng.next_int(2)],RESONANCES[rng.next_int(2)]]

static func resonance_for(g: Dictionary) -> Array:
	return g.get("resonance",legacy_resonance(int(g.seed))).duplicate()

static func expressed_resonance(g: Dictionary) -> Array:
	var alleles := resonance_for(g)
	var result: Array=[alleles[0]]
	if int(g.tier)>=2 and alleles[1]!=alleles[0]: result.append(alleles[1])
	return result
