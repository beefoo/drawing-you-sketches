/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Thomas (http://youdrawingyou.com/sketches/thomas)
 */

import processing.pdf.*;

String imgSrc = "img/thomas.jpg";
String outputFile = "output/thomas.png";
String outputPDF = "output/thomas.pdf";
boolean savePDF = false;

int roadWidth = 675;
int roadHeight = 900;
float sidewalkWidth = 10;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage road;
ThomasCrew theThomasCrew;
color[] spaces;

void setup() {
  
  // set the stage
  size(roadWidth, roadHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(roadWidth, roadHeight);
  
  // load road from image source
  road = loadImage(imgSrc);
  pg.image(road, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a crew of Thomass 
  theThomasCrew = new ThomasCrew();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 60);
  
  if(captureFrames && !fs.running) {
    fs.start();
  }

  theThomasCrew.run();
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

class ThomasCrew
{
  int crewSize = 4;
  
  ArrayList<Thomas> crew;

  ThomasCrew () {
    float centerX = roadWidth/2.0,
          centerY = roadHeight/2.0,
          radius = (roadWidth-sidewalkWidth*2)/2;
          
    crew = new ArrayList<Thomas>();
    for(int i=0; i<crewSize; i++) {
      crew.add(new Thomas(centerX, centerY, radius));
    }
  }

  void run() {   
    for (int i = crew.size()-1; i >= 0; i--) {    
      Thomas thomas = crew.get(i);
      thomas.run();
    }   
  } 

}

class Thomas
{
  int baseX = 2, baseY = 3, angleStep = 12;
  
  float[] middleRange = {0.3, 0.6}, middle = new float[2];
  float maxEntropy = 20, maxAngleEntropy = 2;
  float radius, centerX, centerY, myX1, myY1, myX2, myY2, myX3, myY3;
  
  Thomas (float x, float y, float r) {
    centerX = x;
    centerY = y;
    radius = r;
    middle[0] = middleRange[0] * radius;
    middle[1] = middleRange[1] * radius;
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {    
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  boolean isCurve(float r) {
    return (r < middle[0] || r > middle[1]);
  }
  
  void run(){    
    float hr = Math.halton(spaceIterator, baseX),
          r = hr * radius,
          e = hr * maxEntropy,
          ae = hr * maxAngleEntropy;
    float[] p = Math.translatePoint(centerX, centerY, 0, r + random(-10, 10));
    spaceIterator++;
    
    myX1 = p[0];
    myY1 = p[1];
    myX2 = p[0];
    myY2 = p[1];
    myX3 = p[0];
    myY3 = p[1];
    
    for(int a=angleStep; a<=360; a+=angleStep) {
      r += random(-e, e);
      p = Math.translatePoint(centerX, centerY, a+random(-ae, ae), r);
      Space s = new Space(p[0], p[1]);      
      if (s.isWithinRoad() && s.isEmpty()) {
        if (isCurve(r)) {
          drawCurve(myX1, myY1, myX2, myY2, myX3, myY3, s.getX(), s.getY());
        } else {
          drawPath(myX3, myY3, s.getX(), s.getY());
        }         
        s.runAround();
      }
      myX1 = myX2;
      myY1 = myY2;
      myX2 = myX3;
      myY2 = myY3;     
      myX3 = s.getX();
      myY3 = s.getY();
    }
  } 

}

class Space 
{
  float brightThreshold = 5,
        brightnessUnit = 5;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinRoad()) {
      myColor = spaces[int(myX) + int(myY)*roadWidth];
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
  
  boolean isWithinRoad(){    
    return (Math.inBounds(myX, myY, roadWidth, roadHeight, sidewalkWidth));
  }
  
  void run(){
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*roadWidth] = color(myHue, mySaturation, myBrightness);
  }
  
  void runAround(){
    run();
    for(int a=0; a<360; a+=45) {
      float[] pos = Math.translatePoint(myX, myY, 1.0*a, 1);
      Space s = new Space(pos[0], pos[1]);
      if (s.isWithinRoad() && s.isEmpty()) {
        s.run();
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

