extends Node
## Original synthesized PCM sound effects and ambient loops. No gameplay RNG.
const RATE := 16000
const VOICES := 8
const CONFIG := "user://audio_settings.cfg"
# duration, frequency start/end, harmonic mix, noise mix
const SOUNDS := {
	"click":[0.075,420.0,250.0,0.18,0.08],
	"fire":[0.16,170.0,74.0,0.24,0.48],
	"ice":[0.18,820.0,430.0,0.26,0.08],
	"steam":[0.20,240.0,130.0,0.08,0.66],
	"special_fire":[0.42,150.0,46.0,0.35,0.55],
	"special_ice":[0.48,740.0,300.0,0.35,0.12],
	"special_steam":[0.48,160.0,70.0,0.22,0.62],
	"impact":[0.075,150.0,65.0,0.16,0.35],
	"hurt":[0.21,140.0,58.0,0.44,0.17],
	"defeat":[0.13,220.0,95.0,0.22,0.18],
	"level":[0.58,440.0,880.0,0.20,0.0],
	"reward":[0.40,523.25,783.99,0.22,0.0],
	"boss":[0.74,95.0,53.0,0.30,0.17],
	"victory":[0.85,392.0,784.0,0.24,0.0],
	"fallen":[0.70,220.0,82.0,0.18,0.02],
	"ritual":[0.88,110.0,440.0,0.32,0.16],
	"reveal":[0.95,330.0,990.0,0.22,0.0]
}
var effects_enabled := true
var music_enabled := true
var persist_settings := true
var bank: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var priorities: Array[int] = []
var ambient: AudioStreamPlayer
var current_track := ""
var last_impact := -1.0
var last_defeat := -1.0

func _ready() -> void:
	if persist_settings:
		var config := ConfigFile.new()
		if config.load(CONFIG)==OK:
			effects_enabled=bool(config.get_value("audio","effects",true))
			music_enabled=bool(config.get_value("audio","music",true))
	for id in SOUNDS:
		bank[id]=effect_stream(id)
	for i in range(VOICES):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
		priorities.append(0)
	ambient=AudioStreamPlayer.new()
	ambient.volume_db=-24.0
	add_child(ambient)

static func effect_stream(id: String) -> AudioStreamWAV:
	var spec: Array = SOUNDS[id]
	var duration: float = spec[0]
	var count := int(RATE*duration)
	var data := PackedByteArray()
	data.resize(count*2)
	var phase := 0.0
	var seed := 79
	var filtered := 0.0
	for i in range(count):
		var t := float(i)/RATE
		var u := t/duration
		var frequency := lerpf(float(spec[1]),float(spec[2]),u)
		phase+=TAU*frequency/RATE
		seed=(seed*48271)%2147483647
		filtered=lerpf(filtered,float(seed)/2147483647.0*2.0-1.0,0.40)
		var tone := sin(phase)*(1.0-float(spec[3]))+sin(phase*2.0)*float(spec[3])
		var envelope := minf(1.0,t/0.012)*pow(1.0-u,1.6)*minf(1.0,(duration-t)/0.018)
		var sample := lerpf(tone,filtered,float(spec[4]))*envelope*0.38
		data.encode_s16(i*2,roundi(clampf(sample,-1,1)*32767))
	var wav := AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=RATE
	wav.data=data
	return wav

static func ambient_stream(track: String) -> AudioStreamWAV:
	# Eight-second seamless dark modal drones with soft periodic swells, no copyrighted music.
	var count := RATE*8
	var data := PackedByteArray()
	data.resize(count*2)
	var notes := [55.0,82.5,110.0] if track=="dungeon" else [65.375,98.0,130.75]
	for i in range(count):
		var t := float(i)/RATE
		var phase := TAU*t/8.0
		var swell := 0.55+0.22*cos(phase)
		var sample := (sin(TAU*float(notes[0])*t)*0.45+sin(TAU*float(notes[1])*t)*0.23+sin(TAU*float(notes[2])*t)*0.14)*swell
		sample+=sin(TAU*float(notes[0])*2.0*t)*sin(phase)*0.06
		data.encode_s16(i*2,roundi(sample*32767))
	var wav := AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=RATE
	wav.data=data
	wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin=0
	wav.loop_end=count
	return wav

func save_settings() -> void:
	if not persist_settings: return
	var config := ConfigFile.new()
	config.set_value("audio","effects",effects_enabled)
	config.set_value("audio","music",music_enabled)
	config.save(CONFIG)

func toggle_effects() -> void:
	effects_enabled=not effects_enabled
	if not effects_enabled:
		for voice in voices: voice.stop()
	save_settings()

func toggle_music() -> void:
	music_enabled=not music_enabled
	if not music_enabled:
		ambient.stop()
	else:
		var track := current_track
		current_track=""
		set_track(track)
	save_settings()

func set_track(track: String) -> void:
	if current_track==track: return
	current_track=track
	ambient.stop()
	if not music_enabled or track.is_empty(): return
	if not bank.has(track): bank[track]=ambient_stream(track)
	ambient.stream=bank[track]
	ambient.play()

func duck(quiet: bool) -> void:
	ambient.volume_db=-34.0 if quiet else -24.0

func play_sound(id: String,priority: int = 1,volume: float = -13.0) -> void:
	if not effects_enabled or not bank.has(id): return
	var slot := -1
	for i in range(voices.size()):
		if not voices[i].playing:
			slot=i
			break
	if slot<0:
		for i in range(voices.size()):
			if priorities[i]<priority:
				slot=i
				break
	if slot<0: return
	var voice := voices[slot]
	voice.stop()
	voice.stream=bank[id]
	voice.volume_db=volume
	priorities[slot]=priority
	voice.play()

static func snapshot(run: Variant) -> Dictionary:
	return {"basic":run.basic_casts,"special":run.special_casts,"damage":run.total_damage_dealt,
		"hurt":run.total_damage_taken,"kills":run.kills,"level":run.run_level,
		"sites":run.claimed_sites.size(),"boss":run.boss_spawned}

func reset_run() -> void:
	last_impact=-1.0
	last_defeat=-1.0

func after_step(before: Dictionary,run: Variant) -> void:
	var element := str(run.phenotype.affinity)
	var now := float(run.elapsed)
	if run.basic_casts>before.basic: play_sound(element,1,-19.0)
	if run.special_casts>before.special: play_sound("special_"+element,3,-11.0)
	if run.total_damage_dealt>before.damage and now-last_impact>=0.20:
		last_impact=now
		play_sound("impact",0,-23.0)
	if run.kills>before.kills and now-last_defeat>=0.25:
		last_defeat=now
		play_sound("defeat",1,-20.0)
	if run.total_damage_taken>before.hurt: play_sound("hurt",4,-10.0)
	if run.run_level>before.level: play_sound("level",5,-10.0)
	if run.claimed_sites.size()>before.sites: play_sound("reward",3,-13.0)
	if run.boss_spawned and not before.boss: play_sound("boss",5,-11.0)
