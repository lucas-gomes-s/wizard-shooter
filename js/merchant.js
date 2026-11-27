import {lootOffers,equipItem} from './equipment.js';
export const merchantWindows=[360,660,960,1260];
export const itemPrices={common:45,rare:90,epic:170,legendary:300};
export function freshMarket(){return {cursor:0,merchant:null,offers:[],history:[],earned:0,spent:0}}
export function addGold(g,n){if(g.config.economyEnabled===false||g.config.equipmentEnabled===false)return;const value=Math.max(0,Math.floor(n));g.player.gold+=value;g.market.earned+=value;}
export function stepMarket(g){
 if(g.config.economyEnabled===false||g.config.equipmentEnabled===false||g.bossSpawned)return;
 const s=g.market,p=g.player;
 if(s.merchant&&s.merchant.until<=g.tick)s.merchant=null;
 if(!s.merchant&&s.cursor<merchantWindows.length&&g.seconds>=merchantWindows[s.cursor]){
  while(s.cursor<merchantWindows.length&&g.seconds>merchantWindows[s.cursor]+60)s.cursor++;
  if(s.cursor<merchantWindows.length&&g.seconds>=merchantWindows[s.cursor]){
   const sec=merchantWindows[s.cursor++],a=g.rng()*Math.PI*2;
   s.merchant={x:p.x+p.width/2+Math.cos(a)*140,y:p.y+p.height/2+Math.sin(a)*140,until:g.tick+3000,tier:sec>=1200?3:sec>=600?2:1};
  }
 }
 const m=s.merchant;if(!m||Math.hypot(p.x+p.width/2-m.x,p.y+p.height/2-m.y)>38)return;
 s.offers=lootOffers(p,m.tier,g.rng).map(i=>({...i,price:itemPrices[i.rarity]}));
 s.offers.push({id:'heal',name:'Restorative draught',glyph:'✚',description:'Recover 35% maximum health.',price:35,kind:'heal'});
 s.merchant=null;g.phase='shop';
}
export function choosePurchase(g,index=-1){
 const s=g.market,p=g.player;
 if(g.phase!=='shop'||!Number.isInteger(index)||index< -1||index>=s.offers.length)return false;
 if(index>=0){const o=s.offers[index];if(p.gold<o.price)return false;
  if(o.kind==='heal'){if(p.health>=p.maxHealth)return false;g.healPlayer(p.maxHealth*.35);}
  else if(!equipItem(p,o.id,g.tick))return false;
  p.gold-=o.price;s.spent+=o.price;s.history.push({id:o.id,price:o.price,tick:g.tick});
 }
 s.offers=[];g.phase='playing';g.levelUp();return true;
}
