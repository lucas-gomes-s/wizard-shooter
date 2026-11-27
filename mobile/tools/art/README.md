# Procedural wizard sprites: prototype 0.1

Run from this directory with Python 3.10+:

```sh
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python sprite_generator.py --seed 42 --count 100
python -m unittest -v
```

Generated PNGs and JSON manifest are in `../../assets/characters/prototype/`. All art is drawn programmatically, no external assets. 32×32 transparent tiles, feet anchor (15,29), front-facing two-frame walk. Seven layer slots: wings, body, robe, head, hat, staff, mutation. Atlas indices map to 32×32 regions in eight columns. Composite in manifest order, nearest-neighbor filtering in Godot. Population sheet has ten columns. Walk sheet shows four example characters, one row each.

This is a visual prototype, not a genetic inheritance engine. It accepts resolved phenotype descriptors; random samples are seeded and restricted to legal visual combinations, but do not represent biological inheritance or balanced combat stats. The three body templates are Stoneborn, Fae and a mixed body. Fire/Ice/Steam and crystal wings/living flame follow the design baseline. Hat, robe and staff variants are aesthetic placeholders; eventual functional traits must select them. Current walking animation only alternates feet; directional/cast/idle animation and more pronounced silhouettes remain future work. Atlas includes layers used by the sampled population, not necessarily every theoretical combination. No Godot scene yet.
