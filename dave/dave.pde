/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Dave (http://youdrawingyou.com/sketches/dave)
 */

import processing.pdf.*;

String imgSrc = "img/dave.jpg";
String outputFile = "output/dave.png";
String outputPDF = "output/dave.pdf";
boolean savePDF = false;

int stageWidth = 675;
int stageHeight = 900;
float stageBorder = 50;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage stage;
DaveGroup theDaveGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(stageWidth, stageHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(stageWidth, stageHeight);
  
  // load stage from image source
  stage = loadImage(imgSrc);
  pg.image(stage, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;
  
  // noLoop();

  // create a group of Daves 
  theDaveGroup = new DaveGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 80);
  
  if(captureFrames && !fs.running) {
    fs.start();
  }

  theDaveGroup.drum();
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

class DaveGroup
{
  int groupSize = 40;
  
  ArrayList<Dave> group;

  DaveGroup () {        
    group = new ArrayList<Dave>();
    for(int i=0; i<groupSize; i++) {
      group.add(new Dave());   
    }
  }

  void drum() {   
    for (int i = group.size()-1; i >= 0; i--) {    
      Dave dave = group.get(i);
      dave.drum();
    }   
  } 

}

class Dave
{
  int baseA = 2, baseS = 3;
  float myX, myY, gridSize = 20, variance = 10;
  boolean iAmFinished = false;
  
  Dave () {
    myX = stageBorder;
    myY = stageBorder;
  }
  
  void drawArc(float x, float y, float w, float h, float start, float stop) {
    arc(x, y, w, h, radians(start), radians(stop));
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {  
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void drum(){
    if (iAmFinished) return;
    
    Space space = new Space(myX, myY);
    
    if (!space.isEmpty()) {
      goNext();
      return;
    } else {
      space.drum();
    } 
    
    float ha = Math.halton(int((int(myX)+int(myY)*stageWidth)/gridSize), baseA),
          hs = Math.halton(spaceIterator, baseS),
          x = myX + gridSize/2,
          y = myY + gridSize/2,
          a = ha * 360,
          s = hs * gridSize,
          v = hs * variance;
    int type = round(ha);
    
    spaceIterator++;
    
    pushMatrix();
    
    translate(x+random(-v, v), y+random(-v, v));      
    rotate(radians(a));
    // scale(s);    
    
    if (type < 1) {
      float[] p1 = Math.translatePoint(0, 0, 0, s*2);
      float[] p2 = Math.translatePoint(0, 0, a, s*2);
      drawPath(0, 0, p1[0], p1[1]);
      drawPath(0, 0, p2[0], p2[1]);
      
    } else {
      drawArc(0, 0, s*2, s*2, 0, a);
    }
    
    popMatrix();   
  }
  
  void goNext(){
    myX += gridSize;
    
    if (myX >= stageWidth-stageBorder) {
      myX = stageBorder;
      myY += gridSize;
    }
    
    if (myX >= stageHeight-stageBorder) {
      iAmFinished = true;
    }
  }
  
}

class Space 
{
  float brightThreshold = 10,
        brightnessUnit = 0.5;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinStage()) {
      myColor = spaces[int(myX) + int(myY)*stageWidth];
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
  
  boolean isWithinStage(){    
    return (Math.inBounds(myX, myY, stageWidth, stageHeight, stageBorder));
  }
  
  void drum(){
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space and directions
    spaces[int(myX)+int(myY)*stageWidth] = color(myHue, mySaturation, myBrightness);
  }

  void drumAround(){
    drum();
    for(int a=0; a<360; a+=45) {
      float[] pos = Math.translatePoint(myX, myY, 1.0*a, 1);
      Space s = new Space(pos[0], pos[1]);
      if (s.isWithinStage() && s.isEmpty()) {
        s.drum();
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
  
  static float phi(){
    return (sqrt(5)+1)/2.0;
  }
  
  static float[] rotatePoint(float x, float y, float cx,float cy, float angle) {
    float s = sin(radians(angle));
    float c = cos(radians(angle));
  
    // translate point back to origin:
    x -= cx;
    y -= cy;
  
    // rotate point
    float xnew = x * c - y * s;
    float ynew = x * s + y * c;
  
    // translate point back:
    x = xnew + cx;
    y = ynew + cy;
    
    float[] p = {x, y};
    return p;
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

