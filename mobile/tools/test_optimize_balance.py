import unittest
import tempfile
from pathlib import Path
from optimize_balance import evaluate, atomic_json, create_snapshot, fingerprint, recover_log_candidates, DEFAULTS

def matrix(wins):
    return [dict(difficulty=d,strategy=s,affinity=a,outcome="Victory" if wins else "Defeated",
                 seconds=110 if wins else 12,first_upgrade=12,boss_reached=wins)
            for d in (1,2,3) for s in ("stationary","aggressive","kiting","explorer")
            for a in ("fire","ice","steam")]

class ObjectiveTest(unittest.TestCase):
    def test_not_trivial_or_impossible(self):
        rows=[r for _ in range(20) for r in matrix(False)]
        counters={}
        for r in rows:
            key=(r["difficulty"],r["strategy"],r["affinity"])
            i=counters.get(key,0); counters[key]=i+1
            if r["strategy"] in ("aggressive","kiting"):
                r.update(outcome="Victory" if i<{1:9,2:4,3:2}[r["difficulty"]] else "Defeated",
                         seconds=110 if i<{1:9,2:4,3:2}[r["difficulty"]] else 70,
                         boss_reached=i<14)
        self.assertLess(evaluate(rows)[0],evaluate(matrix(True))[0])
        self.assertLess(evaluate(rows)[0],evaluate(matrix(False))[0])

class RecoveryTest(unittest.TestCase):
    def test_snapshot_is_independent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            source=root/"source"
            (source/"tools").mkdir(parents=True)
            (source/"gameplay").mkdir()
            (source/"domain").mkdir()
            (source/"tools/balance_benchmark.gd").write_text("extends SceneTree")
            (source/"gameplay/run.gd").write_text("extends RefCounted")
            snapshot=root/"snapshot"
            expected=create_snapshot(source,snapshot)
            (source/"tools/balance_benchmark.gd").unlink()
            self.assertEqual(fingerprint(snapshot),expected)
            self.assertTrue((snapshot/"project.godot").exists())

    def test_legacy_candidates_ranked_and_validated(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=Path(tmp)/"old.log"
            other=dict(DEFAULTS,enemy_hp=1.1)
            path.write_text(f"Trial 2 finished with value: 0.4 and parameters: {DEFAULTS}.\n"
                            f"Trial 8 finished with value: 0.148 and parameters: {other}.\n"
                            f"Trial 9 finished with value: 0.01 and parameters: {{'enemy_hp': 0}}.\n")
            self.assertEqual(recover_log_candidates(path),[other,DEFAULTS])
            out=Path(tmp)/"checkpoint.json"
            atomic_json(out,{"trial":8})
            atomic_json(out,{"trial":9})
            self.assertIn('"trial": 9',out.read_text())

if __name__=="__main__":
    unittest.main()
