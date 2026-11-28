# Wizard Shooter Reforged: closed beta 1

Version 1.19.0-beta.1. Desktop keyboard browser build. This is a release candidate, not a public release.

## Play
Extract the ZIP, open a terminal in the extracted directory, run `python3 -m http.server 8000 --bind 127.0.0.1`, then visit http://127.0.0.1:8000/. Keep the terminal open while playing. Use a recent desktop Chrome/Edge, Firefox or Safari. Browser compatibility is a verification target, not a certification. No account, network service, installation or payment is required. Do not open index.html directly from disk: modules require HTTP.

WASD movement, arrow keys casting, Space boots ability, E relic ability, Q health bars, Esc pause. Choose a school and environment on the title screen. Audio and effects can be adjusted. Progress is local to this browser and origin; changing ports or clearing storage may remove access to saved progress. No touch controls or mid-run resume.

## Tester protocol
1. Start one standard Crypt run; record time, school, build, cause of death and perceived difficulty (1–5).
2. Try one different school and environment. Try at least one event, treasure, active skill and merchant when possible.
3. Note boring periods, unreadable effects, unfair damage, control problems, and whether you would play again.
4. Test pause/resume, settings, and profile persistence after refresh. Report crashes or stuck menus immediately.
5. For issues, click Report issue to capture a local JSON snapshot, copy it and send it privately to your beta coordinator with the steps, expected vs actual result, severity and optional screenshot. Do not include personal information. Nothing is submitted automatically.

## Release gates
- All Node unit and Chromium full smoke tests pass.
- Chromium, Firefox and WebKit short compatibility/stress jobs pass. Inspect screenshots and frame-time JSON; investigate p95 frame time above 33ms or sustained FPS below 30. Headless shared runners are noisy; confirm on real devices.
- Real-device smoke on macOS Safari/Chrome and Windows or Linux; check keyboard, audio and compact layout.
- At least five invited testers, two runs each, record qualitative feedback and fix all blocking crashes or progression errors before public release.
- Review distribution rights for the code and text; runtime artwork consists of original Canvas and SVG illustrations, synthesized audio. Legacy images are excluded from the ZIP. This is not a legal clearance.
- No change to mobile project. Use integration PR against master after review; do not reset master or overwrite mobile work.
- Distribute ZIP privately to invited testers; no public deployment or automated issue upload. A ZIP is not an access-controlled hosted game.

## Developer commands
`npm run check && npm test`
`python3 scripts/package-web-beta.py`
CI generates the ZIP and browser diagnostic artifacts. Synthetic stress scene starts with 240 enemies, 250 player projectiles and 80 hazard zones; frame measurements are observations, not a guarantee of real-world FPS. No gameplay balance changes.
