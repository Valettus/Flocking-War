
class Explosion {
  boolean _alive = false;
  float   _duration = 500; //milliseconds
  float   _startTime = 0;
  float   _size = 25;
  color   _color = 255;

  boolean _shockwave = false;

  PVector _pos;

  void init(PVector pos, float size, float duration, color c, boolean shockwave) {
    _alive = true;
    _startTime = millis();

    _pos = pos;
    _size = random(size * 0.5, size);
    _duration = random(duration * 0.8, duration * 1.2);

    _color = c;
    _shockwave = shockwave;
  }
  void init(PVector pos, float size, float duration, color c) {
    init(pos, size, duration, c, false);
  }

  void run() {
    if (!_alive)
      return;

    float t = inverseLerp(_startTime + _duration, _startTime, millis());
    if (t < 0) {
      _alive = false;
    } else {
      render(t);
    }
  }

  void render(float t) {
    //fill(_color, lerp(64, 255, t));
    fill(_color);
    noStroke();

    float d = _size * 2 * sin(PI*t);
    ellipse(_pos.x, _pos.y, d, d);

    if (_shockwave) {
      d = _size * 10 * sin(HALF_PI+HALF_PI*t);
      stroke(_color, 255*t);
      strokeWeight(2);
      noFill();
      ellipse(_pos.x, _pos.y, d, d);
    }
  }
}

class Spark {
  boolean _alive = false;
  PVector _pos;
  PVector _vel;  
  float _damp = 0.9;
  color _color;

  void init(PVector pos, PVector velocity, color c) {
    _alive = true;

    _pos = pos.copy(); 

    float speed = velocity.mag() * 0.5;
    _vel = PVector.random2D();
    _vel.mult(random(speed * 0.5, speed * 1.5));
    _vel.add(velocity);
    _vel.mult(0.5);

    _color = c;
  }
  void init(PVector pos, float speed, color c) {
    _alive = true;

    _pos = pos.copy();

    _vel = PVector.random2D();
    _vel.mult(random(speed * 0.5, speed * 1.5));

    _color = c;
  }

  void run() {
    if (!_alive)
      return;

    _vel.mult(_damp);
    if (_vel.magSq() < 1) {
      _alive = false;
    } else {

      PVector p1 = PVector.sub(_pos, _vel);
      PVector p2 = PVector.add(_pos, _vel);
      render(p1, p2);
      _pos = p2;
    }
  }

  void render(PVector p1, PVector p2) {
    stroke(_color);
    strokeWeight(1);
    line(p1.x, p1.y, p2.x, p2.y);
    strokeWeight(3);
    line(_pos.x, _pos.y, p2.x, p2.y);
  }
}

class ExplosionManager {
  Explosion[] _ePool;
  Spark[] _sPool;
  int _eIndex = 0;
  int _sIndex = 0;
  int len;

  float _size = 25;
  float _duration = 500;

  ExplosionManager(int poolSize) {
    _ePool = new Explosion[poolSize];
    _sPool = new Spark[poolSize];
    len = poolSize;

    for (int i = 0; i < len; i++) {
      _ePool[i] = new Explosion();
      _sPool[i] = new Spark();
    }
  }

  void addExplosion(PVector pos, float size, float duration, color c, int detail) {
    _eIndex++;
    if (_eIndex == len)
      _eIndex = 0;
    Explosion e = _ePool[_eIndex];

    if (detail > 1) {
      e.init(PVector.add(pos, PVector.random2D().mult(size*0.33)), size, duration, c);

      addExplosion(pos, size, duration, c, detail-1);
    } else {
      e.init(pos, size, duration, c, true);
    }
  }

  void addSpark(PVector pos, PVector velocity, color c, int detail) {
    _sIndex++;
    if (_sIndex == len)
      _sIndex = 0;

    Spark s = _sPool[_sIndex];
    s.init(pos, velocity, c);

    if (detail > 0)
      addSpark(pos, velocity, c, detail-1);
  }
  void addSpark(PVector pos, float speed, color c, int detail) {
    _sIndex++;
    if (_sIndex == len)
      _sIndex = 0;

    Spark s = _sPool[_sIndex];
    s.init(pos, speed, c);

    if (detail > 0)
      addSpark(pos, speed, c, detail-1);
  }

  void run() {
    for (int i = 0; i < len; i++) {
      _ePool[i].run();
      _sPool[i].run();
    }
  }
}