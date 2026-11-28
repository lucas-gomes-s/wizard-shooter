extends RefCounted
## Upgrade metadata and eligibility. No school selection or permanent stat changes.
const DEFINITIONS := {
	"evo_fire_fan": {"name":"Ember fan","text":"3 angled bolts, each at 68% prior impact power.","category":"Evolution","cap":1,"affinity":"fire","relic":true,"evolution":true},
	"evo_fire_storm": {"name":"Ember storm","text":"5 angled bolts, each at 90% fan power.","category":"Evolution","cap":1,"affinity":"fire","relic":true,"evolution":true},
	"evo_fire_blast": {"name":"Blast ember","text":"Each hit splashes nearby enemies in 27px.","category":"Evolution","cap":1,"affinity":"fire","relic":true,"evolution":true},
	"evo_fire_nova": {"name":"Nova ember","text":"Splash expands to 43px and 80% spell power.","category":"Evolution","cap":1,"affinity":"fire","relic":true,"evolution":true},
	"evo_ice_spear": {"name":"Glacier spear","text":"+2 pierces; wider lance; stronger chill bonus.","category":"Evolution","cap":1,"affinity":"ice","relic":true,"evolution":true},
	"evo_ice_glacier": {"name":"Absolute zero","text":"Hits pulse chill and damage; larger special.","category":"Evolution","cap":1,"affinity":"ice","relic":true,"evolution":true},
	"evo_ice_volley": {"name":"Crystal volley","text":"3 angled lances at 63% power; one fewer pierce.","category":"Evolution","cap":1,"affinity":"ice","relic":true,"evolution":true},
	"evo_ice_storm": {"name":"Crystal storm","text":"5 angled lances at 90% volley power.","category":"Evolution","cap":1,"affinity":"ice","relic":true,"evolution":true},
	"evo_steam_burst": {"name":"Pressure orb","text":"Impact bursts damage nearby enemies in 35px.","category":"Evolution","cap":1,"affinity":"steam","relic":true,"evolution":true},
	"evo_steam_rupture": {"name":"Rupture orb","text":"Impact bursts expand to 49px, full spell power.","category":"Evolution","cap":1,"affinity":"steam","relic":true,"evolution":true},
	"evo_steam_mantle": {"name":"Mist mantle","text":"Special cloud follows you; 15% smaller radius.","category":"Evolution","cap":1,"affinity":"steam","relic":true,"evolution":true},
	"evo_steam_eye": {"name":"Eye of the storm","text":"Mobile cloud gains 18px radius and 1.2s life.","category":"Evolution","cap":1,"affinity":"steam","relic":true,"evolution":true},
	"relic_power": {"name":"Emberglass seal","text":"+25% spell damage for this run","category":"Relic","cap":2,"relic":true},
	"relic_focus": {"name":"Chronomancer seal","text":"25% shorter special cooldown (min 2.5s)","category":"Relic","cap":2,"relic":true},
	"relic_heart": {"name":"Guardian heart","text":"+25 max HP; heal 40 HP","category":"Relic","cap":2,"relic":true},
	"vitality": {"name":"Vitality","text":"+12 max HP; heal 20 HP","category":"Universal","cap":0},
	"power": {"name":"Spell power","text":"+10% base spell damage","category":"Universal","cap":8},
	"haste": {"name":"Haste","text":"10% shorter basic cast interval","category":"Universal","cap":6},
	"stride": {"name":"Fleet foot","text":"+6 movement speed","category":"Universal","cap":4},
	"kindle": {"name":"Kindle","text":"+25% burn rate; +0.5s burn duration","category":"Fire","cap":4,"affinity":"fire"},
	"wildfire": {"name":"Wildfire","text":"+10px death burst radius; +20% burst damage","category":"Fire","cap":4,"affinity":"fire"},
	"inferno": {"name":"Inferno mastery","text":"+12px special radius; +15% special damage","category":"Fire","cap":4,"affinity":"fire"},
	"pierce": {"name":"Deep frost","text":"+1 enemy pierced per lance","category":"Ice","cap":3,"affinity":"ice"},
	"shatter": {"name":"Shatter","text":"+35% bonus shatter damage","category":"Ice","cap":4,"affinity":"ice"},
	"permafrost": {"name":"Permafrost","text":"+0.3s freeze; +0.5s chill and slow","category":"Ice","cap":4,"affinity":"ice"},
	"mist": {"name":"Dense mist","text":"+8px vapor cloud radius; +0.5s duration","category":"Steam","cap":4,"affinity":"steam"},
	"pressure": {"name":"Pressure","text":"+20% steam cloud damage","category":"Steam","cap":4,"affinity":"steam"},
	"vortex": {"name":"Vortex mastery","text":"+12px vortex radius; +0.6s duration","category":"Steam","cap":4,"affinity":"steam"},
	"wingward": {"name":"Crystal aegis","text":"+0.5s wing ward; +8px special radius","category":"Mutation","cap":3,"mutation":"crystal_wings"},
	"flametrail": {"name":"Scorching path","text":"+0.6s trail; +20% trail damage","category":"Mutation","cap":3,"mutation":"living_flame"},
	"fortify": {"name":"Fortified ward","text":"8% less incoming damage","category":"Talent","cap":3,"talent":"resilient"},
	"rapid": {"name":"Rapid incantation","text":"12% shorter basic cast interval","category":"Talent","cap":3,"talent":"quickcast"},
	"focus": {"name":"Perfect focus","text":"+12% spell damage","category":"Talent","cap":3,"talent":"focused"},
	"flow": {"name":"Channeling","text":"12% shorter special cooldown","category":"Talent","cap":3,"talent":"flow"},
	"stone": {"name":"Stone endurance","text":"+20 max HP; heal 20 HP","category":"Species","cap":3,"body":"stoneborn"},
	"fae": {"name":"Fae agility","text":"+10 movement speed","category":"Species","cap":3,"body":"fae"},
	"hybrid": {"name":"Hybrid vigor","text":"+6 movement speed; +10 max HP and heal","category":"Species","cap":3,"body":"hybrid"}
}

static func eligible(id: String, p: Dictionary, ranks: Dictionary) -> bool:
	if not DEFINITIONS.has(id): return false
	var d: Dictionary = DEFINITIONS[id]
	if int(d.cap) > 0 and int(ranks.get(id, 0)) >= int(d.cap): return false
	for field in ["affinity", "mutation", "body"]:
		if d.has(field) and d[field] != p.get(field): return false
	if d.has("talent") and not d.talent in p.get("passives", []): return false
	return true

static func _pick(pool: Array[String], rng: Variant) -> String:
	return pool[rng.next_int(pool.size())] if not pool.is_empty() else ""

static func offer(p: Dictionary, ranks: Dictionary, rng: Variant) -> Array[String]:
	var universal: Array[String] = []
	var elemental: Array[String] = []
	var genetic: Array[String] = []
	for id in DEFINITIONS:
		if DEFINITIONS[id].get("relic",false): continue
		if not eligible(id, p, ranks): continue
		var d: Dictionary = DEFINITIONS[id]
		if d.category == "Universal": universal.append(id)
		elif d.has("affinity"): elemental.append(id)
		else: genetic.append(id)
	var chosen: Array[String] = []
	# Guaranteed one universal, one affinity and one genetic option when available.
	for pool in [universal, elemental, genetic]:
		var id := _pick(pool, rng)
		if not id.is_empty(): chosen.append(id)
	var remaining: Array[String] = []
	for id in universal + elemental + genetic:
		if not id in chosen: remaining.append(id)
	while chosen.size() < 3 and not remaining.is_empty():
		var id := _pick(remaining, rng)
		chosen.append(id)
		remaining.erase(id)
	# Only vitality is uncapped; late endless runs never get stuck on an empty offer.
	return chosen

static func description(id: String, rank: int) -> String:
	var d: Dictionary = DEFINITIONS[id]
	var progress := "%d/%d" % [rank + 1, d.cap] if int(d.cap) > 0 else str(rank + 1)
	return "%s  •  %s  [%s]\n%s" % [d.category, d.name, progress, d.text]
