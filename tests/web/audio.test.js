import test from 'node:test';
import assert from 'node:assert/strict';
import {GameAudio,normalizeAudio,loadAudio,saveAudio,castSounds,musicThemes,MAX_VOICES,AUDIO_KEY} from '../../js/audio.js';
class Param{setValueAtTime(v,t){this.value=v}exponentialRampToValueAtTime(v,t){this.value=v}}
class Node{connect(){}disconnect(){}}
class Osc extends Node{constructor(){super();this.frequency=new Param()}start(t){this.startAt=t}stop(t){this.stopAt=t}}
class Context{constructor(){this.state='suspended';this.currentTime=0;this.destination=new Node()}createGain(){return Object.assign(new Node(),{gain:new Param()})}createOscillator(){return new Osc()}async resume(){this.state='running'}async close(){this.state='closed'}}
test('settings validate, clamp, persist and tolerate malformed storage',()=>{
 assert.deepEqual(normalizeAudio({muted:true,sfx:10,music:-1}),{muted:true,sfx:1,music:0});
 assert.deepEqual(loadAudio({getItem:()=>'{bad'}),{muted:false,sfx:.55,music:.25});
 let stored;const storage={setItem:(k,v)=>{assert.equal(k,AUDIO_KEY);stored=v},getItem:()=>stored};
 assert.ok(saveAudio(storage,{muted:true,sfx:.3,music:.4}));assert.deepEqual(loadAudio(storage),{muted:true,sfx:.3,music:.4});
 assert.equal(saveAudio({setItem(){throw Error('quota')}},{}),false);
});
test('context is lazy and unavailable or blocked audio is harmless',async()=>{
 const a=new GameAudio({},Context);assert.equal(a.ctx,null);assert.equal(a.cue('cast','fire'),false);assert.ok(await a.unlock());assert.equal(a.ctx.state,'running');
 const b=new GameAudio({},null);assert.equal(await b.unlock(),false);const c=new GameAudio({muted:true},Context);assert.equal(await c.unlock(),false);assert.equal(c.ctx,null);
 class Blocked extends Context{async resume(){throw Error('blocked')}}assert.equal(await new GameAudio({},Blocked).unlock(),false);
});
test('five cast voices are distinct and repetitive hit sounds rate limited',async()=>{
 const a=new GameAudio({},Context);await a.unlock();assert.equal(new Set(['fire','ice','lightning','necro','arcane'].map(k=>JSON.stringify(castSounds[k]))).size,5);
 assert.ok(a.cue('cast','ice'));assert.equal(a.cue('cast','fire'),false);assert.ok(a.cue('hit'));assert.equal(a.cue('hit'),false);a.ctx.currentTime=.2;assert.ok(a.cue('hit'));
});
test('voice budget is bounded and important cues can replace ordinary sounds',async()=>{
 const a=new GameAudio({},Context);await a.unlock();for(let i=0;i<100;i++)a.tone(castSounds.fire[0],0);
 assert.equal(a.voices.size,MAX_VOICES);assert.ok(a.cue('warning'));assert.equal(a.voices.size,MAX_VOICES);assert.ok([...a.voices].some(v=>v.priority));
 const v=[...a.voices][0];v.oscillator.onended();assert.equal(a.voices.size,MAX_VOICES-1);
});
test('music changes theme, stops on pause, and does not backlog on resume',async()=>{
 const a=new GameAudio({},Context);await a.unlock();assert.equal(Object.keys(musicThemes).length,4);a.setPlaying(true);a.pump('crypt');assert.equal(a.mode,'crypt');assert.ok(a.voices.size>0);
 a.pump('boss');assert.equal(a.mode,'boss');assert.ok(a.voices.size<=3);a.setPlaying(false);assert.equal(a.voices.size,0);a.ctx.currentTime=500;a.pump('frost');assert.equal(a.voices.size,0);
 a.setPlaying(true);a.pump('frost');assert.ok(a.next>500);assert.ok(a.next<502);
});
test('mute and independent channels stop their own voices',async()=>{
 const a=new GameAudio({},Context);await a.unlock();a.setPlaying(true);a.pump('forge');a.cue('hurt');assert.ok([...a.voices].some(v=>v.bus==='music'));
 a.update({...a.settings,music:0});assert.ok([...a.voices].every(v=>v.bus==='sfx'));a.update({...a.settings,muted:true});assert.equal(a.voices.size,0);assert.equal(a.cue('hurt'),false);await a.dispose();assert.equal(a.ctx.state,'closed');
});
test('warning, boss and challenge cues fire once per observed transition',async()=>{
 const a=new GameAudio({},Context);await a.unlock();const enemy={action:{kind:'orc-windup'}},hazard={activeAt:30,x:0,y:0,radius:40},g={enemies:[enemy],hazards:[hazard],visible:()=>true,tick:1,boss:null,miniboss:null,dungeon:{active:{id:'altar',stage:'offered',serial:1}}};
 a.observe(g);const n=a.voices.size;assert.ok(n>0);a.ctx.currentTime=2;a.observe(g);assert.equal(a.voices.size,n);enemy.action={kind:'orc-windup'};g.dungeon.active.stage='active';a.observe(g);assert.ok(a.voices.size>n);
 a.reset();assert.equal(a.voices.size,0);assert.equal(a.last.size,0);
});
