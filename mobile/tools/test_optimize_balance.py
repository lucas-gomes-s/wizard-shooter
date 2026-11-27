import unittest
from optimize_balance import evaluate

def matrix(wins):
    return [dict(difficulty=d,strategy=s,affinity=a,outcome="Victory" if wins else "Defeated",
                 seconds=110 if wins else 12,first_upgrade=12,boss_reached=wins)
            for d in (1,2,3) for s in ("stationary","aggressive","kiting","explorer")
            for a in ("fire","ice","steam")]

class ObjectiveTest(unittest.TestCase):
    def test_not_trivial_or_impossible(self):
        rows=matrix(False)*20
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

if __name__=="__main__":
    unittest.main()
