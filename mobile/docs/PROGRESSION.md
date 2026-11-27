# Progression, academy and economy
Status: v0.1. All pacing and reward values are proposed.

## Progression dimensions
Run level: temporary upgrades only. Character level: permanent XP and mastery. Evolutionary tier: generation capacity, increased via fusion; difficulty is independent. Account progression unlocks choices, never large universal damage multipliers. Character death in combat is not permanent. Retirement is exclusively a confirmed fusion outcome.

## XP, maturity and training
Initial maturity levels I=10, II=15, III=20, future IV=25/V=30. Candidate active training times I=20–40 min, II=30–60, III=45–90. Tune using playtest, not imposed grind. Use configurable monotone XP threshold table, independent of run XP. Define XP from survival time, kills, encounter completion and first-clear milestones; cap repetitive trivial farming and ensure a failed but meaningful run earns some XP. No offline timed training.
Select active wizard and up to N distinct inactive apprentices before run; POC N=1, MVP N=3. Award active 100% persistent XP, each apprentice 25% (initial hypothesis), no reduction to active reward. Snapshot training group when run starts; retired/invalid IDs rejected. Apprentices can mature but receive no active-only mastery, proficiency or achievements. Level capped; no negative XP. Training past maturity optional; mastery may bias a related inheritance weight in a future version, not required for POC. Never gate viable fusion on mastering every character.

## Acquisition
Founders generated from context-weighted pools. Dungeon rewards: first expedition guarantees a second wizard or enough essence for one; rescues/boss clears can grant targeted ancestry/affinity. Summoning: lesser general pool, elemental biased pool, ancestral biased pool; later greater summons yield higher tiers to avoid exponential grind. All costs from play-earned resources. Ritual preview states target bias and cost, not hidden probabilities. Generate and debit atomically. Guarantee useful baseline, no paid random acquisition. Onboarding should make first fusion achievable quickly and explain archive. Keep new bloodlines available to prevent roster exhaustion.

## Fusion economy
Same-tier mature pair, guaranteed next-tier offspring, permanently retire parents. Optional catalyst. No functional gear, no failed fusion, no cooldown timers. Lock/favorite confirmation and explicit irreversible consent. Parent archive stays accessible. Never allow active wizard or apprentice reserved by a run to fuse; release reservation on resolved run. See GENETICS for algorithm.
A tier T descendant from only tier I founders consumes 2^(T-1) founders and 2^(T-1)-1 fusion transactions. Sequential training effort sum over i=1..T-1 of 2^(T-i)*time_i, ignoring acquisition. With 30/45/60/90 min per tier, tier V requires 16 founders and 21 hours of sequential training (480+360+240+180=1260 min). Shared XP and higher-tier rewards reduce wall-clock effort; measure through simulations and actual play. Do not require large roster churn. Start at max tier III for MVP, cap explicitly. Target first fusion within first 60–90 min of active play as a hypothesis.

## Resources
Essence: common earned resource spent on summons. Knowledge: discovery/academy unlocks (consider flags rather than spendable currency). Catalysts: discrete items, one per fusion, earned from environments. POC only essence, no catalysts. MVP three catalysts: affinity crystal biases core inheritance; chaos fragment increases mutation chance; prismatic shard biases compatible hybrid expression. No gold until justified. Define costs/rewards in data registry; prevent negative balances, overflow and duplicate claims. No equipment inventory.
Account unlocks: additional apprentice slots, rituals, dungeons, difficulties, cosmetics and journal hints. Records by difficulty/mode/tier, not forced difficulty scaling.

## Collection and archive
Active roster supports filtering, sorting, renaming, favorite/lock, selected wizard, apprentices. Archive contains original IDs, genome and phenotype snapshot, final training/mastery, records, parents and retired timestamp. Archived records immutable except display metadata if allowed; never combat/fusion eligible. Ancestry is a DAG, distinct parents, earlier generation, no cycles; descendants retain links. Store lineage nodes once and traverse lazily. Avoid deleting archive entries required by descendants. Grimoire records discoveries and observed fusions, not theoretical probabilities. Roster size/overflow policy open: POC unlimited local roster; later test UI and storage, never silently discard reward.

## Run rewards and interruption
At run start create unique run ID, snapshot difficulty and active/apprentice IDs. At finish calculate reward receipt from authoritative local simulation outcome, commit exactly once, then show summary. On reload replay display, never grant again. POC keep failure XP and earned essence, character rewards on completed rescue/boss objectives; later tune extraction reward. Save checkpoint for interrupted active run; if unrecoverable, offer explicit discard/recovery policy, never silently corrupt roster.
 
## Validation
Track first summon/fusion time, XP per minute, run completion rate, perceived grind, roster diversity, lock usage, retirement regret, catalyst use and repeated combinations. Simulate 100+ sessions under alternative player policies; compare time-to-tier, not just XP curves. Test capped XP, multiple levels, shared XP snapshot, locked/archived invalid inputs, reward idempotency, insufficient essence, crash during fusion/summon, ancestry preservation. Balance metrics local developer tools by default, no telemetry collection without separate decision.
