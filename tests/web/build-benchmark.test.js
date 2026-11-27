import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {upgradeOffers,schools} from '../../js/magic.js';
import {buildTargets,targetedChoice,simulateBuild,summarizeBuilds} from '../../js/build-benchmark.js';

test('target matrix contains 20 ordered hybrids and five pure builds',()=>{
 const targets=buildTargets();assert.equal(targets.length,25);assert.equal(targets.filter(t=>t.secondary===null).length,5);assert.equal(new Set(targets.map(t=>t.primary+':'+t.secondary)).size,25);
});
test('general upgrades remain available while secondary choice is optional',()=>{
 for(const s of schools)for(const rank of [1,5])for(const v of [0,.2,.5,.99]){
  const g=new Game(config,()=>v);g.start(s.id);g.player.level=10;g.player.magic.ranks[s.id]=rank;
  const offers=upgradeOffers(g.player,config.skills,()=>v);assert.ok(offers.some(o=>o.kind==='basic'));assert.ok(offers.some(o=>o.kind==='school'&&o.rank===0));
 }
});
test('targeted bot refuses unwanted schools and prioritizes eligible fusion',()=>{
 const g=new Game(config);g.start('fire');g.player.level=10;
 g.offers=[{kind:'school',id:'ice',rank:0},{kind:'basic',index:2},{kind:'school',id:'arcane',rank:0}];
 assert.equal(targetedChoice(g,null),1);assert.equal(targetedChoice(g,'arcane'),2);
 g.offers=[{kind:'basic',index:0},{kind:'synergy',id:'starfall'}];assert.equal(targetedChoice(g,'arcane'),1);
 g.offers=[{kind:'school',id:'ice',rank:0}];assert.equal(targetedChoice(g,'arcane'),-1);
});
test('targeted simulation reproduces short runs and reports actual school ranks',()=>{
 const options={primary:'fire',secondary:'ice',seed:1,seconds:30};const a=simulateBuild(config,options),b=simulateBuild(config,options);
 assert.deepEqual(a,b);assert.equal(a.secondaryAt,null);assert.equal(a.build.ice,0);assert.equal(a.fusionAt,null);assert.equal(summarizeBuilds([a])[0].n,1);
});
