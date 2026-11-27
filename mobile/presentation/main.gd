extends Node2D
## Portrait prototype. Simulation is owned by RunModel, UI only dispatches commands.
const Academy = preload("res://domain/academy.gd")
const ProfileStore = preload("res://persistence/profile_store.gd")
const RunModel = preload("res://gameplay/run.gd")
const SpriteLibrary = preload("res://presentation/sprite_library.gd")
const ArenaArt = preload("res://presentation/arena_art.gd")
const FIRE := Color("#ef8052")
const ICE := Color("#84d7e8")
const STEAM := Color("#c7b7d8")
var academy := Academy.new(int(Time.get_unix_time_from_system()), ProfileStore.new())
var sprites := SpriteLibrary.new()
var arena_art := ArenaArt.new()
var run: Variant
var selected := 0
var partner_index := -1
var active: Dictionary = {}
var apprentice: Dictionary = {}
var run_id := 0
var difficulty := 1
var screen := "academy"
var paused := false
var touch_id := -1
var touch_origin := Vector2(68, 573)
var touch_current := Vector2(68, 573)
var special_requested := false
var prev_space := false
var movement := Vector2.ZERO
var ui: Control
var info: Label
var start_finite: Button
var start_endless: Button
var special_button: Button
var pause_button: Button
var extract_button: Button
var upgrade_panel: VBoxContainer
var result_panel: VBoxContainer
var academy_panel: VBoxContainer
var run_hud: Label
var difficulty_button: Button
var confirm_fusion: ConfirmationDialog
var archive_dialog: AcceptDialog
var archive_text: RichTextLabel
var lock_button: Button
var result_retry: Button
var result_return: Button

func _ready() -> void:
	get_viewport().gui_embed_subwindows = true
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	_build_ui()
	_show_academy()

func _button(parent: Node, title: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(0, 32)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _label(parent: Node, value: String, size: int = 15) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l

func _box_at(pos: Vector2, size: Vector2) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.position = pos
	v.size = size
	v.add_theme_constant_override("separation", 5)
	ui.add_child(v)
	return v

func _build_ui() -> void:
	academy_panel = _box_at(Vector2(16, 118), Vector2(328, 516))
	_label(academy_panel, "THE ACADEMY", 21)
	info = _label(academy_panel, "")
	_button(academy_panel, "Next wizard", _next_wizard)
	_button(academy_panel, "Next fusion / training partner", _next_partner)
	_button(academy_panel, "Summon  (10 essence)", _summon)
	_button(academy_panel, "Fuse selected pair", _ask_fuse)
	difficulty_button = _button(academy_panel, "Difficulty: I", _cycle_difficulty)
	start_finite = _button(academy_panel, "Enter dungeon", func() -> void: _start(false))
	start_endless = _button(academy_panel, "Endless survival", func() -> void: _start(true))
	lock_button = _button(academy_panel, "Lock wizard", _lock_wizard)
	_button(academy_panel, "Ancestry archive", _show_archive)
	_label(academy_panel, "Completed progress is saved locally.", 12)
	run_hud = _label(ui, "", 14)
	run_hud.position = Vector2(12, 12)
	special_button = _button(ui, "CAST", func() -> void: special_requested = true)
	special_button.position = Vector2(248, 552)
	special_button.size = Vector2(100, 60)
	pause_button = _button(ui, "II", _toggle_pause)
	pause_button.position = Vector2(305, 10)
	pause_button.size = Vector2(43, 35)
	extract_button = _button(ui, "Extract", _extract)
	extract_button.position = Vector2(253, 51)
	extract_button.size = Vector2(95, 34)
	upgrade_panel = _box_at(Vector2(42, 214), Vector2(276, 160))
	_label(upgrade_panel, "CHOOSE AN UPGRADE", 20)
	_button(upgrade_panel, "Spell power +20%", func() -> void: _upgrade(0))
	_button(upgrade_panel, "Faster casting", func() -> void: _upgrade(1))
	_button(upgrade_panel, "Health +15 / heal", func() -> void: _upgrade(2))
	result_panel = _box_at(Vector2(28, 220), Vector2(304, 160))
	_label(result_panel, "")
	result_return = _button(result_panel, "Return to academy", _show_academy)
	result_retry = _button(result_panel, "Retry saving rewards", _finish)
	confirm_fusion = ConfirmationDialog.new()
	confirm_fusion.title = "Irreversible fusion"
	confirm_fusion.dialog_text = "Both parents will retire permanently. Create a Tier II descendant?"
	confirm_fusion.confirmed.connect(_fuse)
	add_child(confirm_fusion)
	archive_dialog = AcceptDialog.new()
	archive_dialog.title = "Ancestry archive"
	archive_text = RichTextLabel.new()
	archive_text.custom_minimum_size = Vector2(290, 290)
	archive_text.scroll_active = true
	archive_dialog.add_child(archive_text)
	add_child(archive_dialog)

func _lock_wizard() -> void:
	if academy.blocked: return
	var c: Dictionary = academy.roster[selected]
	academy.toggle_lock(c.id)
	_refresh_academy()

func _show_archive() -> void:
	var lines := PackedStringArray()
	for c in academy.archive:
		lines.append("%s | Tier %d | %s / %s\nXP %d" % [c.id, c.phenotype.tier, c.phenotype.body.capitalize(), c.phenotype.affinity.capitalize(), c.xp])
		for descendant in academy.roster:
			if c.id in descendant.parents:
				lines.append("Descendant: " + str(descendant.id))
		lines.append("")
	archive_text.text = "\n".join(lines) if not lines.is_empty() else "No retired wizards yet."
	archive_dialog.popup_centered(Vector2i(320, 360))

func _show_academy() -> void:
	screen = "academy"
	run = null
	paused = false
	_clear_input()
	if academy.blocked:
		_refresh_academy()
		_sync_visibility()
		queue_redraw()
		return
	selected = clampi(selected, 0, academy.roster.size() - 1)
	if partner_index == selected or partner_index >= academy.roster.size():
		partner_index = -1
	if partner_index < 0 and academy.roster.size() > 1:
		partner_index = (selected + 1) % academy.roster.size()
	_refresh_academy()
	_sync_visibility()
	queue_redraw()

func _refresh_academy() -> void:
	if academy.blocked:
		info.text = academy.error
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for node in academy_panel.get_children():
			if node is Button: node.disabled = true
		return
	var c: Dictionary = academy.roster[selected]
	var p: Dictionary = c.phenotype
	var partner_text := "None"
	if partner_index >= 0:
		var other: Dictionary = academy.roster[partner_index]
		partner_text = "%s | %s XP %d/%d" % [other.id, other.phenotype.affinity.capitalize(), other.xp, Academy.MATURE_XP]
	info.text = "%s   Tier %d   %s / %s\nHP %d  Speed %d  Damage %.1f\n%s  |  XP %d/%d\nPartner: %s\nRoster %d  |  Archive %d  |  Essence %d" % [c.id, p.tier, p.body.capitalize(), p.affinity.capitalize(), int(p.health), int(p.speed), p.damage, p.special, c.xp, Academy.MATURE_XP, partner_text, academy.roster.size(), academy.archive.size(), academy.essence]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	difficulty_button.text = "Difficulty: %s" % ["I", "II", "III"][difficulty - 1]
	lock_button.text = "Unlock wizard" if c.locked else "Lock wizard"
	if not c.parents.is_empty(): info.text += "\nParents: " + ", ".join(PackedStringArray(c.parents))
	if not academy.error.is_empty(): info.text += "\n" + academy.error
	elif not academy.notice.is_empty(): info.text += "\n" + academy.notice

func _next_wizard() -> void:
	selected = (selected + 1) % academy.roster.size()
	if partner_index == selected:
		partner_index = (selected + 1) % academy.roster.size() if academy.roster.size() > 1 else -1
	_refresh_academy()
	queue_redraw()

func _next_partner() -> void:
	if academy.roster.size() < 2: return
	partner_index = (partner_index + 1) % academy.roster.size()
	if partner_index == selected: partner_index = (partner_index + 1) % academy.roster.size()
	_refresh_academy()
	queue_redraw()

func _summon() -> void:
	if academy.summon():
		selected = academy.roster.size() - 1
	_refresh_academy()
	queue_redraw()

func _ask_fuse() -> void:
	if partner_index < 0: return
	if academy.eligible(academy.roster[selected], academy.roster[partner_index]):
		confirm_fusion.popup_centered(Vector2i(300, 160))
	else:
		_refresh_academy()
		info.text += "\nBoth parents must be mature, unlocked Tier I."

func _fuse() -> void:
	if partner_index < 0: return
	var child: Dictionary = academy.fuse(academy.roster[selected], academy.roster[partner_index])
	if not child.is_empty():
		selected = academy.roster.size() - 1
		partner_index = -1
		_show_academy()
	else:
		_refresh_academy()

func _cycle_difficulty() -> void:
	difficulty = difficulty % 3 + 1
	_refresh_academy()

func _start(endless: bool) -> void:
	active = academy.roster[selected]
	apprentice = academy.roster[partner_index] if partner_index >= 0 else {}
	run_id = academy.allocate_run()
	if run_id < 0:
		_refresh_academy()
		return
	run = RunModel.new(active.phenotype, endless, difficulty, 1000 + run_id)
	screen = "run"
	paused = false
	_clear_input()
	_sync_visibility()

func _toggle_pause() -> void:
	if screen != "run" or run.pending_upgrades > 0: return
	paused = not paused
	_clear_input()
	_sync_visibility()

func _extract() -> void:
	if screen == "run" and not paused and run.pending_upgrades == 0:
		run.extract()
		if run.outcome != "": _finish()

func _upgrade(choice: int) -> void:
	if screen == "run":
		run.upgrade(choice)
		_clear_input()
		_sync_visibility()

func _finish() -> void:
	var earned: int = floori(float(run.elapsed) / 4.0) + int(run.kills) * 2
	var active_now := academy.find_active(str(active.id))
	var apprentice_now := academy.find_active(str(apprentice.get("id", "")))
	var saved := academy.reward(run_id, active_now, apprentice_now, earned, run.outcome == "Victory")
	screen = "result"
	_clear_input()
	var summary := result_panel.get_child(0) as Label
	summary.text = "%s\nTime %.0fs  |  Kills %d\nCharacter XP +%d\nShared XP +%d" % [run.outcome, run.elapsed, run.kills, earned, floori(earned * 0.25) if not apprentice.is_empty() else 0] if saved else "Reward not saved.\n" + academy.error + "\nRetry before leaving."
	result_retry.visible = not saved
	result_return.visible = saved
	_sync_visibility()

func _sync_visibility() -> void:
	var in_run := screen == "run"
	academy_panel.visible = screen == "academy"
	result_panel.visible = screen == "result"
	run_hud.visible = in_run
	special_button.visible = in_run
	pause_button.visible = in_run
	extract_button.visible = in_run and run != null and run.endless
	upgrade_panel.visible = in_run and run != null and run.pending_upgrades > 0
	pause_button.text = ">" if paused else "II"

func _clear_input() -> void:
	touch_id = -1
	touch_current = touch_origin
	movement = Vector2.ZERO
	special_requested = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "run":
		paused = true
		_clear_input()
		_sync_visibility()

func _input(event: InputEvent) -> void:
	if screen != "run" or paused or run.pending_upgrades > 0: return
	if event is InputEventScreenTouch:
		if event.pressed and Rect2(248, 552, 100, 60).has_point(event.position):
			special_requested = true
			get_viewport().set_input_as_handled()
			return
		if event.pressed and touch_id == -1 and event.position.x < 220 and event.position.y > 525:
			touch_id = event.index
			touch_origin = event.position
			touch_current = touch_origin
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			touch_current = touch_origin
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_id:
		touch_current = event.position
		get_viewport().set_input_as_handled()

func _physics_process(dt: float) -> void:
	if screen != "run":
		queue_redraw()
		return
	var space := Input.is_physical_key_pressed(KEY_SPACE)
	if not paused and run.pending_upgrades == 0:
		var keyboard := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		movement = keyboard.limit_length()
		if touch_id != -1:
			movement = ((touch_current - touch_origin) / 35.0).limit_length()
			if movement.length() < 0.12: movement = Vector2.ZERO
		run.step(dt, movement, special_requested or (space and not prev_space))
		if run.pending_upgrades > 0:
			_clear_input()
		if run.outcome != "":
			_finish()
		else:
			_sync_visibility()
	else:
		movement = Vector2.ZERO
	prev_space = space
	special_requested = false
	if screen == "run":
		run_hud.text = "HP %d/%d    Lv %d\nXP %d/%d    %ds    Kills %d%s" % [int(run.hp), int(run.max_hp), run.run_level, run.xp, run.next_xp, int(run.elapsed), run.kills, "  PAUSED" if paused else ""]
		special_button.text = str(run.phenotype.special) if run.special_cd <= 0 else "%.1fs" % run.special_cd
		special_button.add_theme_font_size_override("font_size", 12)
		special_button.disabled = paused or run.special_cd > 0 or run.pending_upgrades > 0
		extract_button.disabled = paused or run.elapsed < 30 or run.pending_upgrades > 0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 360, 640), Color("#1b1924"))
	if screen == "academy":
		if academy.blocked or academy.roster.is_empty(): return
		var c: Dictionary = academy.roster[selected]
		sprites.draw_wizard(self, c.phenotype, Vector2(180, 112), 0, 3.0)
		return
	if screen != "run" or run == null: return
	draw_texture(arena_art.floor_texture, Vector2(0, 88))
	draw_rect(Rect2(0, 88, 360, 448), Color("#48404e"), false, 2.0)
	var color: Color = FIRE if run.phenotype.affinity == "fire" else (ICE if run.phenotype.affinity == "ice" else STEAM)
	draw_rect(Rect2(12, 73, 220, 8), Color("#502e40"))
	draw_rect(Rect2(12, 73, 220 * run.hp / run.max_hp, 8), Color("#c66c73"))
	for e in run.enemies:
		arena_art.draw_enemy(self, e, float(run.elapsed))
	for shot in run.shots:
		var projectile: Texture2D = arena_art.projectiles[run.phenotype.affinity]
		draw_texture(projectile, shot.pos - Vector2(4, 4))
	if run.special_fx > 0:
		var radius := 82.0 if run.phenotype.mutation == "crystal_wings" else 66.0
		var fraction := 1.0 - float(run.special_fx) / 0.35
		var ring := radius * (0.45 + 0.55 * fraction)
		var fade := Color(color, 1.0 - fraction)
		draw_arc(run.player, ring, 0, TAU, 32, fade, 3.0)
		for i in range(12):
			var offset := Vector2.from_angle(i * TAU / 12.0) * ring
			draw_rect(Rect2(run.player + offset - Vector2(2, 2), Vector2(4, 4)), fade)
	var frame: int = int(run.elapsed * 6) % 2 if movement.length_squared() > 0 else 0
	sprites.draw_wizard(self, run.phenotype, run.player, frame, 1.2)
	var origin := touch_origin if touch_id != -1 else Vector2(68, 573)
	var thumb := origin + movement * 30.0
	draw_circle(origin, 34, Color(0.7, 0.7, 0.8, 0.12))
	draw_arc(origin, 34, 0, TAU, 32, Color("#655f78"), 1.0)
	draw_circle(thumb, 12, Color("#89819c"))
	if paused or run.pending_upgrades > 0:
		draw_rect(Rect2(0, 90, 360, 446), Color(0.04, 0.03, 0.06, 0.76))

