import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {equipment,equipmentSlots,itemById,equipItem,lootOffers,gearMovement,gearCast,gearDamage} from '../../js/equipment.js';
const make=()=>{const g=new Game(config,()=>.5);g.start('fire');return g};
const enemy=(x,y=280,h=100)=>({x,y,width:20,height:20,maxSpeed:0,health:h,maxHealth:h,damage:10,expGiven:1,cd:0});
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,a+' != '+b);
test('catalog has 24 unique items, six per slot and all rarity tiers',()=>{
 assert.equal(equipment.length,24);assert.equal(new Set(equipment.map(i=>i.id)).size,24);
 for(const slot of equipmentSlots){const items=equipment.filter(i=>i.slot===slot);assert.equal(items.length,6);assert.equal(new Set(items.map(i=>i.rarity)).size,4);}
});
test('chests offer three distinct slots and a top-tier item without offering equipped gear',()=>{
 const g=make();equipItem(g.player,'meteor');for(const tier of [0,1,2,3]){const o=lootOffers(g.player,tier,()=>.5);assert.equal(o.length,3);assert.equal(new Set(o.map(i=>i.slot)).size,3);assert.equal(o[0].rarity,['common','rare','epic','legendary'][tier]);assert.ok(o.every(i=>i.id!=='meteor'));}
});
test('equipment replacements do not stack or mutate base stats',()=>{
 const g=make(),p=g.player;equipItem(p,'swift');close(gearMovement(p,0),1.12);equipItem(p,'silk');close(gearMovement(p,0),1);assert.equal(p.maxSpeed,2);assert.equal(equipItem(p,'silk'),false);g.start('ice');assert.ok(Object.values(g.player.equipment).every(v=>v===null));
});
test('treasure spawns at minute two, pauses upon pickup, and supports skip or equip',()=>{
 const g=make(),p=g.player;g.tick=6000;g.stepLoot();assert.equal(g.chests.length,1);g.stepLoot();assert.equal(g.chests.length,1);
 Object.assign(p,{x:g.chests[0].x,y:g.chests[0].y});g.stepLoot();assert.equal(g.phase,'loot');assert.equal(g.chestsOpened,1);const tick=g.tick;g.step();assert.equal(g.tick,tick);
 assert.equal(g.chooseLoot(4),false);assert.ok(g.chooseLoot(-1));assert.equal(g.phase,'playing');assert.equal(g.lootHistory.length,0);
 g.dropChest(p.x+20,p.y+20,2,'test');g.stepLoot();const item=g.loot[0];assert.ok(g.chooseLoot(0));assert.equal(p.equipment[item.slot],item.id);assert.equal(g.lootHistory.length,1);
});
test('guardian death drops exactly one chest and disabled gear leaves baseline intact',()=>{
 const g=make(),e=enemy(350,280,0);e.miniboss=true;e.lootTier=3;g.enemies=[e];g.step();assert.equal(g.chests.length,1);assert.equal(g.chests[0].tier,3);g.step();assert.equal(g.chests.length,1);
 const h=new Game({...config,equipmentEnabled:false});h.start('fire');h.tick=6000;h.stepLoot();assert.equal(h.chests.length,0);
});
test('chests expire and are bounded',()=>{
 const g=make();for(let i=0;i<12;i++)g.dropChest(500,500,1,'test');assert.equal(g.chests.length,8);g.tick=4500;g.stepLoot();assert.equal(g.chests.length,0);
});
test('staff modifiers fire on correct casts and replace without stacking',()=>{
 const g=make(),p=g.player;equipItem(p,'echo');for(let i=1;i<=5;i++){p.cooldown=0;g.shots=[];g.shoot([1,0]);assert.equal(g.shots.length,i===5?2:1)}
 equipItem(p,'bloodwood');for(let i=1;i<=4;i++){p.cooldown=0;g.shots=[];g.shoot([1,0]);close(g.shots[0].damage,i===4?15:10)}close(p.health,98);
 equipItem(p,'quickwand');p.cooldown=0;g.shoot([1,0]);assert.equal(p.cooldown,44);
 equipItem(p,'prism');p.cooldown=0;g.shots=[];g.shoot([1,0]);assert.equal(g.shots[0].remaining,2);
});
test('robe damage, phantom duration and aegis cooldown work',()=>{
 const g=make(),p=g.player;equipItem(p,'linen');close(g.hurtPlayer(10),8.8);equipItem(p,'wardrobe');close(g.hurtPlayer(10,'projectile'),7.5);
 equipItem(p,'phantom');close(g.hurtPlayer(10),10);close(g.hurtPlayer(10),0);g.tick=30;close(g.hurtPlayer(10),10);
 equipItem(p,'aegis',g.tick);close(g.hurtPlayer(10),0);close(g.hurtPlayer(10),10);
});
test('silk boots cancel webs, relic fang heals once per death',()=>{
 const g=make(),p=g.player;equipItem(p,'silk');p.webUntil=100;const x=p.x;g.step({x:1});close(p.x-x,2);
 equipItem(p,'fang');p.health=50;g.enemies=[enemy(350,280,0)];g.step();close(p.health,50.5);g.step();close(p.health,50.5);
});
test('meteor impact uses shared per-cast token and no recursive hits',()=>{
 const g=make(),p=g.player;equipItem(p,'meteor');for(let i=0;i<3;i++){p.cooldown=0;g.shots=[];g.shoot([1,0]);}
 const token=g.shots[0].meteor;assert.ok(token);g.shots=[];const a=enemy(350),b=enemy(390);g.enemies=[a,b];g.shots=[{x:350,y:280,width:5,height:5,vx:0,vy:0,damage:10,meteor:token},{x:390,y:280,width:5,height:5,vx:0,vy:0,damage:10,meteor:token}];g.step();assert.equal(g.events.filter(e=>e.type==='burst').length,1);assert.equal(token.used,true);
});
test('reactive thorns resolves killed enemies once even from a projectile',()=>{
 const g=make(),p=g.player;equipItem(p,'thorns');g.enemies=[enemy(350,280,4)];g.hostiles=[{x:300,y:300,vx:0,vy:0,radius:6,damage:10,age:0}];g.step();assert.equal(g.kills,1);assert.equal(g.enemies.length,0);assert.equal(p.currentExp,1);
});
