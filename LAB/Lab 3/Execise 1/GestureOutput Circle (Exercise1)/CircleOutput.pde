/**
 * Lab 3 - Exercise 1
 * Gesture-Based Regression with Wekinator
 *
 * OUTPUT / VISUALIZATION SKETCH
 *
 * This Processing sketch receives 2 continuous regression outputs
 * from Wekinator and uses them to control a circle:
 *
 * Output 1: circle size
 * Output 2: outline transparency / alpha
 *
 * OSC message address received from Wekinator: /wek/outputs
 * Listening port: 12000
 *
 * Recommended Wekinator setup for this exercise:
 * Inputs: 3  -> x, y, speed
 * Outputs: 2 -> circle size, outline alpha
 * Model type: Regression
 * Algorithm: KNN Regressor, k = 3
 *
 * In Wekinator, set both output ranges from 0.0 to 1.0.
 * This sketch maps those normalized values to useful visual ranges.
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;

// These variables store the raw output values received from Wekinator.
// They are expected to be normalized values between 0.0 and 1.0.
float circleSizeOutput = 0.5;
float outlineAlphaOutput = 0.5;

// These variables store the mapped visual values used for drawing.
float circleSize;
float outlineAlpha;

PFont f;

void setup() {
  size(640, 480, P2D);
  smooth();

  f = createFont("Courier", 16);
  textFont(f);

  // This sketch listens for Wekinator's regression outputs.
  // Wekinator sends output messages to port 12000 by default.
  oscP5 = new OscP5(this, 12000);
}

void draw() {
  background(0);

  // Keep received values inside the expected normalized range.
  circleSizeOutput = constrain(circleSizeOutput, 0, 1);
  outlineAlphaOutput = constrain(outlineAlphaOutput, 0, 1);

  // Map Wekinator's normalized outputs to visual drawing ranges.
  // Output 1 controls the diameter of the circle.
  circleSize = map(circleSizeOutput, 0, 1, 30, 350);

  // Output 2 controls the alpha/transparency of the circle outline.
  outlineAlpha = map(outlineAlphaOutput, 0, 1, 0, 255);

  // Draw the circle in the center of the window.
  noFill();
  stroke(255, outlineAlpha);
  strokeWeight(6);
  ellipse(width / 2, height / 2, circleSize, circleSize);

  // Display debugging information on the screen.
  fill(255);
  noStroke();
  text("Lab 3 - Exercise 1 Output Sketch", 10, 30);
  text("Receiving 2 regression outputs from Wekinator", 10, 55);
  text("OSC address: /wek/outputs", 10, 80);
  text("Listening port: 12000", 10, 105);

  text("Output 1 - circle size raw     = " + nf(circleSizeOutput, 1, 3), 10, 150);
  text("Output 2 - outline alpha raw   = " + nf(outlineAlphaOutput, 1, 3), 10, 175);
  text("Mapped circle size             = " + nf(circleSize, 1, 1), 10, 215);
  text("Mapped outline alpha           = " + nf(outlineAlpha, 1, 1), 10, 240);
}

// This function is called automatically whenever an OSC message is received.
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/wek/outputs")) {
    if (theOscMessage.typetag().length() >= 2) {
      circleSizeOutput = theOscMessage.get(0).floatValue();
      outlineAlphaOutput = theOscMessage.get(1).floatValue();

      println("Received from Wekinator -> size: " + circleSizeOutput
            + " alpha: " + outlineAlphaOutput);
    }
  }
}
