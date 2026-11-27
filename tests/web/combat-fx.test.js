import test from 'node:test';
import assert from 'node:assert/strict';
import * as config from '../../js/data.js';
import {Game} from '../../js/simulation.js';
import {initEnemy,stepEnemy} from '../../js/enemies.js';
import {CombatFX,FX_LIMITS,webGeometry,boltGeometry,drawWeb,drawHazard,drawEnemyWarning,drawEnemyStatus,drawShield,drawProjectile} from '../../js/combat-fx.js';
const make=()=>new Game(config,()=>.01);
const enemy=(name,x=350,y=280)=>initEnemy(config.monsters.find(m=>m.name===name),x,y,0);
const shot=(x,y)=>({x,y,width:5,height:5,vx:0,vy:0,damage:10,remaining:1});
test('web geometry fits the actual hazard radius',()=>{
 const {rays,loops}=webGeometry(46);
 assert.equal(rays.length,8);assert.equal(loops.length,4);
 for(const [x,y] of rays)assert.ok(Math.abs(Math.hypot(x,y)-46)<1e-8);
 assert.deepEqual(loops[3],rays);
});
test('lightning paths preserve endpoints and are deterministic',()=>{
 const p=boltGeometry(3,4,100,90,11);
 assert.deepEqual(p[0],[3,4]);assert.deepEqual(p.at(-1),[100,90]);assert.deepEqual(p,boltGeometry(3,4,100,90,11));assert.notDeepEqual(p,boltGeometry(3,4,100,90,12));
});
test('effects mode bounds particle count and prioritizes major effects',()=>{
 for(const mode of ['off','reduced','full']){
  const fx=new CombatFX(mode,()=>.5);
  for(let i=0;i<500;i++)fx.add({type:'spark',x:0,y:0,life:5});
  assert.equal(fx.items.length,FX_LIMITS[mode]);
  fx.add({type:'burst',x:0,y:0,life:10,priority:true});
  assert.equal(fx.items.length,FX_LIMITS[mode]);
  if(mode!=='off')assert.ok(fx.items.some(q=>q.type==='burst'));
  fx.setMode('off');assert.equal(fx.items.length,0);
 }
});
test('visual effects expire and do not mutate source events',()=>{
 const fx=new CombatFX('full',()=>.5),event={type:'chain',x:10,y:10,fromX:0,fromY:0,school:'lightning'};
 const before=JSON.stringify(event);fx.collect([event]);assert.equal(JSON.stringify(event),before);assert.ok(fx.items.length);
 for(let i=0;i<50;i++)fx.advance();assert.equal(fx.items.length,0);
});
test('critical, block and freeze notifications are separate from gameplay events',()=>{
 const g=make(),e=enemy('Knight');e.health=e.maxHealth=1000;e.maxSpeed=0;e.facing=Math.PI;
 g.player.magic.ranks.lightning=1;g.player.magic.ranks.ice=5;e.frostHits=2;
 const s=shot(e.x,e.y);s.vx=8;s.x-=8;g.enemies.push(e);g.shots.push(s);g.step();
 assert.deepEqual(g.visualEvents.map(e=>e.type),['crit','block','freeze']);
 assert.equal(g.events.filter(e=>e.type==='hit').length,1);assert.equal(e.health,993);
 g.reset();assert.deepEqual(g.visualEvents,[]);
});
test('teleport and phase notifications use actual locations and new phase',()=>{
 const g=make(),r=enemy('Reaper',100,280);g.tick=50;stepEnemy(g,r);const a=r.action;
 g.tick=a.until;stepEnemy(g,r);const events=g.visualEvents.filter(e=>e.type==='teleport');
 assert.equal(events.length,2);assert.equal(events[1].x,a.x);assert.equal(events[1].y,a.y);
 const d=enemy('Dragon');d.health=d.maxHealth*.5;stepEnemy(g,d);
 assert.equal(g.visualEvents.at(-1).type,'phase');assert.equal(g.visualEvents.at(-1).value,2);
});
test('visual event queue is capped and separate from gameplay events',()=>{
 const g=make();for(let i=0;i<200;i++)g.emitVisual('crit',g.player);
 assert.equal(g.visualEvents.length,128);assert.equal(g.events.length,0);g.step();assert.ok(g.visualEvents.length<128);
});
test('all essential canvas primitives draw with cosmetics off',()=>{
 const calls=[];const gradient={addColorStop(){}};
 const ctx=new Proxy({}, {get:(o,k)=>k==='createRadialGradient'?()=>gradient:k in o?o[k]:(...args)=>{calls.push([k,...args])},set:(o,k,v)=>{o[k]=v;return true}});
 const g=make(),c=g.camera,e=enemy('Knight');e.burnUntil=e.slowUntil=e.freezeUntil=e.curseUntil=100;
 drawWeb(ctx,0,0,46,true,1,'off');drawHazard(ctx,{type:'flame',x:0,y:0,radius:40,activeAt:0},c,1,'off');drawEnemyStatus(ctx,e,c,1,'off');
 e.action={kind:'orc-windup',angle:0,until:50};drawEnemyWarning(ctx,e,c,1,'off');drawShield(ctx,0,0,1,'off');drawProjectile(ctx,{...shot(0,0),school:'ice'},c,1,'off');
 assert.ok(calls.filter(q=>q[0]==='stroke').length>20);
 assert.equal(calls.filter(q=>q[0]==='save').length,calls.filter(q=>q[0]==='restore').length);
});
