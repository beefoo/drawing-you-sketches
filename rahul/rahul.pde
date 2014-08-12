/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Rahul
 */
 
import processing.pdf.*;

String imgSrc = "img/rahul.jpg";
String outputFile = "output/rahul.png";
String outputPDF = "output/rahul.pdf";
boolean savePDF = false;

int storeWidth = 675;
int storeHeight = 900;
int startX = round(storeWidth/2);
int startY = round(storeHeight/2);
int gridUnit = 20;
float angleUnit = 10;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 120;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage store;
RahulGang theRahulGang;
color[] bins;
float[] pathDirections;

void setup() {
  
  // set the stage
  size(storeWidth, storeHeight);
  colorMode(HSB, 360, 100, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(storeWidth, storeHeight);
  
  // load store from image source
  store = loadImage(imgSrc);
  pg.image(store, 0, 0);
  pg.loadPixels();
  
  // just lines
  noFill();
  // smooth();
  
  // set the bins and create a Rahul Gang  
  bins = pg.pixels;
  pathDirections = new float[storeWidth*storeHeight];
  theRahulGang = new RahulGang(startX, startY);
  
  // frame saver
  if (captureFrames) fs = new FrameSaver();
  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theRahulGang.loot();
}

void mousePressed() {  
  if (captureFrames) {
    fs.quit();
  } else {
    save(outputFile);
  }  
  if (savePDF) endRecord();
  exit();
}

class Rahul
{
  int capacity = 2000;
  
  float[] hueRange = {30, 50};
  float[] brightnessRange = {10, 80};
  float[] saturationRange = {20, 80};
  float[] strokeWeightRange = {0.2, 1};
  
  float chanceToDuplicate = 0.5;
  float chanceToChangeDirection = 0.5;
  float chanceToAdoptIntersectedPath = 0.4;
  float chanceToAdoptNeighborPath = 0.1;
  
  int myX, myY, myStuffCount;
  float myDirection; // 1-360
  boolean iAmDead;
  Bin myBin;
  
  Rahul (int x, int y, int stuffCount, float direction) {
    myX = x;
    myY = y;
    myStuffCount = stuffCount;
    myDirection = normalizeAngle(direction);
    iAmDead = false;
  }
  
  Bin chooseABin() {
    int[] nextPosition = getNewPosition(myX, myY, myDirection, gridUnit);
    float chance = random(0,1);    
    float direction;
    Bin nextBin = new Bin(nextPosition[0], nextPosition[1]);
    
    // if next bin is not empty and in bounds
    if (!nextBin.isEmpty() && nextBin.isInBounds()) {

      if (nextBin.wasVisited() && chance < chanceToAdoptIntersectedPath) {
        myDirection = nextBin.visitorsDirection();        
        
      } else if (nextBin.neighborsAverageDirection() > 0 && chance < chanceToAdoptNeighborPath) {
        myDirection = nextBin.neighborsAverageDirection();
        
      } else if (chance < chanceToChangeDirection) {
        myDirection = nudgeAngle(myDirection);
      }
      
      nextPosition = getNewPosition(myX, myY, myDirection, gridUnit);
      nextBin = new Bin(nextPosition[0], nextPosition[1]);
      
    // if next bin is empty or out-of-bounds
    } else {
      nextBin = getClosestAvailableBin();
    }
  
    return nextBin;  
  }
  
  void drawPath(int x1, int y1, int x2, int y2, int iterator) {    
    strokeWeight(0.1);
    stroke(40, 20, 20, 10);
    line(x1, y1, x2, y2);
  }
  
  void die(){
    iAmDead = true;
  }
  
  void dropEverything() {
    // TODO
    myStuffCount = 0;
  }
  
  Rahul duplicate(){
    // make a new Rahul with half my stuff and a different direction
    float newDirection = nudgeAngle(myDirection);
    Rahul newRahul = new Rahul(myX, myY, floor(myStuffCount/2), newDirection);
    
    // halve my own stuff
    myStuffCount = ceil(myStuffCount/2);
    
    return newRahul;
  }
  
  float getChanceToDuplicate(){
    return chanceToDuplicate;
  }
  
  Bin getClosestAvailableBin(){
    boolean binFound = false, first = true;
    Bin closestBin = new Bin(0, 0);
    
    for(int a=int(angleUnit); a<=180 && !binFound; a+=int(angleUnit)) {
      for(int b=-1; b<=1 && !binFound; b+=2) {
        
        float direction = normalizeAngle(myDirection+float(b * a));
        int[] position = getNewPosition(myX, myY, direction, gridUnit);
        Bin bin = new Bin(position[0], position[1]);
        
        // default to first in-bounds bin
        if (first && bin.isInBounds()) {
          closestBin = bin;
          first = false; 
        }
        
        if (!bin.isEmpty() && bin.isInBounds()) {
          closestBin = bin;
          binFound = true;
        }
        
      }      
    }
    
    return closestBin;
  }
  
  int[] getNewPosition(int x, int y, float angle, float distance){
    int[] coords = new int[2];
    float r = radians(angle);
    
    coords[0] = x + round(distance*cos(r));
    coords[1] = y + round(distance*sin(r));
    
    return coords;
  }
  
  int getStuffCount(){
    return myStuffCount;
  }
 
  boolean isAlive(){
    return (!iAmDead);
  } 
  
  boolean isOverCapacity(){
    return (myStuffCount >= capacity);
  }
  
  boolean loot(){
    boolean foundStuff = false;
    int dieAfter = 1000; // die after this many failed tries
    int i = 0;
    
    // move until i find stuff
    while(!foundStuff){
      foundStuff = move(i);
      i++;
      if (i>dieAfter) {
        die();
        break;
      }
    }
    
    if (foundStuff) {
      stealStuff();
    }
    
    return foundStuff;    
  }
  
  boolean move(int iterator){
    // see if I can find a bin that's not empty or the current one
    myBin = chooseABin();    
    boolean foundStuff = (!myBin.isEmpty() && myBin.isInBounds() && !myBin.positionEquals(myX, myY));
    int prevX = myX;
    int prevY = myY;
    
    // stuff found
    if (foundStuff) {
      myX = myBin.getX();
      myY = myBin.getY();     
    
    // no stuff in any bin around me
    } else {      
      moveRandomly();            
    }
    
    myBin.setPathDirection(myDirection);
    
    // draw path
    if (iterator<1) drawPath(prevX, prevY, myX, myY, iterator);
    
    return foundStuff;       
  }
  
  void moveRandomly(){
    float newAngle = normalizeAngle(random(1, 360));
    int[] newPosition = getNewPosition(myX, myY, newAngle, gridUnit);
    
    // move in that direction
    myX = newPosition[0];
    myY = newPosition[1];
    myDirection = newAngle;

    // make sure i am not at the edge
    if (myX < gridUnit) myX = gridUnit;
    if (myY < gridUnit) myY = gridUnit;
    if (myX > storeWidth-gridUnit-1) myX = storeWidth-gridUnit-1;
    if (myY > storeHeight-gridUnit-1) myY = storeHeight-gridUnit-1;
    
    // update my bin
    myBin = new Bin(myX, myY);    
  }
  
  float normalizeAngle(float angle){
    // round to nearest angle unit
    angle = round(angle/angleUnit)*angleUnit;
    
    // ensure I am within 1-360 degrees
    if (angle > 360) angle = angle - 360;
    else if (angle < 1) angle = 360 + angle;
    
    return angle;
  }
  
  float nudgeAngle(float angle) {
    float variance = angleUnit;
    if (random(-1,1) < 0) variance *= -1;
    return normalizeAngle(angle * variance);
  }
  
  void stealStuff() {
    float stuffAmount = myBin.take();    
    myStuffCount += round(stuffAmount);
  }
}

class RahulGang
{
  int gangSizeLimit = 40;  
  
  ArrayList<Rahul> gang;

  RahulGang (int x, int y) {    
    gang = new ArrayList<Rahul>();
    gang.add(new Rahul(x, y, 0, random(1, 360)));
  }
  
  void giveJudgementTo(Rahul rahul) {
    float judgement = random(0, 1);
    
    if (judgement < rahul.getChanceToDuplicate() && gang.size() < gangSizeLimit) {
      Rahul newRahul = rahul.duplicate();
      gang.add(newRahul);
      
    } else {
      rahul.dropEverything();
    }
  }

  void loot() {
    for (int i = gang.size()-1; i >= 0; i--) {
      Rahul rahul = gang.get(i);
      if (!rahul.isAlive()) continue;
      
      rahul.loot();
      
      if (rahul.isOverCapacity()) {
        giveJudgementTo(rahul);
      }
    }    
  } 

}

class Bin
{
  float stuffBrightness = 20; // a white pixel will have 100 brightness and thus about 10 things to take; < 10 brightness is considered empty
  
  float myHue, mySaturation, myBrightness;
  int myX, myY;
  
  Bin (int x, int y) {
    myX = x;
    myY = y;    
    ensureInBounds();
    
    // retrieve bin's current color
    color c = bins[myX+myY*storeWidth];
    myHue = hue(c);
    mySaturation = saturation(c);
    myBrightness = brightness(c);
    
  }
  
  void ensureInBounds(){
    if (myX < gridUnit) myX = gridUnit;
    if (myY < gridUnit) myY = gridUnit;
    if (myX > storeWidth-gridUnit-1) myX = storeWidth-gridUnit-1;
    if (myY > storeHeight-gridUnit-1) myY = storeHeight-gridUnit-1;
  }
  
  float getBrightness() {
    return myBrightness; 
  }
  
  int getX(){
    return myX;
  }
  
  int getY(){
    return myY;
  }
  
  boolean isEmpty(){    
    return (myBrightness < stuffBrightness);
  }
  
  boolean isInBounds(){
    return (myX>=gridUnit 
              && myY>=gridUnit 
              && myX<=storeWidth-gridUnit-1
              && myY<=storeHeight-gridUnit-1);
  }
  
  float neighborsAverageDirection(){
    int[] delta = {0, -1};
    int dx = 0, dy = 0, directionCount = 0;
    float directionsTotal = 0, averageDirection = 0;
    
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
     
      // check if bin was visited     
      Bin bin = new Bin(myX+dx*gridUnit, myY+dy*gridUnit);
      if (bin.wasVisited()){
        directionsTotal += bin.visitorsDirection();
        directionCount++;
      }           
    }
    
    if (directionCount > 0) {
      averageDirection = directionsTotal/directionCount;
    }
    
    return averageDirection;
  }
  
  boolean positionEquals(int x, int y) {
    return (x==myX && y==myY);
  }
  
  void setPathDirection(float direction){
    if (!wasVisited()) {
      pathDirections[myX+myY*storeWidth] = direction;
    }
  }
  
  float take(){
    float stuffAmount = stuffBrightness;
    
    myBrightness -= stuffAmount;
    
    // can't have stuff with a negative brightness
    if (myBrightness<0) {
      stuffAmount += myBrightness;
      myBrightness = 0;
    }
    if (stuffAmount<0) {
      stuffAmount = 0; 
    }
    
    // update bin    
    color c = color(myHue, mySaturation, myBrightness);
    bins[myX+myY*storeWidth] = c;
    
    return stuffAmount;
  }
  
  float visitorsDirection(){
    return pathDirections[myX+myY*storeWidth];
  }
  
  boolean wasVisited(){
    return (visitorsDirection() > 0);
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
