import test from 'node:test';
import assert from 'node:assert/strict';
import {FrameStats,makeReport,browserFamily,RELEASE} from '../../js/beta-report.js';
test('bounded rolling frame statistics omit pauses and long gaps',()=>{
 const f=new FrameStats(3);for(const t of [0,10,30,60,100])f.frame(t);
 assert.deepEqual(f.summary(),{samples:3,meanMs:30,p95Ms:40,fps:33});
 f.pause();f.frame(5000);f.frame(5020);assert.equal(f.summary().samples,3);f.reset();assert.equal(f.summary().samples,0);
});
test('report is a whitelisted snapshot, not profile or browser identifiers',()=>{
 const g={config:{environment:'forge'},tick:100,kills:2,player:{level:1,health:90,magic:{ranks:{fire:1}},equipment:{staff:null}},enemies:[],shots:[],hostiles:[],hazards:[],private:'secret'};
 const r=makeReport(g,{screen:'play',effects:'full',surface:{width:800,height:600,dpr:1},frames:new FrameStats(),browser:browserFamily('Mozilla Chrome/123 Safari/1')});
 assert.equal(r.version,RELEASE);assert.equal(r.browser,'Chromium');assert.equal(r.elapsedSeconds,2);assert.equal(r.environment,'forge');assert.equal(r.private,undefined);assert.equal(r.profile,undefined);r.schools.fire=5;assert.equal(g.player.magic.ranks.fire,1);
});
