String name = "subaru outback";
String path = "/Users/Hizal/Documents/College/S17/Exp. Capture/Capstone/"+name+"/";
File dir; 
File [] files;
int f_index = 0;
PImage img;
PVector[] points;
PVector[][] allpoints;
float threshold = 30; // minimum red brightness
float spectrum = 75; // maximum distance from median

int smoothing = 1;
int detail = 1280/smoothing;
int spacing = 25;
float height_amplification = 4.5;

boolean lineview = true;
boolean pause = false;
int skip = 3;

int frameIndex = 0;

import peasy.*;
PeasyCam cam;

void setup() {
  size(1280, 720, P3D);
  //surface.setResizable(true);
  //fullScreen(P3D);
  dir= new File(dataPath(path+"frames"));
  println(dir);
  files= dir.listFiles();
  allpoints = new PVector[files.length][detail];

  convert();
  //saveData();

  cam = new PeasyCam(this, 3000);
  cam.setMinimumDistance(10);
  cam.setMaximumDistance(3000);
  
  frameRate(30);
}

void draw() {
  if (!pause) {
    drawNew();
    frameIndex=(frameIndex+1)%files.length;
  }
}

void drawNew() {
  int nRows = files.length;
  int nCols = detail;
  background(0); 
  noStroke() ; 
  strokeWeight(1); 
  //float dirY = (mouseY / float(height) - 0.5) * 2;
  //float dirX = (mouseX / float(width) - 0.5) * 2;
  float dirX = -0.07343751;
  float dirY = -0.80277777;
  colorMode(HSB, 360, 100, 100);
  directionalLight(265, 13, 90, -dirX, -dirY, -1);

  directionalLight(137, 13, 90, dirX, dirY, 1);
  colorMode(RGB, 255);

  pushMatrix(); 
  translate(0, 0, 20);
  scale(.5); 
  fill(255, 200, 200); 

  if (lineview) {
    noFill();
    stroke(255, 255, 255);
    strokeWeight(2);
    for (int row=0; row<frameIndex; row++) {
      beginShape();
      for (int col=0; col<nCols; col++) {
        if (allpoints[row][col] != null && col%skip == 0) {
          float x= allpoints[row][col].x;
          float y= allpoints[row][col].y;
          float z= allpoints[row][col].z;
          stroke(255, map(row, 0, nRows, 0, 255), map(row, 0, nRows, 0, 255));
          vertex(x, y, z);
        }
      }
      endShape(OPEN);
    }
  } else {
    noStroke();
    for (int row=0; row<(frameIndex-1); row++) {
      fill(255, map(row, 0, nRows, 0, 255), map(row, 0, nRows, 0, 255));
      beginShape(TRIANGLES);
      for (int col = 0; col<(nCols-1); col++) {
        if (allpoints[row][col] != null &&
          allpoints[row+1][col] != null &&
          allpoints[row][col+1] != null &&
          allpoints[row+1][col+1] != null) {
          float x0 = allpoints[row][col].x;
          float y0 = allpoints[row][col].y;
          float z0 = allpoints[row][col].z;

          float x1 = allpoints[row][col+1].x;
          float y1 = allpoints[row][col+1].y;
          float z1 = allpoints[row][col+1].z;

          float x2 = allpoints[row+1][col].x;
          float y2 = allpoints[row+1][col].y;
          float z2 = allpoints[row+1][col].z;

          float x3 = allpoints[row+1][col+1].x;
          float y3 = allpoints[row+1][col+1].y;
          float z3 = allpoints[row+1][col+1].z;

          vertex(x0, y0, z0); 
          vertex(x1, y1, z1); 
          vertex(x2, y2, z2); 

          vertex(x2, y2, z2); 
          vertex(x1, y1, z1); 
          vertex(x3, y3, z3);
        }
      }
      endShape();
    }
  }

  //noFill();
  //strokeWeight(10);
  //stroke(0, 255, 0);
  //fill(0, 255, 0);
  //line(0, 0, 0, 25, 0, 0); // x
  //text("X", 25, 0, 0);

  //stroke(255, 0, 0);
  //fill(255, 0, 0);
  //line(0, 0, 0, 0, 25, 0); // y
  //text("Y", 0, 25, 0);

  //fill(0, 0, 255);
  //stroke(0, 0, 255);
  //line(0, 0, 0, 0, 0, 25); // z
  //text("Z", 0, 0, 25);

  popMatrix();
}

void convert() {
  for (int f_index = 0; f_index < files.length; f_index++) {
    points = new PVector[detail];
    String f = files[f_index].getAbsolutePath();
    while (!f.toLowerCase().endsWith(".jpg")) {
      f_index = (f_index + 1)%files.length;
      f = files[f_index].getAbsolutePath();
    }

    img = loadImage(f);

    for (int x=0; x<img.width; x+=smoothing) {
      PVector p = new PVector(x, 0, 0);
      float red = 0;
      float total = 0;
      for (int y=0; y<img.height; y++) {
        color c = img.get(x, y);
        if (red(c) > red && red(c) + green(c) + blue(c) > total) {
          red = red(c);
          total = red(c) + green(c) + blue(c);
          p.y = y;
        }
      }
      // check red threshold
      if (red < threshold) {
        p = null;
      }
      points[x/smoothing] = p;
    }

    // remove outliers from center
    float avg = pass1();

    // remove outliers from median
    pass2(avg);

    // draw depth points
    for (int i=0; i<points.length; i++) {
      if (points[i] != null) {
        //point(points[i].x, points[i].y);
        float x = i - (detail/2);
        float y = (f_index - (files.length/2))*spacing;
        float z = (points[i].y-height/4)*-1*height_amplification;
        allpoints[f_index][i] = new PVector(x, y, z);
      } else {
        allpoints[f_index][i] = null;
      }
    }
  }
}

// returns avg of points within the center
float pass1() {
  float center = height/2-50;
  float sum = 0;
  int pointCount = 0;
  for (int i=0; i<points.length; i++) {
    if (points[i] != null && 
      (points[i].y < center+spectrum*2
      && points[i].y > center-spectrum*2)) {
      sum += points[i].y;
      pointCount ++;
    }
  }
  return sum / pointCount;
}

void pass2(float avg) {
  for (int i=0; i<points.length; i++) {
    if (points[i] != null && 
      (points[i].y >= avg+spectrum
      || points[i].y <= avg-spectrum)) {
      points[i] = null;
    }
  }
}

void keyPressed() {
  if (key == 'p')
    pause = !pause;
  if (key == 'v')
    lineview = !lineview;
}