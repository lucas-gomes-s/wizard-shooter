extends SceneTree
const Academy = preload("res://domain/academy.gd")
const Store = preload("res://persistence/profile_store.gd")
const Backup = preload("res://persistence/profile_backup.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var prefix := "user://persistence_test_%d" % Time.get_ticks_usec()
	var store := Store.new(prefix)
	var a := Academy.new(42, store)
	check(not a.blocked and store.revision == 1, "Initial profile saved: " + a.error)
	if a.blocked:
		quit(1)
		return
	var id := a.allocate_run()
	check(id == 1, "Allocated durable run ID")
	check(a.reward(id, a.roster[0], a.roster[1], 160, false), "Reward saved")
	var reopened := Academy.new(999, Store.new(prefix))
	if reopened.blocked or reopened.roster.size() < 2:
		check(false, "Reload failed: " + reopened.error)
		quit(1)
		return
	check(reopened.roster[0].xp == 160 and reopened.roster[1].xp == 40, "XP survived reload")
	check(not reopened.reward(id, reopened.roster[0], reopened.roster[1], 160, false), "Duplicate reward rejected after reload")
	var next_id := reopened.allocate_run()
	check(next_id == 2, "Run IDs survive restart")
	check(reopened.toggle_lock(reopened.roster[0].id), "Lock saved")
	check(not reopened.eligible(reopened.roster[0], reopened.roster[1]), "Locked wizard excluded")
	check(reopened.toggle_lock(reopened.roster[0].id), "Unlock saved")
	var first_id: String = reopened.roster[0].id
	var second_id: String = reopened.roster[1].id
	# Inject a deterministic write failure: turn inactive slot path into a directory.
	var inactive: String = reopened.store.slot_path(1 - reopened.store.current_slot)
	var abs_path := ProjectSettings.globalize_path(inactive)
	if FileAccess.file_exists(inactive): DirAccess.remove_absolute(abs_path)
	check(DirAccess.make_dir_absolute(abs_path) == OK, "Failure fixture created")
	var before_seed: int = reopened.next_seed
	var rejected: Dictionary = reopened.fuse(reopened.roster[0], reopened.roster[1])
	check(rejected.is_empty() and reopened.roster.size() == 2 and reopened.archive.is_empty() and reopened.next_seed == before_seed, "Failed write rolls back entire fusion")
	DirAccess.remove_absolute(abs_path)
	var child: Dictionary = reopened.fuse(reopened.roster[0], reopened.roster[1])
	check(not child.is_empty(), "Fusion saved")
	var final := Academy.new(999, Store.new(prefix))
	check(final.roster.size() == 1 and final.archive.size() == 2, "Fusion and retirement survive restart: " + final.error)
	if final.roster.is_empty():
		quit(1)
		return
	check(final.roster[0].id == child.id and final.roster[0].parents == [first_id, second_id], "Lineage survives restart")
	check(final.find_active(first_id).is_empty(), "Retired wizard absent from active roster")
	check(final.summon(), "Summon saved")
	var after_summon := Academy.new(999, Store.new(prefix))
	check(after_summon.roster.size() == 2 and after_summon.essence == final.essence, "Summon and essence survive restart")
	# Truncated inactive slot: latest valid revision remains intact.
	var broken: String = after_summon.store.slot_path(1 - after_summon.store.current_slot)
	var f := FileAccess.open(broken, FileAccess.WRITE)
	f.store_string("{incomplete")
	f.close()
	var recovered := Academy.new(999, Store.new(prefix))
	check(not recovered.blocked and recovered.roster.size() == 2 and recovered.store.recovered, "Corrupt inactive slot recovered")
	# Both copies invalid: refuse to reset or overwrite.
	var other: String = recovered.store.slot_path(recovered.store.current_slot)
	f = FileAccess.open(other, FileAccess.WRITE)
	f.store_string("{also incomplete")
	f.close()
	var blocked := Academy.new(999, Store.new(prefix))
	check(blocked.blocked and not blocked.summon(), "Both corrupted copies block writes")
	check(FileAccess.get_file_as_string(other) == "{also incomplete", "Corrupt originals preserved")
	for slot in range(2):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.slot_path(slot)))
	# Unknown version with a valid checksum must not be downgraded.
	var future_prefix := prefix + "_future"
	var future_store := Store.new(future_prefix)
	var payload := JSON.stringify({"schema": 99, "revision": 2, "profile": {}})
	f = FileAccess.open(future_store.slot_path(0), FileAccess.WRITE)
	f.store_string(JSON.stringify({"payload": payload, "checksum": payload.sha256_text()}))
	f.close()
	var future := Academy.new(42, Store.new(future_prefix))
	check(future.blocked, "Future schema blocks overwrite")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(future_store.slot_path(0)))
	_test_backup(prefix+"_backup")
	print("Wizard Shooter persistence: %d failures" % failures)
	quit(0 if failures == 0 else 1)

func _test_backup(prefix: String) -> void:
	var a := Academy.new(42,Store.new(prefix))
	var first: String=a.roster[0].id
	var second: String=a.roster[1].id
	var legacy := a.snapshot()
	legacy.erase("active_id")
	legacy.erase("apprentice_id")
	check(Store.valid_profile(legacy),"Legacy profile accepted")
	check(a.assign(second,""),"Assign active and explicit empty apprentice")
	var b := Academy.new(999,Store.new(prefix))
	check(b.active_id==second and b.apprentice_id=="","Assignments survive reload")
	check(not b.assign(first,first),"Self apprentice rejected")
	var bad := b.snapshot()
	bad.active_id="missing"
	check(not Store.valid_profile(bad),"Missing active rejected")
	var raw := Backup.encode(b.snapshot())
	var decoded := Backup.decode(raw)
	check(decoded.has("profile"),"Backup round trip")
	check(Backup.decode(raw+"garbage").has("error"),"Malformed backup rejected")
	var envelope: Dictionary=JSON.parse_string(raw)
	envelope.checksum="bad"
	check(Backup.decode(JSON.stringify(envelope)).has("error"),"Checksum rejected")
	var inactive: String=b.store.slot_path(1-b.store.current_slot)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(inactive))
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(inactive))
	check(not b.assign(first,second) and b.active_id==second and b.apprentice_id=="","Failed assignment rolls back")
	check(not b.restore_backup(legacy) and b.active_id==second,"Failed restore leaves memory intact")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(inactive))
	check(b.restore_backup(legacy),"Legacy restore accepted")
	check(b.active_id==first and b.apprentice_id==second,"Legacy defaults restored")
	check(b.restore_backup(decoded.profile),"Backup replaces current collection")
	var c := Academy.new(999,Store.new(prefix))
	check(c.active_id==second and c.apprentice_id=="","Restored profile survives restart")
	for slot in range(2):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(c.store.slot_path(slot)))
