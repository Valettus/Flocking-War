
class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxForce;
  float maxSpeed;
  
  color strokeColor;
  
  Boid(float x, float y, color c) {
    strokeColor = c;
    
    acceleration = new PVector(0, 0);
    
    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));
    
    position = new PVector(x, y);
    r = 2.0;
    maxSpeed = 2;
    maxForce = 0.03;
  }

  void run() {
    //flock(boids);
    update();
    borders(false);
    render();
  }

  void applyForce(PVector force) {
    //We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids, 25);   // Separation
    PVector ali = align(boids);          // Alignment
    PVector coh = cohesion(boids, 50);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(1.0);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }
  
  void otherFlock(ArrayList<Boid> boids) {
    PVector sep = separate(boids, 50);
    //PVector coh = cohesion(boids, 50);    
    
    sep.mult(1.5);
    //coh.mult(-0.5);
    applyForce(sep);
    //applyForce(coh);
  }
  
  // Method to update position
  void update() {
    //Update velocity
    velocity.add(acceleration);
    //Limit speed
    velocity.limit(maxSpeed);
    position.add(velocity);
    //Reset accelertion to 0 each cycle
    acceleration.mult(0);
  }

  PVector calcSteer(PVector desired) {
    //First two lines of code below could be condensed with new PVector setMag() method
    //Not using this method until Processing.js catches up
    //sum.setMag(maxSpeed);
    
    //Scale to maximum speed
    desired.normalize();
    desired.mult(maxSpeed);
    
    //Reynolds: Steering = Desired - Velocity
    desired.sub(velocity);
    desired.limit(maxForce);
    
    return desired;
  }
  
  void render() {
    //Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading2D() + radians(90);
    //heading2D() above is now heading() but leaving old syntax until Processing.js catches up
    
    fill(200, 100);
    stroke(strokeColor);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders(boolean wrap) {
    if(wrap) {
      if (position.x < -r) position.x = width+r;
      if (position.y < -r) position.y = height+r;
      if (position.x > width+r) position.x = -r;
      if (position.y > height+r) position.y = -r;
    }
    else {
      float margin = 100;
      PVector repel = new PVector();
      
      if (position.x < -r + margin) repel.x = inverseLerp(0, -r + margin, max(0, position.x));
      if (position.y < -r + margin) repel.y = inverseLerp(0, -r + margin, max(0, position.y));
      if (position.x > width+r - margin) repel.x = -1*inverseLerp(width, width+r-margin, min(width, position.x));
      if (position.y > height+r - margin) repel.y = -1*inverseLerp(height, height+r-margin, min(height, position.y));
    
      repel.mult(0.1);
      applyForce(repel);
    }
  }
  
  float inverseLerp(float min, float max, float mid) {
    return 1-((mid - min) / (max - min));
  }
  

  //Separation
  //Calculate average steering vector away from nearby boids  
  PVector separate (ArrayList<Boid> boids, float radius, boolean weight) {
    
    PVector sum = new PVector(0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);      
      if ((d > 0) && (d < radius)) {
        // Calculate vector pointing away from neighbor        
        PVector sepVec = PVector.sub(position, other.position);        
        
        sepVec.normalize();        
        if(weight) {
          sepVec.div(d);// Weight by distance
        }        
        sum.add(sepVec);        
        count++; // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      sum.div((float)count);  
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
      if(d > 0 && d < closestDist*closestDist) {
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
    else {
      //return new PVector(0, 0);
      return calcSteer(PVector.sub(boids.get(closest).position, position));
    }
  }
  
  //Alignment
  //For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
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