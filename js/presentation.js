// Presentation helpers, independent of browser APIs.
export function viewportFor(width,height){
  const ratio=Math.max(.56,Math.min(1.8,width/Math.max(1,height)));
  return ratio>=1?{width:Math.round(600*ratio),height:600}:{width:600,height:Math.round(600/ratio)};
}
export function fitViewport(width,height,worldWidth,worldHeight){
  const scale=Math.min(width/worldWidth,height/worldHeight);
  return {scale,x:(width-worldWidth*scale)/2,y:(height-worldHeight*scale)/2};
}
export function formatTime(seconds){
  return String(Math.floor(seconds/60)).padStart(2,'0')+':'+String(seconds%60).padStart(2,'0');
}
export function skillValue(status,value){
  if(status==='shotCd')return (50/Math.max(1,value)).toFixed(2)+' casts/s';
  if(status==='maxSpeed')return Math.round(value*50)+' units/s';
  if(status==='maxHealth')return value+' HP';
  return value+' damage';
}
export function skillPreview(player,skill){
  const old=player[skill.status], next=skill.status==='shotCd'?Math.max(1,old+skill.modifier):old+skill.modifier;
  return skillValue(skill.status,old)+' → '+skillValue(skill.status,next);
}
