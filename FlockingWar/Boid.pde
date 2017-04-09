
class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float size;
  float force;
  float maxSpeed;
  
  color strokeColor;
  
  Flock flock;
  
  Boid(float x, float y, Flock owner) {    
    flock = owner;
    
    acceleration = new PVector(0, 0);
    
    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));
    
    position = new PVector(x, y);
    
    strokeColor = owner.strokeColor;
    size = owner.boidSize;
    maxSpeed = owner.boidMaxSpeed;
    force = owner.boidForce;
  }

  void run() {    
    //Always move toward center
    applyForce(seek(FlockingWar.center).mult(0.8));
    
    move();
    borders(true);
    render();
  }

  void applyForce(PVector force) {
    //We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock() {
    PVector sep = separate(flock.boids, flock.sepRadius);   // Separation
    PVector ali = align(flock.boids, flock.aliRadius);      // Alignment
    PVector coh = cohesion(flock.boids, flock.cohRadius);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(flock.sepWeight);
    ali.mult(flock.aliWeight);
    coh.mult(flock.cohWeight);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }
  
  void otherFlock(ArrayList<Boid> boids) {
    PVector sep = separate(boids, 50);
    PVector coh = cohesion(boids, 50);
    
    if(countWithinRadius(boids, 20) > 3) {
       flock.removeBoid(this);
    }
    
    sep.mult(2.0);
    coh.mult(-1);
    applyForce(sep);
    applyForce(coh);
  }
  
  // Method to update position
  void move() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    
    position.add(velocity);
    //Reset acceleration to 0 each cycle
    acceleration.mult(0);
  }

  PVector seek(PVector target) {
    return calcSteer(PVector.sub(target, position)); 
  }

  PVector calcSteer(PVector desired) {
    
    //Scale to maximum speed
    desired.normalize();
    desired.mult(maxSpeed);
    
    //Reynolds: Steering = Desired - Velocity
    desired.sub(velocity);
    desired.limit(force);
    
    return desired;
  }
  
  void render() {
    //Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading() + radians(90);
    
    fill(200, 100);
    stroke(strokeColor);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -size*2);
    vertex(-size, size*2);
    vertex(size, size*2);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders(boolean wrap) {
    if(wrap) {
      if (position.x < -size) position.x = width+size;
      if (position.y < -size) position.y = height+size;
      if (position.x > width+size) position.x = -size;
      if (position.y > height+size) position.y = -size;
    }
    else {
      float margin = 100;
      PVector repel = new PVector();
      
      float t = -1;
      if (position.x < -size + margin)       t = inverseLerp(0,     -size + margin,       max(0, position.x));
      if (position.y < -size + margin)       t = inverseLerp(0,     -size + margin,       max(0, position.y));
      if (position.x > width+size - margin)  t = inverseLerp(width,  width+size-margin,   min(width, position.x));
      if (position.y > height+size - margin) t = inverseLerp(height, height+size-margin,  min(height, position.y));
      
      
      if (t >= 0) {
      
        repel = PVector.sub(FlockingWar.center, position);
        repel.normalize();
        repel.mult(t);
      }
          
      
      repel.mult(FlockingWar.borderWeight);
      applyForce(repel);
    }
  }
  
  float inverseLerp(float min, float max, float mid) {
    return 1-((mid - min) / (max - min));
  }
  
  int countWithinRadius(ArrayList<Boid> boids, float radius) {
    radius = radius * radius;
     
    int count = 0;
    for (Boid other : boids) {
    float d = PVector.sub(position, other.position).magSq();
      if ((d > 0) && (d < radius)) {        
        count++;
      }
    }
    return count;    
  }

  //Separation
  //Calculate average steering vector away from nearby boids  
  PVector separate (ArrayList<Boid> boids, float radius, boolean weight) {
    
    PVector sum = new PVector(0, 0);
    PVector sepVec = new PVector(0,0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      sepVec = PVector.sub(position, other.position); 
      float d = sepVec.magSq();      
      if ((d > 0) && (d < radius*radius)) {
        // Calculate vector pointing away from neighbor            
        
        //sepVec.normalize();        
        if(weight) {
          sepVec.div(d);// Weight by distance
        }     
        
        sum.add(sepVec);        
        count++; // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      sum.div((float)count).normalize();  
      return calcSteer(sum);
    }
    else {
      return sum; 
    }

  }
  PVector separate(ArrayList<Boid> boids, float radius) {
    return separate(boids, radius, true);
  }
  
  //Cohesion
  //For the average position of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids, float radius) {
    
    PVector sum = new PVector(0, 0);
    int count = 0;
    int closest = 0;
    float closestDist = 999999;
    int num = boids.size();
    for (int i = 0; i < num; i++) {
      float d = PVector.sub(position, boids.get(i).position).magSq();
      if((d > 0) && d < (closestDist*closestDist)) {
        closestDist = d;
        closest = i;
      }
      if ((d > 0) && (d < radius*radius)) {
        sum.add(boids.get(i).position); //Add position
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      //Steer towards the position
      return calcSteer(sum.sub(position));
    }
    else if(num > 1){
      //return new PVector(0, 0);
      return calcSteer(PVector.sub(boids.get(closest).position, position));
    }
    
    return new PVector(0,0);
  }
  
  //Alignment
  //For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids, float radius) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.sub(position, other.position).magSq();
      if ((d > 0) && (d < radius*radius)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      return calcSteer(sum);
    } 
    else {
      return new PVector(0, 0);
    }
  }

  
}