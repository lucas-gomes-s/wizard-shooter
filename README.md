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
