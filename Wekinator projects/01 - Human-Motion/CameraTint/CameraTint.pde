import processing.video.*;
import oscP5.*;
import netP5.*;

Capture cam;
OscP5 oscP5;

// States 
final int STILL = 1;
final int FLOW = 2;
final int CHAOS = 3;

int currentState = STILL;

// color smoothuing
color currentTint;
color targetTint;

// image mirroring
boolean mirror = true;

void setup() {
  size(640, 480);

  // Camera
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("No cam found");
    exit();
  }
  
  println("Evailable cameras:");
  for (int i = 0; i < cameras.length; i++) {
    println(i + ": " + cameras[i]);
  }

  cam = new Capture(this, cameras[0]);
  cam.start();

  // OSC
  oscP5 = new OscP5(this, 12000);

  currentTint = color(255);
  targetTint = color(255);
}

void draw() {
  background(0);

  if (cam.available()) {
    cam.read();
  }
 

  // Update tint state
  updateTintByState();

  // smooth color transition
  currentTint = lerpColor(currentTint, targetTint, 0.1);

  // tint
  tint(currentTint);
    // visual webcam
  pushMatrix();
  if (mirror) {
    translate(width, 0);
    scale(-1, 1);
  }
  image(cam, 0, 0, width, height);
  popMatrix();
  
  fill(red(currentTint), green(currentTint), blue(currentTint), 80);
  rect(0, 0, width, height);
  
  noTint();

  // debug
  fill(255);
  textSize(16);
  text("State: " + stateName(currentState), 20, 30);
}

// ==============================
// MAPPING STATE → COLOUR
// ==============================

void updateTintByState() {
  if (currentState == STILL) {
    targetTint = color(90); // blu
  } 
  else if (currentState == FLOW) {
    targetTint = color(255); // grigio
  } 
  else if (currentState == CHAOS) {
    targetTint = color(255, 80, 80); // rosso
  }
}

String stateName(int s) {
  if (s == STILL) return "STILL";
  if (s == FLOW) return "FLOW";
  if (s == CHAOS) return "CHAOS";
  return "UNKNOWN";
}

// ==============================
// OSC FROM WEKINATOR
// ==============================

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs")) {

    // Caso 1: una sola uscita (classe)
    if (msg.typetag().length() == 1) {
      int newState = round(msg.get(0).floatValue());
      currentState = newState;
    }

    println("State: " + currentState);
  }
}
