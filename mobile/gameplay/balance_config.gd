extends RefCounted
## Versioned experiment parameters. Default values preserve the existing game.
const DEFAULTS := {"enemy_hp":1.0,"enemy_damage":1.0,"spawn_interval":1.0,"recovery":0.0,
	"boss_hp":1.0,"boss_damage":1.0,"boss_add_interval":1.0,"ice_damage":1.0,
	"fire_damage":1.0,"steam_damage":1.0,"xp_growth":1.25,"xp_increment":2.0}
const BOUNDS := {"enemy_hp":[0.75,1.35],"enemy_damage":[0.65,1.35],"spawn_interval":[0.85,1.65],
	"recovery":[0.0,1.5],"boss_hp":[0.65,1.40],"boss_damage":[0.75,1.35],
	"boss_add_interval":[1.0,3.0],"ice_damage":[0.85,1.40],"fire_damage":[0.85,1.25],
	"steam_damage":[0.85,1.25],"xp_growth":[1.15,1.35],"xp_increment":[1.0,4.0]}

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
