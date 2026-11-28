extends RefCounted
## Run-local spell transformations. Two branches per expressed affinity.
const PATHS := {"fire":["evo_fire_fan","evo_fire_blast"],"ice":["evo_ice_spear","evo_ice_volley"],"steam":["evo_steam_burst","evo_steam_mantle"]}
const MASTERY := {"evo_fire_fan":"evo_fire_storm","evo_fire_blast":"evo_fire_nova","evo_ice_spear":"evo_ice_glacier","evo_ice_volley":"evo_ice_storm","evo_steam_burst":"evo_steam_rupture","evo_steam_mantle":"evo_steam_eye"}

const RESONANT_BRANCHES := {"concentrated":["evo_fire_blast","evo_ice_spear","evo_steam_burst"],"dispersed":["evo_fire_fan","evo_ice_volley","evo_steam_mantle"]}

static func resonance_bonus(p: Dictionary,branch: String) -> float:
	var expressed: Array=p.get("resonance",[])
	for kind in expressed:
		if branch in RESONANT_BRANCHES.get(kind,[]): return 0.08 if expressed.size()==2 else 0.15
	return 0.0

static func resonance_summary(p: Dictionary) -> String:
	var names := PackedStringArray()
	for branch in PATHS.get(p.affinity,[]):
		var bonus := resonance_bonus(p,branch)
		if bonus>0:
			var label := "Concentrated" if branch in RESONANT_BRANCHES.concentrated else "Dispersed"
			names.append("%s +%d%%" % [label,roundi(bonus*100)])
	return " / ".join(names) if not names.is_empty() else "None"

static func offer(affinity: String,branch: String,cleared: int) -> Array[String]:
	var choices: Array[String]=[]
	if cleared==1 and branch.is_empty(): choices.assign(PATHS.get(affinity,[]))
	elif cleared==2 and MASTERY.has(branch):
		choices.append(MASTERY[branch])
		choices.append("relic_heart")
	return choices

static func apply(run: Variant,id: String) -> void:
	var basic: Dictionary=run.kit.basic
	var special: Dictionary=run.kit.special
	match id:
		"evo_fire_fan":
			basic.name="Ember fan"
			basic["count"]=3
			basic["spread"]=0.24
			basic.power*=0.68
		"evo_fire_storm":
			basic.name="Ember storm"
			basic.count=5
			basic.spread=0.20
			basic.power*=0.9
		"evo_fire_blast":
			basic.name="Blast ember"
			basic["impact_radius"]=27.0
			basic["impact_power"]=0.55
		"evo_fire_nova":
			basic.name="Nova ember"
			basic.impact_radius=43.0
			basic.impact_power=0.80
		"evo_ice_spear":
			basic.name="Glacier spear"
			basic.pierce+=2
			basic.hit_padding+=3.0
			basic.chilled_bonus+=0.20
		"evo_ice_glacier":
			basic.name="Absolute zero"
			basic["impact_radius"]=30.0
			basic["impact_power"]=0.50
			basic["impact_chill"]=true
			special.name="Absolute zero field"
			special.radius+=12.0
		"evo_ice_volley":
			basic.name="Crystal volley"
			basic["count"]=3
			basic["spread"]=0.22
			basic.power*=0.63
			basic.pierce=maxi(1,int(basic.pierce)-1)
		"evo_ice_storm":
			basic.name="Crystal storm"
			basic.count=5
			basic.spread=0.18
			basic.power*=0.9
		"evo_steam_burst":
			basic.name="Pressure orb"
			basic["impact_radius"]=35.0
			basic["impact_power"]=0.7
		"evo_steam_rupture":
			basic.name="Rupture orb"
			basic.impact_radius=49.0
			basic.impact_power=1.0
		"evo_steam_mantle":
			special.name="Mist mantle"
			special["follow"]=true
			special.radius*=0.85
		"evo_steam_eye":
			special.name="Eye of the storm"
			special.radius+=18.0
			special.duration+=1.2
