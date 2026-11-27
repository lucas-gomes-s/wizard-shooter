# Technical architecture
Status: v0.1. Godot 4 stable, typed GDScript proposed. Engine minor version to be pinned at setup.

## Principles
Native mobile-first, offline, one process. Use Godot scene tree, Resources, signals, input and renderer; avoid reinventing engine. Pure domain logic in RefCounted/typed data classes without Node, scene or UI dependencies. Content Resources treated immutable; runtime instances separate. Explicit services own state; no mutable global combat state. No backend, functional equipment, networking, paid random purchase or ads. Mobile app lifecycle is first-class.

## Project layout (future)
mobile/
  project.godot
  core/ (rng, IDs, result types, config)
  domain/genetics/ (genome, expression, generator, rules, validation)
  domain/characters/ (records, training, phenotype)
  domain/fusion/ (eligibility, pure engine, transaction)
  domain/collection/ (roster, archive, discovery)
  domain/progression/ (XP, rewards, economy, summoning)
  gameplay/ (session, world, combat, ability, AI, encounters, pickups)
  presentation/ (scenes, UI, touch input, sprite composer)
  content/ (typed resource definitions and .tres registries)
  persistence/ (save codec, store, migrations, transaction receipts)
  platform/ (lifecycle, haptics, safe areas)
  assets/ (original/licensed textures, audio, fonts)
  tests/ (unit, integration, statistical, smoke)
  tools/ (headless sim, balance reports, asset validator)
  docs/
Only documentation exists now. Root legacy game stays untouched. Keep Godot .godot cache, export builds, credentials and signing secrets out of Git.

## Dependency direction
UI/scenes -> application use cases -> domain services -> immutable definitions/core. Persistence implements store interface; domain does not read files. Combat reads phenotype snapshot, emits run outcome. Academy reward service consumes outcome, updates profile. Expression engine produces shared functional + visual phenotype; sprite composer cannot re-roll genetics. Signals for presentation notifications; synchronous direct calls for ordered domain updates. Avoid global event bus for authoritative mutations. Autoloads only app router, profile service, settings/audio if needed; per-run state belongs to GameSession.

## Data contracts
Stable opaque IDs (UUID or deterministic transaction-derived ID, never array index).
Genome: schema_version, ruleset_version, seed, ancestry weights, allele pairs, numeric genes, cosmetic seed.
Phenotype: expression_version, content_version, expressed trait IDs, affinities, body tags, base stats, ability IDs, visual descriptor, complexity/power metadata.
CharacterRecord: ID, name, tier, level, XP, mastery, genome, phenotype snapshot, parent IDs, status ACTIVE/RETIRED, locked, timestamps. Archive retains retired record, not a duplicate editable character.
Profile: schema_version, revision, content_version, active roster IDs, archived IDs or status index, records by ID, essence, catalysts, unlock flags, Grimoire, run reservations, reward/fusion/summon receipts. All references validated.
RunSnapshot: run_id, character ID, frozen stats/phenotype, training IDs, mode, difficulty, seed/streams, simulation tick, entities, timers, run XP, upgrades, outcome state. May implement deterministic checkpoint as serialized state, not replay-only. Version separately; preserve profile if run checkpoint incompatible.
Content: typed Resources with stable ID, version, validation metadata; registry resolves cross references at load. JSON export optional for analysis. Store durable resolved values alongside IDs when necessary to preserve old character identity.

## Service contracts (conceptual)
CharacterGenerator.generate(context, seed, rules) -> CharacterDraft
ExpressionEngine.resolve(genome, tier, registry) -> Phenotype
FusionEngine.preview(parentA, parentB, discoveries) -> QualitativeHints
FusionEngine.generate(parentA, parentB, catalyst, seed, rules) -> CharacterDraft
FusionUseCase.execute(parent_ids, catalyst_id, expected_profile_revision, transaction_id) -> FusionReceipt
SummonUseCase.execute(ritual_id, expected_revision, transaction_id) -> SummonReceipt
TrainingService.apply_xp(record, amount) -> updated record
RewardUseCase.apply(run_outcome, run_id) -> RewardReceipt (idempotent)
AbilityCompiler.compile(phenotype, registry) -> validated runtime specs
ProfileStore.load/commit(expected_revision, candidate_profile) -> Result
No side effects in pure generator/expression/fusion. Transaction use cases validate availability, reserve IDs, create complete candidate profile, validate invariants and commit before returning receipt. Retrying same transaction returns same receipt. Store seed and resolved result before reveal; stable ID and seed allocation across retries. UI cannot bypass use case validations.

## Persistence and lifecycle
Use local user:// profile storage; choose versioned JSON with explicit schema/validation for POC, no executable object deserialization. Serialize to temp, flush, verify checksum/schema, replace primary via platform-supported same-filesystem rename, retain last valid backup; test crash semantics on Android/iOS. If atomic rename guarantees insufficient, use journal or SQLite transaction with suitable plugin. Single writer, revision checks, transaction IDs, no partial parent retirement. Recovery chooses latest valid committed revision; pending uncommitted operation either resumes deterministically or rolls back before reveal. No cloud saves initially. Provide user export/import later; privacy local.
On background/focus loss pause simulation, clear input, checkpoint as time permits; periodic checkpoints protect against OS kill without callback. Save settings separately. Startup verifies/migrates schema, never overwrite unknown/newer versions. Migration fixtures for previous schema/content versions and phenotype preservation. No promises of anti-cheat for offline saves.

## Scenes
AppRouter -> Academy/Collection/DungeonSelect/Fusion/Grimoire/Run/Results.
GameSession Node: World (Dungeon, Player, Enemies, Projectiles, Pickups, VFX), Systems (director, combat, progression), CanvasLayer (HUD, touch controls, pause/upgrade). Explicit state machine, one authoritative simulation tick. Character scene components for health, movement, ability controller; avoid deep inheritance; dense entities may use lightweight arrays after profiling. Resource definitions never carry mutable cooldowns. HUD observes snapshots/signals.

## Mobile and distribution
Portrait, responsive viewport, safe area, optional 30 FPS and reduced effects, background resume, offline. Compatibility renderer first; benchmark Mobile renderer if needed. Pin Godot version/export templates, Android SDK/JDK and Xcode requirements against official docs at implementation. Android device smoke test first; iOS build requires macOS/Xcode and signing. Do not commit keys, provisioning profiles or secrets. Exact store requirements verify near release. Original site should still serve index.html without changes.

## Quality and CI
Headless Godot runner (native test harness or selected pinned framework) with deterministic seed fixtures and nonzero exit on failures. CI path filter mobile/**, import project headless, run unit/integration and manifest tests; nightly/optional larger statistical simulations. Reports machine-readable JSON/CSV; baseline budgets not fabricated. Android debug artifact once export tooling configured. iOS build optional with appropriate runner/signing. No network requirement during tests beyond dependencies. Tests: pure generation, expression, mutation, validation, distribution, genealogy DAG, XP thresholds, reward/fusion idempotency, crash injection, schema migrations, missing assets, combat ordering, touch and lifecycle. Test on physical phone. Profile before optimizing; benchmark frame-time and memory with representative builds. See COMBAT for targets.

## ADR candidates
001 Godot/GDScript vs web/native; 002 genotype vs phenotype snapshot; 003 domain/scene separation; 004 deterministic versioned RNG (engine RNG not assumed stable across versions; implement/pin algorithm and test vectors); 005 persistence strategy and recovery semantics; 006 no functional equipment; 007 genetic privacy UX; 008 tier complexity and independent difficulty. Record tradeoffs and accepted alternatives before implementation. 
