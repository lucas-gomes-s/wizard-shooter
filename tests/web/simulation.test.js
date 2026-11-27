import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import { Game, FixedClock, SpatialHash, overlaps } from '../../js/simulation.js';

const create = () => new Game(config,()=>0.5);
const enemy = (extra={}) => ({x:280,y:280,width:20,height:20,maxSpeed:0,health:10,maxHealth:10,damage:10,expGiven:1,cd:0,...extra});
test('diagonal speed equals cardinal speed; opposing inputs cancel',()=>{
  const g=create();g.step({x:1,y:1});
  assert.ok(Math.abs(Math.hypot(g.player.x-280,g.player.y-280)-2)<1e-8);
  const pos=[g.player.x,g.player.y];g.step({x:0,y:0});assert.deepEqual([g.player.x,g.player.y],pos);
});
test('held aim fires on simulation cooldown, not keyboard repeat',()=>{
  const g=create();
  for(let i=0;i<100;i++)g.step({aim:[1,0]});
  assert.equal(g.shots.length,2);
});
test('restart clears runtime state and leaves config unchanged',()=>{
  const g=create();const before=JSON.stringify(config.monsters);
  for(let i=0;i<550;i++)g.step({x:1,y:1,aim:[0,1]});
  g.reset();
  assert.deepEqual([g.tick,g.kills,g.enemies.length,g.shots.length,g.potions.length],[0,0,0,0,0]);
  assert.ok(g.enemyTimers.every(x=>x===0));assert.ok(g.potionTimers.every(x=>x===0));
  assert.equal(g.player.level,1);assert.equal(g.phase,'playing');
  assert.equal(JSON.stringify(config.monsters),before);
});
test('spawns retain original two-second goblin interval',()=>{
  const g=create();for(let i=0;i<99;i++)g.step();
  assert.equal(g.enemies.length,0);g.step();assert.equal(g.enemies.length,1);
  assert.equal(g.enemies[0].name,'Goblin');
});
test('spatial hash returns candidates once across negative and positive cell boundaries',()=>{
  const h=new SpatialHash(64), a={x:-4,y:-4,width:70,height:70};h.insert(a);
  assert.deepEqual([...h.query(a)],[a]);
  assert.ok(overlaps(a,{x:66,y:66,width:1,height:1}));
  assert.equal(h.query({x:500,y:500,width:2,height:2}).size,0);
});
test('spatial broad phase includes every brute-force collision',()=>{
  const h=new SpatialHash(64);
  const objects=Array.from({length:100},(_,i)=>({x:(i*71)%800-400,y:(i*137)%800-400,width:10+i%70,height:10+i%40}));
  objects.forEach(o=>h.insert(o));
  for(const a of objects)for(const b of objects)if(overlaps(a,b))assert.ok(h.query(a).has(b));
});
test('projectile damages one enemy and awards XP only once',()=>{
  const g=create();g.enemies.push(enemy({x:340,y:280}),enemy({x:340,y:280}));
  g.shots.push({x:340,y:280,width:5,height:5,vx:0,vy:0,damage:10});
  g.step();assert.equal(g.kills,1);assert.equal(g.player.currentExp,1);
  assert.equal(g.enemies.length,1);assert.equal(g.shots.length,0);
});
test('lethal collision stops simulation and prevents further spawn or XP',()=>{
  const g=create();g.enemies.push(enemy({damage:200}));g.step();
  assert.equal(g.phase,'over');assert.equal(g.player.health,0);
  const tick=g.tick;g.step();assert.equal(g.tick,tick);
});
test('potions do not overheal or disappear at full HP',()=>{
  const g=create();g.potions.push({x:280,y:280,width:30,height:30,recovery:.25,fade:1000,age:0});
  g.step();assert.equal(g.potions.length,1);g.player.health=90;g.step();
  assert.equal(g.player.health,100);assert.equal(g.potions.length,0);
});
test('XP can queue successive upgrades without advancing game time',()=>{
  const g=create();g.player.currentExp=config.levels[0]+config.levels[1];
  g.levelUp();assert.equal(g.phase,'upgrade');assert.equal(g.player.level,2);
  g.step();assert.equal(g.tick,0);assert.ok(g.choose());
  assert.equal(g.player.level,3);assert.equal(g.phase,'upgrade');
  assert.ok(g.choose());assert.equal(g.phase,'playing');assert.equal(g.player.currentExp,0);
});
test('maxed upgrades are excluded and cooldown is at least one tick',()=>{
  const g=create();g.player.level=3;g.player.skillLvl[0]=config.skills[0].maxLevel;
  g.player.currentExp=g.player.expNeeded;g.levelUp();
  assert.ok(g.offers.every(o=>o.id!=='basic-0'));assert.equal(g.choose(99),false);
  g.offers=[{kind:'basic',index:3}];g.player.shotCd=1;assert.ok(g.choose(0));assert.equal(g.player.shotCd,1);
});
test('level cap keeps XP finite and prevents undefined thresholds',()=>{
  const g=create();g.player.level=49;g.player.expNeeded=5;g.player.currentExp=10;
  g.levelUp();assert.ok(g.choose());assert.equal(g.player.level,50);
  assert.equal(g.player.expNeeded,Infinity);assert.equal(g.phase,'playing');
});
test('fixed clock respects elapsed time, caps catch-up and drops paused time',()=>{
  const c=new FixedClock();let ticks=0;const step=()=>{ticks++;};
  c.advance(0,step);for(let t=10;t<=1000;t+=10)c.advance(t,step);assert.equal(ticks,50);
  c.advance(10000,step);assert.equal(ticks,55);
  c.reset();c.advance(20000,step);assert.equal(ticks,55);
});
test('fixed clock stops immediately when simulation enters another phase',()=>{
  const c=new FixedClock();let ticks=0;c.advance(0,()=>{});
  c.advance(100,()=>{ticks++;return false});assert.equal(ticks,1);
});
