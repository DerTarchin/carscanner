PVector[][] points;
int nRows = 17; 
int nCols = 21; 

import peasy.*;
PeasyCam cam;

void setup() {
  size(500, 500, P3D); 
  points = new PVector[nRows][nCols]; 
  for (int row=0; row<nRows; row++) {
    for (int col = 0; col<nCols; col++) {
      float x = (col - (nCols/2))* 10; 
      float y = (row - (nRows/2))* 10; 
      float z = random(0, 16); 
      points[row][col] = new PVector(x, y, z);
    }
  }
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(500);
}

void draw() {
  background(0); 
  noStroke() ; 
  strokeWeight(1);
  float dirY = (mouseY / float(height) - 0.5) * 2;
  float dirX = (mouseX / float(width) - 0.5) * 2;
  colorMode(HSB, 360, 100, 100);
  directionalLight(265, 13, 90, -dirX, -dirY, -1);
  
  directionalLight(137, 13, 90, dirX, dirY, 1);
  colorMode(RGB, 255);

  rotateX(-.5);
  rotateY(-.5);

  pushMatrix(); 
  translate(0, 0, 20);
  fill(255, 200, 200); 

  beginShape(TRIANGLES);
  for (int row=0; row<(nRows-1); row++) {
    for (int col = 0; col<(nCols-1); col++) {
      float x0 = points[row][col].x;
      float y0 = points[row][col].y;
      float z0 = points[row][col].z;

      float x1 = points[row][col+1].x;
      float y1 = points[row][col+1].y;
      float z1 = points[row][col+1].z;

      float x2 = points[row+1][col].x;
      float y2 = points[row+1][col].y;
      float z2 = points[row+1][col].z;

      float x3 = points[row+1][col+1].x;
      float y3 = points[row+1][col+1].y;
      float z3 = points[row+1][col+1].z;

      vertex(x0, y0, z0); 
      vertex(x1, y1, z1); 
      vertex(x2, y2, z2); 

      vertex(x2, y2, z2); 
      vertex(x1, y1, z1); 
      vertex(x3, y3, z3);
    }
  }
  endShape();

  fill(255, 0, 0);
  beginShape();
  vertex(-10, -10, 0);
  vertex(-10, 10, 0);
  vertex(10, 10, 0);
  vertex(10, -10, 0);
  endShape(CLOSE);
  popMatrix();
}