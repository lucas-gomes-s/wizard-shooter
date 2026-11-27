import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {canLearnSchool,upgradeOffers,eligibleMastery} from '../../js/magic.js';
import {PROFILE_KEY,freshProfile,normalizeProfile,loadProfile,saveProfile,recordProgress,newProgressSession,runConfig,available,contracts,sigils,achievements} from '../../js/progression.js';
const make=()=>{const g=new Game(config,()=>.5);g.start('fire');return g};
test('fresh profile unlocks only standard rules and default cosmetic',()=>{
 const p=freshProfile();assert.equal(achievements.length,14);
 assert.deepEqual(contracts.filter(c=>available(contracts,c.id,p)).map(c=>c.id),['standard']);
 assert.deepEqual(sigils.filter(c=>available(sigils,c.id,p)).map(c=>c.id),['violet']);
});
test('malformed and future-version profiles fail safely; invalid identifiers and selection filtered',()=>{
 assert.deepEqual(normalizeProfile({version:999}),freshProfile());
 const p=normalizeProfile({version:1,runs:2,wins:9,kills:-4,items:['fang','fang','unknown'],selection:{contract:'dry',sigil:'frost'}});
 assert.equal(p.wins,2);assert.equal(p.kills,0);assert.deepEqual(p.items,['fang']);assert.equal(p.selection.contract,'dry');assert.equal(p.selection.sigil,'violet');
 assert.deepEqual(loadProfile({getItem:()=>'{bad'}).profile,freshProfile());
 assert.equal(saveProfile({setItem:()=>{throw Error('quota')}},p),false);
});
test('profile round trips without accepting stored bogus achievements',()=>{
 const storage=new Map(),io={getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)};
 const p=freshProfile();p.runs=1;p.achievements=['first','dragon'];assert.ok(saveProfile(io,p));
 assert.ok(storage.has(PROFILE_KEY));const result=loadProfile(io);assert.equal(result.saved,true);assert.deepEqual(result.profile.achievements,['first']);
});
test('zero-tick starts not counted; checkpoints accrue only deltas',()=>{
 const g=make(),p=freshProfile(),s=newProgressSession();
 assert.deepEqual(recordProgress(p,g,s),[]);assert.equal(p.runs,0);g.tick=30000;g.kills=1000;
 const unlocked=recordProgress(p,g,s);assert.ok(unlocked.includes('survivor'));assert.ok(unlocked.includes('slayer'));
 recordProgress(p,g,s);assert.equal(p.runs,1);assert.equal(p.ticks,30000);assert.equal(p.kills,1000);
 g.tick=35000;g.kills=1100;recordProgress(p,g,s);assert.equal(p.ticks,35000);assert.equal(p.kills,1100);
});
test('victory and endless share one run and one win, contract victory unlocks',()=>{
 const g=make(),p=freshProfile(),s=newProgressSession('purist');g.tick=75000;g.kills=2000;g.bossDefeated=true;
 assert.ok(recordProgress(p,g,s).includes('dragon'));assert.equal(p.wins,1);assert.ok(p.achievements.includes('oath'));assert.deepEqual(p.contracts,['purist']);
 g.tick+=5000;g.kills+=10;recordProgress(p,g,s);assert.equal(p.runs,1);assert.equal(p.wins,1);assert.equal(p.bestTicks,80000);assert.deepEqual(p.winningSchools,['fire']);
});
test('codex records acquired and replaced items, fusions, mastery and only completed events',()=>{
 const g=make(),p=freshProfile();g.tick=100;g.lootHistory=[{id:'fang'},{id:'tonic'}];g.market.history=[{id:'heal'},{id:'echo'}];g.player.equipment.relic='lantern';g.player.magic.synergies=['steam'];g.player.magic.mastery='inferno';g.dungeon.history=[{id:'altar',outcome:'completed'},{id:'moon',outcome:'failed'}];recordProgress(p,g,newProgressSession());
 assert.equal(p.items.length,4);assert.ok(p.fusions.includes('steam'));assert.ok(p.masteries.includes('inferno'));assert.deepEqual(p.events,['altar']);assert.ok(available(contracts,'purist',p));assert.ok(available(sigils,'jade',p));
});
test('purist forbids secondary acquisition but retains pure mastery',()=>{
 const g=new Game(runConfig(config,'purist'),()=>.5);g.start('ice');g.player.level=15;g.player.magic.ranks.ice=5;
 assert.equal(canLearnSchool(g.player,'fire'),false);assert.ok(eligibleMastery(g.player));assert.ok(upgradeOffers(g.player,config.skills,()=>.5).every(o=>o.kind!=='school'||o.id==='ice'));
 const h=new Game(runConfig(config,'standard'));h.start('ice');h.player.level=15;assert.ok(canLearnSchool(h.player,'fire'));
});
test('merchantless keeps equipment and events; dry pilgrimage suppresses natural potions',()=>{
 const n=runConfig(config,'nomad');assert.equal(n.economyEnabled,false);assert.equal(n.equipmentEnabled,undefined);assert.equal(n.eventsEnabled,undefined);
 const d=runConfig(config,'dry');assert.equal(d.potionInfo.length,0);assert.ok(config.potionInfo.length>0);assert.equal(d.economyEnabled,undefined);
});
