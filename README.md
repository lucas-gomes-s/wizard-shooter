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

A run starts with a responsive logical viewport (short axis 600 world units, aspect clamped to 0.56–1.8). Resizing during a run fits that viewport into the new display without changing simulation geometry; starting a new run recalculates it. Wider arenas therefore change spawn distances and sightlines relative to the original square arena. Balance will need playtesting. The original sprites and dungeon texture remain in use. No new runtime dependencies, sound, touch controls, permanent progression or new spell mechanics are introduced.

Rendering reads bounded presentation events from the 50 Hz simulation; effects are capped and do not affect damage, XP or spawn rates. CI runs the Node regression suite and a Chromium smoke test with screenshots of the title, gameplay, pause and compact layout. The browser smoke test is development-only and requires Playwright; normal play still only requires the Python server.
