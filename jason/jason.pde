/*
 * Drawing You Better (http://drawingyoubetter.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Jason (http://drawingyoubetter.com/sketches/jason)
 */

import processing.pdf.*;

String imgSrc = "img/jason.jpg";
String outputFile = "output/jason.png";
String outputPDF = "output/jason.pdf";
boolean savePDF = false;

int fieldWidth = 675;
int fieldHeight = 900;
float fieldBorder = 50;
float gridUnit = 1;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage field;
JasonGroup theJasonGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(fieldWidth, fieldHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(fieldWidth, fieldHeight);
  
  // load field from image source
  field = loadImage(imgSrc);
  pg.image(field, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Jasons 
  theJasonGroup = new JasonGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 50);
  smooth();
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theJasonGroup.hurl();
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

class JasonGroup
{
  int groupSizeLimit = 20;
  
  ArrayList<Jason> group;

  JasonGroup () {    
    group = new ArrayList<Jason>();
    
    for(int i=0; i<groupSizeLimit; i++) {      
      group.add(new Jason(fieldWidth/2, fieldHeight/2));
    }
  }

  void hurl() {
    for (int i = group.size()-1; i >= 0; i--) {
      Jason jason = group.get(i);
      jason.hurl();
    }    
  } 

}

class Jason
{
  float variance = 20, angleMultiplier = 0.3, step = 2;
  
  float centerX, centerY, myX, myY, myI;
  
  Jason (float x, float y) {
    centerX = x;
    centerY = y;
    reset();
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void hurl(){    
    float a = 1, b = 1, angle = angleMultiplier * myI,
          x = (a+angle)*cos(angle) + centerX + random(-variance, variance),
          y = (b+angle)*sin(angle) + centerY + random(-variance, variance);
    
    Space space = new Space(x, y);
    
    if (space.isWithinField() && !space.isEmpty()) {
      drawPath(myX, myY, x, y);      
      space.occupy();      
    }
    
    if (space.isWithinYField()) {
      myX = x;
      myY = y;
      myI+=step;
      
    } else {
      reset(); 
    }
      
  }
  
  void reset(){
    myX = centerX;
    myY = centerY;
    myI = 0;
  }

}



class Space 
{
  float brightThreshold = 50,
        brightnessUnit = 20;
  
  float myX, myY, myHue, mySaturation, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinField()) {
      myColor = spaces[int(myX) + int(myY)*fieldWidth];
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
    return (myBrightness < brightThreshold);
  }
  
  boolean isWithinField(){    
    return (Math.inBounds(myX, myY, fieldWidth, fieldHeight, fieldBorder));
  }
  
  boolean isWithinYField(){   
    return (myY>=fieldBorder && myY<=fieldHeight-fieldBorder-1);
  }
  
  void occupy(){    
    myBrightness -= brightnessUnit;
    
    if (myBrightness<0) {
      myBrightness = 0;
    }
    
    // update space
    spaces[int(myX)+int(myY)*fieldWidth] = color(myHue, mySaturation, myBrightness);
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
