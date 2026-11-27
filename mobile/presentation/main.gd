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
var fusion_panel: VBoxContainer
var fusion_hint: Label
var fusion_confirm: Button
var reveal_panel: VBoxContainer
var reveal_info: Label
var revealed: Dictionary = {}
var active_picker: OptionButton
var partner_picker: OptionButton
var status_label: Label
var fuse_button: Button
var summon_button: Button
var lineage_panel: VBoxContainer
var lineage_info: Label
var lineage_index := 0
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
	ui.theme = _make_theme()
	_build_ui()
	_show_academy()

func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#383044") if state == "normal" else (Color("#52435f") if state == "hover" else (Color("#705774") if state == "pressed" else Color("#25232c")))
		style.border_color = Color("#75627f") if state != "disabled" else Color("#393542")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		theme.set_stylebox(state, "Button", style)
		theme.set_stylebox(state, "OptionButton", style)
	theme.set_color("font_color", "Button", Color("#e9dfd0"))
	theme.set_color("font_disabled_color", "Button", Color("#807789"))
	return theme

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

func _picker(parent: Node, callback: Callable) -> OptionButton:
	var picker := OptionButton.new()
	picker.fit_to_longest_item = false
	picker.custom_minimum_size = Vector2(0, 34)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.item_selected.connect(callback)
	parent.add_child(picker)
	return picker

func _pair(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	return row

func _build_ui() -> void:
	academy_panel = _box_at(Vector2(16, 205), Vector2(328, 420))
	var pickers := _pair(academy_panel)
	active_picker = _picker(pickers, _select_active)
	partner_picker = _picker(pickers, _select_partner)
	info = _label(academy_panel, "", 13)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actions := _pair(academy_panel)
	summon_button = _button(actions, "Summon • 10", _summon)
	fuse_button = _button(actions, "Fusion chamber", _ask_fuse)
	summon_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuse_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var collection := _pair(academy_panel)
	lock_button = _button(collection, "Lock wizard", _lock_wizard)
	var archive_button := _button(collection, "Archive / lineage", _show_archive)
	lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_button = _button(academy_panel, "Difficulty: I", _cycle_difficulty)
	start_finite = _button(academy_panel, "Enter dungeon", func() -> void: _start(false))
	start_endless = _button(academy_panel, "Endless survival", func() -> void: _start(true))
	status_label = _label(academy_panel, "", 12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fusion_panel = _box_at(Vector2(24, 326), Vector2(312, 270))
	fusion_hint = _label(fusion_panel, "", 15)
	fusion_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fusion_confirm = _button(fusion_panel, "Confirm irreversible fusion", _fuse)
	_button(fusion_panel, "Return without fusing", _show_academy)
	reveal_panel = _box_at(Vector2(24, 330), Vector2(312, 220))
	reveal_info = _label(reveal_panel, "", 15)
	reveal_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(reveal_panel, "Meet your new wizard", _show_academy)
	lineage_panel = _box_at(Vector2(20, 362), Vector2(320, 240))
	lineage_info = _label(lineage_panel, "", 14)
	lineage_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var nav := _pair(lineage_panel)
	var previous := _button(nav, "Previous", func() -> void: _cycle_lineage(-1))
	var next := _button(nav, "Next", func() -> void: _cycle_lineage(1))
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(lineage_panel, "Retired records", _show_retired_records)
	_button(lineage_panel, "Return to academy", _show_academy)
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

func _lineage_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for c in academy.roster:
		if not c.parents.is_empty(): records.append(c)
	for c in academy.archive:
		if not c.parents.is_empty(): records.append(c)
	return records

func _show_archive() -> void:
	if academy.blocked: return
	lineage_index = 0
	screen = "lineage"
	_refresh_lineage()
	_sync_visibility()
	queue_redraw()

func _cycle_lineage(direction: int) -> void:
	var records := _lineage_records()
	if records.is_empty(): return
	lineage_index = posmod(lineage_index + direction, records.size())
	_refresh_lineage()
	queue_redraw()

func _refresh_lineage() -> void:
	var records := _lineage_records()
	if records.is_empty():
		lineage_info.text = "No lineages yet. Fuse two mature wizards to establish a bloodline."
	else:
		var c: Dictionary = records[lineage_index]
		lineage_info.text = "Bloodline %d / %d\n%s • Tier %d\nParents remain in the archive." % [lineage_index + 1, records.size(), c.id, c.phenotype.tier]

func _show_retired_records() -> void:
	var lines := PackedStringArray()
	for c in academy.archive:
		lines.append("%s | Tier %d | %s / %s\nXP %d" % [c.id, c.phenotype.tier, c.phenotype.body.capitalize(), c.phenotype.affinity.capitalize(), c.xp])
		for descendant in academy.roster + academy.archive:
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

func _disable_controls(root: Node) -> void:
	for node in root.get_children():
		if node is BaseButton: node.disabled = true
		_disable_controls(node)

func _refresh_academy() -> void:
	if academy.blocked:
		info.text = academy.error
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_disable_controls(academy_panel)
		return
	var c: Dictionary = academy.roster[selected]
	var p: Dictionary = c.phenotype
	active_picker.clear()
	partner_picker.clear()
	partner_picker.add_item("No apprentice", -1)
	for i in range(academy.roster.size()):
		var record: Dictionary = academy.roster[i]
		var label := "%s · %s" % [record.phenotype.affinity.capitalize(), str(record.id).right(4)]
		active_picker.add_item(label, i)
		if i != selected: partner_picker.add_item(label, i)
	active_picker.select(selected)
	partner_picker.select(0)
	for i in range(1, partner_picker.item_count):
		if partner_picker.get_item_id(i) == partner_index: partner_picker.select(i)
	var p2: Dictionary = academy.roster[partner_index] if partner_index >= 0 else {}
	info.text = "HP %d  •  Speed %d  •  Power %.1f\n%s  |  %.2fs cast interval\n%s" % [int(p.health), int(p.speed), p.damage, p.special, p.interval, str(p.mutation).replace("_", " ").capitalize() if p.mutation != "none" else "No expressed mutation"]
	difficulty_button.text = "Difficulty: %s" % ["I", "II", "III"][difficulty - 1]
	lock_button.text = "Unlock wizard" if c.locked else "Lock wizard"
	summon_button.disabled = academy.essence < 10
	fuse_button.disabled = p2.is_empty()
	status_label.text = academy.error if not academy.error.is_empty() else academy.notice
	if status_label.text.is_empty(): status_label.text = "Shared training: apprentice gains 25% XP."

func _select_active(index: int) -> void:
	selected = active_picker.get_item_id(index)
	if partner_index == selected: partner_index = -1
	_refresh_academy()
	queue_redraw()

func _select_partner(index: int) -> void:
	partner_index = -1 if index == 0 else partner_picker.get_item_id(index)
	_refresh_academy()
	queue_redraw()

func _summon() -> void:
	if academy.summon():
		selected = academy.roster.size() - 1
		if partner_index == selected: partner_index = -1
	_refresh_academy()
	queue_redraw()

func _ask_fuse() -> void:
	if partner_index < 0: return
	screen = "fusion"
	_refresh_fusion()
	_sync_visibility()
	queue_redraw()

func _refresh_fusion() -> void:
	var first: Dictionary = academy.roster[selected]
	var second: Dictionary = academy.roster[partner_index]
	fusion_hint.text = academy.fusion_hint(first, second)
	fusion_confirm.disabled = not academy.eligible(first, second)
	if not academy.error.is_empty(): fusion_hint.text += "\n" + academy.error

func _fuse() -> void:
	if partner_index < 0: return
	var child: Dictionary = academy.fuse(academy.roster[selected], academy.roster[partner_index])
	if not child.is_empty():
		selected = academy.roster.size() - 1
		partner_index = -1
		revealed = child
		reveal_info.text = "%s • Tier %d\n%s / %s\n%s\nBoth parents have been archived." % [child.id, child.phenotype.tier, child.phenotype.body.capitalize(), child.phenotype.affinity.capitalize(), child.phenotype.special]
		screen = "reveal"
		_sync_visibility()
		queue_redraw()
	else:
		_refresh_fusion()

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
	fusion_panel.visible = screen == "fusion"
	reveal_panel.visible = screen == "reveal"
	lineage_panel.visible = screen == "lineage"
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
		if screen == "reveal": queue_redraw()
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
		_draw_title("THE ACADEMY", "%d essence   •   %d active   •   %d retired" % [academy.essence, academy.roster.size(), academy.archive.size()])
		if academy.blocked or academy.roster.is_empty(): return
		_draw_card(academy.roster[selected], Rect2(16, 55, 160, 140), "ACTIVE")
		_draw_card(academy.roster[partner_index] if partner_index >= 0 else {}, Rect2(184, 55, 160, 140), "APPRENTICE")
		return
	if screen == "fusion":
		_draw_title("FUSION CHAMBER", "Two bloodlines. One descendant.")
		_draw_card(academy.roster[selected], Rect2(16, 68, 160, 150), "PARENT I")
		_draw_card(academy.roster[partner_index], Rect2(184, 68, 160, 150), "PARENT II")
		draw_line(Vector2(96, 218), Vector2(180, 264), Color("#876c91"), 2)
		draw_line(Vector2(264, 218), Vector2(180, 264), Color("#876c91"), 2)
		draw_arc(Vector2(180, 278), 32, 0, TAU, 40, Color("#a48ab8"), 2)
		_center_text("?", Vector2(180, 288), 26, Color("#dcc8ef"))
		return
	if screen == "reveal":
		_draw_title("A NEW BLOODLINE", "Fusion complete • progress saved")
		if not revealed.is_empty():
			var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 280.0)
			draw_circle(Vector2(180, 180), 76, Color(0.55, 0.35, 0.7, 0.12 + pulse * 0.08))
			draw_arc(Vector2(180, 180), 82, 0, TAU, 48, Color("#8f77ac"), 2)
			sprites.draw_wizard(self, revealed.phenotype, Vector2(180, 246), 0, 5)
			_center_text(revealed.phenotype.affinity.capitalize(), Vector2(180, 288), 18, Color("#e8d8f1"))
		return
	if screen == "lineage":
		_draw_title("ANCESTRY ARCHIVE", "%d retired wizards" % academy.archive.size())
		var records := _lineage_records()
		if not records.is_empty():
			var c: Dictionary = records[lineage_index]
			var parents := academy.parents_of(c)
			if parents.size() == 2:
				_draw_card(parents[0], Rect2(16, 54, 160, 132), "RETIRED")
				_draw_card(parents[1], Rect2(184, 54, 160, 132), "RETIRED")
				draw_line(Vector2(96, 186), Vector2(180, 214), Color("#927e9e"), 2)
				draw_line(Vector2(264, 186), Vector2(180, 214), Color("#927e9e"), 2)
			_draw_card(c, Rect2(100, 214, 160, 138), "DESCENDANT")
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


func _center_text(value: String, baseline: Vector2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, baseline - Vector2(width / 2.0, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_title(value: String, subtitle: String) -> void:
	_center_text(value, Vector2(180, 25), 19, Color("#e8d4a7"))
	_center_text(subtitle, Vector2(180, 44), 12, Color("#b5a5bc"))

func _draw_card(c: Dictionary, rect: Rect2, role: String) -> void:
	draw_rect(rect, Color("#2c2635"))
	draw_rect(rect, Color("#62516d"), false, 1)
	var center := rect.get_center().x
	_center_text(role, Vector2(center, rect.position.y + 15), 10, Color("#cdb891"))
	if c.is_empty():
		_center_text("No wizard", Vector2(center, rect.position.y + 77), 13, Color("#aaa0b2"))
		return
	var p: Dictionary = c.phenotype
	var hue: Color = FIRE if p.affinity == "fire" else (ICE if p.affinity == "ice" else STEAM)
	draw_circle(Vector2(center, rect.position.y + 58), 31, Color(hue, 0.09))
	sprites.draw_wizard(self, p, Vector2(center, rect.position.y + 81), 0, 2.0)
	_center_text("%s · Tier %d" % [p.affinity.capitalize(), p.tier], Vector2(center, rect.position.y + 97), 13, hue)
	_center_text("%s%s" % [p.body.capitalize(), " / Locked" if c.locked else ""], Vector2(center, rect.position.y + 112), 11, Color("#d1c5d5"))
	var bar := Rect2(rect.position.x + 13, rect.end.y - 15, rect.size.x - 26, 4)
	draw_rect(bar, Color("#49404e"))
	var fraction := clampf(float(c.xp) / Academy.MATURE_XP, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), hue)
	_center_text("Mature" if int(c.xp) >= Academy.MATURE_XP else "%d / %d XP" % [c.xp, Academy.MATURE_XP], Vector2(center, rect.end.y - 3), 9, Color("#d1c5d5"))
