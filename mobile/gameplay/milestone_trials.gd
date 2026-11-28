extends RefCounted
## Mandatory, run-local milestone encounters. Timers are simulation seconds.
const RADIUS := 150.0
const WARNING_SECONDS := 10.0
const DEFINITIONS := [
	{"at":120.0,"name":"Guardian trial","kinds":[0,0,1,1,2,2],"elite_indices":[4,5],"elite_hp":1.6},
	{"at":240.0,"name":"Elite trial","kinds":[0,1,1,2,2,4,4,0,2],"elite_indices":[5,6,8],"elite_hp":1.75}
]
const RELICS: Array[String] = ["relic_power","relic_focus","relic_heart"]

static func warning(clock: float,cleared: int) -> bool:
	if cleared>=DEFINITIONS.size(): return false
	var at := float(DEFINITIONS[cleared].at)
	return clock>=at-WARNING_SECONDS and clock<at

static func name_at(index: int) -> String:
	return str(DEFINITIONS[index].name) if index>=0 and index<DEFINITIONS.size() else ""

static func clamp_point(center: Vector2,point: Vector2) -> Vector2:
	return center+(point-center).limit_length(RADIUS)
