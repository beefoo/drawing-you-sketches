/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Hoang (http://youdrawingyou.com/sketches/hoang)
 */

import processing.pdf.*;

String imgSrc = "img/hoang.jpg";
String outputFile = "output/hoang.png";
String outputPDF = "output/hoang.pdf";
boolean savePDF = false;

int canvasWidth = 675;
int canvasHeight = 900;
float canvasBorder = 10;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage canvas;
HoangGroup theHoangGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(canvasWidth, canvasHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(canvasWidth, canvasHeight);
  
  // load canvas from image source
  canvas = loadImage(imgSrc);
  pg.image(canvas, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Hoangs 
  theHoangGroup = new HoangGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 50);
  
  if(captureFrames && !fs.running) {
    fs.start();
  }

  theHoangGroup.paint();
}

void mousePressed() {
  if (captureFrames) {
    fs.quit();
  } else {
    save(outputFile);
  }
  if (savePDF) {
    endRecord();
  }
  exit();
}

class HoangGroup
{
  int groupSize = 30;
  
  ArrayList<Hoang> group;

  HoangGroup () {
    float x = canvasWidth/2.0,
          y = canvasHeight/2.0;    
    group = new ArrayList<Hoang>();
    for(int i=0; i<groupSize; i++) {
      group.add(new Hoang(x, y));
    }
  }

  void paint() {   
    for (int i = group.size()-1; i >= 0; i--) {    
      Hoang hoang = group.get(i);
      hoang.paint();
    }   
  } 

}

class Hoang
{
  int baseA1 = 2, baseA2 = 3, baseW = 5, baseH = 7;
  float centerX, centerY;
  
  Hoang (float x, float y) {
    centerX = x;
    centerY = y;
  }
  
  void drawArc(float x, float y, float w, float h, float start, float stop) {
    arc(x, y, w, h, radians(start), radians(stop));
  }
  
  void drawEllipse(float x, float y, float w, float h) {
    ellipse(x, y, w, h);
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {    
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void paint(){  
    float ha1 = Math.halton(spaceIterator, baseA1),
          ha2 = Math.halton(spaceIterator, baseA2),
          hw = Math.halton(spaceIterator, baseW),
          hh = Math.halton(spaceIterator, baseH),
          a1 = ha1*360,
          a2 = ha2*360,
          w = hw*(canvasWidth-canvasBorder*2),
          h = hh*(canvasHeight-canvasBorder*2),
          x = centerX,
          y = centerY;
    boolean valid = true;
    ArrayList<Space> spaces = new ArrayList<Space>();
    
    spaceIterator++;    
    if (a1 > a2) {
      float temp = a1;
      a1 = a2;
      a2 = temp;
    }
    float a3 = (a2-a1)/2;
    
    float[] p1 = Math.ellipsePoint(x, y, w, h, a1),
            p2 = Math.ellipsePoint(x, y, w, h, a2),
            p3 = Math.ellipsePoint(x, y, w, h, a3);  
    
    spaces.add(new Space(p1[0], p1[1]));
    spaces.add(new Space(p2[0], p2[1]));
    spaces.add(new Space(p3[0], p3[1]));
    
    for (int i = spaces.size()-1; i >= 0 && valid; i--) {    
      Space space = spaces.get(i);
      if (!space.isWithinCanvas() || !space.isEmpty()) {
        valid = false;
      }
    }
    
    if (valid) {
      drawArc(x, y, w, h, a1, a2);
      for (int i = spaces.size()-1; i >= 0; i--) {
        Space space = spaces.get(i);
        space.paintAround();
      }
    }   
  }
}

class Space 
{
  float brightThreshold = 60,
        brightnessUnit = 9;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinCanvas()) {
      myColor = spaces[int(myX) + int(myY)*canvasWidth];
      myHue = hue(myColor);
      mySaturation = saturation(myColor);
      myBrightness = brightness(myColor); 
    }      
  }
  
  float getBrightness(){
    return myBrightness;
  }
  
  float getX(){    
    return myX;
  }
  
  float getY(){
    return myY;
  }
  
  boolean isEmpty(){
    return (myBrightness >= brightThreshold);
  }
  
  boolean isWithinCanvas(){    
    return (Math.inBounds(myX, myY, canvasWidth, canvasHeight, canvasBorder));
  }
  
  void paint(){
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*canvasWidth] = color(myHue, mySaturation, myBrightness);
  }
  
  void paintAround(){
    paint();
    for(int a=0; a<360; a+=45) {
      float[] pos = Math.translatePoint(myX, myY, 1.0*a, 1);
      Space s = new Space(pos[0], pos[1]);
      if (s.isWithinCanvas() && s.isEmpty()) {
        s.paint();
      }
    }
  }
  
}

static class Math {
  
  static float angleBetweenPoints(float x1, float y1, float x2, float y2){
    float deltaX = x2 - x1,
          deltaY = y2 - y1;  
    return atan2(deltaY, deltaX) * 180 / PI;
  }
  
  static float[] ellipsePoint(float cx, float cy, float w, float h, float a){
    float x = cx + (w/2) * cos(radians(a));
    float y = cy + (h/2) * sin(radians(a));
    float[] point = {x, y};
    return point;
  }
  
  static float floorToNearest(float n, float nearest) {
    return 1.0 * floor(n/nearest) * nearest;
  }
  
  static float halton(int hIndex, int hBase) {    
    float result = 0;
    float f = 1.0 / hBase;
    int i = hIndex;
    while(i > 0) {
      result = result + f * float(i % hBase);
      
      i = floor(i / hBase);
      f = f / float(hBase);
    }
    return result;
  }
  
  static boolean inBounds(float x, float y, float w, float h, float padding) {
    return (x>=padding && y>=padding && x<=w-padding-1 && y<=h-padding-1);
  }
  
  static float[] lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4){    
    float[] coords = {-1, -1};
    float a1, a2, b1, b2, c1, c2,
          r1, r2 , r3, r4,
          denom, offset, num,
          x = 0, y = 0;
  
    // Compute a1, b1, c1, where line joining points 1 and 2
    // is "a1 x + b1 y + c1 = 0".
    a1 = y2 - y1;
    b1 = x1 - x2;
    c1 = (x2 * y1) - (x1 * y2);
  
    // Compute r3 and r4.
    r3 = ((a1 * x3) + (b1 * y3) + c1);
    r4 = ((a1 * x4) + (b1 * y4) + c1);
  
    // Check signs of r3 and r4. If both point 3 and point 4 lie on
    // same side of line 1, the line segments do not intersect.
    if ((r3 != 0) && (r4 != 0) && r3*r4 > 0){
      return coords;
    }
  
    // Compute a2, b2, c2
    a2 = y4 - y3;
    b2 = x3 - x4;
    c2 = (x4 * y3) - (x3 * y4);
  
    // Compute r1 and r2
    r1 = (a2 * x1) + (b2 * y1) + c2;
    r2 = (a2 * x2) + (b2 * y2) + c2;
  
    // Check signs of r1 and r2. If both point 1 and point 2 lie
    // on same side of second line segment, the line segments do
    // not intersect.
    if ((r1 != 0) && (r2 != 0) && r1*r2 > 0){
      return coords;
    }
  
    //Line segments intersect: compute intersection point.
    denom = (a1 * b2) - (a2 * b1);
  
    // parallel
    if (denom == 0) {
      coords[0] = -2;
      coords[1] = -2;
      return coords;
    }
  
    if (denom < 0){ 
      offset = -denom / 2; 
    } 
    else {
      offset = denom / 2 ;
    }
  
    // The denom/2 is to get rounding instead of truncating. It
    // is added or subtracted to the numerator, depending upon the
    // sign of the numerator.
    num = (b1 * c2) - (b2 * c1);
    if (num < 0){
      x = (num - offset) / denom;
    } 
    else {
      x = (num + offset) / denom;
    }
  
    num = (a2 * c1) - (a1 * c2);
    if (num < 0){
      y = ( num - offset) / denom;
    } 
    else {
      y = (num + offset) / denom;
    }
  
    // lines intersect
    coords[0] = x;
    coords[1] = y;
    return coords;
  }
  
  static float normalizeAngle(float angle) {
    angle = angle % 360;    
    if (angle <= 0) {
      angle += 360;
    }
    return angle;
  }
  
  static float[] translatePoint(float x, float y, float angle, float distance){
    float[] newPoint = new float[2];
    float r = radians(angle);
    
    newPoint[0] = x + distance*cos(r);
    newPoint[1] = y + distance*sin(r);
    
    return newPoint;
  }
  
  static float roundToNearest(float n, float nearest) {
    return 1.0 * round(n/nearest) * nearest;
  }
  
}

class FrameSaver extends Thread {
 
  boolean running;
   
  public FrameSaver () {
    running = false;
  }
   
  public void start() {
    println("recording frames!");
    running = true;
   
    try{
      super.start();
    }
    catch(java.lang.IllegalThreadStateException itse){
      println("cannot execute! ->"+itse);
    }
  }
   
  public void run(){
    while(running){
      frameIterator++;
      if (frameIterator >= frameCaptureEvery) {
        frameIterator = 0;
        saveFrame(outputMovieFile);
      }      
    }
  }
   
  public void quit() {
    println("stopped recording..");
    running = false; 
    interrupt();
  }
}

