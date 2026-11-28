import {FrameStats,makeReport,browserFamily,RELEASE} from './beta-report.js';
import {DungeonArt,drawSigil,drawTargetRing,drawLight} from './dungeon-art.js';
import {GameAudio,loadAudio,saveAudio} from './audio.js';
import {environments,environmentById,environmentConfig} from './environments.js';
import {loadProfile,saveProfile,recordProgress,newProgressSession,runConfig,available,contracts,sigils,achievements} from './progression.js';
import {equipment} from './equipment.js';
import {dungeonEvents} from './dungeon-events.js';
import {itemAttunements} from './attunements.js';
import {activeGear,activeInfo} from './active-gear.js';
import {eventById,eventObjective} from './dungeon-events.js';
import {equipmentSlots,itemById,rarityColors} from './equipment.js';
import * as config from './data.js';
import { Game, FixedClock } from './simulation.js';
import { schools, synergies, learnedSchools, SECOND_SCHOOL_LEVEL, synergyFor, masteries, MASTERY_LEVEL } from './magic.js';
import {CombatFX,drawWeb,drawHazard,drawEnemyWarning,drawEnemyStatus,drawShield,drawProjectile} from './combat-fx.js';
import { viewportFor, fitViewport, formatTime, skillPreview } from './presentation.js';

const $=id=>document.getElementById(id);
const canvas=$('gameArea'), ctx=canvas.getContext('2d'), arena=$('arena');
const game=new Game(config), clock=new FixedClock();
const frames=new FrameStats();
const art=new DungeonArt((w,h)=>{const c=document.createElement('canvas');c.width=w;c.height=h;return c});
let storage=null;try{storage=window.localStorage}catch{}
const audio=new GameAudio(loadAudio(storage),window.AudioContext||window.webkitAudioContext||null);
function audioControls(){
 $('muteAudio').setAttribute('aria-pressed',String(audio.settings.muted));$('muteAudio').textContent=audio.settings.muted?'Sound off':'Sound on';
 $('sfxVolume').value=Math.round(audio.settings.sfx*100);$('musicVolume').value=Math.round(audio.settings.music*100);
 $('audioStatus').textContent=audio.Context?'Audio starts after interaction.':'Audio unavailable in this browser.';
}
function changeAudio(patch){audio.update({...audio.settings,...patch});saveAudio(storage,audio.settings);audioControls();}
$('muteAudio').addEventListener('click',()=>{changeAudio({muted:!audio.settings.muted});if(!audio.settings.muted)void audio.unlock();if(screen==='play')focus(canvas)});
for(const [id,key] of [['sfxVolume','sfx'],['musicVolume','music']])$(id).addEventListener('input',()=>changeAudio({[key]:Number($(id).value)/100}));
// Autoplay policy: creation/resume only from a real gesture, never on page load.
for(const type of ['pointerdown','keydown'])document.addEventListener(type,e=>{if(e.isTrusted&&!audio.ready&&!document.hidden)void audio.unlock()},{capture:true});
audioControls();
const loaded=loadProfile(storage),profile=loaded.profile;let profileSaved=loaded.saved,progressSession=null,runSigil='violet';
function persistProfile(){profileSaved=saveProfile(storage,profile);return profileSaved}
function checkpoint(){const unlocked=recordProgress(profile,game,progressSession);if(progressSession?.recorded)persistProfile();return unlocked}
function unlockText(ids){return ids.length?'Achievements unlocked: '+ids.map(id=>achievements.find(a=>a.id===id).name).join(' · '):''}
window.addEventListener('pagehide',()=>checkpoint());
const keys=new Set(), arrows=['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'];
const aimVectors={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
const allowed=new Set(['KeyW','KeyA','KeyS','KeyD','KeyQ','Space','KeyE','Escape','Enter',...arrows]);
const panels={home:$('homePanel'),profile:$('profilePanel'),pause:$('pausePanel'),confirm:$('confirmPanel'),upgrade:$('upgradePanel'),loot:$('lootPanel'),shop:$('shopPanel'),over:$('resultPanel'),victory:$('victoryPanel')};
let activeKeys=new Set();
let screen='home',ready=false,aimOrder=[],confirmAction=null,dirty=true,lastHud='',lastUpgrade=-1,lastBuild='';
let lastBoss='',startingSchool='fire',lastGear='';
const fx=new CombatFX(matchMedia('(prefers-reduced-motion: reduce)').matches?'off':'full');
$('effectsMode').value=fx.mode;
$('effectsMode').addEventListener('change',()=>{fx.setMode($('effectsMode').value);dirty=true;if(screen==='play')focus(canvas)});
const images=new Map();
const urls=new Set([...config.potionInfo.map(p=>p.imageSrc),...config.skills.map(s=>s.img)]);
$('titleWizard').src=art.actor('Wizard').toDataURL();
const journey=[...config.minibosses.map(b=>[b.minute*60,'Next guardian']),[1500,'Dragon']];
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
function clearInput(){activeKeys.clear();keys.clear();aimOrder=[];clock.reset();}
function focus(el){el.focus({preventScroll:true});}
function setScreen(next){
  const previous=screen;screen=next;clearInput();dirty=true;
  audio.setPlaying(next==='play'&&!document.hidden);
  if(next!==previous&&!document.hidden){const cue={upgrade:'upgrade',loot:'loot',shop:'shop',over:'defeat',victory:'victory'}[next];if(cue)audio.cue(cue);}
  for(const [name,panel] of Object.entries(panels))panel.hidden=name!==next;
  $('overlay').hidden=next==='play';
  $('pauseButton').disabled=!['play','pause'].includes(next);
  $('pauseButton').firstChild.textContent=next==='pause'?'Resume ':'Pause ';
  if(next==='play')focus(canvas);
  else if(next==='home'){refreshProfileControls();if(ready)focus($('startButton'));}
  else if(next==='profile'){renderProfile();focus($('profileBack'));}
  else if(next==='pause')focus($('resumeButton'));
  else if(next==='confirm')focus($('cancelButton'));
  else if(next==='upgrade'){lastUpgrade=-1;buildUpgrades();}
  else if(next==='loot')buildLoot();
  else if(next==='shop')buildShop();
  else if(next==='over'){$('resultUnlocks').textContent=unlockText(checkpoint());showResults();focus($('retryButton'));}
  else if(next==='victory'){$('victoryTitle').textContent=environmentById(game.config.environment).boss+' defeated.';$('victoryUnlocks').textContent=unlockText(checkpoint());$('victoryTime').textContent=formatTime(game.seconds);$('victoryKills').textContent=game.kills;focus($('endlessButton'));}
}
function buildStarters(){const root=$('starterCards');root.replaceChildren();for(const school of schools){const button=document.createElement('button');button.type='button';button.className='starter-card';button.style.setProperty('--school',school.color);button.dataset.school=school.id;button.setAttribute('aria-pressed',String(startingSchool===school.id));const glyph=document.createElement('span');glyph.className='starter-glyph';glyph.textContent=school.glyph;const name=document.createElement('strong');name.textContent=school.name;const detail=document.createElement('span');detail.textContent=school.ranks[0];button.append(glyph,name,detail);button.addEventListener('click',()=>{startingSchool=school.id;for(const card of root.children)card.setAttribute('aria-pressed',String(card.dataset.school===startingSchool));});root.append(button)}}
buildStarters();
function refreshProfileControls(){
 $('profileSummary').textContent=profile.runs+' expeditions · '+profile.wins+' victories · '+profile.achievements.length+'/'+achievements.length+' achievements'+(profileSaved?'':' · Save unavailable');
 for(const [id,catalog,key] of [['contractSelect',contracts,'contract'],['sigilSelect',sigils,'sigil'],['environmentSelect',environments,'environment']]){
  const el=$(id);el.replaceChildren();
  for(const entry of catalog){const opt=document.createElement('option');opt.value=entry.id;opt.disabled=!available(catalog,entry.id,profile);opt.textContent=entry.name+(opt.disabled?' (unlock: '+achievements.find(a=>a.id===entry.requires).name+')':'');el.append(opt);}
  el.value=profile.selection[key];
 }
 $('contractDescription').textContent=contracts.find(c=>c.id===profile.selection.contract).description;
 $('environmentDescription').textContent=environmentById(profile.selection.environment).description;
 $('environmentSelect').style.borderColor=environmentById(profile.selection.environment).color;dirty=true;
}
function renderProfile(){
 $('profileStats').textContent=profile.runs+' expeditions · '+profile.wins+' victories · '+profile.kills.toLocaleString()+' kills · Best '+formatTime(Math.floor(profile.bestTicks/50))+' · Highest level '+profile.bestLevel;
 $('profileStorage').textContent=profileSaved?'Saved locally in this browser. No account or network tracking.':'Local storage unavailable; progress may be lost when you leave.';
 const root=$('codexEntries');root.replaceChildren();
 const groups=[['Achievements',achievements,profile.achievements],['Equipment',equipment,profile.items],['School fusions',synergies,profile.fusions],['Pure masteries',masteries,profile.masteries],['Dungeon challenges',dungeonEvents,profile.events],['Starting schools',schools,profile.schools],['Contract victories',contracts.filter(c=>c.id!=='standard'),profile.contracts],['Victories by starting school',schools,profile.winningSchools],['Environments explored',environments,profile.visitedEnvironments],['Environment victories',environments,profile.winningEnvironments]];
 for(const [name,entries,found] of groups){
  const section=document.createElement('section');section.className='codex-group';const h=document.createElement('h3');h.textContent=name+' · '+found.length+'/'+entries.length;section.append(h);
  for(const entry of entries){const row=document.createElement('div');row.className='codex-entry'+(found.includes(entry.id)?' discovered':'');const title=document.createElement('strong');title.textContent=(found.includes(entry.id)?'✓ ':'○ ')+entry.name;const desc=document.createElement('span');desc.textContent=entry.description||'';row.append(title,desc);section.append(row);}
  root.append(section);
 }
}
$('profileButton').addEventListener('click',()=>setScreen('profile'));
$('profileBack').addEventListener('click',()=>setScreen('home'));
for(const [id,catalog,key] of [['contractSelect',contracts,'contract'],['sigilSelect',sigils,'sigil'],['environmentSelect',environments,'environment']])$(id).addEventListener('change',()=>{const value=$(id).value;if(available(catalog,value,profile)){profile.selection[key]=value;persistProfile();}refreshProfileControls();});
refreshProfileControls();
function startRun(){
  if(!ready)return;
  checkpoint();game.config=environmentConfig(runConfig(config,profile.selection.contract),profile.selection.environment);progressSession=newProgressSession(profile.selection.contract,profile.selection.environment);runSigil=profile.selection.sigil;
  Object.assign(game,viewportFor(surface.width,surface.height));game.start(startingSchool);
  frames.reset();audio.reset();void audio.unlock();fx.clear();lastHud='';setScreen('play');
}
function home(){frames.reset();audio.reset();checkpoint();progressSession=null;game.config=config;game.reset();fx.clear();Object.assign(game,viewportFor(surface.width,surface.height));setScreen('home');}
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
  $('assetStatus').textContent=missing?missing+' asset(s) unavailable; fallback graphics enabled.':'Choose a school. Battle the guardians and face the dungeon’s dragon at minute 25.';
  dirty=true;
});
function buy(index){
 if(screen!=='shop'||!game.choosePurchase(index))return;
 setScreen(game.phase==='upgrade'?'upgrade':'play');
}
$('skipShop').addEventListener('click',()=>buy(-1));
function attunementText(item,p){
 return itemAttunements(item.id).map(a=>a.name+' · '+a.school.toUpperCase()+' rank II · '+((p.magic.ranks[a.school]||0)>=2?'ACTIVE: ':'Locked: ')+a.description).join(' ');
}
function appendAttunement(button,item){
 const value=attunementText(item,game.player);if(!value)return;
 const node=document.createElement('span');node.className='attunement-preview';node.textContent=value;button.append(node);
}
function buildShop(){
 const root=$('shopCards');root.replaceChildren();$('shopGold').textContent=game.player.gold+' gold available';
 for(const [i,item] of game.market.offers.entries()){
  const button=document.createElement('button');button.type='button';button.className='upgrade-card shop-card';button.style.setProperty('--school',rarityColors[item.rarity]||'#8ae1ae');
  const old=itemById[game.player.equipment[item.slot]],active=activeGear[item.id];
  const fields=[['spell-glyph',item.glyph],['skill-flavor',item.kind==='heal'?'CONSUMABLE':item.rarity.toUpperCase()+' · '+item.slot],['skill-title',item.name],['skill-effect',item.description],['skill-value',item.price+' gold'],['skill-rank',old?'Replaces '+old.name:item.kind==='heal'?'Immediate recovery':'Empty slot']];
  if(active)fields.push(['synergy-preview',active.name+' · '+active.description+' ('+active.cooldown/50+'s cooldown)']);
  for(const [cls,value] of fields){const span=document.createElement('span');span.className=cls;span.textContent=value;button.append(span);}
  appendAttunement(button,item);
  button.disabled=game.player.gold<item.price||(item.kind==='heal'&&game.player.health>=game.player.maxHealth);
  button.addEventListener('click',()=>buy(i));root.append(button);
 }
 focus([...root.children].find(b=>!b.disabled)||$('skipShop'));
}
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
  const active=activeGear[item.id];if(active){const span=document.createElement('span');span.className='synergy-preview';span.textContent=active.name+' · '+active.description+' ('+active.cooldown/50+'s cooldown)';button.append(span)}
  appendAttunement(button,item);button.addEventListener('click',()=>chooseLoot(i));root.append(button);
 }
 focus(root.firstElementChild||$('skipLoot'));
}
function updateGear(){
 const p=game.player,signature=JSON.stringify([p.equipment,p.magic.ranks]);
 if(signature!==lastGear){lastGear=signature;const root=$('equipmentBuild');root.replaceChildren();
  for(const slot of equipmentSlots){const item=itemById[p.equipment[slot]],chip=document.createElement('span');chip.className='gear-chip';chip.style.setProperty('--rarity',item?rarityColors[item.rarity]:'#777080');chip.textContent=slot.toUpperCase()+': '+(item?item.glyph+' '+item.name:'Empty');chip.title=item?item.description+' '+attunementText(item,p):'No '+slot+' equipped';if(item&&itemAttunements(item.id).some(a=>p.magic.ranks[a.school]>=2)){chip.textContent+=' ✦';chip.classList.add('attuned-gear');}root.append(chip);}
 }
 const chest=game.chests[0],hint=chest?game.chests.length+' treasure chest'+(game.chests.length===1?'':'s')+' · '+Math.ceil(Math.max(0,chest.until-game.tick)/50)+'s remaining':'';if($('treasureHint').textContent!==hint)$('treasureHint').textContent=hint;
}
function choose(index=game.selected){
  if(screen!=='upgrade'||!game.choose(index))return;
  if(game.phase==='upgrade')setScreen('upgrade');else setScreen('play');
}
document.addEventListener('keydown',e=>{
  if(!allowed.has(e.code)||e.altKey||e.ctrlKey||e.metaKey)return;
  if(screen==='profile'){if(e.code==='Escape'){e.preventDefault();setScreen('home')}return;}
  if(screen==='home'||screen==='over'||screen==='victory')return;
  if(e.code==='Escape'&&!e.repeat){
    if(screen==='play'){e.preventDefault();pause();}
    else if(screen==='pause'){e.preventDefault();resume();}
    else if(screen==='confirm'){e.preventDefault();confirmAction=null;setScreen('pause');}
    return;
  }
  if(screen==='loot'||screen==='shop'){return;}
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
  if((e.code==='Space'||e.code==='KeyE')&&!e.repeat)activeKeys.add(e.code);
  keys.add(e.code);
});
document.addEventListener('keyup',e=>{keys.delete(e.code);aimOrder=aimOrder.filter(k=>k!==e.code)});
window.addEventListener('blur',()=>{clearInput();pause();audio.stopVoices()});
document.addEventListener('visibilitychange',()=>{clearInput();if(document.hidden){pause();audio.setPlaying(false);audio.stopVoices()}});
function input(){const result={x:Number(keys.has('KeyD'))-Number(keys.has('KeyA')),y:Number(keys.has('KeyS'))-Number(keys.has('KeyW')),aim:aimVectors[aimOrder[aimOrder.length-1]],boots:activeKeys.has('Space'),relic:activeKeys.has('KeyE')};activeKeys.clear();return result}
function buildUpgrades(){
  const root=$('upgradeCards');root.replaceChildren();$('upgradeLevel').textContent='Level '+game.player.level+' reached';
  const m=game.player.magic,count=learnedSchools(m).length;
  $('upgradeHint').textContent=m.pureOath&&!m.mastery?'Purist oath: only your primary school is available. Reach rank V and level 15 for mastery.':m.mastery?'Exclusive mastery acquired. Your primary school is permanent.':count<2&&game.player.level<SECOND_SCHOOL_LEVEL?'Master your primary school. Secondary school unlocks at level '+SECOND_SCHOOL_LEVEL+'.':count<2?'Choose a secondary school now or keep specializing. Your choice is permanent for this run.':'Your two schools are locked in. Master them and discover compatible synergies.';
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
 const t=game.reportCombat(),top=Object.entries(t.damageBySource).sort((a,b)=>b[1].effective-a[1].effective).slice(0,3);$('combatReport').textContent='Effective DPS '+t.dps.toFixed(1)+' · Projectile hit rate '+Math.round(t.accuracy*100)+'% · Damage taken '+Math.round(t.incoming)+' · Healing '+Math.round(t.healing)+' · Leading damage: '+(top.map(([k,v])=>k+' '+Math.round(v.effective)).join(', ')||'None');
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
function updateBuild(){const m=game.player.magic,signature=JSON.stringify([m.ranks,m.synergies,m.shieldReady,m.primary,m.secondary,m.mastery,Math.min(game.player.level,MASTERY_LEVEL)]);if(signature===lastBuild)return;lastBuild=signature;const root=$('spellBuild');root.replaceChildren();for(const s of schools)if(m.ranks[s.id])root.append(spellChip(s,m.ranks[s.id]));for(const s of synergies)if(m.synergies.includes(s.id))root.append(spellChip(s));for(const mastery of masteries)if(m.mastery===mastery.id)root.append(spellChip(mastery));if(!root.children.length)root.textContent='Choose your starting school';else if(learnedSchools(m).length<2){const lock=document.createElement('span');lock.className='school-lock';lock.textContent=m.mastery?'Pure mastery · second school locked':m.pureOath?'Purist oath · second school locked':game.player.level<SECOND_SCHOOL_LEVEL?'Secondary school · Lv '+SECOND_SCHOOL_LEVEL+' ('+(SECOND_SCHOOL_LEVEL-game.player.level)+' to go)':'Secondary school available · Pure mastery at Lv '+MASTERY_LEVEL+' / rank V';root.append(lock)}else{const lock=document.createElement('span');lock.className='school-lock';const combo=synergyFor(m.primary,m.secondary);lock.textContent='Two schools learned'+(combo&&!m.synergies.includes(combo.id)?' · '+combo.name+' at rank II + II':'');root.append(lock)}if(m.ranks.arcane>=2){const shield=document.createElement('span');shield.className='spell-chip';shield.textContent=m.shieldReady?'Shield ready':'Shield recharging';root.append(shield)}}
function meter(id,value){const percent=Math.round(Math.max(0,Math.min(1,value))*100),node=$(id);node.firstElementChild.style.width=percent+'%';node.setAttribute('aria-valuenow',percent);}
function updateBoss(){const boss=game.boss||game.miniboss,signature=boss?[boss.title||boss.name,Math.ceil(boss.health),boss.bossPhase].join('|'):String(game.endless);if(signature===lastBoss)return;lastBoss=signature;const node=$('bossHud');node.hidden=!boss&&!game.endless;if(boss){$('bossName').textContent=boss.boss?(boss.title||'Ancient Dragon')+' · Phase '+boss.bossPhase+' / 3':boss.title;$('bossHealth').textContent=Math.ceil(boss.health)+' / '+boss.maxHealth;meter('bossMeter',boss.health/boss.maxHealth);$('bossMeter').hidden=false}else{$('bossName').textContent='Endless survival';$('bossHealth').textContent='Dragon defeated';$('bossMeter').hidden=true}}
function updateHud(){
  const sec=game.seconds,upcoming=journey.find(([t])=>t>sec),next=upcoming?upcoming[1]+' '+formatTime(upcoming[0]):game.bossDefeated?'Endless survival':'Dragon encounter';
  if($('nextEncounter').textContent!==next)$('nextEncounter').textContent=next;
  $('runProgress').style.width=Math.min(100,sec/15)+'%';
  const env=environmentById(screen==='home'||screen==='profile'?profile.selection.environment:game.config.environment);if($('biomeName').textContent!==env.name)$('biomeName').textContent=env.name;
  updateBoss();updateGear();updateDungeon();updateMarket();
  updateBuild();const p=game.player,health=Math.ceil(p.health),max=p.maxHealth,maxed=p.level>=config.maxLevel;
  const xp=maxed?'MAX':p.currentExp+' / '+p.expNeeded+' XP';
  const signature=[health,max,p.level,xp,game.seconds,game.kills].join('|');if(signature===lastHud)return;lastHud=signature;
  $('healthText').textContent=health+' / '+max;$('level').textContent=p.level;$('xpText').textContent=xp;
  $('timer').textContent=formatTime(game.seconds);$('kills').textContent=game.kills;
  meter('healthMeter',p.health/max);meter('xpMeter',maxed?1:p.currentExp/p.expNeeded);
}
function step(){
  fx.advance();const running=game.step(input());fx.collect(game.events);fx.collect(game.visualEvents);
  audio.collect(game.events.filter(e=>e.type!=='victory'));audio.collect(game.visualEvents);audio.observe(game);return running;
}
$('betaVersion').textContent=RELEASE;
$('betaReport').addEventListener('click',()=>{
 const report=makeReport(game,{screen,effects:fx.mode,surface,frames,browser:browserFamily(navigator.userAgent),contract:progressSession?.contract||'standard'});
 const output=$('betaReportText');output.value=JSON.stringify(report,null,2);$('betaReportPanel').hidden=false;output.focus();output.select();
});
$('closeBetaReport').addEventListener('click',()=>{$('betaReportPanel').hidden=true;$('betaReport').focus()});
$('copyBetaReport').addEventListener('click',async()=>{const output=$('betaReportText');try{await navigator.clipboard.writeText(output.value);$('betaCopyStatus').textContent='Copied.';}catch{output.focus();output.select();$('betaCopyStatus').textContent='Copy the selected text manually.';}});
function background(){
 const c=game.camera,env=environmentById(screen==='home'||screen==='profile'?profile.selection.environment:game.config.environment);
 art.drawFloor(ctx,env.id,c,game.width,game.height);
 const p=game.player;
 drawLight(ctx,game.width,game.height,p.x+p.width/2-c.x,p.y+p.height/2-c.y,env.id,fx.mode);
}
function shadow(x,y,w,h){ctx.fillStyle='rgba(6,5,11,.43)';ctx.beginPath();ctx.ellipse(x+w/2,y+h*.88,w*.44,h*.18,0,0,Math.PI*2);ctx.fill();}
function bar(x,y,w,h,fraction,color){const f=Math.max(0,Math.min(1,fraction));ctx.fillStyle='#1c1723';ctx.fillRect(x,y,w,h);ctx.fillStyle=color;ctx.fillRect(x,y,w*f,h);}
function updateDungeon(){
 const e=game.dungeon.active,n=game.dungeon.notice,node=$('eventHud');
 node.hidden=!e&&!(n&&n.until>game.tick);
 if(node.hidden)return;
 const def=e?eventById[e.id]:null;
 const heading=e?def.glyph+' '+def.name+' · '+(e.stage==='offered'?'OPTIONAL CHALLENGE':'ACTIVE')+' · '+Math.ceil(Math.max(0,e.until-game.tick)/50)+'s':n.text;
 const objective=e?(e.stage==='offered'?def.description+' '+eventObjective(game):eventObjective(game)):'';
 if($('eventTitle').textContent!==heading)$('eventTitle').textContent=heading;
 if($('eventObjective').textContent!==objective)$('eventObjective').textContent=objective;
 node.style.setProperty('--event-color',def?.color||(n.outcome==='completed'?'#8ae1ae':'#c5ac9b'));
 node.classList.toggle('with-boss',!!(game.boss||game.miniboss));
}
function drawDungeon(c){
 const e=game.dungeon.active;if(!e)return;const def=eventById[e.id];
 function marker(wx,wy,r,glyph,label){
  const x=wx-c.x,y=wy-c.y,sx=Math.max(24,Math.min(game.width-24,x)),sy=Math.max(45,Math.min(game.height-28,y));
  ctx.save();ctx.strokeStyle=def.color;ctx.fillStyle=def.color;ctx.lineWidth=2.5;
  if(sx!==x||sy!==y){ctx.translate(sx,sy);ctx.rotate(Math.atan2(y-sy,x-sx));ctx.beginPath();ctx.moveTo(13,0);ctx.lineTo(-6,-8);ctx.lineTo(-6,8);ctx.closePath();ctx.fill();ctx.restore();return;}
  ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fillStyle=def.color+'22';ctx.fill();ctx.stroke();
  ctx.beginPath();ctx.arc(x,y,Math.max(8,r-7),0,Math.PI*2);ctx.setLineDash([5,6]);ctx.stroke();ctx.setLineDash([]);
  ctx.fillStyle=def.color;ctx.textAlign='center';ctx.font='bold 25px system-ui';ctx.fillText(glyph,x,y+8);
  ctx.font='bold 11px system-ui';ctx.fillText(label,x,y-r-9);ctx.restore();
 }
 if(e.stage==='offered')marker(e.x,e.y,e.radius,def.glyph,'OPTIONAL CHALLENGE');
 else if(e.id==='shrine')marker(e.x,e.y,e.radius,def.glyph,'RITUAL CIRCLE');
 else if(e.id==='anomaly'){for(const rune of e.runes)if(!rune.collected)marker(rune.x,rune.y,21,'✧','RUNE');}
 else if(e.id==='guardian'&&e.target?.health>0)marker(e.target.x+e.target.width/2,e.target.y+e.target.height/2,e.target.width/2+11,'','GUARDIAN');
}
function updateMarket(){
 const p=game.player;
 const text=p.gold+' gold';if($('goldText').textContent!==text)$('goldText').textContent=text;
 for(const [slot,key] of [['boots','Space'],['relic','E']]){
  const a=activeInfo(p,slot,game.tick),el=$(slot+'Active');
  const label=key+' · '+(a?a.name+(a.remaining?' '+Math.ceil(a.remaining/50)+'s':' READY'):'No active skill');
  if(el.textContent!==label)el.textContent=label;
  el.classList.toggle('active-ready',!!a&&!a.remaining);
  el.title=a?a.description:'Equip an item with an active skill';
 }
 const m=game.market.merchant;const hint=m?'Merchant nearby · '+Math.ceil((m.until-game.tick)/50)+'s':'';
 if($('merchantHint').textContent!==hint)$('merchantHint').textContent=hint;
}
function drawMerchant(c){
 const m=game.market.merchant;if(!m)return;
 const x=m.x-c.x,y=m.y-c.y,sx=Math.max(24,Math.min(game.width-24,x)),sy=Math.max(38,Math.min(game.height-24,y));
 ctx.save();ctx.strokeStyle='#ffd277';ctx.fillStyle='#ffd277';ctx.lineWidth=2;
 if(x!==sx||y!==sy){ctx.translate(sx,sy);ctx.rotate(Math.atan2(y-sy,x-sx));ctx.beginPath();ctx.moveTo(13,0);ctx.lineTo(-7,-8);ctx.lineTo(-7,8);ctx.closePath();ctx.fill();}
 else{ctx.beginPath();ctx.arc(x,y,30,0,Math.PI*2);ctx.fillStyle='#78533544';ctx.fill();ctx.stroke();ctx.fillStyle='#ffd277';ctx.textAlign='center';ctx.font='bold 24px system-ui';ctx.fillText('¤',x,y+8);ctx.font='bold 11px system-ui';ctx.fillText('MERCHANT',x,y-39);}
 ctx.restore();
}
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
  background();const c=game.camera,p=game.player;drawTreasure(c);drawDungeon(c);drawMerchant(c);
  for(const h of game.hazards)if(game.visible({x:h.x-h.radius,y:h.y-h.radius,width:h.radius*2,height:h.radius*2},30))drawHazard(ctx,h,c,game.tick,fx.mode);
  for(const e of game.enemies)if(e.action&&game.visible(e,350))drawEnemyWarning(ctx,e,c,game.tick,fx.mode);
  for(const o of game.potions)if(game.visible(o,0)){const px=o.x-c.x,py=o.y-c.y;shadow(px,py,o.width,o.height);ctx.strokeStyle='#8ae1ae99';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(px+o.width/2,py+o.height/2,17,0,Math.PI*2);ctx.stroke();sprite(o.imageSrc,px,py,o.width,o.height,'#82dba5');}
  const variant=environmentById(game.config.environment).id;
  // Stable depth ordering, independent of the simulation's enemy array.
  const actors=[...game.enemies.filter(e=>game.visible(e,0)).map(e=>({entity:e,player:false})),{entity:p,player:true}].sort((a,b)=>a.entity.y+a.entity.height-b.entity.y-b.entity.height);
  const sigilColor=sigils.find(s=>s.id===runSigil)?.color||'#d6b8ff';
  for(const {entity:e,player} of actors){
   const x=e.x-c.x,y=e.y-c.y;
   if(player)drawSigil(ctx,x+e.width/2,y+e.height*.88,24,sigilColor,game.tick,fx.mode);
   else if(e.elite||e.miniboss||e.boss)drawTargetRing(ctx,x,y,e.width,e.height,e.boss?'#ef8978':'#e5c48b',e.boss?'boss':'elite');
   shadow(x,y,e.width,e.height);
   art.drawActor(ctx,player?'Wizard':e.name,x,y,e.width,e.height,{variant,tick:game.tick,animate:fx.mode==='full'&&!e.action&&!(e.freezeUntil>game.tick),flip:player?e.lastDirection?.[0]<0:Math.cos(e.facing||0)<0});
   if(!player){
    drawEnemyStatus(ctx,e,c,game.tick,fx.mode);
    if(e.elite||e.miniboss||e.boss){ctx.fillStyle=e.boss?'#f5a592':'#e5c48b';ctx.font='bold 10px system-ui';ctx.textAlign='center';ctx.fillText(e.boss?'DRAGON':e.eventGuardian?'GUARDIAN':e.miniboss?'MINIBOSS':'ELITE',x+e.width/2,y-13);}
    if(keys.has('KeyQ')||e.eventGuardian||e.miniboss||e.boss)bar(x,y-8,e.width,4,e.health/e.maxHealth,'#e27279');
   }
  }
  const px=p.x-c.x,py=p.y-c.y;
  if(p.magic.shieldReady)drawShield(ctx,px+p.width/2,py+p.height/2,game.tick,fx.mode);
  if(keys.has('KeyQ'))bar(px,py-8,p.width,4,p.health/p.maxHealth,'#e27279');
  for(const s of game.shots)if(game.visible(s,0))drawProjectile(ctx,s,c,game.tick,fx.mode);
  for(const s of game.hostiles)if(game.visible({x:s.x-s.radius,y:s.y-s.radius,width:2*s.radius,height:2*s.radius},20))drawProjectile(ctx,s,c,game.tick,fx.mode,true);
  if(p.frostUntil>game.tick){ctx.strokeStyle='#93d9ff';ctx.lineWidth=2;ctx.beginPath();ctx.arc(px+p.width/2,py+p.height/2,26,0,Math.PI*2);ctx.stroke();}
  if(p.webUntil>game.tick)drawWeb(ctx,px+p.width/2,py+p.height/2,26,true,game.tick,fx.mode);
  fx.draw(ctx,c,p,game.tick);
  if(game.flash&&fx.mode!=='off'){const strength=fx.mode==='full'?.16:.07;ctx.fillStyle='rgba(175,38,54,'+strength+')';ctx.fillRect(0,0,game.width,game.height);}
  ctx.restore();
}
function frame(now){
  if(screen==='play'&&!document.hidden)frames.frame(now);else frames.pause();
  if(screen==='play'&&!document.hidden){
    clock.advance(now,step);dirty=true;
    if(game.phase==='upgrade')setScreen('upgrade');else if(game.phase==='loot')setScreen('loot');else if(game.phase==='shop')setScreen('shop');else if(game.phase==='over')setScreen('over');else if(game.phase==='victory')setScreen('victory');
  }
  if(screen==='play'&&!document.hidden)audio.pump(game.boss||game.miniboss?'boss':environmentById(game.config.environment).id);
  if(dirty){render();updateHud();dirty=false;}
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
