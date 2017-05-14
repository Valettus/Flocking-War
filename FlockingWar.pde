/** //<>//
 * Flocking War
 * Christopher Kaiser
 *
 * -Based on the Flocking example that comes with processing implemented by Daniel Shiffman. 
 * --An implementation of Craig Reynold's Boids program to simulate
 * --the flocking behavior of birds. Each boid steers itself based on 
 * --rules of avoidance, alignment, and coherence.
 *
 */

/*
TODO:
 #Ability to modify parameters at runtime
 --Above parameters
 --number of flocks (after reset)
 #*Reset simulation without restart.
 #Flanking/surrounding (this may not be possible without managing behavior at the flock level)
 #Toggle hostility
 #Toggle avoiding other flocks
 #*Toggle border wrapping/repel
 #*Random placement of all boids, or place each flock together (eg, in a corner) at start
 #*Toggle randomness
 #Implement deltaTime
 #Experiment with removing Boid.calcSteer and replace with simple velocity, acceleration, and damping.
 --Every property would need to be re-tuned to get good behavior again.
 --But, if the flocking still works with this change, it would remove several vector operations per boid per frame, including normalize().
 #
 */

int numFlocks = 1;
int numBoids = 300;
Flock[] flocks;
ExplosionManager explosions;

public static PVector center;
public static float borderWeight = 0.2;
public static boolean wrap = false;
public static float deltaTime = 16.667;

String[] options = {"Flock Count: ", "Boid Count: ", "Spawn Mode: ", "Boid Properties: ", "Border Mode: "};
int optionIndex = 0;
int numOptions = 3;
boolean optionsActive = false;
boolean hideText = false;

boolean randomSpawn = true;
boolean randomizeProperties = true;

//--Boid and Flock properties--
float minSize = 1.5;
float maxSize = 3;
float minSpeed = 1.5;
float maxSpeed = 3;
float minForce = 0.03;
float maxForce = 0.08;

float minSep = 1.5;
float maxSep = 2.5;
float minAli = 0;
float maxAli = 2;
float minCoh = 0.7;
float maxCoh = 2;
float maxTotalWeight = 4;

float minSepR = 25;
float maxSepR = 40;
float minAliR = 25;
float maxAliR = 75;
float minCohR = 15;
float maxCohR = 60;

float minOtherSepR = 25;
float maxOtherSepR = 75;
float minOtherCohR = 25;
float maxOtherCohR = 75;
float minOtherSep = 1;
float maxOtherSep = 3;
float minOtherCoh = -2;
float maxOtherCoh = -0.5;
//-----

void setup() {
  size(1280, 720);
  center = new PVector(width/2, height/2);

  explosions = new ExplosionManager(30);

  Restart();
}

void draw() {
  background(96);
  int count = flocks.length;
  for (int i = 0; i < count; i++) {
    flocks[i].run(flocks);
  }

  explosions.run();

  if (!hideText) {
    fill(64);
    textSize(12);
    text("FPS: " + frameRate, 10, 20);

    deltaTime = 1000/frameRate;

    options();
  }
}

void options() {
  PVector pos = new PVector(10, 40);
  float lineSpace = 20;
  
  fill(200);
  text("Hide Text: 'h'", pos.x, pos.y);
  
  fill(255);  
  pos.y += lineSpace;
  text("Restart: Spacebar", pos.x, pos.y);

  

  pos.y += lineSpace;
  text("Toggle Options: 'o'", pos.x, pos.y);

  if (optionsActive) {
    pos.y += lineSpace/2;
    stroke(255);
    strokeWeight(2);
    line(pos.x, pos.y, pos.x + 100, pos.y);

    pos.y += lineSpace;
    fill(200);
    text("(Navigate with arrow keys)", pos.x, pos.y);

    fill(255);
    for (int i = 0; i < options.length; i++) {
      pos.y += lineSpace;
      if (i == optionIndex) {
        strokeWeight(1);
        line(pos.x, pos.y+2, pos.x + 100, pos.y+2);
      }
      text(options[i], pos.x, pos.y);
    }

    textSize(12);
    //0
    pos.y -= lineSpace * (options.length-1);
    pos.x = 120;
    text(numFlocks, pos.x, pos.y);
    //1
    pos.y += lineSpace;
    text(numBoids, pos.x, pos.y);
    //2
    pos.y += lineSpace;
    if (randomSpawn)
      text("Random", pos.x, pos.y);
    else
      text("Groups", pos.x, pos.y);
    //3
    pos.y += lineSpace;
    if (randomizeProperties)
      text("Random Per Flock", pos.x, pos.y);
    else
      text("Fixed", pos.x, pos.y);
    //4
    pos.y += lineSpace;
    if (wrap)
      text("Wrap", pos.x, pos.y);
    else
      text("Repel", pos.x, pos.y);
  }
}

void keyPressed() {
  if (key == CODED) {
    if (!optionsActive || hideText)
      return;

    if (keyCode == UP) {
      optionIndex--;
      if (optionIndex < 0)
        optionIndex = options.length-1;
    } else if (keyCode == DOWN) {
      optionIndex = (optionIndex+1) % options.length;
    }

    int keyDir = 0;
    if (keyCode == LEFT)
      keyDir = -1;
    else if (keyCode == RIGHT)
      keyDir = 1;

    if (keyDir != 0) {
      switch(optionIndex) {
      case 0:
        numFlocks = constrain(numFlocks+keyDir, 1, 10);
        break;
      case 1:
        numBoids = constrain(numBoids+keyDir*10, numFlocks*10, 10000);
        break;
      case 2:
        randomSpawn = !randomSpawn;
        break;
      case 3:
        randomizeProperties = !randomizeProperties;
        break;
      case 4:
        wrap = !wrap;
        break;
      }
    }
  } else {
    if (key == ' ') {
      Restart();
    } 
    if (key == 'o' || key == 'O') {
      optionsActive = !optionsActive;
    }
    if(key == 'h' || key == 'H') {
      hideText = !hideText; 
    }
  }
}

void mousePressed() {
  explosions.addExplosion(new PVector(mouseX, mouseY), 30, 500, 255, 4);
  explosions.addSpark(new PVector(mouseX, mouseY), 20, 255, 10);
}

void Restart() {
  flocks = new Flock[numFlocks];
  //initialize flocks
  for (int i = 0; i < numFlocks; i++) {
    flocks[i] = initializeFlock(i, numBoids/numFlocks, color(random(255), 255 * ((float)i/(numFlocks-1)), random(255)));
  }
}

Flock initializeFlock(int index, int count, color c) {
  Flock flock = new Flock(index);

  if (randomizeProperties) {
    flock.setBoidProperties(c, 
      random(minSize, maxSize), //size
      random(minSpeed, maxSpeed), //speed
      random(minForce, maxForce)); //force
    flock.setFlockingWeights(random(minSep, maxSep), random(minAli, maxAli), random(minCoh, maxCoh), maxTotalWeight);
    flock.setFlockingRadius (random(minSepR, maxSepR), random(minAliR, maxAliR), random(minCohR, maxCohR));
    flock.setFlockAvoidanceProperties(random(minOtherSep, maxOtherSep), random(minOtherCoh, maxOtherCoh), 
      random(minOtherSepR, maxOtherSepR), random(minOtherCohR, maxOtherCohR));
    
  } else {
    flock.setBoidProperties(c, 
      average(minSize, maxSize), //size
      average(minSpeed, maxSpeed), //speed
      average(minForce, maxForce)); //force
    flock.setFlockingWeights(average(minSep, maxSep), average(minAli, maxAli), average(minCoh, maxCoh), maxTotalWeight);
    flock.setFlockingRadius(average(minSepR, maxSepR), average(minAliR, maxAliR), average(minCohR, maxCohR));
    flock.setFlockAvoidanceProperties(average(minOtherSep, maxOtherSep), average(minOtherCoh, maxOtherCoh), 
      average(minOtherSepR, maxOtherSepR), average(minOtherCohR, maxOtherCohR));
    
  }
  
  if(randomSpawn)
      flock.initializeBoids(count);
    else
      flock.initializeBoids(count, new PVector(random(width), random(height)));
  return flock;
}