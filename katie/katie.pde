/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Katie (http://youdrawingyou.com/sketches/katie)
 */

import processing.pdf.*;

String imgSrc = "img/katie.jpg";
String outputFile = "output/katie.png";
String outputPDF = "output/katie.pdf";
boolean savePDF = false;

int bookWidth = 675;
int bookHeight = 900;
float pageMargin = 20;
int pageIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage book;
KatieGroup theKatieGroup;
color[] spaces;

void setup() {
  
  // set the stage
  size(bookWidth, bookHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(bookWidth, bookHeight);
  
  // load book from image source
  book = loadImage(imgSrc);
  pg.image(book, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a group of Katies 
  theKatieGroup = new KatieGroup();
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 0, 7);
  smooth();
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theKatieGroup.write();
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

class KatieGroup
{
  int groupSizeLimit = 30;
  
  ArrayList<Katie> group;

  KatieGroup () {
    group = new ArrayList<Katie>();
    for(int i=0; i<groupSizeLimit; i++) {      
      group.add(new Katie());
    }    
  }

  void write() {
    for (int i = group.size()-1; i >= 0; i--) {
      Katie katie = group.get(i);
      katie.write();
    }    
  } 

}

class Katie
{
  int baseX = 2, baseY = 3;
  
  float myX, myY;
  
  Katie () {
    turnPage();
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void turnPage(){    
    float hx = Math.halton(pageIterator, baseX),
          hy = Math.halton(pageIterator, baseY);
          
    myX = hx*(bookWidth-pageMargin*2)+pageMargin;
    myY = hy*(bookHeight-pageMargin*2)+pageMargin;
    
    pageIterator++;
  }
  
  void write(){
    Space space = new Space(myX, myY);        
    
    if (space.isEmpty()) {      
      float startX = myX, startY = myY,
            borderY = -bookHeight/bookWidth * startX + bookHeight,
            targetX = pageMargin, targetY = bookHeight - pageMargin,
            middlePosition = 0.6, curveRadius = 0.05,
            distance = dist(targetX, targetY, startX, startY),
            angle = Math.angleBetweenPoints(startX, startY, targetX, targetY),
            translateX = pageMargin,
            translateY = -pageMargin*2,
            curveAngle = angle+90,
            curveTightness = random(-0.9, 0);
      
      if (borderY > myY) {
        curveAngle = angle-90; 
      }
                  
      float[] middlePoint = Math.translatePoint(startX, startY, angle, distance*middlePosition),
              curvePoint = Math.translatePoint(middlePoint[0], middlePoint[1], curveAngle, distance*curveRadius);
      
      beginShape();
      curveTightness(curveTightness);
      curveVertex(startX+translateX, startY+translateY);
      curveVertex(startX+translateX, startY+translateY);
      curveVertex(curvePoint[0]+translateX, curvePoint[1]+translateY);
      curveVertex(targetX+translateX, targetY+translateY);
      curveVertex(targetX+translateX, targetY+translateY); 
      endShape();      
    }
    
    turnPage();
  }

}



class Space 
{
  float brightThreshold = 30;
  char[] letters = {'l', 'i', 'n', 'e', ' '};
  
  float myX, myY, myBrightness;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    myColor = spaces[int(myX) + int(myY)*bookWidth];
    myBrightness = brightness(myColor);
  }
  
  float getBrightness(){
    return myBrightness;
  }
  
  char getLetter(){
    int pickOne = round(random(0, letters.length-1));
    return letters[pickOne];
  }
  
  float getX(){
    return myX;
  }
  
  float getY(){
    return myY;
  }
  
  boolean isEmpty(){
    return (myBrightness > brightThreshold);
  }
  
  boolean isWithinMargins(){
    return (Math.inBounds(myX, myY, bookWidth, bookHeight, pageMargin));
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
