import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {dungeonEvents,eventWindows,announceEvent,stepDungeon,recordEventDeath,recordEventHazard,eventObjective} from '../../js/dungeon-events.js';
const make=()=>{const g=new Game(config,()=>.5);g.start('fire');return g};
function accept(g,id){assert.ok(announceEvent(g,id));const e=g.dungeon.active;g.player.x=e.x-20;g.player.y=e.y-20;stepDungeon(g);assert.equal(e.stage,'active');return e}
test('five scheduled opportunities are unique and can be ignored without penalties',()=>{
 const g=make(),seen=new Set();
 for(const sec of eventWindows){g.tick=sec*50;stepDungeon(g);const e=g.dungeon.active;assert.ok(e);assert.ok(!seen.has(e.id));seen.add(e.id);g.tick=e.until;stepDungeon(g);assert.equal(g.dungeon.active,null);}
 assert.equal(g.dungeon.history.length,5);assert.ok(g.dungeon.history.every(e=>e.outcome==='ignored'));assert.equal(g.chests.length,0);assert.equal(g.player.health,100);
});
test('shrine accumulates only time in circle and awards exactly one chest',()=>{
 const g=make(),e=accept(g,'shrine');g.player.x+=400;for(let i=0;i<20;i++){g.tick++;stepDungeon(g)}assert.equal(e.progress,0);
 g.player.x-=400;for(let i=0;i<750;i++){g.tick++;stepDungeon(g)}assert.equal(g.dungeon.active,null);assert.equal(g.dungeon.history[0].outcome,'completed');assert.equal(g.chests.length,1);stepDungeon(g);assert.equal(g.chests.length,1);
});
test('altar spawns bounded reinforcements and clears them after completion',()=>{
 const g=make(),e=accept(g,'altar');g.tick++;stepDungeon(g);assert.equal(g.enemies.length,2);assert.ok(g.enemies.every(o=>o.eventSerial===e.serial));g.tick=e.until;stepDungeon(g);assert.equal(g.enemies.length,0);assert.equal(g.kills,0);assert.equal(g.chests.length,1);
});
test('guardian only completes on marked target death and is rewarded once',()=>{
 const g=make(),e=accept(g,'guardian');assert.ok(e.target.eventGuardian);recordEventDeath(g,{});assert.equal(e.progress,0);e.target.health=0;g.step();assert.equal(g.dungeon.history[0].outcome,'completed');assert.equal(g.chests.length,1);assert.equal(g.kills,1);
});
test('blood moon tracks kills after acceptance, not prior kills',()=>{
 const g=make();g.kills=40;const e=accept(g,'moon');g.kills+=e.goal-1;g.tick++;stepDungeon(g);assert.equal(e.progress,e.goal-1);g.kills++;g.tick++;stepDungeon(g);assert.equal(g.dungeon.history[0].outcome,'completed');
});
test('collapse warns before rubble damage and fails on third actual hit',()=>{
 const g=make(),e=accept(g,'collapse');g.tick++;stepDungeon(g);assert.equal(g.hazards.length,3);assert.ok(g.hazards.every(h=>h.activeAt>g.tick&&h.type==='rubble'));
 recordEventHazard(g,g.hazards[0],0);assert.equal(e.hits,0);for(let i=0;i<3;i++)recordEventHazard(g,g.hazards[0],10);stepDungeon(g);assert.equal(g.dungeon.history[0].outcome,'failed');assert.equal(g.hazards.length,0);assert.equal(g.chests.length,0);
});
test('anomaly requires all three distinct runes and does not count a rune twice',()=>{
 const g=make(),e=accept(g,'anomaly');for(const rune of e.runes){g.player.x=rune.x-20;g.player.y=rune.y-20;g.tick++;stepDungeon(g);g.tick++;stepDungeon(g);}
 assert.equal(g.dungeon.history[0].progress,3);assert.equal(g.dungeon.history[0].outcome,'completed');assert.equal(g.chests.length,1);
});
test('failed objective expires, death closes active encounter and restart resets state',()=>{
 const g=make(),e=accept(g,'shrine');g.player.x+=400;g.tick=e.until;stepDungeon(g);assert.equal(g.dungeon.history[0].outcome,'failed');assert.equal(g.chests.length,0);
 accept(g,'altar');g.player.health=0;g.step();assert.equal(g.dungeon.history[1].outcome,'failed');g.start('ice');assert.equal(g.dungeon.history.length,0);assert.equal(g.dungeon.active,null);
});
test('disabled events and boss phase do not spawn opportunities',()=>{
 const g=new Game({...config,eventsEnabled:false});g.start('fire');g.tick=eventWindows[0]*50;stepDungeon(g);assert.equal(g.dungeon.active,null);
 const h=make();h.bossSpawned=true;h.tick=eventWindows[0]*50;stepDungeon(h);assert.equal(h.dungeon.active,null);assert.equal(dungeonEvents.length,6);
});
