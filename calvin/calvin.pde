/*
 * Drawing You Better (http://drawingyoubetter.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Calvin (http://drawingyoubetter.com/sketches/calvin)
 */

import processing.pdf.*;

String imgSrc = "img/calvin.jpg";
String outputFile = "output/calvin.png";
String outputPDF = "output/calvin.pdf";
boolean savePDF = false;

int mapWidth = 675;
int mapHeight = 900;
float mapMargin = 20;
int destinationIterator = 0;

int fr = 200;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage map;
CalvinGroup theCalvinGroup;
color[] places;

void setup() {
  
  // set the stage
  size(mapWidth, mapHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(mapWidth, mapHeight);
  
  // load map from image source
  map = loadImage(imgSrc);
  pg.image(map, 0, 0);
  pg.loadPixels();
  places = pg.pixels;  
  
  // noLoop();

  // create a group of Calvins 
  theCalvinGroup = new CalvinGroup();
  
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
  
  theCalvinGroup.travel();
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

class CalvinGroup
{
  int baseX = 2, baseY = 3;
  
  int[] destinationRange = {1, 6};
  
  float ourX, ourY;

  CalvinGroup () {
       
  }
  
  void chooseNextDestination(){    
    float hx = Math.halton(destinationIterator, baseX),
          hy = Math.halton(destinationIterator, baseY);
          
    ourX = hx*(mapWidth-mapMargin*2)+mapMargin;
    ourY = hy*(mapHeight-mapMargin*2)+mapMargin;
    
    destinationIterator++;
  }

  void travel() {
    chooseNextDestination();
    
    Space space = new Space(ourX, ourY);    
    if (space.isLand()) {
      
      int destinationCount = round(random(destinationRange[0], destinationRange[1]));      
      float x = space.getX(), y = space.getY(), 
            direction = space.getDirection(),
            distance = space.getDistance(),
            destinationDistance = max(round(distance/destinationCount), 1);
   
      ArrayList<Calvin> group = new ArrayList<Calvin>();
      for(int i=0; i<space.getSize(); i++) {      
        Calvin calvin = new Calvin(ourX, ourY, i);
        calvin.travel(x, y, direction, destinationDistance, destinationCount);
      }      
    }
    
        
  } 

}

class Calvin
{
  int[] wanderRange = {-20, 20};
  
  float myX, myY;
  int myPosition;
  
  Calvin (float x, float y, int position) {
    myX = x;
    myY = y;
    myPosition = position;
  }
  
  void drawPath(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
  }
  
  void drawCurve(ArrayList<Space> points){
    
    beginShape();
    // curveTightness(curveTightness);
    for(int i=0; i<points.size(); i++) {
      Space point = points.get(i);
      
      // control points
      if (i<=0 || i>=points.size()-1) {
        curveVertex(point.getX(), point.getY());
      }
      
      curveVertex(point.getX(), point.getY());
    } 
    endShape();   
  
  }
  
  float getWanderAmount(float x, float y, float direction, int destinationCount){
    float amount = random(wanderRange[0], wanderRange[1]),
          delta = 90 - direction;
    boolean southOfBorder = (direction < 180);
    
    if (southOfBorder) {
      amount += delta/destinationCount;
      
    } else {
      delta = 90 - (direction-180);
      amount += -delta/destinationCount;
    }    
    
    return amount;
  }
  
  void travel(float x, float y, float direction, float distance, int destinationCount){ 
    ArrayList<Space> destinations = new ArrayList<Space>();
    
    destinations.add(new Space(x, y));
    
    for(int d=0; d<destinationCount; d++) {
      direction += getWanderAmount(x, y, direction, destinationCount);    
      float[] nextDestination = Math.translatePoint(x, y, direction, distance);
      destinations.add(new Space(nextDestination[0], nextDestination[1]));
      x = nextDestination[0];
      y = nextDestination[1];
    } 
    
    drawCurve(destinations);
  }

}



class Space 
{
  float brightThreshold = 5,
        brightnessUnit = 5,
        directionVariance = 20,
        distanceVariance = 35;
  
  float myX, myY, myBrightness, myDirection, myDistance;
  color myColor;
  
  Space(float x, float y) {
    myX = x;
    myY = y;
    if (isWithinMargins()) {
      myColor = places[int(myX) + int(myY)*mapWidth];
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
    float distance = 1;
    boolean waterFound = false;
    
    while(!waterFound) {
      float[] nextPos = Math.translatePoint(myX, myY, myDirection, distance);
      Space sample = new Space(nextPos[0], nextPos[1]);
      if (!sample.isLand() || !sample.isWithinMargins()) {
        waterFound = true; 
      } else {
        distance++;
      }      
    }
    
    return distance + random(0, distanceVariance);    
  }
  
  int getSize(){
    return round(myBrightness/brightnessUnit);
  }
  
  float getX(){
    return myX;
  }
  
  float getY(){
    return myY;
  }
  
  boolean isLand(){
    return (myBrightness > brightThreshold);
  }
  
  boolean isWithinMargins(){
    return (Math.inBounds(myX, myY, mapWidth, mapHeight, mapMargin));
  }
  
  void setDirection(){
    float centerX = 1.0*mapWidth/2,
          centerY = 1.0*mapHeight/2;
          
    myDirection = Math.angleBetweenPoints(centerX, centerY, myX, myY);          
    myDirection += random(-directionVariance, directionVariance);
    myDirection = Math.normalizeAngle(myDirection);
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
