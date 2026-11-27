import * as config from '../js/data.js';
import {benchmarkBuilds,summarizeBuilds} from '../js/build-benchmark.js';
import {writeFileSync} from 'node:fs';
const [secondsArg='1800',countArg='2',startArg='1',output='']=process.argv.slice(2);
const seconds=Number(secondsArg),count=Number(countArg),start=Number(startArg);
if(!Number.isInteger(seconds)||seconds<1||seconds>3600||!Number.isInteger(count)||count<1||count>100||!Number.isSafeInteger(start)||start<1||start+count>4294967296)throw Error('Usage: npm run balance:compare -- [seconds] [seed count] [first seed] [output.json]');
const seeds=Array.from({length:count},(_,i)=>start+i);
const report={seconds,seeds,decisionTicks:5,variants:{}};
for(const [name,combatBalance] of [['baseline',{}],['candidate',config.combatBalance]]){
 const results=benchmarkBuilds({...config,combatBalance},{seconds,seeds,decisionTicks:5});
 const summary={runs:results.length,wins:results.filter(r=>r.phase==='victory').length,dragon:results.filter(r=>r.reachedDragon).length,blocked:results.filter(r=>r.phase==='blocked').length,meanSeconds:results.reduce((s,r)=>s+r.seconds,0)/results.length,builds:summarizeBuilds(results)};
 report.variants[name]={combatBalance,summary,results};
 console.log(name,JSON.stringify({...summary,builds:undefined}));
}
if(output)writeFileSync(output,JSON.stringify(report,null,2)+'\n');else console.log(JSON.stringify(report,null,2));
