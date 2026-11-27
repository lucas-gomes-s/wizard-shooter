import {freshMagic,upgradeOffers,applyUpgrade,boltPattern,pierceCount,nearby,dominantSchool} from './magic.js';
// Pure simulation. Legacy balance uses 50 fixed ticks per second.
export const STEP_MS = 20;
export function normalize(x,y){const n=Math.hypot(x,y);return n?[x/n,y/n]:[0,0]}

export function overlaps(a,b){return a.x<=b.x+b.width&&a.x+a.width>=b.x&&a.y<=b.y+b.height&&a.y+a.height>=b.y}

export class SpatialHash{
 constructor(size=64){this.size=size;this.cells=new Map()}
 keys(o){const out=[];for(let y=Math.floor(o.y/this.size);y<=Math.floor((o.y+o.height)/this.size);y++)for(let x=Math.floor(o.x/this.size);x<=Math.floor((o.x+o.width)/this.size);x++)out.push(x+','+y);return out}
 insert(o){for(const k of this.keys(o)){if(!this.cells.has(k))this.cells.set(k,[]);this.cells.get(k).push(o)}}
 query(o){const found=new Set();for(const k of this.keys(o))for(const e of this.cells.get(k)||[])found.add(e);return found}
}

export class FixedClock{
 constructor(step=STEP_MS){this.step=step;this.last=null;this.accumulator=0}
 reset(){this.last=null;this.accumulator=0}
 advance(now,update){if(this.last===null){this.last=now;return 0}this.accumulator+=Math.max(0,Math.min(100,now-this.last));this.last=now;let count=0;while(this.accumulator>=this.step){this.accumulator-=this.step;count++;if(update()===false){this.accumulator=0;break}}return count}
}

export class Game{
 constructor(config,rng=Math.random){this.config=config;this.rng=rng;this.width=600;this.height=600;this.reset()}
 reset(){this.phase='playing';this.tick=0;this.kills=0;this.enemies=[];this.shots=[];this.potions=[];this.flash=0;this.events=[];this.offers=[];this.selected=0;this.deathQueue=[];this.enemyTimers=this.config.monsters.map(()=>0);this.potionTimers=this.config.potionInfo.map(()=>0);this.player={x:280,y:280,width:40,height:40,maxSpeed:2,health:100,maxHealth:100,level:1,currentExp:0,expNeeded:this.config.levels[0],shotDmg:10,shotSpd:8,shotSize:5,shotCd:50,cooldown:50,skillLvl:this.config.skills.map(()=>0),magic:freshMagic()}}
 emit(type,object,value=0,school=null,extra={}){if(this.events.length<128)this.events.push({type,x:object.x+object.width/2,y:object.y+object.height/2,value,school,...extra})}
 get camera(){return {x:this.player.x+this.player.width/2-this.width/2,y:this.player.y+this.player.height/2-this.height/2}}
 get seconds(){return Math.floor(this.tick/50)}
 visible(o,margin=600){const c=this.camera;return o.x+o.width>=c.x-margin&&o.x<=c.x+this.width+margin&&o.y+o.height>=c.y-margin&&o.y<=c.y+this.height+margin}
 shoot(aim){
  const p=this.player;if(!aim||p.cooldown>0)return;
  const [dx,dy]=normalize(...aim);if(!dx&&!dy)return;
  const school=dominantSchool(p.magic)?.id||null;
  for(const bolt of boltPattern(p,dx,dy)){
   if(this.shots.length>=720)break;
   this.shots.push({x:p.x+p.width/2-p.shotSize/2,y:p.y+p.height/2-p.shotSize/2,width:p.shotSize,height:p.shotSize,...bolt,school,remaining:pierceCount(p),hit:new Set(),age:0});
  }
  p.cooldown=p.shotCd;this.emit('cast',p,0,school);
 }
 damage(enemy,amount,school=null){
  if(enemy.health<=0||amount<=0)return;
  const dealt=amount*(enemy.curseUntil>this.tick?1.15:1);
  enemy.health-=dealt;this.emit('hit',enemy,Math.min(dealt,enemy.health+dealt),school);
  if(enemy.health<=0)this.deathQueue.push(enemy);
 }
 directHit(enemy,shot,hash){
  const p=this.player,m=p.magic,r=m.ranks,combos=m.synergies;
  const damage=shot.damage*(r.lightning&&this.rng()<.05*r.lightning?2:1);
  this.damage(enemy,damage,shot.school);
  if(r.fire){
   enemy.burnUntil=this.tick+100;enemy.burnDamage=shot.damage*(.15+.05*r.fire);
   if(!(enemy.burnNext>this.tick))enemy.burnNext=this.tick+25;
   if(r.fire>=3){const radius=r.fire>=5?65:45;this.emit('burst',enemy,radius,'fire');for(const other of nearby(hash,enemy,radius,new Set([enemy])))this.damage(other,shot.damage*.3,'fire')}
  }
  if(r.ice){
   enemy.slowUntil=this.tick+100;enemy.slowFactor=1-(.15+.1*r.ice);
   enemy.frostHits=(enemy.frostHits||0)+1;
   if(r.ice>=5&&enemy.frostHits%3===0)enemy.freezeUntil=this.tick+30;
  }
  if(r.necro>=3)enemy.curseUntil=this.tick+100;
  if(r.lightning){
   const storm=combos.includes('storm'),visited=new Set([enemy]);
   let origin=enemy;
   for(let i=0;i<1+Math.floor((r.lightning-1)/2)+Number(storm);i++){
    const target=nearby(hash,origin,100+10*r.lightning+(storm?30:0),visited)[0];if(!target)break;
    this.emit('chain',target,0,'lightning',{fromX:origin.x+origin.width/2,fromY:origin.y+origin.height/2});
    this.damage(target,shot.damage*(.35+.05*r.lightning),'lightning');visited.add(target);origin=target;
   }
  }
  if(combos.includes('steam')){
   this.emit('burst',enemy,70,'ice');
   for(const target of nearby(hash,enemy,70,new Set([enemy]))){
    this.damage(target,shot.damage*.35,'ice');
    target.slowUntil=Math.max(target.slowUntil||0,this.tick+100);
    target.slowFactor=Math.min(target.slowFactor||1,.5);
   }
  }
 }
 resolveDeaths(hash){
  const p=this.player,m=p.magic,r=m.ranks,processed=new Set();
  // Includes externally created dead entities as well as damage-generated deaths.
  for(const e of this.enemies)if(e.health<=0)this.deathQueue.push(e);
  for(const e of this.deathQueue){
   if(processed.has(e))continue;processed.add(e);
   this.kills++;p.currentExp+=e.expGiven;this.emit('kill',e,e.expGiven);
   if(r.necro&&p.health<p.maxHealth){const before=p.health;p.health=Math.min(p.maxHealth,p.health+.5+.5*r.necro);this.emit('heal',p,p.health-before,'necro')}
   if(r.necro>=5){this.emit('burst',e,65,'necro');for(const other of nearby(hash,e,65,new Set([e])))this.damage(other,p.shotDmg*.4,'necro')}
   if(m.synergies.includes('soulfire')&&e.burnUntil>=this.tick){this.emit('burst',e,60,'fire');for(const other of nearby(hash,e,60,new Set([e])))this.damage(other,p.shotDmg*.6,'fire')}
  }
  this.deathQueue=[];
  this.enemies=this.enemies.filter(e=>e.health>0&&this.visible(e));
 }
 spawnEnemies(){const c=this.camera;this.config.monsters.forEach((m,i)=>{if(this.seconds<m.startMinute*60)return;if(++this.enemyTimers[i]<m.spawn)return;this.enemyTimers[i]=0;const side=Math.floor(this.rng()*4),v=this.rng();let x=c.x+v*this.width,y=c.y+v*this.height;if(side===0)y=c.y-m.height;else if(side===1)y=c.y+this.height;else if(side===2)x=c.x+this.width;else x=c.x-m.width;this.enemies.push({...m,x,y,cd:0})})}
 spawnPotions(){const c=this.camera;this.config.potionInfo.forEach((p,i)=>{if(this.seconds<p.startMinute*60)return;if(++this.potionTimers[i]<p.currentSpawn)return;this.potionTimers[i]=0;this.potions.push({x:c.x+this.rng()*(this.width-30),y:c.y+this.rng()*(this.height-30),width:30,height:30,imageSrc:p.imageSrc,recovery:p.recovery,fade:p.fade,age:0})})}
 levelUp(){
  const p=this.player;
  if(p.level>=this.config.maxLevel||p.currentExp<p.expNeeded)return;
  p.currentExp-=p.expNeeded;p.level++;p.expNeeded=p.level<this.config.maxLevel?this.config.levels[p.level-1]:Infinity;
  p.health=Math.min(p.maxHealth,p.health*1.3);
  this.offers=upgradeOffers(p,this.config.skills,this.rng);this.selected=0;
  if(this.offers.length)this.phase='upgrade';else if(p.level<this.config.maxLevel)this.levelUp();
 }
 navigate(direction){if(this.phase!=='upgrade'||!this.offers.length)return;this.selected=(this.selected+direction+this.offers.length)%this.offers.length}
 choose(index=this.selected){
  if(this.phase!=='upgrade'||!this.offers[index]||!applyUpgrade(this.player,this.offers[index],this.config.skills,this.tick))return false;
  this.offers=[];this.phase='playing';this.levelUp();return true;
 }
 step(input={}){
  if(this.phase!=='playing')return false;
  const p=this.player,m=p.magic;this.events=[];this.deathQueue=[];this.tick++;this.flash=Math.max(0,this.flash-1);
  if(m.ranks.arcane>=2&&!m.shieldReady&&this.tick>=m.shieldUntil)m.shieldReady=true;
  const [dx,dy]=normalize(input.x||0,input.y||0);p.x+=dx*p.maxSpeed;p.y+=dy*p.maxSpeed;p.cooldown=Math.max(0,p.cooldown-1);this.shoot(input.aim);
  for(const s of this.shots){s.x+=s.vx;s.y+=s.vy;s.age=(s.age||0)+1}
  const hash=new SpatialHash();
  for(const e of this.enemies){
   if(e.health<=0)continue;
   if(e.burnUntil>=this.tick&&e.burnNext<=this.tick){this.damage(e,e.burnDamage,'fire');e.burnNext+=25;}
   if(e.health<=0)continue;
   const x=p.x+p.width/2-e.x-e.width/2,y=p.y+p.height/2-e.y-e.height/2;
   const [nx,ny]=normalize(x,y),factor=e.freezeUntil>this.tick?0:e.slowUntil>this.tick?e.slowFactor:1;
   const speed=Math.min(e.maxSpeed*factor,Math.hypot(x,y));e.x+=nx*speed;e.y+=ny*speed;hash.insert(e);
  }
  this.shots=this.shots.filter(s=>{
   if(!this.visible(s)||s.age>240)return false;
   s.hit??=new Set();s.remaining??=1;
   for(const e of hash.query(s))if(e.health>0&&!s.hit.has(e)&&overlaps(e,s)){
    s.hit.add(e);this.directHit(e,s,hash);if(--s.remaining<=0)return false;
   }
   return true;
  });
  this.resolveDeaths(hash);
  for(const e of this.enemies){
   if(e.cd>0)e.cd--;
   else if(overlaps(e,p)){
    e.cd=50;
    if(m.ranks.arcane>=2&&m.shieldReady){m.shieldReady=false;m.shieldUntil=this.tick+(m.ranks.arcane>=4?500:750);this.emit('shield',p,0,'arcane');continue}
    const previous=p.health;p.health=Math.max(0,p.health-e.damage);this.emit('hurt',p,previous-p.health);this.flash=4;
   }
  }
  if(p.health<=0){this.phase='over';return false}
  this.potions=this.potions.filter(o=>{if(++o.age>=o.fade||!this.visible(o))return false;if(p.health<p.maxHealth&&overlaps(o,p)){const previous=p.health;p.health=Math.min(p.maxHealth,p.health+o.recovery*p.maxHealth);this.emit('heal',p,p.health-previous);return false}return true});
  this.spawnEnemies();this.spawnPotions();this.levelUp();return this.phase==='playing';
 }
}
