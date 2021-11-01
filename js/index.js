const ctx = document.getElementById("gameArea").getContext("2d")
const canvasElement = document.getElementById("gameArea")
const startBtn = document.getElementById("startButton")
let interval = "";
let enemies = [];
let shots = [];
let canvasWidth = 600;
let canvasHeight = 600;
let counter = 0;
let lvlUpScreen = false;
let lvlUpNavigation = 0;


startBtn.addEventListener("click", () => {
    startGame();
    
})

function startGame() {
    printBackground();
    enemies = [];
    shots = [];
    counter = 0;
    if (interval) {
        clearInterval(interval)
    }
    interval = setInterval(updateCanvas, 20);  
    return wizard = new Main();

}


//Prints background (duh)
function printBackground() {
    const img = new Image();
    img.src = "../images/dungeonfloor.jpg"
    let pattern = ctx.createPattern(img, "repeat");
    ctx.fillStyle = pattern;
    ctx.fillRect(0, 0, 600, 600)
    
}



//Start of user inputs
document.addEventListener("keydown", (e) => {
    switch (e.key){
        case "a":
            wizard.xSpeed = -wizard.maxSpeed;
            break;
        case "d":
            wizard.xSpeed = wizard.maxSpeed; 
            break;
        case "s":
            wizard.ySpeed = wizard.maxSpeed;
            break;
        case "w":
            wizard.ySpeed = -wizard.maxSpeed;
            break;
        case "ArrowLeft":
            if (lvlUpScreen && lvlUpNavigation>0) {
                lvlUpNavigation -= 1;
            }
            if (wizard.cooldown === 0) {
                shots.push(new Shot(wizard.x+wizard.width/2, wizard.y+wizard.height/2, -wizard.shotSpd, 0, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
                wizard.cooldown = wizard.shotCd;
            }
            break;
        case "ArrowRight":
            if (lvlUpScreen && lvlUpNavigation<3) {
                lvlUpNavigation += 1;
            }
            if (wizard.cooldown === 0) {
                shots.push(new Shot(wizard.x+wizard.width/2, wizard.y+wizard.height/2, wizard.shotSpd, 0, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
                wizard.cooldown = wizard.shotCd;
            }         
            break;
        case "ArrowUp":
            if (wizard.cooldown === 0) {
                shots.push(new Shot(wizard.x+wizard.width/2, wizard.y+wizard.height/2, 0, -wizard.shotSpd, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
                wizard.cooldown = wizard.shotCd;
            }
            break;
        case "ArrowDown":
            if (wizard.cooldown === 0) {
                shots.push(new Shot(wizard.x+wizard.width/2, wizard.y+wizard.height/2, 0, wizard.shotSpd, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
                wizard.cooldown = wizard.shotCd;
            }
            break;             
        case "Enter":
            if (lvlUpScreen && wizard.skillLvl[lvlUpNavigation]!==skills[lvlUpNavigation].maxLevel) {
                wizard[skills[lvlUpNavigation].status] += skills[lvlUpNavigation].modifier;
                wizard.skillLvl[lvlUpNavigation] += 1; 
                ResumeGame();
            }

    }
})

document.addEventListener("keyup", (e) => {
    switch (e.key){
        case "a":
            wizard.xSpeed = 0;
            break;
        case "d":
            wizard.xSpeed = 0;
            break;
        case "s":
            wizard.ySpeed = 0;
            break;
        case "w":
            wizard.ySpeed = 0;
    }
})
//End of user inputs



//update the position of shots and deletes the offscreen and the ones that already hit
function updateShots() {
    for (let i=0; i<shots.length; i++) {
        shots[i].updatePos();
        shots[i].drawShot();
    }

    shots = shots.filter(shot => shot.checkOnScreen())
    shots = shots.filter(shot => shot.hits === 0)
}



//Generates enemy from random directions
function generateEnemies() {
    for (let i=0; i<monsters.length; i++) {
        if (monsters[i].startMinute<=minutesElapsed()) {
            monsters[i].cooldown += 1;
            if (monsters[i].cooldown===monsters[i].spawn) {
                let randomDirection = Math.floor(Math.random()*4) //0 top, 1 bottom, 2 right, 3 left
                let randomValue = Math.floor(Math.random()*canvasWidth) 
                let x = 0;
                let y = 0;
                switch(randomDirection) {
                    case(0):
                        x = randomValue;
                        y = 0;
                        break;
                    case (1):
                        x= randomValue;
                        y= canvasHeight;
                        break;
                    case (2):
                        x=canvasWidth;
                        y=randomValue;
                        break;
                    case (3):
                        x = 0;
                        y = randomValue;
                        break;            
                }
                enemies.push(new Enemy(x, y, monsters[i].maxSpeed, monsters[i].width, monsters[i].height, monsters[i].imageSrc, monsters[i].health, monsters[i].maxHealth, monsters[i].damage, monsters[i].expGiven ));
                monsters[i].cooldown = 0;
            }    
        }
    }
}




//checks the colision between two GameObjects
//Maybe make it a GameObject method?
function objectsCollide(object1, object2) {
    return !(object1.bottom() < object2.top() || object1.left() > object2.right() || object1.top()>object2.bottom() || object1.right()<object2.left())
}



//checks if each enemy was hit by each shot
function checkShot() {
    for (let i=0; i<enemies.length; i++) {
        for (let j=0; j<shots.length; j++) {
            if (shots[j].hits === 0) {
                if (objectsCollide(enemies[i], shots[j])) {
                    enemies[i].health -= shots[j].damage;
                    shots[j].hits += 1;
                }
            }
        }
    }
}


//checks if wizard took damage from and enemy
function checkDamage() {
    for (let i=0; i<enemies.length; i++) {
        if (enemies[i].cd > 0) {
            enemies[i].cd -= 1;
        }
        else if (objectsCollide(enemies[i], wizard)) {
            wizard.health -= enemies[i].damage;
            enemies[i].cd = enemies[i].dmgCd;
            ctx.fillStyle = "red"
            ctx.fillRect(0,0, 600,600)
        }
    }
}



// Checks if shot, delete dead, gives Exp to wizard, adjust velocity, update position, redraw, generate new enemies
function updateEnemies () {   
    
    checkShot();
    enemies = enemies.filter(enemy => {
        if (!enemy.checkAlive()) {
            wizard.gainExp(enemy)
        }
        return enemy.checkAlive()}) 
    
    for (let i=0; i<enemies.length; i++) {
        enemies[i].follow(wizard);
        enemies[i].updatePos();
        enemies[i].drawObject()
    }
    generateEnemies();
}

function updateWizard () {
    checkDamage();
    wizard.mainUpdatePos();
    wizard.drawObject();
    wizard.levelUp()
    if (!wizard.checkAlive()) {
        gameOver();
    }
    if (wizard.cooldown > 0) {
        wizard.cooldown -= 1;
    }
}


function updateGameElements() {
    ctx.clearRect(0,0,600,600);
    printBackground();
    printTimer();
    printHpBar();
    printExpBar();
}

//Calculate and Print Time Elapsed
function minutesElapsed() {
    return Math.floor(counter/50/60)
}

function secondsElapsed() {
    return Math.floor((counter/50)%60)
}

function turnToTwoDigitString (number) {
    if (number < 10) {
        return "0"+number
    }
    else return number.toString()
}

function printTimer() {
    ctx.fillStyle = "white"
    ctx.font = "20px arial"
    let text = turnToTwoDigitString(minutesElapsed())+":"+turnToTwoDigitString(secondsElapsed())
    ctx.fillText(text,278,40)
}
//End of Calculate and Print Time Elapsed

function printHpBar() {
    ctx.strokeStyle = "red";
    ctx.lineWidth = 1;
    ctx.strokeRect(50,25,200,15)
    ctx.fillStyle="red"
    ctx.fillRect(50,25,200*(wizard.health/wizard.maxHealth),15)
    let img = new Image()
    img.src = "../images/heart.png"
    ctx.drawImage(img, 20, 22, 20, 20)
}

function printExpBar() {
    ctx.strokeStyle = "yellow";
    ctx.lineWidth = 1;
    ctx.strokeRect(380,25,200,15)
    ctx.fillStyle="yellow"
    ctx.fillRect(380,25,200*(wizard.currentExp/wizard.expNeeded),15)
    ctx.fillStyle = "white"
    ctx.font = "10px arial"
    ctx.fillText("Level", 350, 25)
    ctx.font = "18px arial"
    ctx.fillText(wizard.level, 355, 45)
}


function lvlUpScreenCanvas() {
    ctx.clearRect(0,0, canvasWidth, canvasHeight);   
    ctx.fillStyle = "rgba(0, 0, 0, 0.5)";
    ctx.fillRect(0, 0, 600, 600);
    ctx.fillStyle = "red";
    ctx.font = "50px arial";
    let levelUpString = "Level Up!";
    ctx.fillText(levelUpString, canvasWidth/2 - ctx.measureText(levelUpString).width/2, 150);
    let skillString = "Choose a Skill to improve:";
    ctx.fillStyle = "white";
    ctx.font = "25px arial";
    ctx.fillText(skillString, canvasWidth/2 - ctx.measureText(skillString).width/2, 200);
    ctx.font = "15px arial"
    skillString = "(Press 'Enter' to choose)";
    ctx.fillText(skillString, canvasWidth/2 - ctx.measureText(skillString).width/2, 220);
    ctx.fillRect(51, 241, 98, 98);
    let skillImg = new Image();
    skillImg.src = skills[0].img;
    ctx.drawImage(skillImg, 60, 250, 80, 80);
    ctx.fillRect(181, 241, 98, 98);
    let skillImg1 = new Image();
    skillImg1.src = skills[1].img;
    ctx.drawImage(skillImg1, 190, 250, 80, 80);
    ctx.fillRect(311, 241, 98, 98);
    let skillImg2 = new Image();
    skillImg2.src = skills[2].img
    ctx.drawImage(skillImg2, 320, 250, 80, 80);
    ctx.fillRect(441, 241, 98, 98) ;
    let skillImg3 = new Image();
    skillImg3.src = skills[3].img;
    ctx.drawImage(skillImg3, 450, 250, 80, 80);
    ctx.strokeStyle = "red";
    ctx.lineWidth = 5;
    ctx.strokeRect(50+130*lvlUpNavigation, 240, 100, 100);
    ctx.fillStyle = "white";
    ctx.font = "25px arial";
    ctx.fillText(skills[lvlUpNavigation].name, canvasWidth/2-ctx.measureText(skills[lvlUpNavigation].name).width/2, 390 )
    ctx.fillStyle = "black";
    ctx.font = "15px arial";
    let lvlString = `Current level: ${wizard.skillLvl[lvlUpNavigation]}`
    if (wizard.skillLvl[lvlUpNavigation] === skills[lvlUpNavigation].maxLevel){
        lvlString = `Current level: Maxed`
    }
    ctx.fillText(lvlString, canvasWidth/2-ctx.measureText(lvlString).width/2, 408 )
    ctx.font = "20px arial";
    ctx.fillText(skills[lvlUpNavigation].description1, canvasWidth/2-ctx.measureText(skills[lvlUpNavigation].description1).width/2, 430 )
    ctx.font = "15px arial";
    ctx.fillText(skills[lvlUpNavigation].description2, canvasWidth/2-ctx.measureText(skills[lvlUpNavigation].description2).width/2, 450 )
}

function lvlUp() {
    lvlUpScreen = true;
    clearInterval(interval);
    interval = setInterval(lvlUpScreenCanvas, 20);
}

function ResumeGame() {
    clearInterval(interval);
    lvlUpScreen = false;
    lvlUpNavigation = 0;
    interval = setInterval(updateCanvas, 20)
}

function gameOver() {
    clearInterval(interval);
    printBackground();
    ctx.fillStyle = "red";
    ctx.font = " 60px arial";
    let gameOverString = "Game Over"
    let gameOverStringWidth = ctx.measureText(gameOverString).width
    ctx.fillText(gameOverString , canvasWidth/2 - gameOverStringWidth/2, 300);
    ctx.fillStyle = "white";
    ctx.font = "20px arial";
    let text1 = "You were overrun by monsters." 
    let text1Width = ctx.measureText(text1).width
    let text2 =  "As the light fades from your eyes, you think:"
    let text2Width = ctx.measureText(text2).width
    let text3 = gameOverPhrases[Math.floor(Math.random()*gameOverPhrases.length)]
    let text3Width = ctx.measureText(text3).width
    ctx.fillText(text1 , canvasWidth/2 - text1Width/2, 330);
    ctx.fillText(text2 , canvasWidth/2 - text2Width/2, 350);
    ctx.fillText(text3 , canvasWidth/2 - text3Width/2, 370);
    enemies = [];
    updateEnemies();
}

//Everything that needs to be updated in each iteraction
function updateCanvas() {
    updateGameElements();
    updateShots();  
    updateEnemies();
    updateWizard();
    counter += 1;
}