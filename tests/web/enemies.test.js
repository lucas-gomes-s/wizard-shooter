import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {initEnemy,stepEnemy,stepHazards,frontalMultiplier,ENEMY_CAP,BOSS_MINUTE} from '../../js/enemies.js';
const make=()=>new Game(config,()=>.5);
const enemy=(name,x=100,y=280)=>initEnemy(config.monsters.find(m=>m.name===name),x,y,0);
test('elite modifies stats and rewards without mutating templates',()=>{
 const m=config.monsters.find(m=>m.name==='Goblin'),e=initEnemy(m,0,0,0,true);
 assert.equal(e.elite,true);assert.equal(e.health,Math.round(m.health*1.6));assert.equal(e.damage,Math.round(m.damage*1.25));assert.equal(e.expGiven,Math.ceil(m.expGiven*1.8));assert.equal(m.health,10);
});
test('orc telegraphs, charges in locked direction, then recovers',()=>{
 const g=make(),e=enemy('Orc');g.tick=50;stepEnemy(g,e);
 assert.equal(e.action.kind,'orc-windup');const x=e.x,angle=e.action.angle;
 g.player.y+=100;g.tick=e.action.until-1;stepEnemy(g,e);assert.equal(e.x,x);
 g.tick++;stepEnemy(g,e);assert.equal(e.action.kind,'charge');assert.equal(e.action.angle,angle);
 g.tick++;stepEnemy(g,e);assert.ok(e.x>x);assert.equal(e.y,280);
 g.tick=e.action.until;stepEnemy(g,e);assert.equal(e.action.kind,'recover');
});
test('frozen enemy cannot execute windup and action is delayed',()=>{
 const g=make(),e=enemy('Orc');g.tick=50;stepEnemy(g,e);const until=e.action.until;
 g.tick=until;stepEnemy(g,e,0);assert.equal(e.action.kind,'orc-windup');assert.equal(e.action.until,until+1);
});
test('web warns first and then slows movement without damaging player',()=>{
 const g=make(),e=enemy('Spider',200);g.tick=50;stepEnemy(g,e);assert.equal(g.hazards.length,1);
 const h=g.hazards[0];stepHazards(g);assert.equal(g.player.webUntil,undefined);
 g.tick=h.activeAt;stepHazards(g);assert.ok(g.player.webUntil>g.tick);assert.equal(g.player.health,100);
 const x=g.player.x;g.step({x:1});assert.ok(Math.abs(g.player.x-x-1.1)<1e-8);
});
test('zombie accelerates below half health',()=>{
 const g=make(),a=enemy('Zombie'),b=enemy('Zombie');b.health=b.maxHealth*.4;
 stepEnemy(g,a);stepEnemy(g,b);assert.ok(b.x>a.x);
});
test('knight reduces frontal bolts only; side and rear bypass armor',()=>{
 const e=enemy('Knight');e.facing=0;
 assert.equal(frontalMultiplier(e,{vx:-8,vy:0}),.35);
 assert.equal(frontalMultiplier(e,{vx:8,vy:0}),1);
 assert.equal(frontalMultiplier(e,{vx:0,vy:8}),1);
 assert.equal(frontalMultiplier(e,{vx:0,vy:0}),1);
});
test('vampire heals only from actual contact damage',()=>{
 const g=make(),e=enemy('Vampire',280,280);e.health=100;e.maxSpeed=0;g.enemies.push(e);
 g.step();assert.equal(g.player.health,100-e.damage);assert.equal(e.health,100+e.damage*2);
 const g2=make(),e2=enemy('Vampire',280,280);e2.health=100;e2.maxSpeed=0;g2.enemies.push(e2);
 g2.player.magic.ranks.arcane=2;g2.player.magic.shieldReady=true;g2.step();assert.equal(e2.health,100);
});
test('reaper teleports only after the warning deadline',()=>{
 const g=make(),e=enemy('Reaper');g.tick=50;stepEnemy(g,e);assert.equal(e.action.kind,'reaper-windup');
 const {x,y,until}=e.action;g.tick=until-1;stepEnemy(g,e);assert.equal(e.x,100);
 g.tick=until;stepEnemy(g,e);assert.equal(e.x,x-e.width/2);assert.equal(e.y,y-e.height/2);
});
test('demon fires three locked-angle projectiles after windup',()=>{
 const g=make(),e=enemy('Demon');g.tick=50;stepEnemy(g,e);assert.equal(e.action.kind,'demon-windup');
 assert.equal(g.hostiles.length,0);g.tick=e.action.until;stepEnemy(g,e);assert.equal(g.hostiles.length,3);
});
test('hostile projectile hits once and hazard damages once after warning',()=>{
 const g=make();g.hostiles.push({x:300,y:300,vx:0,vy:0,radius:6,damage:10,age:0});
 g.hazards.push({type:'flame',x:300,y:300,radius:40,activeAt:20,until:30,damage:15,hit:false});
 stepHazards(g);assert.equal(g.player.health,90);assert.equal(g.hostiles.length,0);
 g.tick=20;stepHazards(g);stepHazards(g);assert.equal(g.player.health,75);
});
test('dragon spawns exactly once at 25 minutes and persists outside viewport',()=>{
 const g=make();g.tick=BOSS_MINUTE*60*50-1;g.spawnEnemies();assert.equal(g.boss,null);
 g.tick++;g.spawnEnemies();g.spawnEnemies();assert.equal(g.enemies.filter(e=>e.boss).length,1);
 const boss=g.boss;assert.equal(boss.maxHealth,6000);boss.x=100000;g.step();assert.equal(g.boss,boss);
});
test('dragon phases switch by health and telegraph stronger attacks',()=>{
 const g=make(),e=enemy('Dragon');g.tick=75;stepEnemy(g,e);assert.equal(e.bossPhase,1);
 g.tick=e.action.until;stepEnemy(g,e);assert.equal(g.hostiles.length,5);
 e.health=e.maxHealth*.5;g.tick=e.nextAttack;stepEnemy(g,e);assert.equal(e.bossPhase,2);
 g.tick=e.action.until;stepEnemy(g,e);assert.equal(g.hostiles.length,13);assert.equal(g.hazards.length,1);
 e.health=e.maxHealth*.2;g.tick=e.nextAttack;stepEnemy(g,e);assert.equal(e.bossPhase,3);
 g.tick=e.action.until;stepEnemy(g,e);assert.equal(g.hostiles.length,25);assert.equal(g.hazards.length,4);
});
test('boss death wins once and endless resumes without respawning dragon',()=>{
 const g=make(),e=enemy('Dragon',350,280);g.bossSpawned=true;e.health=1;g.enemies.push(e);
 g.shots.push({x:350,y:280,width:5,height:5,vx:0,vy:0,damage:10});
 g.step();assert.equal(g.phase,'victory');assert.equal(g.bossDefeated,true);assert.equal(g.kills,1);
 const t=g.tick;g.step();assert.equal(g.tick,t);
 g.hostiles.push({});g.hazards.push({});assert.ok(g.continueEndless());assert.equal(g.endless,true);
 assert.equal(g.hostiles.length,0);assert.equal(g.hazards.length,0);
 g.tick=BOSS_MINUTE*60*50+10000;g.spawnEnemies();assert.equal(g.boss,null);
 assert.equal(g.continueEndless(),false);g.reset();assert.equal(g.bossDefeated,false);assert.equal(g.endless,false);
});
test('ordinary spawning respects cap, boss can still appear',()=>{
 const g=make();g.enemies=Array.from({length:ENEMY_CAP},()=>enemy('Goblin'));g.enemyTimers[1]=config.monsters[1].spawn-1;
 g.spawnEnemies();assert.equal(g.enemies.length,ENEMY_CAP);
 g.tick=BOSS_MINUTE*60*50;g.spawnEnemies();assert.equal(g.enemies.length,ENEMY_CAP+1+config.minibosses.length);assert.ok(g.boss);
});
