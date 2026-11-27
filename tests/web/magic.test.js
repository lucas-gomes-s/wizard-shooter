import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {upgradeOffers,applyUpgrade,boltPattern} from '../../js/magic.js';
const game=()=>new Game(config,()=>.5);
const enemy=(x,y,health=100)=>({x,y,width:20,height:20,maxSpeed:0,health,maxHealth:health,damage:10,expGiven:1,cd:0});
const bolt=(x,y,damage=10,remaining=1)=>({x,y,width:5,height:5,vx:0,vy:0,damage,remaining});
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,a+' != '+b);
test('first level-up offers three distinct schools, rejects unavailable indices',()=>{
 const g=game();g.player.currentExp=5;g.levelUp();
 assert.equal(g.offers.length,3);assert.ok(g.offers.every(o=>o.kind==='school'));assert.equal(new Set(g.offers.map(o=>o.id)).size,3);
 assert.equal(g.choose(-1),false);assert.equal(g.choose(3),false);
 const id=g.offers[0].id;assert.ok(g.choose());assert.equal(g.player.magic.ranks[id],1);
});
test('subsequent offers prioritize eligible synergy and exclude unlearned third schools',()=>{
 const g=game(),p=g.player;p.level=8;p.magic.ranks.fire=2;p.magic.ranks.ice=2;
 const offers=upgradeOffers(p,config.skills,()=>.5);
 assert.equal(offers[0].id,'steam');assert.ok(offers.every(o=>o.id!=='arcane'));
 assert.ok(applyUpgrade(p,offers[0],config.skills,0));
 assert.ok(!applyUpgrade(p,offers[0],config.skills,0));
 assert.ok(upgradeOffers(p,config.skills,()=>.5).every(o=>o.id!=='steam'));
 assert.equal(applyUpgrade(p,{kind:'synergy',id:'storm'},config.skills,0),false);
});
test('arcane spread preserves manual direction and changes damage per bolt',()=>{
 const p=game().player;p.magic.ranks.arcane=1;
 const pair=boltPattern(p,1,0);assert.equal(pair.length,2);close(pair[0].damage,7.5);close(pair[0].vy,-pair[1].vy);
 p.magic.ranks.arcane=3;const triple=boltPattern(p,0,-1);assert.equal(triple.length,3);close(triple[1].vy,-8);close(triple[1].damage,7);
});
test('fire applies four timed burn ticks with no recursive effects',()=>{
 const g=game(),e=enemy(350,280);g.player.magic.ranks.fire=1;g.enemies.push(e);g.shots.push(bolt(350,280));
 g.step();close(e.health,90);
 for(let i=0;i<100;i++)g.step();close(e.health,82);
});
test('frost pierces distinct enemies only and freezes every third hit',()=>{
 const g=game(),a=enemy(350,280),b=enemy(350,280),c=enemy(350,280);
 g.player.magic.ranks.ice=5;g.enemies.push(a,b,c);g.shots.push(bolt(350,280,10,3));g.step();
 assert.deepEqual([a.health,b.health,c.health],[90,90,90]);
 for(let i=0;i<2;i++){g.shots.push(bolt(350,280));g.step()}
 assert.ok(a.freezeUntil>g.tick);assert.equal(b.health,90);
});
test('piercing bolt cannot repeatedly hit same target on later ticks',()=>{
 const g=game(),a=enemy(350,280);g.enemies.push(a);g.shots.push(bolt(350,280,10,2));
 g.step();g.step();assert.equal(a.health,90);assert.equal(g.shots[0].remaining,1);
});
test('lightning chains to nearest distinct targets and does not recurse',()=>{
 const g=game(),a=enemy(350,280),b=enemy(390,280),c=enemy(430,280);
 g.player.magic.ranks.lightning=1;g.enemies.push(a,b,c);g.shots.push(bolt(350,280));g.step();
 close(a.health,90);close(b.health,96);close(c.health,100);
 assert.equal(g.events.filter(e=>e.type==='chain').length,1);
});
test('necro death rewards are once per enemy; curse boosts subsequent hits',()=>{
 const g=game(),a=enemy(350,280,30);g.player.magic.ranks.necro=3;g.player.health=50;
 g.enemies.push(a);g.shots.push(bolt(350,280));g.step();close(a.health,20);
 g.shots.push(bolt(350,280));g.step();close(a.health,8.5);
 g.shots.push(bolt(350,280));g.step();assert.equal(g.kills,1);close(g.player.health,52);assert.equal(g.player.currentExp,1);
});
test('arcane shield blocks contact once, then recharges at deadline',()=>{
 const g=game(),a=enemy(280,280);g.player.magic.ranks.arcane=2;g.player.magic.shieldReady=true;g.enemies.push(a);
 g.step();assert.equal(g.player.health,100);assert.equal(g.player.magic.shieldReady,false);
 a.cd=0;g.step();assert.equal(g.player.health,90);
 g.enemies=[];g.tick=g.player.magic.shieldUntil-1;g.step();assert.equal(g.player.magic.shieldReady,true);
});
test('steam damages and slows nearby targets only',()=>{
 const g=game(),a=enemy(350,280),b=enemy(390,280),c=enemy(500,280);
 g.player.magic.ranks.fire=2;g.player.magic.ranks.ice=2;g.player.magic.synergies.push('steam');
 g.enemies.push(a,b,c);g.shots.push(bolt(350,280));g.step();
 close(b.health,96.5);close(c.health,100);close(b.slowFactor,.5);
});
test('storm prism adds one chain jump',()=>{
 const g=game();g.player.magic.ranks.lightning=2;g.player.magic.ranks.arcane=2;g.player.magic.synergies.push('storm');
 const a=enemy(350,280),b=enemy(390,280),c=enemy(430,280);g.enemies.push(a,b,c);g.shots.push(bolt(350,280));g.step();
 assert.equal(g.events.filter(e=>e.type==='chain').length,2);close(c.health,95.5);
});
test('soulfire and necro bursts resolve secondary deaths only once',()=>{
 const g=game();g.player.magic.ranks.fire=2;g.player.magic.ranks.necro=5;g.player.magic.synergies.push('soulfire');
 const a=enemy(350,280,10),b=enemy(380,280,8);g.enemies.push(a,b);g.shots.push(bolt(350,280));g.step();
 assert.equal(g.kills,2);assert.equal(g.player.currentExp,2);assert.equal(g.enemies.length,0);
});
test('reset removes magic, synergies, shield, offers and projectiles',()=>{
 const g=game();g.player.magic.ranks.arcane=5;g.player.magic.synergies.push('storm');g.player.magic.shieldReady=true;g.offers=[{}];g.shots=[{}];g.reset();
 assert.ok(Object.values(g.player.magic.ranks).every(r=>r===0));assert.deepEqual(g.player.magic.synergies,[]);assert.equal(g.player.magic.shieldReady,false);assert.deepEqual(g.offers,[]);assert.deepEqual(g.shots,[]);
});
