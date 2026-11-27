extends SceneTree
const Main = preload("res://presentation/main.tscn")
const Academy = preload("res://domain/academy.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
const Art = preload("res://presentation/pixel_ui_art.gd")
const Upgrades = preload("res://gameplay/upgrade_catalog.gd")
const Audio = preload("res://presentation/game_audio.gd")
const FX = preload("res://presentation/element_fx.gd")
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
	app.audio.persist_settings=false
	app.audio.effects_enabled=false
	app.audio.music_enabled=false
	root.add_child(app)
	await process_frame
	check(app.screen=="title" and app.title_panel.visible and not app.academy_panel.visible,"Title initially visible")
	check(not app.title_quick.disabled,"Quick expedition available")
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
	app.run.special_cd=3.0
	await physics_frame
	await process_frame
	check(app.special_button.disabled and app.special_button.remaining>0,"Cast cooldown shown")
	check(Fantasy.fraction(-2,10)==0 and Fantasy.fraction(15,10)==1 and Fantasy.fraction(5,0)==0,"Bar fraction bounded")
	app.run.elapsed=40.0
	app.run.kills=5
	app.run.exploration_xp=0
	app.run.exploration_essence=3
	app.run.outcome="Defeated"
	app.academy.roster[app.selected].xp=25
	app.academy.roster[app.partner_index].xp=38
	var old_essence: int=app.academy.essence
	app.academy.blocked=true
	app._finish()
	check(app.screen=="result" and app.result_reward.is_empty() and app.result_retry.visible and not app.result_return.visible,"Failed reward offers retry only")
	check(app.academy.essence==old_essence,"Failed reward does not credit essence")
	app.academy.blocked=false
	app._finish()
	check(app.result_reward.active_gain==20 and app.result_reward.apprentice_gain==5,"Actual training deltas")
	check(app.result_reward.essence_gain==5 and app.result_reward.essence_total==old_essence+5,"Actual total essence delta")
	check(app.result_reward.fusion_ready and app.result_return.visible and not app.result_retry.visible,"Successful retry reveals fusion readiness")
	app._finish()
	check(app.academy.essence==old_essence+5,"Results cannot settle rewards twice")
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
	app._ask_fuse()
	app._fuse()
	check(app.screen=="reveal" and app.academy.archive.size()==2 and app.academy.roster.size()==1,"Fusion commits before ritual")
	check(app.reveal_skip.visible and not app.reveal_panel.visible,"Ritual starts before detail display")
	app._complete_reveal()
	check(app.reveal_panel.visible and not app.reveal_skip.visible,"Skip reveals committed child")
	app._fuse()
	check(app.academy.roster.size()==1 and app.academy.archive.size()==2,"Reveal cannot fuse again")
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
	check(app.result_reward.essence_gain==12,"Victory bonus included")
	app._replay_result()
	check(app.screen=="run" and app.result_reward.is_empty() and app.result_before.is_empty(),"Replay resets result state")
	app.run.endless=true
	app.run.elapsed=30.0
	app._extract()
	check(app.screen=="result" and app.run.outcome=="Extracted" and app.result_reward.newcomer.is_empty(),"Extraction rewards without victory founder")
	app.queue_free()
	await process_frame
	print("Fantasy UI navigation: %d failures" % failures)
	quit(0 if failures==0 else 1)
