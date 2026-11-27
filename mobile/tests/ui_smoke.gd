extends SceneTree
const Main = preload("res://presentation/main.tscn")
const Academy = preload("res://domain/academy.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
const Art = preload("res://presentation/pixel_ui_art.gd")
const Upgrades = preload("res://gameplay/upgrade_catalog.gd")
const Audio = preload("res://presentation/game_audio.gd")
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
	app._show_title()
	app._start(false)
	await process_frame
	check(app.screen=="run" and not app.title_panel.visible and app.special_button.visible,"Quick expedition navigation")
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
	app.queue_free()
	await process_frame
	print("Fantasy UI navigation: %d failures" % failures)
	quit(0 if failures==0 else 1)
