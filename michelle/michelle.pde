/*
 * Drawing You Better (http://drawingyoubetter.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Michelle (http://drawingyoubetter.com/sketches/michelle)
 */

import processing.pdf.*;

String imgSrc = "img/michelle.jpg";
String outputFile = "output/michelle.png";
String outputPDF = "output/michelle.pdf";
boolean savePDF = false;

int gapWidth = 675;
int gapHeight = 900;
float gapBorder = 60;
float jumpUnit = 60;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage gap;
MichelleGroup theMichelleGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(gapWidth, gapHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(gapWidth, gapHeight);
  
  // load gap from image source
  gap = loadImage(imgSrc);
  pg.image(gap, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Michelles 
  theMichelleGroup = new MichelleGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 22);
  smooth();
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theMichelleGroup.jump();
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

class MichelleGroup
{
  int groupSizeLimit = 40;
  
  ArrayList<Michelle> group;

  MichelleGroup () {
    
    group = new ArrayList<Michelle>();
    
    for(int i=0; i<groupSizeLimit/2; i++) {      
      group.add(new Michelle(gapBorder + random(0,gapBorder), 0));
    }
    
    for(int j=0; j<groupSizeLimit/2; j++) {
      group.add(new Michelle(gapWidth-gapBorder-random(1,gapBorder), 180));
    }
  }

  void jump() {
    for (int i = group.size()-1; i >= 0; i--) {
      Michelle michelle = group.get(i);
      michelle.jump();
    }    
  } 

}

class Michelle
{
  float directionVariance = 55, center = 0.55;
  
  float startX, myX, myY, myDirection;
  float myX1, myY1, myX2, myY2, myX3, myY3;
  
  Michelle (float x, float direction) {
    startX = x;
    myDirection = direction;
    restart();
  }
  
  void drawCurve(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    curve(x1, y1, x2, y2, x3, y3, x4, y4);
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void jump(){
    boolean jumped = false, outOfBounds = false;
    float[] nextPos = Math.translatePoint(myX3, myY3, myDirection, random(jumpUnit/2,jumpUnit));
    Space nextSpace = new Space(nextPos[0], nextPos[1]);
    float lightest = 0;
    
    for(int i=1; i<directionVariance; i++) {
      
      for(int j=-1; j<=1; j+=2) {        
        float[] pos = Math.translatePoint(myX3, myY3, myDirection+i*j, random(jumpUnit/2,jumpUnit));
        Space space = new Space(pos[0], pos[1]);
        
        if (!space.isEmpty() && space.isWithinGap() && space.getBrightness()>lightest) {          
          nextSpace = space;
          jumped = true;
          lightest = space.getBrightness();
        }
     
        if (!space.isWithinGap()) {
          outOfBounds = true;
        }   
      }     
      
    }
    
    if (nextSpace.isWithinGap()) {
      if (jumped) {
        curveTightness(random(-1, 0));
        drawCurve(myX1, myY1, myX2, myY2, myX3, myY3, nextSpace.getX(), nextSpace.getY());
        nextSpace.occupy();
      }
      myX1 = myX2;
      myY1 = myY2;
      myX2 = myX3;
      myY2 = myY3;     
      myX3 = nextSpace.getX();
      myY3 = nextSpace.getY();
    }
    
    if (!jumped && outOfBounds) {
      restart();      
    }
    
  }
  
  void restart(){
    myY = gapHeight * center;
    myX = startX;
    
    myX1 = myX;
    myY1 = myY;
    myX2 = myX;
    myY2 = myY;
    myX3 = myX;
    myY3 = myY;
    
    spaceIterator++;
  }

}



class Space 
{
  float brightThreshold = 1,
        brightnessUnit = 20;
  
  float[] positionVariance = {4, 8};
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;    
    myColor = spaces[int(myX) + int(myY)*gapWidth];
    myHue = hue(myColor);
    mySaturation = saturation(myColor);
    myBrightness = brightness(myColor);   
  }
  
  float getBrightness(){
    return myBrightness;
  }
  
  float getX(){    
    return Math.floorToNearest(myX, random(positionVariance[0], positionVariance[1]));
  }
  
  float getY(){
    return Math.floorToNearest(myY, random(positionVariance[0], positionVariance[1]));
  }
  
  boolean isEmpty(){
    return (myBrightness < brightThreshold);
  }
  
  boolean isWithinGap(){
    return (Math.inBounds(myX, myY, gapWidth, gapHeight, gapBorder));
  }
  
  void occupy(){    
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*gapWidth] = color(myHue, mySaturation, myBrightness);
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
