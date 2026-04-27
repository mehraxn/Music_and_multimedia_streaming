import processing.video.*;
import oscP5.*;
import netP5.*;

// ============================================================
// Exercise 2 — Gesture Classification Input Sketch
// Webcam → Crop → Downsample → Grayscale/RGB Features → Wekinator
// ============================================================

// ----------------------------
// Camera and OSC objects
// ----------------------------
Capture cam;
OscP5 oscP5;
NetAddress wekinator;

// ----------------------------
// Wekinator OSC settings
// ----------------------------
String wekHost = "127.0.0.1";
int wekPort = 6448;
String oscAddress = "/wek/inputs";

// Local OSC port for this Processing sketch.
// This sketch mainly sends data, so the local port is not very important.
int localPort = 12001;

// ----------------------------
// Feature configuration
// ----------------------------
// The lab asks us to start from a 200×200 center crop.
// Then we can use 200×200, 100×100, or 50×50 as the feature image.

int cropSize = 200;

// Choose one of these values:
// 200, 100, or 50
int featureSize = 50;

// Choose color mode:
// false = grayscale
// true  = RGB
boolean useRGB = false;

// If featureSize = 50 and useRGB = false:
// number of inputs = 50 × 50 = 2500
//
// If featureSize = 50 and useRGB = true:
// number of inputs = 50 × 50 × 3 = 7500
int featureCount;

// ----------------------------
// Images used during processing
// ----------------------------
PImage cropImg;
PImage featureImg;

// Mirror camera preview like a normal webcam mirror
boolean mirrorPreview = true;

// Send features every frame?
boolean sendToWekinator = true;

void setup() {
  size(960, 720);

  // ----------------------------
  // Setup OSC
  // ----------------------------
  oscP5 = new OscP5(this, localPort);
  wekinator = new NetAddress(wekHost, wekPort);

  // ----------------------------
  // Setup camera
  // ----------------------------
  String[] cameras = Capture.list();

  if (cameras == null || cameras.length == 0) {
    println("No camera found.");
    exit();
  }

  println("Available cameras:");
  for (int i = 0; i < cameras.length; i++) {
    println(i + ": " + cameras[i]);
  }

  // Use the first available camera
  cam = new Capture(this, cameras[0]);
  cam.start();

  // ----------------------------
  // Calculate number of features
  // ----------------------------
  if (useRGB) {
    featureCount = featureSize * featureSize * 3;
  } else {
    featureCount = featureSize * featureSize;
  }

  println("=====================================");
  println("Exercise 2 Input Sketch Started");
  println("Crop size: " + cropSize + " x " + cropSize);
  println("Feature image size: " + featureSize + " x " + featureSize);
  println("Color mode: " + (useRGB ? "RGB" : "Grayscale"));
  println("Number of Wekinator inputs: " + featureCount);
  println("OSC address: " + oscAddress);
  println("Sending to: " + wekHost + ":" + wekPort);
  println("=====================================");

  textFont(createFont("Arial", 16));
}

void captureEvent(Capture c) {
  c.read();
}

void draw() {
  background(0);

  if (cam.width == 0 || cam.height == 0) {
    return;
  }

  // Make sure camera pixels are available
  cam.loadPixels();

  // ----------------------------
  // 1. Crop the center 200×200 region
  // ----------------------------
  cropImg = getCenterCrop(cam, cropSize);

  // ----------------------------
  // 2. Downsample to selected resolution
  // ----------------------------
  featureImg = cropImg.copy();
  featureImg.resize(featureSize, featureSize);
  featureImg.loadPixels();

  // ----------------------------
  // 3. Send pixel features to Wekinator
  // ----------------------------
  if (sendToWekinator) {
    sendImageFeaturesToWekinator(featureImg);
  }

  // ----------------------------
  // 4. Draw interface
  // ----------------------------
  drawCameraPreview();
  drawCropPreview();
  drawFeaturePreview();
  drawHUD();
}

// ============================================================
// Create a center crop from the webcam image
// ============================================================

PImage getCenterCrop(PImage source, int size) {
  int startX = (source.width - size) / 2;
  int startY = (source.height - size) / 2;

  // Safety limits, in case the camera image is smaller than expected
  startX = constrain(startX, 0, source.width - size);
  startY = constrain(startY, 0, source.height - size);

  return source.get(startX, startY, size, size);
}

// ============================================================
// Send grayscale or RGB pixel features to Wekinator
// ============================================================

void sendImageFeaturesToWekinator(PImage img) {
  OscMessage msg = new OscMessage(oscAddress);

  img.loadPixels();

  for (int i = 0; i < img.pixels.length; i++) {
    color c = img.pixels[i];

    if (useRGB) {
      // RGB mode sends 3 values per pixel:
      // red, green, blue
      //
      // Values are normalized from 0..255 to 0..1
      msg.add(red(c) / 255.0);
      msg.add(green(c) / 255.0);
      msg.add(blue(c) / 255.0);
    } else {
      // Grayscale mode sends 1 value per pixel.
      // This converts RGB to brightness.
      //
      // Values are normalized from 0..255 to 0..1
      float gray = brightness(c) / 255.0;
      msg.add(gray);
    }
  }

  oscP5.send(msg, wekinator);
}

// ============================================================
// Draw full camera preview
// ============================================================

void drawCameraPreview() {
  pushMatrix();

  if (mirrorPreview) {
    translate(width, 0);
    scale(-1, 1);
  }

  image(cam, 0, 0, width, height);

  popMatrix();

  // Draw center crop rectangle on preview
  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);

  int rectX = (width - cropSize) / 2;
  int rectY = (height - cropSize) / 2;

  rect(rectX, rectY, cropSize, cropSize);
}

// ============================================================
// Draw the 200×200 cropped image
// ============================================================

void drawCropPreview() {
  int previewSize = 160;
  int x = width - previewSize - 20;
  int y = 20;

  fill(0, 180);
  noStroke();
  rect(x - 10, y - 10, previewSize + 20, previewSize + 45);

  image(cropImg, x, y, previewSize, previewSize);

  fill(255);
  textSize(14);
  text("Center crop: 200 x 200", x, y + previewSize + 25);
}

// ============================================================
// Draw the downsampled feature image
// ============================================================

void drawFeaturePreview() {
  int previewSize = 160;
  int x = width - previewSize - 20;
  int y = 240;

  fill(0, 180);
  noStroke();
  rect(x - 10, y - 10, previewSize + 20, previewSize + 65);

  if (useRGB) {
    image(featureImg, x, y, previewSize, previewSize);
  } else {
    // Display grayscale preview manually
    PImage grayPreview = createImage(featureImg.width, featureImg.height, RGB);
    featureImg.loadPixels();
    grayPreview.loadPixels();

    for (int i = 0; i < featureImg.pixels.length; i++) {
      float gray = brightness(featureImg.pixels[i]);
      grayPreview.pixels[i] = color(gray);
    }

    grayPreview.updatePixels();
    image(grayPreview, x, y, previewSize, previewSize);
  }

  fill(255);
  textSize(14);
  text("Feature image: " + featureSize + " x " + featureSize, x, y + previewSize + 25);
  text("Mode: " + (useRGB ? "RGB" : "Grayscale"), x, y + previewSize + 45);
}

// ============================================================
// Draw information panel
// ============================================================

void drawHUD() {
  fill(0, 190);
  noStroke();
  rect(20, 20, 390, 170);

  fill(255);
  textSize(16);
  text("Exercise 2 — Gesture Input Sketch", 35, 50);

  textSize(14);
  text("OSC address: " + oscAddress, 35, 80);
  text("Sending to Wekinator: " + wekHost + ":" + wekPort, 35, 105);
  text("Crop: " + cropSize + " x " + cropSize, 35, 130);
  text("Feature size: " + featureSize + " x " + featureSize, 35, 155);
  text("Color mode: " + (useRGB ? "RGB" : "Grayscale"), 35, 180);
  text("Wekinator inputs: " + featureCount, 35, 205);

  fill(sendToWekinator ? color(0, 255, 0) : color(255, 0, 0));
  text("Sending: " + (sendToWekinator ? "ON" : "OFF"), 35, 230);

  fill(255);
  text("Press SPACE to start/stop sending", 35, height - 35);
}

// ============================================================
// Keyboard control
// ============================================================

void keyPressed() {
  if (key == ' ') {
    sendToWekinator = !sendToWekinator;
    println("Sending to Wekinator: " + sendToWekinator);
  }
}
