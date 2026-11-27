import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {initEnemy,stepEnemy} from '../../js/enemies.js';
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,a+' != '+b);
function enemy(g,name){return initEnemy(config.monsters.find(m=>m.name===name),100,280,0);}
test('calibrated demon windup and projectile damage are configurable',()=>{
 for(const [balance,windup,damage] of [[{},45,18],[config.combatBalance,55,14]]){
  const g=new Game({...config,combatBalance:balance},()=>.5),e=enemy(g,'Demon');g.tick=50;stepEnemy(g,e);assert.equal(e.action.until-g.tick,windup);g.tick=e.action.until;stepEnemy(g,e);assert.equal(g.hostiles.length,3);assert.equal(g.hostiles[0].damage,damage);
 }
});
test('reaper pauses for half a second after teleport only under candidate rules',()=>{
 for(const [balance,recovery] of [[{},0],[config.combatBalance,25]]){
  const g=new Game({...config,combatBalance:balance},()=>.5),e=enemy(g,'Reaper');g.tick=50;stepEnemy(g,e);g.tick=e.action.until;stepEnemy(g,e);
  if(recovery){assert.equal(e.action.kind,'recover');assert.equal(e.action.until-g.tick,25);const x=e.x,y=e.y;g.tick+=10;stepEnemy(g,e);assert.equal(e.x,x);assert.equal(e.y,y);}
  else assert.equal(e.action,null);
 }
});
test('alternative recovery starts at level ten, excludes necromancy, and tracks effective healing once',()=>{
 for(const [school,level,balance,expected] of [['fire',9,config.combatBalance,0],['fire',10,config.combatBalance,.35],['fire',10,{},0],['necro',10,config.combatBalance,0]]){
  const g=new Game({...config,combatBalance:balance},()=>.5);g.start(school);g.player.level=level;g.player.health=50;g.player.expNeeded=10000;
  g.enemies=[{x:350,y:280,width:20,height:20,maxSpeed:0,health:0,maxHealth:10,damage:0,expGiven:1,cd:0}];g.step();close(g.telemetry.healingBySource['balance:recovery']||0,expected);g.step();close(g.telemetry.healingBySource['balance:recovery']||0,expected);
 }
});
