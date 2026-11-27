#!/usr/bin/env python3
"""Offline, bounded Optuna search. Never modifies game source or live defaults."""
import argparse
import ast
import hashlib
import json
import os
import re
import shutil
import fcntl
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

class MatrixError(RuntimeError):
    """A failed Godot process or incomplete matrix, not a valid balance outcome."""


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, prefix=".tmp-", delete=False) as f:
        temporary = Path(f.name)
        try:
            json.dump(value, f, indent=2, allow_nan=False)
            f.flush()
            os.fsync(f.fileno())
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def source_files(project):
    # The headless benchmark has no scene or asset dependencies.
    project = Path(project)
    files = [project / "tools/balance_benchmark.gd"]
    for folder in ("gameplay", "domain"):
        files.extend(sorted((project / folder).rglob("*.gd")))
    if not files[0].is_file() or not (project/"gameplay/run.gd").is_file():
        raise ValueError("Benchmark sources missing in " + str(project))
    return files


def fingerprint(project):
    digest = hashlib.sha256()
    for path in sorted(source_files(project)):
        digest.update(str(path.relative_to(project)).encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def create_snapshot(project, snapshot):
    """Copy only simulation sources, not the live game, .venv, or Godot cache."""
    before = fingerprint(project)
    with tempfile.TemporaryDirectory(dir=snapshot.parent, prefix=".snapshot-") as staging:
        target = Path(staging)/"project"
        target.mkdir()
        for src in source_files(project):
            dst=target/src.relative_to(project)
            dst.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(src,dst)
        (target/"project.godot").write_text('config_version=5\n[application]\nconfig/name="Wizard Balance Sandbox"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        if fingerprint(target)!=before or fingerprint(project)!=before:
            raise ValueError("Simulation files changed during snapshot; retry after the repository update.")
        target.rename(snapshot)
    return before


def recover_log_candidates(path, limit=5):
    """Read legacy Optuna logs as suggestions only; never trust old scores as fresh measurements."""
    found = []
    for line in Path(path).read_text(errors="replace").splitlines():
        m = re.search(r"Trial (\d+) finished with value: ([0-9.eE+\-]+) and parameters: (\{.*?\})", line)
        if not m:
            continue
        try:
            score = float(m[2])
            params = ast.literal_eval(m[3])
            if not isinstance(params,dict) or set(params)!=set(BOUNDS):
                continue
            if not all(type(params[k]) in (int,float) and lo<=params[k]<=hi for k,(lo,hi) in BOUNDS.items()):
                continue
            if not (0 <= score < float("inf")):
                continue
            found.append((score, int(m[1]),params))
        except (ValueError,SyntaxError,TypeError):
            continue
    unique = []
    seen = set()
    for _,_,params in sorted(found,key=lambda v:(v[0],v[1])):
        key=json.dumps(params,sort_keys=True)
        if key not in seen:
            unique.append(params)
            seen.add(key)
        if len(unique)>=limit:
            break
    return unique


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
        try:
            p=subprocess.run(command,capture_output=True,text=True,timeout=3600)
        except (subprocess.TimeoutExpired,OSError) as exc:
            raise MatrixError(str(exc)) from exc
        logs=p.stdout+p.stderr
        if p.returncode or any(token in logs for token in ("SCRIPT ERROR","Parse Error","Failed to load script","ERROR:")) or not out.exists():
            raise MatrixError(logs[-5000:])
        try:
            result=json.loads(out.read_text())
        except (OSError,ValueError) as exc:
            raise MatrixError("Cannot read benchmark JSON") from exc
        expected=36*seeds*(3 if all_bodies else 1)
        if len(result["runs"])!=expected:
            raise MatrixError("Incomplete benchmark matrix")
        score,metrics=evaluate(result["runs"])
        return dict(score=score,metrics=metrics,benchmark=result)

def main():
    import optuna
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot",default=os.getenv("GODOT","godot"))
    parser.add_argument("--project",type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument("--trials",type=int,default=12,help="Target total successful training trials, including existing trials")
    parser.add_argument("--train-seeds",type=int,default=2)
    parser.add_argument("--validation-seeds",type=int,default=5)
    parser.add_argument("--seconds",type=int,default=150)
    parser.add_argument("--jobs",type=int,default=1)
    parser.add_argument("--all-bodies",action="store_true")
    parser.add_argument("--output",type=Path,required=True)
    parser.add_argument("--state-dir",type=Path,help="Persistent study directory; default is output with .study suffix")
    parser.add_argument("--seed-log",type=Path,help="Queue up to five promising parameters from an old terminal log; new studies only")
    args=parser.parse_args()
    if not (args.trials>=1 and 1<=args.train_seeds<=100 and 1<=args.validation_seeds<=100 and 120<=args.seconds<=900 and args.jobs>=1):
        parser.error("Invalid trial/seed/time/job settings")
    args.project=args.project.expanduser().resolve()
    args.output=args.output.expanduser().resolve()
    state=(args.state_dir or args.output.with_suffix(".study")).expanduser().resolve()
    state.mkdir(parents=True,exist_ok=True)
    with (state/"study.lock").open("a") as lock:
        try:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            parser.exit(2,"Another optimizer is using this study directory.\n")
        execute(args,state,optuna,parser)


def execute(args,state,optuna,parser):
    train_start, validation_start = 7001, 200000003
    version=subprocess.check_output([args.godot,"--version"],text=True,timeout=30).strip()
    snapshot=state/"snapshot"
    manifest_path=state/"manifest.json"
    # Training protocol must remain fixed across resumed runs. Parallelism and trial target may change.
    protocol=dict(schema=2,engine=version,train_seeds=args.train_seeds,
                  validation_seeds=args.validation_seeds,seconds=args.seconds,all_bodies=args.all_bodies,
                  train_seed_start=train_start,validation_seed_start=validation_start,
                  optimizer_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    if manifest_path.exists():
        manifest=json.loads(manifest_path.read_text())
        if any(manifest.get(k)!=v for k,v in protocol.items()):
            parser.exit(2,"Study protocol or optimizer version changed. Use the original settings or a new --state-dir.\n")
        if fingerprint(snapshot)!=manifest["source_sha256"]:
            parser.exit(2,"Stored simulation snapshot is missing or modified. Use a new study.\n")
        if args.seed_log:
            parser.exit(2,"--seed-log is for a new study only; remove it when resuming.\n")
    else:
        if snapshot.exists() or (state/"study.sqlite3").exists():
            parser.exit(2,"Incomplete initialization. Choose a new --state-dir; existing files preserved.\n")
        manifest=dict(protocol,source_sha256=create_snapshot(args.project,snapshot))
        atomic_json(manifest_path,manifest)
    print(f"Study: {state}\nGodot: {version}\nFrozen simulation: {manifest['source_sha256']}",flush=True)
    check=subprocess.run([args.godot,"--headless","--path",str(snapshot),"--check-only","--script","tools/balance_benchmark.gd"],capture_output=True,text=True,timeout=60)
    logs=check.stdout+check.stderr
    if check.returncode or any(token in logs for token in ("SCRIPT ERROR","Parse Error","Failed to load script","ERROR:")):
        parser.exit(2,"Godot snapshot preflight failed:\n"+logs+"\n")
    storage=optuna.storages.RDBStorage(url="sqlite:///"+str(state/"study.sqlite3"),engine_kwargs={"connect_args":{"timeout":60}})
    study=optuna.create_study(study_name="wizard-balance",storage=storage,load_if_exists=True,
                             direction="minimize",sampler=optuna.samplers.TPESampler(seed=42))
    TrialState=optuna.trial.TrialState
    if not study.trials:
        study.enqueue_trial(DEFAULTS)
        if args.seed_log:
            recovered=recover_log_candidates(args.seed_log)
            print(f"Recovered {len(recovered)} candidate configurations; re-evaluating, not reusing scores.",flush=True)
            for params in recovered:
                study.enqueue_trial(params,skip_if_exists=True)
        study.enqueue_trial(dict(DEFAULTS,enemy_damage=.8,spawn_interval=1.25,recovery=.8,boss_add_interval=1.8,ice_damage=1.15),skip_if_exists=True)
    trial_dir=state/"trials"
    trial_dir.mkdir(exist_ok=True)
    # A process interrupted between writing the trial file and marking COMPLETE can be recovered.
    for trial in study.get_trials(deepcopy=False,states=(TrialState.RUNNING,)):
        record_path=trial_dir/f"{trial.number:06d}.json"
        if record_path.exists():
            record=json.loads(record_path.read_text())
            if record["parameters"]==trial.params:
                study.tell(trial.number,record["score"])
                continue
        study.tell(trial.number,state=TrialState.FAIL)
    completed_before=len(study.get_trials(deepcopy=False,states=(TrialState.COMPLETE,)))
    print(f"Resuming with {completed_before} completed trials; target {args.trials}",flush=True)

    def objective(trial):
        params={k:trial.suggest_float(k,*bounds) for k,bounds in BOUNDS.items()}
        # All subprocesses read the frozen snapshot; the checkout can change independently.
        result=run_matrix(args.godot,snapshot,params,args.train_seeds,train_start,args.seconds,args.all_bodies)
        atomic_json(trial_dir/f"{trial.number:06d}.json",dict(parameters=params,**result))
        print(f"TRIAL {trial.number} loss={result['score']:.5f} (saved)",flush=True)
        return result["score"]

    remaining=max(0,args.trials-completed_before)
    if remaining:
        study.optimize(objective,n_trials=remaining,n_jobs=args.jobs,catch=(MatrixError,))
    completed=study.get_trials(deepcopy=False,states=(TrialState.COMPLETE,))
    if not completed:
        parser.exit(2,"No successful trials. Check Godot errors. Study is retained for diagnosis.\n")
    history={}
    for trial in completed:
        path=trial_dir/f"{trial.number:06d}.json"
        if not path.exists():
            parser.exit(2,f"Completed trial {trial.number} has no result file; refusing to report incomplete data.\n")
        history[trial.number]=json.loads(path.read_text())
    best=dict(study.best_params)
    selected=study.best_trial.number
    # Persist each validation separately, so interrupted validation need not be repeated.
    def validate(name,params):
        path=state/"validation"/f"{name}.json"
        if path.exists():
            record=json.loads(path.read_text())
            if record["parameters"]==params:
                return record["result"]
        result=run_matrix(args.godot,snapshot,params,args.validation_seeds,validation_start,args.seconds,args.all_bodies)
        atomic_json(path,dict(parameters=params,result=result))
        return result
    baseline=validate("baseline",DEFAULTS)
    candidate=validate(f"trial-{selected}",best)
    report=dict(schema=2,targets=TARGETS,protocol=manifest,train_seed_start=train_start,
                validation_seed_start=validation_start,training_trials=history,
                completed_trials=len(completed),requested_trials=args.trials,
                failed_trials=len(study.get_trials(deepcopy=False,states=(TrialState.FAIL,))),
                best_training_trial=selected,baseline_validation=baseline,candidate_validation=candidate,
                candidate_parameters=best,improves_holdout=candidate["score"]<baseline["score"],
                status="review_required",search_complete=len(completed)>=args.trials,
                note="Bot targets are provisional. No live changes. If extending a study after examining holdout, use a fresh final evaluation set before adopting parameters.")
    atomic_json(args.output,report)
    print(f"HOLDOUT baseline={baseline['score']:.5f} candidate={candidate['score']:.5f}; review required",flush=True)
    if len(completed)<args.trials:
        print("Some trials failed. Run the same command again to reach the requested successful count.",flush=True)


if __name__=="__main__":
    main()
