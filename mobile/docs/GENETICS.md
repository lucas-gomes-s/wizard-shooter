# Genetics and fusion
Status: v0.1. All numeric examples below are provisional. Fictional genetics, not a biological simulator.

## Goals and invariants
Genotype is private, persistent and inherited; phenotype is the resolved appearance and combat capabilities, visible to the player. Training state and run state are separate. The same genome, expression version and content registry must produce the same resolved phenotype. A gene that conveys visible anatomy or magical power must define both effects in one content record. Neutral cosmetic variation is allowed; functional visual cues cannot be overwritten by cosmetics. Every valid phenotype is playable, renderable and within a tier-specific complexity and power budget. No random outcome depends on rendering or frame rate.

## Data model
Genome: schema_version, ruleset_version, founder_seed, ancestry (species ID -> integer weight, sum 10000), loci (stable locus ID -> allele pair), quantitative genes (bounded fixed-point values), cosmetic seed. Each allele has stable content ID; diploid pairs are fictional and need not correspond to real DNA. Retain allele provenance if useful for genealogy. Character record includes id, genome, resolved phenotype snapshot, level, XP, mastery, tier, status, parents, created_at, name, lock. See ARCHITECTURE.

Loci for POC: body, locomotion, magical core, casting talent, constitution, optional anatomical mutation. Each locus has two allele slots (including explicit neutral allele). Species ancestry is genealogical expectation, NOT measured expression: offspring gets average of parents' ancestry, with deterministic rounding and remainder assignment by sorted species ID. Founders start with 10000 for one species. Anatomy is determined by expressed loci, not ancestry percentages. Later species hybrids need no new species class.

TraitDefinition: id, locus, min_tier, allele_dominance, eligible_ancestry, prerequisites, exclusions, functional effects (stats, ability IDs, tags, triggers), visual effects (slot, asset ID, anchors, palette, animation variants), complexity cost, power cost, fallback ID. Stable IDs, explicit neutral and fallback alleles. Traits may be dormant if inaccessible at current tier. Never silently discard genotype during expression. Define deterministic precedence for competing expression rules.

## Founder generation
Use a versioned RNG, independent streams for ancestry, functional alleles and neutral appearance. Choose weighted species and affinity using acquisition context (ritual or dungeon). Draw two alleles per locus from curated pools, sample quantitative genes within bounded ranges, assign name/seed and resolve phenotype. Reject or repair invalid results deterministically with bounded retries; guaranteed safe template fallback. Do not reroll after viewing. Persist exact chosen genome, not seed alone.

## Expression
1. Resolve expressed allele(s) in stable locus order. POC uses explicit dominance rank and deterministic tie-break; codominance only when a registered hybrid rule applies.
2. Resolve anatomy first, then affinity, stats, talent, mutations and derived synergies. Example stone body + fae wing allele may express crystal wings if a compatibility rule exists; otherwise suppress wing expression and retain allele.
3. Apply tier capacity and exclusions. Tier I: one primary affinity, one passive, no advanced mutation; II: up to two affinities, two passives, one mutation; III: two affinities, three passives, one mutation plus conditional synergy and optional ultimate. Additional tiers deferred.
4. Compute stats from baseline, expressed modifiers and training; enforce positive health, speed and cast interval. Compile at least one auto and one manual ability. Resolve slot assets, palette and anchors using identical phenotype tags.
5. Validate ability graph, anatomical combination, asset coverage and power budget. Explicit fallback for incompatible combinations; fallback must change both visuals and functionality together. Record developer diagnostics; hide raw allele data in player UI.
6. Store expression/content version and resolved phenotype snapshot. Existing characters retain appearance and identity across updates; intentional balance migrations are explicit, tested and communicated.

## Fusion algorithm
Eligibility: distinct active unlocked characters, equal tier, both mature, neither currently in a run or reserved by another transaction, next tier available. Validate catalyst availability. Parents are immutable inputs to pure FusionEngine; no writes until result committed.
- Sort parent IDs to canonicalize order. Allocate a unique transaction seed before reveal. Derive substreams by locus and purpose.
- For each diploid locus sample one allele from each parent's pair (50/50 baseline). Optional catalyst biases a documented internal weight, not certainty. Do not inherit acquired XP or run upgrades.
- Recombine compatible expressed core alleles into hybrid phenotype via registered rules; preserve raw parental alleles. Example Fire/Ice may express Fire, Ice or Steam depending on dominance and hybrid gate.
- For each eligible locus, mutation roll may replace one allele with a weighted eligible allele. Starting hypothesis: 5% per eligible locus; cap at one mutation event per POC fusion. New tier unlocks expression capacity, may allow a new locus sampled from eligible tier pool. Mutation cannot violate tier/anatomy restrictions.
- Numeric genes: midpoint of parental values plus bounded zero-mean jitter (e.g. Gaussian sigma 8 on 0–100 scale); clamp or use truncated sampling consistently. Use fixed-point quantization and document bias near bounds.
- Resolve phenotype, validate, bounded resample only invalid components (max 8 attempts, provisional), deterministic repair/fallback if still invalid. Never fail valid fusion due to generated invalid child. Track effective outcome distribution after validation, not just configured probabilities.
- Child starts level 1, XP 0, mastery 0, next tier, new stable ID and both parent IDs. On confirmation atomically retire parents, debit catalyst, insert child, update archive/journal; commit before reveal. Recover and show same child after interruption. No reroll on reload.

## Hidden genetics and discovery
Visible: current stats, active abilities, species/affinity expression, tier, mastery, ancestry links and effects; no raw loci, recessive alleles or exact probability tables. Preview shows qualitative hints based on known observations, not exact child. Journal stores observed combinations, discovery flags and counts separately from actual probabilities. A discovered association is evidence, not a guarantee. No paid genetic reveal. Internal debugging can inspect full genomes in developer builds only. Hidden is a UX constraint, not security for offline saves.

## Power and complexity
Distinguish normalized combat power from complexity. Avoid cumulative tier damage multipliers. Define per-effect cost and constraint registry, cap trigger depth, cooldown floors, projectile multiplicity, sustained defense and mobility. Budget initial builds near a common baseline across tiers, permit specialization and drawbacks. Cost model is heuristic; validate via combat benchmarks and human play. Avoid selection pressure toward all-purpose universally dominant builds. Recessive genes may reappear in later lineages.

## Initial content hypothesis
Stoneborn: high defense, low mobility, stone body. Fae: fast, fragile, slender body/wings. Fire: burns; Ice: slow and shatter; Steam: obscuring/area bursts, no automatic power advantage. Mutations: crystal wings (dash tradeoff), living flame (trail and vulnerability). Four passives: quick casting, resilient, nimble, glass cannon. Each needs visual mapping, cost, eligibility and tests. MVP adds Human, Earth, Lightning, Magma and Plasma.

## Statistical acceptance
Run headless 100k founder/fusion samples across fixed seeds; report distributions by locus, expression, ancestry, tier and parent pairing; compare simple Mendelian loci to expected binomial confidence intervals; record repair/fallback rate (target <1%, investigate any violation). All outcomes pass schema, playability and asset validation. Test parent swap symmetry, repeatability, distinct IDs, hidden recessive expression, catalyst direction, ancestry sum, impossible combinations, no retired reuse, no reroll. Simulate multiple generations with random and selection policies; report diversity/entropy and loss of rare traits. No promise of exact balance until playtest.
