extends RefCounted
## Shared permanent rewards, independent of run XP and difficulty parameters.
## Versioned policy; all presets and endless use it to avoid fast-mode XP farming.
const VERSION := "training-v2"
const SECONDS_PER_XP := 18.0
const SECONDS_PER_ESSENCE := 60.0
const APPRENTICE_SHARE := 0.25

static func quote(seconds: float,kills: int,exploration_xp: int,exploration_essence: int,victory: bool) -> Dictionary:
	var t := maxf(0.0,seconds)
	var base := floori((t+0.000001)/SECONDS_PER_XP)
	# Bonuses reward active engagement but cannot outgrow elapsed play.
	var bonus := mini(floori(base/4.0),floori(maxi(0,kills)/20.0)+floori(maxi(0,exploration_xp)/8.0))
	var training := base+bonus
	var currency := floori((t+0.000001)/SECONDS_PER_ESSENCE)
	var discovery := mini(floori(currency/2.0),floori(maxi(0,exploration_essence)/2.0))
	var clear_bonus := mini(4,1+floori(currency/2.0)) if victory else 0
	return {"training":training,"apprentice":floori(training*APPRENTICE_SHARE),
		"essence":currency+discovery+clear_bonus,"base_training":base,"bonus_training":bonus,
		"base_essence":currency,"discovery_essence":discovery,"victory_essence":clear_bonus}
