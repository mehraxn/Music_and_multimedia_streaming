import processing.sound.*;
import oscP5.*;
import netP5.*;

SoundFile file;
AudioIn in;
LowPass lp;

OscP5 oscP5;

int currentFilter = 20000;

void setup() {
  size(400, 200);

  // Audio input
  file = new SoundFile(this, "sample.mp3");
  file.play();

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
  
  text(currentFilter, width/2, height/2);
  
}

// OSC Receiver
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs")) {
    
    float value = msg.get(0).floatValue();
    
    currentFilter = int(map(value,0,1,100,20000));
    
    println(currentFilter);
    updateFilter();
  }
}


void updateFilter() {
  lp.freq(currentFilter);
}
