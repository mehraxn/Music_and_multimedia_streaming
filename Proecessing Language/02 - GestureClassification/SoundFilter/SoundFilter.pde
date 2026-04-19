import processing.sound.*;
import oscP5.*;
import netP5.*;

SoundFile file;
AudioIn in;
LowPass lp;

OscP5 oscP5;

int currentClass = 1;

void setup() {
  size(400, 200);

  // Audio input
  file = new SoundFile(this, "sample.mp3");
  file.play();

  // Low Pass filter
  lp = new LowPass(this);
  lp.process(file);
  lp.freq(20000); 

  // OSC (port 12000)
  oscP5 = new OscP5(this, 12000);
}

void draw() {
  background(0);
  fill(255);
  textAlign(CENTER, CENTER);
  
  if (currentClass == 1) {
    text("No Filter applyed", width/2, height/2);
  }
  else if (currentClass == 2){
    text("Filter applyed", width/2, height/2);
  }
  
}

// OSC receiver
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs")) {
    
    float value = msg.get(0).floatValue();
    int newClass = round(value);
    
    println(value);

    if (newClass != currentClass) {
      currentClass = newClass;
      updateFilter();
    }
  }
}

// Uodate Filter behaviuor
void updateFilter() {
  if (currentClass == 1) {
    lp.freq(20000);
  }
  else if (currentClass == 2){
    lp.freq(80);
  }
}
