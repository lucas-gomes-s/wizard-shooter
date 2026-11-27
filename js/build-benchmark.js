// Targeted benchmark: no forced cards, no injected XP, no gameplay overrides.
import {Game} from './simulation.js';
import {schools,synergyFor} from './magic.js';
import {seededRng,botInput,botLoot,botPurchase} from './balance-bot.js';

export function buildTargets(){
 return schools.flatMap(a=>[{primary:a.id,secondary:null},...schools.filter(b=>b.id!==a.id).map(b=>({primary:a.id,secondary:b.id}))]);
}
export function targetedChoice(g,secondary){
 const p=g.player,m=p.magic,combo=synergyFor(m.primary,secondary);
 const score=o=>{
  if(o.kind==='mastery')return secondary===null?125:-Infinity;
  if(o.kind==='synergy')return o.id===combo?.id?120:-Infinity;
  if(o.kind==='school'){
   if(o.id!==m.primary&&o.id!==secondary)return -Infinity;
   if(o.rank===0)return o.id===secondary?110:-Infinity;
   if(secondary&&p.level>=10&&o.rank<2&&!m.synergies.includes(combo?.id))return 105;
   if(secondary===null&&p.level>=10)return 85;
   return o.rank<2?75:60;
  }
  if(o.kind==='basic'){
   if(o.index===0)return p.maxSpeed<4?90:30;
   if(o.index===2)return 80;
   if(o.index===3)return 70;
   return 50;
  }
  return -Infinity;
 };
 let best=-1,value=-Infinity;
 for(let i=0;i<g.offers.length;i++){const v=score(g.offers[i]);if(v>value){best=i;value=v}}
 return best;
}
export function simulateBuild(config,{primary,secondary=null,seed=1,seconds=1800,decisionTicks=5}){
 if(!schools.some(s=>s.id===primary)||secondary!==null&&!synergyFor(primary,secondary))throw Error('Invalid target build');
 const g=new Game(config,seededRng(seed));g.start(primary);
 let input={},firstUpgrade=null,secondaryAt=null,secondaryLevel=null,fusionAt=null,fusionLevel=null,maxEnemies=0,blocked=false,secondaryOfferedAt=null,masteryAt=null,masteryLevel=null;
 const combo=synergyFor(primary,secondary);
 const milestones={};
 for(let n=0;n<seconds*50&&g.phase!=='over'&&g.phase!=='victory';n++){
  while(g.phase==='upgrade'||g.phase==='loot'||g.phase==='shop'){
   if(g.phase==='shop'){g.choosePurchase(botPurchase(g));continue;}
   if(g.phase==='loot'){g.chooseLoot(botLoot(g));continue;}
   const p=g.player;
   if(firstUpgrade===null)firstUpgrade=g.tick/50;
   if(secondary&&secondaryOfferedAt===null&&g.offers.some(o=>o.kind==='school'&&o.id===secondary&&o.rank===0))secondaryOfferedAt=g.tick/50;
   const choice=targetedChoice(g,secondary);
   if(choice<0){blocked=true;break}
   const offer=g.offers[choice],level=p.level;
   if(!g.choose(choice))throw Error('Invalid offered upgrade');
   if(offer.kind==='school'&&offer.id===secondary&&secondaryAt===null){secondaryAt=g.tick/50;secondaryLevel=level}
   if(offer.kind==='synergy'&&offer.id===combo?.id){fusionAt=g.tick/50;fusionLevel=level}
   if(offer.kind==='mastery'){masteryAt=g.tick/50;masteryLevel=level}
  }
  if(blocked)break;
  if(g.tick%decisionTicks===0)input=botInput(g);
  g.step(input);maxEnemies=Math.max(maxEnemies,g.enemies.length);
  if(g.tick%15000===0)milestones[g.tick/50]={level:g.player.level,kills:g.kills,health:Math.round(g.player.health),enemies:g.enemies.length};
 }
 const p=g.player,xp=config.levels.slice(0,p.level-1).reduce((a,b)=>a+b,0)+p.currentExp;
 return {primary,secondary,seed,seconds:g.tick/50,phase:blocked?'blocked':g.phase,level:p.level,kills:g.kills,xp,health:Math.round(p.health),maxEnemies,firstUpgrade,secondaryOfferedAt,secondaryAt,secondaryLevel,fusion:combo?.id??null,fusionAt,fusionLevel,mastery:p.magic.mastery,masteryAt,masteryLevel,reachedDragon:g.bossSpawned,build:{...p.magic.ranks},equipment:{...p.equipment},chestsOpened:g.chestsOpened,lootHistory:g.lootHistory,eventHistory:g.dungeon.history,gold:p.gold,goldEarned:g.market.earned,goldSpent:g.market.spent,marketHistory:g.market.history,activeHistory:g.activeHistory,telemetry:g.reportCombat(),stats:{damage:p.shotDmg,castTicks:p.shotCd,speed:p.maxSpeed,maxHealth:p.maxHealth},milestones};
}
export function benchmarkBuilds(config,{seconds=1800,seeds=[1,2,3],decisionTicks=5,targets=buildTargets()}={}){
 return targets.flatMap(target=>seeds.map(seed=>simulateBuild(config,{...target,seconds,seed,decisionTicks})));
}
const mean=xs=>xs.length?xs.reduce((a,b)=>a+b,0)/xs.length:null;
const median=xs=>{if(!xs.length)return null;const a=[...xs].sort((x,y)=>x-y),n=a.length;return (a[(n-1)>>1]+a[n>>1])/2};
export function summarizeBuilds(results){
 return buildTargets().flatMap(({primary,secondary})=>{
  const rows=results.filter(r=>r.primary===primary&&r.secondary===secondary);if(!rows.length)return [];
  return [{primary,secondary,n:rows.length,wins:rows.filter(r=>r.phase==='victory').length,dragon:rows.filter(r=>r.reachedDragon).length,blocked:rows.filter(r=>r.phase==='blocked').length,secondaryLearned:rows.filter(r=>r.secondaryAt!==null).length,fusionLearned:rows.filter(r=>r.fusionAt!==null).length,medianSeconds:median(rows.map(r=>r.seconds)),meanSeconds:mean(rows.map(r=>r.seconds)),medianFusionAt:median(rows.filter(r=>r.fusionAt!==null).map(r=>r.fusionAt)),meanLevel:mean(rows.map(r=>r.level)),meanKills:mean(rows.map(r=>r.kills)),meanMaxEnemies:mean(rows.map(r=>r.maxEnemies))}];
 });
}
