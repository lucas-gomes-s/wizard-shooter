// Original, cached Canvas artwork. No simulation state writes or gameplay RNG.
export const ART_SIZE=96;
export const FLOOR_SIZE=384;
export const actorNames=['Wizard','Spider','Goblin','Orc','Zombie','Knight','Vampire','Reaper','Demon','Dragon'];
const ink='#100e19',TAU=Math.PI*2;
export const palettes={
 crypt:{base:'#25252e',stone:['#30313b','#292a34','#35343e','#2b2b35'],mortar:'#1d1d26',edge:'#44434b',crack:'#1c1d26',accent:'#8173a6',light:'#bda0ed'},
 frost:{base:'#20323e',stone:['#2b414e','#243844','#344954','#293d49'],mortar:'#192a35',edge:'#45606c',crack:'#192d3d',accent:'#86c7e5',light:'#93d9ff'},
 forge:{base:'#352924',stone:['#42332b','#392e29','#49372c','#3c3029'],mortar:'#241d1c',edge:'#64483a',crack:'#281d1b',accent:'#cc7950',light:'#ffac74'}
};
export function hashCell(x,y,salt=0){let n=(Math.imul(x,73856093)^Math.imul(y,19349663)^Math.imul(salt+1,83492791))>>>0;n=Math.imul(n^(n>>>16),0x45d9f3b)>>>0;return (n^(n>>>16))>>>0}
export function tileOffset(value,size=FLOOR_SIZE){return -((value%size+size)%size)}
function poly(c,points,fill,stroke=ink,width=1.5){c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.fillStyle=fill;c.fill();if(stroke){c.strokeStyle=stroke;c.lineWidth=width;c.stroke()}}
function line(c,points,color,width=1.5){c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.strokeStyle=color;c.lineWidth=width;c.stroke()}
function oval(c,x,y,rx,ry,fill,stroke=ink,width=1.5){c.beginPath();c.ellipse(x,y,rx,ry,0,0,TAU);c.fillStyle=fill;c.fill();if(stroke){c.strokeStyle=stroke;c.lineWidth=width;c.stroke()}}
function rect(c,x,y,w,h,fill){c.fillStyle=fill;c.fillRect(x,y,w,h)}
function eyes(c,x,y,color,spread=5){oval(c,x-spread,y,2,1.4,color,null);oval(c,x+spread,y,2,1.4,color,null)}
function gem(c,x,y,r,color){poly(c,[[x,y-r],[x+r*.7,y],[x,y+r],[x-r*.7,y]],color,'#151323',1);line(c,[[x-r*.3,y],[x,y-r*.7]],'#ffffff99',1)}
function armor(c,fill,trim){poly(c,[[15,28],[23,23],[32,29],[41,23],[49,28],[46,46],[40,57],[24,57],[18,46]],fill);poly(c,[[23,30],[32,35],[41,30],[39,44],[32,49],[25,44]],trim);line(c,[[32,35],[32,48]],'#11131e',1.5);oval(c,18,31,7,5,trim);oval(c,46,31,7,5,trim)}
function legs(c,fill){poly(c,[[22,45],[31,45],[29,59],[19,59]],fill);poly(c,[[33,45],[42,45],[45,59],[35,59]],fill)}
function cloak(c,fill,highlight){poly(c,[[21,22],[43,22],[52,57],[33,53],[13,57]],fill);poly(c,[[24,28],[20,51],[30,48],[32,30]],highlight,null)}
export function paintActor(c,name,variant='crypt'){
 c.save();c.scale(ART_SIZE/64,ART_SIZE/64);c.lineJoin='round';c.lineCap='round';
 switch(name){
 case 'Wizard':
  cloak(c,'#553b83','#8064af');legs(c,'#211c35');poly(c,[[22,27],[42,27],[46,53],[32,56],[18,53]],'#695397');line(c,[[32,30],[32,53]],'#b8a0dd',2);rect(c,24,42,16,3,'#c6a273');gem(c,32,43,4,'#ead18e');
  oval(c,32,24,10,10,'#d6b394');oval(c,32,19,12,8,'#34274c');eyes(c,32,25,'#251d2d',3);
  poly(c,[[15,19],[24,15],[27,3],[38,6],[43,16],[49,21],[35,24],[19,23]],'#594078');line(c,[[26,16],[42,18]],'#d2b47d',3);gem(c,35,17,3,'#e2cfff');
  line(c,[[49,55],[51,13]],ink,5);line(c,[[49,55],[51,13]],'#9b7653',2.5);gem(c,51,11,8,'#c3a2ff');oval(c,47,36,4,4,'#d6b394');break;
 case 'Spider':
  for(const sign of [-1,1])for(let i=0;i<4;i++){const y=23+i*6;line(c,[[32+sign*9,y],[32+sign*(19+i%2*4),y-7],[32+sign*29,y+3]],ink,5);line(c,[[32+sign*9,y],[32+sign*(19+i%2*4),y-7],[32+sign*29,y+3]],'#7c697c',2.4)}
  oval(c,32,38,13,16,'#45364f');oval(c,32,23,10,9,'#6a526c');gem(c,32,40,7,'#b86b6b');eyes(c,32,20,'#ffb183',4);break;
 case 'Goblin':
  legs(c,'#4e473b');poly(c,[[20,29],[43,29],[45,47],[18,47]],'#786342');rect(c,21,42,23,4,'#3f302a');poly(c,[[22,16],[7,11],[13,28],[24,30]],'#879b57');poly(c,[[42,16],[57,11],[51,28],[40,30]],'#879b57');oval(c,32,22,14,12,'#91ad62');poly(c,[[30,21],[35,21],[33,29]],'#6b864c');eyes(c,32,21,'#ffda8a',6);line(c,[[25,30],[32,32],[38,30]],'#392e25',1.5);line(c,[[47,44],[57,23]],'#aa895d',3);poly(c,[[55,25],[53,10],[62,16]],'#c7c3aa');break;
 case 'Orc':
  legs(c,'#493730');armor(c,'#816455','#ba946d');oval(c,32,21,15,13,'#76965f');rect(c,17,12,30,6,'#485647');eyes(c,32,22,'#ffbd7a',6);poly(c,[[22,29],[25,21],[28,30]],'#e1d6ad');poly(c,[[36,30],[39,21],[42,29]],'#e1d6ad');line(c,[[49,54],[53,13]],'#9f7652',4);poly(c,[[51,11],[62,7],[61,26],[51,25]],'#b5b4b2');break;
 case 'Zombie':
  legs(c,'#484044');poly(c,[[19,29],[43,27],[45,48],[37,45],[30,51],[23,46],[17,49]],'#63576b');line(c,[[19,31],[5,37],[3,30]],'#8eaa85',7);line(c,[[43,31],[57,37],[60,30]],'#8eaa85',7);oval(c,32,19,12,13,'#91a78a');poly(c,[[21,13],[25,5],[36,6],[43,12],[34,13],[27,10]],'#4e514b');eyes(c,32,20,'#e7efb2',5);rect(c,28,27,9,3,'#514343');line(c,[[33,32],[29,41]],'#a98080',2);break;
 case 'Knight':
  legs(c,'#444959');armor(c,'#757d8e','#a5aabb');poly(c,[[20,13],[26,6],[38,6],[44,13],[43,27],[32,32],[21,27]],'#9aa4b4');rect(c,22,17,20,5,'#232733');eyes(c,32,19,'#efb96e',5);line(c,[[32,8],[32,15]],'#e0d7c1',2);poly(c,[[5,28],[22,25],[27,37],[20,53],[9,48]],'#66788d','#131722',2);gem(c,15,37,7,'#c9b380');line(c,[[48,52],[56,12]],'#d8d9e2',4);line(c,[[45,35],[56,38]],'#b79a6e',3);break;
 case 'Vampire':
  cloak(c,'#6f293f','#a33d55');legs(c,'#252231');poly(c,[[21,25],[32,32],[43,25],[42,51],[32,55],[22,51]],'#373044');poly(c,[[17,14],[26,28],[20,39],[10,24]],'#87364d');poly(c,[[47,14],[38,28],[44,39],[54,24]],'#87364d');oval(c,32,20,11,13,'#e0c8c8');poly(c,[[21,17],[20,9],[28,5],[37,5],[44,11],[43,17],[36,13],[32,17],[27,13]],'#262333');eyes(c,32,21,'#f06a7a',5);poly(c,[[27,28],[29,33],[31,28]],'#fff3e6',null);poly(c,[[34,28],[36,33],[38,28]],'#fff3e6',null);gem(c,32,37,4,'#e86b89');break;
 case 'Reaper':
  cloak(c,'#30334f','#505477');poly(c,[[10,52],[20,19],[26,8],[32,4],[40,10],[48,26],[53,53],[42,58],[33,54],[23,59]],'#3d405f');poly(c,[[23,19],[32,11],[41,19],[40,32],[32,39],[24,32]],'#171a2c');oval(c,32,25,8,9,'#b9c5c8');eyes(c,32,24,'#253342',3.5);rect(c,29,31,6,4,'#253342');line(c,[[48,58],[52,8]],'#9f9279',3);poly(c,[[51,8],[41,2],[27,2],[14,11],[31,8],[44,11],[50,15]],'#b8d5df');break;
 case 'Demon':
  legs(c,'#6b333d');poly(c,[[20,26],[5,10],[3,36],[15,32],[10,48],[27,39]],'#83374e');poly(c,[[44,26],[59,10],[61,36],[49,32],[54,48],[37,39]],'#83374e');armor(c,'#a74a45','#d97b50');oval(c,32,20,12,12,'#c2674e');poly(c,[[23,14],[17,2],[28,9]],'#e1c4a0');poly(c,[[41,14],[47,2],[36,9]],'#e1c4a0');eyes(c,32,20,'#fff0a2',5);gem(c,32,37,6,'#ffba6e');break;
 case 'Dragon':{
  const body=variant==='frost'?'#5898ba':variant==='forge'?'#b65b3d':'#92704b',wing=variant==='frost'?'#3a6986':variant==='forge'?'#783e38':'#634858',glow=palettes[variant]?.light||'#e0bd85';
  poly(c,[[23,28],[3,8],[1,37],[13,30],[6,51],[24,42]],wing);poly(c,[[41,28],[61,8],[63,37],[51,30],[58,51],[40,42]],wing);line(c,[[21,31],[4,11],[13,30]],body,2);line(c,[[43,31],[60,11],[51,30]],body,2);
  poly(c,[[30,41],[38,43],[40,52],[50,57],[40,62],[29,55],[27,48]],body);oval(c,32,39,13,17,body);poly(c,[[24,32],[32,28],[40,32],[38,46],[32,51],[26,46]],'#c6ae92');for(let i=0;i<3;i++)line(c,[[26,35+i*5],[38,35+i*5]],'#79635d',1);
  poly(c,[[20,16],[24,7],[32,10],[40,7],[44,16],[43,27],[32,34],[21,27]],body);poly(c,[[22,15],[16,2],[28,10]],'#e7d4ac');poly(c,[[42,15],[48,2],[36,10]],'#e7d4ac');eyes(c,32,19,glow,6);poly(c,[[25,24],[39,24],[37,29],[27,29]],'#30232d');gem(c,32,13,4,glow);break;}
 default:oval(c,32,32,23,23,'#a398b0');break;
 }c.restore();
}
export function paintFloor(c,id){
 const p=palettes[id]||palettes.crypt,cell=48;
 rect(c,0,0,FLOOR_SIZE,FLOOR_SIZE,p.mortar);
 for(let y=0;y<8;y++)for(let x=0;x<8;x++){
  const n=hashCell(x,y,17),px=x*cell,py=y*cell;
  rect(c,px+1,py+1,46,46,p.stone[n%4]);
  line(c,[[px+2,py+46],[px+2,py+2],[px+46,py+2]],p.edge,1);
  line(c,[[px+46,py+3],[px+46,py+46],[px+3,py+46]],p.crack,1);
  for(let i=0;i<12;i++){const h=hashCell(x,y,i);rect(c,px+4+h%39,py+4+(h>>>8)%39,1+(h>>>16)%3,1,(i%2?p.edge:p.crack)+'55')}
  if(n%3===0)line(c,[[px+5,py+11],[px+17,py+19],[px+14,py+24],[px+30,py+32],[px+42,py+35]],p.crack,1);
  if(n%7===0){
   if(id==='frost'){poly(c,[[px+7,py+36],[px+16,py+16],[px+20,py+32],[px+27,py+9],[px+35,py+35]],p.accent+'35',p.accent+'66',1)}
   else if(id==='forge'){rect(c,px+10,py+10,28,28,'#281e1c');for(let k=13;k<38;k+=6)line(c,[[px+k,py+11],[px+k,py+37]],'#795442',2);line(c,[[px+11,py+24],[px+37,py+24]],p.accent+'88',2)}
   else{oval(c,px+24,py+24,14,14,'#34313e',p.accent+'55',1);gem(c,px+24,py+24,8,p.accent+'55')}
  }
 }
}
export class DungeonArt{
 constructor(makeCanvas){this.makeCanvas=makeCanvas;this.actors=new Map();this.floors=new Map();}
 actor(name,variant='crypt'){const key=name+':'+(name==='Dragon'?variant:'crypt');if(!this.actors.has(key)){const canvas=this.makeCanvas(ART_SIZE,ART_SIZE);paintActor(canvas.getContext('2d'),name,variant);this.actors.set(key,canvas)}return this.actors.get(key)}
 floor(id){id=Object.hasOwn(palettes,id)?id:'crypt';if(!this.floors.has(id)){const canvas=this.makeCanvas(FLOOR_SIZE,FLOOR_SIZE);paintFloor(canvas.getContext('2d'),id);this.floors.set(id,canvas)}return this.floors.get(id)}
 drawFloor(c,id,camera,w,h){const tile=this.floor(id);for(let y=tileOffset(camera.y);y<h;y+=FLOOR_SIZE)for(let x=tileOffset(camera.x);x<w;x+=FLOOR_SIZE)c.drawImage(tile,x,y,FLOOR_SIZE,FLOOR_SIZE)}
 drawActor(c,name,x,y,w,h,{variant='crypt',tick=0,animate=false,flip=false}={}){
  const art=this.actor(name,variant);const bob=animate?Math.sin(tick*.18+x*.02)*.75:0;
  c.save();c.translate(x+w/2,y+h/2+bob);if(flip)c.scale(-1,1);c.drawImage(art,-w/2,-h/2,w,h);c.restore();
 }
}
export function drawSigil(c,x,y,r,color,tick,mode){
 c.save();c.translate(x,y);c.scale(1,.58);
 oval(c,0,0,r+3,r+3,color+'12',color+'55',1);oval(c,0,0,r-2,r-2,'#15101d22',color,1.2);
 if(mode!=='off'){const offset=mode==='full'?tick*.012:0;for(let i=0;i<6;i++){const a=i*TAU/6+offset;gem(c,Math.cos(a)*(r-2),Math.sin(a)*(r-2),2.8,color)}}
 c.restore();
}
export function drawTargetRing(c,x,y,w,h,color,kind){
 c.save();const cx=x+w/2,cy=y+h*.88;
 oval(c,cx,cy,w*.56,h*.23,color+'19',color,1.5);
 const size=kind==='boss'?6:4;for(const s of [-1,1])poly(c,[[cx+s*w*.58,cy],[cx+s*(w*.58+size),cy-size],[cx+s*(w*.58+size),cy+size]],color,null);
 c.restore();
}
export function drawLight(c,w,h,x,y,id,mode){
 if(mode!=='full')return;
 const p=palettes[id]||palettes.crypt,r=Math.max(w,h)*.75,gradient=c.createRadialGradient(x,y,20,x,y,r);
 gradient.addColorStop(0,p.light+'0d');gradient.addColorStop(.40,'#00000000');gradient.addColorStop(1,'#08061155');c.fillStyle=gradient;c.fillRect(0,0,w,h);
}
