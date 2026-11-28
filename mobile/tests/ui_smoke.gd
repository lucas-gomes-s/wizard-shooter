extends SceneTree
const Main = preload("res://presentation/main.tscn")
const Academy = preload("res://domain/academy.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
const Art = preload("res://presentation/pixel_ui_art.gd")
const Upgrades = preload("res://gameplay/upgrade_catalog.gd")
const Audio = preload("res://presentation/game_audio.gd")
const FX = preload("res://presentation/element_fx.gd")
const Settings = preload("res://presentation/visual_settings.gd")
const Monitor = preload("res://presentation/performance_monitor.gd")
const Guide = preload("res://presentation/onboarding.gd")
const Playtest = preload("res://persistence/playtest_journal.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_test")

func check(value: bool, note: String) -> void:
	if not value:
		failures += 1
		push_error(note)

func _test() -> void:
	var app: Variant = Main.instantiate()
	app.academy = Academy.new(42)
	app.settings.persist=false
	app.guide.persist=false
	app.playtest.persist=false
	app.audio.persist_settings=false
	app.audio.effects_enabled=false
	app.audio.music_enabled=false
	root.add_child(app)
	await process_frame
	check(app.screen=="title" and app.title_panel.visible and not app.academy_panel.visible,"Title initially visible")
	check(not app.title_quick.disabled,"Quick expedition available")
	app._open_guide()
	await process_frame
	check(app.guide_panel.visible and not app.title_panel.visible,"Guide accessible from title")
	check(app.guide_content.text.contains("40 XP"),"Guide explains first fusion")
	app._toggle_guide()
	check(not app.guide.enabled,"Tips can be dismissed")
	app._reset_guide()
	check(app.guide.enabled and app.guide.lesson_count()==0,"Guide reset does not require fresh profile")
	app._close_guide()
	check(app.screen=="title","Guide returns to origin")
	var saved_guide := Guide.new()
	saved_guide.path="user://test_onboarding.cfg"
	saved_guide.mark(Guide.MOVE)
	saved_guide.enabled=false
	check(saved_guide.save_settings()==OK,"Lesson preference saved")
	var loaded_guide := Guide.new()
	loaded_guide.path=saved_guide.path
	loaded_guide.load_settings(false)
	check(loaded_guide.knows(Guide.MOVE) and not loaded_guide.enabled,"Lesson progress reloads")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_guide.path))
	app._open_settings()
	check(app.settings_panel.visible and not app.title_panel.visible,"Title settings navigation")
	app._toggle_visual("fps")
	check(Engine.max_fps==30 and Engine.physics_ticks_per_second==60,"Render cap independent of simulation ticks")
	app._toggle_visual("fps")
	check(app.settings.balance_preset=="trial20-short","Candidate is initial finite playtest preference")
	app._cycle_balance()
	check(app.settings.balance_preset=="trial20-frost","Frost experiment selectable")
	app._cycle_balance()
	check(app.settings.balance_preset=="expedition-six","Long experiment selectable")
	app._cycle_balance()
	check(app.settings.balance_preset=="expedition-mana","Mana experiment selectable")
	app._cycle_balance()
	check(app.settings.balance_preset=="expedition-trials","Trial experiment selectable")
	app._cycle_balance()
	check(app.settings.balance_preset=="expedition-evolution","Evolution experiment selectable")
	app._cycle_balance()
	check(app.settings.balance_preset=="original","Original comparison selectable")
	app._cycle_balance()
	app._open_backup()
	check(app.screen=="backup" and app.backup_panel.visible,"Backup navigation")
	app._generate_backup()
	check(not app.backup_text.text.is_empty() and app.backup_confirm.disabled,"Export does not authorize restore")
	app._validate_backup()
	check(not app.backup_confirm.disabled,"Valid backup requires confirmation")
	app.backup_text.text="invalid"
	app._restore_backup()
	check(app.backup_confirm.disabled,"Changed backup cannot restore")
	app._generate_backup()
	app._validate_backup()
	app._restore_backup()
	check(app.academy.roster.size()==2 and app.pending_backup.is_empty(),"Confirmed restore")
	app._close_backup()
	app._open_playtest()
	check(app.screen=="playtest" and not app.playtest.enabled and app.playtest.events.is_empty(),"Journal disabled by default")
	app._toggle_playtest()
	check(app.playtest.enabled and app.playtest.events.size()==1,"Explicit opt-in starts local session")
	app._preview_playtest()
	check(app.playtest_text.text.contains("wizard-shooter-playtest"),"Preview report")
	app._clear_playtest()
	check(app.playtest.events.size()==1 and app.clear_armed,"Clear needs confirmation")
	app._clear_playtest()
	check(app.playtest.events.is_empty(),"Confirmed clear")
	app._close_playtest()
	app._close_settings()
	_test_journal()
	check(app.screen=="title","Settings return to title")
	var preferences := Settings.new()
	preferences.path="user://test_visual_settings.cfg"
	preferences.fps=30
	preferences.simple_effects=true
	preferences.balance_preset="original"
	check(preferences.save_settings()==OK,"Visual preferences save")
	var restored := Settings.new()
	restored.path=preferences.path
	restored.load_settings()
	check(restored.fps==30 and restored.simple_effects and restored.balance_preset=="original","Visual and balance preferences reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(preferences.path))
	var meter := Monitor.new()
	for i in range(Monitor.LIMIT+10): meter.record_frame(0.020)
	check(meter.frame_ms.size()==Monitor.LIMIT and meter.total_frames==Monitor.LIMIT+10,"Rolling frame sample bounded")
	check(absf(float(Monitor.stats(meter.frame_ms).p95)-20.0)<0.01,"Frame percentile calculation")
	app._show_academy()
	await process_frame
	check(app.academy_panel.visible and app.title_menu_button.visible and not app.title_panel.visible,"Academy navigation")
	app._show_roster()
	await process_frame
	check(app.roster_panel.visible and not app.academy_panel.visible,"Collection screen navigation")
	check(app.roster_buttons[0].visible and app.roster_buttons[1].visible and not app.roster_buttons[2].visible,"Only occupied roster cards visible")
	app._open_roster_slot(1)
	check(app.detail_panel.visible and app.detail_index==1,"Inspect selected card")
	app._assign_active()
	check(app.selected==1 and app.partner_index==-1,"Active cannot be own apprentice")
	app._back_detail()
	app._open_roster_slot(0)
	app._assign_apprentice()
	check(app.partner_index==0,"Assign apprentice from collection")
	app._lock_detail()
	check(app.academy.roster[0].locked,"Lock from detail")
	app._lock_detail()
	app._show_academy()
	app._clear_apprentice()
	app._show_title()
	app._show_academy()
	check(app.partner_index==-1,"Explicit empty apprentice survives navigation")
	app._show_detail(0,"academy")
	app._assign_apprentice()
	app._show_title()
	app._start(false)
	await process_frame
	check(app.screen=="run" and not app.title_panel.visible and app.special_button.visible,"Quick expedition navigation")
	check(app.run.balance==app.Balance.TRIAL_20,"Finite run receives selected preset")
	var run_start: Dictionary={}
	for event in app.playtest.events:
		if event.type=="run_start": run_start=event.data
	check(run_start.get("balance_preset")=="trial20-short" and run_start.get("balance")==app.run.balance,"Journal records actual balance")
	app.walk_facing="west"
	app._update_motion_art(app.run.player,1.0/60.0)
	check(app.walk_facing=="west","Idle facing retained")
	app._update_motion_art(app.run.player-Vector2(0,2),1.0/60.0)
	check(app.walk_facing=="south","Actual displacement drives facing")
	var cast_count: int = app.run.special_casts
	app.special_requested=true
	await physics_frame
	await process_frame
	check(app.run.special_casts==cast_count+1 and not app.elemental_fx.cast.is_empty(),"Real cast triggers visual snapshot")
	check(app.guide.knows(Guide.SPECIAL),"Successful cast completes lesson")
	app.guide.observe_step(app.run,app.run.player-Vector2(25,0),app.run.basic_casts,app.run.special_casts)
	check(app.guide.knows(Guide.MOVE),"Actual travel completes movement lesson")
	var origin: Vector2=app.elemental_fx.cast.pos
	app.run.player+=Vector2(25,0)
	check(app.elemental_fx.cast.pos==origin,"Cast effect remains at cast origin")
	check(float(app.elemental_fx.cast.radius)==float(app.run.kit.special.radius),"Cast radius matches compiled spell")
	check(FX.intersects(Rect2(0,0,100,100),Vector2(120,50),25),"Area culling includes overlapping effects")
	check(not FX.intersects(Rect2(0,0,100,100),Vector2(140,50),25),"Distant areas culled")
	# Exercise all effect drawing branches independently of founder affinity.
	var probe := Node2D.new()
	probe.draw.connect(func() -> void:
		for element in ["fire","ice","steam"]:
			FX.projectile(probe,{"pos":Vector2(20,20),"vel":Vector2.RIGHT*100,"affinity":element,"life":0.5},0.2)
			FX.cloud(probe,{"pos":Vector2(60,60),"radius":42.0,"affinity":element,"life":1.0},0.2)
			FX.burst(probe,Vector2(80,80),76.0,element,0.4,true)
			FX.burst(probe,Vector2(80,80),19.0,element,0.4,false)
			FX.impact(probe,{"pos":Vector2(60,60),"affinity":element,"kind":"hit"},0.2)
			FX.impact(probe,{"pos":Vector2(60,60),"affinity":element,"kind":"defeat"},0.7)
		FX.enemy_status(probe,{"pos":Vector2(50,50),"radius":7.0,"freeze":1.0,"burn":1.0},0.4)
		FX.enemy_status(probe,{"pos":Vector2(50,50),"radius":7.0,"chill":1.0},0.4))
	root.add_child(probe)
	probe.queue_redraw()
	await process_frame
	await process_frame
	probe.queue_free()
	app.run.hp = app.run.max_hp*0.15
	app.run.xp = 3
	app.run.run_level = 2
	app.queue_redraw()
	await process_frame
	app._toggle_pause()
	await process_frame
	check(app.paused,"Pause works")
	var elapsed: float=app.run.elapsed
	app._open_settings()
	check(app.settings_options.balance.disabled,"Preset cannot change during a paused run")
	app._cycle_balance()
	check(app.settings.balance_preset=="trial20-short","Paused preset guard")
	app._toggle_visual("simple_effects")
	app._toggle_visual("monitor")
	app._toggle_visual("reduced_motion")
	await physics_frame
	await process_frame
	check(app.screen=="settings" and app.run.elapsed==elapsed,"Settings preserve paused run")
	app._close_settings()
	check(app.screen=="run" and app.paused,"Settings return to paused run")
	app._toggle_pause()
	app.run.pending_upgrades=1
	app.run.ensure_upgrade_offer()
	app._sync_visibility()
	await process_frame
	check(app.upgrade_panel.visible and app.upgrade_buttons[0].visible,"Upgrade card visible")
	var card: Variant = app.upgrade_buttons[0]
	for id in Upgrades.DEFINITIONS:
		var d: Dictionary = Upgrades.DEFINITIONS[id]
		card.configure(id,d,0,Fantasy.GOLD)
		check(card.name_label.text==d.name and card.detail_label.text==d.text,"Upgrade card contents: "+id)
		check(card.icon_view.texture!=null,"Upgrade icon: "+id)
	for id in Art.ICONS:
		var img := Art.icon_image(id,Fantasy.GOLD)
		check(img.get_size()==Vector2i(9,9) and img.get_used_rect().get_area()>0,"Pixel icon: "+id)
	app._refresh_upgrades()
	var offered: String = app.run.upgrade_offer[0]
	app._upgrade(0)
	check(int(app.run.upgrade_ranks.get(offered,0))==1 and not app.upgrade_panel.visible,"Card selection applies original upgrade")
	check(app.guide.knows(Guide.UPGRADE),"Applied upgrade completes lesson")
	check(int(app.playtest.report().counts.get("upgrade",0))==1,"Actual upgrade choice logged once")
	app.run.special_cd=3.0
	await physics_frame
	await process_frame
	check(app.special_button.disabled and app.special_button.remaining>0,"Cast cooldown shown")
	check(Fantasy.fraction(-2,10)==0 and Fantasy.fraction(15,10)==1 and Fantasy.fraction(5,0)==0,"Bar fraction bounded")
	app.run.elapsed=72.0
	app.run.kills=20
	app.run.exploration_xp=0
	app.run.exploration_essence=3
	app.run.outcome="Defeated"
	app.academy.roster[app.selected].xp=35
	app.academy.roster[app.partner_index].xp=39
	var old_essence: int=app.academy.essence
	app.academy.blocked=true
	app._finish()
	check(app.screen=="result" and app.result_reward.is_empty() and app.result_retry.visible and not app.result_return.visible,"Failed reward offers retry only")
	check(app.academy.essence==old_essence,"Failed reward does not credit essence")
	app.academy.blocked=false
	app._finish()
	check(app.result_reward.active_gain==5 and app.result_reward.apprentice_gain==1,"Actual training deltas")
	check(app.result_reward.essence_gain==1 and app.result_reward.essence_total==old_essence+1,"Actual total essence delta")
	check(app.result_reward.fusion_ready and app.result_return.visible and not app.result_retry.visible,"Successful retry reveals fusion readiness")
	check(Guide.fusion_tip(app.academy,app.academy.roster[app.selected],app.academy.roster[app.partner_index]).contains("ready"),"First fusion guidance reflects committed training")
	app._finish()
	check(app.academy.essence==old_essence+1,"Results cannot settle rewards twice")
	var logged: Dictionary=app.playtest.report().counts
	check(logged.get("run_end",0)==1 and logged.get("reward_saved",0)==1,"Retry does not duplicate outcome or reward log")
	await process_frame
	app._show_academy()
	await process_frame
	check(not app.special_button.visible and app.run==null,"Return removes run HUD")
	for id in Audio.SOUNDS:
		var wav := Audio.effect_stream(id)
		check(wav.data.size()>0 and wav.mix_rate==Audio.RATE,"Synthesized sound: "+id)
	var loop := Audio.ambient_stream("dungeon")
	check(loop.loop_mode==AudioStreamWAV.LOOP_FORWARD and loop.loop_end*2==loop.data.size(),"Ambient loop configured")
	check(app.audio.voices.size()==Audio.VOICES,"Audio voice pool bounded")
	app.academy.roster[0].xp=Academy.MATURE_XP
	app.academy.roster[1].xp=Academy.MATURE_XP
	app.settings.reduced_motion=false
	app._ask_fuse()
	app._fuse()
	check(app.screen=="reveal" and app.academy.archive.size()==2 and app.academy.roster.size()==1,"Fusion commits before ritual")
	check(app.reveal_skip.visible and not app.reveal_panel.visible,"Ritual starts before detail display")
	app._complete_reveal()
	check(app.reveal_panel.visible and not app.reveal_skip.visible,"Skip reveals committed child")
	app._fuse()
	check(app.academy.roster.size()==1 and app.academy.archive.size()==2,"Reveal cannot fuse again")
	check(app.playtest.report().counts.get("fusion",0)==1,"Committed fusion logged once")
	app._show_academy()
	app.academy.essence=100
	for i in range(7): app.academy.summon()
	app._show_roster()
	app._change_page(1)
	check(app.roster_page==1 and app.roster_buttons[1].visible and not app.roster_buttons[2].visible,"Pagination after roster expansion")
	app._change_page(1)
	check(app.roster_page==1 and app.roster_next.disabled,"Last page bounded")
	app._show_academy()
	app._start(false)
	var prior_count: int=app.academy.roster.size()
	app.run.outcome="Victory"
	app.run.elapsed=90.0
	app.run.kills=0
	app._finish()
	check(app.academy.roster.size()==prior_count+1 and not app.result_reward.newcomer.is_empty(),"Victory shows actual awarded founder")
	check(app.result_reward.essence_gain==2,"Victory bonus included exactly once")
	app._replay_result()
	check(app.screen=="run" and app.result_reward.is_empty() and app.result_before.is_empty(),"Replay resets result state")
	app.run.endless=true
	app.run.elapsed=30.0
	app._extract()
	check(app.screen=="result" and app.run.outcome=="Extracted" and app.result_reward.newcomer.is_empty(),"Extraction rewards without victory founder")
	app._show_academy()
	app._cycle_balance()
	app._start(false)
	check(app.run.frost_rules and app.run.balance==app.Balance.TRIAL_20,"Frost run uses candidate numeric parameters and revised rules")
	app._show_academy()
	app._cycle_balance()
	app._start(false)
	check(app.run.phased_expedition and app.run.boss_after_seconds()==360.0,"Long run selected")
	app.run.elapsed=345.0
	app.queue_redraw()
	await process_frame
	app._show_academy()
	app._cycle_balance()
	app._start(false)
	check(app.run.mana_rules and app.run.phased_expedition,"Mana expedition selected")
	app.run.mana.drop(Vector2(40,0),5,0,app.run.world_seed)
	app.queue_redraw()
	await process_frame
	app._show_academy()
	app._cycle_balance()
	app._start(false)
	check(app.run.trial_rules and app.run.mana_rules,"Trial mode selected")
	app.run.elapsed=120.0
	app.run._maybe_start_trial()
	app.queue_redraw()
	await process_frame
	for e in app.run.enemies: e.hp=0
	app.run.step(1.0/60.0,Vector2.ZERO,false)
	app._sync_visibility()
	check(app.upgrade_panel.visible and app.upgrade_heading.text.contains("RELIC"),"Trial reward uses visible upgrade cards")
	app._upgrade(1)
	check(app.run.relic_choices.size()==1 and not app.run.relic_pending,"Relic UI applies selection")
	app._show_academy()
	app._cycle_balance()
	app._start(false)
	check(app.run.evolution_rules,"Evolution mode selected")
	app.run.elapsed=120.0
	app.run._maybe_start_trial()
	for e in app.run.enemies: e.hp=0
	app.run.step(1.0/60.0,Vector2.ZERO,false)
	app._sync_visibility()
	check(app.upgrade_heading.text=="EVOLVE YOUR MAGIC" and app.run.upgrade_offer.size()==2,"Evolution reward cards visible")
	app._upgrade(0)
	check(not app.run.evolution_branch.is_empty(),"UI applies branch")
	app._show_academy()
	app._start(true)
	check(app.run.balance==app.Balance.DEFAULTS and not app.run.frost_rules,"Endless keeps original unoptimized balance")
	app.queue_free()
	await process_frame
	print("Fantasy UI navigation: %d failures" % failures)
	quit(0 if failures==0 else 1)

func _test_journal() -> void:
	var journal := Playtest.new()
	journal.path="user://test_playtest_%d.json" % Time.get_ticks_usec()
	check(journal.record("session")==0 and not FileAccess.file_exists(journal.path),"No logging or files before opt-in")
	check(journal.set_enabled(true),"Journal opt-in saved")
	journal.record("session",{"build":"test"})
	var reopened := Playtest.new()
	reopened.path=journal.path
	reopened.load_journal()
	check(reopened.enabled and reopened.events.size()==1,"Journal survives restart")
	check(reopened.set_enabled(false) and reopened.record("session")==0,"Opt-out stops recording")
	check(reopened.events.size()==1,"Opt-out retains inspectable history")
	check(reopened.clear() and reopened.events.is_empty(),"Clear persisted")
	var fresh := Playtest.new()
	fresh.path=journal.path
	fresh.load_journal()
	check(not fresh.enabled and fresh.events.is_empty(),"Clear and opt-out survive restart")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(journal.path))
	var memory := Playtest.new()
	memory.persist=false
	memory.enabled=true
	for i in range(Playtest.LIMIT+3): memory.record("session")
	check(memory.events.size()==Playtest.LIMIT and memory.dropped==3 and int(memory.events[0].seq)==4,"Journal retention bounded with dropped count")
