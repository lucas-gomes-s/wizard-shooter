import {chromium,firefox,webkit} from 'playwright';
import assert from 'node:assert/strict';
import {mkdir,writeFile} from 'node:fs/promises';
const engine=process.argv[2]||'chromium',type={chromium,firefox,webkit}[engine];
if(!type)throw Error('Unknown browser '+engine);
await mkdir('web-beta-artifacts',{recursive:true});
const browser=await type.launch({headless:true});
try{
 const page=await browser.newPage({viewport:{width:1280,height:800},deviceScaleFactor:1});
 const errors=[];page.on('pageerror',e=>errors.push(String(e)));
 await page.route('**/js/index.js',async route=>{const response=await route.fetch();const body=await response.text();const marker='const game=new Game(config), clock=new FixedClock();';assert.ok(body.includes(marker));await route.fulfill({response,body:body.replace(marker,marker+'\nwindow.__wizardTestGame=game;')});});
 await page.goto('http://127.0.0.1:8000/');
 await page.waitForFunction(()=>!document.getElementById('startButton').disabled);
 await page.locator('#environmentSelect').selectOption('forge');
 await page.locator('#startButton').click();await page.locator('#overlay').waitFor({state:'hidden'});
 await page.waitForFunction(()=>window.__wizardTestGame.tick>5);
 // Synthetic stress scene, not a natural gameplay benchmark.
 await page.evaluate(()=>{
  const g=window.__wizardTestGame,p=g.player;
  g.enemies=[];g.shots=[];g.hostiles=[];g.hazards=[];
  const c=g.camera;
  for(let i=0;i<240;i++){const m=g.config.monsters[i%8],e=g.spawnAtEdge(m);Object.assign(e,{x:c.x+30+(i%20)*((g.width-60)/20),y:c.y+30+Math.floor(i/20)*((g.height-60)/12),health:1e9,maxHealth:1e9,damage:0,maxSpeed:0,nextAttack:1e9,expGiven:0});g.enemies.push(e)}
  for(let i=0;i<250;i++)g.shots.push({x:c.x+(i%25)*g.width/25,y:c.y+Math.floor(i/25)*g.height/10,width:5,height:5,vx:0,vy:0,damage:0,remaining:999,age:-5000,hit:new Set(),school:['fire','ice','lightning','necro','arcane'][i%5]});
  for(let i=0;i<80;i++)g.hazards.push({type:'lava-vent',x:c.x+(i%10)*g.width/10,y:c.y+Math.floor(i/10)*g.height/8,radius:20,activeAt:g.tick+5000,until:g.tick+6000,warning:6000,damage:0,hit:false});
  g.player.health=g.player.maxHealth;
 });
 const results=[];
 for(const mode of ['full','reduced','off']){
  await page.locator('#effectsMode').selectOption(mode);
  const sample=await page.evaluate(()=>new Promise(resolve=>{const intervals=[];let last=null,start=null;function loop(t){if(start===null)start=t;if(last!==null)intervals.push(t-last);last=t;if(t-start>=3000){intervals.sort((a,b)=>a-b);const mean=intervals.reduce((s,v)=>s+v,0)/intervals.length;resolve({frames:intervals.length,meanMs:mean,p95Ms:intervals[Math.ceil(intervals.length*.95)-1],fps:1000/mean,tick:window.__wizardTestGame.tick,enemies:window.__wizardTestGame.enemies.length,shots:window.__wizardTestGame.shots.length,hazards:window.__wizardTestGame.hazards.length})}else requestAnimationFrame(loop)}requestAnimationFrame(loop)}));
  assert.ok(sample.frames>0&&Number.isFinite(sample.p95Ms));results.push({mode,...sample});
 }
 await page.screenshot({path:'web-beta-artifacts/'+engine+'-stress.png'});
 await page.locator('#betaReport').click();await page.locator('#betaReportPanel').waitFor({state:'visible'});
 const report=JSON.parse(await page.locator('#betaReportText').inputValue());
 assert.equal(report.version,'1.19.0-beta.1');assert.equal(report.environment,'forge');assert.ok(report.performance.samples>0);assert.equal(report.browser,engine==='chromium'?'Chromium':engine==='firefox'?'Firefox':'Safari');
 await page.locator('#pausePanel').waitFor({state:'visible'});
 await page.locator('#closeBetaReport').click();await page.locator('#resumeButton').click();
 await page.setViewportSize({width:800,height:700});await page.waitForTimeout(150);
 assert.ok((await page.locator('#gameArea').boundingBox()).width<800);
 assert.deepEqual(errors,[]);
 await writeFile('web-beta-artifacts/'+engine+'-performance.json',JSON.stringify({engine,scenario:'synthetic heavy scene, headless CI; not hardware certification',results,report},null,2));
 console.log(JSON.stringify({engine,results}));
}finally{await browser.close()}
