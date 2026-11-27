# First playable prototype

Target Godot 4.5.1 stable (explicit baseline, not a claim that this is the newest engine). Open mobile/project.godot in the editor and press F6/F5 (use F5 for main scene). CLI from repository root:

    godot --editor --path mobile
    godot --headless --path mobile --import
    godot --headless --path mobile --script tests/smoke.gd

Use the actual executable name/path on your OS (on macOS it may be /Applications/Godot.app/Contents/MacOS/Godot).

Controls: WASD/arrows or drag the bottom-left touch area; Space or CAST for the special; pause button; pick an upgrade when prompted. Choose active wizard and partner in Academy. Partner earns 25% XP. Dungeon is deliberately accelerated to a boss at 90 seconds. Endless offers extraction after 30 seconds. Difficulty I–III is independent of character tier. Defeat still yields training XP; victory yields a wizard and essence. Summon costs 10 essence. Two mature tier I characters (40 XP each) can fuse after explicit confirmation; parents retire into the session archive. Tier II is the current cap.

Implemented: portrait project, pure seeded genetics prototype (two species, two affinities, mixed body and steam, hidden allele pairs, two possible mutations), phenotype stats, atlas layer composition, fixed-step auto-attacks, manual burst, burn/slow, three enemy types plus simple dragon boss, difficulty, finite/endless, three run upgrades, in-memory collection and fusion, shared XP, reward idempotency.

Limitations: no durable save/checkpoint or archival UI, no Android export presets or device validation, no final art for enemies, no directional animation, no full trait/catalyst system, no mature-level curve, no graphical discovery journal. Roster resets when app exits. The atlas has one missing Fae/Steam robe variant, mapped to cosmetic robe 0. Hats/robes/staff shapes are neutral cosmetic genes for now; mutation abilities and stats are simplified. Combat uses a fixed arena with simple collision and a 120-enemy cap. Balance numbers and 90s encounter are test defaults. Genetic RNG is an explicit small integer algorithm, not yet statistically qualified. The 1000-sample smoke script is not the planned 100k statistical report.

No engine or Android SDK is installed in the authoring environment. The code has not been executed in Godot here; run import + smoke before treating any milestone as complete. The original browser game is unchanged.
