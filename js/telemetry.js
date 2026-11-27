// Aggregate counters, not a growing event log. Separate from capped presentation events.
export function freshTelemetry(){
 return {casts:0,bolts:0,boltsHit:0,directHits:0,damage:0,overkill:0,damageBySource:{},incoming:0,prevented:0,incomingBySource:{},healing:0,healingBySource:{},selfDamage:0,selfDamageBySource:{},windows:{}};
}
function bucket(map,key){return map[key]??(map[key]={effective:0,overkill:0,hits:0})}
function windowAt(t,tick){const key=Math.floor(Math.max(0,tick-1)/15000)*5;return t.windows[key]??(t.windows[key]={damage:0,incoming:0,healing:0,casts:0,bolts:0,boltsHit:0})}
export function trackDamage(t,tick,source,amount,health){
 const effective=Math.min(amount,health),overkill=amount-effective,b=bucket(t.damageBySource,source);
 t.damage+=effective;t.overkill+=overkill;b.effective+=effective;b.overkill+=overkill;b.hits++;windowAt(t,tick).damage+=effective;
}
export function trackIncoming(t,tick,source,requested,applied,prevented=0){
 const b=t.incomingBySource[source]??(t.incomingBySource[source]={requested:0,applied:0,prevented:0,hits:0});
 b.requested+=requested;b.applied+=applied;b.prevented+=prevented;b.hits++;
 t.incoming+=applied;t.prevented+=prevented;windowAt(t,tick).incoming+=applied;
}
export function trackHeal(t,tick,source,amount){if(amount<=0)return;t.healing+=amount;t.healingBySource[source]=(t.healingBySource[source]||0)+amount;windowAt(t,tick).healing+=amount}
export function trackCost(t,source,amount){if(amount<=0)return;t.selfDamage+=amount;t.selfDamageBySource[source]=(t.selfDamageBySource[source]||0)+amount}
export function trackCast(t,tick,bolts){t.casts++;t.bolts+=bolts;const w=windowAt(t,tick);w.casts++;w.bolts+=bolts}
export function trackHit(t,tick,shot){t.directHits++;if(!shot.telemetryHit&&shot.telemetrySpawnTick!==undefined){shot.telemetryHit=true;t.boltsHit++;windowAt(t,shot.telemetrySpawnTick).boltsHit++}}
export function telemetrySummary(t,seconds){return {...t,seconds,dps:seconds?t.damage/seconds:0,accuracy:t.bolts?t.boltsHit/t.bolts:0,hitsPerCast:t.casts?t.directHits/t.casts:0}}
