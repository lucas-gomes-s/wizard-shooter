extends RefCounted
## Result screen reads actual committed reward deltas; never calculates or grants rewards.
const Fantasy = preload("res://presentation/fantasy_ui.gd")
const Pixel = preload("res://presentation/pixel_ui_art.gd")
const Collection = preload("res://presentation/collection_art.gd")
const Academy = preload("res://domain/academy.gd")

static func before_reward(academy: Variant,active: Dictionary,apprentice: Dictionary) -> Dictionary:
	var ids: Array[String] = []
	for c in academy.roster: ids.append(str(c.id))
	return {"active":active.duplicate(true),"apprentice":apprentice.duplicate(true),"essence":academy.essence,"ids":ids}

static func committed(before: Dictionary,academy: Variant) -> Dictionary:
	var a: Dictionary = academy.find_active(str(before.active.id))
	var b: Dictionary = academy.find_active(str(before.apprentice.get("id","")))
	var newcomer: Dictionary = {}
	for c in academy.roster:
		if not str(c.id) in before.ids:
			newcomer=c.duplicate(true)
			break
	return {"active":a.duplicate(true),"apprentice":b.duplicate(true),"active_gain":int(a.xp)-int(before.active.xp),
		"apprentice_gain":int(b.xp)-int(before.apprentice.xp) if not b.is_empty() else 0,
		"essence_gain":int(academy.essence)-int(before.essence),"essence_total":academy.essence,
		"newcomer":newcomer,"fusion_ready":academy.eligible(a,b)}

static func outcome_color(outcome: String) -> Color:
	match outcome:
		"Victory": return Fantasy.GOLD
		"Extracted": return Color("#8bd6ba")
	return Color("#e08b87")

static func metric(canvas: CanvasItem,pos: Vector2,label: String,value: String) -> void:
	Fantasy.text_at(canvas,label,pos,10,Fantasy.MUTED,true)
	Fantasy.text_at(canvas,value,pos+Vector2(0,21),19,Fantasy.IVORY,true)

static func training_row(canvas: CanvasItem,sprites: Variant,old: Dictionary,current: Dictionary,gain: int,y: float,role: String) -> void:
	if current.is_empty(): return
	var hue := Collection.hue(current.phenotype)
	sprites.draw_wizard(canvas,current.phenotype,Vector2(36,y+48),0,1.3)
	Fantasy.text_at(canvas,role+"  "+Collection.title(current),Vector2(64,y+12),12,hue)
	Fantasy.text_at(canvas,"+%d XP" % gain,Vector2(308,y+12),12,Fantasy.GOLD,true)
	if int(current.phenotype.tier)==1:
		Fantasy.bar(canvas,Rect2(64,y+19,263,10),float(current.xp),Academy.MATURE_XP,hue)
		var message := "%d → %d / %d XP" % [old.xp,current.xp,Academy.MATURE_XP]
		if int(current.xp)>=Academy.MATURE_XP:
			message="NEWLY MATURE" if int(old.xp)<Academy.MATURE_XP else "Mature • %d training XP" % current.xp
		Fantasy.text_at(canvas,message,Vector2(64,y+43),11,Fantasy.MUTED)
	else:
		Fantasy.text_at(canvas,"%d → %d training XP" % [old.xp,current.xp],Vector2(64,y+37),11,Fantasy.MUTED)

static func draw(canvas: CanvasItem,sprites: Variant,run: Variant,before: Dictionary,reward: Dictionary) -> void:
	var accent := outcome_color(str(run.outcome))
	canvas.draw_rect(Rect2(0,0,360,640),Color("#17131f"))
	var heading := "VICTORY" if run.outcome=="Victory" else ("EXTRACTED" if run.outcome=="Extracted" else "DEFEATED")
	Pixel.heading(canvas,heading,Vector2(180,38),3,accent)
	var mode := "Endless survival" if run.endless else ("Trial expedition" if run.trial_rules else ("Mana expedition" if run.mana_rules else ("6-minute expedition" if run.phased_expedition else "Dungeon expedition")))
	Fantasy.text_at(canvas,mode+" • Difficulty "+["I","II","III"][int(run.difficulty)-1],Vector2(180,56),11,Fantasy.MUTED,true)
	Fantasy.frame(canvas,Rect2(12,66,336,104),accent.darkened(0.25))
	var p: Dictionary=before.active.phenotype
	canvas.draw_circle(Vector2(63,115),35,Color(accent,0.12))
	sprites.draw_wizard(canvas,p,Vector2(63,153),0,2.6)
	Fantasy.text_at(canvas,Collection.title(before.active),Vector2(116,89),15,Collection.hue(p))
	Fantasy.text_at(canvas,"TIER %d  •  RUN LEVEL %d" % [p.tier,run.run_level],Vector2(116,107),11,Fantasy.GOLD)
	var subtitle := "Dragon defeated" if run.outcome=="Victory" else ("Returned safely" if run.outcome=="Extracted" else "Fell in the dungeon")
	Fantasy.text_at(canvas,subtitle,Vector2(116,126),12,Fantasy.IVORY)
	if run.outcome=="Defeated" and not str(run.last_hit).is_empty():
		Fantasy.text_at(canvas,"Last hit: "+str(run.last_hit),Vector2(116,144),11,Fantasy.MUTED)
	Fantasy.frame(canvas,Rect2(12,180,336,106))
	var seconds := int(run.elapsed)
	metric(canvas,Vector2(70,198),"TIME","%02d:%02d" % [seconds/60,seconds%60])
	metric(canvas,Vector2(180,198),"KILLS",str(run.kills))
	metric(canvas,Vector2(290,198),"LEVEL",str(run.run_level))
	Fantasy.text_at(canvas,"Damage dealt %d   •   Taken %d" % [roundi(run.total_damage_dealt),roundi(run.total_damage_taken)],Vector2(180,248),12,Fantasy.IVORY,true)
	var exploration := "Caches %d  •  Shrines %d  •  Encounters %d" % [run.treasure_count,run.shrine_count,run.encounters_cleared]
	if run.trial_rules: exploration="Trials %d/2  •  Relics %d  •  Caches %d" % [run.trials_cleared,run.relic_choices.size(),run.treasure_count]
	if run.evolution_rules and not run.evolution_branch.is_empty():
		var id: String=run.evolution_mastery if not run.evolution_mastery.is_empty() else run.evolution_branch
		exploration="Trials %d/2 • %s" % [run.trials_cleared,run.Upgrades.DEFINITIONS[id].name]
	Fantasy.text_at(canvas,exploration,Vector2(180,270),11,Fantasy.MUTED,true)
	Fantasy.frame(canvas,Rect2(12,296,336,132),Color("#86719b"))
	Fantasy.text_at(canvas,"PERMANENT TRAINING",Vector2(180,314),11,Fantasy.GOLD,true)
	if reward.is_empty():
		Fantasy.text_at(canvas,"Rewards not saved yet",Vector2(180,356),15,Color("#e08b87"),true)
		Fantasy.text_at(canvas,"Retry to commit this expedition.",Vector2(180,382),12,Fantasy.MUTED,true)
	else:
		training_row(canvas,sprites,before.active,reward.active,int(reward.active_gain),320,"ACTIVE")
		if not reward.apprentice.is_empty():
			training_row(canvas,sprites,before.apprentice,reward.apprentice,int(reward.apprentice_gain),374,"APPRENTICE")
		else:
			Fantasy.text_at(canvas,"No apprentice assigned",Vector2(180,406),11,Fantasy.MUTED,true)
	Fantasy.frame(canvas,Rect2(12,438,336,100),accent.darkened(0.30))
	if reward.is_empty():
		Fantasy.text_at(canvas,"REWARD COMMIT PENDING",Vector2(180,477),13,Color("#e08b87"),true)
		return
	Fantasy.text_at(canvas,"+%d ESSENCE" % reward.essence_gain,Vector2(180,460),16,Fantasy.GOLD,true)
	Fantasy.text_at(canvas,"Academy balance: %d" % reward.essence_total,Vector2(180,479),11,Fantasy.MUTED,true)
	if not reward.newcomer.is_empty():
		Fantasy.text_at(canvas,"NEW WIZARD: "+Collection.title(reward.newcomer),Vector2(180,500),12,Collection.hue(reward.newcomer.phenotype),true)
	else:
		Fantasy.text_at(canvas,"Training carries over to future runs.",Vector2(180,500),11,Fantasy.MUTED,true)
	Fantasy.text_at(canvas,"FUSION READY" if reward.fusion_ready else "PROGRESS SAVED",Vector2(180,521),11,Color("#8bd6ba"),true)
