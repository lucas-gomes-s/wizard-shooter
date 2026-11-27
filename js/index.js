import * as config from './data.js';
import { Game, FixedClock } from './simulation.js';
import { viewportFor, fitViewport, formatTime, skillPreview } from './presentation.js';

const $=id=>document.getElementById(id);
const canvas=$('gameArea'), ctx=canvas.getContext('2d'), arena=$('arena');
const game=new Game(config), clock=new FixedClock();
const keys=new Set(), arrows=['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'];
const aimVectors={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
const allowed=new Set(['KeyW','KeyA','KeyS','KeyD','KeyQ','Escape','Enter',...arrows]);
const panels={home:$('homePanel'),pause:$('pausePanel'),confirm:$('confirmPanel'),upgrade:$('upgradePanel'),over:$('resultPanel')};
let screen='home',ready=false,aimOrder=[],confirmAction=null,dirty=true,particles=[],lastHud='',lastUpgrade=-1;
let effects=!matchMedia('(prefers-reduced-motion: reduce)').matches;
$('effectsToggle').checked=effects;
$('effectsToggle').addEventListener('change',()=>{effects=$('effectsToggle').checked;particles=[];dirty=true;});
const images=new Map();
const urls=new Set(['./images/dungeonfloor.jpg','./images/wizard-hat.png',...config.monsters.map(m=>m.imageSrc),...config.potionInfo.map(p=>p.imageSrc),...config.skills.map(s=>s.img)]);
function preload(url){return new Promise(resolve=>{
  const image=new Image();image.onload=()=>{images.set(url,image);resolve(true)};
  image.onerror=()=>{console.warn('Missing game asset:',url);resolve(false)};image.src=url;
});}
function sprite(url,x,y,w,h,fallback='#aaa'){const image=images.get(url);if(image)ctx.drawImage(image,x,y,w,h);else{ctx.fillStyle=fallback;ctx.fillRect(x,y,w,h)}}
let surface={width:600,height:600,dpr:1};
function resize(){
  const w=Math.max(1,arena.clientWidth),h=Math.max(1,arena.clientHeight),dpr=Math.min(2,window.devicePixelRatio||1);
  if(w===surface.width&&h===surface.height&&dpr===surface.dpr&&canvas.width===Math.round(w*dpr)&&canvas.height===Math.round(h*dpr))return;
  surface={width:w,height:h,dpr};canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);
  if(screen==='home')Object.assign(game,viewportFor(w,h));
  dirty=true;
}
new ResizeObserver(resize).observe(arena);window.addEventListener('resize',resize);resize();
function clearInput(){keys.clear();aimOrder=[];clock.reset();}
function focus(el){el.focus({preventScroll:true});}
function setScreen(next){
  screen=next;clearInput();dirty=true;
  for(const [name,panel] of Object.entries(panels))panel.hidden=name!==next;
  $('overlay').hidden=next==='play';
  $('pauseButton').disabled=!['play','pause'].includes(next);
  $('pauseButton').firstChild.textContent=next==='pause'?'Resume ':'Pause ';
  if(next==='play')focus(canvas);
  else if(next==='home'&&ready)focus($('startButton'));
  else if(next==='pause')focus($('resumeButton'));
  else if(next==='confirm')focus($('cancelButton'));
  else if(next==='upgrade'){lastUpgrade=-1;buildUpgrades();}
  else if(next==='over'){showResults();focus($('retryButton'));}
}
function startRun(){
  if(!ready)return;
  Object.assign(game,viewportFor(surface.width,surface.height));game.reset();
  particles=[];lastHud='';setScreen('play');
}
function home(){game.reset();particles=[];Object.assign(game,viewportFor(surface.width,surface.height));setScreen('home');}
function pause(){if(screen==='play')setScreen('pause');}
function resume(){if(screen==='pause')setScreen('play');}
function ask(action){confirmAction=action;setScreen('confirm');}
$('startButton').addEventListener('click',startRun);
$('resumeButton').addEventListener('click',resume);
$('pauseButton').addEventListener('click',()=>screen==='pause'?resume():pause());
$('restartButton').addEventListener('click',()=>ask(startRun));
$('quitButton').addEventListener('click',()=>ask(home));
$('confirmButton').addEventListener('click',()=>{const action=confirmAction;confirmAction=null;action?.()});
$('cancelButton').addEventListener('click',()=>{confirmAction=null;setScreen('pause')});
$('retryButton').addEventListener('click',startRun);
$('titleButton').addEventListener('click',home);
if(document.fullscreenEnabled&&$('gameShell').requestFullscreen){
  $('fullscreenButton').hidden=false;
  $('fullscreenButton').addEventListener('click',async()=>{
    try{if(document.fullscreenElement)await document.exitFullscreen();else await $('gameShell').requestFullscreen();}
    catch(error){console.warn('Fullscreen unavailable',error);}
  });
  document.addEventListener('fullscreenchange',()=>{$('fullscreenButton').textContent=document.fullscreenElement?'Exit full screen':'Full screen';resize();});
}
Promise.all([...urls].map(preload)).then(results=>{
  ready=true;$('startButton').disabled=false;$('startButton').textContent='Enter the dungeon';
  const missing=results.filter(x=>!x).length;
  $('assetStatus').textContent=missing?missing+' asset(s) unavailable; fallback graphics enabled.':'No time limit. Survive as long as you can.';
  dirty=true;
});
function choose(index=game.selected){
  if(screen!=='upgrade'||!game.choose(index))return;
  if(game.phase==='upgrade')setScreen('upgrade');else setScreen('play');
}
document.addEventListener('keydown',e=>{
  if(!allowed.has(e.code)||e.altKey||e.ctrlKey||e.metaKey)return;
  if(screen==='home'||screen==='over')return;
  if(e.code==='Escape'&&!e.repeat){
    if(screen==='play'){e.preventDefault();pause();}
    else if(screen==='pause'){e.preventDefault();resume();}
    else if(screen==='confirm'){e.preventDefault();confirmAction=null;setScreen('pause');}
    return;
  }
  if(screen==='upgrade'){
    if(!['ArrowLeft','ArrowRight','KeyQ','Enter'].includes(e.code))return;
    if(e.repeat){e.preventDefault();return;}
    if(e.code==='Enter'&&e.target instanceof HTMLButtonElement&&!e.target.classList.contains('upgrade-card'))return;
    e.preventDefault();
    if(e.code==='ArrowLeft'||e.code==='ArrowRight'){game.navigate(e.code==='ArrowLeft'?-1:1);updateSelection(true);}
    else if(e.code==='Enter'&&e.target instanceof HTMLButtonElement&&e.target.classList.contains('upgrade-card'))choose(Number(e.target.dataset.index));
    else choose();
    return;
  }
  if(screen!=='play'||['Escape','Enter'].includes(e.code))return;
  if(e.target instanceof HTMLInputElement)return;
  e.preventDefault();
  if(!keys.has(e.code)&&arrows.includes(e.code))aimOrder.push(e.code);
  keys.add(e.code);
});
document.addEventListener('keyup',e=>{keys.delete(e.code);aimOrder=aimOrder.filter(k=>k!==e.code)});
window.addEventListener('blur',()=>{clearInput();pause()});
document.addEventListener('visibilitychange',()=>{clearInput();if(document.hidden)pause()});
function input(){return{x:Number(keys.has('KeyD'))-Number(keys.has('KeyA')),y:Number(keys.has('KeyS'))-Number(keys.has('KeyW')),aim:aimVectors[aimOrder[aimOrder.length-1]]}}
function buildUpgrades(){
  const root=$('upgradeCards');root.replaceChildren();$('upgradeLevel').textContent='Level '+game.player.level+' reached';
  config.skills.forEach((s,i)=>{
    const rank=game.player.skillLvl[i],button=document.createElement('button');
    button.type='button';button.className='upgrade-card';button.dataset.index=i;button.disabled=rank>=s.maxLevel;
    const image=document.createElement('img');image.src=s.img;image.alt='';button.append(image);
    for(const [name,value] of [['skill-title',s.name],['skill-effect',s.description2],['skill-value',button.disabled?'Maximum rank':skillPreview(game.player,s)],['skill-flavor',s.description1],['skill-rank','Rank '+rank+' / '+s.maxLevel]]){
      const span=document.createElement('span');span.className=name;span.textContent=value;button.append(span);
    }
    button.addEventListener('click',()=>choose(i));
    button.addEventListener('focus',()=>{if(!button.disabled){game.selected=i;updateSelection(false)}});
    root.append(button);
  });updateSelection(true);
}
function updateSelection(moveFocus){
  const cards=[...$('upgradeCards').children];if(lastUpgrade!==game.selected){cards.forEach((c,i)=>c.setAttribute('aria-current',String(i===game.selected)));lastUpgrade=game.selected;}
  if(moveFocus&&cards[game.selected])focus(cards[game.selected]);
}
function showResults(){
  $('resultTime').textContent=formatTime(game.seconds);$('resultLevel').textContent=game.player.level;$('resultKills').textContent=game.kills;
  $('deathPhrase').textContent=config.gameOverPhrases[Math.floor(Math.random()*config.gameOverPhrases.length)];
  const root=$('resultSkills');root.replaceChildren();
  config.skills.forEach((s,i)=>{const rank=game.player.skillLvl[i];if(!rank)return;const chip=document.createElement('div');chip.className='result-skill';const image=document.createElement('img');image.src=s.img;image.alt='';chip.append(image,document.createTextNode(s.name+' × '+rank));root.append(chip)});
  if(!root.children.length)root.textContent='No upgrades acquired';
}
function meter(id,value){const percent=Math.round(Math.max(0,Math.min(1,value))*100),node=$(id);node.firstElementChild.style.width=percent+'%';node.setAttribute('aria-valuenow',percent);}
function updateHud(){
  const p=game.player,health=Math.ceil(p.health),max=p.maxHealth,maxed=p.level>=config.maxLevel;
  const xp=maxed?'MAX':p.currentExp+' / '+p.expNeeded+' XP';
  const signature=[health,max,p.level,xp,game.seconds,game.kills].join('|');if(signature===lastHud)return;lastHud=signature;
  $('healthText').textContent=health+' / '+max;$('level').textContent=p.level;$('xpText').textContent=xp;
  $('timer').textContent=formatTime(game.seconds);$('kills').textContent=game.kills;
  meter('healthMeter',p.health/max);meter('xpMeter',maxed?1:p.currentExp/p.expNeeded);
}
function collectEvents(){
  if(!effects)return;
  for(const e of game.events){
    const color={hit:'#ead8ff',kill:'#e5c48b',heal:'#85e8b3',hurt:'#ff828a',cast:'#d0a4ff'}[e.type];
    if(!color)continue;
    const count=e.type==='kill'?7:e.type==='hit'?3:1;
    for(let i=0;i<count&&particles.length<180;i++){
      const angle=Math.random()*Math.PI*2, speed=1+Math.random()*2;
      particles.push({x:e.x,y:e.y,vx:Math.cos(angle)*speed,vy:Math.sin(angle)*speed,life:18,max:18,color});
    }
    if(['hit','heal','hurt'].includes(e.type)&&particles.length<180)particles.push({x:e.x,y:e.y-12,vx:0,vy:-.8,life:30,max:30,color,label:(e.type==='heal'?'+':'−')+Math.ceil(e.value)});
  }
}
function advanceEffects(){
  for(const p of particles){p.x+=p.vx;p.y+=p.vy;p.life--}
  particles=particles.filter(p=>p.life>0);
}
function step(){
  advanceEffects();const running=game.step(input());collectEvents();return running;
}
function background(){
  const W=game.width,H=game.height,c=game.camera,tile=600;
  const x=-((c.x%tile+tile)%tile),y=-((c.y%tile+tile)%tile);
  ctx.fillStyle='#24202a';ctx.fillRect(0,0,W,H);
  const floor=images.get('./images/dungeonfloor.jpg');
  if(floor){for(let iy=y;iy<H;iy+=tile)for(let ix=x;ix<W;ix+=tile)ctx.drawImage(floor,ix,iy,tile,tile);ctx.fillStyle='rgba(18,14,26,.53)';ctx.fillRect(0,0,W,H);}
}
function shadow(x,y,w,h){ctx.fillStyle='rgba(6,5,11,.43)';ctx.beginPath();ctx.ellipse(x+w/2,y+h*.88,w*.44,h*.18,0,0,Math.PI*2);ctx.fill();}
function bar(x,y,w,h,fraction,color){const f=Math.max(0,Math.min(1,fraction));ctx.fillStyle='#1c1723';ctx.fillRect(x,y,w,h);ctx.fillStyle=color;ctx.fillRect(x,y,w*f,h);}
function render(){
  const {width,height,dpr}=surface,{scale,x,y}=fitViewport(width,height,game.width,game.height);
  ctx.setTransform(dpr,0,0,dpr,0,0);ctx.fillStyle='#14121b';ctx.fillRect(0,0,width,height);
  ctx.save();ctx.translate(x,y);ctx.scale(scale,scale);ctx.beginPath();ctx.rect(0,0,game.width,game.height);ctx.clip();
  background();const c=game.camera,p=game.player;
  for(const o of game.potions)if(game.visible(o,0)){const px=o.x-c.x,py=o.y-c.y;shadow(px,py,o.width,o.height);ctx.strokeStyle='#8ae1ae99';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(px+o.width/2,py+o.height/2,17,0,Math.PI*2);ctx.stroke();sprite(o.imageSrc,px,py,o.width,o.height,'#82dba5');}
  for(const e of game.enemies)if(game.visible(e,0)){const px=e.x-c.x,py=e.y-c.y;shadow(px,py,e.width,e.height);sprite(e.imageSrc,px,py,e.width,e.height,'#799653');if(keys.has('KeyQ'))bar(px,py-8,e.width,4,e.health/e.maxHealth,'#e27279');}
  const px=p.x-c.x,py=p.y-c.y;
  ctx.strokeStyle='#d6b8ff80';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(px+p.width/2,py+p.height*.82,22,12,0,0,Math.PI*2);ctx.stroke();
  shadow(px,py,p.width,p.height);sprite('./images/wizard-hat.png',px,py,p.width,p.height,'#bda0ed');
  if(keys.has('KeyQ'))bar(px,py-8,p.width,4,p.health/p.maxHealth,'#e27279');
  for(const s of game.shots)if(game.visible(s,0)){
    const sx=s.x-c.x+s.width/2,sy=s.y-c.y+s.height/2;
    if(effects){ctx.strokeStyle='#bca0ed99';ctx.lineWidth=3;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(sx-s.vx*1.6,sy-s.vy*1.6);ctx.lineTo(sx,sy);ctx.stroke();}
    ctx.fillStyle='#f3e8ff';ctx.beginPath();ctx.arc(sx,sy,Math.max(2.5,s.width/2),0,Math.PI*2);ctx.fill();
  }
  if(effects){for(const q of particles){
    ctx.globalAlpha=q.life/q.max;ctx.fillStyle=q.color;
    if(q.label){ctx.font='bold 13px system-ui';ctx.textAlign='center';ctx.fillText(q.label,q.x-c.x,q.y-c.y);}
    else ctx.fillRect(q.x-c.x,q.y-c.y,3,3);
  }ctx.globalAlpha=1;
    if(game.flash){ctx.fillStyle='rgba(175,38,54,.13)';ctx.fillRect(0,0,game.width,game.height);}
  }
  ctx.restore();
}
function frame(now){
  if(screen==='play'&&!document.hidden){
    clock.advance(now,step);dirty=true;
    if(game.phase==='upgrade')setScreen('upgrade');else if(game.phase==='over')setScreen('over');
  }
  if(dirty){render();updateHud();dirty=false;}
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
