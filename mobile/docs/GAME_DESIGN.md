# Game design
Status: v0.1 | design baseline | 2026-11-27

## Product promise
Create a bloodline of wizards that nobody else has. The player learns how a unique character fights, grows attached to it, and makes meaningful choices about whether to retire it to create a descendant. Combat must be fun even without rewards. Fusion should be exciting even when unexpected.

## Established decisions
- Mobile native game, Android and iOS; Godot is the recommended engine.
- One active wizard. Automatic basic casting and manually activated special abilities.
- Randomly generated characters, functional and aesthetic genetics strongly correlated. Mixed-species hybrids allowed.
- Probabilistic parental inheritance; genetics largely hidden, expressed mechanics visible.
- Mature characters fuse into a new random character at the next tier. Parents retire permanently and remain in an archive.
- Both dungeon rewards and summoning rituals acquire characters.
- Limited shared XP to inactive characters.
- Both finite dungeons and endless survival.
- No functional equipment: durable character capabilities originate in genetics. Temporary run upgrades develop those capabilities; cosmetic personalization has no functional effect.
- Higher tiers unlock more complex builds, not blanket superiority. Difficulty is independent of tier.
- Dark fantasy pixel art; retain the original dungeon and irreverent humor.

## Proposed player flow
First launch: generate a starter (initially offer a choice of three viable random founders); teach movement, auto-casting, manual ability and upgrade choice in a short arena. First expedition rewards a second character or enough essence for a summon. Academy exposes roster and training group. Once two same-tier characters mature, show a fusion tutorial, explain permanent retirement, present qualitative compatibility hints, confirm and reveal the descendant. Record parents in lineage, update the Grimoire and allow immediate play with the offspring. No dead end if the active roster is small: ensure a starter summon or recovery grant if needed.

Combat loop (seconds): dodge, position, cast special, kill, collect XP, choose a temporary upgrade.
Character loop (minutes/hours): select wizard and apprentices, run, earn permanent XP and mastery, choose whether to mature/fuse or keep.
Legacy loop (hours/weeks): discover genetic associations, choose parents and catalysts, unlock new environments, develop lineages and record discoveries.

## Screens
Academy: overview, active wizard selection, apprentice assignment, summoning.
Collection: active vs archive; filters by tier, affinity, species phenotype, maturity and favorites; inspect abilities, statistics, lineage and mastery. Lock protects from retirement. Names are editable.
Dungeon: choose mode, environment, difficulty and wizard. Show reward expectations and personal record.
Run: joystick, HP, temporary XP, timer, manual ability and optional ultimate. Pause and upgrades overlay.
Results: run metrics, XP allocation, acquired characters and resources; acknowledge rewards exactly once.
Fusion: two distinct eligible parents, optional catalyst, qualitative hints, explicit irreversible confirmation, reveal, lineage.
Grimoire: discovered species, traits, affinities, observed combinations and encounter records. No complete genome dump.

## Modes
Finite expedition: proposed 10–15 minutes; timed arena for MVP, milestones and a final boss, optional rescue event. Successful completion grants targeted character acquisition and resources. Later add branching rooms.
Endless: rising waves, periodic elites and extraction windows; death or extraction ends run. Main rewards are XP, mastery and personal records. No difficulty scaling based on tier; encounter settings depend on selected difficulty and elapsed simulation time.

## Content and scope
Proof of concept (POC): Stoneborn/Fae, Fire/Ice, Steam, tiers I–II, four traits, two mutations, two basic spells, two manual abilities, three enemies, one boss, one arena, one apprentice, one summon, archive and basic journal. MVP: add Human, Earth and Lightning, three hybrids total, tier III, 12 traits, six mutations, eight basic spells, six manual abilities, three ultimates, nine original enemy archetypes, one or two bosses, three apprentices, three ritual types and three catalysts. Counts are provisional, not promises. See ROADMAP for validation gates.

## Design guardrails
No fusion failure or permanent death in combat. No premium random acquisition or time gates. No compulsory daily tasks. Every valid generated character must have a viable basic attack, a manual ability and accessible movement. Distinct traits should change decisions, not only numbers. Lower-tier characters remain useful on the same difficulty. Hidden genetic rules must be stable and learnable; known current effects always explained. Accessible visual cues use silhouette and icons, not hue alone. Target offline play, short sessions, background recovery and adjustable effects.

## Open design questions
Exact starter selection, expedition reward on defeat, extraction cadence, rarity nomenclature, maximum roster/archive size, whether cosmetic changes may obscure traits, detailed narrative, exact tier cap, and final monetization. Defaults in other specs are experimental and must not be presented as validated outcomes.
