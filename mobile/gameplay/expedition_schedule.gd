extends RefCounted
## Independent, provisional six-minute expedition schedule. No wall-clock timers.
const BOSS_AT := 360.0
const WARNING_AT := 345.0
const PHASES := [
	{"name":"Arrival","start":0.0,"delay":1.18,"cap":22,"pack":1,"weights":[75,25,0,0],"hp":1.0,"damage":1.0},
	{"name":"Escalation","start":60.0,"delay":0.95,"cap":30,"pack":1,"weights":[45,30,25,0],"hp":1.25,"damage":1.05},
	{"name":"Pressure","start":180.0,"delay":0.86,"cap":38,"pack":2,"weights":[35,25,22,18],"hp":1.65,"damage":1.12},
	{"name":"Climax","start":300.0,"delay":0.72,"cap":44,"pack":2,"weights":[25,23,30,22],"hp":2.1,"damage":1.2},
	{"name":"Dragon","start":360.0,"delay":1.1,"cap":24,"pack":1,"weights":[42,28,20,10],"hp":2.1,"damage":1.2}
]
const KINDS := [0,1,2,4]
const BOSS_HP_SCALE := 4.0
const BOSS_DAMAGE_SCALE := 1.2

static func index_at(t: float) -> int:
	for i in range(PHASES.size()-1,-1,-1):
		if t>=float(PHASES[i].start): return i
	return 0

static func recovery(t: float) -> bool:
	return t>=60.0 and t<BOSS_AT and fmod(t,40.0)>=32.0

static func warning(t: float) -> bool:
	return t>=WARNING_AT and t<BOSS_AT

static func kind_at(t: float,roll: int) -> int:
	if t<12.0: return 0
	var weights: Array=PHASES[index_at(t)].weights
	var remaining := clampi(roll,0,99)
	for i in range(weights.size()):
		remaining-=int(weights[i])
		if remaining<0: return KINDS[i]
	return 0

static func delay(t: float,difficulty: int,balance: Dictionary) -> float:
	var p: Dictionary=PHASES[index_at(t)]
	var base := float(p.delay)*float(balance.spawn_interval)*maxf(0.65,1.0-0.10*(difficulty-1))
	if recovery(t): base*=2.5*(1.0+float(balance.recovery))
	if t>=BOSS_AT: base*=float(balance.boss_add_interval)
	return maxf(0.35,base)

static func pack_size(t: float) -> int:
	return 1 if recovery(t) or warning(t) else int(PHASES[index_at(t)].pack)

static func density_cap(t: float,difficulty: int) -> int:
	return int(PHASES[index_at(t)].cap)+4*(difficulty-1)
