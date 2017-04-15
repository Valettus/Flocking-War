
class Explosion {
  boolean alive = false;
  float _duration = 500; //milliseconds
  float startTime = 0;
  float _size = 25;
  color fill = 255;
  
  PVector _pos;
  
  void init(PVector pos, float size, float duration, color c) {
    alive = true;
    startTime = millis();
    
    _pos = pos;
    _size = random(size * 0.5, size);
    _duration = random(duration * 0.8, duration * 1.2);
    
    fill = c;
  }
  
  void run() {
    if(!alive)
      return;
    
    float t = inverseLerp(startTime + _duration, startTime, millis());
    if(t < 0) {
      alive = false;
    } else {
       render(t);
    }
  }
  
  void render(float t) {
    fill(fill);
    noStroke();
    
    float d = _size * 2 * sin(PI*t);
    ellipse(_pos.x, _pos.y, d, d);
    
  }
}

class ExplosionManager {
  Explosion[] pool;
  int current = 0;
  int len;
  
  float size = 25;
  float duration = 500;
  
  ExplosionManager(int poolSize) {
     pool = new Explosion[poolSize];
     len = poolSize;
     
     for(int i = 0; i < len; i++) {
       pool[i] = new Explosion(); 
     }
  }
  
  void addExplosion(PVector pos, color c, int detail) {
    current++;
    if(current == len)
      current = 0;
    Explosion e = pool[current];
    
    if(detail > 1) {
      e.init(PVector.add(pos, PVector.random2D().mult(size*0.33)), size, duration, c);
      addExplosion(pos, c, detail-1);      
    } else {
      e.init(pos, size, duration, c);
    }
  }
  
  void run() {
    for(int i = 0; i < len; i++) {
      pool[i].run(); 
    }
  }
}