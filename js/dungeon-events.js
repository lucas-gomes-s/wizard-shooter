import {addGold} from './merchant.js';
// Optional dungeon challenges. All timings use the 50 Hz simulation clock.
import {ENEMY_CAP,HAZARD_CAP} from './enemies.js';
export const eventWindows=[210,510,810,1110,1380];
export const dungeonEvents=[
 {id:'altar',name:'Cursed altar',glyph:'✹',color:'#ff9467',duration:30,description:'Survive 30 seconds of summoned reinforcements.'},
 {id:'shrine',name:'Arcane shrine',glyph:'◇',color:'#c6a2ff',duration:40,description:'Spend 15 seconds inside the ritual circle before time expires.'},
 {id:'guardian',name:'Treasure guardian',glyph:'♛',color:'#ffd277',duration:40,description:'Slay the marked treasure guardian before it escapes.'},
 {id:'moon',name:'Blood moon',glyph:'☾',color:'#ff7183',duration:35,description:'Slay the required number of monsters before the moon fades.'},
 {id:'collapse',name:'Dungeon collapse',glyph:'⚠',color:'#ffbf73',duration:30,description:'Survive the falling rubble. Avoid taking three collapse hits.'},
 {id:'anomaly',name:'Magical anomaly',glyph:'✧',color:'#78e9de',duration:40,description:'Collect all three unstable runes before they disappear.'}
];
export const eventById=Object.fromEntries(dungeonEvents.map(e=>[e.id,e]));
const eventCenter=o=>({x:o.x+o.width/2,y:o.y+o.height/2});
const eventDistance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const eventPosition=(x,y,r,a)=>({x:x+Math.cos(a)*r,y:y+Math.sin(a)*r});
export function freshEvents(){return {cursor:0,deck:[],active:null,history:[],notice:null}}
export function announceEvent(g,id){
 const state=g.dungeon,def=eventById[id];if(!def||state.active||g.bossSpawned)return false;
 const p=eventCenter(g.player),angle=g.rng()*Math.PI*2,r=Math.min(150,Math.min(g.width,g.height)*.28);
 const pos=eventPosition(p.x,p.y,r,angle);
 state.active={id,serial:state.cursor,stage:'offered',...pos,radius:36,until:g.tick+35*50,progress:0,goal:1,hits:0,runes:[],target:null};
 return true;
}
function finish(g,outcome){
 const s=g.dungeon,e=s.active;if(!e)return;
 const def=eventById[e.id],p=eventCenter(g.player);
 if(outcome==='completed'){
  const tier=g.seconds>=1200?3:g.seconds>=600?2:1;
  addGold(g,15*tier);
  // Drop close to the wizard, but never stack on the player's collision box.
  if(g.config.equipmentEnabled!==false)g.dropChest(p.x+55,p.y,tier,def.name+' reward');
 }
 s.history.push({id:e.id,outcome,tick:g.tick,startedAt:e.startedAt??null,progress:e.progress,goal:e.goal,hits:e.hits});
 s.notice={text:def.name+' · '+(outcome==='completed'?'Completed! Reward nearby':outcome==='ignored'?'Opportunity expired':'Challenge failed'),until:g.tick+250,outcome};
 // Event-only threats disappear without kills, healing or XP on expiration.
 g.enemies=g.enemies.filter(o=>o.eventSerial!==e.serial);
 g.hazards=g.hazards.filter(o=>o.eventSerial!==e.serial);
 g.hostiles=g.hostiles.filter(o=>o.eventSerial!==e.serial);
 s.active=null;
}
function eventEnemy(g,e,guardian=false){
 if(g.enemies.length>=ENEMY_CAP)return null;
 const candidates=g.config.monsters.filter(m=>m.name!=='Dragon'&&m.startMinute*60<=g.seconds);
 if(!candidates.length)return null;
 const template=guardian?candidates[candidates.length-1]:candidates[Math.floor(g.rng()*candidates.length)];
 const enemy=g.spawnAtEdge(template,guardian);enemy.eventSerial=e.serial;
 if(guardian){
  enemy.eventGuardian=true;enemy.health=enemy.maxHealth=Math.max(120,Math.round(template.health*3.5));enemy.damage=Math.round(template.damage*1.15);
  enemy.expGiven=template.expGiven*2;
 }else{enemy.expGiven=Math.max(1,Math.round(enemy.expGiven*.65));}
 g.enemies.push(enemy);return enemy;
}
function start(g,e){
 const def=eventById[e.id];e.stage='active';e.startedAt=g.tick;e.until=g.tick+def.duration*50;e.nextPulse=g.tick;e.startKills=g.kills;
 switch(e.id){
 case 'shrine':e.radius=95;e.goal=750;break;
 case 'guardian':e.goal=1;e.target=eventEnemy(g,e,true);if(!e.target){finish(g,'failed');return;}break;
 case 'moon':e.goal=Math.min(45,16+Math.floor(g.seconds/60));break;
 case 'collapse':e.goal=3;break;
 case 'anomaly':{
  e.goal=3;const offset=g.rng()*Math.PI*2;
  e.runes=Array.from({length:3},(_,i)=>({...eventPosition(e.x,e.y,130,offset+i*Math.PI*2/3),collected:false}));break;
 }
 case 'altar':e.goal=def.duration*50;break;
 }
}
export function recordEventDeath(g,enemy){
 const e=g.dungeon?.active;
 if(e?.stage==='active'&&e.id==='guardian'&&enemy===e.target)e.progress=1;
}
export function recordEventHazard(g,h,damage){
 const e=g.dungeon?.active;
 if(damage>0&&e?.stage==='active'&&e.id==='collapse'&&h.eventSerial===e.serial)e.hits++;
}
export function stepDungeon(g){
 if(g.config.eventsEnabled===false||g.config.equipmentEnabled===false)return;
 const s=g.dungeon,t=g.tick,p=eventCenter(g.player);
 if(g.player.health<=0){if(s.active)finish(g,s.active.stage==='offered'?'ignored':'failed');return;}
 if(g.bossSpawned){if(s.active)finish(g,s.active.stage==='offered'?'ignored':'failed');return;}
 if(!s.active&&s.cursor<eventWindows.length&&g.seconds>=eventWindows[s.cursor]){
  // Consume missed windows rather than starting a backlog of simultaneous events.
  while(s.cursor<eventWindows.length&&g.seconds>eventWindows[s.cursor]+60)s.cursor++;
  if(s.cursor<eventWindows.length&&g.seconds>=eventWindows[s.cursor]){
   if(!s.deck.length)s.deck=dungeonEvents.map(d=>d.id);
   const i=Math.floor(g.rng()*s.deck.length),id=s.deck.splice(i,1)[0];s.cursor++;announceEvent(g,id);
  }
 }
 const e=s.active;if(!e)return;
 if(e.stage==='offered'){
  if(t>=e.until){finish(g,'ignored');return;}
  if(eventDistance(p,e)<=e.radius)start(g,e);
  return;
 }
 switch(e.id){
 case 'altar':
  e.progress=t-e.startedAt;
  if(t>=e.nextPulse&&t<e.until){e.nextPulse=t+200;for(let i=0;i<2;i++)eventEnemy(g,e);}
  if(t>=e.until){finish(g,'completed');return;}break;
 case 'shrine':
  if(eventDistance(p,e)<=e.radius)e.progress++;
  if(e.progress>=e.goal){finish(g,'completed');return;}break;
 case 'guardian':
  if(e.progress>=1){finish(g,'completed');return;}
  if(!g.enemies.includes(e.target)){finish(g,'failed');return;}break;
 case 'moon':
  e.progress=g.kills-e.startKills;
  if(e.progress>=e.goal){finish(g,'completed');return;}
  if(t>=e.nextPulse){e.nextPulse=t+150;eventEnemy(g,e);}break;
 case 'collapse':
  if(e.hits>=3){finish(g,'failed');return;}
  if(t>=e.until){finish(g,'completed');return;}
  if(t>=e.nextPulse){
   e.nextPulse=t+150;
   for(let i=0;i<3&&g.hazards.length<HAZARD_CAP;i++){
    const pos=i===0?p:eventPosition(p.x,p.y,65+g.rng()*90,g.rng()*Math.PI*2);
    g.hazards.push({type:'rubble',...pos,radius:34,activeAt:t+55,until:t+85,damage:Math.min(28,10+Math.floor(g.seconds/60)),hit:false,eventSerial:e.serial});
   }
  }break;
 case 'anomaly':
  for(const rune of e.runes)if(!rune.collected&&eventDistance(p,rune)<=30){rune.collected=true;e.progress++;}
  if(e.progress>=e.goal){finish(g,'completed');return;}break;
 }
 if(t>=e.until)finish(g,'failed');
}
export function eventObjective(g){
 const e=g.dungeon?.active;if(!e)return null;
 if(e.stage==='offered')return 'Enter the marked circle to accept, or ignore it';
 if(e.id==='altar')return 'Survive the summoned wave';
 if(e.id==='shrine')return 'Ritual: '+Math.min(15,Math.floor(e.progress/50))+' / 15s inside circle';
 if(e.id==='guardian')return 'Guardian HP: '+Math.max(0,Math.ceil(e.target?.health||0))+' / '+(e.target?.maxHealth||0);
 if(e.id==='moon')return 'Kills: '+e.progress+' / '+e.goal;
 if(e.id==='collapse')return 'Rubble hits: '+e.hits+' / 3 · survive';
 return 'Runes: '+e.progress+' / 3';
}
