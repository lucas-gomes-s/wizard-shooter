// Data-driven spell upgrades. All effects are applied to manually aimed bolts.
export const schools=[
 {id:'fire',name:'Pyromancy',glyph:'✹',color:'#ff9560',ranks:['Burn for 2 seconds: 20% bolt damage every half second.','Burn damage rises to 35% per tick.','Fire burst: 45% damage to other enemies within 55 units; burn deals 45% per tick.','Burn damage rises to 55% per tick.','Fire burst radius increases to 75 units; burn ticks deal 65%.']},
 {id:'ice',name:'Cryomancy',glyph:'❄',color:'#80dcff',ranks:['Slow enemies by 25% for 2 seconds.','Slow rises to 35%.','Bolts pierce one additional target; slow rises to 45%.','Slow rises to 55%.','Bolts pierce two additional targets; every third frost hit freezes for 0.6s.']},
 {id:'lightning',name:'Electromancy',glyph:'ϟ',color:'#ffe17a',ranks:['Chain to one nearby enemy for 40% bolt damage; 5% critical chance.','Chain damage 45%; critical chance 10%.','Chain to two nearby enemies for 50%; critical chance 15%.','Chain damage 55%; critical chance 20%.','Chain to three nearby enemies for 60%; critical chance 25%.']},
 {id:'necro',name:'Necromancy',glyph:'☾',color:'#86e3ab',ranks:['Heal 1 HP per kill.','Heal 1.5 HP per kill.','Curse struck enemies: take 15% extra damage for 2 seconds. Heal 2 HP per kill.','Heal 2.5 HP per kill.','Heal 3 HP per kill; slain enemies release a 40% soul burst within 65 units.']},
 {id:'arcane',name:'Arcane magic',glyph:'✧',color:'#c3a2ff',ranks:['Two angled bolts, each at 75% damage.','Gain a shield that blocks one contact hit, recharging after 15 seconds.','Three bolts, each at 70% damage.','Shield recharge decreases to 10 seconds.','Three bolts, each at 85% damage.']}
];
export const synergies=[
 {id:'steam',name:'Steam eruption',glyph:'♨',color:'#e4f2ff',requires:['fire','ice'],description:'Every direct hit releases steam: 55% damage and a 50% slow to other enemies within 85 units.'},
 {id:'storm',name:'Storm prism',glyph:'✷',color:'#f2d4ff',requires:['lightning','arcane'],description:'Chain lightning jumps to one additional enemy, with 30 extra units of range.'},
 {id:'soulfire',name:'Soulfire',glyph:'✺',color:'#f6b18c',requires:['fire','necro'],description:'Burning enemies that die release 60% bolt damage to other enemies within 80 units.'},
 {"id":"plasma","name":"Plasma surge","glyph":"⚡","color":"#ffb34f","requires":["fire","lightning"],"description":"Chain lightning also ignites each struck target for 3 seconds at 40% bolt damage per half second. Burns refresh, never stack."},
 {"id":"starfall","name":"Starfire","glyph":"✦","color":"#ff8fc8","requires":["fire","arcane"],"description":"Every fourth cast releases a wide fan of five explosive bolts at 65% base damage each. Direct impacts release a 25% burst within 45 units."},
 {"id":"thunderfrost","name":"Thunderfrost","glyph":"❅","color":"#a2e7ff","requires":["ice","lightning"],"description":"Chain lightning chills its targets by 45% for 2 seconds. Chaining to an already chilled target freezes it for 0.8 seconds, at most once every 2 seconds per target."},
 {"id":"gravefrost","name":"Gravefrost","glyph":"☠","color":"#8df2d8","requires":["ice","necro"],"description":"Slaying a chilled enemy releases a 60-unit pulse dealing 35% base damage and slowing nearby enemies by 50% for 2 seconds. Each death can pulse only once."},
 {"id":"mirror","name":"Glacial mirror","glyph":"◇","color":"#c4e9ff","requires":["ice","arcane"],"description":"Gain one additional piercing target per bolt. When the arcane shield blocks a contact hit, freeze enemies within 90 units for 0.8 seconds."},
 {"id":"reaping","name":"Soul conductor","glyph":"ϟ","color":"#a2ff8b","requires":["lightning","necro"],"description":"Chain strikes mark targets for 2 seconds. Killing a marked enemy restores 1.5 additional HP and releases a 40% base-damage soul bolt into the nearest enemy within 120 units."},
 {"id":"soulward","name":"Soul ward","glyph":"✧","color":"#b4f6c7","requires":["necro","arcane"],"description":"Every kill reduces the active shield recharge by 0.3 seconds. When a shield blocks a contact hit, heal 8 HP and release a 70-unit pulse for 50% base damage."}
];
// Single-school capstones commit the player to that school for the rest of the run.
export const MASTERY_LEVEL=15;
export const masteries=[
 {id:'inferno',school:'fire',name:'Inferno',glyph:'✹',color:'#ff7537',description:'Burning enemies take 40% more burn damage. Fire bursts deal 65% bolt damage within 95 units. Permanently forgo a second school.'},
 {id:'absolute-zero',school:'ice',name:'Absolute zero',glyph:'❄',color:'#76ddff',description:'Bolts pierce two more enemies and deal 40% extra damage to already chilled targets. Permanently forgo a second school.'},
 {id:'tempest',school:'lightning',name:'Tempest',glyph:'ϟ',color:'#ffe86c',description:'Two additional chain jumps, 40 extra chain range and 20 percentage points more critical chance. Permanently forgo a second school.'},
 {id:'lich',school:'necro',name:'Lich ascension',glyph:'☾',color:'#69f3a2',description:'Slain enemies release a 60% base-damage soul burst within 85 units. Heal one extra HP per kill. Permanently forgo a second school.'},
 {id:'archmage',school:'arcane',name:'Archmage',glyph:'✧',color:'#c49aff',description:'Five bolts at 75% base damage each. Shield recharge takes 7 seconds. Permanently forgo a second school.'}
];
export const SECOND_SCHOOL_LEVEL=10;
export const MAX_SCHOOLS=2;
export const schoolById=Object.fromEntries(schools.map(s=>[s.id,s]));
export function freshMagic(){return {ranks:Object.fromEntries(schools.map(s=>[s.id,0])),primary:null,secondary:null,mastery:null,synergies:[],shieldUntil:0,shieldReady:false}}
export function dominantSchool(magic){return schoolById[magic.primary]||schools.reduce((best,s)=>magic.ranks[s.id]>(best?magic.ranks[best.id]:0)?s:best,null)}
export function synergyFor(a,b){return synergies.find(s=>s.requires.includes(a)&&s.requires.includes(b)&&a!==b)||null}
export function learnedSchools(magic){return schools.filter(s=>magic.ranks[s.id]>0)}
export function canLearnSchool(player,id){
 if(!Object.hasOwn(schoolById,id))return false;
 const m=player.magic,rank=m.ranks[id],count=learnedSchools(m).length;
 if(rank>0)return rank<5;
 return count===0||(!m.mastery&&!m.pureOath&&count<MAX_SCHOOLS&&player.level>=SECOND_SCHOOL_LEVEL);
}
export function eligibleMastery(player){
 const m=player.magic;
 return !m.mastery&&player.level>=MASTERY_LEVEL&&learnedSchools(m).length===1?masteries.find(s=>s.school===m.primary&&m.ranks[s.school]===5)||null:null;
}
function sample(pool,rng){return pool.splice(Math.min(pool.length-1,Math.floor(rng()*pool.length)),1)[0]}
export function upgradeOffers(player,skills,rng=Math.random){
 const m=player.magic;
 const basic=skills.flatMap((s,i)=>player.skillLvl[i]<s.maxLevel?[{kind:'basic',id:'basic-'+i,index:i,name:s.name,img:s.img,description:s.description2,flavor:s.description1,rank:player.skillLvl[i],max:s.maxLevel,color:'#e5c48b'}]:[]);
 const magic=schools.filter(s=>canLearnSchool(player,s.id)).map(s=>({kind:'school',id:s.id,name:s.name,glyph:s.glyph,color:s.color,rank:m.ranks[s.id],max:5,description:s.ranks[m.ranks[s.id]],flavor:m.ranks[s.id]?'School mastery':learnedSchools(m).length?'Secondary school · permanent choice':'Primary school'}));
 const combos=synergies.filter(s=>!m.synergies.includes(s.id)&&s.requires.every(id=>m.ranks[id]>=2)).map(s=>({kind:'synergy',id:s.id,name:s.name,glyph:s.glyph,color:s.color,description:s.description,flavor:'Synergy · '+s.requires.map(id=>schoolById[id].name).join(' + '),rank:0,max:1}));
 if(player.level===2&&magic.length>=3&&Object.values(m.ranks).every(rank=>rank===0)){return Array.from({length:3},()=>sample(magic,rng))}
 const offers=[];
 const mastery=eligibleMastery(player);
 if(mastery)offers.push({...mastery,kind:'mastery',rank:0,max:1,flavor:'Exclusive mastery · permanent choice'});
 // Give new players a reliable path to damage or mobility rather than a dead-end roll.
 if(player.level<=4&&Object.values(m.ranks).some(rank=>rank>0)){const priority=basic.findIndex(o=>o.index===(player.level===3?0:2));if(priority>=0)offers.push(basic.splice(priority,1)[0]);}
 if(combos.length&&offers.length<3)offers.push(sample(combos,rng));
 const mastered=magic.filter(o=>o.rank>0),newSchools=magic.filter(o=>o.rank===0);
 // Give mastery and a new-school option separate slots whenever available.
 if(mastered.length&&offers.length<3){const offer=sample(mastered,rng);offers.push(offer);magic.splice(magic.indexOf(offer),1);}
 if(newSchools.length&&offers.length<3){const offer=sample(newSchools,rng);offers.push(offer);magic.splice(magic.indexOf(offer),1);}
 if(!offers.some(o=>o.kind==='school')&&magic.length&&offers.length<3)offers.push(sample(magic,rng));
 // Optional specialization must remain a real choice when secondary schools are offered.
 if(learnedSchools(m).length===1&&player.level>=SECOND_SCHOOL_LEVEL&&basic.length&&offers.length<3&&!offers.some(o=>o.kind==='basic'))offers.push(sample(basic,rng));
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
 if(offer.kind==='mastery'){const mastery=eligibleMastery(player);if(!mastery||mastery.id!==offer.id)return false;player.magic.mastery=mastery.id;return true}
 if(offer.kind==='synergy'){
  const s=synergies.find(s=>s.id===offer.id),m=player.magic;
  if(!s||m.synergies.includes(s.id)||!s.requires.every(id=>m.ranks[id]>=2))return false;
  m.synergies.push(s.id);return true;
 }
 return false;
}
export function boltPattern(player,dx,dy){
 const rank=player.magic.ranks.arcane;
 const star=player.magic.synergies.includes('starfall')&&(player.magic.casts||0)%4===0;
 const angles=player.magic.mastery==='archmage'?[-.24,-.12,0,.12,.24]:star?[-.30,-.15,0,.15,.30]:rank>=3?[-.14,0,.14]:rank>=1?[-.085,.085]:[0];
 const multiplier=player.magic.mastery==='archmage'?.75:star?.65:rank>=5?.85:rank>=3?.7:rank>=1?.75:1;
 return angles.map(a=>({star,vx:(dx*Math.cos(a)-dy*Math.sin(a))*player.shotSpd,vy:(dx*Math.sin(a)+dy*Math.cos(a))*player.shotSpd,damage:player.shotDmg*multiplier}));
}
export function pierceCount(player){return (player.magic.ranks.ice>=5?3:player.magic.ranks.ice>=3?2:1)+Number(player.magic.synergies.includes('mirror'))+2*Number(player.magic.mastery==='absolute-zero')}
export function center(o){return {x:o.x+o.width/2,y:o.y+o.height/2}}
export function nearby(hash,origin,radius,excluded=new Set()){
 const c=center(origin), box={x:c.x-radius,y:c.y-radius,width:radius*2,height:radius*2};
 return [...hash.query(box)].filter(e=>e.health>0&&!excluded.has(e)).map(e=>({e,d:Math.hypot(center(e).x-c.x,center(e).y-c.y)})).filter(o=>o.d<=radius).sort((a,b)=>a.d-b.d).map(o=>o.e);
}
