import * as config from '../js/data.js';
import {benchmarkBuilds,summarizeBuilds} from '../js/build-benchmark.js';
import {writeFileSync} from 'node:fs';
const [secondsArg='1800',seedsArg='5',ticksArg='5',output='']=process.argv.slice(2);
const seconds=Number(secondsArg),n=Number(seedsArg),decisionTicks=Number(ticksArg);
if(!Number.isInteger(seconds)||seconds<1||seconds>3600||!Number.isInteger(n)||n<1||n>100||!Number.isInteger(decisionTicks)||decisionTicks<1||decisionTicks>50)throw Error('Usage: npm run balance:builds -- [seconds 1..3600] [seeds per build 1..100] [decision ticks 1..50] [optional output.json]');
const seeds=Array.from({length:n},(_,i)=>i+1);
const results=benchmarkBuilds(config,{seconds,seeds,decisionTicks});
const summary=summarizeBuilds(results);
console.table(summary.map(r=>({...r,secondary:r.secondary??'pure',medianSeconds:Math.round(r.medianSeconds),meanSeconds:Math.round(r.meanSeconds),medianFusionAt:r.medianFusionAt===null?null:Math.round(r.medianFusionAt),meanLevel:r.meanLevel.toFixed(1),meanKills:Math.round(r.meanKills),meanMaxEnemies:r.meanMaxEnemies.toFixed(1)})));
const report={seconds,seeds,decisionTicks,total:results.length,wins:results.filter(r=>r.phase==='victory').length,blocked:results.filter(r=>r.phase==='blocked').length,summary,results};
if(output){writeFileSync(output,JSON.stringify(report,null,2)+'\n');console.log('Saved '+output)}
else console.log(JSON.stringify(report,null,2));
