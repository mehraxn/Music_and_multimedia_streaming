/**
 * Lab 3 - Exercise 1
 * Gesture-Based Regression with Wekinator
 *
 * INPUT SKETCH
 * This Processing sketch captures mouse gesture data and sends
 * 3 normalized input features to Wekinator:
 *
 * Input 1: normalized horizontal position x       -> 0.0 to 1.0
 * Input 2: normalized vertical position y         -> 0.0 to 1.0
 * Input 3: normalized mouse movement speed        -> 0.0 to 1.0
 *
 * OSC message address: /wek/inputs
 * Destination port: 6448
 *
 * Wekinator setup for this exercise:
 * Inputs: 3
 * Outputs: 2
 * Model: KNN Regressor, k = 3
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress dest;

PFont f;

float xNorm;
float yNorm;
float speedNorm;

// This value defines what we consider a "fast" mouse movement.
// A speed of 50 pixels per frame or more becomes 1.0.
// Slower speeds are scaled between 0.0 and 1.0.
float maxSpeed = 50.0;

void setup() {
  size(640, 480, P2D);
  smooth();

  f = createFont("Courier", 16);
  textFont(f);

  // This sketch sends data to Wekinator on port 6448.
  // The local receiving port 9000 is not important here,
  // but oscP5 still needs a port to initialize.
  oscP5 = new OscP5(this, 9000);
  dest = new NetAddress("127.0.0.1", 6448);
}

void draw() {
  background(0);

  // 1. Normalize mouse x position between 0 and 1
  xNorm = mouseX / (float) width;
  xNorm = constrain(xNorm, 0, 1);

  // 2. Normalize mouse y position between 0 and 1
  yNorm = mouseY / (float) height;
  yNorm = constrain(yNorm, 0, 1);

  // 3. Calculate mouse movement speed in pixels per frame
  float speed = dist(mouseX, mouseY, pmouseX, pmouseY);

  // Normalize speed between 0 and 1
  speedNorm = speed / maxSpeed;
  speedNorm = constrain(speedNorm, 0, 1);

  // Draw a small visual feedback circle at the mouse position
  noStroke();
  fill(255);
  ellipse(mouseX, mouseY, 12, 12);

  // Send the 3 features continuously to Wekinator
  sendOsc();

  // Display values on screen for checking/debugging
  fill(255);
  text("Lab 3 - Exercise 1 Input Sketch", 10, 30);
  text("Sending 3 normalized inputs to Wekinator", 10, 55);
  text("OSC address: /wek/inputs", 10, 80);
  text("Destination port: 6448", 10, 105);

  text("x normalized      = " + nf(xNorm, 1, 3), 10, 150);
  text("y normalized      = " + nf(yNorm, 1, 3), 10, 175);
  text("speed normalized  = " + nf(speedNorm, 1, 3), 10, 200);
}

void sendOsc() {
  OscMessage msg = new OscMessage("/wek/inputs");

  // These are the exact 3 inputs required by the exercise:
  msg.add(xNorm);
  msg.add(yNorm);
  msg.add(speedNorm);

  oscP5.send(msg, dest);
}
