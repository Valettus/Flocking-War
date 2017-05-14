
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
  
  //Cashed from flocking functions
  PVector averageFriendlyPos;
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
    
    averageFriendlyPos = new PVector(0,0);
  }

  void update() {
    move();
    borders(FlockingWar.wrap);
    render();
    
    friendlyCount = -1;
    attackerCount = 0;
    if(attacking > 0)
      attacking--;
  }

  void applyForce(PVector force) {
    //We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  //Accumulate a new acceleration every frame based on three rules
  void flock() {
    /* This code has been condensed below. Keeping this for clarity.
     *
     * PVector ali = align(flock.boids, flock.aliRadius);
     * // Weight the forces
     * ali.mult(flock.aliWeight);
     * // Add the force vectors to acceleration
     * applyForce(sep);
     */
    
    applyForce(align(flock.boids, flock.aliRadius).mult(flock.aliWeight));
    applyForce(cohesion(flock.boids, flock.cohRadius, true).mult(flock.cohWeight));
    
    if(attacking <= 0) {
      applyForce(separate(flock.boids, flock.sepRadius, true, false).mult(flock.sepWeight));
    } else {
      applyForce(separate(flock.boids, 7).mult(2));
    }
  }

  void otherFlock(ArrayList<Boid> boids) {
    if(FlockingWar.destruction) {
      if (countWithinRadius(boids, 15) > 3) {
        explosions.addExplosion(position, 12, 500, strokeColor, 3);
        PVector ali = align(boids, 20).mult(250); //Find average velocity of attackers for direction of explosion
        explosions.addSpark(position, ali, strokeColor, 2);
        flock.removeBoid(this);
        return;
      }
    }
    
    PVector att = new PVector(0,0);
    if(FlockingWar.hostility)
      att = getAttackVector(boids, 100, true);
    if(att.x == 0 && att.y == 0) {
      if(FlockingWar.avoidOther) {
        //PVector sep = separate(boids, flock.sepOtherRadius, true, false);
        //sep.mult(flock.sepOtherWeight);
        //applyForce(sep);
        applyForce(separate(boids, flock.sepOtherRadius, true, false).mult(flock.sepOtherWeight));
      }
    } else {
      att.mult(1.5);
      applyForce(att);
      attacking = 5;
    }    
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
    //Reset acceleration to 0 each frame
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
    
    //Scale based on speed
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

  // Wraparound or repel edges of screen
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
  
  // Get the vector toward the nearest enemy within radius from either this boid's position, or the average position of friendlies as calculated by cohesion() 
  // IF the number of enemies in that range PLUS the number of enemies targeting this boid,
  // is less than the number of friendlies within radius.
  // Returns (0,0) if conditions fail.
  PVector getAttackVector(ArrayList<Boid> boids, float radius, boolean useAverage) {
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
      if(useAverage)
        d = PVector.sub(averageFriendlyPos, boids.get(i).position).magSq();
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
 
        //Tell the enemy it is being attacked from here
        boids.get(closest).addAttacker(this.position);
        
        //Steer towards the closest enemy
        return seek(boids.get(closest).position);
      }
    }
    
    return new PVector(0, 0);
  }
  
  //Separation
  //Calculate the average vector pointing away from boids within radius
  PVector separate (ArrayList<Boid> boids, float radius, boolean weightDir, boolean weightDist) {

    PVector sum = new PVector(0, 0);
    PVector sepVec = new PVector(0, 0);
    float distFactor = 0;
    int count = 0;
    
    radius = radius*radius; //Working with all squared numbers to avoid the sqrt() function
    
    //For every boid in the system, check if it's too close
    for (Boid other : boids) {
      sepVec = PVector.sub(position, other.position); 
      float d = sepVec.magSq();      
      if ((d > 0) && (d < radius)) {    
      
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
        distFactor = 1 + (distFactor); //start multiplier at 1 (range of 1-2 because inverseLerp() will return 0-1).      
        return calcSteer(sum, distFactor).mult(0.9);
      } else {
        return calcSteer(sum);
      }
    }
    
    return new PVector(0,0);
  }
  PVector separate(ArrayList<Boid> boids, float radius) {
    return separate(boids, radius, true, true);
  }

  //Cohesion
  //Calculate steering vector towards the average position of boids within radius
  //If seek is true and no boids are in range, steer toward nearest one
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
      averageFriendlyPos = sum.copy();
      return calcSteer(sum.sub(position));
    } else if (seek && num > 1) {
      //Steer toward the closest friendly, if none are in range
      return seek(boids.get(closest).position);
    }

    return new PVector(0, 0);
  }

  //Alignment
  //Calculate the average velocity of boids within radius
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