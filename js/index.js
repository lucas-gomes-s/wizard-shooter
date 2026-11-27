import * as config from './data.js';
import { Game, FixedClock } from './simulation.js';

const canvas = document.getElementById('gameArea');
const ctx = canvas.getContext('2d');
const start = document.getElementById('startButton');
const W = 600, H = 600;
const game = new Game(config);
const clock = new FixedClock();
const keys = new Set();
const movement = ['KeyW','KeyA','KeyS','KeyD'];
const arrows = ['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'];
const allowed = new Set([...movement,...arrows,'KeyQ','Escape']);
let active = false, aimOrder = [], deathPhrase = '', paused = false;
const images = new Map();
const urls = new Set([
  './images/dungeonfloor.jpg','./images/wizard-hat.png','./images/heart.png',
  ...config.monsters.map(m=>m.imageSrc),
  ...config.potionInfo.map(p=>p.imageSrc),
  ...config.skills.map(s=>s.img)
]);
function preload(url) {
  return new Promise(resolve => {
    const image = new Image();
    image.onload = () => { images.set(url,image); resolve(); };
    image.onerror = () => { console.warn('Missing game asset:',url); resolve(); };
    image.src = url;
  });
}
function sprite(url,x,y,w,h,fallback='#aaa') {
  const image = images.get(url);
  if(image) ctx.drawImage(image,x,y,w,h);
  else {ctx.fillStyle=fallback;ctx.fillRect(x,y,w,h);}
}
function clearInput(){keys.clear();aimOrder=[];}
function resetTiming(){clock.reset();clearInput();}
start.disabled = true;
Promise.all([...urls].map(preload)).then(()=>{
  start.disabled=false; background();
});
start.addEventListener('click',()=>{
  game.reset(); resetTiming(); paused=false; deathPhrase=''; active=true;
  start.textContent='Restart Game';
  canvas.scrollIntoView({block:'center'});
  start.blur();
});
document.addEventListener('keydown',e=>{
  if(!active || !allowed.has(e.code) || e.altKey || e.ctrlKey || e.metaKey) return;
  if(e.target instanceof HTMLElement && ['INPUT','TEXTAREA','SELECT'].includes(e.target.tagName))return;
  e.preventDefault();
  if(e.code==='Escape' && !e.repeat && game.phase==='playing'){
    paused=!paused;resetTiming();return;
  }
  if(paused || game.phase==='over')return;
  if(game.phase==='upgrade'){
    if(e.repeat)return;
    if(e.code==='ArrowLeft')game.navigate(-1);
    if(e.code==='ArrowRight')game.navigate(1);
    if(e.code==='KeyQ'){game.choose();resetTiming();}
    return;
  }
  if(!keys.has(e.code) && arrows.includes(e.code))aimOrder.push(e.code);
  keys.add(e.code);
});
document.addEventListener('keyup',e=>{
  keys.delete(e.code);
  aimOrder=aimOrder.filter(k=>k!==e.code);
});
window.addEventListener('blur',()=>{resetTiming();if(active&&game.phase==='playing')paused=true;});
document.addEventListener('visibilitychange',()=>{resetTiming();if(document.hidden&&active&&game.phase==='playing')paused=true;});
const aimVectors={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
function input(){
  return {x:Number(keys.has('KeyD'))-Number(keys.has('KeyA')),y:Number(keys.has('KeyS'))-Number(keys.has('KeyW')),aim:aimVectors[aimOrder[aimOrder.length-1]]};
}
function background(){
  const c=game.camera;
  const x=-((c.x%W+W)%W), y=-((c.y%H+H)%H);
  ctx.fillStyle='#292929';ctx.fillRect(0,0,W,H);
  const floor=images.get('./images/dungeonfloor.jpg');
  if(floor)for(let iy=y;iy<H;iy+=H)for(let ix=x;ix<W;ix+=W)ctx.drawImage(floor,ix,iy,W,H);
}
function bar(x,y,w,h,fraction,color){
  const f=Math.max(0,Math.min(1,fraction));
  ctx.fillStyle='rgba(0,0,0,.65)';ctx.fillRect(x,y,w,h);
  ctx.fillStyle=color;ctx.fillRect(x,y,w*f,h);
  ctx.strokeStyle=color;ctx.lineWidth=1;ctx.strokeRect(x,y,w,h);
}
function text(value,x,y,size=16,color='white',align='center'){
  ctx.font=size+'px Arial';ctx.textAlign=align;ctx.fillStyle=color;ctx.fillText(value,x,y);
}
function timer(){return String(Math.floor(game.seconds/60)).padStart(2,'0')+':'+String(game.seconds%60).padStart(2,'0');}
function renderWorld(){
  background();
  const c=game.camera, p=game.player;
  for(const o of game.potions)if(game.visible(o,0))sprite(o.imageSrc,o.x-c.x,o.y-c.y,o.width,o.height,'#d44');
  for(const s of game.shots){ctx.fillStyle='white';ctx.fillRect(s.x-c.x,s.y-c.y,s.width,s.height);}
  for(const e of game.enemies)if(game.visible(e,0)){
    sprite(e.imageSrc,e.x-c.x,e.y-c.y,e.width,e.height,'#799653');
    if(keys.has('KeyQ'))bar(e.x-c.x,e.y-c.y-10,e.width,5,e.health/e.maxHealth,'red');
  }
  sprite('./images/wizard-hat.png',p.x-c.x,p.y-c.y,p.width,p.height,'#8c75c7');
  if(keys.has('KeyQ'))bar(p.x-c.x,p.y-c.y-10,p.width,5,p.health/p.maxHealth,'red');
  if(game.flash){ctx.fillStyle='rgba(255,0,0,.20)';ctx.fillRect(0,0,W,H);}
  ctx.fillStyle='rgba(0,0,0,.65)';ctx.fillRect(0,0,W,58);
  sprite('./images/heart.png',20,22,20,20,'red');
  bar(50,25,200,15,p.health/p.maxHealth,'red');
  text(timer(),300,40,20);
  text('Level',355,20,10);text(String(p.level),355,43,18);
  bar(380,25,200,15,p.level>=config.maxLevel?1:p.currentExp/p.expNeeded,'yellow');
}
function overlay(){ctx.fillStyle='rgba(0,0,0,.85)';ctx.fillRect(0,0,W,H);}
function renderUpgrade(){
  overlay();
  text('Level Up!',300,150,50,'#ff5555');
  text('Choose a Skill to improve:',300,200,25);
  text('Left / Right to select, Q to confirm',300,224,15);
  config.skills.forEach((s,i)=>{
    const x=50+i*130;
    ctx.fillStyle='#454545';ctx.fillRect(x,240,100,100);
    sprite(s.img,x+10,250,80,80);
    const maxed=game.player.skillLvl[i]>=s.maxLevel;
    if(maxed){ctx.fillStyle='rgba(0,0,0,.7)';ctx.fillRect(x,240,100,100);text('MAX',x+50,298,16);}
    if(i===game.selected){ctx.strokeStyle='#ff5555';ctx.lineWidth=4;ctx.strokeRect(x,240,100,100);}
  });
  const s=config.skills[game.selected];
  text(s.name,300,390,25);
  text('Current level: '+game.player.skillLvl[game.selected]+' / '+s.maxLevel,300,410,15);
  text(s.description1,300,439,18);
  text(s.description2,300,463,15);
}
function renderEnd(){
  if(!deathPhrase)deathPhrase=config.gameOverPhrases[Math.floor(Math.random()*config.gameOverPhrases.length)];
  overlay();text('Game Over',300,250,60,'#ff5555');
  text('You were overrun by monsters.',300,290,20);
  text('As the light fades from your eyes, you think:',300,320,17);
  ctx.font='16px Arial';
  let line='',y=350;
  for(const word of deathPhrase.split(' ')){
    if(ctx.measureText(line+' '+word).width>540){text(line,300,y,16);line=word;y+=20;}
    else line+=(line?' ':'')+word;
  }
  text(line,300,y,16);
  text('Survived '+timer()+'  |  Level '+game.player.level+'  |  Kills '+game.kills,300,430,17,'yellow');
  text('Click Restart Game to try again.',300,465,15);
}
function frame(now){
  if(active){
    if(game.phase==='playing' && !paused && !document.hidden){
      clock.advance(now,()=>game.step(input()));
      if(game.phase!=='playing')resetTiming();
    }
    renderWorld();
    if(game.phase==='upgrade')renderUpgrade();
    else if(game.phase==='over')renderEnd();
    else if(paused){overlay();text('Paused',300,280,45);text('Press Escape to resume',300,320,18);}
  }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
