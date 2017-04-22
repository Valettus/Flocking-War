
class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float size;
  float force;
  float maxSpeed;

  color strokeColor;

  Flock flock;
  
  byte attacking = 0;
  
  //Stored from flocking functions
  PVector cohAverage;
  int friendlyCount = -1;
  int attackerCount = 0;
  
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
    
    cohAverage = new PVector(0,0);
  }

  void update() {    
    //Always move toward center
    //applyForce(seek(FlockingWar.center).mult(0.5));

    move();
    borders(FlockingWar.wrap);
    render();
    
    friendlyCount = -1;
    attackerCount = 0;
    attacking--;
  }

  void applyForce(PVector force) {
    //We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock() {
    //PVector sep = separate(flock.boids, flock.sepRadius);   // Separation
    PVector ali = align(flock.boids, flock.aliRadius);      // Alignment
    PVector coh = cohesion(flock.boids, flock.cohRadius, true);   // Cohesion
    // Arbitrarily weight these forces
    //sep.mult(flock.sepWeight);
    ali.mult(flock.aliWeight);
    coh.mult(flock.cohWeight);
    // Add the force vectors to acceleration
    //applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    
    if(attacking <= 0) {
      applyForce(separate(flock.boids, flock.sepRadius).mult(flock.sepWeight));
    } else {
      applyForce(separate(flock.boids, 7).mult(2));
    }
  }

  void otherFlock(ArrayList<Boid> boids) {
    if (countWithinRadius(boids, 15) > 3) {
      explosions.addExplosion(position, 12, 500, strokeColor, 3);
      PVector ali = align(boids, 20).mult(250); //Find average velocity of attackers for direction of explosion
      explosions.addSpark(position, ali, strokeColor, 2);
      flock.removeBoid(this);
    }
    
    PVector att = getAttackVector(boids, 100, false);
    if(att.x == 0 && att.y == 0) {
      PVector sep = separate(boids, flock.sepOtherRadius, true, false);
      sep.mult(flock.sepOtherWeight);
      applyForce(sep);
    } else {
      att.mult(1.5);
      applyForce(att);
      attacking = 5;
    }
    
    
    
    //PVector coh = cohesion(boids, flock.cohOtherRadius, false);
    //coh.mult(flock.cohOtherWeight); 
      
    
    //applyForce(coh);
    
  }
  
  void addAttacker(PVector attackerPos) {
    applyForce(flee(attackerPos).mult(0.3));
    attackerCount++;
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
  
  PVector flee(PVector target) {
    return calcSteer(PVector.sub(position, target));
  }

  PVector calcSteer(PVector desired, float multiplier) {
    return calcSteer(desired).mult(multiplier);
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
    
    float f = inverseLerp(maxSpeed*maxSpeed, 0, velocity.magSq()); 
    float bLength = size * (2.5 - f);
    float bWidth = size * lerp(0.7, 1.3, f);
    
    fill(strokeColor, 50);
    stroke(strokeColor);
    strokeWeight(1);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -bLength);
    vertex(-bWidth, bLength);
    vertex(bWidth, bLength);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders(boolean wrap) {
    if (wrap) {
      if (position.x < -size) position.x = width+size;
      if (position.y < -size) position.y = height+size;
      if (position.x > width+size) position.x = -size;
      if (position.y > height+size) position.y = -size;
    } else {
      float margin = 100;
      PVector repel = new PVector();

      float t = -1;
      if (position.x < margin)          t = inverseLerp(margin, 0, max(0, position.x));
      if (position.y < margin)          t = inverseLerp(margin, 0, max(0, position.y));
      if (position.x > width - margin)  t = inverseLerp(width-margin, width, min(width, position.x));
      if (position.y > height - margin) t = inverseLerp(height-margin, height, min(height, position.y));


      if (t >= 0) {

        repel = PVector.sub(FlockingWar.center, position);
        repel.normalize();
        repel.mult(t);
      }


      repel.mult(FlockingWar.borderWeight);
      applyForce(repel);
    }
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
  
  PVector getAttackVector(ArrayList<Boid> boids, float radius, boolean group) {
    int num = boids.size();
    if(num == 0)
      return new PVector (0,0);
    
    //friendlyCount will be -1 if it has not been calculated this frame
    if(friendlyCount == -1)
      friendlyCount = countWithinRadius(flock.boids, radius);
    
    radius = radius*radius;
    
    int enemyCount = 0;
    int closest = 0;
    float closestDist = radius;
    
    for (int i = 0; i < num; i++) {
      float d;
      if(group)
        d = PVector.sub(cohAverage, boids.get(i).position).magSq();
      else
        d = PVector.sub(position, boids.get(i).position).magSq();
      
      if ((d > 0) && (d < radius)) {
        if (d < closestDist) {
          closestDist = d;
          closest = i;          
        }
        
        enemyCount++;      
      }
    }
    
    if(enemyCount > 0) {
      if (friendlyCount > (enemyCount + attackerCount)) {
        /*
        PVector c = boids.get(closest).position;
        fill(strokeColor);
        stroke(strokeColor);
        strokeWeight(3);
        ellipse(c.x, c.y, 10,10);
        
        if(group)
          line(cohAverage.x, cohAverage.y, c.x, c.y);
        else
          line(position.x, position.y, c.x, c.y);
        
        println("Index-" + closest + " E-" + (enemyCount + attackerCount) + " F-" + friendlyCount);
        */
        //Steer towards the closest enemy
        boids.get(closest).addAttacker(this.position);
        return seek(boids.get(closest).position);
      }
    }
    
    if(attackerCount > 0)
      println(attackerCount);
    
    return new PVector(0, 0);
  }
  
  //Separation
  //Calculate average steering vector away from nearby boids  
  PVector separate (ArrayList<Boid> boids, float radius, boolean weightDir, boolean weightDist) {

    PVector sum = new PVector(0, 0);
    PVector sepVec = new PVector(0, 0);
    float distFactor = 0;
    int count = 0;
    
    radius = radius*radius; //Working with all squared numbers to avoid the sqrt() function
    
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      sepVec = PVector.sub(position, other.position); 
      float d = sepVec.magSq();      
      if ((d > 0) && (d < radius)) {
        // Calculate vector pointing away from neighbor            

        //sepVec.normalize();        
        if (weightDir) {
          sepVec.div(d);//Weight direction by distance
        }
        distFactor += (radius - d); //For weighting force by distance

        sum.add(sepVec);
        count++; //Keep track of how many are in range
      }
    }

    if (count > 0) {      
      // Average
      sum.div((float)count);     

      if (weightDist) {
        distFactor /= (float)count; //Average
        distFactor = inverseLerp(0, radius, distFactor); //Get percentage of max distance
        distFactor = 1 + (distFactor); //start multiplier at 1 (range of 1-2).      
        return calcSteer(sum, distFactor).mult(0.9);
      } else {
        return calcSteer(sum);
      }
    } else {
      return sum;
    }
  }
  PVector separate(ArrayList<Boid> boids, float radius) {
    return separate(boids, radius, true, true);
  }

  //Cohesion
  //For the average position of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids, float radius, boolean seek) {
  
    radius = radius*radius;
    
    PVector sum = new PVector(0, 0);
    int count = 0;
    int closest = 0;
    float closestDist = radius;
    int num = boids.size();
    
    
    
    for (int i = 0; i < num; i++) {
      float d = PVector.sub(position, boids.get(i).position).magSq();
      if(seek) {
        if ((d > 0) && d < (closestDist)) {
          closestDist = d;
          closest = i;
        }
      }
      
      if ((d > 0) && (d < radius)) {
        sum.add(boids.get(i).position); //Add position
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      //Steer towards the position
      cohAverage = sum.copy();
      return calcSteer(sum.sub(position));
    } else if (seek && num > 1) {
      //Steer toward the closest friendly, if none are in range
      return seek(boids.get(closest).position);
    }

    return new PVector(0, 0);
  }

  //Alignment
  //For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids, float radius) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    
    radius = radius*radius;
    
    for (Boid other : boids) {
      float d = PVector.sub(position, other.position).magSq();
      if ((d > 0) && (d < radius)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      return calcSteer(sum);
    } else {
      return new PVector(0, 0);
    }
  }
}