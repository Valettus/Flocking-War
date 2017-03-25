// The Flock (a list of Boid objects)

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  
  int index;
  color strokeColor;
  
  Flock(int count, color c, int id) {
    boids = new ArrayList<Boid>(count); // Initialize the ArrayList
    index = id;
    strokeColor = c;
    
    for(int i = 0; i < count; i++) {
       addBoid(random(width), random(height));
    }
  }

  void run() {
    for (Boid b : boids) {
      b.run(boids);  //Passing the entire list of boids to each boid individually
    }
  }

  void addBoid(float x, float y) {
    boids.add(new Boid(x,y, strokeColor));
  }

}