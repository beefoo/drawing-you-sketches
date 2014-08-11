/*
 * You Drawing You (http://youdrawingyou.com)
 * Author: Brian Foo (http://brianfoo.com)
 * This drawing algorithm is based on my friend Rahul
 */

String imgSrc = "img/test.jpg";
String outputFile = "output/test.png";
int storeWidth = 800;
int storeHeight = 800;
int fr = 120;
int startX = storeWidth / 2;
int startY = storeHeight / 2;
int gridUnit = 2;

PImage store;
RahulGang theRahulGang;
color[] bins;

void setup() {
  
  // set the stage
  size(storeWidth, storeHeight);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  frameRate(fr);  
  
  // load store from image source
  store = loadImage(imgSrc);
  image(store, 0, 0);
  loadPixels();
  
  // overlay rectangle
  noStroke();
  background(0, 0, 100);
  rect(0, 0, storeWidth, storeHeight);
  noFill();
  
  // set the bins and create a Rahul Gang  
  bins = pixels;
  theRahulGang = new RahulGang(startX, startY);

}

void draw(){
  theRahulGang.loot();
  // exit();
}

void mousePressed() {
  save(outputFile);
  exit();
}

class Rahul
{
  int capacity = 2000;
  float strokeHue = 40;
  float maxStrokeBrightness = 80;
  float minStrokeSaturation = 40;
  float maxStrokeSaturation = 100;
  
  int myX, myY, myStuffCount;
  boolean iAmDead;
  Bin myBin;
  
  Rahul (int x, int y, int stuffCount) {
    myX = x;
    myY = y;
    myStuffCount = stuffCount;
    iAmDead = false;
  }
  
  void drawPath(int x1, int y1, int x2, int y2, int iterator) {
    float multiplier = min(float(myStuffCount)/capacity, 1.0);
    float myStrokeHue = strokeHue;
    float myStrokeSaturation = min(minStrokeSaturation + iterator, maxStrokeSaturation);
    float myStrokeBrightness = maxStrokeBrightness - multiplier * maxStrokeBrightness;
    float myStrokeWeight = multiplier;
    
    if (iterator > 10) {
      myStrokeHue = 0;
    }
    
    strokeWeight(myStrokeWeight);
    stroke(myStrokeHue, myStrokeSaturation, myStrokeBrightness);
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
    // make a new Rahul with half my stuff
    Rahul newRahul = new Rahul(myX, myY, floor(myStuffCount/2));
    
    // halve my own stuff
    myStuffCount = ceil(myStuffCount/2);
    
    return newRahul;
  }
  
  // retrieve brightest bin around me
  Bin getBrightestBinAround(int x, int y){    
    int[] delta = {0, -1};
    int dx = 0;
    int dy = 0;
    
    // initialize brightest bin to the center one
    ArrayList<Bin> brightestBins = new ArrayList<Bin>();
    Bin brightestBin = new Bin(x+dx*gridUnit, y+dy*gridUnit);
    
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
     
      // check if it is the brightest bin and in bounds      
      Bin bin = new Bin(x+dx*gridUnit, y+dy*gridUnit);
      if (bin.getBrightness() > brightestBin.getBrightness() && bin.isInBounds()) {
        brightestBins = new ArrayList<Bin>();
        brightestBin = bin;
      } 
      if (bin.getBrightness() >= brightestBin.getBrightness() && bin.isInBounds()) {
        brightestBins.add(bin);
      }      
    }
    
    // choose a random bright bin
    if (brightestBins.size() > 0) {
      int rand = round(random(0, brightestBins.size()-1));
      brightestBin = brightestBins.get(rand);
    }
    
    return brightestBin;
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
    myBin = getBrightestBinAround(myX, myY);    
    boolean foundStuff = (!myBin.isEmpty() && !myBin.positionEquals(myX, myY));
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
    
    // draw path
    drawPath(prevX, prevY, myX, myY, iterator);
    
    return foundStuff;       
  }
  
  void moveRandomly(){
    // randomly choose a direction
    int xDirection = round(random(-1, 1));
    int yDirection = round(random(-1, 1));
    
    // move in that direction
    myX += xDirection * gridUnit;
    myY += yDirection * gridUnit;

    // make sure i am not at the edge
    if (myX < gridUnit) myX = gridUnit;
    if (myY < gridUnit) myY = gridUnit;
    if (myX > storeWidth-gridUnit-1) myX = storeWidth-gridUnit-1;
    if (myY > storeHeight-gridUnit-1) myY = storeHeight-gridUnit-1;  
  }
  
  void stealStuff() {
    float stuffAmount = myBin.take();    
    myStuffCount += round(stuffAmount);
  }
}

class RahulGang
{
  int gangSizeLimit = 40;
  float chanceToDuplicate = 0.8;
  
  ArrayList<Rahul> gang;

  RahulGang (int x, int y) {    
    gang = new ArrayList<Rahul>();
    gang.add(new Rahul(x, y, 0));
  }
  
  void giveJudgementTo(Rahul rahul) {
    float judgement = random(0, 1);
    
    if (judgement < chanceToDuplicate && gang.size() < gangSizeLimit) {
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
  
  boolean positionEquals(int x, int y) {
    return (x==myX && y==myY);
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
  
}
