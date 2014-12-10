/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Patricia (http://youdrawingyou.com/sketches/patricia)
 */

import processing.pdf.*;

String imgSrc = "img/patricia.jpg";
String outputFile = "output/patricia.png";
String outputPDF = "output/patricia.pdf";
boolean savePDF = false;

int worldWidth = 675;
int worldHeight = 900;
float worldBorder = 20;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage world;
PatriciaGroup thePatriciaGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(worldWidth, worldHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(worldWidth, worldHeight);
  
  // load world from image source
  world = loadImage(imgSrc);
  pg.image(world, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;
  
  // noLoop();

  // create a group of Patricias 
  thePatriciaGroup = new PatriciaGroup();
  
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

  thePatriciaGroup.explore();
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

class PatriciaGroup
{
  int groupSize = 10;
  
  ArrayList<Patricia> group;

  PatriciaGroup () {  
    float centerX = worldWidth/2.0 + 50,
          centerY = worldHeight/2.0;
          
    group = new ArrayList<Patricia>();
    for(int i=0; i<groupSize; i++) {
      group.add(new Patricia(centerX, centerY));
    }
  }

  void explore() {   
    for (int i = group.size()-1; i >= 0; i--) {    
      Patricia patricia = group.get(i);
      patricia.explore();
    }   
  } 

}

class Patricia
{
  int baseX = 2, baseY = 3;
  
  float centerX, centerY, variance = 20;
  
  int angleStep = 20, roundToNearest = 40;
  
  Patricia (float x, float y) {
    centerX = x;
    centerY = y;
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
  
  void explore(){
    float hx = Math.halton(spaceIterator, baseX),
          hy = Math.halton(spaceIterator, baseY),
          x = Math.roundToNearest(hx*(worldWidth-worldBorder*2)+worldBorder, roundToNearest),
          y = Math.roundToNearest(hy*(worldHeight-worldBorder*2)+worldBorder, roundToNearest),
          d = dist(x, y, centerX, centerY),
          a = Math.angleBetweenPoints(centerX, centerY, x, y),
          r = d/2;
          
    float[] c = Math.translatePoint(centerX, centerY, a, r);
          
    spaceIterator++;
    
    for(int i = 0; i<360-angleStep; i+=angleStep) {
      float a1 = i, a2 = i+angleStep,
            cx = c[0] + random(-variance, variance),
            cy = c[1] + random(-variance, variance);
      
      float[] p1 = Math.translatePoint(cx, cy, a1, r);
      Space s1 = new Space(p1[0], p1[1]);
      
      float[] p2 = Math.translatePoint(cx, cy, a2, r);
      Space s2 = new Space(p2[0], p2[1]);
      
      if (s1.isWithinWorld() && s2.isWithinWorld()
            && s1.isEmpty() && s2.isEmpty()) {
        s1.exploreAround();
        s2.exploreAround();
        drawArc(cx, cy, d, d, a1, a2 + random(0, variance));
      }
    }
  }
  
}

class Space 
{
  float brightThreshold = 5,
        brightnessUnit = 15;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinWorld()) {
      myColor = spaces[int(myX) + int(myY)*worldWidth];
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
  
  boolean isWithinWorld(){    
    return (Math.inBounds(myX, myY, worldWidth, worldHeight, worldBorder));
  }
  
  void explore(){
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space and directions
    spaces[int(myX)+int(myY)*worldWidth] = color(myHue, mySaturation, myBrightness);
  }

  void exploreAround(){
    explore();
    for(int a=0; a<360; a+=45) {
      float[] pos = Math.translatePoint(myX, myY, 1.0*a, 1);
      Space s = new Space(pos[0], pos[1]);
      if (s.isWithinWorld() && s.isEmpty()) {
        s.explore();
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

