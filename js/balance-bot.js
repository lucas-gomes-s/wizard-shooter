import {itemAttunements} from './attunements.js';
import {Game} from './simulation.js';
import {itemById} from './equipment.js';
import {schools} from './magic.js';
export function seededRng(seed){let s=seed>>>0;return ()=>{s=(Math.imul(1664525,s)+1013904223)>>>0;return s/4294967296}}
function center(o){return [o.x+o.width/2,o.y+o.height/2]}
export function botInput(g){
 const p=g.player,[px,py]=center(p);
 const enemies=g.enemies.filter(e=>g.visible(e,40)&&e.health>0);
 const targets=enemies.map(e=>{const [x,y]=center(e);return {e,dx:x-px,dy:y-py,d:Math.hypot(x-px,y-py)}}).sort((a,b)=>a.d-b.d);
 let x=0,y=0,aim;
 // Aim along the closest cardinal axis; align with a target when safe.
 const target=targets[0];
 if(target){
  const {dx,dy,d}=target;
  aim=Math.abs(dx)>Math.abs(dy)?[Math.sign(dx),0]:[0,Math.sign(dy)];
  if(d>110){if(aim[0])y=Math.sign(dy);else x=Math.sign(dx);}
  else if(d<90){x-=dx/Math.max(1,d)*2;y-=dy/Math.max(1,d)*2;}
 }
 for(const t of targets.slice(0,12))if(t.d<120){const w=(120-t.d)/120*3;x-=t.dx/Math.max(1,t.d)*w;y-=t.dy/Math.max(1,t.d)*w;}
 for(const h of g.hazards){const dx=h.x-px,dy=h.y-py,d=Math.hypot(dx,dy);if(d<h.radius+50){x-=dx/Math.max(1,d)*3;y-=dy/Math.max(1,d)*3;}}
 for(const s of g.hostiles){const dx=s.x-px,dy=s.y-py,d=Math.hypot(dx,dy);if(d<70){x-=dx/Math.max(1,d)*2;y-=dy/Math.max(1,d)*2;}}
 if(p.health<p.maxHealth*.55&&(!target||target.d>100)){
  const pot=g.potions.map(o=>{const [x,y]=center(o);return {dx:x-px,dy:y-py,d:Math.hypot(x-px,y-py)}}).sort((a,b)=>a.d-b.d)[0];
  if(pot&&pot.d<250){x+=pot.dx/Math.max(1,pot.d)*1.5;y+=pot.dy/Math.max(1,pot.d)*1.5;}
 }
 const chest=(g.chests||[]).map(o=>{const [cx,cy]=center(o);return {dx:cx-px,dy:cy-py,d:Math.hypot(cx-px,cy-py)}}).sort((a,b)=>a.d-b.d)[0];
 if(chest&&chest.d<500&&(!target||target.d>85)){x+=chest.dx/Math.max(1,chest.d)*2;y+=chest.dy/Math.max(1,chest.d)*2;}
 const event=g.dungeon?.active;
 if(event&&p.health>p.maxHealth*.35){
  let objective=null;
  if(event.stage==='offered')objective=event;
  else if(event.id==='shrine')objective=event;
  else if(event.id==='anomaly')objective=event.runes.filter(r=>!r.collected).sort((a,b)=>Math.hypot(a.x-px,a.y-py)-Math.hypot(b.x-px,b.y-py))[0];
  else if(event.id==='guardian'&&event.target){const [gx,gy]=center(event.target);if(Math.hypot(gx-px,gy-py)>130)objective={x:gx,y:gy};}
  if(objective&&(!target||target.d>65)){const dx=objective.x-px,dy=objective.y-py,d=Math.hypot(dx,dy);if(d>15){x+=dx/d*2.5;y+=dy/d*2.5;}}
 }
 const merchant=g.market?.merchant;
 if(merchant&&p.gold>=35&&(!target||target.d>85)){
  const dx=merchant.x-px,dy=merchant.y-py,d=Math.hypot(dx,dy);if(d>10){x+=dx/d*2.4;y+=dy/d*2.4;}
 }
 const boots=!!target&&target.d<65&&(x*x+y*y)>0;
 const relic=p.equipment.relic==='tonic'?p.health<p.maxHealth*.65:p.equipment.relic==='crown'?p.health>p.maxHealth*.7&&targets.length>=5:targets.filter(t=>t.d<130).length>=3;
 return {x,y,aim,boots,relic};
}
const gearValues={quickwand:6,longshot:4,echo:7,bloodwood:7,prism:8,meteor:9,linen:6,wardrobe:4,thorns:7,phantom:7,mending:5,aegis:9,swift:6,silk:3,runner:5,escape:5,trail:7,phaseboots:9,tonic:4,fang:7,gambler:6,hourglass:6,lantern:8,crown:7};
function gearScore(p,id){return (gearValues[id]||0)+(itemAttunements(id).some(a=>p.magic.ranks[a.school]>=2)?1.5:0)}
export function botLoot(g){
 const values=gearValues;
 let best=-1,score=0;
 for(const [i,item] of g.loot.entries()){
  const old=itemById[g.player.equipment[item.slot]];
  const value=gearScore(g.player,item.id)-gearScore(g.player,old?.id);
  if(value>score){score=value;best=i;}
 }
 return best;
}
export function botPurchase(g){
 const p=g.player;let best=-1,score=0;
 for(const [i,o] of g.market.offers.entries()){
  if(o.price>p.gold)continue;
  const value=o.kind==='heal'?(p.health<p.maxHealth*.55?8:0):(gearScore(p,o.id)-gearScore(p,p.equipment[o.slot]));
  const v=value-o.price/100;
  if(v>score){score=v;best=i;}
 }
 return best;
}
export function botChoose(g){
 const p=g.player;
 const score=o=>{
  if(o.kind==='mastery')return 9.5;
  if(o.kind==='synergy')return 9;
  if(o.kind==='basic'){if(o.index===2)return 8;if(o.index===0)return p.maxSpeed<4?10:3;if(o.index===3)return 7;return 4;}
  return {fire:6.4,ice:7.2,lightning:6.6,arcane:6.8,necro:5.8}[o.id]+o.rank*.12;
 };
 return g.offers.reduce((best,o,i)=>score(o)>score(g.offers[best])?i:best,0);
}
export function simulate(config,{school='fire',seed=1,seconds=180,decisionTicks=5}={}){
 const g=new Game(config,seededRng(seed));g.start(school);let input={},firstUpgrade=null,maxEnemies=0,earnedXP=0,lastLevel=1,spentXP=0;
 for(let n=0;n<seconds*50&&g.phase!=='over'&&g.phase!=='victory';n++){
  while(g.phase==='upgrade'||g.phase==='loot'||g.phase==='shop'){if(g.phase==='shop'){g.choosePurchase(botPurchase(g));continue;}if(g.phase==='loot'){g.chooseLoot(botLoot(g));continue;}if(firstUpgrade===null)firstUpgrade=g.tick/50;g.choose(botChoose(g));}
  if(g.tick%decisionTicks===0)input=botInput(g);
  g.step(input);maxEnemies=Math.max(maxEnemies,g.enemies.length);
  while(lastLevel<g.player.level){spentXP+=config.levels[lastLevel-1];lastLevel++}
  earnedXP=spentXP+g.player.currentExp;
 }
 return {school,seed,seconds:g.tick/50,phase:g.phase,level:g.player.level,firstUpgrade,kills:g.kills,xp:earnedXP,health:Math.round(g.player.health),maxEnemies,build:g.player.magic.ranks,equipment:{...g.player.equipment},chestsOpened:g.chestsOpened,lootHistory:g.lootHistory,eventHistory:g.dungeon.history,gold:g.player.gold,marketHistory:g.market.history,goldEarned:g.market.earned,goldSpent:g.market.spent,activeHistory:g.activeHistory,telemetry:g.reportCombat()};
}
export function benchmark(config,{seconds=180,seeds=[1,2,3],decisionTicks=5}={}){
 return schools.flatMap(s=>seeds.map(seed=>simulate(config,{school:s.id,seed,seconds,decisionTicks})));
}
