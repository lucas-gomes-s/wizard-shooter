extends RefCounted
## Local presentation preferences, separate from the collection save.
const DEFAULT_PATH := "user://visual_settings.cfg"
var path := DEFAULT_PATH
var persist := true
var fps := 60
var reduced_motion := false
var simple_effects := false
var damage_numbers := true
var monitor := false

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

func save_settings() -> Error:
	if not persist: return OK
	var cfg := ConfigFile.new()
	cfg.set_value("visual","fps",fps)
	cfg.set_value("visual","reduced_motion",reduced_motion)
	cfg.set_value("visual","simple_effects",simple_effects)
	cfg.set_value("visual","damage_numbers",damage_numbers)
	cfg.set_value("visual","monitor",monitor)
	return cfg.save(path)

func apply() -> void:
	# Render cap only; never change physics tick rate or simulation delta.
	Engine.max_fps=fps
