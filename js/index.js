import {equipmentSlots,itemById,rarityColors} from './equipment.js';
import * as config from './data.js';
import { Game, FixedClock } from './simulation.js';
import { schools, synergies, learnedSchools, SECOND_SCHOOL_LEVEL, synergyFor, masteries, MASTERY_LEVEL } from './magic.js';
import {CombatFX,drawWeb,drawHazard,drawEnemyWarning,drawEnemyStatus,drawShield,drawProjectile} from './combat-fx.js';
import { viewportFor, fitViewport, formatTime, skillPreview } from './presentation.js';

const $=id=>document.getElementById(id);
const canvas=$('gameArea'), ctx=canvas.getContext('2d'), arena=$('arena');
const game=new Game(config), clock=new FixedClock();
const keys=new Set(), arrows=['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'];
const aimVectors={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
const allowed=new Set(['KeyW','KeyA','KeyS','KeyD','KeyQ','Escape','Enter',...arrows]);
const panels={home:$('homePanel'),pause:$('pausePanel'),confirm:$('confirmPanel'),upgrade:$('upgradePanel'),loot:$('lootPanel'),over:$('resultPanel'),victory:$('victoryPanel')};
let screen='home',ready=false,aimOrder=[],confirmAction=null,dirty=true,lastHud='',lastUpgrade=-1,lastBuild='';
let lastBoss='',startingSchool='fire',lastGear='';
const fx=new CombatFX(matchMedia('(prefers-reduced-motion: reduce)').matches?'off':'full');
$('effectsMode').value=fx.mode;
$('effectsMode').addEventListener('change',()=>{fx.setMode($('effectsMode').value);dirty=true;if(screen==='play')focus(canvas)});
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
  else if(next==='loot')buildLoot();
  else if(next==='over'){showResults();focus($('retryButton'));}
  else if(next==='victory'){$('victoryTime').textContent=formatTime(game.seconds);$('victoryKills').textContent=game.kills;focus($('endlessButton'));}
}
function buildStarters(){const root=$('starterCards');root.replaceChildren();for(const school of schools){const button=document.createElement('button');button.type='button';button.className='starter-card';button.style.setProperty('--school',school.color);button.dataset.school=school.id;button.setAttribute('aria-pressed',String(startingSchool===school.id));const glyph=document.createElement('span');glyph.className='starter-glyph';glyph.textContent=school.glyph;const name=document.createElement('strong');name.textContent=school.name;const detail=document.createElement('span');detail.textContent=school.ranks[0];button.append(glyph,name,detail);button.addEventListener('click',()=>{startingSchool=school.id;for(const card of root.children)card.setAttribute('aria-pressed',String(card.dataset.school===startingSchool));});root.append(button)}}
buildStarters();
function startRun(){
  if(!ready)return;
  Object.assign(game,viewportFor(surface.width,surface.height));game.start(startingSchool);
  fx.clear();lastHud='';setScreen('play');
}
function home(){game.reset();fx.clear();Object.assign(game,viewportFor(surface.width,surface.height));setScreen('home');}
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
$('endlessButton').addEventListener('click',()=>{if(game.continueEndless()){fx.clear();setScreen(game.phase==='upgrade'?'upgrade':'play')}});
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
  $('assetStatus').textContent=missing?missing+' asset(s) unavailable; fallback graphics enabled.':'Choose a school. Battle the guardians and face the Ancient Dragon at minute 25.';
  dirty=true;
});
function chooseLoot(index){
 if(screen!=='loot'||!game.chooseLoot(index))return;
 setScreen(game.phase==='upgrade'?'upgrade':'play');
}
$('skipLoot').addEventListener('click',()=>chooseLoot(-1));
function buildLoot(){
 const root=$('lootCards');root.replaceChildren();$('lootTitle').textContent=game.lootSource||'Treasure recovered';
 for(const [i,item] of game.loot.entries()){
  const button=document.createElement('button');button.type='button';button.className='upgrade-card loot-card';button.style.setProperty('--school',rarityColors[item.rarity]);
  const current=itemById[game.player.equipment[item.slot]];
  for(const [cls,value] of [['spell-glyph',item.glyph],['skill-flavor',item.rarity.toUpperCase()+' · '+item.slot],['skill-title',item.name],['skill-effect',item.description],['skill-rank',current?'Replaces '+current.name+': '+current.description:'Empty slot']]){
   const span=document.createElement('span');span.className=cls;span.textContent=value;button.append(span);
  }
  button.addEventListener('click',()=>chooseLoot(i));root.append(button);
 }
 focus(root.firstElementChild||$('skipLoot'));
}
function updateGear(){
 const p=game.player,signature=JSON.stringify(p.equipment);
 if(signature!==lastGear){lastGear=signature;const root=$('equipmentBuild');root.replaceChildren();
  for(const slot of equipmentSlots){const item=itemById[p.equipment[slot]],chip=document.createElement('span');chip.className='gear-chip';chip.style.setProperty('--rarity',item?rarityColors[item.rarity]:'#777080');chip.textContent=slot.toUpperCase()+': '+(item?item.glyph+' '+item.name:'Empty');chip.title=item?item.description:'No '+slot+' equipped';root.append(chip);}
 }
 const chest=game.chests[0];$('treasureHint').textContent=chest?game.chests.length+' treasure chest'+(game.chests.length===1?'':'s')+' · '+Math.ceil(Math.max(0,chest.until-game.tick)/50)+'s remaining':'';
}
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
  if(screen==='loot'){return;}
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
  if(e.target instanceof HTMLInputElement||e.target instanceof HTMLSelectElement)return;
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
  const m=game.player.magic,count=learnedSchools(m).length;
  $('upgradeHint').textContent=m.mastery?'Exclusive mastery acquired. Your primary school is permanent.':count<2&&game.player.level<SECOND_SCHOOL_LEVEL?'Master your primary school. Secondary school unlocks at level '+SECOND_SCHOOL_LEVEL+'.':count<2?'Choose a secondary school now or keep specializing. Your choice is permanent for this run.':'Your two schools are locked in. Master them and discover compatible synergies.';
  game.offers.forEach((s,i)=>{
    const button=document.createElement('button');
    button.type='button';button.className='upgrade-card';button.dataset.index=i;button.style.setProperty('--school',s.color);
    if(s.img){const image=document.createElement('img');image.src=s.img;image.alt='';button.append(image)}
    else{const glyph=document.createElement('span');glyph.className='spell-glyph';glyph.textContent=s.glyph;glyph.setAttribute('aria-hidden','true');button.append(glyph)}
    for(const [name,value] of [['skill-flavor',s.flavor],['skill-title',s.name],['skill-effect',s.description],['skill-value',s.kind==='basic'?skillPreview(game.player,config.skills[s.index]):s.kind==='mastery'?'Exclusive capstone':s.kind==='synergy'?'New combined spell':'Rank '+(s.rank+1)+' / '+s.max],['skill-rank',s.kind==='mastery'?'Locks secondary schools':s.kind==='synergy'?'Requires rank II in both schools':'Current rank '+s.rank+' / '+s.max]]){
      const span=document.createElement('span');span.className=name;span.textContent=value;button.append(span);
    }
    if(s.kind==='school'&&s.rank===0&&m.primary){const combo=synergyFor(m.primary,s.id);if(combo){const preview=document.createElement('span');preview.className='synergy-preview';preview.textContent='Fusion: '+combo.name+' · '+combo.description;button.append(preview);}}
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
  for(const combo of synergies)if(game.player.magic.synergies.includes(combo.id))root.append(spellChip(combo));for(const mastery of masteries)if(game.player.magic.mastery===mastery.id)root.append(spellChip(mastery));
  for(const slot of equipmentSlots){const item=itemById[game.player.equipment[slot]];if(item)root.append(spellChip({...item,color:rarityColors[item.rarity]}));}
  if(!root.children.length)root.textContent='No upgrades acquired';
}
function spellChip(s,rank){const chip=document.createElement('span');chip.className='spell-chip';chip.style.setProperty('--school',s.color);chip.textContent=s.glyph+' '+s.name+(rank?' '+rank:'');if(s.id===game.player.magic.primary){chip.title='Primary school';chip.classList.add('primary-school')}else if(s.id===game.player.magic.secondary)chip.title='Secondary school';return chip}
function updateBuild(){const m=game.player.magic,signature=JSON.stringify([m.ranks,m.synergies,m.shieldReady,m.primary,m.secondary,m.mastery,Math.min(game.player.level,MASTERY_LEVEL)]);if(signature===lastBuild)return;lastBuild=signature;const root=$('spellBuild');root.replaceChildren();for(const s of schools)if(m.ranks[s.id])root.append(spellChip(s,m.ranks[s.id]));for(const s of synergies)if(m.synergies.includes(s.id))root.append(spellChip(s));for(const mastery of masteries)if(m.mastery===mastery.id)root.append(spellChip(mastery));if(!root.children.length)root.textContent='Choose your starting school';else if(learnedSchools(m).length<2){const lock=document.createElement('span');lock.className='school-lock';lock.textContent=m.mastery?'Pure mastery · second school locked':game.player.level<SECOND_SCHOOL_LEVEL?'Secondary school · Lv '+SECOND_SCHOOL_LEVEL+' ('+(SECOND_SCHOOL_LEVEL-game.player.level)+' to go)':'Secondary school available · Pure mastery at Lv '+MASTERY_LEVEL+' / rank V';root.append(lock)}else{const lock=document.createElement('span');lock.className='school-lock';const combo=synergyFor(m.primary,m.secondary);lock.textContent='Two schools learned'+(combo&&!m.synergies.includes(combo.id)?' · '+combo.name+' at rank II + II':'');root.append(lock)}if(m.ranks.arcane>=2){const shield=document.createElement('span');shield.className='spell-chip';shield.textContent=m.shieldReady?'Shield ready':'Shield recharging';root.append(shield)}}
function meter(id,value){const percent=Math.round(Math.max(0,Math.min(1,value))*100),node=$(id);node.firstElementChild.style.width=percent+'%';node.setAttribute('aria-valuenow',percent);}
function updateBoss(){const boss=game.boss||game.miniboss,signature=boss?[boss.title||boss.name,Math.ceil(boss.health),boss.bossPhase].join('|'):String(game.endless);if(signature===lastBoss)return;lastBoss=signature;const node=$('bossHud');node.hidden=!boss&&!game.endless;if(boss){$('bossName').textContent=boss.boss?'Ancient Dragon · Phase '+boss.bossPhase+' / 3':boss.title;$('bossHealth').textContent=Math.ceil(boss.health)+' / '+boss.maxHealth;meter('bossMeter',boss.health/boss.maxHealth);$('bossMeter').hidden=false}else{$('bossName').textContent='Endless survival';$('bossHealth').textContent='Dragon defeated';$('bossMeter').hidden=true}}
function updateHud(){
  updateBoss();updateGear();
  updateBuild();const p=game.player,health=Math.ceil(p.health),max=p.maxHealth,maxed=p.level>=config.maxLevel;
  const xp=maxed?'MAX':p.currentExp+' / '+p.expNeeded+' XP';
  const signature=[health,max,p.level,xp,game.seconds,game.kills].join('|');if(signature===lastHud)return;lastHud=signature;
  $('healthText').textContent=health+' / '+max;$('level').textContent=p.level;$('xpText').textContent=xp;
  $('timer').textContent=formatTime(game.seconds);$('kills').textContent=game.kills;
  meter('healthMeter',p.health/max);meter('xpMeter',maxed?1:p.currentExp/p.expNeeded);
}
function step(){
  fx.advance();const running=game.step(input());fx.collect(game.events);fx.collect(game.visualEvents);return running;
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
function drawTreasure(c){
 for(const chest of game.chests){
  const x=chest.x+16-c.x,y=chest.y+16-c.y,color=rarityColors[['common','rare','epic','legendary'][chest.tier]]||'#ffd277';
  const sx=Math.max(22,Math.min(game.width-22,x)),sy=Math.max(38,Math.min(game.height-24,y));
  ctx.save();ctx.strokeStyle=color;ctx.fillStyle='#4a3030';ctx.lineWidth=2;
  if(sx!==x||sy!==y){const angle=Math.atan2(y-sy,x-sx);ctx.translate(sx,sy);ctx.rotate(angle);ctx.fillStyle=color;ctx.beginPath();ctx.moveTo(12,0);ctx.lineTo(-5,-8);ctx.lineTo(-5,8);ctx.closePath();ctx.fill();ctx.restore();continue;}
  ctx.beginPath();ctx.arc(x,y,25,0,Math.PI*2);ctx.stroke();
  ctx.fillRect(x-14,y-8,28,19);ctx.strokeRect(x-14,y-8,28,19);ctx.fillStyle='#947247';ctx.fillRect(x-14,y-4,28,4);ctx.fillStyle=color;ctx.fillRect(x-3,y-5,6,8);
  ctx.font='bold 11px system-ui';ctx.textAlign='center';ctx.fillText('TREASURE',x,y-31);ctx.restore();
 }
}
function render(){
  const {width,height,dpr}=surface,{scale,x,y}=fitViewport(width,height,game.width,game.height);
  ctx.setTransform(dpr,0,0,dpr,0,0);ctx.fillStyle='#14121b';ctx.fillRect(0,0,width,height);
  ctx.save();ctx.translate(x,y);ctx.scale(scale,scale);ctx.beginPath();ctx.rect(0,0,game.width,game.height);ctx.clip();
  background();const c=game.camera,p=game.player;drawTreasure(c);
  for(const h of game.hazards)if(game.visible({x:h.x-h.radius,y:h.y-h.radius,width:h.radius*2,height:h.radius*2},30))drawHazard(ctx,h,c,game.tick,fx.mode);
  for(const e of game.enemies)if(e.action&&game.visible(e,350))drawEnemyWarning(ctx,e,c,game.tick,fx.mode);
  for(const o of game.potions)if(game.visible(o,0)){const px=o.x-c.x,py=o.y-c.y;shadow(px,py,o.width,o.height);ctx.strokeStyle='#8ae1ae99';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(px+o.width/2,py+o.height/2,17,0,Math.PI*2);ctx.stroke();sprite(o.imageSrc,px,py,o.width,o.height,'#82dba5');}
  for(const e of game.enemies)if(game.visible(e,0)){const px=e.x-c.x,py=e.y-c.y;shadow(px,py,e.width,e.height);sprite(e.imageSrc,px,py,e.width,e.height,'#799653');if(e.elite||e.miniboss){ctx.strokeStyle='#e5c48b';ctx.lineWidth=2;ctx.strokeRect(px-3,py-3,e.width+6,e.height+6);ctx.fillStyle='#e5c48b';ctx.font='bold 11px system-ui';ctx.textAlign='center';ctx.fillText(e.miniboss?'MINIBOSS':'ELITE',px+e.width/2,py-13)}drawEnemyStatus(ctx,e,c,game.tick,fx.mode);if(keys.has('KeyQ'))bar(px,py-8,e.width,4,e.health/e.maxHealth,'#e27279');}
  const px=p.x-c.x,py=p.y-c.y;
  ctx.strokeStyle='#d6b8ff80';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(px+p.width/2,py+p.height*.82,22,12,0,0,Math.PI*2);ctx.stroke();
  shadow(px,py,p.width,p.height);sprite('./images/wizard-hat.png',px,py,p.width,p.height,'#bda0ed');
  if(p.magic.shieldReady)drawShield(ctx,px+p.width/2,py+p.height/2,game.tick,fx.mode);
  if(keys.has('KeyQ'))bar(px,py-8,p.width,4,p.health/p.maxHealth,'#e27279');
  for(const s of game.shots)if(game.visible(s,0))drawProjectile(ctx,s,c,game.tick,fx.mode);
  for(const s of game.hostiles)if(game.visible({x:s.x-s.radius,y:s.y-s.radius,width:2*s.radius,height:2*s.radius},20))drawProjectile(ctx,s,c,game.tick,fx.mode,true);
  if(p.webUntil>game.tick)drawWeb(ctx,px+p.width/2,py+p.height/2,26,true,game.tick,fx.mode);
  fx.draw(ctx,c,p,game.tick);
  if(game.flash&&fx.mode!=='off'){const strength=fx.mode==='full'?.16:.07;ctx.fillStyle='rgba(175,38,54,'+strength+')';ctx.fillRect(0,0,game.width,game.height);}
  ctx.restore();
}
function frame(now){
  if(screen==='play'&&!document.hidden){
    clock.advance(now,step);dirty=true;
    if(game.phase==='upgrade')setScreen('upgrade');else if(game.phase==='loot')setScreen('loot');else if(game.phase==='over')setScreen('over');else if(game.phase==='victory')setScreen('victory');
  }
  if(dirty){render();updateHud();dirty=false;}
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
