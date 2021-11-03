const maxLevel = 50
let levels = [5]

for (let i=1; i<maxLevel; i++){
    if (i<5){
        levels.push(Math.floor(levels[i-1]*(1.5)))
        continue;
    }
    if (i<10) {
        levels.push(Math.floor(levels[i-1]*(1.3)))
        continue;
    }
    if (i<25) {
        levels.push(Math.floor(levels[i-1]*(1.2)))
        continue;
    }
    if (i<50) {
        levels.push(Math.floor(levels[i-1]*(1.1)))
        continue;
    }
} 


let skills = [
    {name: "Hermes' Emissary",
    description1: "Run like the wind!",
    description2: "Increases move speed",
    status: "maxSpeed",
    modifier: 1,
    maxLevel: 5,
    img: "./images/skills/nimbleFeet.png"
    },
    {name: "Dragon Scales",
    description1: "I've got thick skin and an elastic heart!",
    description2: "Increases maximum HP",
    status: "maxHealth",
    modifier: 20,
    maxLevel: 20,
    img: "./images/skills/dragonScales.png"
    },
    {name: "Necronomicon",
    description1: "Give up a little Sanity, gain more power!",
    description2: "Increases magic damage",
    status: "shotDmg",
    modifier: 10,
    maxLevel: 20,
    img: "./images/skills/necronomicon.jpg"
    },
    {name: "Who is Rambo?",
    description1: "No, really, who is this guy?!",
    description2: "Increases casting speed",
    status: "shotCd",
    modifier: -5,
    maxLevel: 10,
    img: "./images/skills/machineGun.png"
    }
]


let gameOverPhrases  = [
    "'I should've taken anti-dungeon monster defenses in Wizard School'",
    "'Now my laundry will go forever unfolded'",
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
    "'Questão de Ordem, Sr. Presidente'",
    "'Please tell me you've saved some phoenix down'",
    "'Microwave beeps ARE NOT passive-aggressive'",
    "'I don't exist and neither do you'",
    "'I hope I don't have to start from scratch' (you do)",
    "'I should have chosen the blue pill'",
    "'Hello Darkness, my old friend'",
    "'Now God will have to hear some harsh truths'"
]

let monsters = [
    {name : "Spider",
    imageSrc : "./images/enemies/spider.png",   
    maxSpeed: 3,
    width: 20,
    height: 20,
    health:10,
    maxHealth: 10,
    damage:10,
    expGiven: 1,
    startMinute: 4,
    spawn: 70,
    cooldown: 0
    },

    {name : "Goblin",
    imageSrc : "./images/enemies/goblin.png",   
    maxSpeed: 2,
    width: 30,
    height: 30,
    health:20,
    maxHealth: 20,
    damage:10,
    expGiven: 1,
    startMinute: 0,
    spawn: 100,
    cooldown: 0
    },

    {name : "Orc",
    imageSrc : "./images/enemies/orc.png",   
    maxSpeed: 2,
    width: 40,
    height: 40,
    health:100,
    maxHealth: 100,
    damage:20,
    expGiven: 5,
    startMinute: 1,
    spawn: 350,
    cooldown: 0
    },

    {name : "Zombie",
    imageSrc : "./images/enemies/zombie.png",   
    maxSpeed: 1,
    width: 40,
    height: 40,
    health:300,
    maxHealth: 300,
    damage:30,
    expGiven: 10,
    startMinute: 5,
    spawn: 300,
    cooldown: 0
    },    
    
    {name : "Knight",
    imageSrc : "./images/enemies/knight.png",   
    maxSpeed: 3,
    width: 40,
    height: 40,
    health:400,
    maxHealth: 400,
    damage:50,
    expGiven: 15,
    startMinute: 7,
    spawn: 500,
    cooldown: 0
    },    
    
    {name : "Vampire",
    imageSrc : "./images/enemies/vampire.png",   
    maxSpeed: 3,
    width: 40,
    height: 40,
    health:300,
    maxHealth: 300,
    damage:30,
    expGiven: 30,
    startMinute: 10,
    spawn: 200,
    cooldown: 0
    },    
    
    {name : "Reaper",
    imageSrc : "./images/enemies/reaper.png",   
    maxSpeed: 3,
    width: 50,
    height: 50,
    health:300,
    maxHealth: 300,
    damage:30,
    expGiven: 70,
    startMinute: 15,
    spawn: 200,
    cooldown: 0
    },    
    
    {name : "Demon",
    imageSrc : "./images/enemies/demon.png",   
    maxSpeed: 3,
    width: 50,
    height: 50,
    health:300,
    maxHealth: 300,
    damage:30,
    expGiven: 300,
    startMinute: 20,
    spawn: 200,
    cooldown: 0
    },    
    
    {name : "Dragon",
    imageSrc : "./images/enemies/dragon.png",   
    maxSpeed: 1,
    width: 100,
    height: 100,
    health:5000,
    maxHealth: 5000,
    damage:300,
    expGiven: 1000,
    startMinute: 25,
    spawn: 5000,
    cooldown: 0
    }
]

let potionInfo = [
    {type: "Minor HP Potion",
    recovery: 0.1,
    minSpawn: 500,
    maxSpawn: 2000,
    currentSpawn: 500,
    startMinute: 0,
    cooldown: 1,
    fade: 1000,
    imageSrc: "./images/potions/potion.png"},

    {type: "HP Potion",
    recovery: 0.25,
    minSpawn: 2000,
    maxSpawn: 4000,
    currentSpawn: 2000,
    startMinute: 10,
    fade: 1000,
    cooldown: 1,
    imageSrc: "./images/potions/midPotion"},

    {type: "Great HP Potion",
    recovery: 0.5,
    minSpawn: 4000,
    maxSpawn: 5000,
    currentSpawn: 4000,
    startMinute: 20,
    fade: 1000,
    cooldown: 1,
    imageSrc: "./images/potions/highPotion.png"}

]