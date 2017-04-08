/**
 * Flocking War
 * Christopher Kaiser
 *
 * -Based on the Flocking example that comes with processing implementated by Daniel Shiffman. 
 * --An implementation of Craig Reynold's Boids program to simulate
 * --the flocking behavior of birds. Each boid steers itself based on 
 * --rules of avoidance, alignment, and coherence.
 *
 */

/*
TODO Before putting on GitHub:
#Randomized parameters per flock (stored on flock class, accessed by Boids):
  -Boid
   -size
   -maxSpeed
   -maxForce
   -weight on all flocking functions in flock() and otherFlock()
   -*color
  -Also slightly different values per boid (maybe, would add a bit of memory)
#Ability to modify parameters at runtime
  -Above parameters
  -number of flocks (after reset)
#Reset simulation without restart.
#Actual aggressive functionality
-When a higher percentage (parameter) of friendlies are in range, move toward the enemies rather than away
-Flanking/surrounding (this may not be possible without managing behavior at the flock level)
#Toggle hostility
#Toggle avoiding other flocks
#Toggle border wrapping/repel


*/

int numFlocks = 2;
int maxBoids = 400;
Flock[] flocks;

public static PVector center;
public static float borderWeight = 0.2;

void setup() {
  size(1280, 720);
  center = new PVector(width/2, height/2);
  
  flocks = new Flock[numFlocks];
  //initialize flocks
  for (int i = 0; i < numFlocks; i++) {
    flocks[i] = new Flock(maxBoids/numFlocks, color(random(255), 255 * ((float)i/(numFlocks-1)),255 * (1-((float)i/(numFlocks-1)))), i);
  }
}

void draw() {
  background(128);
  
  for(int i = 0; i < numFlocks; i++) {
    flocks[i].run(flocks);
  }
  
  text("FPS: " + frameRate, 10, 20);
}

// Add a new boid into the System
void mousePressed() {
  flocks[0].addBoid(mouseX, mouseY);
}