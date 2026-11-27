import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {schools,SECOND_SCHOOL_LEVEL,MAX_SCHOOLS,learnedSchools,canLearnSchool,upgradeOffers,applyUpgrade,dominantSchool} from '../../js/magic.js';
const make=(id='fire')=>{const g=new Game(config,()=>.5);g.start(id);return g};
const offer=id=>({kind:'school',id});
test('every starting school is exclusive before level ten',()=>{
 for(const school of schools){
  const g=make(school.id),p=g.player;
  for(let l=2;l<SECOND_SCHOOL_LEVEL;l++){p.level=l;
   assert.ok(upgradeOffers(p,config.skills,()=>.5).filter(o=>o.kind==='school').every(o=>o.id===school.id));
   for(const s of schools)if(s.id!==school.id){assert.equal(canLearnSchool(p,s.id),false);assert.equal(applyUpgrade(p,offer(s.id),config.skills,0),false);}
  }
 }
});
test('level ten offers mastery plus a secondary school and preserves player choice',()=>{
 const g=make(),p=g.player;p.level=SECOND_SCHOOL_LEVEL;
 const cards=upgradeOffers(p,config.skills,()=>.5);
 assert.ok(cards.some(o=>o.kind==='school'&&o.id==='fire'));
 const secondary=cards.find(o=>o.kind==='school'&&o.rank===0);assert.ok(secondary);
 assert.ok(applyUpgrade(p,offer('fire'),config.skills,0));assert.equal(p.magic.secondary,null);
 assert.ok(applyUpgrade(p,secondary,config.skills,0));assert.equal(p.magic.secondary,secondary.id);
 assert.equal(learnedSchools(p.magic).length,MAX_SCHOOLS);
 for(const s of schools)if(!p.magic.ranks[s.id])assert.equal(applyUpgrade(p,offer(s.id),config.skills,0),false);
});
test('mastery cap does not bypass the secondary unlock',()=>{
 const g=make(),p=g.player;p.level=9;p.magic.ranks.fire=5;
 assert.ok(upgradeOffers(p,config.skills,()=>.5).every(o=>o.kind==='basic'));
 assert.equal(applyUpgrade(p,offer('fire'),config.skills,0),false);
 p.level=10;assert.ok(upgradeOffers(p,config.skills,()=>.5).some(o=>o.kind==='school'&&o.rank===0));
});
test('primary identity persists when secondary rank is higher',()=>{
 const g=make('ice'),p=g.player;p.level=10;
 assert.ok(applyUpgrade(p,offer('fire'),config.skills,0));assert.ok(applyUpgrade(p,offer('fire'),config.skills,0));
 assert.equal(dominantSchool(p.magic).id,'ice');
 g.start('necro');assert.equal(p.magic.primary,'ice');assert.equal(g.player.magic.primary,'necro');assert.equal(g.player.magic.secondary,null);
});
test('synergy requires both learned schools at rank two',()=>{
 const g=make(),p=g.player;p.level=10;applyUpgrade(p,offer('ice'),config.skills,0);applyUpgrade(p,offer('fire'),config.skills,0);
 assert.equal(applyUpgrade(p,{kind:'synergy',id:'steam'},config.skills,0),false);
 applyUpgrade(p,offer('ice'),config.skills,0);
 assert.ok(upgradeOffers(p,config.skills,()=>.5).some(o=>o.id==='steam'));
 assert.ok(applyUpgrade(p,{kind:'synergy',id:'steam'},config.skills,0));
 assert.equal(applyUpgrade(p,{kind:'synergy',id:'soulfire'},config.skills,0),false);
});
