/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my brother Brandon (http://youdrawingyou.com/sketches/brandon)
 */

import processing.pdf.*;
import java.util.Collections;
import java.util.Comparator;

String imgSrc = "img/brandon.jpg";
String outputFile = "output/brandon.png";
String outputPDF = "output/brandon.pdf";
boolean savePDF = true;

int courseWidth = 675;
int courseHeight = 900;
float coursePadding = 50;
float holeSize = 50;
int spaceIterator = 0;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = true;
FrameSaver fs;

PGraphics pg;
PImage course;
BrandonTeam theBrandonTeam;
color[] spaces;
float[] visitedSpaces;

void setup() {
  
  // set the stage
  size(courseWidth, courseHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(courseWidth, courseHeight);
  
  // load course from image source
  course = loadImage(imgSrc);
  pg.image(course, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  
  
  // noLoop();

  // create a team of Brandons 
  theBrandonTeam = new BrandonTeam();
  visitedSpaces = new float[courseWidth*courseHeight];
  
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
  
  theBrandonTeam.golf();
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

class Brandon
{
  int baseX = 2, baseY = 3;
  
  boolean iAmResting;
  
  Brandon () {
    iAmResting = false;
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  Space getNextHole() {
    float hx = Math.halton(spaceIterator, baseX),
          hy = Math.halton(spaceIterator, baseY),
          x = hx*(courseWidth-coursePadding*2)+coursePadding,
          y = hy*(courseHeight-coursePadding*2)+coursePadding;
    
    Space hole = new Space(x, y, holeSize);    
    spaceIterator++;
    
    return hole;
  }
  
  boolean isResting(){
    return iAmResting;
  }
  
  void play(){
    Space hole = getNextHole();
    // hole.setNeighborsDirection();
    
    for(int swing=0; swing<hole.getCapacity(); swing++) {
      float[] target = Math.translatePoint(hole.getX(0), hole.getY(0), hole.getDirection(0), hole.getDistance(2, 1));
      
      if (Math.inBounds(target[0], target[1], courseWidth, courseHeight, coursePadding)) {
        drawPath(hole.getX(holeSize/2), hole.getY(holeSize/2), target[0], target[1]);
      }
      
    }
    
    hole.occupy();
  } 
  
  void rest(){
    iAmResting = true;
  }

}

class BrandonTeam
{
  int teamSizeLimit = 10;
  
  ArrayList<Brandon> team;

  BrandonTeam () {
    team = new ArrayList<Brandon>();
    
    for(int i=0; i<teamSizeLimit; i++) {
      team.add(new Brandon());
    }
  }

  void golf() {
    for (int i = team.size()-1; i >= 0; i--) {
      Brandon brandon = team.get(i);
      if (!brandon.isResting()) {
        brandon.play();
      }
    }    
  } 

}

class Space implements Comparable<Space>
{
  float brightnessUnit = 35;
  
  float myX, myY, myBrightness, myDirection, myGridLength, myDistance;
  int myCapacity;
  
  Space(float x, float y, float gridLength) {
    myX = Math.floorToNearest(x, gridLength);
    myY = Math.floorToNearest(y, gridLength);
    myGridLength = gridLength;
    
    if (isInBounds()) {
      setBrightness();
      setDirection();
      setDistance();
      setCapacity();
      
    } else {
      myBrightness = -1;
      myDirection = -1;
      myDistance = -1;
      myCapacity = -1;
    } 
  }
  
  int compareTo(Space space) {
    float value1 = myBrightness,
          value2 = space.getBrightness();
    
    if (value1 < value2) return -1;
    else if (value1 > value2) return 1;
    else return 0;
  }
  
  float getBrightness(){
    return myBrightness;
  }
  
  int getCapacity(){
    return myCapacity;
  }
  
  float getDirection(float variance){    
    return random(myDirection-variance, myDirection+variance);
  }
  
  float getDistance(float multiplier, float variance){    
    return random(myDistance*multiplier-variance, myDistance*multiplier+variance);
  }
  
  ArrayList<Space> getNeighbors(){
    ArrayList<Space> neighbors = new ArrayList<Space>();    
    int[] delta = {0, -1};
    int dx = 0, dy = 0;
    
    // go in a counter-clockwise spiral around me
    for(int i=0; i<8; i++) {
      
      // change directions
      if (dx==dy || (dx<0 && dx==(-1*dy)) || (dx>0 && dx==(1-dy))) {
        int temp = delta[0];
        delta[0] = -1*delta[1];
        delta[1] = temp;          
      }      
      
      // add delta
      dx += delta[0];
      dy += delta[1];
     
      // check if space is in bounds
      // println(myX, myY, myX+dx*myGridLength, myY+dy*myGridLength, myGridLength);
      Space space = new Space(myX+dx*myGridLength, myY+dy*myGridLength, myGridLength);
      if (space.isInBounds()){
        neighbors.add(space);
      }        
    }
    
    return neighbors;
  }
  
  float getNeighborsDirection(){
    ArrayList<Space> neighbors = getNeighbors();
    float direction = 0, directions = 0;
    int count = 0;
    
    for(int i=0; i<neighbors.size(); i++) {
      Space space = neighbors.get(i);     
      if (space.wasOccupied()) {
        directions += space.getDirection(0);
        count++;
      } 
    }
    if (count>0) {
      direction = directions/count;
    }
    
    return direction;    
  }
  
  float getX(float variance){
    return random(myX-variance, myX+variance);
  }
  
  float getY(float variance){
    return random(myY-variance, myY+variance);
  }
  
  boolean isInBounds(){
    return (Math.inBounds(myX, myY, courseWidth, courseHeight, coursePadding));
  }
  
  void occupy(){
    visitedSpaces[int(myX) + int(myY)*courseWidth] = myDirection;
  }
  
  void setBrightness(){
    float totalBrightness = 0;
    
    for(int y=0; y<myGridLength; y++) {
      for(int x=0; x<myGridLength; x++) {
        color c = spaces[int(myX+x) + int(myY+y)*courseWidth];
        totalBrightness += brightness(c);
      }
    }
    
    myBrightness = totalBrightness/(myGridLength*myGridLength);
  }
  
  void setCapacity(){
    myCapacity = round(myBrightness/brightnessUnit);
  }
  
  void setDirection(){
    /* myDirection = visitedSpaces[int(myX) + int(myY)*courseWidth];
    
    if (myDirection <= 0) {      
      float centerX = courseWidth/2,
            centerY = courseHeight/2;
            
       if (centerX==myX && centerY==myY) {
         myDirection = random(1, 360);
         
       } else {
         float direction = Math.angleBetweenPoints(centerX, centerY, myX, myY);
         myDirection = Math.normalizeAngle(direction+90);
       }
    } */
    myDirection = random(1, 360);
  }
  
  void setDistance(){
    myDistance = max(coursePadding * (myBrightness/100), 1);
  }
  
  void setNeighborsDirection(){
    float direction = getNeighborsDirection();
    
    if (direction>0) {
      myDirection = direction; 
    }
  }
  
  boolean wasOccupied(){
    return (visitedSpaces[int(myX) + int(myY)*courseWidth] > 0);
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
