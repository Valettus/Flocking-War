// The Flock (a list of Boid objects)

class Flock {
  private ArrayList<Boid> boids; // An ArrayList for all the boids

  int flockSize;
  int id;
  color strokeColor = 0;
  float boidSize = 2;
  float boidMaxSpeed = 2;
  float boidForce = 0.03;

  float sepWeight = 1.5;
  float aliWeight = 1;
  float cohWeight = 1.2;
  float sepRadius = 25;
  float aliRadius = 50;
  float cohRadius = 50;

  float sepOtherWeight = 2;
  float cohOtherWeight = -1;
  float sepOtherRadius = 50;
  float cohOtherRadius = 50;

  boolean initialized = false;

  Flock(int index) {
    id = index;
  }

  void setBoidProperties(color c, float size, float maxSpeed, float force) {
    strokeColor = c;
    boidSize = size;
    boidMaxSpeed = maxSpeed;
    boidForce = force;

    if (initialized) {
      for (Boid b : boids) {
        b.strokeColor = c;
        b.size = size;
        b.maxSpeed = maxSpeed;
        b.force = force;
      }
    }
  }

  void setFlockingWeights(float sep, float ali, float coh, float maxTotalWeight) {
    sepWeight = sep;
    aliWeight = ali;
    cohWeight = coh;

    if (sep + ali + coh > maxTotalWeight) {
      float f = maxTotalWeight / (sep + ali + coh);
      sep *= f;
      ali *= f;
      coh *= f;
    }
  }

  void setFlockingRadius(float sep, float ali, float coh) {
    sepRadius = sep;
    aliRadius = ali;
    cohRadius = coh;
  }

  void setFlockAvoidanceProperties(float sepW, float cohW, float sepR, float cohR) {
    sepOtherWeight = sepW;
    cohOtherWeight = cohW;
    sepOtherRadius = sepR;
    cohOtherRadius = cohR;
  }

  void initializeBoids(int count) {

    boids = new ArrayList<Boid>(flockSize);

    for (int i = 0; i < count; i++) {
      addBoid(random(width), random(height));
    }
    flockSize = count;

    initialized = true;
  }

  void run(Flock[] allFlocks) {

    for (int i = 0; i < flockSize; i++) {
      boids.get(i).flock();  //Passing the entire list of boids to each boid individually

      for (Flock f : allFlocks) {
        if (i >= flockSize) { 
          break;
        }
        if (f.id != id) {
          boids.get(i).otherFlock(f.boids);
        }
      }

      if (i < flockSize) { 
        boids.get(i).update();
      }
    }
  }

  void addBoid(float x, float y) {
    boids.add(new Boid(x, y, this));
    flockSize++;
  }

  void removeBoid(Boid boid) {
    //println("Removed Boid " + "(" + boid.position + ") " + (flockSize-1));
    boids.remove(boid);
    flockSize--;
  }
}