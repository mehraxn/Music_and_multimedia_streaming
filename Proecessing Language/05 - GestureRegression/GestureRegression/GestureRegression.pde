import processing.video.*;
import oscP5.*;
import netP5.*;

Capture cam;
OscP5 oscP5;
NetAddress wekinator;

// final scropped dimension (downscaling)
int smallW = 50;
int smallH = 50;

// crop dimension (central area)
int cropW = 200;
int cropH = 200;

PImage mirroredCam;
PImage cropImg;
PImage smallImg;

// OSC
String oscAddress = "/wek/inputs";
String host = "127.0.0.1";
int outPort = 6448;
int inPort  = 12001;

void setup() {
  size(960, 722);

  oscP5 = new OscP5(this, inPort);
  wekinator = new NetAddress(host, outPort);

  String[] cameras = Capture.list();

  if (cameras == null || cameras.length == 0) {
    println("Nessuna camera trovata");
    exit();
  }

  cam = new Capture(this, cameras[0]);
  cam.start();

  mirroredCam = createImage(640, 480, RGB);
  cropImg = createImage(cropW, cropH, RGB);
  smallImg = createImage(smallW, smallH, RGB);

  textFont(createFont("Arial", 14));
}

void captureEvent(Capture c) {
  c.read();
}

void draw() {
  background(0);

  if (cam.width == 0) return;

  // --- visual camera ---
  mirroredCam = mirrorImage(cam);
  image(mirroredCam, 0, 0, width, height);

  // --- extract central crop ---
  int cx = cam.width / 2;
  int cy = cam.height / 2;

  int x0 = cx - cropW / 2;
  int y0 = cy - cropH / 2;

  cropImg.copy(mirroredCam, x0, y0, cropW, cropH, 0, 0, cropW, cropH);
  image(cropImg, 20, 20, cropW, cropH);

  // --- downscale ---
  smallImg.copy(cropImg, 0, 0, cropW, cropH, 0, 0, smallW, smallH);
  smallImg.loadPixels();

  // --- send OSC ---
  sendGrayscalePixels();

  // --- preview downscaled ---
  drawSmallPreview();

  fill(255);
  text("Features: " + (smallW * smallH), 20, height - 20);
}

void sendGrayscalePixels() {
  OscMessage msg = new OscMessage(oscAddress);

  for (int i = 0; i < smallImg.pixels.length; i++) {
    color c = smallImg.pixels[i];

    // grayscale
    float gray = (red(c) + green(c) + blue(c)) / 3.0;

    // nornalization 0–1
    float normalized = gray / 255.0;

    msg.add(normalized);
  }

  oscP5.send(msg, wekinator);
}

void drawSmallPreview() {
  
  int py = 20;
  int cell = 10;
  int px = width/2-(smallW*cell)/2;

  noStroke();
  for (int y = 0; y < smallH; y++) {
    for (int x = 0; x < smallW; x++) {
      int i = y * smallW + x;
      fill(smallImg.pixels[i]);
      rect(px + x * cell, py + y * cell, cell, cell);
    }
  }

  stroke(255);
  noFill();
  rect(px, py, smallW * cell, smallH * cell);

  fill(255);
  text("Downscaled", px, py + smallH * cell + 20);
}


PImage mirrorImage(PImage src) {
  PImage dst = createImage(src.width, src.height, RGB);

  src.loadPixels();
  dst.loadPixels();

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      int srcIndex = y * src.width + x;
      int dstIndex = y * src.width + (src.width - 1 - x);
      dst.pixels[dstIndex] = src.pixels[srcIndex];
    }
  }

  dst.updatePixels();
  return dst;
}
