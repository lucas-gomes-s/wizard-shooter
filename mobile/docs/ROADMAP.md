# Implementation roadmap
Status: initial source prototype implemented; M0–M3 are partially implemented but not yet verified in Godot. See [IMPLEMENTATION.md](../IMPLEMENTATION.md) for current scope and known gaps. No milestone is marked complete unless implemented and verified.

## M0: repository and tooling
Create Godot project in mobile/ only; pin stable engine and templates; typed GDScript, ignore generated files, README setup. Create headless test runner, lint/style conventions and CI for mobile path. Preserve legacy root. Acceptance: clean clone imports and runs a minimal portrait scene, headless test succeeds, legacy tree unchanged. Record exact dependencies and Android export setup.

## M1: genetics prototype (first technical priority)
Implement content registry, schema types, stable RNG and fixture tests; two species/two affinities, tier I/II, four passives and two mutation definitions; founder generator, hidden loci, dominance, hybrid expression and deterministic compatibility repair; pure fusion engine. Write headless population tool and distribution report. Implement placeholder visual descriptors, inspect sample contact sheet. Acceptance: 100k valid generated/fused records, deterministic vectors, ancestry sum, symmetry, no invalid builds, report effective distributions/repair rate. No UI or combat required. 
## M2: mobile combat prototype
Portrait scene, joystick, camera, auto cast/manual skill, movement, damage, three enemies, finite timed encounter and boss, basic endless wave director, run upgrades and result state. Instantiate generated phenotype; demonstrate two distinct playstyles and one hybrid. Acceptance: debug APK on physical Android, touch and background tests, no frame-time-dependent cooldowns, test death/restart, playable without server. Profile before expanding.
## M3: end-to-end collection/fusion
Profile persistence and recovery, roster, active selection, training group, reward receipt, first acquisition, summoning, eligibility, confirmation, retirement/archive, lineage, journal, child playable. Basic modular appearance. Acceptance: start fresh, acquire two distinct founders, mature both through play (test acceleration in debug), fuse, observe archived parents and playable tier II descendant, restart app and verify exact state; crash injection at transaction boundaries; no duplicate grants; favorite lock. Test first fusion pacing with users.
## M4: MVP expansion
Third species, four primary/three hybrid affinities, three tiers, 12 traits, six mutations, eight basic/six manual/three ultimate spells, nine original enemy archetypes, one or two bosses, three apprentices, three rituals, three catalysts. Counts provisional; only expand proven mechanics. Finite and endless reward differences, difficulty independent of tier, accessibility, audio, settings, consistent licensed art and journal discovery. Acceptance: all valid combinations render, headless combat comparisons by tier/difficulty, no tier blanket dominance, measured 60 FPS target and 30 FPS fallback on chosen phone, stable saves and no frustrating grind in playtest.
## M5: release readiness
Polish controls, tutorial, suspend/resume, battery/thermal tests, device matrix, signing and store assets. Android closed testing and production release only after verifying current store policy; iOS/TestFlight after validation. Verify asset licenses and choose software license with owner. Privacy policy if needed, no paid random mechanics. Acceptance: reproducible builds, release checklist and store requirements verified. More tiers/dungeons, hidden gene complexity, cosmetics and cloud saves deferred until design validated.

## Priority backlog
P0: decide exact RNG and fixture vectors; trait/locus schema; expression compatibility; atomic save recovery; touch and physical test; first fusion loop.
P1: headless balance simulator; asset manifest; archive/grimoire; shared XP; difficulty and encounter configs.
P2: advanced effects/transformations; additional dungeons; expanded discovery and optional account unlocks.
Non-goals: multiplayer, backend, equipment loot, gacha, procedural room generation before timed arena works, full genetic biology, arbitrary mod scripting, premature ECS/C++ optimization.

## Definition of done
Acceptance criteria tested; new content IDs validated; docs updated; no legacy root changes; no generated build/cache/secrets; deterministic fixtures maintained; physical device results recorded for mobile behavior; failed tests or blockers explicitly documented. Balance changes include before/after simulation or playtest evidence where practical.

## Open questions to resolve at milestone boundaries
M0: engine minor version, reference phone, test framework. M1: allele dominance table, mutation and hybrid probabilities, power budget, fallback strategy. M2: auto targeting, special activation, camera zoom, run duration. M3: XP and costs, rewards on defeat, archive/roster limits, save recovery. M4: difficulty unlocks, advanced ability count, art asset license and authoring workflow. M5: distribution and monetization. 
