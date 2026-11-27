import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {equipItem} from '../../js/equipment.js';
import {activeInfo,activeGear} from '../../js/active-gear.js';
import {addGold,stepMarket,merchantWindows,itemPrices} from '../../js/merchant.js';
const make=()=>{const g=new Game(config,()=>.5);g.start('fire');return g};
const enemy=(x,y=280,h=100)=>({x,y,width:20,height:20,maxSpeed:0,health:h,maxHealth:h,damage:10,expGiven:1,cd:0});
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,a+' != '+b);
test('boot dash is directional, bounded by cooldown and replacement cannot reset cooldown',()=>{
 const g=make(),p=g.player;equipItem(p,'runner');const x=p.x;g.step({x:1,boots:true});close(p.x-x,87);assert.equal(g.activeHistory.length,1);assert.ok(activeInfo(p,'boots',g.tick).remaining>0);
 const next=p.x;g.step({x:1,boots:true});close(p.x-next,2);equipItem(p,'phaseboots',g.tick);g.step({x:1,boots:true});assert.equal(g.activeHistory.length,1);g.start('ice');assert.equal(g.player.activeReady.boots,0);
});
test('escape clears webs and blocks contact but not projectile damage',()=>{
 const g=make(),p=g.player;equipItem(p,'escape');p.webUntil=100;g.step({x:1,boots:true});assert.equal(p.webUntil,0);assert.equal(g.hurtPlayer(10,'contact'),0);close(g.hurtPlayer(10,'projectile'),10);
});
test('phase shift provides short universal immunity',()=>{
 const g=make(),p=g.player;equipItem(p,'phaseboots');g.step({x:1,boots:true});assert.equal(g.hurtPlayer(10,'hazard'),0);g.tick+=25;close(g.hurtPlayer(10,'hazard'),10);
});
test('blazing step damages nearby enemies at the destination',()=>{
 const g=make(),p=g.player;equipItem(p,'trail');g.enemies=[enemy(390)];g.step({x:1,boots:true});assert.ok(g.enemies[0].health<91);
});
test('hourglass freezes nearby targets, soul eruption damages them',()=>{
 const g=make(),p=g.player;equipItem(p,'hourglass');g.enemies=[enemy(350),enemy(550)];g.step({relic:true});assert.equal(g.enemies[0].freezeUntil,g.tick+60);assert.equal(g.enemies[1].freezeUntil,undefined);
 const h=make();equipItem(h.player,'lantern');h.enemies=[enemy(350)];h.step({relic:true});close(h.enemies[0].health,82);
});
test('forbidden power has health cost and temporary buff, tonic heals without overheal',()=>{
 const g=make(),p=g.player;equipItem(p,'crown');p.cooldown=0;g.step({relic:true,aim:[1,0]});close(p.health,90);close(g.shots[0].damage,18.75);assert.ok(p.crownUntil>g.tick);
 const h=make();equipItem(h.player,'tonic');h.step({relic:true});assert.equal(h.activeHistory.length,0);h.player.health=95;h.step({relic:true});close(h.player.health,100);assert.equal(h.activeHistory.length,1);
});
test('gold is earned once per kill and reset between runs',()=>{
 const g=make(),e=enemy(350,280,0);e.expGiven=20;g.kills=3;g.enemies=[e];g.step();assert.equal(g.player.gold,1);g.step();assert.equal(g.player.gold,1);g.start('ice');assert.equal(g.player.gold,0);
});
function open(g){g.tick=merchantWindows[0]*50;stepMarket(g);const m=g.market.merchant;assert.ok(m);g.player.x=m.x-20;g.player.y=m.y-20;stepMarket(g);assert.equal(g.phase,'shop');}
test('merchant pauses time, rejects unaffordable purchase and allows leaving',()=>{
 const g=make();open(g);assert.equal(g.market.offers.length,4);const t=g.tick;g.step();assert.equal(g.tick,t);assert.equal(g.choosePurchase(0),false);assert.equal(g.player.gold,0);assert.ok(g.choosePurchase(-1));assert.equal(g.phase,'playing');assert.equal(g.market.history.length,0);
});
test('merchant purchase is atomic, equips exactly one item and deducts gold',()=>{
 const g=make();addGold(g,300);open(g);const offer=g.market.offers[0];assert.equal(offer.price,itemPrices[offer.rarity]);assert.ok(g.choosePurchase(0));assert.equal(g.player.equipment[offer.slot],offer.id);assert.equal(g.player.gold,300-offer.price);assert.equal(g.market.spent,offer.price);assert.equal(g.choosePurchase(0),false);
});
test('merchant healing is optional, cannot buy at full health, and expires',()=>{
 const g=make();addGold(g,100);open(g);const i=g.market.offers.findIndex(o=>o.kind==='heal');assert.equal(g.choosePurchase(i),false);g.player.health=50;assert.ok(g.choosePurchase(i));close(g.player.health,85);assert.equal(g.player.gold,65);
 const h=make();h.tick=merchantWindows[0]*50;stepMarket(h);h.tick=h.market.merchant.until;stepMarket(h);assert.equal(h.market.merchant,null);
});
test('disabled economy has no gold or merchant, all active gear maps to real items',()=>{
 const g=new Game({...config,economyEnabled:false});g.start('fire');addGold(g,100);g.tick=merchantWindows[0]*50;stepMarket(g);assert.equal(g.player.gold,0);assert.equal(g.market.merchant,null);
 assert.equal(Object.keys(activeGear).length,8);
});
