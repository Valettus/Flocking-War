
float average(float n1, float n2) {
  return (n1 + n2) * 0.5; 
}

float inverseLerp(float min, float max, float mid) {
  return 1-((mid - min) / (max - min));
}