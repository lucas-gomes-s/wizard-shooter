// Biomes preserve the original crypt and reuse established enemy behavior families.
// Spawn factors below 1 mean more frequent spawning; no player-level scaling.
export const environments=[
 {id:'crypt',name:'The Forgotten Crypt',description:'The original dungeon. Balanced enemy roster and no biome-specific hazards.',color:'#bda0ed',ground:'#24202a',tint:'rgba(18,14,26,.53)',boss:'Ancient Dragon',rules:{}},
 {id:'frost',name:'The Frozen Hollow',description:'More spiders, knights and reapers. Telegraphing ice fissures slow and damage the wizard. Fewer demons.',color:'#93d9ff',ground:'#172c3b',tint:'rgba(18,52,78,.60)',boss:'Frostbound Dragon',hazard:{type:'frost-fissure',start:120,interval:18,radius:46,warning:70,duration:55,damage:8},rules:{Spider:{spawn:.72},Goblin:{spawn:1.12},Knight:{spawn:.8},Reaper:{spawn:.85},Demon:{spawn:1.4}}},
 {id:'forge',name:'The Ashen Forge',description:'More orcs and demons, fewer spiders and reapers. Erupting lava vents force you to relocate.',color:'#ffac74',ground:'#39251e',tint:'rgba(82,31,13,.57)',boss:'Ember Dragon',hazard:{type:'lava-vent',start:120,interval:16,radius:49,warning:60,duration:65,damage:12},rules:{Spider:{spawn:1.45},Orc:{spawn:.75},Zombie:{spawn:1.15},Reaper:{spawn:1.3},Demon:{spawn:.78}}}
];
export function environmentById(id){return environments.find(e=>e.id===id)||environments[0]}
export function environmentConfig(base,id){
 const env=environmentById(id);
 if(env.id==='crypt')return {...base,environment:'crypt'};
 return {...base,environment:env.id,monsters:base.monsters.map(m=>({...m,spawn:Math.round(m.spawn*(env.rules[m.name]?.spawn||1))}))};
}
export function stepEnvironment(g,cap){
 const env=environmentById(g.config.environment),h=env.hazard;
 if(!h||g.config.environmentHazards===false||g.tick<h.start*50||g.tick<g.nextEnvironmentHazard)return;
 g.nextEnvironmentHazard=g.tick+h.interval*50;
 if(g.hazards.length>=cap)return;
 const p=g.player,x=p.x+p.width/2,y=p.y+p.height/2;
 // First zone targets the current position. After minute 10 add an offset zone.
 const count=g.seconds>=600?2:1;
 for(let i=0;i<count&&g.hazards.length<cap;i++){
  const angle=i?g.rng()*Math.PI*2:0,r=i?95:0;
  g.hazards.push({type:h.type,x:x+Math.cos(angle)*r,y:y+Math.sin(angle)*r,radius:h.radius,activeAt:g.tick+h.warning,until:g.tick+h.warning+h.duration,warning:h.warning,damage:h.damage+(g.seconds>=900?4:0),hit:false,environment:true});
 }
}
