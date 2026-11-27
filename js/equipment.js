import {attuned} from './attunements.js';
// Run-local equipment. Each item occupies exactly one slot; no stacking on replacement.
export const equipmentSlots=['staff','robe','boots','relic'];
export const rarityColors={common:'#d0d5df',rare:'#77c5ff',epic:'#c99aff',legendary:'#ffd277'};
export const equipment=[
 {id:'quickwand',slot:'staff',rarity:'common',name:'Quickcast Wand',glyph:'✧',description:'Cast 12% faster.'},
 {id:'longshot',slot:'staff',rarity:'common',name:'Farshot Staff',glyph:'➶',description:'Projectiles travel 30% faster.'},
 {id:'echo',slot:'staff',rarity:'rare',name:'Staff of Echoes',glyph:'✦',description:'Every fifth cast adds a straight bolt at 60% base damage.'},
 {id:'bloodwood',slot:'staff',rarity:'rare',name:'Bloodwood Wand',glyph:'♦',description:'Every fourth cast costs 2 HP for 50% bonus projectile damage, only above 2 HP.'},
 {id:'prism',slot:'staff',rarity:'epic',name:'Prismatic Rod',glyph:'◇',description:'Each bolt pierces one additional enemy.'},
 {id:'meteor',slot:'staff',rarity:'legendary',name:'Meteor Scepter',glyph:'☄',description:'Every third cast releases a 45% base-damage impact burst within 65 units, once per cast.'},
 {id:'linen',slot:'robe',rarity:'common',name:'Runic Robe',glyph:'▣',description:'Take 12% less damage from all sources.'},
 {id:'wardrobe',slot:'robe',rarity:'common',name:'Warding Mantle',glyph:'◈',description:'Take 25% less projectile damage.'},
 {id:'thorns',slot:'robe',rarity:'rare',name:'Robe of Thorns',glyph:'✹',description:'Taking damage releases a 50% base-damage pulse within 75 units, once every 2 seconds.'},
 {id:'phantom',slot:'robe',rarity:'rare',name:'Phantom Cloak',glyph:'☾',description:'After taking damage, become invulnerable for 0.6s; 8s cooldown.'},
 {id:'mending',slot:'robe',rarity:'epic',name:'Mending Vestments',glyph:'✚',description:'Recover 2 HP every 2 seconds while below half health.'},
 {id:'aegis',slot:'robe',rarity:'legendary',name:'Aegis of Dawn',glyph:'⛨',description:'Block one otherwise damaging hit every 12 seconds.'},
 {id:'swift',slot:'boots',rarity:'common',name:'Fleet Boots',glyph:'»',description:'Move 12% faster.'},
 {id:'silk',slot:'boots',rarity:'common',name:'Spider Silk Boots',glyph:'⌘',description:'Ignore web movement penalties.'},
 {id:'runner',slot:'boots',rarity:'rare',name:'Runner’s Greaves',glyph:'⇢',description:'Move 25% faster below half health.'},
 {id:'escape',slot:'boots',rarity:'rare',name:'Escape Boots',glyph:'↯',description:'Move 35% faster for 1.5s after taking damage.'},
 {id:'trail',slot:'boots',rarity:'epic',name:'Trailblazer Boots',glyph:'♨',description:'While moving, pulse for 35% base damage within 48 units once per second.'},
 {id:'phaseboots',slot:'boots',rarity:'legendary',name:'Phasewalkers',glyph:'◌',description:'Move 18% faster and take 25% less contact damage.'},
 {id:'tonic',slot:'relic',rarity:'common',name:'Alchemist’s Charm',glyph:'✚',description:'Potions restore 35% more health.'},
 {id:'fang',slot:'relic',rarity:'common',name:'Vampire Fang',glyph:'♦',description:'Restore 0.5 HP per kill.'},
 {id:'gambler',slot:'relic',rarity:'rare',name:'Gambler’s Ring',glyph:'⚄',description:'Each cast has a 25% chance of double damage and 25% chance of half damage.'},
 {id:'hourglass',slot:'relic',rarity:'rare',name:'Hourglass of Eternity',glyph:'⌛',description:'Every 8s slow enemies within 115 units by 50% for 2s.'},
 {id:'lantern',slot:'relic',rarity:'epic',name:'Soul Lantern',glyph:'✺',description:'Every 12 kills release a 90-unit pulse for 100% base damage around the wizard.'},
 {id:'crown',slot:'relic',rarity:'legendary',name:'Cursed Crown',glyph:'♛',description:'Deal 25% more projectile damage, but take 15% more damage.'}
];
export const itemById=Object.fromEntries(equipment.map(i=>[i.id,i]));
const rarityOrder=['common','rare','epic','legendary'];
export const treasureMinutes=[2,7,12,17,22];
export function freshEquipment(){return {staff:null,robe:null,boots:null,relic:null}}
export function hasGear(p,id){return p.equipment?.[itemById[id]?.slot]===id}
export function equipItem(p,id,tick=0){
 const item=Object.hasOwn(itemById,id)?itemById[id]:null;if(!item||!p.equipment||hasGear(p,id))return false;
 p.equipment[item.slot]=id;
 if(item.slot==='relic')p.crownUntil=0;
 if(item.slot==='boots'){p.contactImmuneUntil=0;p.phaseImmuneUntil=0;}
 p.gearState[item.slot]={readyAt:tick,activeUntil:0,count:0};
 if(id==='hourglass'||id==='mending')p.gearState[item.slot].readyAt=tick+(id==='hourglass'?400:100);
 return true;
}
export function lootOffers(p,tier,rng){
 const max=Math.max(0,Math.min(3,tier)),pool=equipment.filter(i=>rarityOrder.indexOf(i.rarity)<=max&&!hasGear(p,i.id));
 const out=[];
 for(let j=0;j<3&&pool.length;j++){
  const distinct=pool.filter(i=>!out.some(o=>o.slot===i.slot));
  const candidates=distinct.length?distinct:pool;
  // Guarantee at least one item at the chest's advertised rarity if possible.
  const high=j===0?candidates.filter(i=>rarityOrder.indexOf(i.rarity)===max):[];
  const group=high.length?high:candidates,item=group[Math.min(group.length-1,Math.floor(rng()*group.length))];
  out.push(item);pool.splice(pool.indexOf(item),1);
 }
 return out;
}
export function gearMovement(p,tick){
 let v=1;if(hasGear(p,'swift'))v*=1.12;if(hasGear(p,'runner')&&p.health<p.maxHealth*.5)v*=1.25;
 if(hasGear(p,'escape')&&p.gearState.boots.activeUntil>tick)v*=1.35;if(hasGear(p,'phaseboots'))v*=1.18;return v;
}
export function gearCast(p,bolts,dx,dy,rng,tick=0){
 const staff=p.gearState.staff;staff.count++;
 let scale=hasGear(p,'crown')?1.25:1;
 if(hasGear(p,'crown')&&p.crownUntil>tick)scale*=1.5;
 if(hasGear(p,'gambler')){const v=rng();scale*=v<(attuned(p,'gambler','lightning')?.35:.25)?2:v<.5?.5:1}
 if(hasGear(p,'bloodwood')&&staff.count%4===0&&p.health>2){p.health-=2;scale*=1.5}
 const meteor=hasGear(p,'meteor')&&staff.count%3===0?{used:false}:null;
 const speed=hasGear(p,'longshot')?1.3:1;
 const result=bolts.map(b=>({...b,damage:b.damage*scale,vx:b.vx*speed,vy:b.vy*speed,meteor}));
 if(hasGear(p,'echo')&&staff.count%(attuned(p,'echo','arcane')?4:5)===0)result.push({vx:dx*p.shotSpd,vy:dy*p.shotSpd,damage:p.shotDmg*.6*scale});
 return result;
}
export function gearDamage(p,amount,source,tick){
 const robe=p.gearState.robe;
 if(hasGear(p,'phantom')&&robe.activeUntil>tick)return 0;
 if(hasGear(p,'aegis')&&robe.readyAt<=tick){robe.readyAt=tick+(attuned(p,'aegis','arcane')?450:600);return 0}
 let value=amount;
 if(hasGear(p,'linen'))value*=.88;if(hasGear(p,'wardrobe')&&source==='projectile')value*=.75;
 if(hasGear(p,'phaseboots')&&source==='contact')value*=.75;if(hasGear(p,'crown'))value*=1.15;
 return value;
}
