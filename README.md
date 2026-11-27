# wizard-shooter
Wizard Shooter is a 1-week project in CSS, HTML and Vanilla JavaScript done during IronHack Bootcamp.


>Play it [here](https://fitz552.github.io/wizard-shooter/)

## About the Game
After a wild night-out you wake up in an unfamiliar dungeon.

Use your magic to try to survive.

## Game Instruction
- Walk around using WASD
- Shoot using Directional Arrows
- Pick your skills wisely
- Survive!

## Contribution


>This is a free software, product of a study about webdev. Feel free to contribute in any way you want

Fork it
Create your feature branch (git checkout -b feature/fooBar)
Commit your changes (git commit -am 'Add some fooBar')
Push to the branch (git push origin feature/fooBar)
Create a new Pull Request

## IronHack

- Deployed game [link](https://fitz552.github.io/wizard-shooter/)
- Presentation [link](https://docs.google.com/presentation/d/1f6KZOAQbaHc2opn7Utvzz10aALow47Y_48NhELgFjEY/edit?usp=sharing)

## Local web development (technical foundations)

Serve the repository root using `python3 -m http.server 8000` and open http://localhost:8000. The browser now uses ES modules; opening index.html directly through file:// is not supported. No runtime dependencies or npm install are needed. WASD moves; hold arrows to shoot; Q shows HP bars while held or confirms a skill; Escape pauses/resumes. Switching tabs or losing focus pauses the run. Click Restart Game to begin a clean session.

The simulation runs at 50 fixed ticks/s (original balance), independently of requestAnimationFrame. `js/data.js` contains original configuration; `js/simulation.js` is the DOM-independent game state and spatial index; `js/index.js` handles cached assets, canvas rendering and input. Max cast speed is one shot per tick. Health potions are only consumed when injured. The original art, spell system and enemy roster remain unchanged, with smooth pursuit replacing randomized movement. The old mobile/ project is independent.

With Node.js 20+ run `npm run check` and `npm test` for dependency-free syntax and simulation regression checks. Browser playtesting and performance benchmarking remain necessary; the tests do not establish a frame-rate improvement.

## Reforged visual overhaul

The browser game has a new responsive layout with a dark dungeon theme, live HUD, title screen, pause/resume and abandonment confirmation, clickable upgrade cards with stat previews, and a run summary. Q/Enter or clicking an upgrade confirms it; arrows navigate. The Effects checkbox disables optional damage/healing numbers, particles, projectile trails and damage tint. Reduced-motion preference starts with effects off. Fullscreen is available where the browser supports it.

A run starts with a responsive logical viewport (short axis 600 world units, aspect clamped to 0.56–1.8). Resizing during a run fits that viewport into the new display without changing simulation geometry; starting a new run recalculates it. Wider arenas therefore change spawn distances and sightlines relative to the original square arena. Balance will need playtesting. The original sprites and dungeon texture remain in use. No new runtime dependencies, sound, touch controls or permanent progression are introduced in this visual phase.

Rendering reads bounded presentation events from the 50 Hz simulation; effects are capped and do not affect damage, XP or spawn rates. CI runs the Node regression suite and a Chromium smoke test with screenshots of the title, gameplay, pause and compact layout. The browser smoke test is development-only and requires Playwright; normal play still only requires the Python server.

## Magic system (v1.3 prototype)

Start with an ordinary manually aimed bolt. At level 2, choose one of three distinct random schools; later level-ups offer up to three distinct eligible cards. At least one school is offered while any ranks remain; eligible synergies have a reserved slot. Basic legacy stat upgrades stay in the later pool. Five ranks per school, and all acquired effects stack onto the same manually aimed cast. No automatic aiming. The existing level cap, spawn schedule and base stats remain.

| School | Rank I | Higher ranks |
| --- | --- | --- |
| Pyromancy | Burn ticks for 2 seconds | Stronger burn and splash damage |
| Cryomancy | Slow enemies | Pierce and periodic freeze |
| Electromancy | Chain and critical chance | Additional targets and stronger chains |
| Necromancy | Heal on kills | Curse and death bursts |
| Arcane magic | Two angled bolts | Triple bolts and recharging shield |

Synergies must be picked as a level-up reward after acquiring rank II in both schools: Steam eruption (fire + ice), Storm prism (lightning + arcane), Soulfire (fire + necromancy). The card pool and rank texts live in `js/magic.js`. Effects are evaluated at hit time using current ranks; bolt spread and pierce are fixed at cast time. Direct hits may apply multiple effects. Secondary damage does not recursively trigger on-hit effects; death bursts may cascade but each enemy's death is processed only once. Burn refreshes duration, not stacking independent burns. All timing uses simulation ticks, so pause and upgrade screens freeze effects. Projectiles capped at 720, lifetime 240 ticks, presentation events capped at 128 per tick. School colors, status marks and active shield remain visible with optional particles disabled.

These are initial balance hypotheses, not validated difficulty. Combining arcane multishot with chain and splash may prove too strong, and a wider arena changes spawn geometry. No bouncing bolts, summoned minions, orbiting projectiles, persistent unlocks or enemy-specific AI yet. The original manual aim and enemy roster remain. Run `npm run check` and `npm test` with Node 20+. The 33 test cases cover old and new simulation/presentation behavior; browser smoke and manual playtesting remain necessary.

## Enemy overhaul (v1.4)

All original enemy sprites and regular introduction times remain. Goblins pursue; orcs telegraph directional charges; spiders lay slowing webs; zombies accelerate when below half health; knights reduce frontal direct bolt damage to 35%; vampires heal from successful contact hits; reapers warn before teleporting; demons fire three-projectile volleys. Freeze delays an enemy's pending attack. Webs and projectiles persist independently of their caster. Threat telegraphs remain visible with cosmetic effects disabled.

From minute 3, every twelfth regular spawn is elite: 1.6x HP, 1.25x damage and 1.8x XP (rounded). At minute 25 a single Ancient Dragon appears (6000 HP, 65 contact damage, three phases at 66% and 33% HP); normal spawn intervals double while it is alive. The dragon cannot despawn, and its death grants victory before subsequent incoming damage. Victory offers a return to title or endless continuation, which clears existing hostile projectiles and hazards and increases future enemy stats with elapsed endless time. No recurring dragon. The old 3000 contact damage was deliberately replaced. Arcane shield still blocks contact damage only, not hazards or enemy bolts.

Performance limits: 260 regular enemy slots (boss may exceed by one), 320 hostile projectiles and 100 hazards. No enemy art replacements, audio or permanent progression. Difficulty and boss reachability have not been playtested. The 47 unit cases include enemy state transitions, hazard timing, shield behavior, unique boss spawning and victory. Browser CI now pins Ubuntu 24.04 and Playwright 1.55.1 rather than the incompatible Ubuntu 26.04 runner; Chromium smoke covers boss HUD and endless transition.

## Opening and balance laboratory (v1.5)

Select any of the five schools before the run; you start with rank I and no initial casting delay. Level 2 and 4 always include an eligible damage upgrade, and level 3 an eligible movement upgrade. Goblins appear immediately on the schedule, spiders unlock at 20 seconds, and orcs at 45 seconds (actual spawn follows their interval). Regular enemies ramp by elapsed time only: spawn intervals decrease by 1.8% of the base interval per minute, to a floor of 65%. Unique minibosses appear at minutes 5/10/15/20; the Ancient Dragon still arrives at 25. Earlier enemy introductions, HP, rewards, damage and speeds are centralized in data.js. Existing sprites and manual aiming remain. The title screen retains the last selected school when retrying.

### Balance model and repeatable experiments

`npm run balance` prints the analytic forecast and runs each school for 180 seconds with seeds 1–3. `npm run balance -- 1800 1 5` performs one 30-minute-cap run per school; `npm run balance -- 1800 10 10` increases the sample and reduces the bot's decision frequency. The third argument is ticks between bot decisions, not a calibrated human difficulty setting. Output includes actual survival duration, level, kills, earned XP, health, first upgrade timing, enemy backlog, school ranks and victory status. No browser or extra dependencies required.

The analytic forecast integrates the actual scheduled spawn intervals, elite rounding and miniboss rewards, excluding dragon XP, post-dragon encounters and spawn-cap losses. Its XP is a theoretical available supply, not XP already earned. Levels are scenarios at 25%, 50%, 75% of available XP collected. HP/s is the local regular-enemy HP influx, excluding discrete miniboss/dragon spikes. Reference effective DPS assumes one-quarter of level-up picks in damage, one-quarter in casting speed (cooldown floor 5 ticks for the reference build only), 55% hit rate and 1.4x area multiplier. This is not a prediction of player DPS; actual build, aim, positioning, armor, healing, status and enemy density matter. The 50 Hz simulation bot uses cardinal aiming, kiting and upgrade selection, sees world state, and reacts every five ticks in the default experiment. Do not interpret it as a human model.

### Recorded initial calibration (same seeds, 600x600 world)

| Time | Available XP | Level at 25/50/75% XP | Regular HP/s | Reference DPS at 50% XP |
| --- | ---: | --- | ---: | ---: |
| 0:15 | 16 | 1 / 2 / 3 | 5.9 | 8 |
| 1:00 | 106 | 4 / 5 / 6 | 16.8 | 17 |
| 5:00 | 1195 | 10 / 13 / 15 | 56.7 | 44 |
| 10:00 | 4542 | 16 / 20 / 22 | 94.1 | 64 |
| 15:00 | 10901 | 21 / 24 / 27 | 147.7 | 92 |
| 20:00 | 22396 | 24 / 29 / 32 | 235.6 | 205 |
| 25:00 | 34637 | 27 / 32 / 35 | 235.6 | 205 |

First candidate: 8/15 bots survived 3 minutes. Final candidate: 15/15 survived 3 minutes, first upgrades at 6.28–8.06 seconds (earlier than the initial 15–20 second design goal), levels 11–12 before late tuning. Prior long candidate: zero of five reached minute 25. Final 30-minute cap, seed 1 per school: Fire died at 337.4s (L17); Ice died at 1208.48s (L34); Lightning victory at 1515.34s (L38); Necromancy victory at 1514.96s (L38); Arcane victory at 1507.78s (L38). Small exploratory samples, not a win-rate estimate. Bot variance, school choice, screen aspect ratio and balance of contact vs ranged damage need further testing. Fire's late viability is not established. No adaptive enemy scaling to player power has been added. Fifty-five regression cases passed in a direct JS harness; the actual Node CI and browser smoke still require confirmation.

## Combat readability and effects (v1.6)

The original sprites, world dimensions, enemy stats, timing, damage and upgrade rules are unchanged. Procedural Canvas visuals live in `js/combat-fx.js`. Each school has recognizable projectiles, hit feedback and persistent status graphics: fire flames, frost crystals and freeze rings, jagged lightning beams, necromantic curses and soul wisps, and arcane shield geometry. Steam and soulfire have separate visual palettes. Enemy visuals include web strands with a clearly marked pending trap, sticky strands on a slowed player, directional charge lanes, teleport portals and arrival pulses, demon/dragon volley directions, flame zones, knight shields and block notices, vampire drain tethers and dragon phase pulses. The procedural visuals use no new assets or runtime dependencies.

Effects selector: Full (up to 320 transient objects), Reduced (up to 100), Off (no transient objects). Threat telegraphs, active floor hazards, shield and status indicators and projectile cores remain visible in all modes. Reduced-motion preference defaults to Off. No camera shake or full-screen strobe effects. Rendering uses independent visual randomness and bounded cosmetic events (128 per tick), separate from gameplay events. Pausing freezes effect progression; restart, title and endless transition clear transient objects.

Verification: all 63 regression cases passed in a direct JS harness; all 15 seeded 180-second bot results were identical to the preceding balance branch, including first upgrade timing, kills, health, level, XP, enemy backlog and ranks. CI browser smoke exercises all three modes and captures a forced elemental/web showcase with full effects and essential telegraphs only. Actual browser screenshots and frame-rate performance require CI and manual review. The effects are not additional attacks, larger collision volumes or changes to difficulty.

## School specialization (v1.7)

The starting school is a permanent primary identity for the run, including the main projectile color. Levels 2–9 offer only mastery of that school and basic stat upgrades. At level 10, a second school becomes eligible. Until chosen, at least one eligible secondary school is offered on subsequent level-ups; learning it is optional. Existing eligible school mastery receives a reserved offer slot. Each school still caps at rank V. The permanent two-school limit is enforced both in card generation and when applying upgrades. Compatible rank II pairs can still unlock the three existing synergies; other pairs combine their normal effects without an additional synergy. No new spell damage, enemy stats or spawn changes.

The starting screen explains the restriction and the build strip shows the secondary unlock countdown. The secondary choice is permanent until restarting. Five new regression cases passed, 68 total in the direct harness. In three-minute benchmarks (3 seeds per school), all 15 bots survived, reaching levels 11–12. In the five exploratory full-run benchmarks (seed 1, 1800s cap), fire died at 540.74s, ice at 819.82s, lightning at 535.66s, arcane at 476.20s, and necromancy won at 1501.24s. Earlier unrestricted builds won three of five runs on the same seeds, although changing offer pools also changes RNG consumption. These samples are too small to infer win rates. Late difficulty and upgrade incentives need retesting, especially after restricting combinations. Browser smoke includes the new level-ten choice; actual CI pending.

## Complete school fusions (v1.8)

All ten unordered school pairs now have exactly one unique combination ability. Secondary-school offers preview the corresponding fusion before committing. Both schools must reach rank II, after which the fusion is guaranteed to appear in the eligible upgrade pool until selected. Primary/secondary order does not change the combination; the two-school cap and level-10 secondary unlock remain.

| Pair | Fusion | Mechanic |
| --- | --- | --- |
| Fire + Ice | Steam eruption | Existing 70-unit damage and slow pulse |
| Fire + Lightning | Plasma surge | Chain hits ignite targets, refreshing a nonstacking burn |
| Fire + Necro | Soulfire | Existing burning-death explosion |
| Fire + Arcane | Starfire | Every fourth cast becomes five explosive bolts |
| Ice + Lightning | Thunderfrost | Chain chills and freezes previously chilled targets, per-target freeze cooldown |
| Ice + Necro | Gravefrost | Chilled deaths pulse damage and slow |
| Ice + Arcane | Glacial mirror | One extra pierce; shield block freezes nearby enemies |
| Lightning + Necro | Soul conductor | Chain-marked kills heal and fire a single soul bolt |
| Lightning + Arcane | Storm prism | Existing extra chain jump and range |
| Necro + Arcane | Soul ward | Kills shorten shield recharge; shield blocks heal and pulse damage |

Secondary damage never calls directHit recursively. Death effects use the existing deduplicated death queue, so cascading kills pay XP once. Starfire uses the run's cast counter and the base damage at impact for its splash. Shield effects trigger only on blocked contact attacks, not hazards or hostile bolts. Seven new effects use distinct color palettes; no new assets. Existing three fusions and enemy stats remain unchanged.

Verification: 76 regression cases passed in a direct JS harness, including all 20 ordered combinations, eligibility, offer guarantees and the seven new mechanics. Browser smoke checks secondary fusion previews. Three-minute sample: 15/15 survivors. Five long seed-1 runs (1800s cap): Fire 540.74s, Ice 840.22s, Lightning 573.46s, Necro victory 1501.86s, Arcane 476.2s. The default bot chooses opportunistically and does not exercise every pair in full runs. These exploratory results are not win-rate estimates; pair-specific balance and actual browser verification are outstanding. 

## Targeted build benchmark (v1.8.1)

Run `npm run balance:builds -- 1800 5 5 results.json` to test all 25 targets (20 ordered hybrids and five pure schools), five seeds each, 30-minute cap, decisions every five simulation ticks. The bot chooses only legal offered upgrades, targets the requested secondary when offered, prioritizes rank II and fusion eligibility, and never changes gameplay state to force a build. Pure bots refuse every secondary school. The shared policy favors movement to speed 4, damage and cast speed, then mastery and vitality; it is not an optimized strategy per school. Movement uses continuous vectors rather than strict WASD, sees exact game state, and is not a human skill model. Each run captures actual learned ranks, secondary/fusion timing, survival, kills, levels, XP, maximum enemies, stats and five-minute milestones. Same seed does not mean identical encounters after differing RNG calls.

The original seed-1 diagnostic in benchmarks/v1.8/ showed six blocked runs (five pure, one hybrid). The offer generator could present only unwanted secondary schools despite the optional specialization rule. v1.8.1 guarantees one general upgrade when one school is learned, level >=10, and a basic upgrade remains eligible. No damage, HP, timing or enemy-stat changes were made. This changes offer distributions and random consumption. Only the corrected runs are summarized in benchmarks/v1.8.1/.

Actual 125-run results (seeds 1–5, 34.62 simulated hours): 34 victories, 0 blocked, all 125 reached five minutes, 96 reached ten, 74 fifteen, 39 twenty, 34 reached the dragon and defeated it. Hybrid targets: 31/100 wins; pure: 3/25. Of 100 hybrid attempts, 97 learned their requested secondary and fusion; in three the requested school was never offered before death (lightning→fire seeds 1,4; necro→fire seed 5). Median fusion time among successful unlocks 222.78 seconds, median level 14. Unordered pair wins out of ten: Soul conductor 9, Soul ward 7, Storm prism 4, Starfire 4, Glacial mirror 3, Gravefrost 3, Soulfire 1, Steam eruption 0, Plasma surge 0, Thunderfrost 0. Primary school wins out of 25: Arcane 16, Necro 10, Lightning 5, Ice 2, Fire 1. Pure wins out of five: Necro 2, Arcane 1, others 0. These are exploratory outcomes, not human win rates or statistically robust rankings. Recommend investigating offensive/survival tradeoffs, build-specific upgrade policies and matched ablation of fusions before changing balance.

Raw per-seed JSON and aggregate summary are committed; the original opportunistic benchmark remains available. All 80 regression cases passed in a direct JS harness; actual Node/Chromium CI not confirmed.

## Balance iteration 2 (v1.9.0)

Implemented the proposed fusion tuning: Steam damage 35%→55%, radius 70→85; Plasma chain burn 20%→40% per half-second, duration 2→3 seconds (nonstacking); Thunderfrost freeze 0.4→0.8 seconds, retaining its per-target cooldown; Soulfire radius 60→80; Soul conductor bonus healing 3→1.5 HP; Soul ward recharge reduction 0.5→0.3 seconds per kill. Fire burn per rank is now 20/35/45/55/65% of bolt damage, versus 20/25/30/35/40%; rank III+ splash is 45% (was 30%), radius 55/75 at ranks III/V (was 45/65).

Exclusive pure-school mastery becomes an eligible upgrade at level 15 or later, with primary school rank V and no secondary. Choosing it permanently locks the second school. Inferno boosts burn by 40% and makes bursts 65% within 95 units; Absolute zero adds two pierce targets and 40% damage to previously chilled targets; Tempest adds two chain jumps, 40 range and 20 percentage points of crit chance; Lich ascension boosts death pulse to 60% within 85 units and adds 1 HP per kill; Archmage fires five 75% bolts and has a seven-second shield recharge. Mastery is visible in the HUD and results.

Dragon health 6,000→18,000, contact damage 65→75, projectile damage/speed increased, hazard damage 35→45, windup 55→45 ticks, attack cooldown 120/80→90/60 ticks. Dragon movement factor is floored at 0.5, preventing freeze from stopping attacks. Spawn timing and regular enemy stats unchanged.

### Actual matched-seed benchmark

125 runs (25 targeted builds × seeds 1–5, 1800s cap, five-tick decision cadence), 35.48 simulated hours. Compared to v1.8.1, 38/125 reached dragon (was 34), 30 won (was 34); 8/38 arrivals lost to dragon (previously zero). All 125 reached 5 minutes, 101 reached 10, 75 reached 15, 40 reached 20. Hybrid wins 27/100 (was 31), pure wins 3/25 (unchanged). All 25 pure runs acquired capstones; 98/100 hybrid runs acquired fusion, 99 learned desired secondary. No forced-choice blocks. Median pure survival 819.76s vs 766.9s; hybrid 1047.19s vs 1027.36s. The pure bot now prioritizes rank-V mastery after level 10 and selects capstone when eligible; hybrid policy unchanged. Thus pure comparisons include policy change. Same seed does not guarantee identical encounters after divergent RNG consumption.

| Fusion | Previous wins / 10 | New wins / 10 |
| --- | ---: | ---: |
| Steam eruption | 0 | 0 |
| Plasma surge | 0 | 2 |
| Soulfire | 1 | 5 |
| Starfire | 4 | 3 |
| Thunderfrost | 0 | 0 |
| Gravefrost | 3 | 3 |
| Glacial mirror | 3 | 3 |
| Soul conductor | 9 | 3 |
| Storm prism | 4 | 3 |
| Soul ward | 7 | 5 |

Primary wins / 25: Fire 1→5; Ice 2→2; Lightning 5→1; Necro 10→10; Arcane 16→12. Spread narrowed, but Ice/Lightning, Steam and pure offensive schools remain weak; Thunderfrost median survival fell from 774.84s to 579.97s despite buff, so further targeted diagnosis is needed. Do not infer causal effects of individual changes from this multi-parameter patch. Five seeds per ordered build, shared bot strategy and unverified human playability limit conclusions.

All 87 direct JS regression checks passed. Actual Node/Chromium CI and human playtests remain unverified. Raw benchmark results and summary in benchmarks/v1.9/. Run npm run balance:builds -- 1800 5 5 results.json.

## Equipment and treasure (v1.10.0)

Four run-local slots (staff, robe, boots, relic), six unique items per slot, 24 total. Equipment is independent of magic schools. A replacement removes the previous effect and resets slot-specific timers and counters; no permanent stat mutation or inventory accumulation. Item effects are defined in js/equipment.js, using existing combat visuals for the new pulses. All current effects are passive or automatic; active controls, merchants, gold, and randomized dungeon events are deferred.

Timed treasure spawns near the wizard at minutes 2/7/12/17/22, with maximum rarity rare/rare/epic/epic/legendary. Guardians at minutes 5/10/15/20 drop rare/epic/epic/legendary chests on death. Chests expire after 90 seconds and the live count is capped at eight. The HUD displays equipment and treasure countdown, and offscreen chests have directional markers. Contact with a chest pauses simulation and opens three comparison cards from distinct slots, guaranteeing one item of the advertised rarity when available. Pick one or keep current equipment. Equipment is lost when a new run starts.

Equipment benchmarks use actual offered items and a simple heuristic to pursue chests and prefer improvements, not forced equipment or optimized item combinations. Set equipmentEnabled:false in simulation config for no-equipment experiments. The initial targeted ten-minute benchmark (seed 1, all 25 builds, five-tick decisions) completed 21/25 runs to the time cap; all 25 collected at least one chest, 70 chests opened overall. Raw results: benchmarks/v1.10/ten-minute-seed-1.json. These short exploratory runs do not establish item balance or endgame win rates. 103 direct JS regression checks passed across the test suite (16 new equipment tests); controller syntax parsed. Browser smoke coverage includes opening, equipping and skipping loot. Actual browser CI and human playtesting are not yet confirmed. To test a larger sample, npm run balance:builds -- 1800 5 5 equipment-results.json.

## Optional dungeon challenges (v1.11.0)

Five opportunities appear at 03:30, 08:30, 13:30, 18:30 and 23:00. A seeded random deck selects five of six challenge types without replacement. The activation circle appears near the player, with 35 seconds to accept by entering it; ignored offers have no penalty. Only one challenge is active, and each ends before the next scheduled guardian or dragon, though an undefeated earlier guardian can remain present. Events are disabled after the dragon spawns, and are reset on restart. No changes to normal enemy stats or spawn schedule.

| Event | Objective | Active duration |
| --- | --- | --- |
| Cursed altar | Survive summoned reinforcements (two extra monsters every four seconds) | 30s |
| Arcane shrine | Accumulate 15s inside a fixed ritual circle | 40s |
| Treasure guardian | Defeat marked elite before timeout | 40s |
| Blood moon | Meet kill quota (16 + elapsed minutes, capped at 45) | 35s |
| Dungeon collapse | Survive without taking three actual rubble hits; 1.1s telegraph | 30s |
| Magical anomaly | Collect three distinct runes | 40s |

Successful challenges drop one nearby equipment chest (rare before minute 10, epic until minute 20, legendary thereafter, subject to existing chest cap). Event-only enemies, their projectiles and hazards are removed on resolution, without awarding XP for despawned enemies. No reward on failure or expiration. Existing fixed-step pause behavior applies. HUD shows optional/active state, objective, time left and completion notices; directional markers, ritual circle, rune markers, guardian HP and rubble warnings remain visible with cosmetic effects off. Config flags eventsEnabled:false or equipmentEnabled:false disable the event system.

The bots pursue challenge markers, shrine, guardian and uncollected runes when health and nearby threats allow; actual offers and rewards are recorded. Preliminary ten-minute sample (25 ordered build targets, seed 1, before final summoned-hazard cleanup): 20 reached 10 minutes, 45/48 completed encounters. Final 30-minute-cap sample (same 25 targets, seed 1, 5-tick decisions): 20 reached 10 minutes, 9 reached dragon, 4 won; 88 encounters resolved, 80 completed, 5 failed, 3 ignored; 235 chests opened. Completion counts by type: altar 12/14, shrine 10/15, guardian 14/14, moon 18/18, collapse 15/15, anomaly 11/12. This is a single-seed exploratory sample; some challenge objectives appear too forgiving for this bot, and actual fun/difficulty require human playtests. Raw files in benchmarks/v1.11/. All 112 direct JavaScript regression checks passed (9 new event tests). Controller syntax parsed; browser smoke now covers event activation, but actual Chromium CI remains unverified. Active equipment controls, merchant/economy and permanent rituals remain future work.

## Active equipment and merchant (v1.12.0)

Eight existing items now grant active skills in addition to their passives. Space activates eligible boots; E activates eligible relics. A keypress queues one activation, not continuous auto-cast. The HUD shows the ability and remaining cooldown; item offers preview the skill. Slot cooldowns survive replacements to prevent bypassing recharge, while temporary item buffs are cleared on replacement. New runs reset all equipment, gold and active state.

Boots: Runner's Greaves (85-unit dash, 7s cooldown); Escape Boots (110-unit dash, clear webs, 9s); Trailblazer Boots (70-unit dash plus damaging pulse, 10s); Phasewalkers (120-unit teleport plus short invulnerability, 9s). Relics: Hourglass (nearby freeze, 20s); Soul Lantern (180% base damage pulse, 15s); Cursed Crown (50% projectile buff for 4s at 10% max HP cost, 20s); Alchemist's Charm (12% max HP recovery, 25s). Passive effects retained; crown cannot activate if lethal and tonic cannot activate at full HP.

Gold is earned automatically: one per four kills, two extra for elite kills, twenty extra per miniboss, and 15/30/45 for successful rare/epic/legendary challenges. Merchants appear at minutes 6, 11, 16 and 21, remain for 60 seconds, and open a paused shop when approached. Choose one of three items or a restorative draught (35% max HP), or leave without spending. Prices: common 45, rare 90, epic 170, legendary 300, draught 35. Stock rarity follows run progression. No real money, persistent currency or monetization. Economy can be disabled with economyEnabled:false.

Initial ten-minute sample, 25 ordered build targets, seed 1: 24 survived, 22 purchases, 483 active uses, 8,457 gold earned and 1,770 spent after reducing initial excessive payouts. All 123 direct regression cases passed in two groups (76 existing core, 47 recent/new); 11 new active/economy tests. Controller syntax parsed. Full browser CI and full-duration balance not verified. Gold still accumulates faster than spending in this sample; later pricing, stock and sinks need calibration. Raw results in benchmarks/v1.12/. Bots use proximity-based active and purchase heuristics, not optimized policies.

## Equipment attunements and combat telemetry (v1.13.0)

Ten equipment-specific bonuses, two for each magic school, activate automatically when the corresponding item is equipped and either learned school reaches rank II. Equipment replacements remove the bonus; this does not bypass the two-school limit or require a separate upgrade. Loot and merchant cards show the requirements and whether the attunement is active; equipped attuned items are marked in the HUD.

| School | Item | Attunement |
| --- | --- | --- |
| Fire | Meteor Scepter | Meteor impact burst 45% → 65% |
| Fire | Trailblazer Boots | Passive movement pulse 35% → 50% |
| Ice | Prismatic Rod | One additional piercing target |
| Ice | Hourglass of Eternity | Active freeze 1.2s → 1.6s |
| Lightning | Farshot Staff | Chain range +30 |
| Lightning | Gambler's Ring | Double damage 25% → 35%; half damage 25% → 15% |
| Necromancy | Vampire Fang | Healing per kill 0.5 → 0.8 HP |
| Necromancy | Soul Lantern | Passive pulse every 9 kills instead of 12 |
| Arcane | Staff of Echoes | Extra bolt every fourth instead of fifth cast |
| Arcane | Aegis of Dawn | Recharge 12s → 9s |

Combat counters are independent of the presentation event queue. Reports include actual enemy HP removed, excess (overkill) damage, damage by attack mechanism, actual incoming damage and mitigation by enemy/attack type, healing by source, explicit equipment health costs, casts, projectiles, distinct projectiles hitting at least once, direct hits, and five-minute windows. Accuracy counts emitted projectiles, including those still in flight at the end of the run; a piercing projectile counts as one successful projectile. Direct damage includes all modifiers to a bolt and is classified by its primary school, not a causal attribution of individual upgrades. Control effects, movement and avoidance are not measured as damage; no causal effectiveness claims from source totals. The report appears on the defeat/results screen and is exported in benchmark JSON. No network telemetry or account tracking.

A full-duration exploratory sample of all 25 ordered build targets (seed 1, 1800s cap, decisions every five ticks) produced 5 victories and 9 dragon arrivals; 22 reached minute 10, 18 minute 15 and 9 minute 20. Total simulated time 27,455.62s, effective damage 3,117,766 HP, overkill 3,046,829 HP, actual incoming 19,976 HP, healing 19,878 HP, prevented incoming damage 8,735 HP. 43,566 of 145,263 emitted projectiles hit a target (30.0%); overkill accounts for 49.4% of computed outgoing damage. Demon projectiles accounted for 7,322 HP (36.7% of incoming), Reaper contact 3,951 HP (19.8%). Necromancy kill healing accounted for 11,789 HP (59.3% of actual healing). Observed primary-school victories (five runs each): fire 1, ice 0, lightning 0, necromancy 3, arcane 1. These are aggregate observations from unequal run durations, not proof that a particular mechanic is overpowered. Bot item preferences now account for attunement; no enemy stats or base gear stats were otherwise retuned. Raw data: benchmarks/v1.13/full-seed-1.json.

132 direct JavaScript regression checks passed across three batches (56 + 55 + 21); controller syntax parsed. Full browser CI and human playtesting remain unverified. Next balance pass should compare at matched time windows, account for enemy exposure, and test targeted changes with multiple seeds and holdout seeds. 

## Permanent progression and the wizard chronicles (v1.14.0)

The browser title screen now offers a local profile/codex, expedition contract selector, cosmetic sigil selector and lifetime statistics. Fourteen achievements are derived from saved records: first run, ten- and twenty-minute survival, 1,000 lifetime kills, six/all 24 items equipped, first/all ten fusions, first/all five masteries, all six challenge types completed, first dragon victory, victories with all five primary schools, and a contract victory. The codex tracks acquired/replaced items, learned schools, fusions, masteries, completed events and winning starting schools/contracts.

Unlockable options:
- Purist oath: discover a pure mastery. Secondary schools are forbidden.
- Merchantless expedition: equip six distinct items. No gold or merchants; treasure and challenges remain.
- Dry pilgrimage: defeat the dragon. No natural potion spawns; other healing remains.
- Ember, jade, golden and frost sigils unlock at ten-minute survival, first fusion, first dragon victory and full item collection respectively. Sigils only recolor the wizard's ground ring.

Standard expeditions and all five starting schools remain available immediately. There are no permanent numerical stat buffs or paid unlocks. Progress is stored in localStorage under wizard-shooter.profile.v1; no network service. The versioned save validates counters, identifiers and unlocked selections; storage failures are reported and gameplay remains available. Records are checkpointed on death, victory, confirmed restart/exit and pagehide. Continuing endless adds incremental time/kills and discoveries but does not duplicate the run or win. Zero-tick starts are not counted. No mid-run resume or cross-device synchronization; simultaneous tabs are not merged. The profile contains local gameplay records, not a competitive leaderboard or tamper-resistant save.

Verification: eight new progression tests and twelve existing specialization/mastery tests passed in a direct JS harness (20 total). Controller syntax parsed. Ten seeded 180-second standard runs (five schools, seeds 1 and 2) produced identical benchmark JSON to v1.13. Browser smoke was extended to open the profile, verify locked options, record a dragon victory and reload to verify unlocks. Actual browser CI and human playtesting remain unverified. No enemy, weapon, loot or economy balance changes; Android untouched.

## Dungeon environments (v1.15.0)

Choose one of three environments on the title screen. All are available immediately, with any starting school or unlocked expedition contract. The original Forgotten Crypt preserves standard spawns and floor; Frozen Hollow uses icy floor treatment/crystal scenery and more frequent spiders, knights and reapers; Ashen Forge uses warm floor treatment, cracks and grates, and more frequent orcs and demons. Existing enemy sprites and behavior families are reused; no new creature AI or independent boss mechanics yet. Boss names are Ancient Dragon, Frostbound Dragon and Ember Dragon respectively, with identical core boss combat.

| Environment | Normal spawn interval multipliers | Environmental hazard |
| --- | --- | --- |
| Forgotten Crypt | Unchanged | None |
| Frozen Hollow | Spider 0.72, Goblin 1.12, Knight 0.8, Reaper 0.85, Demon 1.4 | Ice fissure every 18s, 1.4s warning, 8 damage, 25% movement slow for 1.5s on damaging hit |
| Ashen Forge | Spider 1.45, Orc 0.75, Zombie 1.15, Reaper 1.3, Demon 0.78 | Lava vent every 16s, 1.2s warning, 12 damage |

Unlisted spawn intervals unchanged; lower multiplier means more frequent spawn. Hazards start at minute 2, produce two zones from minute 10 and gain 4 damage from minute 15. Zones damage at most once, respect the shared hazard cap, persist during boss encounters, and have essential warning geometry even with cosmetic effects disabled. Environmental hazards can be disabled in config with environmentHazards:false. Frost slow is separate from spider web slow. Floor decorations are procedural, world-anchored and noncolliding; they use no simulation RNG. No new asset dependencies.

The local profile tracks environments visited and won, adds the Worldwalker achievement for winning all three, and remembers the selected environment. Older version-1 profiles remain valid and default to the crypt; old victories cannot be reliably assigned to a biome retroactively, so biome records start empty.

Exploratory environment benchmark: 30 runs, all five primary schools, two seeds each per biome, ten-minute cap and five-tick bot decisions. Crypt 9/10 survived (mean level 22.5, mean kills 719.3), Frost 7/10 (22.0, 707.3; 64 hazard HP damage across runs), Forge 8/10 (22.1, 684.4; 60 hazard HP damage). Raw data in benchmarks/v1.15/environments-ten-minute.json. No full-duration environment comparison or balance tuning performed. Reproduce with npm run balance:environments -- 600 2 results.json. Six new environment and eight progression checks passed in the direct JS harness; controller syntax parsed. Ten standard crypt three-minute seeded benchmarks exactly matched v1.14. Browser smoke expanded to select environments and check profile records, but actual Chromium execution remains unverified. Web only.

## Sound design (v1.16.0)

The web game now uses Web Audio to synthesize original sound effects and four looping musical themes. The five schools have distinct cast signatures (fire low sweep, ice high crystalline notes, lightning sharp electrical pulse, necromancy descending low tone, arcane rising harmonic notes). Other cues cover impact, kills, injury, healing, elemental bursts, chains, shields, freezing, critical hits, blocks, teleportation, visible enemy windups and hazard warnings, guardians, boss phase changes, encounters, upgrades, loot, shops, success/failure, victory and defeat. Original oscillator note patterns provide crypt, frost, forge and faster boss themes; no sampled or third-party music/assets.

Audio is presentation-only: the game simulation and RNG are untouched. The header Audio menu has master mute and independent effect/music sliders (defaults 55% and 25%). Settings persist in localStorage under wizard-shooter.audio.v1, independent of player progress. AudioContext creation/resume requires a trusted browser interaction, with unsupported or blocked contexts handled silently. Music plays during combat, switches for active guardians/dragon and stops during overlays or pause. Screen transition cues may play briefly during loot/upgrade/shop or results. Backgrounding/blur stops voices. Audio remains independent of visual-effects intensity. Visual warnings are still essential and never replaced by sound.

Repeated cues are throttled, warnings deduplicated by action/hazard identity, simultaneous voices capped at 32 with important cues able to evict ordinary voices, and a compressor reduces peak levels. Music scheduling uses short look-ahead on the animation loop rather than persistent timers, avoiding backlogs when the page pauses.

Seven new audio tests passed in a direct JavaScript harness using a mock AudioContext (settings, autoplay fallback, school signatures, throttling, voice cap, theme switching, pause, mute and cue deduplication). Controller syntax parsed. Browser smoke coverage extended for actual Web Audio unlock, mute, pause and reload persistence. Actual Chromium execution and subjective sound quality/mix remain unverified. No combat balance changes, no new runtime dependencies, Android untouched.
