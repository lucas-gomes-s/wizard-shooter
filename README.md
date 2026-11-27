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
