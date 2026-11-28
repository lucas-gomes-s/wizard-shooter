import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {waveAt,waveRate,waveInterval,freshPacing,recordSpawn,recordUpgrade,samplePacing,pacingSummary} from '../../js/waves.js';
test('opening, 90-second phase boundaries, theme rotation and boss override',()=>{
 for(const [t,id,remaining] of [[0,'opening',60],[59,'opening',1],[60,'advance',30],[90,'surge',25],[115,'peak',15],[130,'recovery',20],[150,'advance',30]]){const w=waveAt(t);assert.equal(w.id,id);assert.equal(w.remaining,remaining)}
 assert.equal(waveAt(90).theme.name,'Swarm');assert.equal(waveAt(180).theme.name,'Assault');assert.equal(waveAt(270).theme.name,'Nightmare');assert.equal(waveAt(1500,true,true).id,'boss');assert.equal(waveAt(200,false).id,'classic');
});
test('surge favors theme without unlocking enemies; classic interval is exact',()=>{
 const m={name:'Goblin'},e={name:'Orc'};
 assert.equal(waveInterval(85,waveAt(200,false),m),85);
 assert.ok(waveRate(waveAt(115),m)>waveRate(waveAt(115),e));
 assert.ok(waveInterval(85,waveAt(115),m)<85);assert.ok(waveInterval(85,waveAt(130),m)>85);
 const g=new Game(config,()=>.5);g.start('fire');g.tick=115*50;for(let i=0;i<500;i++)g.spawnEnemies();assert.ok(g.enemies.length>0);assert.ok(g.enemies.every(e=>e.startMinute<=115/60));
});
test('wave selection is independent of player power and resets correctly',()=>{
 const a=new Game(config),b=new Game(config);a.start('fire');b.start('ice');a.tick=b.tick=115*50;b.player.level=50;b.player.shotDmg=999;assert.deepEqual(a.wave,b.wave);
 a.start('fire');assert.equal(a.wave.id,'opening');assert.equal(a.pacing.samples,0);
});
test('pacing captures visible density, cap skips, upgrade drought and bounded windows',()=>{
 const p=freshPacing(),g={pacing:p,tick:50,enemies:[{health:10}],visible:()=>true,player:{level:1,health:100},kills:0};
 const w=waveAt(1);recordSpawn(p,w);recordSpawn(p,w,true);samplePacing(g,w);recordUpgrade(p,100);g.tick=150;samplePacing(g,w);
 const r=pacingSummary(p,200);assert.equal(r.spawned,1);assert.equal(r.capSkips,1);assert.equal(r.meanVisible,1);assert.equal(r.quietFraction,1);assert.equal(r.maxUpgradeGapSeconds,2);
 for(let i=1;i<250;i++){g.tick=i*750;samplePacing(g,w)}assert.equal(p.windows.length,240);
});
