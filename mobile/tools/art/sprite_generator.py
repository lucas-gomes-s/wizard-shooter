"""Wizard Shooter pixel-art prototype. Python 3.10+ / Pillow. No external art."""
from dataclasses import asdict, dataclass
from pathlib import Path
import argparse, json, random
from PIL import Image, ImageDraw

SIZE = 32
INK = '#191923'
PALETTES = {
    'fire': ('#522d3c', '#a34441', '#ed7950', '#ffce82'),
    'ice': ('#293d57', '#416c88', '#76b9d2', '#c9f4f1'),
    'steam': ('#453950', '#766681', '#a3a5b5', '#e0e9e5'),
}
BODIES = ('stoneborn', 'fae', 'hybrid')
SLOTS = ('wings', 'body', 'robe', 'head', 'hat', 'staff', 'mutation')

@dataclass(frozen=True)
class Phenotype:
    body: str
    affinity: str
    tier: int
    hat: int = 0
    robe: int = 0
    staff: int = 0
    mutation: str = 'none'

    def validate(self):
        if self.body not in BODIES or self.affinity not in PALETTES or self.tier not in (1, 2):
            raise ValueError('Unknown body, affinity or tier')
        if self.tier == 1 and (self.body == 'hybrid' or self.affinity == 'steam' or self.mutation != 'none'):
            raise ValueError('Advanced expression requires tier II')
        if any(v not in range(3) for v in (self.hat, self.robe, self.staff)):
            raise ValueError('Variant must be 0, 1 or 2')
        if self.mutation not in ('none', 'crystal_wings', 'living_flame'):
            raise ValueError('Unknown mutation')
        if self.mutation == 'crystal_wings' and self.body not in ('stoneborn', 'hybrid'):
            raise ValueError('Crystal wings require stone anatomy')
        if self.mutation == 'living_flame' and self.affinity not in ('fire', 'steam'):
            raise ValueError('Living flame requires fire-compatible core')


def sample(rng):
    """Sample legal *visual* descriptors, not an inheritance simulation."""
    tier = rng.choice((1, 2))
    body = rng.choice(BODIES if tier == 2 else BODIES[:2])
    affinity = rng.choice(tuple(PALETTES) if tier == 2 else ('fire', 'ice'))
    mutations = ['none']
    if tier == 2 and body != 'fae': mutations.append('crystal_wings')
    if tier == 2 and affinity != 'ice': mutations.append('living_flame')
    return Phenotype(body, affinity, tier, *(rng.randrange(3) for _ in range(3)), rng.choice(mutations))


def layer(p, slot, frame=0):
    """All layers share a 32x32 canvas and feet anchor (15,29)."""
    p.validate()
    if slot not in SLOTS or frame not in (0, 1): raise ValueError('Invalid slot/frame')
    img = Image.new('RGBA', (SIZE, SIZE)); d = ImageDraw.Draw(img)
    dark, mid, bright, glow = PALETTES[p.affinity]
    def r(x0,y0,x1,y1,c): d.rectangle((x0,y0,x1,y1),fill=c)
    def poly(points,c,outline=INK): d.polygon(points,fill=c,outline=outline)
    stone = p.body != 'fae'
    if slot == 'wings' and p.mutation == 'crystal_wings':
        for mirror in (False, True):
            def xy(x,y): return (30-x if mirror else x,y)
            poly([xy(x,y) for x,y in [(12,17),(8,8),(3,5),(2,13),(4,21),(8,24),(12,21)]],mid)
            d.line([xy(4,8),xy(6,19),xy(10,21)],fill=bright,width=1)
            d.line([xy(3,13),xy(8,13),xy(10,17)],fill=glow,width=1)
    elif slot == 'body':
        # Keep feet on baseline; alternate one-pixel raised foot.
        left,right = (0,1) if frame else (1,0)
        r(10,24,13,29-left,INK); r(17,24,20,29-right,INK)
        r(11,25,12,28-left,'#74666b'); r(18,25,19,28-right,'#74666b')
        skin = '#8e929d' if stone else '#cbb69e'
        if stone:
            poly([(8,15),(22,15),(24,19),(23,24),(7,24),(6,19)],skin)
            r(7,19,8,22,'#626674'); r(22,19,23,22,'#626674')
        else:
            poly([(11,15),(19,15),(22,20),(21,24),(9,24),(8,20)],skin)
    elif slot == 'robe':
        x=8 if stone else 10; y=22 if stone else 20
        poly([(x,16),(30-x,16),(30-x,22),(24,27),(6,27),(x,22)],dark)
        if p.robe == 0:
            r(13,17,16,25,mid); r(14,18,14,24,bright)
        elif p.robe == 1:
            poly([(x,16),(30-x,16),(20,20),(15,23),(10,20)],mid,None)
            r(14,21,16,25,bright)
        else:
            r(x+1,19,30-x-1,20,mid); r(9,25,21,26,mid)
        r(10,23,20,24,'#806948'); r(14,23,16,24,'#e2b96c')
    elif slot == 'head':
        skin = '#9799a3' if stone else '#d3bca3'
        if p.body in ('fae','hybrid'):
            poly([(11,11),(5,9),(6,13),(10,15)],skin)
            poly([(19,11),(25,9),(24,13),(20,15)],skin)
        poly([(10,9),(20,9),(22,11),(22,16),(19,18),(11,18),(8,16),(8,11)],skin)
        r(10,15,11,16,'#6c6875' if stone else '#9a796d')
        if stone:
            d.line([(10,10),(12,12),(11,14)],fill=mid)
            d.line([(20,10),(18,11)],fill=mid)
        r(11,13,13,14,INK); r(17,13,19,14,INK)
        r(12,13,12,13,glow); r(18,13,18,13,glow)
    elif slot == 'hat':
        if p.hat == 0:
            poly([(13,2),(17,2),(17,5),(19,5),(19,8),(23,8),(23,10),(26,10),(26,12),(4,12),(4,10),(8,10),(8,8),(11,8),(11,5),(13,5)],dark)
            r(10,9,21,10,mid); r(15,9,16,10,bright)
        elif p.hat == 1:
            poly([(11,4),(19,4),(22,7),(23,11),(7,11),(8,7)],dark)
            r(10,9,20,10,mid); r(14,5,16,8,bright)
        else:
            poly([(8,5),(11,5),(11,8),(14,8),(14,3),(17,3),(17,8),(20,8),(20,5),(23,5),(23,11),(8,11)],dark)
            r(10,9,21,10,'#b49761'); r(15,7,16,8,glow)
    elif slot == 'staff':
        r(26,13,27,28,INK); r(26,15,26,27,'#96724e')
        if p.staff == 0: poly([(26,7),(29,10),(27,14),(24,10)],bright)
        elif p.staff == 1: poly([(24,7),(29,7),(30,11),(27,14),(23,11)],bright)
        else: poly([(26,6),(27,6),(30,10),(28,13),(24,13),(22,10)],mid)
        r(26,9,27,10,glow)
    elif slot == 'mutation' and p.mutation == 'living_flame':
        poly([(3,24),(3,21),(4,22),(5,18),(7,22),(8,21),(8,25),(6,27),(4,27)],bright)
        r(5,23,6,25,glow); r(23,17,23,18,bright); r(6,15,6,15,glow)
    return img


def compose(p, frame=0):
    out = Image.new('RGBA', (SIZE, SIZE))
    for slot in SLOTS: out.alpha_composite(layer(p,slot,frame))
    return out


def atlas(images, cols):
    rows = (len(images)+cols-1)//cols
    out = Image.new('RGBA',(cols*SIZE,rows*SIZE))
    for i, im in enumerate(images): out.alpha_composite(im,((i%cols)*SIZE,(i//cols)*SIZE))
    return out


def save_png(im,path):
    # Exact palette encoding: no lossy quantization.
    pixels=list(im.getdata()); colors=sorted(set(pixels))
    if len(colors)>256:
        im.save(path,optimize=True); return
    indexed=Image.new('P',im.size); lookup={v:i for i,v in enumerate(colors)}
    indexed.putdata([lookup[v] for v in pixels])
    indexed.putpalette([v for rgba in colors for v in rgba[:3]])
    indexed.info['transparency']=bytes(v[3] for v in colors)
    indexed.save(path,optimize=True)


def generate(out, seed=42, count=100):
    out.mkdir(parents=True,exist_ok=True)
    rng=random.Random(seed)
    examples=[Phenotype('stoneborn','fire',1),Phenotype('fae','ice',1,1,1,1),Phenotype('hybrid','steam',2,2,2,2,'crystal_wings'),Phenotype('stoneborn','fire',2,1,2,0,'living_flame')]
    population=(examples+[sample(rng) for _ in range(max(0,count-len(examples)))])[:count]
    # Export one reusable atlas with unique layer/frame textures and a per-phenotype lookup.
    unique={}; textures=[]; refs=[]
    for p in population:
        frames=[]
        for frame in range(2):
            layers={}
            for slot in SLOTS:
                im=layer(p,slot,frame); key=im.tobytes()
                if key not in unique: unique[key]=len(textures); textures.append(im)
                layers[slot]=unique[key]
            frames.append(layers)
        refs.append({'phenotype':asdict(p),'frames':frames})
    save_png(atlas(textures,8),out/'layers.png')
    save_png(atlas([compose(p) for p in population],10),out/'population.png')
    save_png(atlas([compose(p,f) for p in examples for f in range(2)],2),out/'walk_examples.png')
    manifest={'schema_version':1,'seed':seed,'tile_size':SIZE,'feet_anchor':[15,29],'layer_order':list(SLOTS),'layer_atlas_columns':8,'layer_count':len(textures),'population_columns':10,'characters':refs}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    return manifest


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,default=Path(__file__).resolve().parents[2]/'assets/characters/prototype')
    parser.add_argument('--seed',type=int,default=42); parser.add_argument('--count',type=int,default=100)
    args=parser.parse_args()
    if not 1<=args.count<=10000: parser.error('count must be 1..10000')
    m=generate(args.out,args.seed,args.count)
    print(f"Generated {len(m['characters'])} wizards, {m['layer_count']} unique layers in {args.out}")

if __name__=='__main__': main()
