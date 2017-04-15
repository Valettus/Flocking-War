
class Explosion {
  boolean alive = false;
  float duration = 500; //milliseconds
  float startTime = 0;
  float size = 25;
  color fill = 255;
  
  PVector center;
  int detail = 3;
  PVector[] circles;
  float[] diameters;
  
  Explosion() {
    circles = new PVector[detail];
    diameters = new float[detail];
  }
  
  void init(PVector pos, color c) {
    alive = true;
    startTime = millis();
    
    center = pos;
    for(int i = 0; i < detail; i++) {
      
      circles[i] = PVector.add(pos, PVector.random2D().mult(size*0.5));
      println(circles[i]);
      diameters[i] = random(size * 0.5, size);
    }
    
    fill = c;
  }
  
  void run() {
    if(!alive)
      return;
    
    float t = inverseLerp(startTime + duration, startTime, millis());
    if(t < 0) {
      alive = false;
    } else {
       render(t);
    }
  }
  
  void render(float t) {
    fill(fill);
    noStroke();
    //float d = size * sin(PI*lerp(0.6, 0, t));
    float sin2 = 2 * sin(PI*t);
    float d = size * sin2;
    ellipse(center.x, center.y, d, d);
    for(int i = 0; i < detail; i++) {
      d = diameters[i] * sin2;
      ellipse(circles[i].x, circles[i].y, d, d);
    }
    //ellipse(center.x, center.y, d, d);
    d = size * sin2;
    ellipse(center.x, center.y, d, d);
    
  }
}

class ExplosionManager {
  Explosion[] pool;
  int current = 0;
  int len;
  
  ExplosionManager(int count) {
     pool = new Explosion[count];
     len = count;
     
     for(int i = 0; i < len; i++) {
       pool[i] = new Explosion(); 
     }
  }
  
  void addExplosion(PVector pos, color c) {
    current++;
    if(current == len)
      current = 0;
    
    pool[current].init(pos, c);
  }
  
  void run() {
    for(int i = 0; i < len; i++) {
      pool[i].run(); 
    }
  }
}