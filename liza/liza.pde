/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Liza (http://youdrawingyou.com/sketches/liza)
 */

import processing.pdf.*;

String imgSrc = "img/liza.jpg";
String outputFile = "output/liza.png";
String outputPDF = "output/liza.pdf";
boolean savePDF = false;

int shelfWidth = 675;
int shelfHeight = 900;
int gridUnit = 20;
int spaceIterator = 0;
float angleUnit = 1;
float angleVariance = 1;

String hiresFile = "output/liza-hires.png";
int hiresFactor = 8;
PGraphics hires;
boolean saveHires = false;

int fr = 120;
String outputMovieFile = "output/frames/frames-#####.png";
int frameCaptureEvery = 30;
int frameIterator = 0;
boolean captureFrames = false;
FrameSaver fs;

PGraphics pg;
PImage shelf;
LizaTeam theLizaTeam;
color[] spaces;
int[] visitedSpaces;

void setup() {
  
  // set the stage
  size(shelfWidth, shelfHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);
  pg = createGraphics(shelfWidth, shelfHeight);
  
  // load shelf from image source
  shelf = loadImage(imgSrc);
  pg.image(shelf, 0, 0);
  pg.loadPixels();
  spaces = pg.pixels;  

  // create a team of Lizas 
  theLizaTeam = new LizaTeam();
  visitedSpaces = new int[shelfWidth*shelfHeight];
  
  // output methods
  if (captureFrames) fs = new FrameSaver();  
  if (savePDF) beginRecord(PDF, outputPDF);
  if (saveHires) {
    hires = createGraphics(shelfWidth*hiresFactor, shelfHeight*hiresFactor);
    beginRecord(hires);
  }
}

void draw(){
  // just lines
  noFill();
  strokeWeight(0.1);
  
  if (saveHires) {
    hires.scale(hiresFactor); 
  }
  
  if(captureFrames && !fs.running) {
    fs.start();
  }
  
  theLizaTeam.build();
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
  if (saveHires) {
    hires.save(hiresFile);
    endRecord();
  }
  exit();
}

float halton(int hIndex, int hBase) {    
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

class Liza
{
  int baseX = 2, baseY = 3;
  float myX, myY;
  float[] xAngleRange = {125.0, 205.0};  
  float[] strokeBrightnessRange = {40, 40};
  
  Liza () {}
  
  void build(){
    setNextPosition();
    ShelfSpace space = new ShelfSpace(myX, myY);
    
    if (space.needsSupport()) {
      buildSupport(1.0);
      buildSupport(-1.0);
    }    
  }
  
  void buildSupport(float xDirection) {
    float x = myX, y = myY;
    int yMax = shelfHeight-gridUnit-1,
        xMax = shelfWidth-gridUnit-1,
        xMin = gridUnit;
    float multiplier = 1, multiplierStep = 0.1;    
    
    while(y < yMax && x < xMax &&  x> xMin) {
      float angleMultiplier = 1.0*y/shelfHeight,
            angle = (xAngleRange[1]-xAngleRange[0])*angleMultiplier+xAngleRange[0];
      angle = nudgeAngle(angle*xDirection, angleVariance);
      float[] newPosition = getNewPosition(x, y, angle, gridUnit);
      drawPath(x, y, newPosition[0], newPosition[1], multiplier);
      x = newPosition[0];
      y = newPosition[1];
      multiplier -= multiplierStep;
      if (multiplier<0) multiplier = 0;
    }
  }
  
  void drawPath(float x1, float y1, float x2, float y2, float multiplier) {
    //color spaceColor = spaces[x1 + y1*shelfWidth];
    //float spaceBrightness = brightness(spaceColor);
    float strokeBrightness = (strokeBrightnessRange[1]-strokeBrightnessRange[0])*multiplier + strokeBrightnessRange[0];
    
    stroke(40, 20, 20, strokeBrightness);
    
    line(x1, y1, x2, y2);
    
    if (saveHires) {
      hires.stroke(40, 20, 20, strokeBrightness);
      hires.line(x1, y1, x2, y2);
    }
  }
  
  float[] getNewPosition(float x, float y, float angle, float distance){
    float[] coords = new float[2];
    float r = radians(angle);
    
    coords[0] = x + distance*cos(r);
    coords[1] = y + distance*sin(r);
    
    //println(coords[0], coords[1]);
    
    // ensure is in bounds
    if (coords[0] < gridUnit) coords[0] = gridUnit;
    if (coords[1] < gridUnit) coords[1] = gridUnit;
    if (coords[0] > shelfWidth-gridUnit-1) coords[0] = shelfWidth-gridUnit-1;
    if (coords[1] > shelfHeight-gridUnit-1) coords[1] = shelfHeight-gridUnit-1;
    
    return coords;
  }
  
  float normalizeAngle(float angle){
    // round to nearest angle unit
    angle = round(angle/angleUnit)*angleUnit;
    
    // translate 90 degrees
    angle = angle-90;
    
    // ensure I am within 1-360 degrees
    if (angle > 360) angle = angle - 360;
    else if (angle < 1) angle = 360 + angle; 
    
    return angle;
  }
  
  float nudgeAngle(float angle, float variance) {
    if (random(-1,1) < 0) variance *= -1;
    return normalizeAngle(angle + variance);
  }
  
  void setNextPosition(){
    float hx = halton(spaceIterator, baseX);
    float hy = halton(spaceIterator, baseY);
    
    myX = hx*(shelfWidth-gridUnit*2)+gridUnit;
    myY = hy*(shelfHeight-gridUnit*2)+gridUnit;
    
    spaceIterator++;
  }

}

class LizaTeam
{
  int teamSizeLimit = 10;  
  
  ArrayList<Liza> team;

  LizaTeam () {
    team = new ArrayList<Liza>();
    for(int i=0; i<teamSizeLimit; i++) {      
      team.add(new Liza());
    }    
  }

  void build() {
    for (int i = team.size()-1; i >= 0; i--) {
      Liza liza = team.get(i);
      liza.build();
    }    
  } 

}

class ShelfSpace 
{
  float spaceBrightnessThreshold = 50;
  
  float myX, myY;
  
  ShelfSpace(float x, float y) {
    myX = x;
    myY = y;
  }
  
  boolean needsSupport(){
    boolean answer = false;
    color spaceColor = spaces[int(myX) + int(myY)*shelfWidth];
    float spaceBrightness = brightness(spaceColor);
    if (spaceBrightness<spaceBrightnessThreshold) {
      answer = true;
    }
    return answer;
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
