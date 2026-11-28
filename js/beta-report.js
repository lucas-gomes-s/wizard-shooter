// Bounded, local diagnostics. No identifiers, URLs, storage, or automatic uploads.
export const RELEASE='1.19.0-beta.1';
export class FrameStats{
 constructor(cap=600){this.cap=cap;this.samples=[];this.last=null}
 reset(){this.samples=[];this.last=null}
 frame(now){if(this.last!==null){const delta=now-this.last;if(delta>0&&delta<1000){this.samples.push(delta);if(this.samples.length>this.cap)this.samples.shift()}}this.last=now}
 pause(){this.last=null}
 summary(){const a=[...this.samples].sort((a,b)=>a-b),n=a.length,mean=n?a.reduce((s,x)=>s+x,0)/n:0;return {samples:n,meanMs:Math.round(mean*100)/100,p95Ms:n?Math.round(a[Math.ceil(n*.95)-1]*100)/100:0,fps:mean?Math.round(1000/mean):0}}
}
export function makeReport(g,{screen,effects,surface,frames,browser,contract='standard'}){
 const p=g.player;
 return {version:RELEASE,screen,environment:g.config.environment||'crypt',pacing:g.config.waveDirector?'waves':'classic',contract,elapsedSeconds:Math.floor(g.tick/50),level:p.level,kills:g.kills,health:Math.round(p.health*100)/100,schools:{...p.magic.ranks},equipment:{...p.equipment},effects,viewport:{width:Math.round(surface.width),height:Math.round(surface.height),dpr:surface.dpr},browser,counts:{enemies:g.enemies.length,shots:g.shots.length,hostiles:g.hostiles.length,hazards:g.hazards.length},performance:frames.summary()};
}
export function browserFamily(ua){return /Firefox\//.test(ua)?'Firefox':/Edg\//.test(ua)?'Edge':/Chrome\//.test(ua)?'Chromium':/Safari\//.test(ua)?'Safari':'Other'}
