extends RefCounted
## Local presentation preferences, separate from the collection save.
const Balance = preload("res://gameplay/balance_config.gd")
const DEFAULT_PATH := "user://visual_settings.cfg"
var path := DEFAULT_PATH
var persist := true
var fps := 60
var reduced_motion := false
var simple_effects := false
var damage_numbers := true
var monitor := false
var balance_preset := Balance.CANDIDATE

func load_settings() -> void:
	if not persist: return
	var cfg := ConfigFile.new()
	if cfg.load(path)!=OK: return
	var cap: Variant=cfg.get_value("visual","fps",60)
	fps=30 if cap==30 else 60
	reduced_motion=cfg.get_value("visual","reduced_motion",false)==true
	simple_effects=cfg.get_value("visual","simple_effects",false)==true
	damage_numbers=cfg.get_value("visual","damage_numbers",true)==true
	monitor=cfg.get_value("visual","monitor",false)==true
	var saved_preset: Variant=cfg.get_value("playtest","balance_preset",Balance.CANDIDATE)
	balance_preset=Balance.ORIGINAL if saved_preset==Balance.ORIGINAL else Balance.CANDIDATE

func save_settings() -> Error:
	if not persist: return OK
	var cfg := ConfigFile.new()
	cfg.set_value("visual","fps",fps)
	cfg.set_value("visual","reduced_motion",reduced_motion)
	cfg.set_value("visual","simple_effects",simple_effects)
	cfg.set_value("visual","damage_numbers",damage_numbers)
	cfg.set_value("visual","monitor",monitor)
	cfg.set_value("playtest","balance_preset",balance_preset)
	return cfg.save(path)

func apply() -> void:
	# Render cap only; never change physics tick rate or simulation delta.
	Engine.max_fps=fps
