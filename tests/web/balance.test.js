import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {schools} from '../../js/magic.js';
import {forecast,levelAtXP,spawnInterval,referenceDps} from '../../js/balance.js';
import {simulate} from '../../js/balance-bot.js';

test('all five starter schools begin at rank I with immediate cast',()=>{
 for(const s of schools){const g=new Game(config);assert.ok(g.start(s.id));assert.equal(g.player.magic.ranks[s.id],1);assert.equal(Object.values(g.player.magic.ranks).reduce((a,b)=>a+b,0),1);g.step({aim:[1,0]});assert.ok(g.events.some(e=>e.type==='cast'));assert.equal(g.player.level,1);}
});
test('starting school resets between runs and invalid school is rejected',()=>{
 const g=new Game(config);g.start('fire');g.start('ice');assert.equal(g.player.magic.ranks.fire,0);assert.equal(g.player.magic.ranks.ice,1);assert.equal(g.start('invalid'),false);
});
test('early upgrade pool guarantees damage and mobility options',()=>{
 const g=new Game(config,()=>.5);g.start('ice');g.player.currentExp=g.player.expNeeded;g.levelUp();assert.ok(g.offers.some(o=>o.id==='basic-2'));assert.equal(g.offers.length,3);g.choose();g.player.currentExp=g.player.expNeeded;g.levelUp();assert.ok(g.offers.some(o=>o.id==='basic-0'));
});
test('three distinct regular enemy types unlock during first minute',()=>{
 assert.deepEqual(config.monsters.filter(m=>m.startMinute<1).map(m=>m.name).sort(),['Goblin','Orc','Spider']);
});
test('miniboss spawns once and persists outside the viewport without winning',()=>{
 const g=new Game(config,()=>.5);g.start('fire');g.tick=5*3000;g.spawnEnemies();g.spawnEnemies();assert.equal(g.enemies.filter(e=>e.miniboss).length,1);const boss=g.miniboss;boss.x=100000;g.step();assert.equal(g.miniboss,boss);boss.health=0;g.step();assert.equal(g.bossDefeated,false);assert.equal(g.miniboss,null);g.spawnEnemies();assert.equal(g.miniboss,null);
});
test('spawn ramp is bounded and independent of player stats',()=>{
 const m=config.monsters.find(m=>m.name==='Goblin');assert.equal(spawnInterval(m,0,config.balanceSettings),85);assert.equal(spawnInterval(m,3000,config.balanceSettings),55);assert.ok(spawnInterval(m,600,config.balanceSettings)<85);
});
test('XP forecast and reference DPS are reproducible and monotone',()=>{
 assert.equal(levelAtXP(5,config.levels).level,2);assert.equal(levelAtXP(11,config.levels).level,2);assert.equal(levelAtXP(12,config.levels).level,3);
 const rows=forecast(config,[1,5,25]);assert.equal(rows[0].totalXP,106);assert.ok(rows[2].totalXP>rows[1].totalXP);assert.ok(rows[2].levels[2]>rows[2].levels[0]);assert.ok(referenceDps(20).dps>referenceDps(5).dps);
});
test('seeded bot is reproducible for short runs',()=>{
 const options={school:'ice',seed:2,seconds:20};assert.deepEqual(simulate(config,options),simulate(config,options));
});
