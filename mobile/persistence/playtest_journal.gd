extends RefCounted
## Voluntary local playtest journal. No account, device identifier, wall-clock time or network.
const PATH := "user://playtest_journal.json"
const LIMIT := 512
const MAX_BYTES := 2*1024*1024
const TYPES := ["session","run_start","lesson","upgrade","run_end","reward_saved","summon","fusion","profile_restored"]
var path := PATH
var persist := true
var enabled := false
var events: Array[Dictionary] = []
var next_sequence := 1
var dropped := 0
var current_run := 0
var error := ""
var unreadable := false

func load_journal() -> void:
	if not persist or not FileAccess.file_exists(path): return
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>MAX_BYTES:
		_block_read()
		return
	var data: Variant=JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("schema")!=1 or not data.get("enabled") is bool or not data.get("events") is Array:
		_block_read()
		return
	if data.events.size()>LIMIT or not _integer(data.get("next_sequence"),1) or not _integer(data.get("dropped"),0):
		_block_read()
		return
	var previous := 0
	for e in data.events:
		if not e is Dictionary or not _integer(e.get("seq"),1) or int(e.seq)<=previous or not e.get("type") in TYPES or not e.get("data") is Dictionary:
			_block_read()
			return
		previous=int(e.seq)
	if int(data.next_sequence)<=previous:
		_block_read()
		return
	events.assign(data.events)
	next_sequence=int(data.next_sequence)
	dropped=int(data.dropped)
	enabled=data.enabled

static func _integer(v: Variant,minimum: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)==floorf(float(v)) and float(v)>=minimum and float(v)<9007199254740991.0

func _block_read() -> void:
	unreadable=true
	enabled=false
	error="Journal unreadable. Clear it explicitly to begin again."

func _save() -> bool:
	if not persist: return true
	if unreadable: return false
	var temp := path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file==null:
		error="Cannot write playtest journal."
		return false
	var payload := JSON.stringify({"schema":1,"enabled":enabled,"events":events,"next_sequence":next_sequence,"dropped":dropped},"",true,true)
	if payload.to_utf8_buffer().size()>MAX_BYTES:
		error="Journal size limit reached."
		return false
	file.store_string(payload)
	file.flush()
	var status := file.get_error()
	file.close()
	if status!=OK or FileAccess.get_file_as_string(temp)!=payload or DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(path))!=OK:
		error="Journal write failed; previous copy retained."
		return false
	error=""
	return true

func set_enabled(value: bool) -> bool:
	if unreadable: return false
	var previous := enabled
	enabled=value
	if not _save():
		enabled=previous
		return false
	if not enabled: current_run=0
	return true

func clear() -> bool:
	# Clear is explicitly authorized in the UI; also repairs unreadable journals.
	var old_events := events.duplicate(true)
	var old_next := next_sequence
	var old_dropped := dropped
	var old_unreadable := unreadable
	var old_run := current_run
	events.clear()
	next_sequence=1
	dropped=0
	current_run=0
	unreadable=false
	if _save(): return true
	events.assign(old_events)
	next_sequence=old_next
	dropped=old_dropped
	current_run=old_run
	unreadable=old_unreadable
	return false

func record(kind: String,data: Dictionary = {}) -> int:
	if not enabled or unreadable or not kind in TYPES: return 0
	var id := next_sequence
	next_sequence+=1
	events.append({"seq":id,"type":kind,"data":data.duplicate(true)})
	if events.size()>LIMIT:
		events.pop_front()
		dropped+=1
	_save()
	return id

func session() -> void:
	record("session",{"build":str(ProjectSettings.get_setting("application/config/version","unknown")),"platform":OS.get_name()})

static func phenotype(p: Dictionary) -> Dictionary:
	# Only expressed categories, never character IDs, seeds from genomes, or raw alleles.
	return {"body":p.body,"affinity":p.affinity,"tier":p.tier,"mutation":p.mutation,"talents":p.get("passives",[]).duplicate(true)}

func start_run(run: Variant,has_apprentice: bool,lessons: int,visual: Dictionary) -> void:
	current_run=record("run_start",{"mode":"endless" if run.endless else "finite","difficulty":run.difficulty,
		"wizard":phenotype(run.phenotype),"apprentice":has_apprentice,"lessons":lessons,"visual":visual})

func run_event(kind: String,data: Dictionary) -> void:
	if current_run<=0: return
	var detail := data.duplicate(true)
	detail["run"]=current_run
	record(kind,detail)

func end_run(run: Variant,performance: Dictionary) -> void:
	run_event("run_end",{"outcome":run.outcome,"seconds":run.elapsed,"kills":run.kills,"level":run.run_level,
		"last_hit":str(run.last_hit) if run.outcome=="Defeated" else "",
		"damage_dealt":run.total_damage_dealt,"damage_taken":run.total_damage_taken,
		"basic_casts":run.basic_casts,"special_casts":run.special_casts,"boss_reached":run.boss_spawned,
		"treasures":run.treasure_count,"shrines":run.shrine_count,"encounters":run.encounters_cleared,
		"upgrades":run.upgrade_ranks.duplicate(true),"performance":performance})

func reward_saved(reward: Dictionary) -> void:
	run_event("reward_saved",{"active_xp":reward.active_gain,"apprentice_xp":reward.apprentice_gain,
		"essence":reward.essence_gain,"new_wizard":not reward.newcomer.is_empty(),"fusion_ready":reward.fusion_ready})
	current_run=0

func report() -> Dictionary:
	var counts: Dictionary={}
	var seconds := 0.0
	for e in events:
		counts[e.type]=int(counts.get(e.type,0))+1
		if e.type=="run_end": seconds+=float(e.data.get("seconds",0))
	return {"schema":1,"format":"wizard-shooter-playtest","retained_events":events.size(),"discarded_events":dropped,
		"counts":counts,"completed_run_seconds_retained":seconds,"events":events.duplicate(true),
		"limitations":"Local opt-in sample. Missing ends may be interruptions, opt-outs or failed writes, not confirmed crashes. No dates or unique player IDs."}
