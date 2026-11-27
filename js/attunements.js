// Equipment attunements activate automatically at school rank II, including secondary schools.
export const attunements=[
 {item:'meteor',school:'fire',name:'Solar impact',description:'Meteor burst damage rises from 45% to 65% base damage.'},
 {item:'trail',school:'fire',name:'Scorched earth',description:'Movement pulses deal 50% instead of 35% base damage.'},
 {item:'prism',school:'ice',name:'Crystal lance',description:'Gain one further piercing target per projectile.'},
 {item:'hourglass',school:'ice',name:'Deep winter',description:'Time Stop freezes for 1.6 seconds instead of 1.2.'},
 {item:'longshot',school:'lightning',name:'Conductive focus',description:'Chain lightning gains 30 units of range.'},
 {item:'gambler',school:'lightning',name:'Loaded thunder',description:'Double-damage cast chance rises to 35%; half-damage chance falls to 15%.'},
 {item:'fang',school:'necro',name:'Sanguine pact',description:'Fang healing increases to 0.8 HP per kill.'},
 {item:'lantern',school:'necro',name:'Soul harvest',description:'Passive soul pulses trigger every 9 kills instead of 12.'},
 {item:'echo',school:'arcane',name:'Echo chamber',description:'Extra bolt triggers every fourth cast instead of every fifth.'},
 {item:'aegis',school:'arcane',name:'Astral guard',description:'Aegis recharges in 9 seconds instead of 12.'}
];
export function attuned(p,item,school){
 return (p.magic?.ranks[school]||0)>=2&&Object.values(p.equipment||{}).includes(item);
}
export function itemAttunements(id){return attunements.filter(a=>a.item===id)}
