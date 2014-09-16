/*
 * Drawing You Better (http://drawingyoubetter.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Lena (http://drawingyoubetter.com/sketches/lena)
 */

import processing.pdf.*;

String imgSrc = "img/lena.jpg";
String outputFile = "output/lena.png";
String outputPDF = "output/lena.pdf";
boolean savePDF = false;

int tableWidth = 675;
int tableHeight = 900;
float tableBorder = 50;
float gridUnit = 120;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage table;
LenaGroup theLenaGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(tableWidth, tableHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(tableWidth, tableHeight);
  
  // load table from image source
  table = loadImage(imgSrc);
  pg.image(table, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Lenas 
  theLenaGroup = new LenaGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 30);
  smooth();
  
  if(captureFrames && !fs.running) {
    fs.start();
  }

  theLenaGroup.construct();
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

class LenaGroup
{
  int baseX = 2, baseY = 3;
  int groupSize = 40;
  float ourX, ourY;
  
  ArrayList<Lena> group;

  LenaGroup () {    
    group = new ArrayList<Lena>();
    for(int i=0; i<groupSize; i++) {
      group.add(new Lena());
    }
  }

  void construct() {   
    for (int i = group.size()-1; i >= 0; i--) {
      float hx = Math.halton(spaceIterator, baseX),
            hy = Math.halton(spaceIterator, baseY),
            x = hx*(tableWidth-tableBorder*2)+tableBorder,
            y = hy*(tableHeight-tableBorder*2)+tableBorder;     
      Lena lena = group.get(i);
      lena.placeObject(x, y);
      spaceIterator++;
    }   
  } 

}

class Lena
{  
  Lena () {}
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void placeObject(float x, float y){    
    Space space = new Space(x, y);
    if (space.isAvailable()) {
      float[] position = space.getNewPosition();
      drawPath(x, y, position[0], position[1]);
    }
  }

}

class Space 
{
  float brightThreshold = 10,
        brightnessUnit = 10,
        distanceUnit = 16,
        angleGroups = 4,
        angleVariance = 2,
        angleRotation = 90,
        angleMax = 120;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinTable()) {
      myColor = spaces[int(myX) + int(myY)*tableWidth];
      myHue = hue(myColor);
      mySaturation = saturation(myColor);
      myBrightness = brightness(myColor); 
    }      
  }
  
  float getBrightness(){
    return myBrightness;
  }
  
  float[] getNewPosition(){
    float distance = 0,
          x = myX, y = myY,
          xUnit = Math.floorToNearest(x, gridUnit),
          yUnit = Math.floorToNearest(y, gridUnit),
          unit = Math.halton(int(xUnit + yUnit), 5) * 100;
    float[] newPos = {x, y};
    boolean valid = true;
    float angle = angleMax * (unit % angleGroups)/angleGroups + angleRotation;    
    angle += random(-angleVariance, angleVariance);
    
    //println(angle);
    
    while(valid) {
      newPos = Math.translatePoint(x, y, angle, distanceUnit);
      distance += distanceUnit;
      Space space = new Space(newPos[0], newPos[1]);
      if (space.isWithinTable() && space.isAvailable()) {
        space.occupy();
        x = newPos[0];
        y = newPos[1];
      } else {
        valid = false; 
      }
    }
    
    return newPos;
  }
  
  float getX(){    
    return myX;
  }
  
  float getY(){
    return myY;
  }
  
  boolean isAvailable(){
    return (myBrightness >= brightThreshold);
  }
  
  boolean isWithinTable(){    
    return (Math.inBounds(myX, myY, tableWidth, tableHeight, tableBorder));
  }
  
  void occupy(){    
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*tableWidth] = color(myHue, mySaturation, myBrightness);
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

