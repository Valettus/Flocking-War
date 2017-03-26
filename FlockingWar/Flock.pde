// The Flock (a list of Boid objects)

class Flock {
  private ArrayList<Boid> boids; // An ArrayList for all the boids
  
  int index;
  color strokeColor;
  int size;
  
  Flock(int count, color c, int id) {
    boids = new ArrayList<Boid>(count); // Initialize the ArrayList
    index = id;
    size = count;
    strokeColor = c;
    
    for(int i = 0; i < count; i++) {
       addBoid(random(width), random(height));
    }
  }

  void run(Flock[] allFlocks) {
    
    for (int i = 0; i < size; i++) {
      boids.get(i).flock(boids);  //Passing the entire list of boids to each boid individually
    
      for(Flock f : allFlocks) {
        if(i >= size) { break; }
        if(f.index != index){
          boids.get(i).otherFlock(f.boids);
        }
      }
      
      if(i < size) { boids.get(i).run(); }
    }
  }

  void addBoid(float x, float y) {
    boids.add(new Boid(x,y, strokeColor, this));
  }
  
  void removeBoid(Boid boid) {
    println("Removed Boid " + "(" + boid.position + ") " + (size-1));
    boids.remove(boid);
    size--;
    
  }

}