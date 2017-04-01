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

int numFlocks = 4;
int maxBoids = 400;
Flock[] flocks;

void setup() {
  size(1280, 720);
  flocks = new Flock[numFlocks];
  //initialize flocks
  for (int i = 0; i < numFlocks; i++) {
    flocks[i] = new Flock(maxBoids/numFlocks, color(random(255), 255 * ((float)i/(numFlocks-1)),255 * (1-((float)i/(numFlocks-1)))), i);
  }
}

void draw() {
  background(50);
  
  for(int i = 0; i < numFlocks; i++) {
    flocks[i].run(flocks);
  }
  
  text("FPS: " + frameRate, 10, 20);
}

// Add a new boid into the System
void mousePressed() {
  flocks[0].addBoid(mouseX, mouseY);
}