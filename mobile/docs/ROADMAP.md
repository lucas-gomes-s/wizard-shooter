# Wizard Shooter Mobile: gameplay-first product roadmap

Revised 2026-11-27. This replaces the initial implementation milestone sequence with a product roadmap. Current implementation and technical limitations: [IMPLEMENTATION.md](../IMPLEMENTATION.md). Prior technical acceptance criteria remain in the [foundation checklist](#foundation-checklist). Numbers and prices are hypotheses, not measured results or deadlines. The browser game is a separate product; learned magical schools belong there, not here.

## Product thesis and guardrails

Make the minute-to-minute survival game enjoyable without purchases or permanent rewards. Make the collection, lineage, discovery and fusion loop worth returning to. Only then introduce optional commercial features, alternating gameplay and commercial increments. Keep offline play, one active wizard, genetically determined affinities and abilities, probabilistic inheritance, retired parents, phenotype-specific run upgrades and independent difficulty.

- Core play, first fusion, all base affinities/species, and normal progression must remain enjoyable for non-paying, offline players.
- Monetization is optional, transparent and additive. No forced ads, energy gates, artificial training timers, paid random summons/fusion rerolls, paid mutation odds, or exclusive superior genetics in the initial business model.
- Paid cosmetics are separate overrides, never alleles or power stats. Preserve functional silhouettes, readable elements, mutations and combat telegraphs. Earnable cosmetics should be meaningful, not deliberately inferior.
- Do not sell a solution to a problem introduced to pressure payment. No commercial feature is a reason to make free progression worse.
- Prefer direct-priced permanent products. Prices, ad rewards and capacity rules are proposals pending user tests. Avoid premium currency and subscriptions until there is a demonstrated need.
- No mandatory account or online connection for core gameplay. Paid entitlement recovery can require connectivity; offline access to previously verified permanent ownership should not be arbitrarily revoked by connectivity failures.

## Current baseline

Implemented prototype: portrait Godot 4.5.1; infinite seeded dungeon, pillars, treasure/shrines/guarded caches; Fire/Ice/Steam combat, 4 inherited talents, 2 species plus hybrid, 2 mutation variants, 22 run upgrades; Tier I/II collection, summoning, shared training, irreversible fusion and archive; two-slot checksummed local saves; Android debug APK pipeline. Headless tests passed for character-specific upgrades (commit 16e9015). Device behavior, balance, tutorial, retention, stable signing, commercial readiness and 100k population qualification remain unverified. The 90s boss is a test fixture, not the target run duration.

## Continuous enabling track (P0, in parallel with gameplay)

Keep this track small; no production billing SDK or backend until Phase 7.
- Stable alpha signing via owner-controlled key kept outside public repo, separate production upload key / Play App Signing, version code strategy, verify same-key upgrade on phone. Do not repurpose public debug key for production. Decide production package ID before Play registration. Generate prerelease APK with explicit version, checksums and release notes; preserve old downloads. If changing application ID, provide save migration path.
- Save export/import with validated schema/checksum, rollback and explicit overwrite confirmation; distinguish local progression from verified paid entitlements, never trust imported purchase flags. Test interrupted writes, corrupt input, and upgrade compatibility. Mid-run checkpoint/resume after combat model stabilizes.
- Record device test notes: reference Android hardware, 60 FPS target / 30 FPS fallback, touch, suspend/resume, heat/battery, UI clipping, loading. Add FPS/enemy/effect counters and optional replay seed/debug controls in development builds.
- Headless simulation harness using actual RunModel and seeded strategies (stationary, kiting, aggressive, exploration). Track alive time, kill/XP rate, damage, upgrades, victory, encounter completion and runtime cost. Run repeated seeds by affinity/body/difficulty and publish summary with uncertainty; use real playtest feedback to calibrate, not optimize bots alone.
- Local-only event schema initially: run start/end, death reason, level-up choices, tutorial, acquisition and first fusion. No remote tracking by default. Later opt-in analytics with minimal data and documented SDK behavior.
- Separate cosmetic ownership/equip state, product/reward interfaces, versioned content IDs and feature flags when their first use arrives. No speculative infrastructure, no secrets in source.

## Phase 1: make combat addictive (gameplay)

Purpose: skill, readable danger and meaningful builds; prioritize improving 3 existing affinities over adding many.
1. Enemy roles: spider web with clear slow zone; goblin swarm and spacing; orc charge with telegraph; skeleton/warlock ranged attack; armored enemy with counterplay; dragon windup, charge and breath patterns. Start with three new behaviors, not all possible enemy types. Add enemy attack cooldowns, hitboxes, status resistance, projectile budgets, offscreen attack rules, and difficulty pacing. Keep enemies threatening even when player is fast.
2. Combat feel: stronger spell VFX, impact flashes, sound, hit feedback, freeze/shatter visuals, readable danger vs player effects, motion/accessibility settings; better targeting through obstacles, crowd separation, responsive touch.
3. Director and progression: tune time-based difficulty, enemy composition, XP curve, level-up frequency and 6–10 minute initial expedition hypothesis, distinct boss clear vs endless extraction. Avoid unbounded multiplicative DPS; test upgrade synergies, failure reasons and alternative strategies. Short debug mode remains.
4. Balance harness and actual device runs. First benchmark existing builds before tuning. Prioritize 3–5 playtest sessions per iteration; record seed, build, difficulty, time, upgrades, and feedback.

Gate A (before expanding breadth): phone build installs over prior alpha without losing saves or has tested export/import; 3 distinct elemental strategies recognizable by testers, at least 3 enemy roles with counterplay, readable boss telegraphs, no blocking touch/save failures; early levels and choices create a satisfying first run. Proposed internal qualitative gate: at least 4 of 5 observed testers voluntarily start another run without a reward prompt. If missed, iterate combat, not monetize. Small sample is directional, not statistically representative.

## Phase 2: make breeding rewarding (gameplay)

Purpose: a player can understand, care about and plan a bloodline.
- Introduce first-run tutorial and a fast, guaranteed route to a second founder. Make first fusion reachable in approximately 30–60 min total normal play as a test hypothesis; compare against original 60–90 min proposal. Do not charge or gate this milestone with ads.
- Define clear maturity progression, training slots and essence sinks, rewards on defeat/extraction/victory. Avoid tedious repeat runs; use mastery objectives and exploration. Make partner choice sticky and explicit.
- Add one species (Human is a candidate) and one primary affinity (Lightning or Earth; choose after combat validation) with new delivery operators as needed. Validate combinations and visual differences before adding more. Build mutation and passive visual cues, meaningful dominance/inheritance, compatibility rules, and observed Grimoire hints. Preserve hidden raw alleles.
- Improve Academy sorting/filtering/favorites, side-by-side comparison, ancestry DAG, fusion preview/reveal; support intentional retirement/collection management without accidental loss.
- Run 100k founder/fusion statistical report; measure distributions, allele inheritance, rare expression, duplicate frequency, repair/fallback, power by body/affinity/tier. Update save migration fixtures and simulation.

Gate B: testers can independently explain affinity vs talent vs mutation and complete first fusion; child plays differently, parents remain archived, restore profile correctly. Initial target: >=80% first-run completion and >=25% of invited testers who have 7 days of access complete first fusion (report denominators). No obvious mandatory grind; keep learning before introducing ads.

## Phase 3: make the Academy personal (monetization foundation, free first)

Purpose: prove people value customization before asking them to pay.
- Add cosmetic catalog with stable IDs, unlock sources, equipped overlays and preview. Use separate slot for hat/robe/staff decoration, non-functional aura, crest, banner and academy theme. Enforce visible phenotype/mutation and combat clarity, including accessibility. Cosmetic save migration and ownership tests.
- Provide a small free set: base theme, 2–3 alternate themes or cosmetic collections, earnable via achievements, exploration and fusion milestones. Allow player/bloodline naming and decorative lineage presentation.
- Define mock entitlement/product catalog and local test store, including owned, locked, restore and unavailable states. No real purchases, ads or commercial SDK yet. User test whether players choose to customize and what they would value; do not conflate unlock use with willingness to pay.
- Reserve separate cosmetic-only supporter pack and permanent themed collections; no premium random draw or essence sale.

Gate C: customization is used voluntarily, ownership/equip survives restart and save migration, functional genetics remain legible, mock flows cannot alter stats or create paid ownership by import. If low engagement, improve free customization before expanding store.

## Phase 4: make the world worth exploring (gameplay)

- Give dungeon biomes recognizable rules, enemies, tile palette and objects, not just cosmetic reskins. Start with a second biome plus one new boss, then expand after validation.
- Add finite objectives (rescue, defeat guardian, clear shrine), meaningful risk/reward detours, rare encounter types, extraction choices, objective/compass UI. Endless remains unrestricted. Make exploration matter to acquisition and collection.
- Improve distinct encounter layouts, limited environmental hazards, treasure variations, safe spawning, deterministic seeds and budgets. Test all biome/affinity combinations and performance; keep core campaign free.
- Define expansion content boundaries with explicit product IDs only where useful. Future paid expansions may add complete known content packs, but cannot create a mandatory purchase for core progression or dominant builds.

Gate D: players recognize two distinct biomes and choose different routes/strategies; new boss is readable, difficulty remains independent of tier, no dead ends or uncontrolled memory growth. Test free campaign completeness.

## Phase 5: introduce optional rewards (monetization foundation, simulated)

- Implement RewardService and AdService adapter with fake success, cancel, unavailable, timeout, duplicate, background and failure results. No ad SDK or real ad traffic yet. Keep game paused while a reward screen is active; grant only after verified completion, never on click. Idempotent receipt per reward/run; recover interrupted grants. Reward feature flag off by default in public noncommercial builds.
- Start with one optional post-run bonus: proposed +50% earned essence, up to 3 completed bonus claims/day. Show normal rewards first and an equally clear continue option. No XP or fusion odds boost; no reward for repeatedly abandoning runs. Test economy with no ads vs maximum bonuses and verify first-fusion/free progression is unchanged.
- Only after this works, consider one optional reroll per run from the same phenotype-eligible pool (no better rarity odds); revive after defeat may be tested later, assisted results clearly separate from unassisted records. Avoid forced, mid-combat, and death-interrupt advertising. Grimoire assistance deferred until it can avoid selling hidden genetic probabilities.
- Test mock ad acceptability, not fake monetization forecasts. Set cadence, caps, eligibility and expected reward values in data config. Never condition access to a core feature on ad availability.

Gate E: no missed/duplicate grants; cancellation and no network leave normal play and rewards intact; testers understand optionality; free vs rewarded economy comparison documented and no pressure complaints. No real ads until release readiness.

## Phase 6: make players want to return (gameplay)

- Introduce Tier III with additional genetic complexity, advanced ability interactions and upgrade synergies rather than raw superiority. Validate cross-generation distribution, balance, art coverage and schema migration.
- Add collection/Grimoire completion goals, optional mastery challenges, dungeon unlocks, deterministic rotating challenges where possible without daily obligation, and more meaningful training goals. Free challenges first; cosmetics may reward milestones. No forced streaks or paid pass expiration at launch.
- Add one more biome/species/affinity only if playtests show demand and balance budget allows. Introduce 10–15 minute expedition target after shorter mode proven.
- UX polish, audio, accessibility, onboarding, checkpoints/resume, battery, storage, translations (English first, Japanese/Portuguese later if resources allow), independent difficulty and no paywall in core progression.

Gate F: closed test cohort shows return behavior; initial internal targets D1 >=30%, D7 >=10%, D30 >=5% once sample/time permits; first run completion >=80%, first fusion >=25% within 7 days; crash-free sessions >=99.5%. Define unique active install, qualifying sessions, day windows and denominator. Small cohorts report counts and uncertainty; use qualitative interviews and cohorts, never treat these as market benchmarks or proof of product-market fit. If poor retention, iterate before adding monetization complexity.

## Phase 7: commercial beta and Google Play (monetization + release)

No actual commercial activity until owner explicitly approves after checking immigration/work authorization, scholarship conditions, taxes, developer identity/address disclosure and business setup. Verify current official Play/AdMob requirements at implementation time; no policy numbers or fees assumed fixed.
- Register Play Console and app, secure account and signing, pin compatible engine/plugins/SDK, production signed AAB, reproducible internal/closed testing build; verify target SDK and applicable testing eligibility before submission. Make package identifier and save migration decision explicit. Prepare store listing, rating, audience, screenshots, privacy policy, Data Safety and ads declarations; audit licenses of all art/music/code.
- Integrate Google Play Billing for direct-price non-consumable cosmetics/supporter pack; show actual localized store prices; use verified purchases, acknowledgement, pending/cancel/refund/revocation and restore. Lightweight serverless backend only as needed for purchase verification/entitlement ledger and optional AdMob server-side reward verification. Never expose API credentials or trust local profile checksums as proof of purchase. Use sandbox billing and test ads first. Ad SDK consent/age controls and privacy requirements depend on regions/audience.
- Small launch catalog proposal: one supporter pack (¥980–1,500 hypothesis), two cosmetic sets (¥480–800 hypothesis), one academy theme (¥480–980 hypothesis). No paid randomized content, roster scarcity or purchasable power. Direct localized prices; no premium currency. Ads: one optional post-run essence bonus if gate E passes. Keep feature flags/kill switches and conservative rates.
- Internal testing then required closed testing with actual testers; track upgrade/reinstall, compatibility, entitlement recovery, purchase and ad failure paths, non-payer experience. No paid acquisition until retention, conversion and operating costs can be measured.

Gate G: official current policy checklist signed off; verified same-key app update and backup/recovery; paid products restored correctly, refund handling tested, ad cancellation and duplicate callbacks tested, no ads on core path; crash-free/stability and free economy targets assessed; owner authorizes launch. Soft launch first, then broader rollout if results support it.

## Phase 8: launch and expand (alternating live increments)

Alternate meaningful game updates with complementary commercial content; each paid release must accompany or follow a free improvement. Example sequence: free necropolis biome + boss -> necropolis cosmetic collection -> free new genetic mutation/challenge -> academy theme and crest -> free quality update -> clearly priced optional expansion pack with substantive campaign content. New genetics in expansion must not dominate free characters; keep shared balancing and core collection viable. Do not promise a live-service cadence before knowing capacity. No subscription, premium currency, paid storage/training or seasons until there is evidence of demand and a sustainable support cadence.

Monitor by cohort: retention, first fusion, sessions, reward accept/completion, opt-out rates, purchases/restore/refunds, net revenue after fees/tax/hosting, crash-free sessions and feedback. Stop or adjust features that erode trust/retention. Marketing: authentic clips of combat and fusion, store asset A/B tests, community feedback, then limited spend only with evidence.

## Foundation checklist

Carry forward prior technical gates: deterministic RNG and versioned schema; 100k generation/fusion validation; original assets/license audit; meaningful combat and independent difficulty; touch/background physical tests; reproducible builds; atomic profile saves, idempotent receipts, recovery fixtures, retired parents archive/locks; complete first acquisition-to-fusion path; 60 FPS target/30 FPS fallback on reference device; all phenotype combinations render; no unbounded effect queues. Keep original browser files separate. Work in mobile/ plus narrowly scoped CI when necessary.

## Immediate execution queue

1. Enemy behavior framework and three counterplay roles (web slow, charge, ranged) plus telegraph/feedback. Establish enemy cooldown and attack-budget tests.
2. Dragon attack patterns and encounter director; fix current targeting/collision shortcomings and profile device. Add automated balance scenarios using current abilities and upgrades.
3. Tune first-run progression and upgrade frequency with actual playtest evidence.
4. Stable alpha signing and save export/import in parallel with 1–3, before recruiting repeat testers.
5. First-fusion tutorial and progression, Grimoire and lineage improvements.
6. Only after Gates A/B, free cosmetics/ownership and mock store.

Definition of done for every increment: documented design and acceptance tests, deterministic regressions, compatible saves or explicit migration, CI status, device/playtest evidence where needed, no secrets/generated cache committed, no browser behavior changed, known limitations explicit. Treat the next gate as the planning horizon; estimate work only after breaking down actual tasks. Revisit roadmap after each gate rather than locking content counts or dates now.
