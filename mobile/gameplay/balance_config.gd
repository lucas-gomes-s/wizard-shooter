extends RefCounted
## Versioned experiment parameters. Default values preserve the existing game.
const DEFAULTS := {"enemy_hp":1.0,"enemy_damage":1.0,"spawn_interval":1.0,"recovery":0.0,
	"boss_hp":1.0,"boss_damage":1.0,"boss_add_interval":1.0,"ice_damage":1.0,
	"fire_damage":1.0,"steam_damage":1.0,"xp_growth":1.25,"xp_increment":2.0}
const BOUNDS := {"enemy_hp":[0.75,1.35],"enemy_damage":[0.65,1.35],"spawn_interval":[0.85,1.65],
	"recovery":[0.0,1.5],"boss_hp":[0.65,1.40],"boss_damage":[0.75,1.35],
	"boss_add_interval":[1.0,3.0],"ice_damage":[0.85,1.40],"fire_damage":[0.85,1.25],
	"steam_damage":[0.85,1.25],"xp_growth":[1.15,1.35],"xp_increment":[1.0,4.0]}

# Trial 20 from the completed 2026-11-28 study, exact unrounded parameters.
# Candidate for 90-second finite expeditions only. DEFAULTS remain the reference.
const TRIAL_20 := {"enemy_hp":1.1092348917138815,"enemy_damage":0.9288859421243479,
	"spawn_interval":1.596806527818022,"recovery":0.2370624515571905,
	"boss_hp":0.653164541416256,"boss_damage":1.1254885227622706,
	"boss_add_interval":2.3378082303080916,"ice_damage":1.2339416502594414,
	"fire_damage":1.242394864172693,"steam_damage":1.1030458163603378,
	"xp_growth":1.152736567557464,"xp_increment":2.9943887713605015}
const ORIGINAL := "original"
const CANDIDATE := "trial20-short"
const FROST := "trial20-frost"
const LONG := "expedition-six"
const MANA := "expedition-mana"
const TRIALS := "expedition-trials"
const EVOLUTION := "expedition-evolution"
const LINEAGE := "expedition-lineage"
const PRESETS := [ORIGINAL,CANDIDATE,FROST,LONG,MANA,TRIALS,EVOLUTION,LINEAGE]

static func preset(id: String) -> Dictionary:
	match id:
		ORIGINAL: return validated({})
		CANDIDATE,FROST,LONG,MANA,TRIALS,EVOLUTION,LINEAGE: return validated(TRIAL_20)
	return {}

static func label(id: String) -> String:
	if id==LINEAGE: return "Six-minute + Lineage"
	if id==EVOLUTION: return "Six-minute + Evolution"
	if id==TRIALS: return "Six-minute + Trials"
	if id==MANA: return "Six-minute + Mana"
	if id==LONG: return "Six-minute expedition"
	if id==FROST: return "Trial 20 + Frost"
	return "Trial 20" if id==CANDIDATE else "Original"

static func preset_id(config: Dictionary) -> String:
	if config==TRIAL_20: return CANDIDATE
	if config==DEFAULTS: return ORIGINAL
	return "custom"

static func validated(overrides: Dictionary) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key in overrides:
		if not BOUNDS.has(key): return {}
		var value: Variant = overrides[key]
		if not (value is int or value is float) or not is_finite(float(value)): return {}
		if float(value)<float(BOUNDS[key][0]) or float(value)>float(BOUNDS[key][1]): return {}
		result[key]=float(value)
	return result

static func spawn_delay(t: float, difficulty: int, boss: bool, c: Dictionary) -> float:
	# Optional 20-second cycles: final 5 seconds provide a lighter spawn period.
	var recovery := 1.0 + float(c.recovery) if fmod(t,20.0)>=15.0 else 1.0
	return maxf(0.24,1.15-t*0.007-(difficulty-1)*0.13)*float(c.spawn_interval)*recovery*(float(c.boss_add_interval) if boss else 1.0)
