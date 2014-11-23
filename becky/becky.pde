/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Becky (http://youdrawingyou.com/sketches/becky)
 */

import processing.pdf.*;

String imgSrc = "img/becky.jpg";
String outputFile = "output/becky.png";
String outputPDF = "output/becky.pdf";
boolean savePDF = false;

int floorWidth = 675;
int floorHeight = 900;
float floorBorder = 10;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage floor;
BeckyGroup theBeckyGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(floorWidth, floorHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(floorWidth, floorHeight);
  
  // load floor from image source
  floor = loadImage(imgSrc);
  pg.image(floor, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Beckys 
  theBeckyGroup = new BeckyGroup();
  
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

  theBeckyGroup.dance();
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

class BeckyGroup
{
  int groupSize = 30;
  
  ArrayList<Becky> group;

  BeckyGroup () {          
    group = new ArrayList<Becky>();
    for(int i=0; i<groupSize; i++) {
      group.add(new Becky());
    }
  }

  void dance() {   
    for (int i = group.size()-1; i >= 0; i--) {    
      Becky becky = group.get(i);
      becky.dance();
    }   
  } 

}

class Becky
{
  int baseX = 2, baseY = 3, baseW = 5, baseH = 7;
  
  float minSpin = 10,
        spinStep = 20,
        rotateStep = 1;
  
  Becky () {}
  
  void drawEllipse(float x, float y, float w, float h) {
    ellipse(x, y, w, h);
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {    
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void dance(){
    float hx = Math.halton(spaceIterator, baseX),
          hy = Math.halton(spaceIterator, baseY),
          x = hx*(floorWidth-floorBorder*2)+floorBorder,
          y = hy*(floorHeight-floorBorder*2)+floorBorder,
          maxW = min(floorWidth-floorBorder-x, x-floorBorder) * 2.0,
          maxH = min(floorHeight-floorBorder-y, y-floorBorder) * 2.0,
          hw = Math.halton(spaceIterator, baseW),
          hh = Math.halton(spaceIterator, baseH),
          w = hw*maxW,
          h = hh*maxH,
          r = rotateStep;
          
    spaceIterator++;
    
    while(w > minSpin && h > minSpin) {
      spin(x, y, w, h, r);    
      w -= spinStep;
      h -= spinStep;
      r += rotateStep;
    }
          
  }
  
  void spin(float x, float y, float w, float h, float r) {
    ArrayList<Space> spaces = new ArrayList<Space>();
    spaces.add(new Space(x, y-h/2));
    spaces.add(new Space(x+w/2, y));
    spaces.add(new Space(x, y+h/2));
    spaces.add(new Space(x-w/2, y));   
    
    boolean allBright = true;
    for(int i=0; i<spaces.size() && allBright; i++) {
      Space space = spaces.get(i);
      if (!space.isWithinFloor() || !space.isEmpty()) {
        allBright = false;
      }
    }
  
    if (allBright) {
      pushMatrix();
      translate(x, y);
      rotate(radians(r));
      drawEllipse(0, 0, w, h);
      popMatrix();      
      for(int i=0; i<spaces.size(); i++) {
        Space space = spaces.get(i);
        space.danceAround();
      }
    }
  }

}

class Space 
{
  float brightThreshold = 30,
        brightnessUnit = 30;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinFloor()) {
      myColor = spaces[int(myX) + int(myY)*floorWidth];
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
  
  boolean isWithinFloor(){    
    return (Math.inBounds(myX, myY, floorWidth, floorHeight, floorBorder));
  }
  
  void dance(){
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*floorWidth] = color(myHue, mySaturation, myBrightness);
  }
  
  void danceAround(){
    dance();
    for(int a=0; a<360; a+=45) {
      float[] pos = Math.translatePoint(myX, myY, 1.0*a, 1);
      Space s = new Space(pos[0], pos[1]);
      if (s.isWithinFloor() && s.isEmpty()) {
        s.dance();
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

