/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Virginia (http://youdrawingyou.com/sketches/virginia)
 */

import processing.pdf.*;

String imgSrc = "img/virginia.jpg";
String outputFile = "output/virginia.png";
String outputPDF = "output/virginia.pdf";
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
VirginiaCollective theVirginiaCollective;
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

  // create a collective of Virginias 
  theVirginiaCollective = new VirginiaCollective();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 25);
  smooth();
  
  if(captureFrames && !fs.running) {
    fs.start();
  }

  theVirginiaCollective.paint();
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

class VirginiaCollective
{
  int collectiveSize = 60;
  
  ArrayList<Virginia> collective;

  VirginiaCollective () {
    float x = canvasBorder * 3,
          y = canvasHeight - canvasBorder;
    
    collective = new ArrayList<Virginia>();
    for(int i=0; i<collectiveSize; i++) {
      collective.add(new Virginia(x, y));
    }
  }

  void paint() {   
    for (int i = collective.size()-1; i >= 0; i--) {    
      Virginia virginia = collective.get(i);
      virginia.paint();
    }   
  } 

}

class Virginia
{
  float strokeUnit = 1;

  float[] strokeFrequency = {220, 240},
          strokeLength = {5, 15},
          strokeVariance = {1, 150};
  
  int baseX = 2, baseY = 3;
  
  float targetX, targetY;  
  
  Virginia (float x, float y) {
    targetX = x;
    targetY = y;
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void paint(){
    float hx = Math.halton(spaceIterator, baseX),
          hy = Math.halton(spaceIterator, baseY),
          x = hx*(canvasWidth-canvasBorder*2)+canvasBorder,
          y = hy*(canvasHeight-canvasBorder*2)+canvasBorder,
          direction = Math.angleBetweenPoints(x, y, targetX, targetY),
          distance = 0;   

    Space space = new Space(x, y);
    spaceIterator++;
    
    while(space.isWithinCanvas() && space.isEmpty()) {
      space.paint();
      distance += strokeUnit;
      
      float[] newPos = Math.translatePoint(space.getX(), space.getY(), direction, strokeUnit);
      space = new Space(newPos[0], newPos[1]);
    }
    
    if (distance > 0) {
      distance += random(strokeVariance[0], strokeVariance[1]);
      space.paint();
      makeStroke(x, y, direction, distance);
    }       
  }
  
  void makeStroke(float x, float y, float direction, float distance){
    float x1 = 0, y1 = 0, a = 0,
          multiplier = distance/100,
          w = random(strokeLength[0], strokeLength[1]) * multiplier,
          f = random(strokeFrequency[0], strokeFrequency[1]) * multiplier;
    
    pushMatrix();
    translate(x, y);
    rotate(radians(direction));
    
    for (int i = int(x1); i < int(distance); i++) {
      float x2 = float(i);
      float y2 = sin(a)*w;    
      drawPath(x1, y1, x2, y2);
      x1 = x2;
      y1 = y2;
      a = a + TWO_PI/f;
    }
    
    popMatrix(); 
  }

}

class Space 
{
  float brightThreshold = 48,
        brightnessUnit = 8;
  
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

