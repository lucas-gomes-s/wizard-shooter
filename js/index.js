import * as config from './data.js';
import { Game, FixedClock } from './simulation.js';
import { schools, synergies, schoolById } from './magic.js';
import { viewportFor, fitViewport, formatTime, skillPreview } from './presentation.js';

const $=id=>document.getElementById(id);
const canvas=$('gameArea'), ctx=canvas.getContext('2d'), arena=$('arena');
const game=new Game(config), clock=new FixedClock();
const keys=new Set(), arrows=['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'];
const aimVectors={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
const allowed=new Set(['KeyW','KeyA','KeyS','KeyD','KeyQ','Escape','Enter',...arrows]);
const panels={home:$('homePanel'),pause:$('pausePanel'),confirm:$('confirmPanel'),upgrade:$('upgradePanel'),over:$('resultPanel'),victory:$('victoryPanel')};
let screen='home',ready=false,aimOrder=[],confirmAction=null,dirty=true,particles=[],lastHud='',lastUpgrade=-1,lastBuild='';
let lastBoss='';
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
  else if(next==='victory'){$('victoryTime').textContent=formatTime(game.seconds);$('victoryKills').textContent=game.kills;focus($('endlessButton'));}
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
$('victoryTitleButton').addEventListener('click',home);
$('endlessButton').addEventListener('click',()=>{if(game.continueEndless()){particles=[];setScreen(game.phase==='upgrade'?'upgrade':'play')}});
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
  $('assetStatus').textContent=missing?missing+' asset(s) unavailable; fallback graphics enabled.':'Survive 25 minutes to face the Ancient Dragon.';
  dirty=true;
});
function choose(index=game.selected){
  if(screen!=='upgrade'||!game.choose(index))return;
  if(game.phase==='upgrade')setScreen('upgrade');else setScreen('play');
}
document.addEventListener('keydown',e=>{
  if(!allowed.has(e.code)||e.altKey||e.ctrlKey||e.metaKey)return;
  if(screen==='home'||screen==='over'||screen==='victory')return;
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
  game.offers.forEach((s,i)=>{
    const button=document.createElement('button');
    button.type='button';button.className='upgrade-card';button.dataset.index=i;button.style.setProperty('--school',s.color);
    if(s.img){const image=document.createElement('img');image.src=s.img;image.alt='';button.append(image)}
    else{const glyph=document.createElement('span');glyph.className='spell-glyph';glyph.textContent=s.glyph;glyph.setAttribute('aria-hidden','true');button.append(glyph)}
    for(const [name,value] of [['skill-flavor',s.flavor],['skill-title',s.name],['skill-effect',s.description],['skill-value',s.kind==='basic'?skillPreview(game.player,config.skills[s.index]):s.kind==='synergy'?'New combined spell':'Rank '+(s.rank+1)+' / '+s.max],['skill-rank',s.kind==='synergy'?'Requires rank II in both schools':'Current rank '+s.rank+' / '+s.max]]){
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
  $('resultTitle').textContent=game.bossDefeated?'Endless run complete.':'The dungeon wins.';
  $('deathPhrase').textContent=config.gameOverPhrases[Math.floor(Math.random()*config.gameOverPhrases.length)];
  const root=$('resultSkills');root.replaceChildren();
  config.skills.forEach((s,i)=>{const rank=game.player.skillLvl[i];if(!rank)return;const chip=document.createElement('div');chip.className='result-skill';const image=document.createElement('img');image.src=s.img;image.alt='';chip.append(image,document.createTextNode(s.name+' × '+rank));root.append(chip)});
  for(const school of schools){const rank=game.player.magic.ranks[school.id];if(rank)root.append(spellChip(school,rank))}
  for(const combo of synergies)if(game.player.magic.synergies.includes(combo.id))root.append(spellChip(combo));
  if(!root.children.length)root.textContent='No upgrades acquired';
}
function spellChip(s,rank){const chip=document.createElement('span');chip.className='spell-chip';chip.style.setProperty('--school',s.color);chip.textContent=s.glyph+' '+s.name+(rank?' '+rank:'');return chip}
function updateBuild(){const m=game.player.magic,signature=JSON.stringify([m.ranks,m.synergies,m.shieldReady]);if(signature===lastBuild)return;lastBuild=signature;const root=$('spellBuild');root.replaceChildren();for(const s of schools)if(m.ranks[s.id])root.append(spellChip(s,m.ranks[s.id]));for(const s of synergies)if(m.synergies.includes(s.id))root.append(spellChip(s));if(!root.children.length)root.textContent='Untrained · choose a school at level 2';if(m.ranks.arcane>=2){const shield=document.createElement('span');shield.className='spell-chip';shield.textContent=m.shieldReady?'Shield ready':'Shield recharging';root.append(shield)}}
function meter(id,value){const percent=Math.round(Math.max(0,Math.min(1,value))*100),node=$(id);node.firstElementChild.style.width=percent+'%';node.setAttribute('aria-valuenow',percent);}
function updateBoss(){const boss=game.boss,signature=boss?[Math.ceil(boss.health),boss.bossPhase].join('|'):String(game.endless);if(signature===lastBoss)return;lastBoss=signature;const node=$('bossHud');node.hidden=!boss&&!game.endless;if(boss){$('bossName').textContent='Ancient Dragon · Phase '+boss.bossPhase+' / 3';$('bossHealth').textContent=Math.ceil(boss.health)+' / '+boss.maxHealth;meter('bossMeter',boss.health/boss.maxHealth);$('bossMeter').hidden=false}else{$('bossName').textContent='Endless survival';$('bossHealth').textContent='Dragon defeated';$('bossMeter').hidden=true}}
function updateHud(){
  updateBoss();
  updateBuild();const p=game.player,health=Math.ceil(p.health),max=p.maxHealth,maxed=p.level>=config.maxLevel;
  const xp=maxed?'MAX':p.currentExp+' / '+p.expNeeded+' XP';
  const signature=[health,max,p.level,xp,game.seconds,game.kills].join('|');if(signature===lastHud)return;lastHud=signature;
  $('healthText').textContent=health+' / '+max;$('level').textContent=p.level;$('xpText').textContent=xp;
  $('timer').textContent=formatTime(game.seconds);$('kills').textContent=game.kills;
  meter('healthMeter',p.health/max);meter('xpMeter',maxed?1:p.currentExp/p.expNeeded);
}
function collectEvents(){
  if(!effects)return;
  for(const e of game.events){
    const color=schoolById[e.school]?.color||{hit:'#ead8ff',kill:'#e5c48b',heal:'#85e8b3',hurt:'#ff828a',cast:'#d0a4ff',shield:'#c3a2ff',burst:'#ff9560',chain:'#ffe17a'}[e.type];
    if(!color)continue;
    if(e.type==='burst'||e.type==='chain'){if(particles.length<180)particles.push({...e,color,life:10,max:10,vx:0,vy:0});continue}
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
function drawHazards(c){
  for(const h of game.hazards){const x=h.x-c.x,y=h.y-c.y,active=game.tick>=h.activeAt,color=h.type==='web'?'#d5d0e2':'#ff9b58';ctx.beginPath();ctx.arc(x,y,h.radius,0,Math.PI*2);ctx.fillStyle=color+(active?'33':'12');ctx.fill();ctx.strokeStyle=color;ctx.lineWidth=active?2:1.5;ctx.setLineDash(active?[]:[5,5]);ctx.stroke();ctx.setLineDash([]);if(!active){const ratio=Math.max(0,Math.min(1,(h.activeAt-game.tick)/35));ctx.beginPath();ctx.arc(x,y,h.radius*ratio,0,Math.PI*2);ctx.stroke();}}
}
function drawEnemyWarning(e,c){const a=e.action;if(!a)return;const x=e.x+e.width/2-c.x,y=e.y+e.height/2-c.y;ctx.lineWidth=2;ctx.strokeStyle='#ffb17b';ctx.fillStyle='#ff8c5530';if(a.kind==='orc-windup'||a.kind==='charge'){const dx=Math.cos(a.angle),dy=Math.sin(a.angle);ctx.beginPath();ctx.moveTo(x-dy*18,y+dx*18);ctx.lineTo(x+dx*200-dy*18,y+dy*200+dx*18);ctx.lineTo(x+dx*200+dy*18,y+dy*200-dx*18);ctx.lineTo(x+dy*18,y-dx*18);ctx.closePath();ctx.fill();ctx.stroke();}
 else if(a.kind==='reaper-windup'){ctx.beginPath();ctx.arc(a.x-c.x,a.y-c.y,e.width/2+8,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.setLineDash([5,5]);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(a.x-c.x,a.y-c.y);ctx.stroke();ctx.setLineDash([])}
 else if(a.kind==='demon-windup'||a.kind==='dragon-windup'){ctx.beginPath();ctx.arc(x,y,e.width*.7,0,Math.PI*2);ctx.stroke();if(a.kind==='dragon-windup'&&e.bossPhase>=2){for(let i=0;i<(e.bossPhase===3?12:8);i++){const angle=a.angle+i*Math.PI*2/(e.bossPhase===3?12:8);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+Math.cos(angle)*150,y+Math.sin(angle)*150);ctx.stroke()}}else{ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+Math.cos(a.angle-(a.kind==='dragon-windup'?.46:.24))*240,y+Math.sin(a.angle-(a.kind==='dragon-windup'?.46:.24))*240);ctx.arc(x,y,240,a.angle-(a.kind==='dragon-windup'?.46:.24),a.angle+(a.kind==='dragon-windup'?.46:.24));ctx.closePath();ctx.fill();ctx.stroke()}}
}
function render(){
  const {width,height,dpr}=surface,{scale,x,y}=fitViewport(width,height,game.width,game.height);
  ctx.setTransform(dpr,0,0,dpr,0,0);ctx.fillStyle='#14121b';ctx.fillRect(0,0,width,height);
  ctx.save();ctx.translate(x,y);ctx.scale(scale,scale);ctx.beginPath();ctx.rect(0,0,game.width,game.height);ctx.clip();
  background();const c=game.camera,p=game.player;drawHazards(c);
  for(const e of game.enemies)if(e.action)drawEnemyWarning(e,c);
  for(const o of game.potions)if(game.visible(o,0)){const px=o.x-c.x,py=o.y-c.y;shadow(px,py,o.width,o.height);ctx.strokeStyle='#8ae1ae99';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(px+o.width/2,py+o.height/2,17,0,Math.PI*2);ctx.stroke();sprite(o.imageSrc,px,py,o.width,o.height,'#82dba5');}
  for(const e of game.enemies)if(game.visible(e,0)){const px=e.x-c.x,py=e.y-c.y;shadow(px,py,e.width,e.height);sprite(e.imageSrc,px,py,e.width,e.height,'#799653');if(e.elite){ctx.strokeStyle='#e5c48b';ctx.lineWidth=2;ctx.strokeRect(px-3,py-3,e.width+6,e.height+6);ctx.fillStyle='#e5c48b';ctx.font='bold 11px system-ui';ctx.textAlign='center';ctx.fillText('ELITE',px+e.width/2,py-13)}if(e.name==='Knight'){ctx.strokeStyle='#a7c7e4';ctx.lineWidth=3;ctx.beginPath();ctx.arc(px+e.width/2,py+e.height/2,e.width*.62,e.facing-Math.PI/3,e.facing+Math.PI/3);ctx.stroke()}const statuses=[e.burnUntil>=game.tick?'#ff9560':null,e.slowUntil>game.tick?'#80dcff':null,e.curseUntil>game.tick?'#86e3ab':null].filter(Boolean);statuses.forEach((color,i)=>{ctx.fillStyle=color;ctx.fillRect(px+i*7,py+e.height+2,5,4)});if(keys.has('KeyQ'))bar(px,py-8,e.width,4,e.health/e.maxHealth,'#e27279');}
  const px=p.x-c.x,py=p.y-c.y;
  ctx.strokeStyle='#d6b8ff80';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(px+p.width/2,py+p.height*.82,22,12,0,0,Math.PI*2);ctx.stroke();
  shadow(px,py,p.width,p.height);sprite('./images/wizard-hat.png',px,py,p.width,p.height,'#bda0ed');
  if(p.magic.shieldReady){ctx.strokeStyle='#c3a2ff';ctx.lineWidth=2;ctx.beginPath();ctx.arc(px+p.width/2,py+p.height/2,27,0,Math.PI*2);ctx.stroke()}
  if(keys.has('KeyQ'))bar(px,py-8,p.width,4,p.health/p.maxHealth,'#e27279');
  for(const s of game.shots)if(game.visible(s,0)){
    const sx=s.x-c.x+s.width/2,sy=s.y-c.y+s.height/2,color=schoolById[s.school]?.color||'#f3e8ff';
    if(effects){ctx.strokeStyle=color+'99';ctx.lineWidth=3;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(sx-s.vx*1.6,sy-s.vy*1.6);ctx.lineTo(sx,sy);ctx.stroke();}
    ctx.fillStyle=color;ctx.beginPath();ctx.arc(sx,sy,Math.max(2.5,s.width/2),0,Math.PI*2);ctx.fill();
  }
  for(const s of game.hostiles){const x=s.x-c.x,y=s.y-c.y;ctx.fillStyle='#ff9b58';ctx.strokeStyle='#fff0b0';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(x,y,s.radius,0,Math.PI*2);ctx.fill();ctx.stroke()}
  if(p.webUntil>game.tick){ctx.strokeStyle='#d5d0e2';ctx.lineWidth=2;ctx.beginPath();ctx.arc(px+p.width/2,py+p.height/2,24,0,Math.PI*2);ctx.stroke()}
  if(effects){for(const q of particles){
    ctx.globalAlpha=q.life/q.max;ctx.fillStyle=q.color;
    if(q.type==='burst'){ctx.strokeStyle=q.color;ctx.lineWidth=2;ctx.beginPath();ctx.arc(q.x-c.x,q.y-c.y,Math.max(1,q.value*(1-q.life/q.max)),0,Math.PI*2);ctx.stroke()}
    else if(q.type==='chain'){ctx.strokeStyle=q.color;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(q.fromX-c.x,q.fromY-c.y);ctx.lineTo(q.x-c.x,q.y-c.y);ctx.stroke()}
    else if(q.label){ctx.font='bold 13px system-ui';ctx.textAlign='center';ctx.fillText(q.label,q.x-c.x,q.y-c.y);}
    else ctx.fillRect(q.x-c.x,q.y-c.y,3,3);
  }ctx.globalAlpha=1;
    if(game.flash){ctx.fillStyle='rgba(175,38,54,.13)';ctx.fillRect(0,0,game.width,game.height);}
  }
  ctx.restore();
}
function frame(now){
  if(screen==='play'&&!document.hidden){
    clock.advance(now,step);dirty=true;
    if(game.phase==='upgrade')setScreen('upgrade');else if(game.phase==='over')setScreen('over');else if(game.phase==='victory')setScreen('victory');
  }
  if(dirty){render();updateHud();dirty=false;}
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
