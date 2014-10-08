/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Todd (http://youdrawingyou.com/sketches/todd)
 */

import processing.pdf.*;

String imgSrc = "img/todd.jpg";
String outputFile = "output/todd.png";
String outputPDF = "output/todd.pdf";
boolean savePDF = true;

int spaceWidth = 675;
int spaceHeight = 900;
int gridUnit = 10;
float startX = 237;
float startY = 234;
int spaceIterator = 0;
float angleVariance = 25;
float angleUnit = 1;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = true;
FrameSaver fs;

PGraphics pg;
PImage space;
ToddGroup theToddGroup;
color[] spaces;
float[] visitedSpaces;

void setup() {
  
  // set the stage
  size(spaceWidth, spaceHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(spaceWidth, spaceHeight);
  
  // load space from image source
  space = loadImage(imgSrc);
  pg.image(space, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  

  // create a group of Todds 
  theToddGroup = new ToddGroup(startX, startY);
  visitedSpaces = new float[spaceWidth*spaceHeight];
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 12);
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theToddGroup.perform();
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

class Todd
{
  float[] frequencyRange = {220, 240}, // width of wave
          waveRange = {10, 30}; // height of wave
  
  int baseX = 2, baseY = 3;  
  float myX, myY;
  
  Todd (float x, float y) {
    myX = x;
    myY = y;
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  float[] getNextPosition(){
    float[] position = new float[2];
    float hx = Math.halton(spaceIterator, baseX);
    float hy = Math.halton(spaceIterator, baseY);
    
    position[0] = hx*(spaceWidth-gridUnit*2)+gridUnit;
    position[1] = hy*(spaceHeight-gridUnit*2)+gridUnit;
    
    spaceIterator++;
    return position;
  }
  
  void perform(){    
    float[] nextPosition = getNextPosition();
    Space space = new Space(nextPosition[0], nextPosition[1]);
    
    float waveLength = random(waveRange[0], waveRange[1]);
    float frequency = random(frequencyRange[0], frequencyRange[1]);
    
    if (space.isBright()) {
      sing(myX, myY, space.getX(), space.getY(), waveLength, frequency);
    }
  }
  
  void sing(float x1, float y1, float x2, float y2, float waveLength, float frequency) {
    float distance = dist(x1, y1, x2, y2),
          angle = Math.angleBetweenPoints(x1, y1, x2, y2),
          a = 0, x = 0, y = 0;
    
    pushMatrix();
    translate(x1, y1);
    rotate(radians(angle));
    
    for (int i = int(x); i < int(distance); i++) {
      float _x = float(i);
      float _y = sin(a)*waveLength;    
      drawPath(x, y, _x, _y);
      x = _x;
      y = _y;
      a = a + TWO_PI/frequency;
    }
    
    popMatrix();
  }

}

class ToddGroup
{
  int groupSizeLimit = 20;
  
  ArrayList<Todd> group;

  ToddGroup (float x, float y) {
    group = new ArrayList<Todd>();
    for(int i=0; i<groupSizeLimit; i++) {      
      group.add(new Todd(x, y));
    }    
  }

  void perform() {
    for (int i = group.size()-1; i >= 0; i--) {
      Todd todd = group.get(i);
      todd.perform();
    }    
  } 

}

class Space 
{
  float brightThreshold = 51;
  
  float myX, myY, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    myColor = spaces[int(myX) + int(myY)*spaceWidth];
    myBrightness = brightness(myColor);
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
  
  boolean isBright(){
    return (myBrightness > brightThreshold);
  }
  
}

static class Math {
  
  static float angleBetweenPoints(float x1, float y1, float x2, float y2){
    float deltaX = x2 - x1,
          deltaY = y2 - y1;  
    return atan2(deltaY, deltaX) * 180 / PI;
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
  
  static float[] translatePoint(float x, float y, float angle, float distance){
    float[] newPoint = new float[2];
    float r = radians(angle);
    
    newPoint[0] = x + distance*cos(r);
    newPoint[1] = y + distance*sin(r);
    
    return newPoint;
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
