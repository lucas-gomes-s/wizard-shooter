import {schools,synergies,masteries} from './magic.js';
import {equipment} from './equipment.js';
import {dungeonEvents} from './dungeon-events.js';
export const PROFILE_KEY='wizard-shooter.profile.v1';
const ids=xs=>xs.map(x=>x.id);
const known={schools:ids(schools),items:ids(equipment),fusions:ids(synergies),masteries:ids(masteries),events:ids(dungeonEvents),winningSchools:ids(schools),contracts:['purist','nomad','dry']};
export const contracts=[
 {id:'standard',name:'Standard expedition',description:'All normal mechanics available.',requires:null},
 {id:'purist',name:'Purist oath',description:'Secondary schools are forbidden. Pure mastery remains available.',requires:'master'},
 {id:'nomad',name:'Merchantless expedition',description:'No merchants or gold. Treasure and events remain available.',requires:'treasure'},
 {id:'dry',name:'Dry pilgrimage',description:'No naturally spawning health potions. Equipment, merchants and magic healing still work.',requires:'dragon'}
];
export const sigils=[
 {id:'violet',name:'Violet sigil',color:'#d6b8ff',requires:null},
 {id:'ember',name:'Ember sigil',color:'#ff9767',requires:'survivor'},
 {id:'jade',name:'Jade sigil',color:'#84e8af',requires:'fusion'},
 {id:'gold',name:'Golden sigil',color:'#ffd277',requires:'dragon'},
 {id:'frost',name:'Frost sigil',color:'#a9e8ff',requires:'collector'}
];
export const achievements=[
 {id:'first',name:'First expedition',description:'Record one run.',check:p=>p.runs>=1},
 {id:'survivor',name:'Into the depths',description:'Survive ten minutes.',check:p=>p.bestTicks>=30000},
 {id:'veteran',name:'Beyond the abyss',description:'Survive twenty minutes.',check:p=>p.bestTicks>=60000},
 {id:'slayer',name:'Monster hunter',description:'Defeat 1,000 monsters across runs.',check:p=>p.kills>=1000},
 {id:'treasure',name:'Treasure seeker',description:'Equip six distinct items.',check:p=>p.items.length>=6},
 {id:'collector',name:'Collector',description:'Equip all 24 items across runs.',check:p=>p.items.length>=24},
 {id:'fusion',name:'Spellweaver',description:'Learn your first fusion.',check:p=>p.fusions.length>=1},
 {id:'allfusions',name:'Grand spellweaver',description:'Discover all ten fusions.',check:p=>p.fusions.length>=10},
 {id:'master',name:'Master of one',description:'Discover a pure-school mastery.',check:p=>p.masteries.length>=1},
 {id:'allmasteries',name:'Archmagister',description:'Discover all five masteries.',check:p=>p.masteries.length>=5},
 {id:'explorer',name:'Dungeon explorer',description:'Complete every type of optional event.',check:p=>p.events.length>=6},
 {id:'dragon',name:'Dragon slayer',description:'Defeat the Ancient Dragon.',check:p=>p.wins>=1},
 {id:'five',name:'Five paths',description:'Win with every starting school.',check:p=>p.winningSchools.length>=5},
 {id:'oath',name:'Oathkeeper',description:'Win with an optional contract.',check:p=>p.contracts.length>=1}
];
export function freshProfile(){return {version:1,runs:0,wins:0,kills:0,ticks:0,bestTicks:0,bestKills:0,bestLevel:0,schools:[],items:[],fusions:[],masteries:[],events:[],winningSchools:[],contracts:[],achievements:[],selection:{contract:'standard',sigil:'violet'}}}
const count=v=>Number.isSafeInteger(v)&&v>=0?v:0;
export function normalizeProfile(raw){
 const p=freshProfile();if(!raw||raw.version!==1)return p;
 for(const k of ['runs','wins','kills','ticks','bestTicks','bestKills','bestLevel'])p[k]=count(raw[k]);
 p.wins=Math.min(p.runs,p.wins);
 for(const [key,allowed] of Object.entries(known))p[key]=Array.isArray(raw[key])?[...new Set(raw[key].filter(x=>allowed.includes(x)))]:[];
 p.achievements=achievements.filter(a=>a.check(p)).map(a=>a.id);
 p.selection.contract=available(contracts,raw.selection?.contract,p)?raw.selection.contract:'standard';
 p.selection.sigil=available(sigils,raw.selection?.sigil,p)?raw.selection.sigil:'violet';
 return p;
}
export function available(catalog,id,p){const entry=catalog.find(x=>x.id===id);return !!entry&&(!entry.requires||p.achievements.includes(entry.requires))}
export function loadProfile(storage){try{return {profile:normalizeProfile(JSON.parse(storage?.getItem(PROFILE_KEY)||'null')),saved:!!storage}}catch{return {profile:freshProfile(),saved:false}}}
export function saveProfile(storage,p){try{if(!storage)return false;storage.setItem(PROFILE_KEY,JSON.stringify(p));return true}catch{return false}}
export function runConfig(base,contract){return {...base,...(contract==='nomad'?{economyEnabled:false}:{}),...(contract==='dry'?{potionInfo:[]}:{}),pureOath:contract==='purist'}}
export function newProgressSession(contract='standard'){return {contract,tick:0,kills:0,recorded:false,won:false}}
function addKnown(p,key,values){for(const v of values)if(known[key].includes(v)&&!p[key].includes(v))p[key].push(v)}
// Victory can be checkpointed immediately, then endless stats added later without another run/win.
export function recordProgress(p,g,session){
 if(!session||g.tick<=0||!g.player.magic.primary)return [];
 const old=new Set(p.achievements),player=g.player,m=player.magic;
 if(!session.recorded){session.recorded=true;p.runs++;}
 p.ticks+=Math.max(0,g.tick-session.tick);p.kills+=Math.max(0,g.kills-session.kills);
 session.tick=Math.max(session.tick,g.tick);session.kills=Math.max(session.kills,g.kills);
 p.bestTicks=Math.max(p.bestTicks,g.tick);p.bestKills=Math.max(p.bestKills,g.kills);p.bestLevel=Math.max(p.bestLevel,player.level);
 addKnown(p,'schools',Object.keys(m.ranks).filter(id=>m.ranks[id]>0));
 addKnown(p,'items',[...Object.values(player.equipment),...g.lootHistory.map(x=>x.id),...g.market.history.map(x=>x.id)]);
 addKnown(p,'fusions',m.synergies);addKnown(p,'masteries',[m.mastery]);addKnown(p,'events',g.dungeon.history.filter(x=>x.outcome==='completed').map(x=>x.id));
 if(g.bossDefeated&&!session.won){session.won=true;p.wins++;addKnown(p,'winningSchools',[m.primary]);addKnown(p,'contracts',[session.contract]);}
 p.achievements=achievements.filter(a=>a.check(p)).map(a=>a.id);
 return p.achievements.filter(id=>!old.has(id));
}
