//import libraries
import processing.serial.*; //to connect arduino serial data to processing
import processing.video.*; //to connect to the webcam

Serial myPort; //variable to read the serial data from port
Capture cam; //variable to read webcam data

//variables to read gyroscope values
float xraw;
float yraw;
float zraw;
float xnorm;
float ynorm;
float znorm;

//variables to average rapid gyroscope values
float avg_xnorm;
float avg_ynorm;
float avg_znorm;

//variables for default movement tracking circle
int d = 50; //diameter of circle
float[] xP = new float[50]; //array for x positions
float[] yP = new float[50]; //array for y positions
Particle [] pickles = new Particle [100]; //multiple circles from particle class

///////VISUALISATION VARIABLES///////

//boom visualisation
int boomWidth = 500;
int boomHeight = 500;

//whoosh visualisation
float[] whoosh_xP = new float[50];
float[] whoosh_yP = new float[50];
float num = 20;
float step, sz, offSet, theta, angle;

//tickticktick visualisation
int[] colors = {#0CE872, #08FF00, #00E031, #00E0A0, #0CF77A, #0BD437, #09EB00, #4ED40B, #A0F50A};
int tick_size = 20;

//beat visualisation
int beat_circleSize;
int beat_circleX;
int beat_circleY;
int beat_shade;

//cah visualisation
int cah_x;
int cah_y;
float outsideRadius = 150;
float insideRadius = 100;

void setup() {
  size(1920, 1080); //canvas size
  frameRate(150);
  smooth();
  String[] cameras = Capture.list(); //array to hold camera data

  //start camera
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i =0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, 1920, 1080, cameras[0]);
    cam.start();
  }
  //open the serial port
    myPort = new Serial(this, Serial.list()[0], 115200);
    
    //set x and y positions of gyroscope circle tracker
    for (int i = 0; i < xP.length; i ++ ) {
    xP[i] = 0;
    yP[i] = 0;
  }

//setup circles
  for (int i=0; i<pickles.length; i++) {
    pickles [i] = new Particle ();
  }
  
  //whoosh visualisation setup
  step = 5;
  
  //cah visualisation setup
  cah_x = 1600;
  cah_y = 750;
  
 //beats visualisation setup
  beat_circleSize=500;
  beat_circleX=1600;
  beat_circleY=250;
  beat_shade=(0);
}

void draw() {
  //draw camera data
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0);

  //get gyroscope values from serial port
  while (myPort.available() > 0) {
    String inBuffer = myPort.readString();
    if (inBuffer != null) {
      println("data: ", inBuffer);
      String[] list = split(inBuffer, ','); //split the string into a list
      //store the axes
      if (list.length == 6) {
        xraw = float (list[0]);
        yraw = float (list[1]);
        zraw = float (list[2]);
        xnorm = float (list[3]);
        ynorm = float (list[4]);
        znorm = float (list[5]);

        //average the norm values
        avg_xnorm = (float(list[3]) * 0.95 + float(list[3]) *0.05)*-5;
        avg_ynorm = (float(list[4]) * 0.95 + float(list[4]) *0.05)*-5;
        avg_znorm = (float(list[5]) * 0.95 + float(list[5]) *0.05)*-5;

        /*modify values to increase range,
         negative values are changed into positive as this will
         help with collision detection when the circle uses the norm values
         as coordinates to move around*/
        xnorm = xnorm * 5;
        if (xnorm < 0) {
          xnorm = xnorm * -1;
        }
        ynorm = ynorm * 5;
        if (ynorm < 0) {
          ynorm = ynorm * -1;
        }
        znorm = znorm * 5;
        if (znorm < 0) {
          znorm = znorm * -1;
        }
      }
    }
  }

  /////display visualisations according to the value ranges//////

  //gyroscope tracker
  if ((avg_xnorm < 1000) && (avg_ynorm < 1000) && (avg_znorm < 1000)) {
    delay(5);
    image(cam, 0, 0);
    gyr();
  }

  //boom visualisation
  if (avg_ynorm > 1000) {
    image(cam, 0, 0);
    boom();
  }

  //whoosh visualisation
  if (avg_znorm > 1000) {
    image(cam, 0, 0);
    whoosh();
  }

  //tickticktick visualisation
  if (avg_xnorm > 1000) {
    image(cam, 0, 0);
    ticktick();
  }

  //beat visualisation
  if ((avg_xnorm > 1000) && (avg_ynorm > 1000)) {
    image(cam, 0, 0);
    beat();
  }

  //cah visualisation
  if ((avg_xnorm > 1000) && (avg_znorm > 1000)) {
    image(cam, 0, 0);
    cah();
  }
}

//circle to track gyroscope movement
void gyr() {
  for (int i = 0; i < xP.length-1; i++) {
    xP[i] = xP[i+1];
    yP[i] = yP[i+1];
  }
  xP[xP.length-1] = xnorm;
  yP[xP.length-1] = ynorm;
  
  for (int i = 0; i < xP.length; i ++ ) {
    strokeWeight(5);
    stroke(#39FF14);
    noFill();
    ellipse(xP[i], yP[i], i, i);
  }
  for (int i=0; i<pickles.length; i++) {
    pickles[i].update();
  }
  for (int r=0; r<pickles.length; r++) {
    pickles[r].x=xnorm;
    pickles[r].y=ynorm;
  }
}


//generates moving circles
class Particle {

  float x;
  float y;

  float velX;
  float velY;


  Particle () {
    x = xraw;
    y = zraw;

    velX = random (-10, 10);
    velY = random (-10, 10);
  }

  void update () {
    x+=velX;
    y+=velY;
    strokeWeight(5);
    stroke(#39FF14);
    noFill();
    ellipse(x, y, 50, 50);
  }
}

///////// VISUALISATION FUNCTIONS //////////////

//boom
void boom() {
  stroke(#FF0000);
  fill(#FF5F1F);
  beginShape();
  vertex(boomWidth/2-90, boomHeight/2-120);
  vertex(boomWidth/2-40, boomHeight/2-40);
  vertex(boomWidth/2+10, boomHeight/2-120);
  vertex(boomWidth/2+30, boomHeight/2-40);
  vertex(boomWidth/2+110, boomHeight/2-90);
  vertex(boomWidth/2+60, boomHeight/2-10);
  vertex(boomWidth/2+130, boomHeight/2+30);
  vertex(boomWidth/2+50, boomHeight/2+20);
  vertex(boomWidth/2+100, boomHeight/2+100);
  vertex(boomWidth/2+10, boomHeight/2+30);
  vertex(boomWidth/2-10, boomHeight/2+110);
  vertex(boomWidth/2-40, boomHeight/2+30);
  vertex(boomWidth/2-110, boomHeight/2+90);
  vertex(boomWidth/2-80, boomHeight/2+10);
  vertex(boomWidth/2-170, boomHeight/2-20);
  vertex(boomWidth/2-75, boomHeight/2-30);
  endShape(CLOSE);
}

//whoosh
void whoosh() {
  int m = 3;
  strokeWeight(10);
  stroke(#11FFEE);
  noFill();
  arc(960, 500, 100*m, 100*m, PI, TWO_PI);
  arc(960, 500, 75*m, 75*m, PI, TWO_PI-(PI/6));
  arc(960, 500, 50*m, 50*m, PI, TWO_PI-(PI/4));
  arc(960, 500, 25*m, 25*m, PI, TWO_PI-(PI/2));
  colorMode(RGB);
  resetMatrix();
}

//tickticktick
void ticktick() {
  for (int i=0; i<colors.length; i++) {
    fill(colors[i]);
    noStroke();
    rect(150+(20*i), 750-(8*i), tick_size, tick_size);
    rect(150+(20*i), 750+(8*i), tick_size, tick_size);
    rect(150+(20*i), 880-(8*i), tick_size, tick_size);
  }
}

//beat animation
void beat() {
  while (beat_circleSize>0) {
    fill(beat_shade);
    ellipse(beat_circleX, beat_circleY, beat_circleSize, beat_circleSize);
    beat_circleSize-=25;
    beat_shade+=20;
  }
}

//cah
void cah() {
  strokeWeight(5);
  stroke(#39FF14);
  fill(0);
  int numPoints = int(map(300, 0, 300, 6, 60));
  float angle = 0;
  float angleStep = 180.0/numPoints;
    
  beginShape(TRIANGLE_STRIP); 
  for (int i = 0; i <= numPoints; i++) {
    float px = cah_x + cos(radians(angle)) * outsideRadius;
    float py = cah_y + sin(radians(angle)) * outsideRadius;
    angle += angleStep;
    vertex(px, py);
    px = cah_x + cos(radians(angle)) * insideRadius;
    py = cah_y + sin(radians(angle)) * insideRadius;
    vertex(px, py); 
    angle += angleStep;
  }
  endShape();
}
