import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {stepHazards,HAZARD_CAP} from '../../js/enemies.js';
import {environments,environmentById,environmentConfig,stepEnvironment} from '../../js/environments.js';
import {freshProfile,normalizeProfile,recordProgress,newProgressSession} from '../../js/progression.js';
const make=id=>{const g=new Game(environmentConfig(config,id),()=>.5);g.start('fire');return g};
test('three biomes; crypt is unchanged and alternate spawns preserve enemy families',()=>{
 assert.equal(environments.length,3);assert.equal(environmentById('missing').id,'crypt');
 assert.deepEqual(environmentConfig(config,'crypt').monsters,config.monsters);
 for(const id of ['frost','forge']){
  const c=environmentConfig(config,id);assert.deepEqual(c.monsters.map(m=>m.name),config.monsters.map(m=>m.name));
  assert.ok(c.monsters.some((m,i)=>m.spawn!==config.monsters[i].spawn));
  for(const [i,m] of c.monsters.entries())assert.equal(m.health,config.monsters[i].health);
 }
});
test('frost fissure has warning, actual hit damage, chill, and expiry',()=>{
 const g=make('frost');g.tick=6000;stepEnvironment(g,HAZARD_CAP);assert.equal(g.hazards.length,1);const h=g.hazards[0];
 assert.equal(h.type,'frost-fissure');stepHazards(g);assert.equal(g.player.health,100);
 g.tick=h.activeAt;stepHazards(g);assert.equal(g.player.health,92);assert.equal(g.player.frostUntil,g.tick+75);
 stepHazards(g);assert.equal(g.player.health,92);
 assert.equal(g.telemetry.incomingBySource['hazard:frost-fissure'].applied,8);
 g.tick=h.until;stepHazards(g);assert.equal(g.hazards.length,0);
});
test('forge vents can be avoided, damage once and never chill',()=>{
 const g=make('forge');g.tick=6000;stepEnvironment(g,HAZARD_CAP);const h=g.hazards[0];assert.equal(h.type,'lava-vent');
 g.tick=h.activeAt;g.player.x+=200;stepHazards(g);assert.equal(g.player.health,100);
 g.player.x-=200;stepHazards(g);assert.equal(g.player.health,88);assert.equal(g.player.frostUntil,undefined);
 stepHazards(g);assert.equal(g.player.health,88);
});
test('biome hazards respect cadence, cap, disable flag and restart',()=>{
 const g=make('frost');g.tick=30000;stepEnvironment(g,HAZARD_CAP);assert.equal(g.hazards.length,2);stepEnvironment(g,HAZARD_CAP);assert.equal(g.hazards.length,2);
 g.tick=g.nextEnvironmentHazard;stepEnvironment(g,2);assert.equal(g.hazards.length,2);
 g.start('fire');assert.equal(g.hazards.length,0);assert.equal(g.nextEnvironmentHazard,0);
 const h=make('forge');h.config.environmentHazards=false;h.tick=6000;stepEnvironment(h,HAZARD_CAP);assert.equal(h.hazards.length,0);
 const c=make('crypt');c.tick=75000;stepEnvironment(c,HAZARD_CAP);assert.equal(c.hazards.length,0);
});
test('dragon has biome title but retains original boss behavior',()=>{
 for(const e of environments){const g=make(e.id);g.tick=75000;g.spawnEnemies();assert.equal(g.boss.title,e.boss);assert.equal(g.boss.health,18000);assert.equal(g.boss.name,'Dragon');}
});
test('old profiles default to crypt; worldwalker needs three distinct biome victories',()=>{
 const p=normalizeProfile({version:1,runs:1,selection:{contract:'standard',sigil:'violet'}});assert.equal(p.selection.environment,'crypt');assert.deepEqual(p.winningEnvironments,[]);
 for(const id of ['crypt','frost','forge']){const g=make(id);g.tick=75000;g.bossDefeated=true;recordProgress(p,g,newProgressSession('standard',id));}
 assert.equal(p.winningEnvironments.length,3);assert.equal(p.visitedEnvironments.length,3);assert.ok(p.achievements.includes('worldwalker'));assert.equal(normalizeProfile({...p,selection:{environment:'forge'}}).selection.environment,'forge');
});
