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

int numFlocks = 2;
Flock[] flocks;

void setup() {
  size(1280, 720);
  flocks = new Flock[numFlocks];
  //initiate flocks
  for (int i = 0; i < numFlocks; i++) {
    flocks[i] = new Flock(100, color(random(255),random(255),random(255)), i);
  }
}

void draw() {
  background(50);
  
  for(int i = 0; i < numFlocks; i++) {
    flocks[i].run();
  }
  
  text("FPS: " + frameRate, 10, 20);
}

// Add a new boid into the System
void mousePressed() {
  flocks[0].addBoid(mouseX, mouseY);
}