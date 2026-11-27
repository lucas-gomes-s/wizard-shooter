import json, random, tempfile, unittest
from pathlib import Path
from PIL import Image
from sprite_generator import *

class SpriteTests(unittest.TestCase):
    def test_reproducibility(self):
        a,b=random.Random(42),random.Random(42)
        for _ in range(100):
            p,q=sample(a),sample(b)
            self.assertEqual(p,q)
            self.assertEqual(compose(p).tobytes(),compose(q).tobytes())
    def test_illegal(self):
        for p in [Phenotype('fae','steam',1),Phenotype('fae','ice',2,mutation='crystal_wings'),Phenotype('stoneborn','ice',2,mutation='living_flame')]:
            with self.assertRaises(ValueError): compose(p)
    def test_population_and_atlas(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=Path(tmp); m=generate(path)
            layers=Image.open(path/'layers.png').convert('RGBA')
            population=Image.open(path/'population.png').convert('RGBA')
            self.assertEqual(len(m['characters']),100)
            for i,record in enumerate(m['characters']):
                p=Phenotype(**record['phenotype'])
                for f,slots in enumerate(record['frames']):
                    out=Image.new('RGBA',(SIZE,SIZE))
                    for slot in SLOTS:
                        idx=slots[slot]; x,y=idx%8*SIZE,idx//8*SIZE
                        out.alpha_composite(layers.crop((x,y,x+SIZE,y+SIZE)))
                    self.assertEqual(out.tobytes(),compose(p,f).tobytes())
                    self.assertEqual(out.size,(32,32))
                    self.assertEqual(out.getpixel((0,0))[3],0)
                    self.assertNotEqual(out.getbbox(),None)
                    if f==0:
                        x,y=i%10*SIZE,i//10*SIZE
                        self.assertEqual(out.tobytes(),population.crop((x,y,x+SIZE,y+SIZE)).tobytes())
                self.assertNotEqual(compose(p,0).tobytes(),compose(p,1).tobytes())
if __name__=='__main__': unittest.main()
