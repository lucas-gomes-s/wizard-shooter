import * as config from '../js/data.js';
import {forecast,referenceDps} from '../js/balance.js';
import {benchmark} from '../js/balance-bot.js';
const args=process.argv.slice(2), seconds=Number(args[0]||180), n=Number(args[1]||3), decisionTicks=Number(args[2]||5);
if(!Number.isInteger(seconds)||seconds<1||seconds>3600||!Number.isInteger(n)||n<1||n>100||!Number.isInteger(decisionTicks)||decisionTicks<1||decisionTicks>50)throw Error('Usage: npm run balance -- [seconds 1..3600] [seeds 1..100] [decision ticks 1..50]');
console.table(forecast(config).map(r=>({minute:r.minute,availableXP:r.totalXP,level25:r.levels[0],level50:r.levels[1],level75:r.levels[2],HPperSecond:r.hpPerSecond,referenceDPS:Math.round(referenceDps(r.levels[1]).dps)})));
const results=benchmark(config,{seconds,seeds:Array.from({length:n},(_,i)=>i+1),decisionTicks});
console.table(results.map(({build,...r})=>r));
console.log(JSON.stringify({seconds,seeds:n,decisionTicks,survivedOrWon:results.filter(r=>r.seconds>=seconds||r.phase==='victory').length,victories:results.filter(r=>r.phase==='victory').length,total:results.length,results},null,2));
