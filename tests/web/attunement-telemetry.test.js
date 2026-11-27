import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game,SpatialHash} from '../../js/simulation.js';
import {equipItem,gearCast,gearDamage} from '../../js/equipment.js';
import {attunements,attuned,itemAttunements} from '../../js/attunements.js';
const make=(school='fire')=>{const g=new Game(config,()=>.99);g.start(school);return g};
const enemy=(x,h=100)=>({x,y:280,width:20,height:20,maxSpeed:0,health:h,maxHealth:h,damage:10,expGiven:1,cd:0});
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,a+' != '+b);
test('attunement requires equipped item and rank II in either school',()=>{
 const g=make();assert.equal(attunements.length,10);
 for(const a of attunements){equipItem(g.player,a.item);g.player.magic.ranks[a.school]=1;assert.equal(attuned(g.player,a.item,a.school),false);g.player.magic.ranks[a.school]=2;assert.ok(attuned(g.player,a.item,a.school));assert.ok(itemAttunements(a.item).includes(a));}
 equipItem(g.player,'quickwand');assert.equal(attuned(g.player,'echo','arcane'),false);
});
test('crystal lance and deep winter strengthen piercing and freeze',()=>{
 const g=make('ice');g.player.magic.ranks.ice=2;equipItem(g.player,'prism');g.shoot([1,0]);assert.equal(g.shots[0].remaining,3);
 equipItem(g.player,'hourglass');g.enemies=[enemy(350)];g.step({relic:true});assert.equal(g.enemies[0].freezeUntil,g.tick+80);
});
test('arcane gear accelerates echo and aegis recharge',()=>{
 const g=make('arcane'),p=g.player;p.magic.ranks.arcane=2;equipItem(p,'echo');
 for(let i=1;i<=4;i++){p.cooldown=0;g.shots=[];g.shoot([1,0]);assert.equal(g.shots.length,i===4?3:2);}
 equipItem(p,'aegis');assert.equal(gearDamage(p,10,'projectile',0),0);assert.equal(p.gearState.robe.readyAt,450);
});
test('lightning attunements increase range and shift gambler probabilities',()=>{
 const g=make('lightning'),p=g.player;p.magic.ranks.lightning=2;equipItem(p,'gambler');const b=[{vx:1,vy:0,damage:10}];close(gearCast(p,b,1,0,()=>.3)[0].damage,20);
 equipItem(p,'longshot');const a=enemy(350),c=enemy(490);g.enemies=[a,c];const h=new SpatialHash();h.insert(a);h.insert(c);g.directHit(a,{damage:10,vx:1,vy:0,school:'lightning'},h);close(c.health,95.5);
});
test('necro gear increases fang recovery and lantern pulse frequency',()=>{
 const g=make('necro'),p=g.player;p.magic.ranks.necro=2;p.health=50;equipItem(p,'fang');g.enemies=[enemy(350,0)];g.step();close(p.health,52.3);close(g.telemetry.healingBySource['gear:fang'],.8);
 equipItem(p,'lantern');p.gearState.relic.count=8;g.enemies=[enemy(350,0),enemy(360)];g.step();close(g.enemies[0].health,90);
});
test('fire attunements strengthen meteor and movement pulses',()=>{
 const g=make(),p=g.player;p.magic.ranks.fire=2;equipItem(p,'meteor');const a=enemy(350),b=enemy(390),h=new SpatialHash();h.insert(a);h.insert(b);g.directHit(a,{damage:10,vx:1,vy:0,school:'fire',meteor:{used:false}},h);close(b.health,93.5);
 equipItem(p,'trail');g.enemies=[enemy(320)];g.step({x:1});close(g.enemies[0].health,95);
});
test('telemetry tracks effective damage, overkill and exactly one projectile hit per bolt',()=>{
 const g=make();g.shoot([1,0]);const shot=g.shots[0],a=enemy(350,4),b=enemy(390,5),h=new SpatialHash();h.insert(a);h.insert(b);
 g.directHit(a,shot,h);g.directHit(b,shot,h);const t=g.reportCombat();assert.equal(t.casts,1);assert.equal(t.bolts,1);assert.equal(t.boltsHit,1);assert.equal(t.directHits,2);close(t.damage,9);close(t.overkill,11);close(t.accuracy,1);close(t.damageBySource['direct:fire'].effective,9);
});
test('incoming telemetry separates mitigated hits, lethal truncation and healing',()=>{
 const g=make(),p=g.player;equipItem(p,'linen');close(g.hurtPlayer(10,'contact',null,'Goblin'),8.8);g.healPlayer(5,'necro','test');close(g.telemetry.healingBySource.test,5);close(g.telemetry.prevented,1.2);p.health=2;g.hurtPlayer(100,'hazard',null,'rubble');close(g.telemetry.incoming,10.8);close(g.telemetry.incomingBySource['hazard:rubble'].applied,2);close(g.telemetry.incomingBySource['hazard:rubble'].prevented,12);
});
test('telemetry counts health costs and resets on restart',()=>{
 const g=make();equipItem(g.player,'crown');g.step({relic:true});close(g.telemetry.selfDamage,10);close(g.telemetry.selfDamageBySource['gear:crown'],10);g.start('fire');assert.equal(g.telemetry.selfDamage,0);assert.equal(g.telemetry.damage,0);
});
