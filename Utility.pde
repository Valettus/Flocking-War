
float average(float n1, float n2) {
  return (n1 + n2) * 0.5;
}

float inverseLerp(float min, float max, float mid) {
  return (mid - min) / (max - min);
}

color brightenColor(color c) {
  int r = (c >> 16) & 0xFF;
  int g = (c >> 8) & 0xFF;
  int b = c & 0xFF;
  
  int biggest = (r > g) ? r : g;  
  biggest = (biggest > b) ? biggest : b;
  
  float percentIncrease = (float)255/biggest;
  
  return color(r*percentIncrease, g*percentIncrease, b*percentIncrease);
}