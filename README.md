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

The simulation runs at 50 fixed ticks/s (original balance), independently of requestAnimationFrame. `js/data.js` contains original configuration; `js/simulation.js` is the DOM-independent game state and spatial index; `js/index.js` handles cached assets, canvas rendering and input. Max cast speed is one shot per tick. Health potions are only consumed when injured. The viewport is still 600 × 600; art, spell system and enemy roster remain unchanged, with smooth pursuit replacing randomized movement. The old mobile/ project is independent.

With Node.js 20+ run `npm run check` and `npm test` for dependency-free syntax and simulation regression checks. Browser playtesting and performance benchmarking remain necessary; the tests do not establish a frame-rate improvement.
