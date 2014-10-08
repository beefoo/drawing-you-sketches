/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend and mentor Raymond "Hap" (http://youdrawingyou.com/sketches/raymond)
 */

import processing.pdf.*;

String imgSrc = "img/raymond.jpg";
String outputFile = "output/raymond.png";
String outputPDF = "output/raymond.pdf";
boolean savePDF = false;

int earthWidth = 675;
int earthHeight = 900;
float earthBorder = 10;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage earth;
HapGroup theHapGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(earthWidth, earthHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(earthWidth, earthHeight);
  
  // load earth from image source
  earth = loadImage(imgSrc);
  pg.image(earth, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Haps 
  theHapGroup = new HapGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 30);
  
  if(captureFrames && !fs.running) {
    fs.start();
  }

  theHapGroup.write();
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

class HapGroup
{
  int groupSize = 30;
  
  ArrayList<Hap> group;

  HapGroup () {
    float centerX = earthWidth/2.0,
          centerY = earthHeight/2.0;
          
    group = new ArrayList<Hap>();
    for(int i=0; i<groupSize; i++) {
      group.add(new Hap(centerX, centerY));
    }
  }

  void write() {   
    for (int i = group.size()-1; i >= 0; i--) {    
      Hap hap = group.get(i);
      hap.write();
    }   
  } 

}

class Hap
{
  float[] deviation = {0.4, 0.6}, variance = {0.5, 0.7}, limit = {40, 80};
  
  float centerX, centerY, myX, myY, myRadius, myLimit, myArea, myMeanArea, minArea, cumulativeArea, maxArea, page;
  
  Hap (float x, float y) {
    centerX = x;
    centerY = y;
    
    myRadius = (earthWidth-earthBorder*2)/2;
    myArea = pow(myRadius, 2) * PI;
    
    rest();    
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {    
    line(x1, y1, x2, y2);
  }
  
  void drawEllipse(float x, float y, float w, float h) {
    ellipse(x, y, w, h);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void write(){
    float angle = page * Math.goldenAngle(),
          ratio = page / myLimit,
          area = minArea + ratio * (maxArea - minArea),
          radius = sqrt(area/PI);
    Space space = new Space(myX, myY);
    
    if (!space.isWithinEarth()) {
      rest();
      return;
    }     
    
    if (space.isEmpty()) {
      drawEllipse(space.getX(), space.getY(), radius*random(variance[0], variance[1])*2, radius*random(variance[0], variance[1])*2);
      space.occupy();
    }
    
    cumulativeArea += area;
  
    float spiralRadius = sqrt(cumulativeArea/PI),
          x = myX + cos(angle) * spiralRadius,
          y = myY + sin(angle) * spiralRadius;      
    
    myX = x;
    myY = y;
    page++;    
  }
  
  void rest(){
    page = 0;
    cumulativeArea = 0;
    myX = centerX;
    myY = centerY;
    myLimit = random(limit[0], limit[1]);
    myMeanArea = myArea/myLimit;
    minArea = myMeanArea * (1-random(deviation[0], deviation[1]));
    maxArea = myMeanArea * (1+random(deviation[0], deviation[1]));
  }
}

class Space 
{
  float brightThreshold = 25,
        brightnessUnit = 3;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinEarth()) {
      myColor = spaces[int(myX) + int(myY)*earthWidth];
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
  
  boolean isWithinEarth(){    
    return (Math.inBounds(myX, myY, earthWidth, earthHeight, earthBorder));
  }
  
  void occupy(){
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*earthWidth] = color(myHue, mySaturation, myBrightness);
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
  
  static float goldenAngle(){
    return Math.phi() * 2.0 * PI;
  }
  
  static float phi(){
    return (sqrt(5.0)+1.0)/2.0 - 1.0;
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

