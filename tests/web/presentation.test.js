import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {viewportFor,fitViewport,formatTime,skillPreview} from '../../js/presentation.js';
test('wide and tall arena keeps short world axis at 600 and caps aspect',()=>{
  assert.deepEqual(viewportFor(1600,900),{width:1067,height:600});
  assert.deepEqual(viewportFor(300,1200),{width:600,height:1071});
  assert.deepEqual(viewportFor(2000,500),{width:1080,height:600});
});
test('resize fits the locked run viewport without changing world aspect',()=>{
  assert.deepEqual(fitViewport(800,800,1000,600),{scale:.8,x:0,y:160});
});
test('stat previews reflect real upgrade and cooldown floor',()=>{
  const g=new Game(config);
  assert.equal(skillPreview(g.player,config.skills[0]),'100 units/s → 150 units/s');
  assert.equal(skillPreview(g.player,config.skills[1]),'100 HP → 120 HP');
  assert.equal(skillPreview(g.player,config.skills[2]),'10 damage → 20 damage');
  assert.equal(skillPreview(g.player,config.skills[3]),'1.00 casts/s → 1.11 casts/s');
  g.player.shotCd=1;assert.equal(skillPreview(g.player,config.skills[3]),'50.00 casts/s → 50.00 casts/s');
  assert.equal(formatTime(1512),'25:12');
});
test('hit and kill events are emitted once and reset each tick',()=>{
  const g=new Game(config);
  g.enemies.push({x:340,y:280,width:20,height:20,maxSpeed:0,health:10,maxHealth:10,damage:10,expGiven:1,cd:0});
  g.shots.push({x:340,y:280,width:5,height:5,vx:0,vy:0,damage:10});g.step();
  assert.deepEqual(g.events.map(e=>e.type),['hit','kill']);
  assert.equal(g.events[0].value,10);assert.equal(g.kills,1);
  g.step();assert.deepEqual(g.events,[]);g.reset();assert.deepEqual(g.events,[]);
});
test('damage and healing events reflect actual health change',()=>{
  const g=new Game(config);g.enemies.push({x:280,y:280,width:40,height:40,maxSpeed:0,health:10,damage:20,expGiven:1,cd:0});
  g.potions.push({x:280,y:280,width:30,height:30,recovery:.5,fade:1000,age:0});g.step();
  assert.deepEqual(g.events.map(e=>[e.type,e.value]),[['hurt',20],['heal',20]]);
  assert.equal(g.player.health,100);
});
test('presentation event buffer is bounded independently of simulation',()=>{
  const g=new Game(config);for(let i=0;i<200;i++)g.emit('hit',g.player,10);
  assert.equal(g.events.length,128);
});
