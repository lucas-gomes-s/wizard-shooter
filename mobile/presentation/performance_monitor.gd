extends RefCounted
## Bounded rolling timings from the live client, not the headless balance simulator.
const LIMIT := 3600
const REPORT := "user://performance_report.json"
var frame_ms := PackedFloat32Array()
var step_ms := PackedFloat32Array()
var frame_cursor := 0
var step_cursor := 0
var peak_enemies := 0
var peak_shots := 0
var peak_chunks := 0
var peak_poses := 0
var total_frames := 0
var total_steps := 0

func reset() -> void:
	frame_ms.clear()
	step_ms.clear()
	frame_cursor=0
	step_cursor=0
	peak_enemies=0
	peak_shots=0
	peak_chunks=0
	peak_poses=0
	total_frames=0
	total_steps=0

func record_frame(dt: float) -> void:
	if dt<=0: return
	if frame_ms.size()<LIMIT: frame_ms.append(dt*1000.0)
	else: frame_ms[frame_cursor]=dt*1000.0
	frame_cursor=(frame_cursor+1)%LIMIT
	total_frames+=1

func record_step(us: int,run: Variant,chunks: int,poses: int) -> void:
	var ms := float(us)/1000.0
	if step_ms.size()<LIMIT: step_ms.append(ms)
	else: step_ms[step_cursor]=ms
	step_cursor=(step_cursor+1)%LIMIT
	total_steps+=1
	peak_enemies=maxi(peak_enemies,run.enemies.size())
	peak_shots=maxi(peak_shots,run.shots.size())
	peak_chunks=maxi(peak_chunks,chunks)
	peak_poses=maxi(peak_poses,poses)

static func stats(samples: PackedFloat32Array) -> Dictionary:
	if samples.is_empty(): return {"count":0,"mean":0.0,"p95":0.0,"max":0.0}
	var sorted := samples.duplicate()
	sorted.sort()
	var sum := 0.0
	for v in sorted: sum+=v
	return {"count":sorted.size(),"mean":sum/sorted.size(),"p95":sorted[ceili(sorted.size()*0.95)-1],"max":sorted[sorted.size()-1]}

func report() -> Dictionary:
	return {"schema":1,"window_limit":LIMIT,"engine":Engine.get_version_info().string,"platform":OS.get_name(),
		"total_frames":total_frames,"total_steps":total_steps,"frame_ms":stats(frame_ms),"simulation_step_ms":stats(step_ms),
		"peak_enemies":peak_enemies,"peak_shots":peak_shots,"peak_chunks":peak_chunks,"peak_pose_textures":peak_poses}

func export_report(settings: Dictionary,path: String = REPORT) -> Error:
	var data := report()
	data["settings"]=settings
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"  "))
	file.flush()
	return file.get_error()

func overlay(run: Variant,chunks: int,poses: int) -> String:
	var frames := stats(frame_ms)
	var steps := stats(step_ms)
	return "%d FPS | frame p95 %.1fms | sim p95 %.2fms\nEnemies %d | shots %d | chunks %d | poses %d" % [Engine.get_frames_per_second(),frames.p95,steps.p95,run.enemies.size(),run.shots.size(),chunks,poses]
