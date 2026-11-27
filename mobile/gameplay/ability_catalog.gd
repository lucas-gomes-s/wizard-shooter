extends RefCounted
## Ability definitions are data; RunModel supplies movement, targets and damage.
## Supported delivery operators: projectile, area, cloud. Effects are composable.
const MAX_SHOTS := 160
const MAX_CLOUDS := 12
const MAX_FLASHES := 32
const BASICS := {
	"fire": {"name":"Ember bolt","delivery":"projectile","target":"nearest","range":350.0,"speed":245.0,"life":1.6,"power":1.0,"pierce":0,"effects":[{"kind":"burn","duration":2.6,"rate":0.30}]},
	"ice": {"name":"Frost lance","delivery":"projectile","target":"nearest","range":320.0,"speed":300.0,"life":1.2,"power":0.88,"pierce":2,"effects":[{"kind":"slow","duration":2.0},{"kind":"chill","duration":2.8}]},
	"steam": {"name":"Vapor orb","delivery":"projectile","target":"nearest","range":300.0,"speed":220.0,"life":1.5,"power":0.55,"pierce":0,"effects":[{"kind":"cloud","duration":2.4,"radius":42.0,"rate":0.26}]}
}
const SPECIALS := {
	"fire":{"name":"Inferno","delivery":"area","target":"self","radius":76.0,"power":2.2,"cooldown":7.0,"effects":[{"kind":"burn","duration":3.0,"rate":0.40}]},
	"ice":{"name":"Glacial fracture","delivery":"area","target":"self","radius":86.0,"power":1.5,"cooldown":7.0,"effects":[{"kind":"shatter","power":1.2},{"kind":"freeze","duration":1.4},{"kind":"slow","duration":3.0}]},
	"steam":{"name":"Steam vortex","delivery":"cloud","target":"self","radius":74.0,"power":0.0,"duration":4.0,"rate":0.65,"cooldown":7.0,"effects":[]}
}
const PASSIVE_NAMES := {"resilient":"Stone Ward","quickcast":"Quick Casting","focused":"Focused Magic","flow":"Arcane Flow"}

static func compile(p: Dictionary) -> Dictionary:
	var affinity: String = p.affinity
	var basic: Dictionary = BASICS[affinity].duplicate(true)
	var special: Dictionary = SPECIALS[affinity].duplicate(true)
	var traits: Array = p.get("passives", [])
	var strength := 0.7 if traits.size() > 1 else 1.0
	var modifiers := {"damage":1.0,"interval":1.0,"incoming":1.0,"cooldown":1.0}
	for talent_id in traits:
		match str(talent_id):
			"resilient": modifiers.incoming *= 1.0 - 0.18 * strength
			"quickcast": modifiers.interval *= 1.0 - 0.12 * strength
			"focused": modifiers.damage *= 1.0 + 0.12 * strength
			"flow": modifiers.cooldown *= 1.0 - 0.20 * strength
	if p.mutation == "crystal_wings":
		special.radius += 16.0
		special.name = "Crystal " + str(special.name)
		special["ward"] = 1.5
	if p.mutation == "living_flame":
		basic.effects.append({"kind":"burn","duration":3.0,"rate":0.32})
		special.name = "Living " + str(special.name)
		special["trail"] = 2.5
	special.cooldown *= modifiers.cooldown
	return {"basic":basic,"special":special,"modifiers":modifiers}

static func passive_names(p: Dictionary) -> String:
	var names := PackedStringArray()
	for talent_id in p.get("passives", []):
		names.append(str(PASSIVE_NAMES.get(talent_id, talent_id)))
	return ", ".join(names) if not names.is_empty() else "None"
