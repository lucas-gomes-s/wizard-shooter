# Art and procedural appearance
Status: v0.1; art dimensions and style guidelines provisional.

## Direction
Dark fantasy pixel art: gothic dungeon silhouettes, restrained environment palettes, striking spell effects, readable anatomy and absurd wizard humor. Strong functional/aesthetic correlation is a requirement. Art references are inspiration only; create original or explicitly licensed assets. Legacy images have no verified licenses and must not ship in mobile until audited.

## Visual grammar
Species/body: silhouette and proportions. Stoneborn bulky, cracked stone, mineral motifs; Fae slender, delicate wing shapes; Human conventional anatomy (MVP). Affinity: hue plus rune shape, particle shape, icon and sound. Fire embers/flame, Ice crystals/snowflake, Steam mist/pressure rings. Constitution changes silhouette, but combat collider is an explicit gameplay parameter not raw sprite bounds. Talents affect staff geometry/runes/casting poses. Mutations have dedicated anatomical layer plus corresponding effect. Neutral pigmentation and ornaments may vary without stats. Do not let cosmetic skins conceal important indicators.

## Asset contract
Initial target 64x64 character frame, 128x128 portraits, 32x32 environment tiles. Four directions (north/south/east/west), idle/walk/cast/hit/death; POC may use one/two directions and minimal animation to validate composition. Standard feet origin at bottom center; define anchor metadata for head, shoulders, hands, back, aura. Each body rig has supported slots and per-frame anchors. Layers: shadow, rear appendages, base body, clothing, front anatomy, headwear, staff, aura/VFX (explicit z order). Larger wings extend bounds without changing origin. Use nearest-neighbor textures, integer scaling where feasible, atlas import settings and consistent animation timing. Define palette index masks or shaders; avoid recoloring UI/text and preserve accessibility.

## Manifest and composer
Asset manifest record: id, source_path, license/provenance, rig_id, slot, directions, animations, frame dimensions/count/timing, anchors, draw order, palette masks, compatible body tags, fallback asset ID. Validate IDs and actual imported textures. Trait definitions emit visual layer IDs and functional effects together; expression resolves compatible rig/slot before rendering. SpriteComposer receives phenotype visual descriptor, not hidden genome. For archive/collection, cache composed portrait keyed by descriptor + content version. Live character uses synchronized layers or baked frames after profiling; avoid allocating textures every frame. Stable phenotype snapshot and asset IDs across releases; migrate with explicit mappings. Missing asset uses compatible placeholder in development, fails release validation.

## POC asset set
Two distinct body rigs, Fire/Ice/Steam palettes and symbols, two staff shapes, two robes, crystal-wing and living-flame overlays, three enemy silhouettes and one boss, basic projectile and manual skill VFX, one dungeon tileset, joystick/icons. Test hybrid Stoneborn body + Fae appendage. Character sizes must remain legible at actual phone gameplay scale. Do not create dozens of unneeded variants before hybrid pipeline works.

## UI
Portrait safe area; contrast strong enough for outdoor/mobile use, distinguish rarity and elements using text/icon not only color. Collection card shows sprite, name, tier, maturity and affinity. Fusion chamber shows parents clearly and confirmation; no deceptive near-miss animation. Archive and Grimoire show lineage, discovery and source records. Haptic/audio feedback optional; reduced flashes, screen shake and effects settings. Localize text separately from texture.

## Workflow and acceptance
Source files organized separately from exports; track artist/license/attribution. Automated manifest validation checks path, dimensions, frame lengths, anchors, slot compatibility, palette IDs and fallback coverage. Generate contact sheets of all POC legal combinations and fixed seed sample across later content; inspect clipping, silhouettes, palette contrast and functional cues. Test animation alignment, portraits, old saved appearances, and device readability. Asset production remains a blocker for visual polish, not for pure genetics tests.
