String path = "/Users/Hizal/Documents/College/S17/Exp. Capture/Capstone/subaru outback/frames";
File dir; 
File [] files;
//int f_index = 0;
PImage img;
//PVector[] points;
PVector[][] allpoints;
PVector[][] cleanpoints;
float[] frameAvgs;
float threshold = 30; // minimum red brightness
float spectrum = 75; // maximum distance from median

boolean debug = false;
boolean clean = true;
boolean pause = false;

int frame = 0;

void setup() {
  size(1280, 720, P3D);
  dir= new File(dataPath(path));
  println(dir);
  files= dir.listFiles();
  //points = new PVector[1280];
  allpoints = new PVector[files.length][1280];
  cleanpoints = new PVector[files.length][1280];
  frameAvgs = new float[files.length];
  convert();
  
  frameRate(30);
}

void convert() {
  for (int f_index = 0; f_index<files.length; f_index++) {
    String f = files[f_index].getAbsolutePath();
    PVector points[] = new PVector[1280];
    PVector fullpoints[] = new PVector[1280];
    while (!f.toLowerCase().endsWith(".jpg")) {
      f_index = (f_index + 1)%files.length;
      f = files[f_index].getAbsolutePath();
    }
    //text(f, 10, 30);

    img = loadImage(f);

    for (int x=0; x<img.width; x++) {
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
      fullpoints[x] = p;
      if (red < threshold) {
        p = null;
      }
      points[x] = p;
    }

    // remove outliers from center
    float avg = pass1(points);
    frameAvgs[f_index] = avg;

    // remove outliers from median
    pass2(avg, points);

    allpoints[f_index] = fullpoints;
    cleanpoints[f_index] = points;
  }
}

void draw() { 
  if (!pause) {
    background(0);
    frame = (frame + 1)%files.length;
    String f = files[frame].getAbsolutePath();
    while (!f.toLowerCase().endsWith(".jpg")) {
      frame = (frame + 1)%files.length;
      f = files[frame].getAbsolutePath();
    }
    text(f, 10, 30);
    drawLinesFast();
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

void keyPressed() {
  if (key == 'p') {
    pause = !pause;
  } else {
    debug = !debug;
    clean = !clean;
  }
}

// returns avg of points within the center
float pass1(PVector[] points) {
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

void pass2(float avg, PVector[] points) {
  //float median = median(sort(depthValsCleaned));
  for (int i=0; i<points.length; i++) {
    if (points[i] != null && 
      (points[i].y >= avg+spectrum
      || points[i].y <= avg-spectrum)
      && clean) {
      points[i] = null;
    }
  }
}

//void drawLines() {
//  background(0);
//  f_index = (f_index + 1)%files.length;
//  String f = files[f_index].getAbsolutePath();
//  while (!f.toLowerCase().endsWith(".jpg")) {
//    f_index = (f_index + 1)%files.length;
//    f = files[f_index].getAbsolutePath();
//  }
//  text(f, 10, 30);

//  img = loadImage(f);

//  for (int x=0; x<img.width; x++) {
//    PVector p = new PVector(x, 0, 0);
//    float red = 0;
//    float total = 0;
//    for (int y=0; y<img.height; y++) {
//      color c = img.get(x, y);
//      if (red(c) > red && red(c) + green(c) + blue(c) > total) {
//        red = red(c);
//        total = red(c) + green(c) + blue(c);
//        p.y = y;
//      }
//    }
//    // check red thresholdp
//    if (clean && red < threshold) {
//      p = null;
//    }
//    points[x] = p;
//  }

//  // remove outliers from center
//  float avg = pass1();

//  // remove outliers from median
//  pass2(avg);

//  // draw depth points
//  stroke(255, 0, 0);
//  strokeWeight(3);
//  for (int i=0; i<points.length; i++) {
//    if (points[i] != null)
//      point(points[i].x, points[i].y);
//  }
//  strokeWeight(1);

//  stroke(100);
//  //line(0, mean, width, mean);
//}



void drawLinesFast() {
  // draw depth points
  stroke(255, 0, 0);
  strokeWeight(3);
  if (clean) {
    for (int i=0; i<cleanpoints[frame].length; i++) {
      if (cleanpoints[frame][i] != null)
        point(cleanpoints[frame][i].x, cleanpoints[frame][i].y);
    }
  } else {
    for (int i=0; i<allpoints[frame].length; i++) {
      if (allpoints[frame][i] != null)
        point(allpoints[frame][i].x, allpoints[frame][i].y);
    }
  }
  if (debug) {
    float center = height/2-50;
    stroke(150);
    line(0, center-spectrum*2, width, center-spectrum*2);
    line(0, center+spectrum*2, width, center+spectrum*2);

    stroke(50);
    line(0, frameAvgs[frame]-spectrum, width, frameAvgs[frame]-spectrum);
    line(0, frameAvgs[frame]+spectrum, width, frameAvgs[frame]+spectrum);
  }
  //line(0, mean, width, mean);
}