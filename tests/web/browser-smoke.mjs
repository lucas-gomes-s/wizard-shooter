import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import {mkdir} from 'node:fs/promises';

await mkdir('web-smoke-artifacts',{recursive:true});
const browser=await chromium.launch({headless:true});
try{
  const page=await browser.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1});
  const errors=[];page.on('pageerror',e=>errors.push(String(e)));
  // Test-only interception: grant XP to exercise UI without waiting for random encounters.
  // The production module does not expose its game state.
  await page.route('**/js/index.js',async route=>{
    const response=await route.fetch();
    const source=await response.text();
    const marker='const game=new Game(config), clock=new FixedClock();';
    assert.ok(source.includes(marker));
    await route.fulfill({response,body:source.replace(marker,marker+'\nwindow.__wizardTestGame=game;')});
  });
  await page.goto('http://127.0.0.1:8000/');
  const start=page.locator('#startButton');
  await start.waitFor({state:'visible'});await page.waitForFunction(()=>!document.getElementById('startButton').disabled);
  await page.screenshot({path:'web-smoke-artifacts/title.png'});
  await start.click();
  await page.locator('#overlay').waitFor({state:'hidden'});
  const canvas=page.locator('#gameArea');
  const size=await canvas.boundingBox();assert.ok(size.width>1000&&size.height>500);
  await page.keyboard.down('KeyD');await page.keyboard.down('ArrowRight');
  await page.waitForFunction(()=>document.getElementById('timer').textContent!=='00:00');
  await page.keyboard.up('KeyD');await page.keyboard.up('ArrowRight');
  await page.screenshot({path:'web-smoke-artifacts/gameplay.png'});
  await page.evaluate(()=>{const game=window.__wizardTestGame;game.player.currentExp=game.player.expNeeded;});
  await page.locator('#upgradePanel').waitFor({state:'visible'});
  assert.equal(await page.locator('#upgradeCards .upgrade-card').count(),3);
  await page.screenshot({path:'web-smoke-artifacts/spell-upgrades.png'});
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('KeyQ');
  await page.locator('#overlay').waitFor({state:'hidden'});
  await page.waitForFunction(()=>document.querySelectorAll('#spellBuild .spell-chip').length===1);
  await page.keyboard.press('Escape');await page.locator('#pausePanel').waitFor({state:'visible'});
  const time=await page.locator('#timer').textContent();await page.waitForTimeout(1200);assert.equal(await page.locator('#timer').textContent(),time);
  await page.screenshot({path:'web-smoke-artifacts/pause.png'});
  await page.locator('#restartButton').click();await page.locator('#confirmPanel').waitFor({state:'visible'});
  await page.locator('#cancelButton').click();await page.locator('#pausePanel').waitFor({state:'visible'});
  await page.locator('#resumeButton').click();await page.locator('#overlay').waitFor({state:'hidden'});
  await page.locator('#effectsToggle').uncheck();assert.equal(await page.locator('#effectsToggle').isChecked(),false);
  await page.setViewportSize({width:800,height:700});
  await page.waitForFunction(()=>document.getElementById('gameArea').width===document.getElementById('arena').clientWidth);
  assert.ok((await canvas.boundingBox()).width<800);
  await page.keyboard.press('Escape');await page.locator('#pausePanel').waitFor({state:'visible'});
  await page.locator('#restartButton').click();await page.locator('#confirmButton').click();
  await page.locator('#overlay').waitFor({state:'hidden'});assert.equal(await page.locator('#kills').textContent(),'0');
  await page.keyboard.press('Escape');await page.locator('#pausePanel').waitFor({state:'visible'});
  await page.locator('#quitButton').click();await page.locator('#confirmButton').click();
  await page.locator('#homePanel').waitFor({state:'visible'});
  await page.screenshot({path:'web-smoke-artifacts/compact-title.png'});
  await start.click();await page.locator('#overlay').waitFor({state:'hidden'});
  await page.evaluate(()=>{const g=window.__wizardTestGame;g.tick=25*60*50;g.spawnEnemies();});
  await page.locator('#bossHud').waitFor({state:'visible'});
  assert.ok((await page.locator('#bossName').textContent()).includes('Ancient Dragon'));
  await page.screenshot({path:'web-smoke-artifacts/boss.png'});
  await page.evaluate(()=>{const g=window.__wizardTestGame;g.boss.expGiven=0;g.damage(g.boss,g.boss.health);});
  await page.locator('#victoryPanel').waitFor({state:'visible'});
  await page.screenshot({path:'web-smoke-artifacts/victory.png'});
  await page.locator('#endlessButton').click();
  await page.locator('#overlay').waitFor({state:'hidden'});
  assert.equal(await page.locator('#bossName').textContent(),'Endless survival');
  assert.deepEqual(errors,[]);
  console.log('Browser smoke passed: assets, start, movement input, pause, confirmation, effects, resizing, restart, return to title.');
}finally{await browser.close();}
