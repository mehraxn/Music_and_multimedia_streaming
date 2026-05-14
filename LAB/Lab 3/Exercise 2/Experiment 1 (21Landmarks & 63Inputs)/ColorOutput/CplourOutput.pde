import oscP5.*;
import netP5.*;

OscP5 oscP5;

// Raw Wekinator outputs. Expected range: 0.0 to 1.0.
float redOutput = 0.0;
float greenOutput = 0.0;
float blueOutput = 0.0;

// Mapped Processing color values. Range: 0 to 255.
float redValue;
float greenValue;
float blueValue;

PFont f;

void setup() {
  size(640, 480, P2D);
  smooth();

  f = createFont("Courier", 16);
  textFont(f);

  // Listen for Wekinator's output OSC messages.
  // Wekinator should send /wek/outputs to port 12000.
  oscP5 = new OscP5(this, 12000);
}

void draw() {
  background(0);

  // Keep raw Wekinator outputs in the expected normalized range.
  redOutput = constrain(redOutput, 0, 1);
  greenOutput = constrain(greenOutput, 0, 1);
  blueOutput = constrain(blueOutput, 0, 1);

  // Map normalized Wekinator outputs to RGB color values.
  redValue = map(redOutput, 0, 1, 0, 255);
  greenValue = map(greenOutput, 0, 1, 0, 255);
  blueValue = map(blueOutput, 0, 1, 0, 255);

  // Draw the color rectangle controlled by Wekinator.
  noStroke();
  fill(redValue, greenValue, blueValue);
  rectMode(CENTER);
  rect(width / 2, height / 2 + 45, 360, 220, 20);

  // Add a white border to make the rectangle visible even for dark colors.
  noFill();
  stroke(255);
  strokeWeight(3);
  rect(width / 2, height / 2 + 45, 360, 220, 20);

  // Debug information.
  fill(255);
  noStroke();
  text("Lab 3 - Exercise 2 Output Sketch", 10, 30);
  text("Receiving 3 regression outputs from Wekinator", 10, 55);
  text("OSC address: /wek/outputs", 10, 80);
  text("Listening port: 12000", 10, 105);

  text("Output 1 - Red raw     = " + nf(redOutput, 1, 3), 10, 150);
  text("Output 2 - Green raw   = " + nf(greenOutput, 1, 3), 10, 175);
  text("Output 3 - Blue raw    = " + nf(blueOutput, 1, 3), 10, 200);

  text("Mapped R = " + nf(redValue, 1, 1), 10, 245);
  text("Mapped G = " + nf(greenValue, 1, 1), 10, 270);
  text("Mapped B = " + nf(blueValue, 1, 1), 10, 295);
}

// This function is called automatically when an OSC message is received.
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/wek/outputs")) {
    if (theOscMessage.typetag().length() >= 3) {
      redOutput = theOscMessage.get(0).floatValue();
      greenOutput = theOscMessage.get(1).floatValue();
      blueOutput = theOscMessage.get(2).floatValue();

      println("Received from Wekinator -> R: " + redOutput
            + " G: " + greenOutput
            + " B: " + blueOutput);
    }
  }
}
