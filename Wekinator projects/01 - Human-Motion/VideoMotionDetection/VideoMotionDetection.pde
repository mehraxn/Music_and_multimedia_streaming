import processing.video.*;
import oscP5.*;
import netP5.*;

Capture cam;
PImage prevFrame;

OscP5 oscP5;
NetAddress wekinator;

// Wekinator
String wekHost = "127.0.0.1";
int wekPort = 6448;
String oscAddress = "/wek/inputs";

// OSC local port
int localPort = 12001;

// motion detection
float threshold = 30;   // color pixel threshold to asses a motion
float motionAmount = 0;

// temporal buffer
int bufferSize = 30;
float[] motionBuffer = new float[bufferSize];

// image mirroring
boolean mirror = true;

void setup() {
  size(960, 722);

  oscP5 = new OscP5(this, localPort);
  wekinator = new NetAddress(wekHost, wekPort);

  String[] cameras = Capture.list();

  if (cameras == null || cameras.length == 0) {
    println("No cam found");
    exit();
  }

  println("Evailable cameras:");
  for (int i = 0; i < cameras.length; i++) {
    println(i + ": " + cameras[i]);
  }

  cam = new Capture(this, cameras[0]);
  cam.start();

  textFont(createFont("Arial", 14));
}

void captureEvent(Capture c) {
  c.read();
}

void draw() {
  background(0);

  cam.loadPixels();

  if (prevFrame == null) {
    prevFrame = cam.get();
    return;
  }

  prevFrame.loadPixels();

  int whiteCount = 0;
  int sampledCount = 0;

  // visual webcam
  pushMatrix();
  if (mirror) {
    translate(width, 0);
    scale(-1, 1);
  }
  image(cam, 0, 0, width, height);
  popMatrix();

  // ompute the difference with the previous frame
  for (int y = 0; y < cam.height; y++) {
    for (int x = 0; x < cam.width; x++) {
      int index = x + y * cam.width;

      color c1 = cam.pixels[index];
      color c2 = prevFrame.pixels[index];

      float b1 = brightness(c1);
      float b2 = brightness(c2);

      float diff = abs(b1 - b2);

      if (diff > threshold) {
        whiteCount++;
      }
      sampledCount++;
    }
  }

  // normalized quantity of movement 0..1 (weaighted by a factor)
  motionAmount = ((float)whiteCount / (float)sampledCount)*4;

  // update temporal buffer
  updateMotionBuffer(motionAmount);
  sendBufferToWekinator();

  // save current frame
  prevFrame = cam.get();

  // GUI
  drawHUD();
  drawBufferPreview();
}

void updateMotionBuffer(float value) {
  for (int i = 0; i < bufferSize - 1; i++) {
    motionBuffer[i] = motionBuffer[i + 1];
  }
  motionBuffer[bufferSize - 1] = value;
}

void sendBufferToWekinator() {
  OscMessage msg = new OscMessage(oscAddress);

  for (int i = 0; i < bufferSize; i++) {
    msg.add(motionBuffer[i]);
  }

  oscP5.send(msg, wekinator);
}

void drawHUD() {
  fill(0, 180);
  noStroke();
  rect(10, 10, 320, 110);

  fill(255);
  text("OSC -> " + wekHost + ":" + wekPort, 20, 35);
  text("Address: " + oscAddress, 20, 55);
  text("Motion amount: " + nf(motionAmount, 1, 4), 20, 75);
  text("Features sent: " + bufferSize, 20, 115);
}

void drawBufferPreview() {
  int gx = 20;
  int gy = height - 120;
  int gw = 300;
  int gh = 80;

  fill(0, 180);
  noStroke();
  rect(gx - 10, gy - 25, gw + 20, gh + 35);

  stroke(255);
  noFill();
  rect(gx, gy, gw, gh);

  noFill();
  stroke(0, 255, 0);
  beginShape();
  for (int i = 0; i < bufferSize; i++) {
    float x = map(i, 0, bufferSize - 1, gx, gx + gw);
    float y = map(motionBuffer[i], 0, 1, gy + gh, gy);
    vertex(x, y);
  }
  endShape();

  fill(255);
  text("Motion buffer (last " + bufferSize + " frames)", gx, gy - 8);
}
