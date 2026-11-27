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
const GameAudio = preload("res://presentation/game_audio.gd")
const Collection = preload("res://presentation/collection_art.gd")
const ElementFX = preload("res://presentation/element_fx.gd")
const Rig = preload("res://presentation/directional_rig.gd")
const Results = preload("res://presentation/result_art.gd")
const VisualSettings = preload("res://presentation/visual_settings.gd")
const Profiler = preload("res://presentation/performance_monitor.gd")
const Onboarding = preload("res://presentation/onboarding.gd")
const PLAYFIELD := Rect2(0, 88, 360, 448)
const CAMERA_CENTER := Vector2(180, 312)
const FIRE := Color("#ef8052")
const ICE := Color("#84d7e8")
const STEAM := Color("#c7b7d8")
var academy := Academy.new(int(Time.get_unix_time_from_system()), ProfileStore.new())
var sprites := SpriteLibrary.new()
var arena_art := ArenaArt.new()
var dungeon_art := DungeonArt.new()
var elemental_fx := ElementFX.new()
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
var audio := GameAudio.new()
var sound_toggle: Button
var music_toggle: Button
var settings := VisualSettings.new()
var profiler := Profiler.new()
var settings_button: Button
var settings_panel: VBoxContainer
var settings_origin := "title"
var settings_notice: Label
var settings_options: Dictionary = {}
var monitor_text := ""
var monitor_timer := 0.0
var guide := Onboarding.new()
var guide_button: Button
var guide_panel: VBoxContainer
var guide_content: Label
var guide_toggle: Button
var guide_start: Button
var guide_notice: Label
var guide_origin := "title"
var reveal_skip: Button
var reveal_time := 0.0
const REVEAL_DURATION := 1.65
var ritual_parents: Array[Dictionary] = []
var displayed_hp := 1.0
var previous_level := 1
var level_flash := 0.0
var player_stride := 0.0
var walk_facing := "south"
var cast_facing := "south"
var cast_pose_remaining := 0.0
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
var roster_panel: Control
var roster_buttons: Array[Button] = []
var roster_prev: Button
var roster_next: Button
var roster_page := 0
var detail_panel: VBoxContainer
var detail_info: Label
var detail_active: Button
var detail_apprentice: Button
var detail_lock: Button
var detail_index := 0
var detail_origin := "academy"
var clear_apprentice: Button
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
var result_replay: Button
var result_error: Label
var result_before: Dictionary = {}
var result_reward: Dictionary = {}

func _ready() -> void:
	get_viewport().gui_embed_subwindows = true
	add_child(audio)
	settings.load_settings()
	settings.apply()
	guide.load_settings(not academy.settled_runs.is_empty() or not academy.archive.is_empty())
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	ui.theme = Fantasy.make_theme()
	_build_ui()
	if academy.roster.size()>1: partner_index=1
	_show_academy()
	_show_title()

func _button(parent: Node, title: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(0, 32)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: audio.play_sound("click",0,-22.0))
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
	settings_button=_button(ui,"Settings",_open_settings)
	settings_button.size=Vector2(130,34)
	_build_settings()
	_build_guide()
	title_menu_button = _button(ui, "Menu", _show_title)
	title_menu_button.position = Vector2(294, 5)
	title_menu_button.size = Vector2(58, 30)
	title_menu_button.add_theme_font_size_override("font_size", 11)
	academy_panel = _box_at(Vector2(16, 298), Vector2(328, 328))
	academy_panel.add_theme_constant_override("separation",7)
	var collection := _pair(academy_panel)
	var browse := _button(collection,"Wizard collection",_show_roster)
	browse.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var details := _button(collection,"Inspect active",func() -> void: _show_detail(selected,"academy"))
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var training := _pair(academy_panel)
	clear_apprentice = _button(training,"Clear apprentice",_clear_apprentice)
	clear_apprentice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	lock_button = _button(training,"Lock wizard",_lock_wizard)
	lock_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var actions := _pair(academy_panel)
	summon_button = _button(actions,"Summon • 10",_summon)
	fuse_button = _button(actions,"Fusion chamber",_ask_fuse)
	summon_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	fuse_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var options := _pair(academy_panel)
	difficulty_button = _button(options,"Difficulty: I",_cycle_difficulty)
	difficulty_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var archive_button := _button(options,"Ancestry archive",_show_archive)
	archive_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	start_finite = _button(academy_panel,"Enter dungeon",func() -> void: _start(false))
	start_finite.custom_minimum_size.y=42
	Fantasy.primary(start_finite)
	start_endless = _button(academy_panel,"Endless survival",func() -> void: _start(true))
	start_endless.custom_minimum_size.y=36
	info = _label(academy_panel,"",12)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status_label = _label(academy_panel,"",11)
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_build_collection()
	fusion_panel = _box_at(Vector2(24, 326), Vector2(312, 270))
	fusion_hint = _label(fusion_panel, "", 15)
	fusion_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fusion_confirm = _button(fusion_panel, "Confirm irreversible fusion", _fuse)
	_button(fusion_panel, "Return without fusing", _show_academy)
	reveal_panel = _box_at(Vector2(24, 330), Vector2(312, 220))
	reveal_info = _label(reveal_panel, "", 15)
	reveal_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(reveal_panel, "Meet your new wizard", _show_academy)
	reveal_skip = _button(ui,"Skip ritual",_complete_reveal)
	reveal_skip.position=Vector2(110,434)
	reveal_skip.size=Vector2(140,36)
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
	result_panel = _box_at(Vector2(16, 548), Vector2(328, 84))
	result_panel.add_theme_constant_override("separation",6)
	result_error = _label(result_panel,"",11)
	result_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result_error.add_theme_color_override("font_color",Color("#e08b87"))
	result_return = _button(result_panel, "Return to Academy", _show_academy)
	result_return.custom_minimum_size.y=38
	Fantasy.primary(result_return)
	result_replay = _button(result_panel,"Run again",_replay_result)
	result_retry = _button(result_panel, "Retry saving rewards", _finish)
	Fantasy.primary(result_retry)
	archive_dialog = AcceptDialog.new()
	archive_dialog.title = "Ancestry archive"
	archive_text = RichTextLabel.new()
	archive_text.custom_minimum_size = Vector2(290, 290)
	archive_text.scroll_active = true
	archive_dialog.add_child(archive_text)
	add_child(archive_dialog)

func _build_collection() -> void:
	roster_panel=Control.new()
	roster_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(roster_panel)
	for i in range(Collection.PAGE_SIZE):
		var button := _button(roster_panel,"",_open_roster_slot.bind(i))
		var r := Collection.card_rect(i)
		button.position=r.position
		button.size=r.size
		# Card art is drawn beneath native buttons; transparent normal state.
		var empty := StyleBoxEmpty.new()
		button.add_theme_stylebox_override("normal",empty)
		button.add_theme_stylebox_override("hover",Fantasy.style(Color(0.85,0.72,0.95,0.08),Fantasy.GOLD))
		button.add_theme_stylebox_override("pressed",Fantasy.style(Color(0.85,0.72,0.95,0.14),Fantasy.GOLD))
		roster_buttons.append(button)
	roster_prev=_button(roster_panel,"Previous",func() -> void: _change_page(-1))
	roster_next=_button(roster_panel,"Next",func() -> void: _change_page(1))
	roster_prev.position=Vector2(12,522)
	roster_prev.size=Vector2(108,37)
	roster_next.position=Vector2(240,522)
	roster_next.size=Vector2(108,37)
	var back := _button(roster_panel,"Return to Academy",_show_academy)
	back.position=Vector2(12,578)
	back.size=Vector2(336,42)
	detail_panel=_box_at(Vector2(22,275),Vector2(316,340))
	detail_panel.add_theme_constant_override("separation",8)
	detail_info=_label(detail_panel,"",13)
	detail_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_info.custom_minimum_size.y=100
	detail_active=_button(detail_panel,"Set active wizard",_assign_active)
	Fantasy.primary(detail_active)
	detail_apprentice=_button(detail_panel,"Assign apprentice",_assign_apprentice)
	detail_lock=_button(detail_panel,"Lock wizard",_lock_detail)
	_button(detail_panel,"Back",_back_detail)

func _show_roster() -> void:
	if academy.blocked or academy.roster.is_empty(): return
	screen="roster"
	roster_page=clampi(roster_page,0,Collection.pages(academy.roster.size())-1)
	_refresh_roster()
	_sync_visibility()
	queue_redraw()

func _refresh_roster() -> void:
	for i in range(roster_buttons.size()):
		var index := roster_page*Collection.PAGE_SIZE+i
		roster_buttons[i].visible=index<academy.roster.size()
		roster_buttons[i].tooltip_text=Collection.title(academy.roster[index]) if index<academy.roster.size() else ""
	roster_prev.disabled=roster_page==0
	roster_next.disabled=roster_page>=Collection.pages(academy.roster.size())-1

func _change_page(step: int) -> void:
	roster_page=clampi(roster_page+step,0,Collection.pages(academy.roster.size())-1)
	_refresh_roster()
	queue_redraw()

func _open_roster_slot(slot: int) -> void:
	_show_detail(roster_page*Collection.PAGE_SIZE+slot,"roster")

func _show_detail(index: int,origin: String) -> void:
	if academy.blocked or index<0 or index>=academy.roster.size(): return
	detail_index=index
	detail_origin=origin
	screen="detail"
	_refresh_detail()
	_sync_visibility()
	queue_redraw()

func _refresh_detail() -> void:
	var c: Dictionary=academy.roster[detail_index]
	detail_info.text=Collection.details(c)
	if not academy.error.is_empty(): detail_info.text+="\n"+academy.error
	detail_active.disabled=detail_index==selected
	detail_active.text="Active wizard" if detail_index==selected else "Set active wizard"
	detail_apprentice.disabled=detail_index==selected
	detail_apprentice.text="Remove apprentice" if detail_index==partner_index else "Assign apprentice"
	detail_lock.text="Unlock wizard" if c.locked else "Lock wizard"

func _assign_active() -> void:
	if screen!="detail": return
	selected=detail_index
	if partner_index==selected: partner_index=-1
	_refresh_detail()
	queue_redraw()

func _assign_apprentice() -> void:
	if screen!="detail" or detail_index==selected: return
	partner_index=-1 if partner_index==detail_index else detail_index
	_refresh_detail()
	queue_redraw()

func _lock_detail() -> void:
	if screen!="detail": return
	academy.toggle_lock(str(academy.roster[detail_index].id))
	_refresh_detail()
	queue_redraw()

func _back_detail() -> void:
	if detail_origin=="roster": _show_roster()
	else: _show_academy()

func _clear_apprentice() -> void:
	partner_index=-1
	_refresh_academy()
	queue_redraw()

func _lock_wizard() -> void:
	if academy.blocked: return
	var c: Dictionary = academy.roster[selected]
	academy.toggle_lock(c.id)
	_refresh_academy()
	queue_redraw()

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
	title_quick.text="First expedition" if guide.enabled and academy.settled_runs.is_empty() else "Quick expedition"
	title_note.text = "Open the Academy to review your profile." if unavailable else "%d essence  |  %d wizards" % [academy.essence,academy.roster.size()]
	if not unavailable and guide.enabled and academy.settled_runs.is_empty(): title_note.text="New? Open Guide, or learn as you play."
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
	var p2: Dictionary = academy.roster[partner_index] if partner_index>=0 else {}
	info.text="Fusion ready" if academy.eligible(c,p2) else "Fusion requires two mature, unlocked Tier I wizards."
	if guide.enabled:
		var hint := Onboarding.fusion_tip(academy,c,p2)
		if not hint.is_empty(): info.text=hint
	difficulty_button.text="Difficulty: %s" % ["I","II","III"][difficulty-1]
	lock_button.text="Unlock wizard" if c.locked else "Lock wizard"
	clear_apprentice.disabled=partner_index<0
	summon_button.disabled=academy.essence<10
	fuse_button.disabled=p2.is_empty()
	status_label.text=academy.error if not academy.error.is_empty() else academy.notice

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
	if screen!="fusion" or partner_index < 0: return
	ritual_parents=[academy.roster[selected].duplicate(true),academy.roster[partner_index].duplicate(true)]
	var child: Dictionary = academy.fuse(academy.roster[selected], academy.roster[partner_index])
	if not child.is_empty():
		selected = academy.roster.size() - 1
		partner_index = -1
		revealed = child
		reveal_time=0.0
		audio.play_sound("ritual",5,-10.0)
		reveal_info.text = "%s • Tier %d\n%s / %s\n%s\nBoth parents have been archived." % [child.id, child.phenotype.tier, child.phenotype.body.capitalize(), child.phenotype.affinity.capitalize(), Abilities.compile(child.phenotype).special.name]
		screen = "reveal"
		_sync_visibility()
		queue_redraw()
	else:
		_refresh_fusion()

func _complete_reveal() -> void:
	if screen!="reveal" or reveal_time>=REVEAL_DURATION: return
	reveal_time=REVEAL_DURATION
	audio.play_sound("reveal",5,-10.0)
	_sync_visibility()
	queue_redraw()

func _build_guide() -> void:
	guide_button=_button(ui,"Guide",_open_guide)
	guide_button.position=Vector2(8,5)
	guide_button.size=Vector2(62,30)
	guide_button.add_theme_font_size_override("font_size",11)
	guide_panel=_box_at(Vector2(24,74),Vector2(312,540))
	guide_panel.add_theme_constant_override("separation",10)
	guide_content=_label(guide_panel,"",13)
	guide_content.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	guide_start=_button(guide_panel,"Start guided expedition",_start_guided)
	Fantasy.primary(guide_start)
	guide_toggle=_button(guide_panel,"Hide tips",_toggle_guide)
	_button(guide_panel,"Repeat combat lessons",_reset_guide)
	guide_notice=_label(guide_panel,"",11)
	guide_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(guide_panel,"Back",_close_guide)

func _open_guide() -> void:
	if screen not in ["title","academy"]: return
	guide_origin=screen
	screen="guide"
	guide_notice.text=""
	_refresh_guide()
	_sync_visibility()
	queue_redraw()

func _close_guide() -> void:
	if screen!="guide": return
	if guide_origin=="academy": _show_academy()
	else: _show_title()

func _refresh_guide() -> void:
	var lines := PackedStringArray()
	lines.append("COMBAT LESSONS  %d / 4" % guide.lesson_count())
	lines.append(("✓ " if guide.knows(Onboarding.MOVE) else "□ ")+"Move: drag the lower-left pad (WASD or arrows).")
	lines.append(("✓ " if guide.knows(Onboarding.BASIC) else "□ ")+"Basic magic attacks automatically.")
	lines.append(("✓ " if guide.knows(Onboarding.SPECIAL) else "□ ")+"Tap CAST (Space) to use your special.")
	lines.append(("✓ " if guide.knows(Onboarding.UPGRADE) else "□ ")+"Earn XP and select a run upgrade.")
	lines.append("Avoid orange attack zones and charge lines. Defeat the dragon, or extract from endless mode after 30 seconds.")
	lines.append("")
	lines.append("BLOODLINE")
	lines.append(("✓ " if not academy.settled_runs.is_empty() else "□ ")+"Finish a run to save training XP and essence, even on defeat.")
	lines.append("Summon costs 10 essence; victory awards a founder. Assign an apprentice for 25% shared XP.")
	lines.append(("✓ " if not academy.archive.is_empty() else "□ ")+"Fuse two unlocked Tier I wizards with 40 XP each. Parents retire permanently; their Tier II child inherits traits.")
	guide_content.text="\n".join(lines)
	guide_toggle.text="Hide combat and training tips" if guide.enabled else "Show combat and training tips"
	guide_start.disabled=academy.blocked or academy.roster.is_empty()

func _toggle_guide() -> void:
	guide.enabled=not guide.enabled
	var error := guide.save_settings()
	guide_notice.text="Preference saved." if error==OK else "Could not save preference."
	_refresh_guide()

func _reset_guide() -> void:
	guide.reset_lessons()
	guide_notice.text="Combat lessons reset. Your wizards are unchanged."
	_refresh_guide()

func _start_guided() -> void:
	if screen!="guide" or academy.blocked: return
	guide.enabled=true
	guide.save_settings()
	_start(false)

func _build_settings() -> void:
	settings_panel=_box_at(Vector2(24,92),Vector2(312,500))
	settings_panel.add_theme_constant_override("separation",8)
	sound_toggle=_button(settings_panel,"SFX ON",_toggle_sfx)
	music_toggle=_button(settings_panel,"Music ON",_toggle_music)
	for key in ["fps","reduced_motion","simple_effects","damage_numbers","monitor"]:
		settings_options[key]=_button(settings_panel,"",_toggle_visual.bind(key))
	_label(settings_panel,"Simplified effects retain spell boundaries and enemy warnings.",11).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(settings_panel,"Export performance report",_export_performance)
	settings_notice=_label(settings_panel,"",11)
	settings_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var back := _button(settings_panel,"Back",_close_settings)
	Fantasy.primary(back)

func _open_settings() -> void:
	if screen!="title" and not (screen=="run" and paused): return
	settings_origin=screen
	screen="settings"
	_clear_input()
	settings_notice.text=""
	_refresh_settings()
	_sync_visibility()
	queue_redraw()

func _close_settings() -> void:
	if screen!="settings": return
	screen=settings_origin
	_clear_input()
	_sync_visibility()
	queue_redraw()

func _refresh_settings() -> void:
	settings_options.fps.text="Frame cap: %d FPS" % settings.fps
	settings_options.reduced_motion.text="Reduced motion: "+("ON" if settings.reduced_motion else "OFF")
	settings_options.simple_effects.text="Spell effects: "+("SIMPLE" if settings.simple_effects else "FULL")
	settings_options.damage_numbers.text="Damage numbers: "+("ON" if settings.damage_numbers else "OFF")
	settings_options.monitor.text="Performance overlay: "+("ON" if settings.monitor else "OFF")

func _toggle_visual(key: String) -> void:
	match key:
		"fps": settings.fps=30 if settings.fps==60 else 60
		"reduced_motion": settings.reduced_motion=not settings.reduced_motion
		"simple_effects": settings.simple_effects=not settings.simple_effects
		"damage_numbers": settings.damage_numbers=not settings.damage_numbers
		"monitor": settings.monitor=not settings.monitor
	settings.apply()
	var error := settings.save_settings()
	settings_notice.text="Preferences saved." if error==OK else "Preferences active; could not save."
	_refresh_settings()
	queue_redraw()

func _export_performance() -> void:
	if profiler.total_frames==0:
		settings_notice.text="Play an expedition before exporting timings."
		return
	var error := profiler.export_report({"fps":settings.fps,"reduced_motion":settings.reduced_motion,"simple_effects":settings.simple_effects,"damage_numbers":settings.damage_numbers})
	settings_notice.text="Saved: "+ProjectSettings.globalize_path(Profiler.REPORT) if error==OK else "Could not write performance report."

func _process(dt: float) -> void:
	if screen=="run" and not paused and run.pending_upgrades==0:
		profiler.record_frame(dt)
		if settings.monitor:
			monitor_timer+=dt
			if monitor_timer>=0.5:
				monitor_timer=0.0
				monitor_text=profiler.overlay(run,dungeon_art.cache.size(),sprites.pose_cache.size())

func _toggle_sfx() -> void:
	audio.toggle_effects()
	_sync_visibility()

func _toggle_music() -> void:
	audio.toggle_music()
	_sync_visibility()

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
	result_before.clear()
	result_reward.clear()
	profiler.reset()
	guide.begin_run()
	monitor_text=""
	monitor_timer=0.0
	displayed_hp = 1.0
	previous_level = 1
	level_flash = 0.0
	camera_position = run.player
	dungeon_art.reset(run.world_seed)
	arena_art.reset_motion()
	elemental_fx.reset()
	audio.reset_run()
	player_stride = 0.0
	walk_facing = "south"
	cast_facing = "south"
	cast_pose_remaining = 0.0
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
		var previous: int=run.pending_upgrades
		run.upgrade(choice)
		if guide.enabled and run.pending_upgrades<previous: guide.mark(Onboarding.UPGRADE)
		_clear_input()
		_sync_visibility()

func _replay_result() -> void:
	if screen!="result" or result_reward.is_empty(): return
	_start(bool(run.endless))

func _finish() -> void:
	if run==null or run.outcome=="" or not result_reward.is_empty(): return
	var earned: int = run.training_reward()
	var active_now := academy.find_active(str(active.id))
	var apprentice_now := academy.find_active(str(apprentice.get("id", "")))
	if result_before.is_empty():
		result_before=Results.before_reward(academy,active_now if not active_now.is_empty() else active,apprentice_now)
	var saved := academy.reward(run_id, active_now, apprentice_now, earned, run.outcome == "Victory", int(run.exploration_essence))
	if saved: result_reward=Results.committed(result_before,academy)
	if screen!="result": audio.play_sound("victory" if run.outcome=="Victory" else ("fallen" if run.outcome=="Defeated" else "reward"),5,-10.0)
	screen="result"
	_clear_input()
	result_error.visible=not saved
	result_error.text=academy.error if not saved else ""
	result_retry.visible=not saved
	result_return.visible=saved
	result_replay.visible=saved
	_sync_visibility()
	queue_redraw()

func _sync_visibility() -> void:
	var in_run := screen == "run"
	title_panel.visible = screen == "title"
	title_menu_button.visible = screen == "academy"
	academy_panel.visible = screen == "academy"
	roster_panel.visible=screen=="roster"
	detail_panel.visible=screen=="detail"
	fusion_panel.visible = screen == "fusion"
	reveal_panel.visible = screen == "reveal" and reveal_time>=REVEAL_DURATION
	reveal_skip.visible = screen=="reveal" and reveal_time<REVEAL_DURATION
	lineage_panel.visible = screen == "lineage"
	result_panel.visible = screen == "result"
	special_button.visible = in_run
	pause_button.visible = in_run
	extract_button.visible = in_run and run != null and run.endless
	upgrade_panel.visible = in_run and run != null and run.pending_upgrades > 0
	if upgrade_panel.visible: _refresh_upgrades()
	pause_button.text = ">" if paused else "II"
	guide_panel.visible=screen=="guide"
	guide_button.visible=screen in ["title","academy"]
	settings_panel.visible=screen=="settings"
	settings_button.visible=screen=="title" or (in_run and paused)
	settings_button.position=Vector2(115,604) if screen=="title" else Vector2(115,340)
	sound_toggle.text="SFX ON" if audio.effects_enabled else "SFX OFF"
	music_toggle.text="Music ON" if audio.music_enabled else "Music OFF"
	var dungeon_audio := in_run or (screen=="settings" and settings_origin=="run")
	audio.set_track("dungeon" if dungeon_audio else "academy")
	audio.duck(dungeon_audio and (paused or run.pending_upgrades>0))

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
		if screen=="reveal" and reveal_time<REVEAL_DURATION:
			if settings.reduced_motion or reveal_time+dt>=REVEAL_DURATION: _complete_reveal()
			else: reveal_time+=dt
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
		var audio_before := GameAudio.snapshot(run)
		var sim_start := Time.get_ticks_usec()
		run.step(dt, movement, special_requested or (space and not prev_space))
		guide.observe_step(run,previous,int(audio_before.basic),int(audio_before.special))
		profiler.record_step(Time.get_ticks_usec()-sim_start,run,dungeon_art.cache.size(),sprites.pose_cache.size())
		if run.special_casts>audio_before.special: elemental_fx.capture(run)
		audio.after_step(audio_before,run)
		_update_motion_art(previous,dt)
		if run.basic_casts>audio_before.basic:
			cast_facing=Rig.facing(run.last_basic_direction,walk_facing)
			cast_pose_remaining=0.16
		elif run.special_casts>audio_before.special:
			cast_facing=walk_facing
			cast_pose_remaining=0.22
		var target: Vector2 = run.player
		camera_position = target if settings.reduced_motion else camera_position.lerp(target, 1.0 - exp(-dt * 12.0))
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
	if screen=="guide":
		_draw_title("WIZARD GUIDE","Learn by playing")
		Fantasy.frame(self,Rect2(12,62,336,566))
		return
	if screen=="settings":
		_draw_title("SETTINGS","Audio, visuals and diagnostics")
		Fantasy.frame(self,Rect2(12,74,336,544))
		return
	if screen == "title":
		Fantasy.hall(self,0.0 if settings.reduced_motion else float(Time.get_ticks_msec())/1000.0)
		PixelArt.heading(self,"WIZARD",Vector2(180,104),5,Fantasy.GOLD)
		PixelArt.heading(self,"SHOOTER",Vector2(180,144),5,Fantasy.IVORY)
		Fantasy.text_at(self,"FORGE YOUR BLOODLINE",Vector2(180,170),11,Fantasy.MUTED,true)
		if not academy.blocked and not academy.roster.is_empty():
			sprites.draw_wizard(self,academy.roster[selected].phenotype,Vector2(180,324),0,4.0)
		Fantasy.frame(self,Rect2(30,374,300,224))

		return
	if screen == "academy":
		_draw_title("THE ACADEMY", "%d essence   •   %d active   •   %d retired" % [academy.essence, academy.roster.size(), academy.archive.size()])
		if academy.blocked or academy.roster.is_empty(): return
		Collection.hero(self,sprites,academy.roster[selected])
		Collection.apprentice(self,sprites,academy.roster[partner_index] if partner_index>=0 else {})
		return
	if screen=="roster":
		_draw_title("WIZARD COLLECTION","%d wizards • choose a portrait to inspect" % academy.roster.size())
		for i in range(Collection.PAGE_SIZE):
			var index := roster_page*Collection.PAGE_SIZE+i
			if index>=academy.roster.size(): break
			Collection.tile(self,sprites,academy.roster[index],Collection.card_rect(i),Collection.role(index,selected,partner_index))
		Fantasy.text_at(self,"%d / %d" % [roster_page+1,Collection.pages(academy.roster.size())],Vector2(180,545),13,Fantasy.GOLD,true)
		return
	if screen=="detail":
		var c: Dictionary=academy.roster[detail_index]
		_draw_title("WIZARD GRIMOIRE",str(c.id))
		Collection.hero(self,sprites,c,"WIZARD RECORD")
		Fantasy.frame(self,Rect2(12,224,336,42))
		Fantasy.text_at(self,Collection.role(detail_index,selected,partner_index),Vector2(180,250),13,Fantasy.GOLD,true)
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
		_draw_reveal()
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
	if screen=="result" and run!=null and not result_before.is_empty():
		Results.draw(self,sprites,run,result_before,result_reward)
		return
	if screen != "run" or run == null: return
	var camera := camera_position.round()
	var view := Rect2(camera - PLAYFIELD.size / 2.0, PLAYFIELD.size)
	var visible_margin := view.grow(40)
	draw_set_transform(CAMERA_CENTER - camera)
	dungeon_art.draw_world(self, view)
	dungeon_art.draw_sites(self, run.claimed_sites, run.active_encounter, run._guards_remaining(), float(run.elapsed))
	var color: Color = FIRE if run.phenotype.affinity == "fire" else (ICE if run.phenotype.affinity == "ice" else STEAM)
	# Ground effects below creatures and hostile telegraphs preserve combat readability.
	for cloud in run.clouds:
		if ElementFX.intersects(view,cloud.pos,float(cloud.radius)):
			if settings.simple_effects:
				draw_arc(cloud.pos,float(cloud.radius),0,TAU,32,Color(ElementFX.hue(str(cloud.affinity)),0.65),1)
			else: ElementFX.cloud(self,cloud,float(run.elapsed))
	for flash in run.flashes:
		if ElementFX.intersects(view,flash.pos,float(flash.radius)):
			if settings.simple_effects:
				draw_arc(flash.pos,float(flash.radius),0,TAU,32,Color(ElementFX.hue(str(flash.affinity)),0.7),1)
			else: ElementFX.burst(self,flash.pos,float(flash.radius),str(flash.affinity),1.0-clampf(float(flash.life)/0.24,0,1),false)
	if settings.simple_effects and not elemental_fx.cast.is_empty() and float(run.elapsed)-float(elemental_fx.cast.at)<ElementFX.CAST_LIFE:
		draw_arc(elemental_fx.cast.pos,float(elemental_fx.cast.radius),0,TAU,32,ElementFX.hue(str(elemental_fx.cast.affinity)),1)
	elif not settings.simple_effects: elemental_fx.draw_cast(self,view,float(run.elapsed))
	_draw_enemy_hazards(visible_margin)
	for e in run.enemies:
		if visible_margin.has_point(e.pos):
			arena_art.draw_enemy(self,e,float(run.elapsed))
			ElementFX.enemy_status(self,e,float(run.elapsed))
	for shot in run.shots:
		if visible_margin.has_point(shot.pos):
			if settings.simple_effects:
				var texture: Texture2D=arena_art.projectiles[shot.affinity]
				draw_texture(texture,shot.pos-Vector2(4,4))
			else: ElementFX.projectile(self,shot,float(run.elapsed))
	_draw_player_art(color)
	if run.ward > 0: draw_arc(run.player, 22, 0, TAU, 24, Color("#c6e6ed"), 2.0)
	if run.webbed: draw_arc(run.player, 18, 0, TAU, 24, Color("#efcfa1"), 2.0)
	_draw_combat_feedback(visible_margin)
	draw_set_transform(Vector2.ZERO)
	# Mask the world outside the playfield, leaving all touch/HUD controls screen-fixed.
	draw_rect(Rect2(0, 0, 360, 88), Color("#1b1924"))
	draw_rect(Rect2(0, 536, 360, 104), Color("#1b1924"))
	draw_rect(PLAYFIELD, Color("#48404e"), false, 2.0)
	if run.player_hit_fx > 0 and not settings.reduced_motion:
		draw_rect(PLAYFIELD.grow(-3), Color(1.0, 0.34, 0.29, float(run.player_hit_fx) * 2.5), false, 3.0)
	_draw_hud()
	if settings.monitor and not paused and run.pending_upgrades==0 and not monitor_text.is_empty():
		draw_rect(Rect2(4,499,352,33),Color(0.06,0.05,0.09,0.88))
		var lines := monitor_text.split("\n")
		for i in range(lines.size()): Fantasy.text_at(self,lines[i],Vector2(10,511+i*13),10,Fantasy.IVORY)
	Fantasy.text_at(self,str(run.kit.special.name),Vector2(298,631),10,Fantasy.MUTED,true)
	if not paused:
		var hint := guide.tip(run)
		if not hint.is_empty():
			var lines := hint.split("\n")
			for i in range(lines.size()): Fantasy.text_at(self,lines[i],Vector2(180,557+i*15),11,Fantasy.GOLD,true)
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


func _draw_reveal() -> void:
	Fantasy.hall(self,reveal_time)
	var complete := reveal_time>=REVEAL_DURATION
	_draw_title("A NEW BLOODLINE" if complete else "FUSION RITUAL","Progress saved")
	var c := Vector2(180,210)
	var progress := clampf(reveal_time/REVEAL_DURATION,0,1)
	var hue := STEAM
	if not revealed.is_empty():
		hue=FIRE if revealed.phenotype.affinity=="fire" else (ICE if revealed.phenotype.affinity=="ice" else STEAM)
	var radius := 72.0+10.0*sin(progress*PI)
	draw_circle(c,radius,Color(hue,0.12))
	draw_arc(c,radius,0,TAU,48,Color(hue,0.7),2)
	draw_arc(c,radius-10,progress*TAU,progress*TAU+TAU*0.8,48,Color(Fantasy.GOLD,0.8),1)
	for i in range(16):
		var direction := Vector2.from_angle(i*TAU/16+progress*2.0)
		var point := c+direction*(radius-5)
		draw_rect(Rect2(point,Vector2(3,3)),hue.lightened(0.3))
	if not complete and progress<0.66 and ritual_parents.size()==2:
		var converge := smoothstep(0.0,0.66,progress)
		for i in range(2):
			var parent: Dictionary = ritual_parents[i]
			var feet := Vector2(82 if i==0 else 278,264).lerp(Vector2(180,264),converge)
			sprites.draw_wizard(self,parent.phenotype,feet,0,3.0)
		for i in range(10):
			var p := c+Vector2.from_angle(i*TAU/10+progress*4)*(95.0-75.0*converge)
			draw_rect(Rect2(p,Vector2(3,3)),Color(hue,0.85))
		Fantasy.text_at(self,"BLOODLINES CONVERGE",Vector2(180,339),13,Fantasy.GOLD,true)
	elif not revealed.is_empty():
		var scale_factor := 4.0+smoothstep(0.66,1.0,progress)
		sprites.draw_wizard(self,revealed.phenotype,Vector2(180,286),0,scale_factor)
		var flash := 0.32*(1.0-smoothstep(0.66,0.90,progress)) if not complete else 0.0
		draw_circle(c,66,Color(hue,flash))
		PixelArt.heading(self,"TIER "+str(revealed.phenotype.tier),Vector2(180,312),2,Fantasy.GOLD)
	if complete:
		Fantasy.frame(self,Rect2(14,320,332,200),hue.darkened(0.25))
	else:
		Fantasy.bar(self,Rect2(86,385,188,12),progress,1.0,hue)

func _update_motion_art(previous: Vector2,dt: float) -> void:
	arena_art.update_motion(run.enemies)
	var current: Vector2 = run.player
	var distance := previous.distance_to(current)
	player_moving = distance>0.05
	if player_moving: walk_facing=Rig.facing(current-previous,walk_facing)
	cast_pose_remaining=maxf(0,cast_pose_remaining-dt)
	player_stride = fposmod(player_stride+distance,16.0)
	dust_distance += distance
	if dust_distance>=12.0 and not settings.reduced_motion and not settings.simple_effects:
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
	if not player_moving: bob = -1.0 if not settings.reduced_motion and sin(float(run.elapsed)*2.6)>0.65 else 0.0
	if settings.reduced_motion: bob=0.0
	var casting := cast_pose_remaining>0
	var direction := cast_facing if casting else walk_facing
	sprites.draw_actor(self,run.phenotype,feet+Vector2(0,bob),frame,direction,casting,1.2)
	if run.special_fx>0:
		var pulse := float(run.special_fx)/0.35
		var spark := feet+Vector2(-10 if direction=="west" else 10,-18)
		draw_circle(spark,5,Color(color,pulse*0.35))
		draw_rect(Rect2(spark-Vector2(1,1),Vector2(3,3)),color.lightened(0.55))

func _draw_hud() -> void:
	var seconds := int(run.elapsed)
	Fantasy.text_at(self,"%02d:%02d" % [seconds/60,seconds%60],Vector2(12,18),15,Fantasy.GOLD)
	Fantasy.text_at(self,"KILLS %d" % run.kills,Vector2(82,18),11,Fantasy.MUTED)
	Fantasy.text_at(self,"LV %d" % run.run_level,Vector2(193,18),13,Fantasy.GOLD)
	var low := Fantasy.fraction(float(run.hp),float(run.max_hp)) < 0.25
	var warning := (0.4 if settings.reduced_motion else 0.3+0.2*sin(float(run.elapsed)*5.0)) if low else 0.0
	Fantasy.bar(self,Rect2(12,25,230,22),float(run.hp),float(run.max_hp),Fantasy.HP,displayed_hp,maxf(warning,0.0 if settings.reduced_motion else float(run.player_hit_fx)*3.0))
	Fantasy.text_at(self,"HP   %d / %d" % [ceili(run.hp),roundi(run.max_hp)],Vector2(127,40),12,Fantasy.IVORY,true)
	Fantasy.bar(self,Rect2(12,52,230,18),float(run.xp),float(run.next_xp),Fantasy.XP,-1.0,0.0 if settings.reduced_motion else level_flash)
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
		if not settings.simple_effects and not settings.reduced_motion: ElementFX.impact(self,fx,progress)
		if fx.kind=="defeat" or not settings.damage_numbers: continue
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
