import test from 'node:test';
import assert from 'node:assert/strict';
import {DungeonArt,actorNames,paintActor,paintFloor,palettes,tileOffset,hashCell,drawSigil,drawTargetRing,drawLight,ART_SIZE,FLOOR_SIZE} from '../../js/dungeon-art.js';
function mock(){const calls=[];const ctx=new Proxy({calls},{get(t,k){if(k==='createRadialGradient')return (...args)=>{calls.push([k,...args]);return {addColorStop:(...a)=>calls.push(['stop',...a])}};if(k in t)return t[k];return (...a)=>calls.push([k,...a])},set(t,k,v){t[k]=v;calls.push(['set',k,v]);return true}});return ctx;}
function factory(w,h){const c=mock();return {width:w,height:h,getContext:()=>c,ctx:c}}
test('all original actors render; dragon variants and enemy silhouettes are distinct',()=>{
 const art=new DungeonArt(factory);const sprites=actorNames.map(n=>art.actor(n));assert.equal(sprites.length,10);
 assert.equal(new Set(sprites.map(s=>JSON.stringify(s.ctx.calls))).size,10);
 for(const s of sprites){assert.equal(s.width,ART_SIZE);assert.ok(s.ctx.calls.length>10);}
 assert.notEqual(JSON.stringify(art.actor('Dragon','frost').ctx.calls),JSON.stringify(art.actor('Dragon','forge').ctx.calls));
 assert.equal(art.actor('Wizard','frost'),art.actor('Wizard','crypt'));
});
test('tile art is deterministic and biome palettes are distinct',()=>{
 const a=new DungeonArt(factory),b=new DungeonArt(factory);
 for(const id of Object.keys(palettes)){assert.deepEqual(a.floor(id).ctx.calls,b.floor(id).ctx.calls);assert.equal(a.floor(id).width,FLOOR_SIZE);}
 assert.equal(new Set(Object.keys(palettes).map(id=>JSON.stringify(a.floor(id).ctx.calls))).size,3);
 assert.equal(a.floor('unknown'),a.floor('crypt'));
});
test('world tile offset handles negative coordinates and wraps without gaps',()=>{
 assert.equal(tileOffset(0),-0);assert.equal(tileOffset(1),-1);assert.equal(tileOffset(-1),-383);assert.equal(tileOffset(384),-0);
 assert.equal(hashCell(-10,21),hashCell(-10,21));assert.notEqual(hashCell(-10,21),hashCell(-10,22));
 const a=new DungeonArt(factory),c=mock();a.drawFloor(c,'crypt',{x:-10,y:20},600,600);
 const draws=c.calls.filter(x=>x[0]==='drawImage');assert.ok(draws.length>=4&&draws.length<=9);
});
test('drawing caches sprites, never mutates actor options or camera',()=>{
 const a=new DungeonArt(factory),c=mock(),camera=Object.freeze({x:-42,y:11}),opts=Object.freeze({tick:200,animate:true,flip:true,variant:'forge'});
 a.drawFloor(c,'forge',camera,600,600);for(let i=0;i<100;i++)a.drawActor(c,'Demon',20,30,50,50,opts);
 assert.equal(a.actors.size,1);assert.equal(a.floors.size,1);assert.equal(c.calls.filter(x=>x[0]==='drawImage').length>100,true);
});
test('essential player and boss markers remain available with effects off',()=>{
 const c=mock();drawSigil(c,20,30,24,'#aabbcc',0,'off');drawTargetRing(c,10,10,100,100,'#ef8978','boss');
 assert.ok(c.calls.filter(x=>x[0]==='ellipse').length>=3);const n=c.calls.length;drawLight(c,600,600,300,300,'crypt','off');assert.equal(c.calls.length,n);
 drawLight(c,600,600,300,300,'crypt','full');assert.ok(c.calls.some(x=>x[0]==='createRadialGradient'));
});
