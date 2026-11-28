import * as config from '../js/data.js';
import {benchmarkBuilds} from '../js/build-benchmark.js';
import {writeFileSync} from 'node:fs';
const [secondsArg='600',countArg='1',firstArg='1',output='']=process.argv.slice(2);
const seconds=Number(secondsArg),count=Number(countArg),first=Number(firstArg);
if(!Number.isInteger(seconds)||seconds<1||seconds>3600||!Number.isInteger(count)||count<1||count>100||!Number.isSafeInteger(first)||first<1)throw Error('Usage: npm run balance:waves -- seconds seedCount firstSeed output.json');
const seeds=Array.from({length:count},(_,i)=>first+i);
const result={seconds,seeds,variants:{}};
for(const [name,enabled] of [['classic',false],['waves',true]]){
 const rows=benchmarkBuilds({...config,waveDirector:enabled},{seconds,seeds,decisionTicks:5});
 const sum=f=>rows.reduce((n,r)=>n+f(r),0),samples=sum(r=>r.pacing.samples);
 const summary={runs:rows.length,completed:rows.filter(r=>r.seconds>=seconds).length,wins:rows.filter(r=>r.phase==='victory').length,meanSeconds:sum(r=>r.seconds)/rows.length,meanVisible:sum(r=>r.pacing.visibleSum)/Math.max(1,samples),quietFraction:sum(r=>r.pacing.quietSeconds)/Math.max(1,samples),crowdedFraction:sum(r=>r.pacing.crowdedSeconds)/Math.max(1,samples),meanLevel:sum(r=>r.level)/rows.length,meanMaxUpgradeGap:sum(r=>r.pacing.maxUpgradeGapSeconds)/rows.length};
 result.variants[name]={summary,rows};console.log(name,summary);
}
if(output)writeFileSync(output,JSON.stringify(result,null,2)+'\n');else console.log(JSON.stringify(result,null,2));
