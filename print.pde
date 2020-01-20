String name = "volvo xc60";
String path = "/Users/Hizal/Documents/College/S17/Exp. Capture/Capstone/"+name+"/frames";
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
int spacing = 10;
float height_amplification = 4.5;

PrintWriter output;

float box_LEFT;
float box_RIGHT;
float box_MAX;
float box_MIN;
float box_FRONT;
float box_BACK;
int box_ROW_START;
int box_ROW_END;
int box_COL_START;
int box_COL_END;

import peasy.*;
PeasyCam cam;

void setup() {
  size(1280, 720, P3D);
  dir= new File(dataPath(path));
  files= dir.listFiles();
  allpoints = new PVector[files.length][detail];

  convert();
  clean();
  saveData();

  cam = new PeasyCam(this, 3000);
  cam.setMinimumDistance(10);
  cam.setMaximumDistance(3000);
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
        float x = i;
        float y = (f_index - (files.length/2))*spacing;
        float z = (points[i].y-height/4)*-1*height_amplification;
        allpoints[f_index][i] = new PVector(x, y, z);
      } else {
        allpoints[f_index][i] = null;
      }
    }
  }
}

void clean() {
  box_ROW_START = 1;
  box_ROW_END = files.length;
  box_FRONT = (box_ROW_START - (files.length/2))*spacing;
  box_BACK = (box_ROW_END - (files.length/2))*spacing;

  int nCols = detail;

  float leftSide[] = new float[box_ROW_END-box_ROW_START];
  float rightSide[] = new float[box_ROW_END-box_ROW_START];
  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    int col = 0;
    while (allpoints[row][col] == null && col < nCols-1) {
      col++;
    }
    leftSide[row-box_ROW_START] = col;
    col = nCols-1;
    while (allpoints[row][col] == null && col > 1) {
      col--;
    }
    rightSide[row-box_ROW_START] = col;
  }
  box_LEFT = mean(leftSide);
  box_RIGHT = mean(rightSide);

  box_COL_START = int(box_LEFT);
  box_COL_END = int(box_RIGHT);

  box_MAX = -1000000;
  box_MIN = 0;
  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    for (int col = box_COL_START; col<box_COL_END; col++) {
      if (allpoints[row][col] != null) {
        box_MAX = max(box_MAX, allpoints[row][col].z);
        box_MIN = min(box_MIN, allpoints[row][col].z);
      }
    }
  }

  float translationZ = abs(box_MIN) + abs(abs(box_MIN)-abs(box_MAX));
  for (int row=0; row<files.length; row++) {
    for (int col = 0; col<nCols; col++) {
      if (allpoints[row][col] != null) {
        allpoints[row][col].z += translationZ;
      }
    }
  }
  box_MAX += translationZ;
  box_MIN += translationZ;

  int count = 0;
  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    int col = box_COL_START;
    while (allpoints[row][col] == null && col < box_COL_END-1) {
      col++;
    }
    float yVal = allpoints[row][col].y;
    float zVal = allpoints[row][col].z;
    while (col > box_COL_START) {
      col--;
      allpoints[row][col] = new PVector(col, yVal, zVal);
      count++;
    }
    col = box_COL_END-1;
    while (allpoints[row][col] == null && col > box_COL_START+1) {
      col--;
    }
    yVal = allpoints[row][col].y;
    zVal = allpoints[row][col].z;
    while (col < box_COL_END) {
      col++;
      allpoints[row][col] = new PVector(col, yVal, zVal);
      count++;
    }
  }

  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    for (int col = box_COL_START; col<box_COL_END; col++) {
      if (allpoints[row][col] == null) {
        //float prevX = allpoints[row][col-1].x;
        float prevY = allpoints[row][col-1].y;
        float prevZ = allpoints[row][col-1].z;
        int nextCol = col+1;
        while (allpoints[row][nextCol] == null && nextCol < box_COL_END)
          nextCol++;
        //float nextX = nextCol;
        //float nextY = allpoints[row][nextCol].y;
        float nextZ = allpoints[row][nextCol].z;

        //int currCol = col+1;
        for (int currCol = col; currCol<nextCol; currCol++) {
          //while (allpoints[row][currCol] == null && currCol < box_COL_END) {
          float newZ = map(currCol, col-1, nextCol, prevZ, nextZ);
          allpoints[row][currCol] = new PVector(currCol, prevY, newZ);
          //nextCol++;
          count++;
        }
      }
    }
  }

  float translationX = detail/2;
  for (int row=0; row<files.length; row++) {
    for (int col = 0; col<nCols; col++) {
      if (allpoints[row][col] != null) {
        allpoints[row][col].x -= translationX;
      }
    }
  }
  box_LEFT -= translationX;
  box_RIGHT -= translationX;

  int missing = 0;
  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    for (int col = box_COL_START; col<box_COL_END; col++) {
      if (allpoints[row][col] == null) {
        missing++;
        println("row: "+row+"   col: "+col);
      }
    }
  }

  println(count + " vertexes created");
  println(missing + " vertexes missing");
  println("LEFT: "+box_COL_START);
  println("RIGHT: "+box_COL_END);
  
  println(box_ROW_END-box_ROW_START);
}

void saveData() {
  int numVertices = 0;
  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    for (int col=box_COL_START; col<box_COL_END; col++) {
      numVertices++;
    }
  }

  output = createWriter(name+".ply"); 
  output.println("ply");
  output.println("format ascii 1.0");
  output.println("element vertex " + numVertices);
  output.println("property float x");
  output.println("property float y");
  output.println("property float z");
  output.println("end_header");

  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    for (int col=box_COL_START; col<box_COL_END; col++) {
      float x = allpoints[row][col].x;
      float y = allpoints[row][col].y;
      float z = allpoints[row][col].z;
      output.println(x + " " + y + " " + z);
    }
  }

  output.flush();
  output.close();
  println("Saved "+name+".ply");
}

void draw() {
  drawNew();
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

public static float median(float[] m) {
  int middle = m.length/2;
  if (m.length%2 == 1) {
    return m[middle];
  } else {
    return (m[middle-1] + m[middle]) / 2.0;
  }
}

public static float mean(float[] m) {
  float sum = 0;
  for (int i = 0; i < m.length; i++) {
    sum += m[i];
  }
  return sum / m.length;
}

void drawNew() {
  background(0); 
  noStroke() ; 
  strokeWeight(1); 
  float dirY = (mouseY / float(height) - 0.5) * 2;
  float dirX = (mouseX / float(width) - 0.5) * 2;
  colorMode(HSB, 360, 100, 100);
  //directionalLight(265, 13, 90, -dirX, -dirY, -1);

  //directionalLight(137, 13, 90, dirX, dirY, 1);
  colorMode(RGB, 255);

  //rotateX(-.5);
  //rotateY(-.5);

  pushMatrix(); 
  translate(0, 0, 20);
  scale(.2); 
  fill(255, 200, 200); 

  //SHAPE
  //noStroke();
  //for (int row=0; row<(nRows-1); row++) {
  //  fill(255, map(row, 0, nRows, 0, 255), map(row, 0, nRows, 0, 255));
  //  beginShape(TRIANGLES);
  //  for (int col = 0; col<(nCols-1); col++) {
  //    if (allpoints[row][col] != null &&
  //      allpoints[row+1][col] != null &&
  //      allpoints[row][col+1] != null &&
  //      allpoints[row+1][col+1] != null) {
  //      float x0 = allpoints[row][col].x;
  //      float y0 = allpoints[row][col].y;
  //      float z0 = allpoints[row][col].z;

  //      float x1 = allpoints[row][col+1].x;
  //      float y1 = allpoints[row][col+1].y;
  //      float z1 = allpoints[row][col+1].z;

  //      float x2 = allpoints[row+1][col].x;
  //      float y2 = allpoints[row+1][col].y;
  //      float z2 = allpoints[row+1][col].z;

  //      float x3 = allpoints[row+1][col+1].x;
  //      float y3 = allpoints[row+1][col+1].y;
  //      float z3 = allpoints[row+1][col+1].z;

  //      vertex(x0, y0, z0); 
  //      vertex(x1, y1, z1); 
  //      vertex(x2, y2, z2); 

  //      vertex(x2, y2, z2); 
  //      vertex(x1, y1, z1); 
  //      vertex(x3, y3, z3);
  //    }
  //  }
  //  endShape();
  //}

  noFill();
  stroke(255, 255, 255);
  strokeWeight(2);
  //for (int row=box_ROW_START; row<box_ROW_END; row++) {
  //  beginShape();
  //  for (int col=box_COL_START; col<box_COL_END; col++) {
  //    if (allpoints[row][col] != null && row%3==0 && col%3==0) {
  //      float x= allpoints[row][col].x;
  //      float y= allpoints[row][col].y;
  //      float z= allpoints[row][col].z;
  //      stroke(255, map(row, 0, box_ROW_END, 0, 255), map(row, 0, box_ROW_END, 0, 255));
  //      vertex(x, y, z);
  //    }
  //  }
  //  endShape(OPEN);
  //}

  for (int row=box_ROW_START; row<box_ROW_END; row++) {
    beginShape();
    for (int col=box_COL_START; col<box_COL_END; col++) {
      if (allpoints[row][col] != null) {
        float x= allpoints[row][col].x;
        float y= allpoints[row][col].y;
        float z= allpoints[row][col].z;
        stroke(255, map(row, 0, box_ROW_END, 0, 255), map(row, 0, box_ROW_END, 0, 255));
        vertex(x, y, z);
      }
    }
    endShape(OPEN);
  }

  noFill();
  strokeWeight(10);
  stroke(0, 255, 0);
  fill(0, 255, 0);
  line(0, 0, 0, 125, 0, 0); // x
  text("X", 125, 0, 0);

  stroke(255, 0, 0);
  fill(255, 0, 0);
  line(0, 0, 0, 0, 125, 0); // y
  text("Y", 0, 125, 0);

  fill(0, 0, 255);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 125); // z
  text("Z", 0, 0, 125);

  stroke(0, 255, 0);
  strokeWeight(10);
  noFill();

  beginShape();
  vertex(box_LEFT, box_FRONT, box_MIN);
  vertex(box_RIGHT, box_FRONT, box_MIN);
  vertex(box_RIGHT, box_FRONT, box_MAX);
  vertex(box_LEFT, box_FRONT, box_MAX);
  endShape(CLOSE);

  beginShape();
  vertex(box_LEFT, box_BACK, box_MIN);
  vertex(box_RIGHT, box_BACK, box_MIN);
  vertex(box_RIGHT, box_BACK, box_MAX);
  vertex(box_LEFT, box_BACK, box_MAX);
  endShape(CLOSE);

  beginShape();
  vertex(box_LEFT, box_FRONT, box_MIN);
  vertex(box_LEFT, box_FRONT, box_MAX);
  vertex(box_LEFT, box_BACK, box_MAX);
  vertex(box_LEFT, box_BACK, box_MIN);
  endShape(CLOSE);

  beginShape();
  vertex(box_RIGHT, box_FRONT, box_MIN);
  vertex(box_RIGHT, box_FRONT, box_MAX);
  vertex(box_RIGHT, box_BACK, box_MAX);
  vertex(box_RIGHT, box_BACK, box_MIN);
  endShape(CLOSE);

  noStroke();
  stroke(0, 255, 0, 50);
  beginShape();
  vertex(box_LEFT, box_FRONT, 0);
  vertex(box_RIGHT, box_FRONT, 0);
  vertex(box_RIGHT, box_BACK, 0);
  vertex(box_LEFT, box_BACK, 0);
  endShape(CLOSE);

  beginShape();
  vertex(box_LEFT, box_FRONT, 0);
  vertex(box_RIGHT, box_FRONT, 0);
  vertex(box_RIGHT, box_FRONT, box_MIN);
  vertex(box_LEFT, box_FRONT, box_MIN);
  endShape(CLOSE);

  beginShape();
  vertex(box_LEFT, box_BACK, 0);
  vertex(box_RIGHT, box_BACK, 0);
  vertex(box_RIGHT, box_BACK, box_MIN);
  vertex(box_LEFT, box_BACK, box_MIN);
  endShape(CLOSE);

  beginShape();
  vertex(box_LEFT, box_BACK, 0);
  vertex(box_LEFT, box_FRONT, 0);
  vertex(box_LEFT, box_FRONT, box_MIN);
  vertex(box_LEFT, box_BACK, box_MIN);
  endShape(CLOSE);

  beginShape();
  vertex(box_RIGHT, box_BACK, 0);
  vertex(box_RIGHT, box_FRONT, 0);
  vertex(box_RIGHT, box_FRONT, box_MIN);
  vertex(box_RIGHT, box_BACK, box_MIN);
  endShape(CLOSE);

  popMatrix();
}