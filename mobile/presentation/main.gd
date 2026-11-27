extends Node2D
## Portrait prototype. Simulation is owned by RunModel, UI only dispatches commands.
const Academy = preload("res://domain/academy.gd")
const ProfileStore = preload("res://persistence/profile_store.gd")
const RunModel = preload("res://gameplay/run.gd")
const SpriteLibrary = preload("res://presentation/sprite_library.gd")
const ArenaArt = preload("res://presentation/arena_art.gd")
const DungeonArt = preload("res://presentation/dungeon_art.gd")
const Abilities = preload("res://gameplay/ability_catalog.gd")
const Upgrades = preload("res://gameplay/upgrade_catalog.gd")
const EnemyAI = preload("res://gameplay/enemy_behavior.gd")
const Fantasy = preload("res://presentation/fantasy_ui.gd")
const PixelArt = preload("res://presentation/pixel_ui_art.gd")
const UpgradeCard = preload("res://presentation/upgrade_card.gd")
const CastButton = preload("res://presentation/cast_button.gd")
const PLAYFIELD := Rect2(0, 88, 360, 448)
const CAMERA_CENTER := Vector2(180, 312)
const FIRE := Color("#ef8052")
const ICE := Color("#84d7e8")
const STEAM := Color("#c7b7d8")
var academy := Academy.new(int(Time.get_unix_time_from_system()), ProfileStore.new())
var sprites := SpriteLibrary.new()
var arena_art := ArenaArt.new()
var dungeon_art := DungeonArt.new()
var camera_position := Vector2.ZERO
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
var special_button: CastButton
var pause_button: Button
var extract_button: Button
var upgrade_panel: VBoxContainer
var upgrade_heading: Label
var upgrade_buttons: Array[UpgradeCard] = []
var result_panel: VBoxContainer
var academy_panel: VBoxContainer
var title_panel: VBoxContainer
var title_quick: Button
var title_endless: Button
var title_menu_button: Button
var title_note: Label
var displayed_hp := 1.0
var previous_level := 1
var level_flash := 0.0
var player_stride := 0.0
var player_moving := false
var dust: Array[Dictionary] = []
var dust_distance := 0.0
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
	ui.theme = Fantasy.make_theme()
	_build_ui()
	_show_academy()
	_show_title()

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
	title_panel = _box_at(Vector2(42, 386), Vector2(276, 220))
	title_panel.add_theme_constant_override("separation", 12)
	var enter := _button(title_panel, "Enter the Academy", _show_academy)
	enter.custom_minimum_size.y = 46
	Fantasy.primary(enter)
	title_quick = _button(title_panel, "Quick expedition", func() -> void: _start(false))
	title_quick.custom_minimum_size.y = 42
	title_endless = _button(title_panel, "Endless survival", func() -> void: _start(true))
	title_endless.custom_minimum_size.y = 42
	title_note = _label(title_panel, "", 12)
	title_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_menu_button = _button(ui, "Menu", _show_title)
	title_menu_button.position = Vector2(294, 5)
	title_menu_button.size = Vector2(58, 30)
	title_menu_button.add_theme_font_size_override("font_size", 11)
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
	Fantasy.primary(start_finite)
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
	special_button = CastButton.new()
	special_button.focus_mode = Control.FOCUS_NONE
	special_button.pressed.connect(func() -> void: special_requested = true)
	ui.add_child(special_button)
	special_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	special_button.position = Vector2(248, 552)
	special_button.size = Vector2(100, 60)
	pause_button = _button(ui, "II", _toggle_pause)
	pause_button.position = Vector2(305, 10)
	pause_button.size = Vector2(43, 35)
	extract_button = _button(ui, "Extract", _extract)
	extract_button.position = Vector2(253, 51)
	extract_button.size = Vector2(95, 34)
	upgrade_panel = _box_at(Vector2(18, 164), Vector2(324, 320))
	upgrade_panel.add_theme_constant_override("separation", 9)
	upgrade_heading = _label(upgrade_panel, "CHOOSE AN UPGRADE", 20)
	upgrade_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _label(upgrade_panel, "Your genes shape the available paths.", 12)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(3):
		var card := UpgradeCard.new()
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(_upgrade.bind(i))
		upgrade_panel.add_child(card)
		upgrade_buttons.append(card)
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

func _show_title() -> void:
	screen = "title"
	run = null
	paused = false
	_clear_input()
	var unavailable := academy.blocked or academy.roster.is_empty()
	title_quick.disabled = unavailable
	title_endless.disabled = unavailable
	title_note.text = "Open the Academy to review your profile." if unavailable else "%d essence  |  %d wizards" % [academy.essence,academy.roster.size()]
	_sync_visibility()
	queue_redraw()

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
	var kit: Dictionary = Abilities.compile(p)
	info.text = "HP %d  •  Speed %d  •  Power %.1f\n%s / %s\nPassive: %s\n%s" % [int(p.health), int(p.speed), float(p.damage) * float(kit.modifiers.damage), kit.basic.name, kit.special.name, Abilities.passive_names(p), str(p.mutation).replace("_", " ").capitalize() if p.mutation != "none" else "No expressed mutation"]
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
		reveal_info.text = "%s • Tier %d\n%s / %s\n%s\nBoth parents have been archived." % [child.id, child.phenotype.tier, child.phenotype.body.capitalize(), child.phenotype.affinity.capitalize(), Abilities.compile(child.phenotype).special.name]
		screen = "reveal"
		_sync_visibility()
		queue_redraw()
	else:
		_refresh_fusion()

func _cycle_difficulty() -> void:
	difficulty = difficulty % 3 + 1
	_refresh_academy()

func _start(endless: bool) -> void:
	if academy.blocked or academy.roster.is_empty(): return
	active = academy.roster[selected]
	apprentice = academy.roster[partner_index] if partner_index >= 0 else {}
	run_id = academy.allocate_run()
	if run_id < 0:
		_show_academy()
		return
	run = RunModel.new(active.phenotype, endless, difficulty, 1000 + run_id)
	displayed_hp = 1.0
	previous_level = 1
	level_flash = 0.0
	camera_position = run.player
	dungeon_art.reset(run.world_seed)
	arena_art.reset_motion()
	player_stride = 0.0
	player_moving = false
	dust_distance = 0.0
	dust.clear()
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
	var earned: int = run.training_reward()
	var active_now := academy.find_active(str(active.id))
	var apprentice_now := academy.find_active(str(apprentice.get("id", "")))
	var saved := academy.reward(run_id, active_now, apprentice_now, earned, run.outcome == "Victory", int(run.exploration_essence))
	screen = "result"
	_clear_input()
	var summary := result_panel.get_child(0) as Label
	summary.text = "%s\nTime %.0fs  |  Kills %d\nCharacter XP +%d\nShared XP +%d\nCaches %d  |  Shrines %d\nExploration essence +%d" % [run.outcome, run.elapsed, run.kills, earned, floori(earned * 0.25) if not apprentice.is_empty() else 0, run.treasure_count, run.shrine_count, run.exploration_essence] if saved else "Reward not saved.\n" + academy.error + "\nRetry before leaving."
	result_retry.visible = not saved
	result_return.visible = saved
	_sync_visibility()

func _sync_visibility() -> void:
	var in_run := screen == "run"
	title_panel.visible = screen == "title"
	title_menu_button.visible = screen == "academy"
	academy_panel.visible = screen == "academy"
	fusion_panel.visible = screen == "fusion"
	reveal_panel.visible = screen == "reveal"
	lineage_panel.visible = screen == "lineage"
	result_panel.visible = screen == "result"
	special_button.visible = in_run
	pause_button.visible = in_run
	extract_button.visible = in_run and run != null and run.endless
	upgrade_panel.visible = in_run and run != null and run.pending_upgrades > 0
	if upgrade_panel.visible: _refresh_upgrades()
	pause_button.text = ">" if paused else "II"

func _refresh_upgrades() -> void:
	run.ensure_upgrade_offer()
	upgrade_heading.text = "LEVEL UP • %d CHOICE%s" % [run.pending_upgrades, "S" if run.pending_upgrades > 1 else ""]
	for i in range(upgrade_buttons.size()):
		var button := upgrade_buttons[i]
		button.visible = i < run.upgrade_offer.size()
		if not button.visible: continue
		var id: String = run.upgrade_offer[i]
		var d: Dictionary = Upgrades.DEFINITIONS[id]
		var color := Color("#e9dfd0")
		if d.has("affinity"): color = FIRE if d.affinity == "fire" else (ICE if d.affinity == "ice" else STEAM)
		elif d.category != "Universal": color = Color("#c6b5e6")
		button.configure(id,d,int(run.upgrade_ranks.get(id,0)),color)

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
			if run.special_cd <= 0: special_requested = true
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
		if screen in ["reveal","title"]: queue_redraw()
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
		var previous: Vector2 = run.player
		run.step(dt, movement, special_requested or (space and not prev_space))
		_update_motion_art(previous,dt)
		var target: Vector2 = run.player
		camera_position = camera_position.lerp(target, 1.0 - exp(-dt * 12.0))
		camera_position = target + (camera_position - target).limit_length(24.0)
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
		var actual := Fantasy.fraction(float(run.hp),float(run.max_hp))
		displayed_hp = maxf(actual,move_toward(displayed_hp,actual,dt*0.7))
		if int(run.run_level) != previous_level:
			previous_level = int(run.run_level)
			level_flash = 0.9
		level_flash = maxf(0.0,level_flash-dt)
		special_button.configure(str(run.phenotype.affinity),str(run.kit.special.name),float(run.special_cd),float(run.kit.special.cooldown),paused or run.pending_upgrades>0)
		extract_button.disabled = paused or run.elapsed < 30 or run.pending_upgrades > 0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 360, 640), Color("#1b1924"))
	if screen == "title":
		Fantasy.hall(self,float(Time.get_ticks_msec())/1000.0)
		PixelArt.heading(self,"WIZARD",Vector2(180,104),5,Fantasy.GOLD)
		PixelArt.heading(self,"SHOOTER",Vector2(180,144),5,Fantasy.IVORY)
		Fantasy.text_at(self,"FORGE YOUR BLOODLINE",Vector2(180,170),11,Fantasy.MUTED,true)
		if not academy.blocked and not academy.roster.is_empty():
			sprites.draw_wizard(self,academy.roster[selected].phenotype,Vector2(180,324),0,4.0)
		Fantasy.frame(self,Rect2(30,374,300,224))
		Fantasy.text_at(self,"OFFLINE ALPHA",Vector2(180,625),10,Fantasy.MUTED,true)
		return
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
	var camera := camera_position.round()
	var view := Rect2(camera - PLAYFIELD.size / 2.0, PLAYFIELD.size)
	var visible_margin := view.grow(40)
	draw_set_transform(CAMERA_CENTER - camera)
	dungeon_art.draw_world(self, view)
	dungeon_art.draw_sites(self, run.claimed_sites, run.active_encounter, run._guards_remaining(), float(run.elapsed))
	var color: Color = FIRE if run.phenotype.affinity == "fire" else (ICE if run.phenotype.affinity == "ice" else STEAM)
	for cloud in run.clouds:
		if visible_margin.has_point(cloud.pos):
			var cloud_color := FIRE if cloud.affinity == "fire" else STEAM
			draw_circle(cloud.pos, float(cloud.radius), Color(cloud_color, 0.18))
			draw_arc(cloud.pos, float(cloud.radius), 0, TAU, 24, Color(cloud_color, 0.5), 1.0)
	for flash in run.flashes:
		if visible_margin.has_point(flash.pos):
			var flash_color := FIRE if flash.affinity == "fire" else ICE
			draw_arc(flash.pos, float(flash.radius), 0, TAU, 24, Color(flash_color, float(flash.life) / 0.24), 2.0)
	_draw_enemy_hazards(visible_margin)
	for e in run.enemies:
		if visible_margin.has_point(e.pos):
			arena_art.draw_enemy(self, e, float(run.elapsed))
	for shot in run.shots:
		if visible_margin.has_point(shot.pos):
			var projectile: Texture2D = arena_art.projectiles[shot.affinity]
			var heading: Vector2 = shot.vel.normalized()
			var shot_color := FIRE if shot.affinity == "fire" else (ICE if shot.affinity == "ice" else STEAM)
			draw_line(shot.pos - heading * (13.0 if shot.affinity == "ice" else 8.0), shot.pos, Color(shot_color, 0.65), 3.0)
			draw_texture(projectile, shot.pos - Vector2(4, 4))
	if run.special_fx > 0:
		var radius: float = float(run.kit.special.radius)
		var fraction := 1.0 - float(run.special_fx) / 0.35
		var ring := radius * (0.45 + 0.55 * fraction)
		var fade := Color(color, 1.0 - fraction)
		draw_arc(run.player, ring, 0, TAU, 32, fade, 3.0)
		for i in range(12):
			var offset := Vector2.from_angle(i * TAU / 12.0) * ring
			draw_rect(Rect2(run.player + offset - Vector2(2, 2), Vector2(4, 4)), fade)
	_draw_player_art(color)
	if run.ward > 0: draw_arc(run.player, 22, 0, TAU, 24, Color("#c6e6ed"), 2.0)
	if run.webbed: draw_arc(run.player, 18, 0, TAU, 24, Color("#efcfa1"), 2.0)
	_draw_combat_feedback(visible_margin)
	draw_set_transform(Vector2.ZERO)
	# Mask the world outside the playfield, leaving all touch/HUD controls screen-fixed.
	draw_rect(Rect2(0, 0, 360, 88), Color("#1b1924"))
	draw_rect(Rect2(0, 536, 360, 104), Color("#1b1924"))
	draw_rect(PLAYFIELD, Color("#48404e"), false, 2.0)
	if run.player_hit_fx > 0:
		draw_rect(PLAYFIELD.grow(-3), Color(1.0, 0.34, 0.29, float(run.player_hit_fx) * 2.5), false, 3.0)
	_draw_hud()
	Fantasy.text_at(self,str(run.kit.special.name),Vector2(298,631),10,Fantasy.MUTED,true)
	if run.site_notice_time > 0:
		draw_rect(Rect2(8, 94, 344, 23), Color(0.09, 0.07, 0.13, 0.90))
		_center_text(run.site_notice, Vector2(180, 110), 12, Color("#e6d2ac"))
	for e in run.enemies:
		if int(e.kind) == 3 and not view.has_point(e.pos):
			var direction: Vector2 = camera.direction_to(e.pos)
			var arrow := CAMERA_CENTER + direction * 150.0
			draw_colored_polygon(PackedVector2Array([arrow + direction * 9, arrow - direction * 5 + direction.orthogonal() * 6, arrow - direction * 5 - direction.orthogonal() * 6]), Color("#e07468"))
	var origin := touch_origin if touch_id != -1 else Vector2(68, 573)
	var thumb := origin + movement * 30.0
	draw_circle(origin, 34, Color(0.7, 0.7, 0.8, 0.12))
	draw_arc(origin, 34, 0, TAU, 32, Color("#655f78"), 1.0)
	draw_circle(thumb, 12, Color("#89819c"))
	if paused or run.pending_upgrades > 0:
		draw_rect(Rect2(0, 90, 360, 446), Color(0.04, 0.03, 0.06, 0.76))
		if paused: Fantasy.text_at(self,"PAUSED",Vector2(180,305),24,Fantasy.GOLD,true)
		else: Fantasy.frame(self,Rect2(10,151,340,376),Color("#977ab5"))


func _update_motion_art(previous: Vector2,dt: float) -> void:
	arena_art.update_motion(run.enemies)
	var current: Vector2 = run.player
	var distance := previous.distance_to(current)
	player_moving = distance>0.05
	player_stride = fposmod(player_stride+distance,16.0)
	dust_distance += distance
	if dust_distance>=12.0:
		dust_distance = fposmod(dust_distance,12.0)
		if dust.size()>=12: dust.pop_front()
		dust.append({"pos":previous,"life":0.36})
	for i in range(dust.size()-1,-1,-1):
		dust[i].life-=dt
		if dust[i].life<=0: dust.remove_at(i)

func _draw_player_art(color: Color) -> void:
	for puff in dust:
		var alpha := float(puff.life)/0.36
		var point: Vector2 = puff.pos
		draw_rect(Rect2(point+Vector2(-4,1),Vector2(3,2)),Color(0.61,0.54,0.63,alpha*0.45))
		draw_rect(Rect2(point+Vector2(3,3),Vector2(2,2)),Color(0.61,0.54,0.63,alpha*0.3))
	var feet: Vector2 = run.player
	draw_circle(feet+Vector2(0,-1),10,Color(0.05,0.04,0.08,0.35))
	var frame := 1 if player_moving and player_stride>=8.0 else 0
	var bob := -1.0 if frame==1 else 0.0
	if not player_moving: bob = -1.0 if sin(float(run.elapsed)*2.6)>0.65 else 0.0
	sprites.draw_wizard(self,run.phenotype,feet+Vector2(0,bob),frame,1.2)
	if run.special_fx>0:
		var pulse := float(run.special_fx)/0.35
		var spark := feet+Vector2(10,-18)
		draw_circle(spark,5,Color(color,pulse*0.35))
		draw_rect(Rect2(spark-Vector2(1,1),Vector2(3,3)),color.lightened(0.55))

func _draw_hud() -> void:
	var seconds := int(run.elapsed)
	Fantasy.text_at(self,"%02d:%02d" % [seconds/60,seconds%60],Vector2(12,18),15,Fantasy.GOLD)
	Fantasy.text_at(self,"KILLS %d" % run.kills,Vector2(82,18),11,Fantasy.MUTED)
	Fantasy.text_at(self,"LV %d" % run.run_level,Vector2(193,18),13,Fantasy.GOLD)
	var low := Fantasy.fraction(float(run.hp),float(run.max_hp)) < 0.25
	var warning := 0.3+0.2*sin(float(run.elapsed)*5.0) if low else 0.0
	Fantasy.bar(self,Rect2(12,25,230,22),float(run.hp),float(run.max_hp),Fantasy.HP,displayed_hp,maxf(warning,float(run.player_hit_fx)*3.0))
	Fantasy.text_at(self,"HP   %d / %d" % [ceili(run.hp),roundi(run.max_hp)],Vector2(127,40),12,Fantasy.IVORY,true)
	Fantasy.bar(self,Rect2(12,52,230,18),float(run.xp),float(run.next_xp),Fantasy.XP,-1.0,level_flash)
	Fantasy.text_at(self,"XP   %d / %d" % [run.xp,run.next_xp],Vector2(127,65),11,Fantasy.IVORY,true)
	var state := "BLESSED %.0fs" % run.blessing if run.blessing > 0 else ("BOSS ACTIVE" if run.boss_spawned else ("ENDLESS" if run.endless else "DUNGEON"))
	Fantasy.text_at(self,state,Vector2(12,83),10,Fantasy.MUTED)
	if not run.endless:
		Fantasy.text_at(self,"DIFFICULTY "+["I","II","III"][difficulty-1],Vector2(300,65),10,Fantasy.MUTED,true)

func _draw_combat_feedback(view: Rect2) -> void:
	var font := ThemeDB.fallback_font
	for fx in run.hit_fx:
		if not view.has_point(fx.pos): continue
		var p: Vector2 = fx.pos
		var color := FIRE if fx.affinity == "fire" else (ICE if fx.affinity == "ice" else STEAM)
		if fx.kind == "hurt": color = Color("#ff9c87")
		var progress := 1.0 - float(fx.life) / 0.55
		var alpha := 1.0 - progress
		if fx.kind == "defeat":
			for i in range(5):
				var offset := Vector2.from_angle(i * TAU / 5.0) * (5.0 + progress * 17.0)
				draw_rect(Rect2(p + offset - Vector2.ONE, Vector2(3,3)), Color(color, alpha))
			continue
		if progress < 0.40:
			for i in range(4):
				var offset := Vector2.from_angle(i * TAU / 4.0 + 0.7) * (5.0 + progress * 15.0)
				draw_rect(Rect2(p + offset, Vector2(2,2)), Color(color, alpha))
		var label_text := "%s%d" % ["-" if fx.kind == "hurt" else "", maxi(1, roundi(float(fx.amount)))]
		var point := p + Vector2(-6, -13 - progress * 14)
		draw_string(font, point + Vector2(1,1), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.06,0.04,0.08,alpha))
		draw_string(font, point, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(color,alpha))

func _draw_enemy_hazards(view: Rect2) -> void:
	var danger := Color("#f3a35f")
	for web in run.webs:
		if not view.has_point(web.pos): continue
		var p: Vector2 = web.pos
		var radius: float = web.radius
		draw_circle(p, radius, Color("#b5a18b", 0.15))
		for ring in [0.4, 0.75, 1.0]:
			draw_arc(p, radius * float(ring), 0, TAU, 12, Color("#d5c5ae", 0.75), 1.0)
		for i in range(8):
			draw_line(p, p + Vector2.from_angle(i * TAU / 8.0) * radius, Color("#d5c5ae", 0.7), 1.0)
	for e in run.enemies:
		if not view.has_point(e.pos): continue
		var p: Vector2 = e.pos
		var target: Vector2 = e.attack_target
		var progress := 1.0 - float(e.attack_time) / maxf(0.01, float(e.attack_total))
		match str(e.attack):
			"web", "breath":
				var radius := EnemyAI.WEB_RADIUS if e.attack == "web" else EnemyAI.BREATH_RADIUS
				draw_circle(target, radius, Color(danger, 0.16))
				draw_arc(target, radius, 0, TAU, 32, danger, 2.0)
				draw_arc(target, radius - 4, 0, TAU * progress, 32, Color("#fff0b5"), 3.0)
			"charge_windup":
				var heading: Vector2 = e.attack_dir
				var length := (EnemyAI.BOSS_CHARGE_SPEED if int(e.kind) == 3 else EnemyAI.CHARGE_SPEED) * EnemyAI.CHARGE_TIME
				var normal := heading.orthogonal() * (float(e.radius) + 7.0)
				var end := p + heading * length
				draw_colored_polygon(PackedVector2Array([p+normal,end+normal,end-normal,p-normal]), Color(danger, 0.20))
				draw_line(p+normal,end+normal,danger,2.0)
				draw_line(p-normal,end-normal,danger,2.0)
				draw_line(p,p+heading*length*progress,Color("#fff0b5"),2.0)
			"bolt":
				draw_line(p, target, Color(danger, 0.6), 1.0)
				draw_arc(p, 15, 0, TAU * progress, 24, danger, 2.0)
	for bolt in run.enemy_bolts:
		if not view.has_point(bolt.pos): continue
		var p: Vector2 = bolt.pos
		var direction: Vector2 = bolt.vel.normalized()
		draw_line(p-direction*11,p,Color("#d87549"),4.0)
		draw_circle(p,5,Color("#f3a35f"))
		draw_circle(p,2,Color("#fff0b5"))
	for flash in run.danger_flashes:
		if view.has_point(flash.pos):
			draw_circle(flash.pos,float(flash.radius),Color(danger,float(flash.life)*1.8))
			draw_arc(flash.pos,float(flash.radius),0,TAU,32,danger,2.0)

func _center_text(value: String, baseline: Vector2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, baseline - Vector2(width / 2.0, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_title(value: String, subtitle: String) -> void:
	PixelArt.heading(self,value,Vector2(180,25),2,Fantasy.GOLD)
	_center_text(subtitle, Vector2(180, 44), 12, Color("#b5a5bc"))

func _draw_card(c: Dictionary, rect: Rect2, role: String) -> void:
	Fantasy.frame(self,rect,Color("#796384"))
	var center := rect.get_center().x
	_center_text(role, Vector2(center, rect.position.y + 15), 10, Color("#cdb891"))
	if c.is_empty():
		_center_text("No wizard", Vector2(center, rect.position.y + 77), 13, Color("#aaa0b2"))
		return
	var p: Dictionary = c.phenotype
	var hue: Color = FIRE if p.affinity == "fire" else (ICE if p.affinity == "ice" else STEAM)
	draw_circle(Vector2(center, rect.position.y + 58), 31, Color(hue, 0.09))
	draw_texture_rect(PixelArt.icon(str(p.affinity),hue),Rect2(rect.position+Vector2(8,24),Vector2(18,18)),false)
	sprites.draw_wizard(self, p, Vector2(center, rect.position.y + 81), 0, 2.0)
	_center_text("%s · Tier %d" % [p.affinity.capitalize(), p.tier], Vector2(center, rect.position.y + 97), 13, hue)
	_center_text("%s%s" % [p.body.capitalize(), " / Locked" if c.locked else ""], Vector2(center, rect.position.y + 112), 11, Color("#d1c5d5"))
	var bar := Rect2(rect.position.x + 13, rect.end.y - 15, rect.size.x - 26, 4)
	draw_rect(bar.grow(1),Fantasy.INK)
	var fraction := Fantasy.fraction(float(c.xp),Academy.MATURE_XP)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), hue)
	_center_text("Mature" if int(c.xp) >= Academy.MATURE_XP else "%d / %d XP" % [c.xp, Academy.MATURE_XP], Vector2(center, rect.end.y - 3), 9, Color("#d1c5d5"))
