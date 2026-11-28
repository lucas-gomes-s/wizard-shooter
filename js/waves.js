// Open-loop wave director: only elapsed simulation time and scheduled boss state.
// A rate of 1 is the old spawn curve; enemy stats and unlock times never change.
export const WAVE_SECONDS=90;
export const wavePhases=[
 {id:'advance',name:'Gathering shadows',duration:30,rate:.90,color:'#b4a4d1'},
 {id:'surge',name:'Enemy surge',duration:25,rate:1.22,color:'#edb479'},
 {id:'peak',name:'Overwhelming horde',duration:15,rate:1.45,color:'#f08a87'},
 {id:'recovery',name:'Breathing room',duration:20,rate:.52,color:'#93d9bd'}
];
const themes=[
 {name:'Swarm',enemies:['Goblin','Spider','Zombie']},
 {name:'Assault',enemies:['Orc','Knight','Vampire']},
 {name:'Nightmare',enemies:['Reaper','Demon','Spider']}
];
export function waveAt(seconds,enabled=true,boss=false){
 if(!enabled)return {id:'classic',name:'Classic pacing',rate:1,remaining:0,color:'#b4a4d1',theme:null};
 if(boss)return {id:'boss',name:'Dragon confrontation',rate:1,remaining:0,color:'#f08a87',theme:null};
 if(seconds<60)return {id:'opening',name:'The first descent',rate:1,remaining:60-seconds,color:'#b4a4d1',theme:null};
 const elapsed=Math.max(0,Math.floor(seconds)-60),cycle=Math.floor(elapsed/WAVE_SECONDS),theme=themes[cycle%themes.length];
 let offset=elapsed%WAVE_SECONDS;
 for(const phase of wavePhases){if(offset<phase.duration)return {...phase,cycle:cycle+1,theme,remaining:phase.duration-offset};offset-=phase.duration}
}
export function waveRate(wave,monster){
 if(!wave.theme||!['surge','peak'].includes(wave.id))return wave.rate;
 // Theme modifiers change composition, not unlocked species.
 return wave.rate*(wave.theme.enemies.includes(monster.name)?1.12:.94);
}
export function waveInterval(base,wave,monster){return Math.max(1,Math.round(base/waveRate(wave,monster)))}
export function freshPacing(){return {samples:0,visibleSum:0,maxVisible:0,quietSeconds:0,crowdedSeconds:0,spawned:0,capSkips:0,upgrades:0,lastUpgradeTick:0,maxUpgradeGapTicks:0,phases:{},windows:[]}}
function phaseStats(p,id){return p.phases[id]??(p.phases[id]={samples:0,visibleSum:0,spawned:0,capSkips:0})}
export function recordSpawn(p,wave,blocked=false){const s=phaseStats(p,wave.id);if(blocked){p.capSkips++;s.capSkips++}else{p.spawned++;s.spawned++}}
export function recordUpgrade(p,tick){p.upgrades++;p.maxUpgradeGapTicks=Math.max(p.maxUpgradeGapTicks,tick-p.lastUpgradeTick);p.lastUpgradeTick=tick}
export function samplePacing(g,wave){
 if(g.tick%50!==0)return;
 const p=g.pacing,n=g.enemies.filter(e=>e.health>0&&g.visible(e,0)).length,s=phaseStats(p,wave.id);
 p.samples++;p.visibleSum+=n;p.maxVisible=Math.max(p.maxVisible,n);if(n<=3)p.quietSeconds++;if(n>=25)p.crowdedSeconds++;
 s.samples++;s.visibleSum+=n;
 const start=Math.floor((g.tick-1)/750)*15;let w=p.windows[p.windows.length-1];
 if(!w||w.start!==start){w={start,samples:0,visibleSum:0,maxVisible:0,level:g.player.level,kills:g.kills,health:g.player.health};p.windows.push(w);if(p.windows.length>240)p.windows.shift()}
 w.samples++;w.visibleSum+=n;w.maxVisible=Math.max(w.maxVisible,n);w.level=g.player.level;w.kills=g.kills;w.health=g.player.health;
}
export function pacingSummary(p,tick){return {...p,meanVisible:p.samples?p.visibleSum/p.samples:0,quietFraction:p.samples?p.quietSeconds/p.samples:0,crowdedFraction:p.samples?p.crowdedSeconds/p.samples:0,maxUpgradeGapSeconds:Math.max(p.maxUpgradeGapTicks,tick-p.lastUpgradeTick)/50}}
