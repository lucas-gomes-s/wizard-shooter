// Presentation only. Geometry is in world units; visual randomness never uses game.rng.
const TAU=Math.PI*2;
export const PALETTE={fire:'#ff7537',ice:'#76ddff',lightning:'#ffe86c',necro:'#69f3a2',arcane:'#c49aff',neutral:'#f3e8ff',steam:'#d8f6ff',soulfire:'#a8ff92',plasma:'#ffb34f',starfall:'#ff8fc8',thunderfrost:'#a2e7ff',gravefrost:'#8df2d8',mirror:'#c4e9ff',reaping:'#a2ff8b',soulward:'#b4f6c7',hostile:'#ff6544'};
export const FX_LIMITS={off:0,reduced:100,full:320};
const clamp=x=>Math.min(1,Math.max(0,x));
const polar=(x,y,r,a)=>[x+Math.cos(a)*r,y+Math.sin(a)*r];
export function webGeometry(radius,spokes=8,rings=4){
 const rays=Array.from({length:spokes},(_,i)=>polar(0,0,radius,i*TAU/spokes));
 const loops=Array.from({length:rings},(_,j)=>rays.map(([x,y])=>[x*(j+1)/rings,y*(j+1)/rings]));
 return {rays,loops};
}
export function boltGeometry(x1,y1,x2,y2,seed=0,segments=7){
 const dx=x2-x1,dy=y2-y1,length=Math.hypot(dx,dy)||1;
 const amplitude=Math.min(12,length*.12),points=[[x1,y1]];
 for(let i=1;i<segments;i++){const t=i/segments,jitter=Math.sin(seed*1.7+i*7.3)*amplitude;points.push([x1+dx*t-dy/length*jitter,y1+dy*t+dx/length*jitter])}
 points.push([x2,y2]);return points;
}
function path(ctx,points,close=false){ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));if(close)ctx.closePath()}
function ring(ctx,x,y,r,color,width=2,fill=null){ctx.beginPath();ctx.arc(x,y,Math.max(.1,r),0,TAU);if(fill){ctx.fillStyle=fill;ctx.fill()}ctx.strokeStyle=color;ctx.lineWidth=width;ctx.stroke()}
function glow(ctx,x,y,r,color){const g=ctx.createRadialGradient(x,y,0,x,y,r);g.addColorStop(0,color+'99');g.addColorStop(1,color+'00');ctx.fillStyle=g;ctx.fillRect(x-r,y-r,r*2,r*2)}
function line(ctx,points,color,width=2){path(ctx,points);ctx.strokeStyle=color;ctx.lineWidth=width;ctx.stroke()}
function label(ctx,text,x,y,color='#fff1c9'){ctx.font='bold 11px system-ui';ctx.textAlign='center';ctx.textBaseline='middle';ctx.lineWidth=3;ctx.strokeStyle='#151019';ctx.strokeText(text,x,y);ctx.fillStyle=color;ctx.fillText(text,x,y)}
function crystal(ctx,x,y,r,angle=0){path(ctx,[polar(x,y,r,angle),polar(x,y,r*.48,angle+Math.PI/2),polar(x,y,r,angle+Math.PI),polar(x,y,r*.48,angle-Math.PI/2)],true);ctx.fillStyle='#b5f4ffbb';ctx.fill();ctx.strokeStyle='#ecfcff';ctx.lineWidth=1;ctx.stroke()}
function rune(ctx,x,y,r,t,color){ring(ctx,x,y,r,color,1.5);ring(ctx,x,y,r*.77,color+'88',1);for(let i=0;i<6;i++){const a=t+i*TAU/6;line(ctx,[polar(x,y,r*.77,a),polar(x,y,r*1.1,a)],color,2)}}
export function drawWeb(ctx,x,y,radius,active,tick=0,mode='full'){
 ctx.save();ctx.translate(x,y);const {rays,loops}=webGeometry(radius);
 ctx.lineJoin='round';ring(ctx,0,0,radius,active?'#dbe5ed':'#ffbe80',active?2:2.5,active?'#b8d6e033':'#ffb37718');
 if(!active)ctx.setLineDash([5,5]);
 ctx.strokeStyle=active?'#e6f5ffcc':'#ffd5a399';ctx.lineWidth=active?1.5:1;
 for(const end of rays){path(ctx,[[0,0],end]);ctx.stroke()}
 for(const loop of loops){path(ctx,loop,true);ctx.stroke()}
 ctx.setLineDash([]);
 if(active&&mode==='full'){ring(ctx,0,0,radius*.8,'#e8f9ff66',1.5);for(let i=0;i<8;i++){const a=i*TAU/8;const [px,py]=polar(0,0,radius*.93,a);ring(ctx,px,py,2.2,'#e4f2ff',1,'#e4f2ff')}}
 if(!active)label(ctx,'WEB INCOMING',0,-radius-10,'#ffd1a1');
 ctx.restore();
}
export function drawHazard(ctx,h,c,tick,mode){
 const x=h.x-c.x,y=h.y-c.y,active=tick>=h.activeAt,r=h.radius;
 if(h.type==='web'){drawWeb(ctx,x,y,r,active,tick,mode);return}
 if(h.type==='rubble'){ctx.save();ring(ctx,x,y,r,active?'#e7a26c':'#ffdb9a',2.5,active?'#a873514f':'#ffbd3222');if(!active){ring(ctx,x,y,r*clamp(1-(h.activeAt-tick)/55),'#ffe3b0',2);label(ctx,'RUBBLE',x,y,'#ffdfae')}else{for(let i=0;i<5;i++){const a=i*2.4,[px,py]=polar(x,y,r*.55,a);path(ctx,[[px-5,py+4],[px-2,py-5],[px+5,py-3],[px+7,py+4]],true);ctx.fillStyle='#d5aa83';ctx.fill();ctx.strokeStyle='#76503f';ctx.stroke()}}ctx.restore();return}
 ctx.save();const color=active?'#ff7042':'#ffca73';
 if(active&&mode==='full')glow(ctx,x,y,r,color);
 ring(ctx,x,y,r,color,2.5,active?'#f14f254c':'#ff9d251a');
 if(!active){const progress=clamp(1-(h.activeAt-tick)/35);ring(ctx,x,y,r*progress,'#ffe1a1',2);label(ctx,'FLAME',x,y,'#ffdc9c')}
 else {for(let i=0;i<9;i++){const a=i*2.4,dist=r*(.22+(i%3)*.23),[px,py]=polar(x,y,dist,a),height=mode==='full'?8+4*Math.sin(tick*.23+i):8;path(ctx,[[px-4,py+3],[px-1,py-height*.65],[px+2,py-height],[px+5,py+3]],true);ctx.fillStyle=i%2?'#ff9c42':'#ffe394';ctx.fill()}}
 ctx.restore();
}
export function drawEnemyWarning(ctx,e,c,tick,mode){
 const a=e.action;if(!a||a.kind==='recover')return;
 const x=e.x+e.width/2-c.x,y=e.y+e.height/2-c.y,color='#ffae70';
 ctx.save();ctx.lineJoin='round';
 if(a.kind==='orc-windup'||a.kind==='charge'){
  const dx=Math.cos(a.angle),dy=Math.sin(a.angle),length=a.kind==='charge'?Math.max(0,a.until-tick+1)*e.maxSpeed*2.1:22*e.maxSpeed*2.1,w=e.width/2;
  path(ctx,[[x-dy*w,y+dx*w],[x+dx*length-dy*w,y+dy*length+dx*w],[x+dx*length+dy*w,y+dy*length-dx*w],[x+dy*w,y-dx*w]],true);ctx.fillStyle=a.kind==='charge'?'#f76a343b':'#f76a342b';ctx.fill();ctx.strokeStyle=color;ctx.lineWidth=2;ctx.stroke();
  for(let n=20;n<length;n+=25){const px=x+dx*n,py=y+dy*n;line(ctx,[[px-dx*7-dy*9,py-dy*7+dx*9],[px+dx*6,py+dy*6],[px-dx*7+dy*9,py-dy*7-dx*9]],color,2)}
  if(a.kind==='orc-windup')label(ctx,'CHARGE',x,y-e.height/2-13);
 }else if(a.kind==='reaper-windup'){
  const tx=a.x-c.x,ty=a.y-c.y,r=e.width/2+8;ring(ctx,tx,ty,r,'#dd9bff',3,'#32143b99');
  rune(ctx,tx,ty,r*.8,mode==='full'?tick*.04:0,'#e4a8ff');
  ctx.setLineDash([6,6]);line(ctx,[[x,y],[tx,ty]],'#c48be9',1.5);ctx.setLineDash([]);
  ring(ctx,x,y,e.width*.65,'#a882cc',2);label(ctx,'TELEPORT',tx,ty-r-10,'#eccaff');
 }else if(a.kind==='demon-windup'||a.kind==='dragon-windup'){
  const dragon=a.kind==='dragon-windup';rune(ctx,x,y,e.width*.7,mode==='full'?tick*.05:0,color);
  const angles=dragon&&e.bossPhase>=2?Array.from({length:e.bossPhase===3?12:8},(_,i)=>a.angle+i*TAU/(e.bossPhase===3?12:8)):dragon?[-.44,-.22,0,.22,.44].map(i=>a.angle+i):[-.23,0,.23].map(i=>a.angle+i);
  if(!(dragon&&e.bossPhase>=2)){const spread=dragon?.46:.25;ctx.beginPath();ctx.moveTo(x,y);ctx.arc(x,y,240,a.angle-spread,a.angle+spread);ctx.closePath();ctx.fillStyle='#f96e3222';ctx.fill();ctx.strokeStyle=color;ctx.lineWidth=2;ctx.stroke()}
  for(const angle of angles){line(ctx,[[x,y],polar(x,y,dragon?180:240,angle)],'#ffb575aa',2)}
  label(ctx,dragon?'DRAGON BREATH':'VOLLEY',x,y-e.height*.65-12);
 }
 ctx.restore();
}
export function drawEnemyStatus(ctx,e,c,tick,mode){
 const x=e.x+e.width/2-c.x,y=e.y+e.height/2-c.y,r=Math.max(e.width,e.height)/2;
 const burn=e.burnUntil>=tick,slow=e.slowUntil>tick,freeze=e.freezeUntil>tick,curse=e.curseUntil>tick;
 ctx.save();
 if(burn){ring(ctx,x,y+r*.6,r*.92,'#ff8b44',1.5,'#ff6c2629');for(let i=0;i<(mode==='full'?5:3);i++){const px=x-r*.7+i*r*1.4/(mode==='full'?4:2),base=y+r*.75,h=r*(.7+.24*Math.sin(i*3+(mode==='full'?tick*.19:0)));path(ctx,[[px-3,base],[px-4,base-h*.4],[px+1,base-h],[px+4,base-h*.4],[px+3,base]],true);ctx.fillStyle=i%2?'#ffcd60':'#ff8038';ctx.fill()}}
 if(slow||freeze){ring(ctx,x,y, r+3,freeze?'#e0faff':'#70dcff',freeze?3:1.7,freeze?'#84dbff44':null);const count=freeze?6:3;for(let i=0;i<count;i++){const a=i*TAU/count+.35,[px,py]=polar(x,y,r+2,a);crystal(ctx,px,py,freeze?7:4,a)}}
 if(curse){const cy=y-r-8;ring(ctx,x,cy,7,'#8af3ad',1.5,'#1c392d');path(ctx,[[x,cy-4],[x+4,cy],[x,cy+4],[x-4,cy]],true);ctx.fillStyle='#a1ffc1';ctx.fill()}
 if(e.name==='Knight'&&Number.isFinite(e.facing)){ctx.beginPath();ctx.arc(x,y,r+5,e.facing-Math.PI/3,e.facing+Math.PI/3);ctx.strokeStyle='#33465b';ctx.lineWidth=8;ctx.stroke();ctx.strokeStyle='#d8eaff';ctx.lineWidth=3;ctx.stroke()}
 if(e.name==='Zombie'&&e.health<e.maxHealth*.5)ring(ctx,x,y+r*.7,r,'#ff625e',1.5);
 if(e.boss&&e.bossPhase>=2){ring(ctx,x,y,r+8,e.bossPhase===3?'#ff6556':'#ffba65',3)}
 ctx.restore();
}
export function drawShield(ctx,x,y,tick,mode){
 ctx.save();const r=28;if(mode==='full')glow(ctx,x,y,r+10,PALETTE.arcane);
 ring(ctx,x,y,r,'#cba7ff',2,'#aa7bff22');ring(ctx,x,y,r-4,'#efe0ff77',1);
 const a=mode==='full'?tick*.035:0;for(let i=0;i<6;i++){const [px,py]=polar(x,y,r,a+i*TAU/6);crystal(ctx,px,py,3,a+i*TAU/6)}
 ctx.restore();
}
export function drawProjectile(ctx,s,c,tick,mode,hostile=false){
 const x=s.x-c.x+(hostile?0:s.width/2),y=s.y-c.y+(hostile?0:s.height/2),r=hostile?s.radius:Math.max(2.5,s.width/2),color=hostile?PALETTE.hostile:(PALETTE[s.star?'starfall':s.school]||PALETTE.neutral);
 const speed=Math.hypot(s.vx,s.vy)||1,dx=s.vx/speed,dy=s.vy/speed;
 ctx.save();ctx.lineCap='round';
 if(mode!=='off'){
  const length=hostile?18:s.school==='fire'?25:18;
  if(s.school==='lightning'&&!hostile)line(ctx,boltGeometry(x-dx*length,y-dy*length,x,y,tick,5),color,2.5);
  else {line(ctx,[[x-dx*length,y-dy*length],[x,y]],color+'55',r*2.6);line(ctx,[[x-dx*length*.7,y-dy*length*.7],[x,y]],color,Math.max(2,r))}
  if(mode==='full')ring(ctx,x,y,r+3,color+'44',2,color+'22');
 }
 if(s.school==='ice'&&!hostile)crystal(ctx,x,y,r+2,Math.atan2(dy,dx));
 else if(s.school==='arcane'&&!hostile){path(ctx,[polar(x,y,r+2,0),polar(x,y,r+2,Math.PI/2),polar(x,y,r+2,Math.PI),polar(x,y,r+2,3*Math.PI/2)],true);ctx.fillStyle=color;ctx.fill();ctx.strokeStyle='#fff0ff';ctx.lineWidth=1;ctx.stroke()}
 else ring(ctx,x,y,r,hostile?'#ffedab':'#fff2da',1.1,color);
 ctx.restore();
}
export class CombatFX{
 constructor(mode='full',rng=Math.random){this.mode=mode;this.rng=rng;this.items=[]}
 setMode(mode){if(!Object.hasOwn(FX_LIMITS,mode))return;this.mode=mode;this.clear()}
 clear(){this.items=[]}
 add(item){const limit=FX_LIMITS[this.mode]??0;if(!limit)return;if(this.items.length>=limit){if(!item.priority)return;const index=this.items.findIndex(q=>!q.priority);if(index<0)return;this.items.splice(index,1)}this.items.push({...item,max:item.life})}
 advance(){for(const q of this.items){q.life--;q.x+=q.vx||0;q.y+=q.vy||0}this.items=this.items.filter(q=>q.life>0)}
 collect(events){
  if(this.mode==='off')return;
  for(const e of events){
   const visualSchool=e.visualSchool||e.school;
   const color=PALETTE[visualSchool]||({hurt:'#ff626b',kill:'#e5c48b',heal:'#8cffae',block:'#d9eaff',teleport:'#cf90ff',phase:'#ffb065',drain:'#f06185'}[e.type])||PALETTE.neutral;
   if(['burst','chain','shield','freeze','block','teleport','phase','drain','soul','crit','cast','victory'].includes(e.type)){
    this.add({...e,school:visualSchool,color,life:e.type==='phase'?40:e.type==='soul'?24:e.type==='burst'?22:16,priority:!['cast','crit'].includes(e.type)});
   }
   if(['hit','heal','hurt','block','crit'].includes(e.type))this.add({...e,type:'label',color,life:28,vy:-.75,label:e.type==='block'?'BLOCK':e.type==='crit'?'CRIT':(e.type==='heal'?'+':'−')+Math.ceil(e.value)});
   if(['hit','kill','burst','freeze','cast','teleport','block'].includes(e.type)){
    const n=this.mode==='full'?(e.type==='kill'?12:e.type==='burst'?10:5):2;
    for(let i=0;i<n;i++){const a=this.rng()*TAU,speed=1+this.rng()*2.7;this.add({type:'spark',x:e.x,y:e.y,vx:Math.cos(a)*speed,vy:Math.sin(a)*speed,color,life:12+Math.floor(this.rng()*10),school:visualSchool})}
   }
  }
 }
 draw(ctx,c,p,tick){
  for(const q of this.items){const x=q.x-c.x,y=q.y-c.y,f=q.life/q.max,progress=1-f;ctx.save();ctx.globalAlpha=clamp(f);ctx.lineCap='round';
   if(q.type==='chain'||q.type==='drain'){const points=boltGeometry(q.fromX-c.x,q.fromY-c.y,x,y,tick+q.max, q.type==='chain'?8:4);line(ctx,points,q.color+'88',7);line(ctx,points,q.color,3);line(ctx,points,'#fff4d7',1)}
   else if(q.type==='soul'){const tx=p.x+p.width/2-c.x,ty=p.y+p.height/2-c.y,sx=x+(tx-x)*progress,sy=y+(ty-y)*progress;line(ctx,[[x,y],[sx,sy]],q.color+'66',2);ring(ctx,sx,sy,4,q.color,1,'#dcffe2')}
   else if(q.type==='burst'){const r=Math.max(1,q.value*progress);ring(ctx,x,y,r,q.color,4,q.color+'33');ring(ctx,x,y,r*.65,'#fff4d9',1.5);if(q.school==='steam'){for(let i=0;i<6;i++){const [px,py]=polar(x,y,r*.6,i*TAU/6);ring(ctx,px,py,r*.32,'#e1f9ff77',1,'#e1f9ff44')}}}
   else if(q.type==='label'){label(ctx,q.label,x,y-12,q.color)}
   else if(q.type==='spark'){if(q.school==='ice')crystal(ctx,x,y,3,tick*.1);else line(ctx,[[x-q.vx*2,y-q.vy*2],[x,y]],q.color,2)}
   else {const r=(q.type==='phase'?90:q.type==='victory'?120:q.type==='shield'?35:25)*progress+4;ring(ctx,x,y,r,q.color,3,q.color+'22');if(q.type==='phase')label(ctx,'PHASE '+q.value,x,y-r-10,q.color);if(q.type==='freeze')for(let i=0;i<6;i++){const [px,py]=polar(x,y,r,i*TAU/6);crystal(ctx,px,py,6,i*TAU/6)}}
   ctx.restore();
  }
 }
}
