extends SceneTree
const Main = preload("res://presentation/main.tscn")
const Academy = preload("res://domain/academy.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
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
	check(Fantasy.fraction(-2,10)==0 and Fantasy.fraction(15,10)==1 and Fantasy.fraction(5,0)==0,"Bar fraction bounded")
	app._show_academy()
	await process_frame
	check(not app.special_button.visible and app.run==null,"Return removes run HUD")
	app.queue_free()
	await process_frame
	print("Fantasy UI navigation: %d failures" % failures)
	quit(0 if failures==0 else 1)
