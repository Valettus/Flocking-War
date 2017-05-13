/**
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
 #Reset simulation without restart.
 #Flanking/surrounding (this may not be possible without managing behavior at the flock level)
 #Toggle hostility
 #Toggle avoiding other flocks
 #Toggle border wrapping/repel
 #Random placement of all boids, or place each flock together (eg, in a corner) at start
 #Toggle randomness
 #Implement deltaTime
 #Experiment with removing Boid.calcSteer and replace with simple velocity, acceleration, and damping.
 --Every property would need to be re-tuned to get good behavior again.
 --But, if the flocking still works with this change, it would remove several vector operations per boid per frame, including normalize().
 #
 */

int numFlocks = 2;
int maxBoids = 300;
Flock[] flocks;
ExplosionManager explosions;

public static PVector center;
public static float borderWeight = 0.2;
public static boolean wrap = false;
public static float deltaTime = 16.667;

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
  size(1280, 720); //<>//
  center = new PVector(width/2, height/2);

  flocks = new Flock[numFlocks];
  explosions = new ExplosionManager(20);
  //initialize flocks
  for (int i = 0; i < numFlocks; i++) {
    flocks[i] = initializeFlock(i, maxBoids/numFlocks, color(random(255), 255 * ((float)i/(numFlocks-1)), 255 * (1-((float)i/(numFlocks-1)))));
  }
}

void draw() {
  background(96);

  for (int i = 0; i < numFlocks; i++) {
    flocks[i].run(flocks);
  }

  explosions.run();
  
  fill(128);
  text("FPS: " + frameRate, 10, 20);
}

void keyPressed() {
   
}

void mousePressed() {
  explosions.addExplosion(new PVector(mouseX, mouseY), 30, 500, 255, 4);
  explosions.addSpark(new PVector(mouseX, mouseY), 20, 255, 10);
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
    flock.initializeBoids(maxBoids/numFlocks);
  } else {
    flock.setBoidProperties(c, 
      average(minSize, maxSize), //size
      average(minSpeed, maxSpeed), //speed
      average(minForce, maxForce)); //force
    flock.setFlockingWeights(average(minSep, maxSep), average(minAli, maxAli), average(minCoh, maxCoh), maxTotalWeight);
    flock.setFlockingRadius(average(minSepR, maxSepR), average(minAliR, maxAliR), average(minCohR, maxCohR));
    flock.setFlockAvoidanceProperties(average(minOtherSep, maxOtherSep), average(minOtherCoh, maxOtherCoh), 
      average(minOtherSepR, maxOtherSepR), average(minOtherCohR, maxOtherCohR));
    flock.initializeBoids(count);
  }

  return flock;
}