// Data-driven spell upgrades. All effects are applied to manually aimed bolts.
export const schools=[
 {id:'fire',name:'Pyromancy',glyph:'✹',color:'#ff9560',ranks:['Burn for 2 seconds: 20% bolt damage every half second.','Burn damage rises to 25% per tick.','Fire burst: 30% damage to other enemies within 45 units.','Burn damage rises to 35% per tick.','Fire burst radius increases to 65 units; burn ticks deal 40%.']},
 {id:'ice',name:'Cryomancy',glyph:'❄',color:'#80dcff',ranks:['Slow enemies by 25% for 2 seconds.','Slow rises to 35%.','Bolts pierce one additional target; slow rises to 45%.','Slow rises to 55%.','Bolts pierce two additional targets; every third frost hit freezes for 0.6s.']},
 {id:'lightning',name:'Electromancy',glyph:'ϟ',color:'#ffe17a',ranks:['Chain to one nearby enemy for 40% bolt damage; 5% critical chance.','Chain damage 45%; critical chance 10%.','Chain to two nearby enemies for 50%; critical chance 15%.','Chain damage 55%; critical chance 20%.','Chain to three nearby enemies for 60%; critical chance 25%.']},
 {id:'necro',name:'Necromancy',glyph:'☾',color:'#86e3ab',ranks:['Heal 1 HP per kill.','Heal 1.5 HP per kill.','Curse struck enemies: take 15% extra damage for 2 seconds. Heal 2 HP per kill.','Heal 2.5 HP per kill.','Heal 3 HP per kill; slain enemies release a 40% soul burst within 65 units.']},
 {id:'arcane',name:'Arcane magic',glyph:'✧',color:'#c3a2ff',ranks:['Two angled bolts, each at 75% damage.','Gain a shield that blocks one contact hit, recharging after 15 seconds.','Three bolts, each at 70% damage.','Shield recharge decreases to 10 seconds.','Three bolts, each at 85% damage.']}
];
export const synergies=[
 {id:'steam',name:'Steam eruption',glyph:'♨',color:'#e4f2ff',requires:['fire','ice'],description:'Every direct hit releases steam: 35% damage and a 50% slow to other enemies within 70 units.'},
 {id:'storm',name:'Storm prism',glyph:'✷',color:'#f2d4ff',requires:['lightning','arcane'],description:'Chain lightning jumps to one additional enemy, with 30 extra units of range.'},
 {id:'soulfire',name:'Soulfire',glyph:'✺',color:'#f6b18c',requires:['fire','necro'],description:'Burning enemies that die release 60% bolt damage to other enemies within 60 units.'}
];
export const SECOND_SCHOOL_LEVEL=10;
export const MAX_SCHOOLS=2;
export const schoolById=Object.fromEntries(schools.map(s=>[s.id,s]));
export function freshMagic(){return {ranks:Object.fromEntries(schools.map(s=>[s.id,0])),primary:null,secondary:null,synergies:[],shieldUntil:0,shieldReady:false}}
export function dominantSchool(magic){return schoolById[magic.primary]||schools.reduce((best,s)=>magic.ranks[s.id]>(best?magic.ranks[best.id]:0)?s:best,null)}
export function learnedSchools(magic){return schools.filter(s=>magic.ranks[s.id]>0)}
export function canLearnSchool(player,id){
 if(!Object.hasOwn(schoolById,id))return false;
 const m=player.magic,rank=m.ranks[id],count=learnedSchools(m).length;
 if(rank>0)return rank<5;
 return count===0||(count<MAX_SCHOOLS&&player.level>=SECOND_SCHOOL_LEVEL);
}
function sample(pool,rng){return pool.splice(Math.min(pool.length-1,Math.floor(rng()*pool.length)),1)[0]}
export function upgradeOffers(player,skills,rng=Math.random){
 const m=player.magic;
 const basic=skills.flatMap((s,i)=>player.skillLvl[i]<s.maxLevel?[{kind:'basic',id:'basic-'+i,index:i,name:s.name,img:s.img,description:s.description2,flavor:s.description1,rank:player.skillLvl[i],max:s.maxLevel,color:'#e5c48b'}]:[]);
 const magic=schools.filter(s=>canLearnSchool(player,s.id)).map(s=>({kind:'school',id:s.id,name:s.name,glyph:s.glyph,color:s.color,rank:m.ranks[s.id],max:5,description:s.ranks[m.ranks[s.id]],flavor:m.ranks[s.id]?'School mastery':learnedSchools(m).length?'Secondary school · permanent choice':'Primary school'}));
 const combos=synergies.filter(s=>!m.synergies.includes(s.id)&&s.requires.every(id=>m.ranks[id]>=2)).map(s=>({kind:'synergy',id:s.id,name:s.name,glyph:s.glyph,color:s.color,description:s.description,flavor:'Synergy · '+s.requires.map(id=>schoolById[id].name).join(' + '),rank:0,max:1}));
 if(player.level===2&&magic.length>=3&&Object.values(m.ranks).every(rank=>rank===0)){return Array.from({length:3},()=>sample(magic,rng))}
 const offers=[];
 // Give new players a reliable path to damage or mobility rather than a dead-end roll.
 if(player.level<=4&&Object.values(m.ranks).some(rank=>rank>0)){const priority=basic.findIndex(o=>o.index===(player.level===3?0:2));if(priority>=0)offers.push(basic.splice(priority,1)[0]);}
 if(combos.length&&offers.length<3)offers.push(sample(combos,rng));
 const mastered=magic.filter(o=>o.rank>0),newSchools=magic.filter(o=>o.rank===0);
 // Give mastery and a new-school option separate slots whenever available.
 if(mastered.length&&offers.length<3){const offer=sample(mastered,rng);offers.push(offer);magic.splice(magic.indexOf(offer),1);}
 if(newSchools.length&&offers.length<3){const offer=sample(newSchools,rng);offers.push(offer);magic.splice(magic.indexOf(offer),1);}
 if(!offers.some(o=>o.kind==='school')&&magic.length&&offers.length<3)offers.push(sample(magic,rng));
 const pool=[...basic,...magic,...combos];
 while(offers.length<3&&pool.length)offers.push(sample(pool,rng));
 return offers;
}
export function applyUpgrade(player,offer,skills,tick){
 if(offer.kind==='basic'){const s=skills[offer.index];if(!s||player.skillLvl[offer.index]>=s.maxLevel)return false;player[s.status]+=s.modifier;player.shotCd=Math.max(1,player.shotCd);player.skillLvl[offer.index]++;return true}
 if(offer.kind==='school'){
  const m=player.magic;if(!canLearnSchool(player,offer.id))return false;
  if(m.ranks[offer.id]===0){if(!learnedSchools(m).length)m.primary=offer.id;else m.secondary=offer.id;}
  m.ranks[offer.id]++;
  if(offer.id==='arcane'&&m.ranks.arcane===2){m.shieldReady=true;m.shieldUntil=tick}
  return true;
 }
 if(offer.kind==='synergy'){
  const s=synergies.find(s=>s.id===offer.id),m=player.magic;
  if(!s||m.synergies.includes(s.id)||!s.requires.every(id=>m.ranks[id]>=2))return false;
  m.synergies.push(s.id);return true;
 }
 return false;
}
export function boltPattern(player,dx,dy){
 const rank=player.magic.ranks.arcane;
 const angles=rank>=3?[-.14,0,.14]:rank>=1?[-.085,.085]:[0];
 const multiplier=rank>=5?.85:rank>=3?.7:rank>=1?.75:1;
 return angles.map(a=>({vx:(dx*Math.cos(a)-dy*Math.sin(a))*player.shotSpd,vy:(dx*Math.sin(a)+dy*Math.cos(a))*player.shotSpd,damage:player.shotDmg*multiplier}));
}
export function pierceCount(player){return player.magic.ranks.ice>=5?3:player.magic.ranks.ice>=3?2:1}
export function center(o){return {x:o.x+o.width/2,y:o.y+o.height/2}}
export function nearby(hash,origin,radius,excluded=new Set()){
 const c=center(origin), box={x:c.x-radius,y:c.y-radius,width:radius*2,height:radius*2};
 return [...hash.query(box)].filter(e=>e.health>0&&!excluded.has(e)).map(e=>({e,d:Math.hypot(center(e).x-c.x,center(e).y-c.y)})).filter(o=>o.d<=radius).sort((a,b)=>a.d-b.d).map(o=>o.e);
}
