import oscP5.*;
import netP5.*;
import java.util.ArrayList;

OscP5 oscP5;

// ----------------------
// CLASSES
// 1 = clap
// 2 = snap
// 3 = voice
// ----------------------
int predictedClass = 0;
int previousClass = 0;

String currentLabel = "SILENCE";

// text animation
float textPulse = 0;
float bgPulse = 0;
float transition = 0;

// particles
ArrayList<Particle> particles = new ArrayList<Particle>();

void setup() {
  size(1000, 700, P2D);
  smooth(8);
  oscP5 = new OscP5(this, 12000);

  textAlign(CENTER, CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);
}

void draw() {
  updateAnimation();
  drawBackgroundByClass();
  drawParticles();
  drawCenterVisual();
  drawFancyLabel();
}

// ----------------------
// OSC RECECIVER
// ----------------------
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs")) {
    if (msg.typetag().length() > 0) {
      int incomingClass = round(msg.get(0).floatValue());

      if (incomingClass != predictedClass) {
        previousClass = predictedClass;
        predictedClass = incomingClass;
        currentLabel = classToLabel(predictedClass);
        triggerClassEffect(predictedClass);
        transition = 1.0;
      }
    }
  }
}

// ----------------------
// LABELS
// ----------------------
String classToLabel(int c) {
  if (c == 1) return "CLAP";
  if (c == 2) return "SNAP";
  if (c == 3) return "VOICE";
  return "CLASSE " + c;
}

// ----------------------
// UPDATE
// ----------------------
void updateAnimation() {
  textPulse += 0.08;
  bgPulse += 0.02;
  transition *= 0.92;

  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    if (p.dead()) {
      particles.remove(i);
    }
  }


  if (frameCount % 4 == 0) {
    particles.add(new Particle(width/2 + random(-80, 80), height/2 + random(-80, 80), predictedClass));
  }
}

// ----------------------
// BACKGROUND
// ----------------------
void drawBackgroundByClass() {
  noStroke();

  if (predictedClass == 0) {
    background(10, 12, 20);
    fill(30, 40, 70, 30);
    for (int i = 0; i < 12; i++) {
      float x = noise(i * 100, bgPulse) * width;
      float y = noise(i * 200, bgPulse + 100) * height;
      ellipse(x, y, 120 + 30*sin(bgPulse+i), 120 + 30*sin(bgPulse+i));
    }
  } 
  else if (predictedClass == 1) {
    background(25, 10, 30);
    for (int i = 0; i < 8; i++) {
      float r = map(i, 0, 7, 100, width * 1.2);
      noFill();
      stroke(255, 120, 180, 50);
      strokeWeight(2);
      ellipse(width/2, height/2, r + sin(bgPulse*8)*30, r + sin(bgPulse*8)*30);
    }
  } 
  else if (predictedClass == 2) {
    background(5, 20, 30);
    stroke(80, 220, 255, 50);
    strokeWeight(2);
    for (int i = 0; i < 40; i++) {
      float x1 = random(width);
      float y1 = random(height);
      float x2 = x1 + random(-80, 80);
      float y2 = y1 + random(-80, 80);
      line(x1, y1, x2, y2);
    }
  } 
  else if (predictedClass == 3) {
    background(20, 8, 8);
    noStroke();
    for (int i = 0; i < 18; i++) {
      float x = width/2 + sin(bgPulse + i*0.2) * (120 + i*8);
      float y = height/2 + cos(bgPulse*1.4 + i*0.3) * (80 + i*6);
      fill(255, 100 + i*5, 60, 20);
      ellipse(x, y, 180, 180);
    }
  }

  // flash di transizione
  if (transition > 0.01) {
    fill(255, 255 * transition * 0.15);
    rect(width/2, height/2, width, height);
  }
}

// ----------------------
// VISUAL
// ----------------------
void drawCenterVisual() {
  pushMatrix();
  translate(width/2, height/2);

  float pulse = 1.0 + 0.08 * sin(textPulse * 2.5);

  noStroke();

  if (predictedClass == 0) {
    for (int i = 0; i < 5; i++) {
      fill(100, 140, 255, 18);
      ellipse(0, 0, 180 + i*35 + sin(textPulse+i)*8, 180 + i*35 + sin(textPulse+i)*8);
    }
  } 
  else if (predictedClass == 1) {
    for (int i = 0; i < 6; i++) {
      fill(255, 80, 160, 22);
      ellipse(0, 0, (120 + i*30) * pulse, (120 + i*30) * pulse);
    }
    stroke(255, 180, 220, 140);
    strokeWeight(4);
    for (int a = 0; a < 16; a++) {
      float ang = TWO_PI / 16 * a + textPulse * 0.15;
      float r1 = 70;
      float r2 = 170 + 20*sin(textPulse*3 + a);
      line(cos(ang)*r1, sin(ang)*r1, cos(ang)*r2, sin(ang)*r2);
    }
  } 
  else if (predictedClass == 2) {
    rotate(sin(textPulse)*0.08);
    for (int i = 0; i < 5; i++) {
      stroke(80, 220, 255, 100);
      strokeWeight(2);
      noFill();
      rect(0, 0, 120 + i*35, 120 + i*35);
    }
    for (int i = 0; i < 10; i++) {
      float ang = TWO_PI / 10 * i;
      stroke(120, 255, 255, 160);
      line(0, 0, cos(ang) * 180, sin(ang) * 180);
    }
  } 
  else if (predictedClass == 3) {
    noStroke();
    for (int i = 0; i < 12; i++) {
      float ang = TWO_PI / 12 * i + textPulse * 0.15;
      float r = 70 + 15*sin(textPulse*2 + i);
      float x = cos(ang) * r;
      float y = sin(ang) * r;
      fill(255, 120, 80, 50);
      ellipse(x, y, 80, 80);
    }
    fill(255, 180, 120, 60);
    ellipse(0, 0, 180 + 20*sin(textPulse*3), 180 + 20*sin(textPulse*3));
  }

  popMatrix();
}

// ----------------------
// TEXT
// ----------------------
void drawFancyLabel() {
  float s = 92 + 10 * sin(textPulse * 3.0) + transition * 30;

  // ombra/glow
  for (int i = 8; i > 0; i--) {
    fill(labelR(), labelG(), labelB(), 18);
    textSize(s + i * 3);
    text(currentLabel, width/2, height/2);
  }

  fill(255);
  textSize(s);
  text(currentLabel, width/2, height/2);

  fill(255, 180);
  textSize(18);
  text("classe rilevata", width/2, height/2 + 70);
}

// ----------------------
// COLOUR LABEL
// ----------------------
float labelR() {
  if (predictedClass == 0) return 120;
  if (predictedClass == 1) return 255;
  if (predictedClass == 2) return 80;
  if (predictedClass == 3) return 255;
  return 255;
}

float labelG() {
  if (predictedClass == 0) return 160;
  if (predictedClass == 1) return 100;
  if (predictedClass == 2) return 220;
  if (predictedClass == 3) return 160;
  return 255;
}

float labelB() {
  if (predictedClass == 0) return 255;
  if (predictedClass == 1) return 180;
  if (predictedClass == 2) return 255;
  if (predictedClass == 3) return 90;
  return 255;
}

void triggerClassEffect(int c) {
  for (int i = 0; i < 40; i++) {
    particles.add(new Particle(width/2, height/2, c));
  }
}

// ----------------------
// PARTICLES
// ----------------------
class Particle {
  float x, y;
  float vx, vy;
  float life;
  float size;
  int type;

  Particle(float x_, float y_, int t_) {
    x = x_;
    y = y_;
    type = t_;
    life = 255;
    size = random(4, 16);

    if (type == 0) {
      vx = random(-0.5, 0.5);
      vy = random(-0.5, 0.5);
    } else if (type == 1) {
      float a = random(TWO_PI);
      float sp = random(2, 7);
      vx = cos(a) * sp;
      vy = sin(a) * sp;
    } else if (type == 2) {
      vx = random(-6, 6);
      vy = random(-6, 6);
    } else {
      vx = random(-2, 2);
      vy = random(-2, 2);
    }
  }

  void update() {
    x += vx;
    y += vy;

    if (type == 0) {
      life -= 2;
    } else if (type == 1) {
      vx *= 0.97;
      vy *= 0.97;
      life -= 4;
    } else if (type == 2) {
      life -= 5;
    } else if (type == 3) {
      x += sin(frameCount * 0.08 + y * 0.01) * 1.2;
      y += cos(frameCount * 0.08 + x * 0.01) * 1.2;
      life -= 3;
    }
  }

  void display() {
    noStroke();
    if (type == 0) fill(120, 170, 255, life * 0.4);
    else if (type == 1) fill(255, 100, 180, life * 0.5);
    else if (type == 2) fill(100, 240, 255, life * 0.5);
    else fill(255, 160, 90, life * 0.45);

    ellipse(x, y, size, size);
  }

  boolean dead() {
    return life <= 0;
  }
}

void drawParticles() {
  for (Particle p : particles) {
    p.display();
  }
}
