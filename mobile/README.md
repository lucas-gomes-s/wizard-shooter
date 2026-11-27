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

Design specification v0.1, 2026-11-27. No Godot implementation or generated art exists yet. Numeric parameters are hypotheses, not validated balance. Decisions labeled established reflect the agreed design; defaults and open questions can change. Work in this directory only; do not import legacy assets until their licenses are verified. No ads, paid random acquisition, backend, multiplayer or functional equipment in initial scope.

## Development

Target Godot 4 stable, statically typed GDScript, Android first for physical testing, iOS compatible. Pin the exact engine version when creating project.godot; record setup and export instructions then. See roadmap for the first runnable vertical slice. 
