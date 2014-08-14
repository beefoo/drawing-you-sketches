/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Vicky (http://youdrawingyou.com/sketches/vicky)
 */

import processing.pdf.*;

String imgSrc = "img/vicky.jpg";
String outputFile = "output/vicky.png";
String outputPDF = "output/vicky.pdf";
boolean savePDF = false;

int islandWidth = 675;
int islandHeight = 900;
int startX = 320;
int startY = 308;
int gridUnit = 1;
float angleUnit = 1;
float angleVariance = 10;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 120;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage island;
VickyTeam theVickyTeam;
color[] landUnits;
float[] pathDirections;

void setup() {
  
  // set the stage
  size(islandWidth, islandHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(islandWidth, islandHeight);
  
  // load island from image source
  island = loadImage(imgSrc);
  pg.image(island, 0, 0);
  pg.loadPixels();
  landUnits = pg.pixels;  

  // create a team of Vickys 
  theVickyTeam = new VickyTeam(startX, startY);
  pathDirections = new float[islandWidth*islandHeight];
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  stroke(40, 20, 20, 50);
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theVickyTeam.explore();
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

class Vicky
{
  float walkDistance = 10, runDistance = 200, swimDistance = 60, jumpDistance = 300;
  float chanceToDuplicate = 0.2, chanceToObserve = 0.2, chanceToRun = 0.1;
  int observationTimeUnit = 20;
  
  int myX, myY;
  float myDirection, myDistance;
  String myStatus; // exploring, observing, running, duplicating, drowned
  MonkeyGroup observedGroup;
  
  Vicky (int x, int y) {
    myX = x;
    myY = y;
    myDirection = random(1, 360);
    
    changeStatus("exploring");    
  }
  
  void changeStatus(String status) {
    // println("Changing Status to", status);
    myStatus = status;
    if (myStatus=="running") {
      myDistance = runDistance;
    } else {
      myDistance = walkDistance;
    }
  }
  
  void decideWhatToDo(){
    if (myStatus=="exploring" || myStatus=="running") explore();
    else if (myStatus=="observing") observe();
    else if (myStatus=="duplicating") {
      changeStatus("exploring");
      explore();
    } else if (myStatus=="drowned") {
      respawn(); 
    }
  }
  
  void decideWhatToDoWithBigGroup(){
    float chance = random(0, 1);
    
    if (chance < chanceToDuplicate) {
      changeStatus("duplicating");
    }
   
    if (chance > 1.0-chanceToRun) {
      run();
    }
    
    if (chance < chanceToObserve && !observedGroup.wasObserved()) {
      observe(); 
    }
    
  }
  
  void decideWhatToDoWithSmallGroup(){    
    lookSomewhereElse();
  }
  
  Vicky duplicate(){
    return new Vicky(myX, myY);
  }
  
  void drawCircle(int x, int y, int r) {
    int diameter = r*2;
    ellipse(x, y, diameter, diameter);
  }
  
  void drawPath(int x1, int y1, int x2, int y2) {
    line(x1, y1, x2, y2);
  } 
  
  void explore(){
    myDirection = nudgeAngle(myDirection, angleVariance);   
    int[] newPosition = getNewPosition(myX, myY, myDirection, myDistance);
    MonkeyGroup newGroup = new MonkeyGroup(newPosition[0], newPosition[1]);
    
    if (newGroup.wasObserved()) {
      myDirection = newGroup.observersDirection();
      turnAway();
      myDirection = nudgeAngle(myDirection, angleVariance);
      newPosition = getNewPosition(myX, myY, myDirection, myDistance);
      newGroup = new MonkeyGroup(newPosition[0], newPosition[1]);
    }
    
    if (newGroup.isWater() || newGroup.isEdge()) {
      newPosition = paddleToLand();
      newGroup = new MonkeyGroup(newPosition[0], newPosition[1]);
    }   
    
    moveTo(newPosition[0], newPosition[1]);  

    if (newGroup.isBig()) {
      decideWhatToDoWithBigGroup();
      
    } else if (newGroup.isSmall()) {
      decideWhatToDoWithSmallGroup();
    }          
  }
  
  int[] getNewPosition(int x, int y, float angle, float distance){
    int[] coords = new int[2];
    float r = radians(angle);
    
    coords[0] = x + round(distance*cos(r));
    coords[1] = y + round(distance*sin(r));
    
    // ensure is in bounds
    if (coords[0] < gridUnit) coords[0] = gridUnit;
    if (coords[1] < gridUnit) coords[1] = gridUnit;
    if (coords[0] > islandWidth-gridUnit-1) coords[0] = islandWidth-gridUnit-1;
    if (coords[1] > islandHeight-gridUnit-1) coords[1] = islandHeight-gridUnit-1;
    
    return coords;
  }
  
  String getStatus(){
    return myStatus;
  }
  
  void lookSomewhereElse(){
    int[] newPosition = jumpRandomDistance(jumpDistance);
    moveTo(newPosition[0], newPosition[1]);
  }
  
  void moveTo(int x, int y){    
    drawPath(myX, myY, x, y);
  
    myX = x;
    myY = y;
   
    observedGroup = new MonkeyGroup(x, y);
    observedGroup.setPathDirection(myDirection); 
  }
  
  int[] jumpRandomDistance(float distance) {
    boolean landFound = false;
    int x = myX, y = myY, i=0;
    int[] newPosition = new int[2];
    float angle = random(1, 360);
  
    while(!landFound) {      
      newPosition = getNewPosition(x, y, angle, distance); 
      MonkeyGroup group = new MonkeyGroup(newPosition[0], newPosition[1]);
      if (!group.isWater() && !group.isEdge()) {        
        landFound = true;
      }
      angle = random(1, 360);  
      i++;
      if (i%360 == 0) {
        distance += distance;
      }
      if (i>3000) {
        println("Timed out");
        break; 
      }
    }  
    
    myDirection = angle;
    
    return newPosition;
  }
  
  float normalizeAngle(float angle){
    // round to nearest angle unit
    angle = round(angle/angleUnit)*angleUnit;
    
    // ensure I am within 1-360 degrees
    if (angle > 360) angle = angle - 360;
    else if (angle < 1) angle = 360 + angle;
    
    return angle;
  }
  
  float nudgeAngle(float angle, float variance) {
    if (random(-1,1) < 0) variance *= -1;
    return normalizeAngle(angle * variance);
  }
  
  void observe(){
    float observationTime = observedGroup.getBrightness();
    float maxR = 40;
    
    for(int i=observationTimeUnit; i<=observationTime; i+=observationTimeUnit) {
      float multiplier = float(i/100);
      drawCircle(myX, myY, round(maxR*multiplier));
    }
       
    changeStatus("exploring");
  }
  
  int[] paddleToLand(){
    return jumpRandomDistance(swimDistance);
  }
  
  void respawn(){
    changeStatus("exploring");
    myDirection = random(1, 360);
    moveTo(startX, startY);
  }
  
  void run(){    
    int[] newPosition = jumpRandomDistance(runDistance);
    moveTo(newPosition[0], newPosition[1]);
  }
  
  void turnAway(){
    float angle = 90;
    if (random(0, 1) < 0.5) angle *= -1;
    myDirection = normalizeAngle(myDirection+angle);
  }
  
}

class VickyTeam
{
  int teamSizeLimit = 40;  
  
  ArrayList<Vicky> team;

  VickyTeam (int x, int y) {    
    team = new ArrayList<Vicky>();
    team.add(new Vicky(x, y));
  }

  void explore() {
    for (int i = team.size()-1; i >= 0; i--) {
      Vicky vicky = team.get(i);      
      vicky.decideWhatToDo();
      if (vicky.getStatus() == "duplicating" && team.size() < teamSizeLimit) {
        Vicky newVicky = vicky.duplicate();
        team.add(newVicky);
      }
    }    
  } 

}

class MonkeyGroup
{
  float bigThreshold = 80;
  float smallThreshold = 50;
  float waterThreshold = 5;
  
  int ourX, ourY;
  color ourColor;
  float ourHue, ourSaturation, ourBrightness;
  
  MonkeyGroup (int x, int y) {    
    ourColor = landUnits[x + y*islandWidth];
    ourHue = hue(ourColor);
    ourSaturation = saturation(ourColor);
    ourBrightness = brightness(ourColor);
    ourX = x;
    ourY = y;
  }
  
  float getBrightness(){
    return ourBrightness;
  }
  
  boolean isBig(){
    return (ourBrightness >= bigThreshold);
  }
  
  boolean isEdge(){
    return (ourX < gridUnit || ourY < gridUnit || ourX > islandWidth-gridUnit-1 || ourY > islandHeight-gridUnit-1);
  }
  
  boolean isSmall(){
    return (ourBrightness <= smallThreshold);
  }
  
  boolean isWater(){
    return (ourBrightness <= waterThreshold);
  }
  
  float observersDirection(){
    return pathDirections[ourX+ourY*islandWidth];
  }
  
  void setPathDirection(float direction){
    if (!wasObserved()) {
      pathDirections[ourX+ourY*islandWidth] = direction;
    }
  }
  
  boolean wasObserved(){
    return (observersDirection() > 0);
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
