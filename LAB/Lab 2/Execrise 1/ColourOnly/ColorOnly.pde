// Exercise 1 - Output / Visualization Sketch
// Receives one classifier output from Wekinator and changes canvas color.

import oscP5.*;

OscP5 oscP5;
int predictedClass = 0;
String currentMessage = "Waiting for Wekinator...";

void setup() {
  size(400, 400);
  oscP5 = new OscP5(this, 12000); // Wekinator sends outputs to port 12000 by default
  textAlign(CENTER, CENTER);
  textSize(32);
}

void draw() {
  if (predictedClass == 1) {
    background(255, 0, 0);   // Class 1 = red
  } else if (predictedClass == 2) {
    background(0, 0, 255);   // Class 2 = blue
  } else {
    background(80);          // Waiting / unknown
  }

  fill(255);
  text(currentMessage, width / 2, height / 2);
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/wek/outputs")) {
    if (theOscMessage.checkTypetag("f")) {
      float outputValue = theOscMessage.get(0).floatValue();
      predictedClass = int(outputValue);
      currentMessage = "Class " + predictedClass;
      println("Received class: " + predictedClass);
    }
  }
}
