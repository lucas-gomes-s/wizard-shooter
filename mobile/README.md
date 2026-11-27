# Wizard Shooter: mobile edition

Design-first successor to the 2021 browser game. The original HTML, CSS, JavaScript and assets remain at repository root, untouched. This folder is the independent future Godot project root.

## Vision

An offline portrait-oriented action survival roguelite in which the character is the build. Acquire procedurally generated wizards, train them through dungeon expeditions and endless survival, fuse mature characters into higher-tier descendants, and preserve their ancestry. Genetics determines both combat and appearance. The player controls one wizard at a time; basic attacks are automatic and special abilities are manually activated.

## Start here

| Document | Purpose |
| --- | --- |
| [Game design](docs/GAME_DESIGN.md) | Player experience, decisions, scope |
| [Genetics](docs/GENETICS.md) | Genome, inheritance, expression and fusion |
| [Combat](docs/COMBAT.md) | Mobile control, ability composition, encounter simulation |
| [Progression](docs/PROGRESSION.md) | Training, summoning, fusion economy, archive |
| [Art pipeline](docs/ART_PIPELINE.md) | Pixel art, anatomy and phenotype rendering |
| [Architecture](docs/ARCHITECTURE.md) | Godot boundaries, schemas, persistence and testing |
| [Roadmap](docs/ROADMAP.md) | Milestones and acceptance criteria |

## Status

Design specification v0.1, 2026-11-27. The first Python/Pillow procedural sprite prototype and generated assets are implemented; a first Godot source prototype now exists. The first Godot build and persistence recovery tests passed automated validation; physical device testing remains pending. Numeric parameters are hypotheses, not validated balance. Decisions labeled established reflect the agreed design; defaults and open questions can change. Work in this directory only; do not import legacy assets until their licenses are verified. No ads, paid random acquisition, backend, multiplayer or functional equipment in initial scope.

## Sprite prototype

[Art tool and instructions](tools/art/README.md) · [Generated population and reusable layers](assets/characters/prototype/). Run the generator and tests with Python 3.10+ and Pillow. The visual sample is not the full genetics engine.

## First Godot prototype

[Implementation and run instructions](IMPLEMENTATION.md). Open project.godot in Godot 4.5.1, press F5, and test academy selection, combat, summoning, shared XP and fusion. Completed progression is saved locally in two checksummed snapshots; unfinished runs are not resumed yet. Headless tests: tests/smoke.gd and tests/persistence.gd. Check CI status for the current commit.

## Development

Target Godot 4 stable, statically typed GDScript, Android first for physical testing, iOS compatible. The initial baseline is Godot 4.5.1 stable. Android Alpha export preset and CI artifact build are configured; check the current Actions run for an APK. Device testing is still required. See roadmap for the first runnable vertical slice. 
