/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Teriha (http://youdrawingyou.com/sketches/teriha)
 */

import processing.pdf.*;

String imgSrc = "img/teriha.jpg";
String outputFile = "output/teriha.png";
String outputPDF = "output/teriha.pdf";
boolean savePDF = false;

int museumWidth = 675;
int museumHeight = 900;
float museumWall = 20;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage museum;
TeriGroup theTeriGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(museumWidth, museumHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(museumWidth, museumHeight);
  
  // load museum from image source
  museum = loadImage(imgSrc);
  pg.image(museum, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Teris 
  theTeriGroup = new TeriGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 40);
  smooth();
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theTeriGroup.observe();
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

class TeriGroup
{
  int groupSizeLimit = 30;
  
  ArrayList<Teri> group;

  TeriGroup () {
    group = new ArrayList<Teri>();
    for(int i=0; i<groupSizeLimit; i++) {      
      group.add(new Teri());
    }    
  }

  void observe() {
    for (int i = group.size()-1; i >= 0; i--) {
      Teri teri = group.get(i);
      teri.observe();
    }    
  } 

}

class Teri
{
  int baseX = 2, baseY = 3;
  
  float myX, myY;
  
  Teri () {}
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void walk(){    
    float hx = Math.halton(spaceIterator, baseX),
          hy = Math.halton(spaceIterator, baseY);
          
    myX = hx*(museumWidth-museumWall*2)+museumWall;
    myY = hy*(museumHeight-museumWall*2)+museumWall;
    
    spaceIterator++;
  }
  
  void observe(){ 
    walk();
    
    Space space = new Space(myX, myY);
    
    if (space.hasPainting()) {
      float x = space.getX(), y = space.getY(),
            distance = space.getDistance(),
            direction = space.getDirection();
            
      float[] newPos = Math.translatePoint(x, y, direction, distance);
      drawPath(x, y, newPos[0], newPos[1]);    
    }
  }

}



class Space 
{
  float brightThreshold = 30,
        brightnessUnit = 5,
        distanceUnit = 20,
        compression = 1.2,
        directionVariance = 2;
  
  float myX, myY, myBrightness, myDirection;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinWalls()) {
      myColor = spaces[int(myX) + int(myY)*museumWidth];
      myBrightness = brightness(myColor);
      setDirection();
    }    
  }
  
  float getBrightness(){
    return myBrightness;
  }

  float getDirection(){
    return myDirection;
  }
  
  float getDistance(){    
    float multiplier = 1.0 - myY/museumHeight,
          distance = myBrightness/brightnessUnit * distanceUnit * multiplier;
    
    return distance;
  }
  
  float getX(){
    float translateX = museumWidth/2 - museumWidth*compression/2,
          x = myX*compression + translateX;
    return x;
  }
  
  float getY(){
    return myY;
  }
  
  boolean hasPainting(){
    return (myBrightness > brightThreshold);
  }
  
  boolean isWithinWalls(){
    return (Math.inBounds(myX, myY, museumWidth, museumHeight, museumWall));
  }
  
  void setDirection(){
    myDirection = 270 + random(-directionVariance, directionVariance);
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
