import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {schools,synergies,synergyFor,applyUpgrade,upgradeOffers,boltPattern,pierceCount} from '../../js/magic.js';
const enemy=(x,y=280,h=100)=>({x,y,width:20,height:20,maxSpeed:0,health:h,maxHealth:h,damage:10,expGiven:1,cd:0});
const bolt=(x,y=280,extra={})=>({x,y,width:5,height:5,vx:0,vy:0,damage:10,remaining:1,...extra});
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,a+' != '+b);
function build(id){
 const combo=synergies.find(s=>s.id===id),g=new Game(config,()=>.99);
 g.start(combo.requires[0]);g.player.level=10; // use the ordinary upgrade path
 for(const school of combo.requires)while(g.player.magic.ranks[school]<2)assert.ok(applyUpgrade(g.player,{kind:'school',id:school},config.skills,0));
 assert.ok(applyUpgrade(g.player,{kind:'synergy',id},config.skills,0));return g;
}
test('all ten distinct pairs have one unique fusion independent of school order',()=>{
 assert.equal(synergies.length,10);const ids=new Set();
 for(let i=0;i<schools.length;i++)for(let j=i+1;j<schools.length;j++){
  const a=schools[i].id,b=schools[j].id,combo=synergyFor(a,b);assert.ok(combo);assert.equal(combo,synergyFor(b,a));ids.add(combo.id);
  for(const [primary,secondary] of [[a,b],[b,a]]){
   const g=new Game(config,()=>.5);g.start(primary);g.player.level=10;
   for(const s of [primary,secondary])while(g.player.magic.ranks[s]<2)assert.ok(applyUpgrade(g.player,{kind:'school',id:s},config.skills,0));
   const offers=upgradeOffers(g.player,config.skills,()=>.5);assert.equal(offers[0].id,combo.id);
   assert.ok(applyUpgrade(g.player,offers[0],config.skills,0));assert.equal(applyUpgrade(g.player,offers[0],config.skills,0),false);
  }
 }
 assert.equal(ids.size,10);assert.equal(synergyFor('fire','fire'),null);
});
test('plasma chains burn without recursively chaining or stacking',()=>{
 const g=build('plasma'),a=enemy(350),b=enemy(390),c=enemy(550);
 g.enemies.push(a,b,c);g.shots.push(bolt(350));g.step();
 close(b.health,95.5);assert.equal(b.burnDamage,4);assert.ok(b.burnUntil>g.tick);assert.equal(c.burnUntil,undefined);
 const first=b.burnNext;g.shots.push(bolt(350));g.step();assert.equal(b.burnDamage,4);assert.equal(b.burnNext,first);close(b.health,91);
});
test('starfire replaces every fourth cast with five wide explosive bolts',()=>{
 const g=build('starfall'),p=g.player;
 for(let i=1;i<=4;i++){p.cooldown=0;g.shots=[];g.shoot([1,0]);assert.equal(g.shots.length,i===4?5:2);assert.equal(g.shots.every(s=>s.star),i===4);}
 const a=enemy(350),b=enemy(385),c=enemy(450);g.enemies=[a,b,c];g.shots=[bolt(350,280,{star:true})];g.step();close(b.health,97.5);close(c.health,100);
});
test('thunderfrost chills, then freezes with per-target cooldown',()=>{
 const g=build('thunderfrost'),a=enemy(350),b=enemy(390);g.enemies=[a,b];
 g.shots.push(bolt(350));g.step();close(b.slowFactor,.55);assert.equal(b.freezeUntil,undefined);
 g.shots.push(bolt(350));g.step();assert.equal(b.freezeUntil,g.tick+40);const deadline=b.freezeUntil;
 g.shots.push(bolt(350));g.step();assert.equal(b.freezeUntil,deadline);
});
test('gravefrost triggers on chilled death and does not double-award kills',()=>{
 const g=build('gravefrost'),a=enemy(350,280,10),b=enemy(385),c=enemy(450);
 g.enemies=[a,b,c];g.shots.push(bolt(350));g.step();
 assert.equal(g.kills,1);close(b.health,96.5);close(b.slowFactor,.5);close(c.health,100);assert.equal(g.events.filter(e=>e.type==='burst'&&e.school==='gravefrost').length,1);
});
test('glacial mirror adds piercing and freezes on shield block only',()=>{
 const g=build('mirror'),a=enemy(280),b=enemy(350),c=enemy(500);g.enemies=[a,b,c];
 assert.equal(pierceCount(g.player),2);g.step();assert.equal(g.player.health,100);assert.equal(g.player.magic.shieldReady,false);
 assert.equal(a.freezeUntil,g.tick+40);assert.equal(b.freezeUntil,g.tick+40);assert.equal(c.freezeUntil,undefined);
});
test('soul conductor marks chain targets and pays a bounded kill bonus',()=>{
 const g=build('reaping'),a=enemy(350),b=enemy(390,280,4),c=enemy(460);
 g.player.health=50;g.enemies=[a,b,c];g.shots.push(bolt(350));g.step();
 assert.equal(g.kills,1);close(g.player.health,53);close(a.health,86);close(c.health,100);assert.equal(g.events.filter(e=>e.type==='chain'&&e.school==='reaping').length,1);
});
test('soul ward reduces recharge and shield block heals and damages nearby targets',()=>{
 const g=build('soulward'),a=enemy(280),b=enemy(350),c=enemy(500);
 g.player.health=50;g.enemies=[a,b,c];g.step();close(g.player.health,58);close(a.health,95);close(b.health,95);close(c.health,100);
 const deadline=g.player.magic.shieldUntil;g.enemies=[];g.enemies.push(enemy(350,280,1));g.shots.push(bolt(350));g.step();
 assert.equal(g.player.magic.shieldUntil,deadline-15);assert.equal(g.kills,1);
});
