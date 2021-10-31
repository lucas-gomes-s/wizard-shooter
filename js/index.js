const ctx = document.getElementById("gameArea").getContext("2d")
const startBtn = document.getElementById("startButton")
let interval = "";
let enemies = [];
let shots = [];
let canvasWidth = 600;
let canvasHeight = 600;
let counter = 0;
let spawn = 100;


startBtn.addEventListener("click", () => {
    startGame();
    
})

function startGame() {
    printBackground();
    interval = setInterval(updateCanvas, 20);    
    return wizard = new Main()
}

class GameObject {
    constructor(x , y, xSpeed, ySpeed, maxSpeed, width, height) {
        this.x = x;
        this.y = y;
        this.xSpeed = xSpeed;
        this.ySpeed = ySpeed;
        this.maxSpeed = maxSpeed;
        this.width = width;
        this.height = height;
    }

    bottom() {
        return (this.y+this.height)
    }
    
    top() {
        return this.y
    }

    left() {
        return this.x
    }

    right() {
        return (this.x+this.width)
    }

    updatePos(){
        this.x += this.xSpeed;
        this.y += this.ySpeed;
    }

    checkOnScreen() {
        if (this.x < canvasWidth + 100 && this.x > -100 && this.y>-100 && this.y<canvasHeight+100){
            return true
        }  
        else return false
    }
}


class Character extends GameObject {
    constructor (x , y, xSpeed, ySpeed, maxSpeed, width, height, health, maxHealth){
        super(x , y, xSpeed, ySpeed, maxSpeed, width, height)
        this.health = health;
        this.maxHealth = maxHealth;
    }

    drawCharacter(src) {
        const img = new Image();
        img.src = src
        ctx.drawImage(img, this.x, this.y, this.width, this.height)
    }

    checkAlive() {
        if (this.health > 0) {
            return true
        }
        else false
    }
}

class Enemy extends Character {
    constructor (x , y, xSpeed, ySpeed, maxSpeed, width, height, health, maxHealth, damage, expGiven) {
        super (x , y, xSpeed, ySpeed, maxSpeed, width, height, health, maxHealth)
        this.damage = damage;
        this.expGiven = expGiven;
    }

    //Makes enemies move in the direction of the wizard
    follow(main) {
        let xDirection = 0 
        let yDirection = 0
        let xModule = 0
        let yModule = 0

        if (this.x > main.x){
            xDirection = -1
        } 
        else if (this.x < main.x) {
            xDirection = 1
        }
        else xDirection = 0

        if (this.y > main.y){
            yDirection = -1
        } 
        else if (this.y < main.y) {
            yDirection = 1
        }
        else yDirection = 0

        xModule = Math.floor(Math.random()*(this.maxSpeed+1))
        yModule = Math.floor((this.maxSpeed**2-xModule**2)**(1/2))

        this.xSpeed = xDirection*xModule;
        this.ySpeed = yDirection*yModule;

        if (xDirection === 0) {
            this.xSpeed = 0
            this.ySpeed = this.maxSpeed*yDirection;
        }

        if (yDirection === 0) {
            this.ySpeed = 0
            this.xSpeed = this.maxSpeed*xDirection;
        }

    }

} 

class Main extends Character {
    constructor(){
        super (280, 280, 0, 0, 10, 40, 40, 100, 100);
        this.level = 1;
        this.currentExp= 0;
        this.experience= 100;
        this.shotDmg = 10;
        this.shotSpd = 5;
        this.shotSize = 5;
        this.shotCd = 2;
        this.drawCharacter("../images/wizard-hat.png")
    }

    mainUpdatePos() {
        if ((this.xSpeed>0 && this.x<canvasWidth-this.width) || (this.xSpeed<0 && this.x > 0)){
            this.x += this.xSpeed;
        }
        if ((this.ySpeed>0 && this.y<canvasHeight-this.height) || (this.ySpeed<0 && this.y > 0)){
            this.y += this.ySpeed;
        }        
    }

    gainExp (enemy) {
        this.currentExp += enemy.expGiven
    }
}

class Shot extends GameObject {
    constructor(x , y, xSpeed, ySpeed, maxSpeed, width, height, damage, hits) {
        super (x , y, xSpeed, ySpeed, maxSpeed, width, height);
        this.damage = damage;
        this.hits = hits;
        this.drawShot();
    }

    drawShot() {
        ctx.fillStyle = "white";
        ctx.fillRect(this.x, this.y, this.width, this.height);
    }
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
            wizard.xSpeed = -5;
            break;
        case "d":
            wizard.xSpeed = 5; 
            break;
        case "s":
            wizard.ySpeed = 5;
            break;
        case "w":
            wizard.ySpeed = -5;
            break;
        case "ArrowLeft":
            shots.push(new Shot(wizard.x, wizard.y, -wizard.shotSpd, 0, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
            break;
        case "ArrowRight":
            shots.push(new Shot(wizard.x, wizard.y, wizard.shotSpd, 0, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0))            
            break;a
        case "ArrowUp":
            shots.push(new Shot(wizard.x, wizard.y, 0, -wizard.shotSpd, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
            break;
        case "ArrowDown":
            shots.push(new Shot(wizard.x, wizard.y, 0, wizard.shotSpd, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg, 0));
            break;                

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
//should work on parameters to create different enemies
function generateEnemies() {
    let randomDirection = Math.floor(Math.random()*4) //0 top, 1 bottom, 2 right, 3 left
    if (counter%spawn === 0) {
        switch(randomDirection) {
            case(0):
                enemies.push(new Enemy(Math.floor(Math.random()*canvasWidth), 0, 0, 0, 1, 40, 40, 20, 20, 10, 10));
                break;
            case (1):
                enemies.push(new Enemy(Math.floor(Math.random()*canvasWidth), canvasHeight, 0, 0, 1, 40, 40, 20, 20, 10, 10));
                break;
            case (2):
                enemies.push(new Enemy(canvasWidth, Math.floor(Math.random()*canvasHeight), 0, 0, 1, 40, 40, 20, 20, 10, 10));
                break;
            case (3):
                enemies.push(new Enemy(0, Math.floor(Math.random()*canvasHeight), 0, 0, 1, 40, 40, 20, 20, 10, 10));
                break;
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



// Checks if shot, delete dead, gives Exp to wizard, adjust velocity, update position, redraw
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
        enemies[i].drawCharacter("../images/orc.png")
    }


}


//Everything that needs to be updated in each iteraction
function updateCanvas() {
    ctx.clearRect(0,0,600,600);
    printBackground();
    wizard.mainUpdatePos();
    updateShots();
    wizard.drawCharacter("../images/wizard-hat.png");
    generateEnemies();
    updateEnemies();
    counter += 1;
}