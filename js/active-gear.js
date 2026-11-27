import {attuned} from './attunements.js';
// Active skills are additive to existing passive gear. Cooldown belongs to the slot.
import {hasGear} from './equipment.js';
export const activeGear={
 runner:{name:'Wind dash',slot:'boots',cooldown:350,description:'Dash 85 units in your movement or aim direction; immune to contact for 0.25s.'},
 escape:{name:'Escape leap',slot:'boots',cooldown:450,description:'Dash 110 units, clear webs and gain 0.4s contact immunity.'},
 trail:{name:'Blazing step',slot:'boots',cooldown:500,description:'Dash 70 units and release a 90% base-damage pulse at your destination.'},
 phaseboots:{name:'Phase shift',slot:'boots',cooldown:450,description:'Teleport 120 units and ignore damage for 0.5s.'},
 hourglass:{name:'Time stop',slot:'relic',cooldown:1000,description:'Freeze nearby enemies within 140 units for 1.2s.'},
 lantern:{name:'Soul eruption',slot:'relic',cooldown:750,description:'Deal 180% base damage within 120 units.'},
 crown:{name:'Forbidden power',slot:'relic',cooldown:1000,description:'Empower projectile damage by 50% for 4s at a cost of 10% maximum HP.'},
 tonic:{name:'Emergency tonic',slot:'relic',cooldown:1250,description:'Recover 12% maximum health.'}
};
export function activeInfo(p,slot,tick){
 const a=activeGear[p.equipment?.[slot]];if(!a)return null;
 return {...a,remaining:Math.max(0,(p.activeReady?.[slot]||0)-tick)};
}
export function useBoots(g,input,dx,dy){
 const p=g.player,a=activeInfo(p,'boots',g.tick);if(!input.boots||!a||a.remaining||p.health<=0)return false;
 let x=dx,y=dy;if(!x&&!y){[x,y]=input.aim||p.lastDirection||[0,0];const n=Math.hypot(x,y);if(n){x/=n;y/=n;}}
 if(!x&&!y)return false;
 const id=p.equipment.boots,distance={runner:85,escape:110,trail:70,phaseboots:120}[id];
 p.activeReady.boots=g.tick+a.cooldown;
 const old={x:p.x,y:p.y,width:p.width,height:p.height};
 p.x+=x*distance;p.y+=y*distance;
 if(id==='escape'||id==='phaseboots')p.webUntil=0;
 p.contactImmuneUntil=g.tick+(id==='escape'?20:id==='phaseboots'?25:13);
 if(id==='phaseboots')p.phaseImmuneUntil=g.tick+25;
 g.emitVisual('teleport',old,0,'arcane');g.emitVisual('teleport',p,0,'arcane');
 g.activeHistory.push({id,tick:g.tick});return id==='trail';
}
export function useRelic(g,input,hash,nearby){
 const p=g.player,a=activeInfo(p,'relic',g.tick);if(!input.relic||!a||a.remaining||p.health<=0)return false;
 const id=p.equipment.relic;
 if(id==='tonic'&&p.health>=p.maxHealth)return false;
 if(id==='crown'&&p.health<=p.maxHealth*.1)return false;
 p.activeReady.relic=g.tick+a.cooldown;
 if(id==='hourglass'){g.emit('burst',p,140,'ice');for(const e of nearby(hash,p,140)){e.freezeUntil=Math.max(e.freezeUntil||0,g.tick+(attuned(p,'hourglass','ice')?80:60));g.emitVisual('freeze',e,0,'ice');}}
 if(id==='lantern')g.pulse(hash,p,120,p.shotDmg*1.8,'necro',null,'gear:lantern:active');
 if(id==='crown'){p.health-=p.maxHealth*.1;g.recordCost('gear:crown',p.maxHealth*.1);p.crownUntil=g.tick+200;g.emit('burst',p,50,'fire');}
 if(id==='tonic')g.healPlayer(p.maxHealth*.12,'necro','gear:tonic:active');
 g.activeHistory.push({id,tick:g.tick});return true;
}
