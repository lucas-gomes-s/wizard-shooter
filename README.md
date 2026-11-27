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
