// Enemy behavior and hazards are pure fixed-tick simulation, not rendering.
const TAU=Math.PI*2;
export const ENEMY_CAP=260, HOSTILE_CAP=320, HAZARD_CAP=100;
export const BOSS_MINUTE=25;
export function centerOf(o){return {x:o.x+o.width/2,y:o.y+o.height/2}}
export function unit(x,y){const d=Math.hypot(x,y);return d?[x/d,y/d]:[1,0]}
function vector(e,p){const a=centerOf(e),b=centerOf(p);return {dx:b.x-a.x,dy:b.y-a.y,d:Math.hypot(b.x-a.x,b.y-a.y)}}
function move(e,dx,dy,speed){const [x,y]=unit(dx,dy);e.x+=x*speed;e.y+=y*speed}
function aim(e,p){const {dx,dy}=vector(e,p);return Math.atan2(dy,dx)}
function pursuit(e,p,speed){const {dx,dy,d}=vector(e,p);if(d>0)move(e,dx,dy,Math.min(d,speed))}
function cooldown(e,tick,ticks){e.nextAttack=tick+ticks;e.action=null}
export function initEnemy(template,x,y,tick,elite=false){
 const e={...template,x,y,cd:0,nextAttack:tick+50,action:null,facing:0,elite};
 if(elite){e.health=e.maxHealth=Math.round(e.maxHealth*1.6);e.damage=Math.round(e.damage*1.25);e.expGiven=Math.ceil(e.expGiven*1.8);}
 if(e.name==='Dragon'){e.boss=true;e.elite=false;e.health=e.maxHealth=6000;e.damage=65;e.nextAttack=tick+75;e.bossPhase=1;}
 return e;
}
function fire(game,e,angle,damage,speed=5,radius=6){
 if(game.hostiles.length>=HOSTILE_CAP)return;
 const c=centerOf(e);game.hostiles.push({x:c.x,y:c.y,vx:Math.cos(angle)*speed,vy:Math.sin(angle)*speed,radius,damage,age:0,source:e.name});
}
function hazard(game,type,x,y,radius,delay,duration,damage=0){
 if(game.hazards.length>=HAZARD_CAP)return;
 game.hazards.push({type,x,y,radius,activeAt:game.tick+delay,until:game.tick+delay+duration,damage,hit:false});
}
function begin(e,tick,kind,duration,extra={}){e.action={kind,until:tick+duration,...extra}}
export function stepEnemy(game,e,factor=1){
 const p=game.player,t=game.tick,{d,dx,dy}=vector(e,p),speed=e.maxSpeed*factor;
 if(e.nextAttack===undefined)e.nextAttack=t+50;
 if(e.name==='Dragon')e.bossPhase=e.health/e.maxHealth<=.33?3:e.health/e.maxHealth<=.66?2:1;
 // Stun holds position, but does not let a completed windup fire while frozen.
 if(factor===0){if(e.action)e.action.until++;e.nextAttack++;return;}
 if(d>0&&(!e.action||e.action.kind!=='charge'))e.facing=Math.atan2(dy,dx);
 if(e.action){
  const a=e.action;
  if(a.kind==='charge'){
   move(e,Math.cos(a.angle),Math.sin(a.angle),speed*2.1);
   if(t>=a.until){begin(e,t,'recover',35);e.nextAttack=t+105;}return;
  }
  if(t<a.until)return;
  e.action=null;
  switch(a.kind){
   case 'orc-windup':begin(e,t,'charge',22,{angle:a.angle});return;
   case 'recover':return;
   case 'reaper-windup':e.x=a.x-e.width/2;e.y=a.y-e.height/2;cooldown(e,t,175);return;
   case 'demon-windup':for(const offset of [-.23,0,.23])fire(game,e,a.angle+offset,Math.round(e.damage*.65),5.3);cooldown(e,t,110);return;
   case 'dragon-windup':{
    const n=e.bossPhase===1?5:e.bossPhase===2?8:12;
    for(let i=0;i<n;i++){const angle=e.bossPhase===1?a.angle+(i-(n-1)/2)*.22:a.angle+i*TAU/n;fire(game,e,angle,24+e.bossPhase*6,5+e.bossPhase*.4,9)}
    if(e.bossPhase>=2){hazard(game,'flame',a.x,a.y,65,35,25,35);if(e.bossPhase===3){hazard(game,'flame',a.x+95,a.y,48,35,25,35);hazard(game,'flame',a.x-95,a.y,48,35,25,35)}}
    cooldown(e,t,e.bossPhase===3?80:120);return;
   }
  }
 }
 switch(e.name){
  case 'Spider':
   if(t>=e.nextAttack&&d<180){const c=centerOf(p);hazard(game,'web',c.x,c.y,46,32,170);e.nextAttack=t+190;}
   pursuit(e,p,speed*.8);break;
  case 'Orc':
   if(t>=e.nextAttack&&d<220&&d>38){begin(e,t,'orc-windup',38,{angle:aim(e,p)});return;}
   pursuit(e,p,speed*.7);break;
  case 'Zombie':pursuit(e,p,speed*(e.health<e.maxHealth*.5?1.35:.85));break;
  case 'Knight':pursuit(e,p,speed*.78);break;
  case 'Vampire':pursuit(e,p,speed*.85);break;
  case 'Reaper':
   if(t>=e.nextAttack&&d<320&&d>45){const c=centerOf(p),angle=aim(e,p)+Math.PI/2*(game.rng()<.5?-1:1);begin(e,t,'reaper-windup',48,{x:c.x+Math.cos(angle)*95,y:c.y+Math.sin(angle)*95});return;}
   pursuit(e,p,speed*.6);break;
  case 'Demon':
   if(t>=e.nextAttack&&d<420){begin(e,t,'demon-windup',45,{angle:aim(e,p)});return;}
   if(d>230)pursuit(e,p,speed*.55);else if(d<145)move(e,-dx,-dy,speed*.35);break;
  case 'Dragon':
   if(t>=e.nextAttack&&d<470){const c=centerOf(p);begin(e,t,'dragon-windup',55,{angle:aim(e,p),x:c.x,y:c.y});return;}
   if(d>170)pursuit(e,p,speed*.55);else if(d<100)move(e,-dx,-dy,speed*.35);break;
  default:pursuit(e,p,speed);
 }
}
export function frontalMultiplier(e,shot){
 if(e.name!=='Knight'||!Number.isFinite(e.facing))return 1;
 const length=Math.hypot(shot.vx,shot.vy);if(!length)return 1;
 const dot=-(shot.vx*Math.cos(e.facing)+shot.vy*Math.sin(e.facing))/length;
 return dot>.5?.35:1;
}
export function inCircle(p,x,y,radius){
 const nx=Math.max(p.x,Math.min(x,p.x+p.width)),ny=Math.max(p.y,Math.min(y,p.y+p.height));
 return (nx-x)**2+(ny-y)**2<=radius**2;
}
export function stepHazards(game){
 const p=game.player,t=game.tick;
 game.hazards=game.hazards.filter(h=>{
  if(t>=h.until)return false;
  if(t>=h.activeAt&&inCircle(p,h.x,h.y,h.radius)){
   if(h.type==='web')p.webUntil=Math.max(p.webUntil||0,t+12);
   else if(!h.hit){h.hit=true;game.hurtPlayer(h.damage,'hazard');}
  }
  return true;
 });
 game.hostiles=game.hostiles.filter(s=>{
  s.x+=s.vx;s.y+=s.vy;s.age++;
  if(s.age>200||!game.visible({x:s.x-s.radius,y:s.y-s.radius,width:s.radius*2,height:s.radius*2},150))return false;
  if(inCircle(p,s.x,s.y,s.radius)){game.hurtPlayer(s.damage,'projectile');return false;}
  return true;
 });
}
