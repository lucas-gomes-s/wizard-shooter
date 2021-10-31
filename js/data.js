const maxLevel = 30
let levels = [30]

for (let i=1; i<maxLevel; i++){
    levels.push(Math.floor(levels[i-1]*(1+2/3)))
} 

let gameOverPhrases  = [
    "'I should've taken anti-dungeon monster defenses at Wizard School'",
    "'Now my laundry will go forever unfolded'",
    "'Jet fuel doesn't melt steel beams'",
    "'#Lula2022'",
    "'Finally!'",
    "'Didn't that orc look like Steve?'",
    "'Sdds da morena'",
    "'Pau que nasce torto nunca se endireita?'",
    "'Ok, that was DEFINETELY the wrong door'",
    "'Picólezin de milho, bom demais'",
    "'Could this be a simulated reality?'",
    "'Now my ghost costume will be REALLY good'",
    "'Eu deveria ter dançado mais Bonde do Tigrão'",
    "'Tu eres puro puro chantaje, puro puro chantaje'",
    "'Akemi Homura, plese stop me from becoming a mahou shoujo'",
    "'Does this hat make me look fat?'",
    "'So Kira was Yagami Raito all along?!'",
    "'We are fighting dreamers'",
    "'I hope he restarts the game soon'",
    "'O Pato sem a pata, quando anda manca'",
    "'Thank you for supporting me. And if you don't...'",
    "'CORONAVIRUS! Shit is real! Shit is getting real!'",
    "'A Lua me traiu'",
    "'A bonekinha não sabe brincar'",
    "'Fly you fools!'"
]

const monsters = [
    {name : "Orc",
    imageSrc : "../images/orc.png",   
    maxHealth : 40
    }
]