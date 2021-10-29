const ctx = document.getElementById("gameArea").getContext("2d")
const startBtn = document.getElementById("startButton")
let interval = "";
let enemies = [];
let shots = [];
let canvasWidth = 600;
let canvasHeight = 600;
let counter = 0;
let spawn = 300;


startBtn.addEventListener("click", () => {
    startGame();
    interval = setInterval(updateCanvas, 20)    
})

function startGame() {
    printBackground();
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
}

class Enemy extends Character {
    constructor (x , y, xSpeed, ySpeed, maxSpeed, width, height, health, maxHealth, damage, expGiven) {
        super (x , y, xSpeed, ySpeed, maxSpeed, width, height, health, maxHealth)
        this.damage = damage;
        this.expGiven = expGiven;
    }

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
}

class Shot extends GameObject {
    constructor(x , y, xSpeed, ySpeed, maxSpeed, width, height, damage) {
        super (x , y, xSpeed, ySpeed, maxSpeed, width, height);
        this.damage = damage;
        this.drawShot();
    }

    drawShot() {
        ctx.fillStyle = "white";
        ctx.fillRect(this.x, this.y, this.width, this.height);
    }
}


function printBackground() {
    const img = new Image();
    img.src = "../images/dungeonfloor.jpg"
    let pattern = ctx.createPattern(img, "repeat");
    ctx.fillStyle = pattern;
    ctx.fillRect(0, 0, 600, 600)
    
}

document.addEventListener("keydown", (e) => {
    console.log(e.key)
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
            shots.push(new Shot(wizard.x, wizard.y, -wizard.shotSpd, 0, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg));
            break;
        case "ArrowRight":
            shots.push(new Shot(wizard.x, wizard.y, wizard.shotSpd, 0, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg))            
            break;
        case "ArrowUp":
            shots.push(new Shot(wizard.x, wizard.y, 0, -wizard.shotSpd, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg));
            break;
        case "ArrowDown":
            shots.push(new Shot(wizard.x, wizard.y, 0, wizard.shotSpd, wizard.shotSpd, wizard.shotSize, wizard.shotSize, wizard.shotDmg));
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

function updateShots() {
    for (let i=0; i<shots.length; i++) {
        shots[i].updatePos();
        shots[i].drawShot();
    }

    deleteOffScreen(shots);
}


function deleteOffScreen(arr) {
    
    arr = arr.filter(pos => {
        (pos.x < canvasWidth + 100 || pos.x > -100 || pos.y>-100||pos.y<canvasHeight+100)
    })
}

function generateEnemies() {
    let randomDirection = Math.floor(Math.random()*4) //0 top, 1 bottom, 2 right, 3 left
    if (counter%spawn === 0) {
        console.log(randomDirection)
        switch(randomDirection) {
            case(0):
                enemies.push(new Enemy(Math.floor(Math.random()*canvasWidth), 0, 0, 0, 1, 20, 20, 20, 20, 10, 10));
                break;
            case (1):
                enemies.push(new Enemy(Math.floor(Math.random()*canvasWidth), canvasHeight, 0, 0, 1, 20, 20, 20, 20, 10, 10));
                break;
            case (2):
                enemies.push(new Enemy(canvasWidth, Math.floor(Math.random()*canvasHeight), 0, 0, 1, 20, 20, 20, 20, 10, 10));
                break;
            case (3):
                enemies.push(new Enemy(0, Math.floor(Math.random()*canvasHeight), 0, 0, 1, 20, 20, 20, 20, 10, 10));
                break;
        }
    console.log(enemies)   
    }
}

function updateEnemies () {
    for (let i=0; i<enemies.length; i++) {
        enemies[i].follow(wizard);
        enemies[i].updatePos();
        enemies[i].drawCharacter("../images/orc.png")
    }

    deleteOffScreen(enemies);
}



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