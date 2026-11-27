extends RefCounted
## Optional, action-driven lessons on the real expedition. No extra rewards or gameplay modifiers.
const DEFAULT_PATH := "user://onboarding.cfg"
const MOVE := 1
const BASIC := 2
const SPECIAL := 4
const UPGRADE := 8
const WARNING := 16
const COMBAT := MOVE | BASIC | SPECIAL | UPGRADE
const ALL := COMBAT | WARNING
var path := DEFAULT_PATH
var persist := true
var enabled := true
var learned := 0
var walked := 0.0
var warning_until := 0.0

func load_settings(existing_player: bool) -> void:
	if not persist: return
	var cfg := ConfigFile.new()
	if cfg.load(path)!=OK:
		# Existing players are not forced through lessons after an update.
		enabled=not existing_player
		return
	enabled=cfg.get_value("guide","enabled",true)==true
	var value: Variant=cfg.get_value("guide","learned",0)
	learned=int(value)&ALL if value is int else 0

func save_settings() -> Error:
	if not persist: return OK
	var cfg := ConfigFile.new()
	cfg.set_value("guide","enabled",enabled)
	cfg.set_value("guide","learned",learned)
	return cfg.save(path)

func reset_lessons() -> void:
	learned=0
	enabled=true
	begin_run()
	save_settings()

func begin_run() -> void:
	walked=0.0
	warning_until=0.0

func knows(flag: int) -> bool:
	return (learned&flag)==flag

func mark(flag: int) -> void:
	var previous := learned
	learned|=flag&ALL
	if learned!=previous: save_settings()

func observe_step(run: Variant,previous: Vector2,old_basic: int,old_special: int) -> void:
	if not enabled: return
	if not knows(MOVE):
		walked+=previous.distance_to(run.player)
		if walked>=24.0: mark(MOVE)
	if int(run.basic_casts)>old_basic: mark(BASIC)
	if int(run.special_casts)>old_special: mark(SPECIAL)
	if not knows(WARNING):
		for e in run.enemies:
			if str(e.attack) in ["web","bolt","breath","charge_windup"]:
				warning_until=float(run.elapsed)+3.0
				mark(WARNING)
				break

func tip(run: Variant) -> String:
	if not enabled: return ""
	if float(run.elapsed)<warning_until: return "Dodge warning\nareas and lines."
	if not knows(MOVE): return "Drag left pad\nto move.\nWASD on PC"
	if not knows(BASIC): return "Magic fires\nautomatically."
	if not knows(SPECIAL): return "Tap CAST\nwhen ready.\nSpace on PC"
	if not knows(UPGRADE): return "Gain XP.\nChoose an\nupgrade."
	if not knows(WARNING) and float(run.elapsed)<18.0: return "Watch orange\nattack warnings."
	return ""

func lesson_count() -> int:
	var count := 0
	for flag in [MOVE,BASIC,SPECIAL,UPGRADE]:
		if knows(flag): count+=1
	return count

static func fusion_tip(academy: Variant,active: Dictionary,apprentice: Dictionary) -> String:
	if not academy.archive.is_empty(): return ""
	if academy.eligible(active,apprentice): return "First fusion ready! Open the fusion chamber."
	if int(active.phenotype.tier)!=1: return "Choose a Tier I pair from the collection."
	if apprentice.is_empty(): return "Assign a Tier I apprentice in the collection. They share 25% XP."
	if int(apprentice.phenotype.tier)!=1: return "Choose a Tier I apprentice to train for fusion."
	if active.locked or apprentice.locked: return "Unlock both parents when ready to fuse."
	return "Train both to 40 XP for fusion. Active gains full XP; apprentice gains 25%."
