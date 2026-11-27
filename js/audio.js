// Original synthesized audio, isolated from the deterministic simulation.
// All music and sound effects are generated from oscillators; no external assets.
export const AUDIO_KEY='wizard-shooter.audio.v1';
export const defaults={muted:false,sfx:.55,music:.25};
const clamp=v=>Math.max(0,Math.min(1,v));
export function normalizeAudio(raw){return {muted:typeof raw?.muted==='boolean'?raw.muted:defaults.muted,sfx:Number.isFinite(raw?.sfx)?clamp(raw.sfx):defaults.sfx,music:Number.isFinite(raw?.music)?clamp(raw.music):defaults.music}}
export function loadAudio(storage){try{return normalizeAudio(JSON.parse(storage?.getItem(AUDIO_KEY)||'null'))}catch{return normalizeAudio(null)}}
export function saveAudio(storage,settings){try{if(!storage)return false;storage.setItem(AUDIO_KEY,JSON.stringify(normalizeAudio(settings)));return true}catch{return false}}
// [waveform, initial Hz, final Hz, duration s, amplitude, optional delay s]
export const castSounds={
 fire:[['sawtooth',145,65,.13,.14],['triangle',440,110,.09,.13]],
 ice:[['sine',1150,660,.12,.12],['triangle',1500,1050,.08,.08,.035]],
 lightning:[['square',380,95,.065,.075],['sawtooth',890,180,.085,.06,.022]],
 necro:[['triangle',165,82,.18,.16],['sine',220,110,.21,.10]],
 arcane:[['sine',660,990,.11,.14],['triangle',990,1320,.10,.08,.045]],
 untrained:[['triangle',440,220,.10,.13]]
};
const cues={
 hit:[['triangle',230,85,.055,.08]],
 kill:[['triangle',150,70,.10,.09]],
 hurt:[['sawtooth',130,48,.19,.18],['triangle',75,48,.17,.13]],
 heal:[['sine',440,660,.12,.10],['sine',660,880,.10,.08,.07]],
 burst:[['triangle',105,42,.18,.16]],
 chain:[['square',700,240,.05,.07]],
 shield:[['sine',1250,380,.20,.12],['triangle',660,440,.12,.08]],
 freeze:[['sine',1800,850,.16,.11]],
 crit:[['triangle',1100,600,.12,.13]],
 block:[['square',220,150,.07,.06]],
 teleport:[['sine',300,1200,.16,.13]],
 warning:[['triangle',330,220,.16,.18],['triangle',330,180,.16,.15,.18]],
 hazard:[['sine',750,410,.15,.12]],
 boss:[['sawtooth',110,55,.35,.12],['triangle',165,82,.32,.12,.12]],
 phase:[['triangle',165,330,.24,.14],['triangle',220,440,.25,.12,.15]],
 upgrade:[['sine',440,440,.13,.14],['sine',554,554,.13,.14,.10],['sine',659,880,.23,.13,.20]],
 loot:[['triangle',523,523,.13,.12],['triangle',659,659,.13,.12,.09],['sine',784,1047,.20,.12,.18]],
 shop:[['sine',392,523,.17,.10],['triangle',587,784,.18,.10,.10]],
 encounter:[['triangle',392,294,.18,.14],['sine',523,392,.18,.12,.13]],
 success:[['sine',523,523,.14,.12],['sine',659,659,.14,.12,.11],['triangle',784,1047,.28,.13,.22]],
 failed:[['triangle',330,220,.23,.10],['triangle',196,130,.23,.10,.13]],
 defeat:[['triangle',220,165,.27,.13],['sine',165,110,.40,.14,.23]],
 victory:[['triangle',392,392,.17,.14],['triangle',523,523,.17,.14,.14],['triangle',659,659,.19,.14,.28],['sine',784,1047,.45,.15,.42]]
};
const gaps={hit:90,kill:120,cast:65,heal:550,burst:150,chain:100,freeze:220,crit:180,block:180,teleport:180,hurt:150,shield:200,warning:500,hazard:450,boss:900,phase:500,encounter:500,success:500,failed:500};
const urgent=new Set(['hurt','shield','warning','hazard','boss','phase','victory','defeat','upgrade','loot','shop','encounter','success','failed']);
export const MAX_VOICES=32;
export const musicThemes={
 crypt:{beat:.82,notes:[45,48,52,50,45,43,40,43],bass:[33,33,36,31],wave:'triangle'},
 frost:{beat:.95,notes:[50,57,60,57,48,55,60,55],bass:[38,38,36,36],wave:'sine'},
 forge:{beat:.67,notes:[43,46,50,49,43,41,46,41],bass:[31,31,29,29],wave:'triangle'},
 boss:{beat:.37,notes:[38,38,41,38,44,43,41,36],bass:[26,26,29,24],wave:'triangle'}
};
const hz=midi=>440*Math.pow(2,(midi-69)/12);
export class GameAudio{
 constructor(settings=defaults,Context=null){this.settings=normalizeAudio(settings);this.Context=Context;this.ctx=null;this.voices=new Set();this.last=new Map();this.actions=new WeakMap();this.hazards=new WeakSet();this.mode=null;this.step=0;this.next=0;this.playing=false;this.eventKey='';this.bossKey='';this.notice=null;this.disposed=false}
 async unlock(){
  if(this.disposed||!this.Context||this.settings.muted)return false;
  try{
   if(!this.ctx){this.ctx=new this.Context();this.master=this.ctx.createGain();this.sfx=this.ctx.createGain();this.music=this.ctx.createGain();this.sfx.connect(this.master);this.music.connect(this.master);if(this.ctx.createDynamicsCompressor){const limiter=this.ctx.createDynamicsCompressor();limiter.threshold.value=-12;limiter.knee.value=12;limiter.ratio.value=12;limiter.attack.value=.003;limiter.release.value=.15;this.master.connect(limiter);limiter.connect(this.ctx.destination);}else this.master.connect(this.ctx.destination);this.update(this.settings);}
   if(this.ctx.state!=='running')await this.ctx.resume();
   return this.ctx.state==='running';
  }catch{return false}
 }
 update(settings){
  this.settings=normalizeAudio(settings);
  if(!this.ctx)return;
  const t=this.ctx.currentTime;this.master.gain.setValueAtTime(this.settings.muted?0:.6,t);this.sfx.gain.setValueAtTime(this.settings.sfx,t);this.music.gain.setValueAtTime(this.settings.music,t);
  if(this.settings.muted)this.stopVoices();
  if(!this.settings.music)this.stopVoices('music');
  if(!this.settings.sfx)this.stopVoices('sfx');
 }
 get ready(){return !!this.ctx&&this.ctx.state==='running'&&!this.settings.muted&&!this.disposed}
 tone(spec,at,bus='sfx',priority=false){
  if(!this.ready||!this.settings[bus])return false;
  if(this.voices.size>=MAX_VOICES){
   if(!priority)return false;
   const victim=[...this.voices].find(v=>v.bus==='music'||!v.priority);if(!victim)return false;this.stopVoice(victim);
  }
  const [wave,from,to,duration,amp,delay=0]=spec,t=Math.max(this.ctx.currentTime,at)+delay,end=t+duration;
  const oscillator=this.ctx.createOscillator(),gain=this.ctx.createGain();
  oscillator.type=wave;oscillator.frequency.setValueAtTime(from,t);oscillator.frequency.exponentialRampToValueAtTime(Math.max(1,to),end);
  gain.gain.setValueAtTime(.0001,t);gain.gain.exponentialRampToValueAtTime(Math.max(.0001,amp),t+Math.min(.025,duration*.3));gain.gain.exponentialRampToValueAtTime(.0001,end);
  oscillator.connect(gain);gain.connect(this[bus]);const voice={oscillator,gain,bus,priority};this.voices.add(voice);
  oscillator.onended=()=>{this.voices.delete(voice);oscillator.disconnect();gain.disconnect()};
  oscillator.start(t);oscillator.stop(end+.01);return true;
 }
 stopVoice(v){this.voices.delete(v);try{v.oscillator.stop();v.oscillator.disconnect();v.gain.disconnect()}catch{}}
 stopVoices(bus){for(const v of [...this.voices])if(!bus||v.bus===bus)this.stopVoice(v)}
 cue(type,school){
  if(!this.ready||!this.settings.sfx)return false;
  const specs=type==='cast'?(castSounds[school]||castSounds.untrained):cues[type];if(!specs)return false;
  const now=this.ctx.currentTime;
  if(now-(this.last.get(type)??-Infinity)<(gaps[type]||0)/1000)return false;
  this.last.set(type,now);let played=false;
  for(const spec of specs)played=this.tone(spec,now,'sfx',urgent.has(type))||played;
  return played;
 }
 collect(events){for(const e of events)this.cue(e.type,e.visualSchool||e.school)}
 observe(g){
  if(!this.ready||!this.settings.sfx)return;
  for(const e of g.enemies){const a=e.action;if(a?.kind.endsWith('windup')&&g.visible(e,80)&&this.actions.get(e)!==a){this.actions.set(e,a);this.cue('warning')}}
  for(const h of g.hazards)if(!this.hazards.has(h)){this.hazards.add(h);if(h.activeAt>g.tick&&g.visible({x:h.x-h.radius,y:h.y-h.radius,width:h.radius*2,height:h.radius*2},50))this.cue('hazard')}
  const boss=g.boss||g.miniboss,key=boss?(boss.title||boss.name):'';
  if(key&&key!==this.bossKey)this.cue('boss');this.bossKey=key;
  const e=g.dungeon?.active,eventKey=e?e.id+':'+e.stage+':'+e.serial:'';
  if(eventKey&&eventKey!==this.eventKey)this.cue('encounter');this.eventKey=eventKey;
  const n=g.dungeon?.notice;if(n&&n!==this.notice){this.notice=n;if(n.outcome==='completed')this.cue('success');else if(n.outcome==='failed')this.cue('failed')}
 }
 setPlaying(playing){if(this.playing===playing)return;this.playing=playing;this.stopVoices();this.next=0;this.mode=null}
 reset(){this.stopVoices();this.last.clear();this.actions=new WeakMap();this.hazards=new WeakSet();this.eventKey='';this.bossKey='';this.notice=null;this.next=0;this.mode=null;this.step=0}
 // Short look-ahead only; no timers, no accumulated scheduling on tab suspension.
 pump(theme){
  if(!this.playing||!this.ready||!this.settings.music)return;
  theme=Object.hasOwn(musicThemes,theme)?theme:'crypt';const t=this.ctx.currentTime,pattern=musicThemes[theme];
  if(theme!==this.mode){this.stopVoices('music');this.mode=theme;this.next=t+.02;this.step=0}
  if(this.next<t)this.next=t+.02;
  if(this.next>t+.10)return;
  const i=this.step++,note=pattern.notes[i%pattern.notes.length],b=pattern.beat;
  this.tone([pattern.wave,hz(note),hz(note),b*.82,.085],this.next,'music');
  if(i%2===0){const bass=pattern.bass[Math.floor(i/2)%pattern.bass.length];this.tone(['sine',hz(bass),hz(bass),b*1.8,.10],this.next,'music')}
  if(theme==='boss'&&i%2===0)this.tone(['triangle',85,38,.15,.09],this.next,'music');
  this.next+=b;
 }
 async dispose(){this.disposed=true;this.stopVoices();if(this.ctx)try{await this.ctx.close()}catch{}}
}
