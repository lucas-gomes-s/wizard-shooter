import {waveAt,waveInterval} from './waves.js';
// Open-loop balance metrics: no hidden scaling to player level.
export function spawnInterval(monster,seconds,settings={}){
 return Math.max(1,Math.round(monster.spawn*Math.max(settings.minSpawnFactor??1,1-seconds/60*(settings.spawnRampPerMinute??0))));
}
export function levelAtXP(xp,levels,maxLevel=50){
 let level=1;
 while(level<maxLevel&&xp>=levels[level-1]){xp-=levels[level-1];level++}
 return {level,remaining:xp};
}
export function forecast(config,minutes=[.25,.5,1,2,5,10,15,20,25],fractions=[.25,.5,.75]){
 const checkpoints=[...minutes].sort((a,b)=>a-b);
 const regular=config.monsters.filter(m=>m.name!=='Dragon');
 const timers=regular.map(()=>0), settings=config.balanceSettings||{};
 let totalXP=0,totalHP=0,spawns=0,eliteCount=0,regularCount=0,windowHP=0,windowSeconds=0,tick=0;
 const result=[],eliteStart=settings.eliteStart??180,eliteEvery=settings.eliteEvery??12;
 for(const minute of checkpoints){
  const target=Math.round(minute*3000);
  for(;tick<target;){
   tick++;const seconds=Math.floor(tick/50);
   for(const [i,m] of regular.entries()){
    if(seconds<m.startMinute*60)continue;
    if(++timers[i]<waveInterval(spawnInterval(m,seconds,settings),waveAt(seconds,config.waveDirector===true,seconds>=1500),m))continue;
    timers[i]=0;spawns++;
    const elite=seconds>=eliteStart&&++regularCount%eliteEvery===0;
    if(elite)eliteCount++;
    const hp=elite?Math.round(m.maxHealth*1.6):m.maxHealth;
    totalHP+=hp;windowHP+=hp;totalXP+=elite?Math.ceil(m.expGiven*1.8):m.expGiven;
   }
   for(const b of config.minibosses||[])if(tick===b.minute*3000){totalHP+=b.health;totalXP+=b.xp;windowHP+=b.health;spawns++;}
   windowSeconds++;
  }
  const hpPerSecond=regular.filter(m=>Math.floor(target/50)>=m.startMinute*60).reduce((sum,m)=>sum+50*m.maxHealth/waveInterval(spawnInterval(m,target/50,settings),waveAt(target/50,config.waveDirector===true,target>=75000),m)*(target/50>=eliteStart?1+.6/eliteEvery:1),0);
  result.push({minute,spawns,eliteCount,totalHP,totalXP,hpPerSecond:Math.round(hpPerSecond*10)/10,intervalHPPerSecond:Math.round(windowHP/Math.max(1,windowSeconds)*500)/10,levels:fractions.map(f=>levelAtXP(totalXP*f,config.levels,config.maxLevel).level)});
  windowHP=0;windowSeconds=0;
 }
 return result;
}
// Damage budget for an explicit reference allocation, not inferred from XP alone.
// Direct damage, hit fraction and a separate area-effect multiplier are independent assumptions.
export function referenceDps(level,{hitRate=.55,aoe=1.4}={}){
 const picks=Math.max(0,level-1),damageRanks=Math.min(20,Math.floor(picks/4)),castRanks=Math.min(9,Math.floor(picks/4));
 const damage=10+10*damageRanks,interval=Math.max(5,50-5*castRanks)/50;
 return {damage,interval,hitRate,aoe,dps:damage/interval*hitRate*aoe};
}
