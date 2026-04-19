
import processing.sound.*;
import oscP5.*;
import netP5.*;

// ----------------------------
// AUDIO
// ----------------------------
AudioIn mic;
Amplitude amp;
FFT fft;

int bands = 512;             // FFT band resolution
float[] spectrum = new float[bands];

// ----------------------------
// FEATURE EXTRACTION
// ----------------------------
int numFeatureBands = 12;    // num bands sent in OSC
float[] features = new float[numFeatureBands + 1]; 
// features[0] =  RMS
// features[1..12] = FFT bands

// FFT smoothing
float smoothAmp = 0;
float[] smoothBands = new float[numFeatureBands];
float smoothing = 0.85;

// ----------------------------
// OSC / WEKINATOR
// ----------------------------
OscP5 oscP5;
NetAddress wekinator;

// OSC ports
int receivePort = 12001;
int sendPort = 6448;

// label / classe ricevuta
//int predictedClass = -1;
//String predictedLabel = "nessuna";

// timer invio
int sendIntervalMs = 30;   // 30 msg/sec
int lastSendTime = 0;

void setup() {
  size(1000, 600);
  surface.setTitle("Realtime Sound Classifier - Processing + Wekinator");
  
  // ----------------------------
  // OSC
  // ----------------------------
  oscP5 = new OscP5(this, receivePort);
  wekinator = new NetAddress("127.0.0.1", sendPort);

  // ----------------------------
  // AUDIO INPUT
  // ----------------------------
  mic = new AudioIn(this, 0);
  mic.start();

  amp = new Amplitude(this);
  amp.input(mic);

  fft = new FFT(this, bands);
  fft.input(mic);

  textFont(createFont("Arial", 16));
}

void draw() {
  background(15);
  
  analyzeAudio();
  
  if (millis() - lastSendTime >= sendIntervalMs) {
    sendFeaturesToWekinator();
    lastSendTime = millis();
  }
  
  drawUI();
}

void analyzeAudio() {
  // RMS
  float currentAmp = amp.analyze();
  smoothAmp = lerp(smoothAmp, currentAmp, 1.0 - smoothing);
  features[0] = smoothAmp;

  // FFT
  fft.analyze(spectrum);

  // Reduce the number of bands by an avareging procedure
  int binSize = bands / numFeatureBands;

  for (int i = 0; i < numFeatureBands; i++) {
    int start = i * binSize;
    int end = min(start + binSize, bands);

    float sum = 0;
    for (int j = start; j < end; j++) {
      sum += spectrum[j];
    }

    float avg = sum / float(end - start);

    // Smoothing
    smoothBands[i] = lerp(smoothBands[i], avg, 1.0 - smoothing);

    // Light amplification
    features[i + 1] = smoothBands[i] * 10.0;
  }
}

void sendFeaturesToWekinator() {
  OscMessage msg = new OscMessage("/wek/inputs");

  for (int i = 0; i < features.length; i++) {
    msg.add(features[i]);
  }

  oscP5.send(msg, wekinator);
}

void drawUI() {
  fill(255);
  textSize(24);
  text("Real time sound classification", 30, 40);

  textSize(18);
  //text("Pedicted class: " + predictedLabel + " (" + predictedClass + ")", 30, 80);
  text("RMS: " + nf(features[0], 1, 4), 30, 110);

  // Barre feature FFT
  int x0 = 30;
  int y0 = 180;
  int barW = 55;
  int gap = 12;
  int maxH = 220;

  for (int i = 0; i < numFeatureBands; i++) {
    float v = constrain(features[i + 1], 0, 1.5);
    float h = map(v, 0, 1.5, 0, maxH);

    fill(80, 180, 255);
    rect(x0 + i * (barW + gap), y0 + maxH - h, barW, h);

    fill(220);
    textSize(12);
    textAlign(CENTER);
    text(i + 1, x0 + i * (barW + gap) + barW / 2, y0 + maxH + 18);
  }

  // waveform / spectrum
  stroke(0, 255, 140);
  noFill();
  beginShape();
  for (int i = 0; i < bands; i++) {
    float x = map(i, 0, bands - 1, 30, width - 30);
    float y = map(spectrum[i], 0, 0.2, height - 30, height - 220);
    vertex(x, y);
  }
  endShape();

  noStroke();
  fill(180);
  textAlign(LEFT);
  textSize(14);
  text("Send OSC -> /wek/inputs", 30, height - 90);
  text("Press T to print feature values", 30, height - 70);
}

void keyPressed() {
  if (key == 't' || key == 'T') {
    print("FEATURES: ");
    for (int i = 0; i < features.length; i++) {
      print(nf(features[i], 1, 4) + " ");
    }
    println();
  }
}
