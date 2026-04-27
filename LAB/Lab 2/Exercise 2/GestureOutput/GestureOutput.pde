import oscP5.*;
import netP5.*;

// ============================================================
// Exercise 2 — Corrected Gesture Classification Output Sketch
// Wekinator → /wek/outputs → Processing text label display
// ============================================================
//
// This is the OUTPUT sketch for Exercise 2.
// It receives the predicted gesture class from Wekinator and displays
// the corresponding gesture name on the screen.
//
// Wekinator output settings:
//   Output OSC message: /wek/outputs
//   Output host: 127.0.0.1 or localhost
//   Output port: 12000
//   Number of outputs: 1
//   Output type: Classification
//   Number of classes: 2
//
// Class mapping in this sketch:
//   Class 1 -> Open Hand
//   Class 2 -> Closed Fist
//
// Change class1Gesture and class2Gesture if your gestures are different.
// ============================================================

OscP5 oscP5;

// ----------------------------
// OSC receiving settings
// ----------------------------
int inPort = 12000;
String oscAddress = "/wek/outputs";

// ----------------------------
// Gesture labels
// ----------------------------
String class1Gesture = "Open Hand";
String class2Gesture = "Closed Fist";

// ----------------------------
// Current prediction values
// ----------------------------
int currentClass = 0;
String currentGesture = "Waiting for Wekinator...";
float lastRawValue = 0.0;
int messageCount = 0;
int lastMessageTime = 0;

void setup() {
  size(800, 450);

  // Listen for Wekinator output messages on port 12000
  oscP5 = new OscP5(this, inPort);

  textAlign(CENTER, CENTER);
  textFont(createFont("Arial", 32));

  println("=====================================");
  println("Exercise 2 Gesture Output Sketch");
  println("Listening on port: " + inPort);
  println("Expected OSC address: " + oscAddress);
  println("Class 1: " + class1Gesture);
  println("Class 2: " + class2Gesture);
  println("=====================================");
}

void draw() {
  drawBackground();
  drawMainText();
  drawDebugInfo();
}

// ============================================================
// Background changes according to the current predicted class
// ============================================================

void drawBackground() {
  if (currentClass == 1) {
    background(210, 60, 60);      // Class 1 background
  } else if (currentClass == 2) {
    background(60, 90, 210);      // Class 2 background
  } else {
    background(25);               // Waiting / unknown background
  }
}

// ============================================================
// Main text display
// ============================================================

void drawMainText() {
  fill(255);

  textSize(26);
  text("Received gesture class:", width / 2, 80);

  textSize(64);
  text(currentClass, width / 2, 155);

  textSize(26);
  text("Recognized gesture:", width / 2, 245);

  textSize(56);
  text(currentGesture, width / 2, 320);
}

// ============================================================
// Small debugging information
// ============================================================

void drawDebugInfo() {
  fill(0, 150);
  noStroke();
  rect(20, 20, 260, 100, 8);

  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  text("OSC port: " + inPort, 35, 35);
  text("OSC address: " + oscAddress, 35, 58);
  text("Messages: " + messageCount, 35, 81);
  text("Last raw value: " + nf(lastRawValue, 1, 3), 35, 104);
  textAlign(CENTER, CENTER);

  // Green dot flashes when a message is received
  if (millis() - lastMessageTime < 250) {
    fill(0, 255, 0);
  } else {
    fill(120);
  }
  ellipse(width - 40, 40, 22, 22);
}

// ============================================================
// Receive OSC messages from Wekinator
// ============================================================

void oscEvent(OscMessage msg) {
  // Only use the correct Wekinator output message
  if (!msg.checkAddrPattern(oscAddress)) {
    println("Ignored message: " + msg.addrPattern());
    return;
  }

  // Wekinator classification output should contain one value:
  // 1.0 for Class 1, 2.0 for Class 2, etc.
  if (msg.arguments().length < 1) {
    println("Received /wek/outputs with no values.");
    return;
  }

  lastRawValue = msg.get(0).floatValue();
  currentClass = round(lastRawValue);
  currentGesture = classToGesture(currentClass);

  messageCount++;
  lastMessageTime = millis();

  println("Received: " + lastRawValue + " -> class " + currentClass + " -> " + currentGesture);
}

// ============================================================
// Convert class number to gesture label
// ============================================================

String classToGesture(int c) {
  switch(c) {
    case 1:
      return class1Gesture;
    case 2:
      return class2Gesture;
    default:
      return "Unknown Class";
  }
}

// ============================================================
// Optional reset
// ============================================================

void keyPressed() {
  if (key == 'r' || key == 'R') {
    currentClass = 0;
    currentGesture = "Waiting for Wekinator...";
    lastRawValue = 0.0;
    println("Reset output display.");
  }
}
