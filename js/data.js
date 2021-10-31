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
    "'Fly you fools!'",
    "'Fintchy reãis!'",
    "'É o quê que tá aconteceno?!'",
    "'Mirella, corre aqui!'",
    "'Lohane Vêkanandre Sthephany Smith Bueno de HA HA HA...'",
    "'Finally, I'll pay for my sins in Ishval'",
    "'Já acabou, Lorena?'",
    "'Don't follow the light, it's a train'",
    "'All that fit food for nothing'",
    "'I can't believe I'm going to die IN THESE clothes'",
    "'At least it wasn't in the shower'",
    "'I should've worn my good underwear'",
    "'Sashay Away'",
    "'Questão de Ordem, presidente'",
    "'Please tell me you've saved some phoenix down'",
    "'Microwave beeps ARE NOT passive-aggressive'"
]

let monsters = [
    {name : "Orc",
    imageSrc : "../images/orc.png",   
    maxSpeed: 1,
    width: 30,
    height: 30,
    health:50,
    maxHealth: 50,
    damage:10,
    expGiven: 10,
    startMinute: 1,
    spawn: 100,
    cooldown: 0
    }
]

