import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {schools,masteries,eligibleMastery,applyUpgrade,upgradeOffers,boltPattern,pierceCount,canLearnSchool} from '../../js/magic.js';
import {initEnemy,stepEnemy} from '../../js/enemies.js';
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,a+' != '+b);
const enemy=(x,h=100)=>({x,y:280,width:20,height:20,maxSpeed:0,health:h,maxHealth:h,damage:10,expGiven:1,cd:0});
const bolt=(x)=>({x,y:280,width:5,height:5,vx:0,vy:0,damage:10,remaining:1});
function pure(id){const g=new Game(config,()=>.99);g.start(id);g.player.level=15;g.player.magic.ranks[id]=5;const m=eligibleMastery(g.player);assert.ok(m);assert.ok(applyUpgrade(g.player,{kind:'mastery',id:m.id},config.skills,0));g.player.cooldown=50;return g}
test('all five capstones require level 15, rank V and one school; lock secondary permanently',()=>{
 for(const s of schools){
  const g=new Game(config,()=>.5);g.start(s.id);const p=g.player;p.level=14;p.magic.ranks[s.id]=5;assert.equal(eligibleMastery(p),null);
  p.level=15;p.magic.ranks[s.id]=4;assert.equal(eligibleMastery(p),null);p.magic.ranks[s.id]=5;
  const m=masteries.find(m=>m.school===s.id);assert.equal(upgradeOffers(p,config.skills,()=>.5)[0].id,m.id);
  assert.ok(applyUpgrade(p,{kind:'mastery',id:m.id},config.skills,0));assert.equal(eligibleMastery(p),null);
  for(const other of schools.filter(o=>o.id!==s.id))assert.equal(canLearnSchool(p,other.id),false);
  g.start(s.id);assert.equal(g.player.magic.mastery,null);
  g.player.level=15;g.player.magic.ranks[s.id]=5;g.player.magic.ranks[schools.find(o=>o.id!==s.id).id]=1;assert.equal(eligibleMastery(g.player),null);
 }
});
test('inferno raises burn and area damage',()=>{
 const g=pure('fire'),a=enemy(350),b=enemy(430);g.enemies=[a,b];g.shots.push(bolt(350));g.step();close(a.burnDamage,9.1);close(b.health,93.5);
});
test('absolute zero adds piercing and bonus damage to chilled enemies',()=>{
 const g=pure('ice'),a=enemy(350);a.slowUntil=100;a.slowFactor=.5;g.enemies=[a];g.shots.push(bolt(350));g.step();assert.equal(pierceCount(g.player),5);close(a.health,86);
});
test('tempest adds two chain jumps',()=>{
 const g=pure('lightning');g.enemies=Array.from({length:7},(_,i)=>enemy(350+i*25));g.shots.push(bolt(350));g.step();assert.equal(g.events.filter(e=>e.type==='chain').length,5);
});
test('lich boosts death pulse and healing',()=>{
 const g=pure('necro'),a=enemy(350,10),b=enemy(430);g.player.health=50;g.enemies=[a,b];g.shots.push(bolt(350));g.step();close(g.player.health,54);close(b.health,94);
});
test('archmage adds bolts and shortens shield recharge',()=>{
 const g=pure('arcane');g.player.magic.shieldReady=true;assert.equal(boltPattern(g.player,1,0).length,5);g.hurtPlayer(20);assert.equal(g.player.magic.shieldUntil,350);
});
test('dragon resists freeze and has strengthened health and attacks',()=>{
 const g=new Game(config),e=initEnemy(config.monsters.find(m=>m.name==='Dragon'),100,280,0);assert.equal(e.health,18000);assert.equal(e.damage,75);
 g.tick=75;stepEnemy(g,e,0);assert.equal(e.action.kind,'dragon-windup');g.tick=e.action.until;stepEnemy(g,e,0);assert.equal(g.hostiles.length,5);assert.equal(g.hostiles[0].damage,38);
});
