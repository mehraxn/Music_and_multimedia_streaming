import oscP5.*;
import netP5.*;

OscP5 oscP5;

// Last value receved
int currentClass = 0;
String currentEmotion = "No input";

// OSC
int inPort = 12000;
String oscAddress = "/wek/outputs";

void setup() {
  size(800, 400);
  oscP5 = new OscP5(this, inPort);

  textAlign(CENTER, CENTER);
  textFont(createFont("Arial", 32));
}

void draw() {
  background(20);

  fill(255);
  textSize(24);
  text("Received class:", width/2, 80);

  textSize(48);
  text(currentClass, width/2, 150);

  textSize(24);
  text("Emotion:", width/2, 240);

  textSize(56);
  fill(255, 200, 0);
  text(currentEmotion, width/2, 310);
}

// OSC received
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern(oscAddress)) {
    float value = msg.get(0).floatValue();
    currentClass = round(value);

    currentEmotion = classToEmotion(currentClass);

    println("Received: " + currentClass + " -> " + currentEmotion);
  }
}

String classToEmotion(int c) {
  switch(c) {
    case 1:
      return "happy";
    case 2:
      return "neutral";
    default:
      return "unknwown";
  }
}
