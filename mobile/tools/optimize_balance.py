#!/usr/bin/env python3
"""Offline, bounded Optuna search. Never modifies game source or live defaults."""
import argparse
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import tempfile

BOUNDS = {
    "enemy_hp": (.75, 1.35), "enemy_damage": (.65, 1.35),
    "spawn_interval": (.85, 1.65), "recovery": (0., 1.5),
    "boss_hp": (.65, 1.4), "boss_damage": (.75, 1.35),
    "boss_add_interval": (1., 3.), "ice_damage": (.85, 1.4),
    "fire_damage": (.85, 1.25), "steam_damage": (.85, 1.25),
    "xp_growth": (1.15, 1.35), "xp_increment": (1., 4.)
}
DEFAULTS = dict.fromkeys(BOUNDS, 1.)
DEFAULTS.update(recovery=0., xp_growth=1.25, xp_increment=2.)
TARGETS = {
    1: {"wins": (.35,.55), "early": .10, "stationary": .10},
    2: {"wins": (.15,.30), "early": .20, "stationary": .05},
    3: {"wins": (.05,.15), "early": .30, "stationary": .02}
}

def outside(x, low, high):
    return max(low-x,0.,x-high)**2

def rate(rows, predicate):
    if not rows:
        raise ValueError("Empty metric cohort")
    return sum(bool(predicate(r)) for r in rows)/len(rows)

def evaluate(rows):
    """Two-sided target bands; report each component for human inspection."""
    loss = 0.
    metrics = {}
    win_rates = []
    for d, target in TARGETS.items():
        group = [r for r in rows if r["difficulty"]==d]
        competent = [r for r in group if r["strategy"] in ("aggressive","kiting")]
        stationary = [r for r in group if r["strategy"]=="stationary"]
        wins = rate(competent,lambda r:r["outcome"]=="Victory")
        early = rate(competent,lambda r:r["outcome"]=="Defeated" and r["seconds"]<22.5)
        idle = rate(stationary,lambda r:r["outcome"]=="Victory")
        timeouts = rate(competent,lambda r:r["outcome"]=="Timeout")
        reached = rate(competent,lambda r:r["boss_reached"])
        per_affinity = {a:rate([r for r in competent if r["affinity"]==a],lambda r:r["outcome"]=="Victory") for a in ("fire","ice","steam")}
        spread = max(per_affinity.values())-min(per_affinity.values())
        # Penalize all wins and all losses, early frustration, stalled combat,
        # trivial idle victories and major differences among elements.
        loss += 12*outside(wins,*target["wins"])
        loss += 5*outside(early,0,target["early"])
        loss += 8*outside(idle,0,target["stationary"])
        loss += 5*outside(timeouts,0,.15)
        loss += 3*outside(spread,0,.30)
        # At least some competent players should see the boss.
        loss += 2*outside(reached,{1:.65,2:.45,3:.25}[d],1.)
        first = [r["first_upgrade"] for r in competent if r["first_upgrade"]>=0]
        no_upgrade = 1-len(first)/len(competent)
        loss += 2*no_upgrade
        if first:
            loss += outside(statistics.median(first)/90.,.06,.22)*6
        metrics[str(d)] = dict(wins=wins,early_deaths=early,stationary_wins=idle,
            timeouts=timeouts,boss_reached=reached,affinity_wins=per_affinity,
            affinity_spread=spread,first_upgrade_median=statistics.median(first) if first else None,
            no_upgrade=no_upgrade)
        win_rates.append(wins)
    loss += 8*sum(max(0,b-a)**2 for a,b in zip(win_rates,win_rates[1:]))
    return loss,metrics

def run_matrix(godot, project, params, seeds, start, seconds, all_bodies):
    with tempfile.TemporaryDirectory(prefix="wizard-balance-") as directory:
        cfg=Path(directory)/"config.json"
        out=Path(directory)/"result.json"
        cfg.write_text(json.dumps(params))
        command=[godot,"--headless","--path",str(project),"--script",
                 "tools/balance_benchmark.gd","--",f"--seeds={seeds}",
                 f"--seed-start={start}",f"--seconds={seconds}",
                 f"--config={cfg}",f"--output={out}"]
        if all_bodies:
            command.append("--all-bodies")
        p=subprocess.run(command,capture_output=True,text=True,timeout=3600)
        if p.returncode or "SCRIPT ERROR" in p.stdout+p.stderr or not out.exists():
            raise RuntimeError((p.stdout+p.stderr)[-5000:])
        result=json.loads(out.read_text())
        expected=36*seeds*(3 if all_bodies else 1)
        if len(result["runs"])!=expected:
            raise RuntimeError("Incomplete benchmark matrix")
        score,metrics=evaluate(result["runs"])
        return dict(score=score,metrics=metrics,benchmark=result)

def main():
    import optuna
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot",default=os.getenv("GODOT","godot"))
    parser.add_argument("--project",type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument("--trials",type=int,default=12)
    parser.add_argument("--train-seeds",type=int,default=2)
    parser.add_argument("--validation-seeds",type=int,default=5)
    parser.add_argument("--seconds",type=int,default=150)
    parser.add_argument("--jobs",type=int,default=1)
    parser.add_argument("--all-bodies",action="store_true")
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    if not (args.trials>=1 and 1<=args.train_seeds<=100 and 1<=args.validation_seeds<=100 and 120<=args.seconds<=900 and args.jobs>=1):
        parser.error("Invalid trial/seed/time/job settings")
    # Fail before launching any parallel trial if Godot cannot parse the benchmark.
    check = subprocess.run([args.godot,"--headless","--path",str(args.project),"--check-only","--script","tools/balance_benchmark.gd"],capture_output=True,text=True,timeout=60)
    logs = check.stdout + check.stderr
    if check.returncode or "SCRIPT ERROR" in logs or "Parse Error" in logs or "Failed to load script" in logs:
        parser.exit(2, "Godot benchmark preflight failed:\n" + logs + "\n")
    # Disjoint ranges; common random numbers within a split.
    train_start, validation_start = 7001, 200000003
    study=optuna.create_study(direction="minimize",sampler=optuna.samplers.TPESampler(seed=42))
    study.enqueue_trial(DEFAULTS)
    study.enqueue_trial(dict(DEFAULTS,enemy_damage=.8,spawn_interval=1.25,recovery=.8,boss_add_interval=1.8,ice_damage=1.15))
    history={}
    def objective(trial):
        params={k:trial.suggest_float(k,*bounds) for k,bounds in BOUNDS.items()}
        result=run_matrix(args.godot,args.project,params,args.train_seeds,train_start,args.seconds,args.all_bodies)
        history[trial.number]=dict(parameters=params,**result)
        print(f"TRIAL {trial.number} loss={result['score']:.5f}",flush=True)
        return result["score"]
    study.optimize(objective,n_trials=args.trials,n_jobs=args.jobs)
    # Select on training only. Holdout is examined once for baseline and selected candidate.
    if not any(t.state == optuna.trial.TrialState.COMPLETE for t in study.trials):
        parser.exit(2, "No successful optimization trials; inspect the Godot error logs above.\n")
    best=dict(study.best_params)
    baseline=run_matrix(args.godot,args.project,DEFAULTS,args.validation_seeds,validation_start,args.seconds,args.all_bodies)
    candidate=run_matrix(args.godot,args.project,best,args.validation_seeds,validation_start,args.seconds,args.all_bodies)
    report=dict(schema=1,targets=TARGETS,train_seed_start=train_start,validation_seed_start=validation_start,
                training_trials=history,best_training_trial=study.best_trial.number,
                baseline_validation=baseline,candidate_validation=candidate,
                candidate_parameters=best,improves_holdout=candidate["score"]<baseline["score"],
                status="review_required",note="Bot targets are provisional, not human outcomes. No live changes.")
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2,allow_nan=False))
    print(f"HOLDOUT baseline={baseline['score']:.5f} candidate={candidate['score']:.5f}; review required",flush=True)

if __name__=="__main__":
    main()
