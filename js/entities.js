class GameObject {
    constructor(x , y, xSpeed, ySpeed, maxSpeed, width, height, imgSrc) {
        this.x = x;
        this.y = y;
        this.xSpeed = xSpeed;
        this.ySpeed = ySpeed;
        this.maxSpeed = maxSpeed;
        this.width = width;
        this.height = height;
        this.imgSrc = imgSrc;
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

    updatePos(main){
        this.x += this.xSpeed - main.xSpeed;
        this.y += this.ySpeed - main.ySpeed;        
    }

    //not being used
    //method for making characters "cross the walls"
    updatePosModified(){
        if (this.y <= 0 ) {
            this.y = 600
        }
        if (this.y>=canvasHeight) {
            this.y = 0
        }
        if (this.x <= 0) {
            this.x = 600
        }
        if (this.x >= canvasWidth) {
            this.x = 0
        }

        this.x += this.xSpeed;
        this.y += this.ySpeed;
        
    }

    checkOnScreen() {
        if (this.x < 2*canvasWidth && this.x > -2*canvasWidth && this.y>-2*canvasHeight && this.y<2*canvasHeight){
            return true
        }  
        else return false
    }

    drawObject() {
        const img = new Image();
        img.src = this.imgSrc
        ctx.drawImage(img, this.x, this.y, this.width, this.height)
    }
}


class Character extends GameObject {
    constructor (x , y, xSpeed, ySpeed, maxSpeed, width, height, imgSource, health, maxHealth){
        super(x , y, xSpeed, ySpeed, maxSpeed, width, height, imgSource)
        this.health = health;
        this.maxHealth = maxHealth;
    }



    checkAlive() {
        if (this.health > 0) {
            return true
        }
        else false
    }

    printHealthBar() {
        ctx.strokeStyle = "red";
        ctx.lineWidth = 1;
        ctx.strokeRect(this.x,this.y-10,this.width,5)
        ctx.fillStyle="red"
        ctx.fillRect(this.x,this.y-10,this.width*(this.health/this.maxHealth),5)       
    }
}

class Enemy extends Character {
    constructor (x , y, maxSpeed, width, height, imgSource, health, maxHealth, damage, expGiven) {
        super (x , y, 0, 0, maxSpeed, width, height, imgSource, health, maxHealth)
        this.damage = damage;
        this.expGiven = expGiven;
        this.dmgCd = 50;
        this.cd = 0;
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
        super (280, 280, 0, 0, 2, 40, 40, "./images/wizard-hat.png", 100, 100);
        this.level = 1;
        this.currentExp= 0;
        this.expNeeded= levels[0];
        this.shotDmg = 10;
        this.shotSpd = 8;
        this.shotSize = 5;
        this.shotCd = 50;
        this.cooldown = 50;
        this.skillLvl = [0,0,0,0];
        this.drawObject();
    }

    //Same as GameObject pos update, except can't go Offscreen
    mainUpdatePos() {
        if ((this.xSpeed>0 && this.x<canvasWidth-this.width) || (this.xSpeed<0 && this.x > 0)){
            this.x += this.xSpeed;
        }
        if ((this.ySpeed>0 && this.y<canvasHeight-this.height) || (this.ySpeed<0 && this.y > 0)){
            this.y += this.ySpeed;
        }        
    }

    bgUpdate() {
        console.log(bgX)
        if ((bgX>canvasWidth-4 && bgX<canvasWidth+4)|| (bgX>-canvasWidth-4 && bgX<-canvasWidth+4)) {
            bgX = 0
        };
        if ((bgY>canvasHeight-4 && bgY<canvasHeight+4)|| (bgY>-canvasHeight-4 && bgY<-canvasHeight+4))
        {
            bgY = 0
        }
        bgX -= this.xSpeed
        bgY -= this.ySpeed
    }

    gainExp (enemy) {
        this.currentExp += enemy.expGiven
    }

    levelUp() {
        if (this.currentExp>=this.expNeeded) {
            this.currentExp = this.currentExp-this.expNeeded;
            this.level += 1;
            this.expNeeded = levels[this.level-1];
            lvlUp();
        }
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

class HpRecovery extends GameObject {
    constructor(x , y, xSpeed, ySpeed, maxSpeed, width, height, imgSrc, HpRecovered, type) {
        super (x , y, xSpeed, ySpeed, maxSpeed, width, height, imgSrc);
        this.HpRecovered = HpRecovered;
        this.fadeTime = 0;
        this.type = type;
        this.drank = false;
    }
}