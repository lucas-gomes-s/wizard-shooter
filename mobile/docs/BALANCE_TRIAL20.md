# Trial 20 and next expedition design

## Evidence
User's complete optimization.json: 32,400 training and 4,320 holdout runs. Exact parameters in gameplay/balance_config.gd. 4.7.2 holdout wins (aggressive + kiting): D1 43.89%, D2 15.83%, D3 2.22%. Ice D2/D3 0%; D1 aggressive 8.89%, kiting 78.89%. Aggregate loss is not a guarantee of fairness. Full original holdout seeds reused on 4.5.1 to compare engines, not an untouched new validation set. Candidate is only a provisional short-run playtest setting. No optimization repeated.

## Next slice: six-minute expedition (design, not implemented)
- Retain short original and Trial 20 as regression protocols. Use a separate duration/encounter configuration, not a blanket multiplier to all timers.
- 0-60s: teach goblins and spiders, give first upgrade within 5-20s; 60-180s: add orcs and guarded sites; 180-300s: warlock pressure with relief windows; 300-360s: mixed packs and boss warning; at 360s boss arrives. Initial target finish within 6-8 minutes on victory.
- Introduce phased spawn budgets and bounded density rather than extending the current linear spawn-rate ramp. Maintain enough empty space to dodge. Test active exploration and ranged attacks rather than length alone.
- Ice: evaluate basic pierce utilization, shatter on chilled targets, boss chill/freeze resistance and damage delivery; trial targeted changes separately before full sweep.
- Permanent XP: decouple from combat XP; calibrate using real runs and 25% apprentice share. Aim first fusion 30-60 active minutes, not one short run; preserve accrued XP and already mature wizards. Determine conversion after 6-minute matrix, not from guessed scaling.
- Benchmark: keep old bot policies reproducible; add dodge-aware close-range and explorer boss-seeking policies. Report each strategy, affinity, body and legal generated phenotype. Penalize zero/low affinity wins and strategy gaps, not just overall rates. New untouched final seeds after selecting long-run candidate.
- Do not change old frozen optimizer study. Separate experiment directory and protocol. No final-beta balance until physical playtesting.

## Manual test
Academy or title Settings: choose Finite balance Trial 20 or Original. Start a finite run; selection is fixed for the run, next runs retain preference. Endless uses Original. Enable local Playtest report before starting to compare actual parameter snapshots. Test both Fire and Ice, both close combat and kiting. Record difficulty and whether boss encounter felt fair.

## Implementation update
The six-minute phase schedule now exists as optional `expedition-six`; see gameplay/expedition_schedule.gd for exact provisional values. The old 90s presets remain available. The long-run benchmark uses 540s horizon, fresh exploratory seed start 310000019, two seeds per cell (216 simulations). Do not compare its aggregate win rate directly to the 150s protocol. No long-run optimizer yet. Next: inspect survival/progression and calibrate permanent XP/essence, then improve bots and long-run objective.

## Permanent economy update
All modes now use training-v2 (see domain/training_economy.gd), independent of historical combat tuning and unchanged maturity XP40. Example six-minute successful run: 20 base training, up to 5 activity bonus, 5–6 apprentice, 10–13 essence with victory bonus, plus a founder. Fixed pair needs about 42–48 active minutes at that pace; swapping active roles speeds it up. Actual time depends on survival and per-run rounding. Keep existing progress. Prior benchmarks used legacy XP; new benchmark emits both, do not compare incompatible fields. Re-evaluate after six-minute results, then decide whether short presets should grant rewards or be debug-only.
