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
 reset(){this.phase='playing';this.tick=0;this.kills=0;this.enemies=[];this.shots=[];this.potions=[];this.flash=0;this.events=[];this.selected=0;this.enemyTimers=this.config.monsters.map(()=>0);this.potionTimers=this.config.potionInfo.map(()=>0);this.player={x:280,y:280,width:40,height:40,maxSpeed:2,health:100,maxHealth:100,level:1,currentExp:0,expNeeded:this.config.levels[0],shotDmg:10,shotSpd:8,shotSize:5,shotCd:50,cooldown:50,skillLvl:this.config.skills.map(()=>0)}}
 emit(type,object,value=0){if(this.events.length<128)this.events.push({type,x:object.x+object.width/2,y:object.y+object.height/2,value})}
 get camera(){return {x:this.player.x+this.player.width/2-this.width/2,y:this.player.y+this.player.height/2-this.height/2}}
 get seconds(){return Math.floor(this.tick/50)}
 visible(o,margin=600){const c=this.camera;return o.x+o.width>=c.x-margin&&o.x<=c.x+this.width+margin&&o.y+o.height>=c.y-margin&&o.y<=c.y+this.height+margin}
 shoot(aim){const p=this.player;if(!aim||p.cooldown>0)return;const [dx,dy]=normalize(...aim);if(!dx&&!dy)return;this.shots.push({x:p.x+p.width/2-p.shotSize/2,y:p.y+p.height/2-p.shotSize/2,width:p.shotSize,height:p.shotSize,vx:dx*p.shotSpd,vy:dy*p.shotSpd,damage:p.shotDmg});p.cooldown=p.shotCd;this.emit('cast',p)}
 spawnEnemies(){const c=this.camera;this.config.monsters.forEach((m,i)=>{if(this.seconds<m.startMinute*60)return;if(++this.enemyTimers[i]<m.spawn)return;this.enemyTimers[i]=0;const side=Math.floor(this.rng()*4),v=this.rng();let x=c.x+v*this.width,y=c.y+v*this.height;if(side===0)y=c.y-m.height;else if(side===1)y=c.y+this.height;else if(side===2)x=c.x+this.width;else x=c.x-m.width;this.enemies.push({...m,x,y,cd:0})})}
 spawnPotions(){const c=this.camera;this.config.potionInfo.forEach((p,i)=>{if(this.seconds<p.startMinute*60)return;if(++this.potionTimers[i]<p.currentSpawn)return;this.potionTimers[i]=0;this.potions.push({x:c.x+this.rng()*(this.width-30),y:c.y+this.rng()*(this.height-30),width:30,height:30,imageSrc:p.imageSrc,recovery:p.recovery,fade:p.fade,age:0})})}
 levelUp(){const p=this.player;if(p.level>=this.config.maxLevel||p.currentExp<p.expNeeded)return; p.currentExp-=p.expNeeded;p.level++;p.expNeeded=p.level<this.config.maxLevel?this.config.levels[p.level-1]:Infinity;p.health=Math.min(p.maxHealth,p.health*1.3);const available=this.config.skills.findIndex((s,i)=>p.skillLvl[i]<s.maxLevel);if(available>=0){this.selected=available;this.phase='upgrade'}else if(p.level<this.config.maxLevel)this.levelUp()}
 navigate(direction){if(this.phase!=='upgrade')return;const n=this.config.skills.length;for(let i=1;i<=n;i++){const j=(this.selected+direction*i+n*2)%n;if(this.player.skillLvl[j]<this.config.skills[j].maxLevel){this.selected=j;return}}}
 choose(index=this.selected){if(this.phase!=='upgrade')return false;const p=this.player,s=this.config.skills[index];if(!s||p.skillLvl[index]>=s.maxLevel)return false;p[s.status]+=s.modifier;p.shotCd=Math.max(1,p.shotCd);p.skillLvl[index]++;this.phase='playing';this.levelUp();return true}
 step(input={}){if(this.phase!=='playing')return false;const p=this.player;this.events=[];this.tick++;this.flash=Math.max(0,this.flash-1);const [dx,dy]=normalize(input.x||0,input.y||0);p.x+=dx*p.maxSpeed;p.y+=dy*p.maxSpeed;p.cooldown=Math.max(0,p.cooldown-1);this.shoot(input.aim);
 for(const s of this.shots){s.x+=s.vx;s.y+=s.vy}
 const hash=new SpatialHash();for(const e of this.enemies){const x=p.x+p.width/2-e.x-e.width/2,y=p.y+p.height/2-e.y-e.height/2;const [nx,ny]=normalize(x,y);const speed=Math.min(e.maxSpeed,Math.hypot(x,y));e.x+=nx*speed;e.y+=ny*speed;hash.insert(e)}
 this.shots=this.shots.filter(s=>{if(!this.visible(s))return false;for(const e of hash.query(s)){if(e.health>0&&overlaps(e,s)){e.health-=s.damage;this.emit('hit',e,s.damage);return false}}return true});
 this.enemies=this.enemies.filter(e=>{if(e.health<=0){this.kills++;p.currentExp+=e.expGiven;this.emit('kill',e,e.expGiven);return false}return this.visible(e)});
 for(const e of this.enemies){if(e.cd>0)e.cd--;else if(overlaps(e,p)){const previous=p.health;p.health=Math.max(0,p.health-e.damage);this.emit('hurt',p,previous-p.health);e.cd=50;this.flash=4}}
 if(p.health<=0){this.phase='over';return false}
 this.potions=this.potions.filter(o=>{if(++o.age>=o.fade||!this.visible(o))return false;if(p.health<p.maxHealth&&overlaps(o,p)){const previous=p.health;p.health=Math.min(p.maxHealth,p.health+o.recovery*p.maxHealth);this.emit('heal',p,p.health-previous);return false}return true});
 this.spawnEnemies();this.spawnPotions();this.levelUp();return this.phase==='playing'}
}
