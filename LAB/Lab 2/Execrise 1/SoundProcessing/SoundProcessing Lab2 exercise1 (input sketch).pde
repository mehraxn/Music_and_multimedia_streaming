import processing.sound.*;
import oscP5.*;
import netP5.*;

// ----------------------------
// AUDIO
// ----------------------------
AudioIn mic;
FFT fft;

int bands = 512;             // FFT band resolution required by the lab
float[] spectrum = new float[bands];

// ----------------------------
// FEATURE EXTRACTION
// ----------------------------
// Change this value before each Wekinator experiment:
// 1 = full FFT, 512 inputs
// 2 = reduced FFT, 64 inputs
// 3 = reduced FFT, 12 inputs
// 4 = mean + variance, 2 inputs
int featureMode = 3;

int numFeatureBands;
float[] features;
float[] smoothFeatures;

// FFT smoothing
float smoothing = 0.85;

// ----------------------------
// OSC / WEKINATOR
// ----------------------------
OscP5 oscP5;
NetAddress wekinator;

// OSC ports
int receivePort = 12001;
int sendPort = 6448;

// timer invio
int sendIntervalMs = 30;   // about 30 msg/sec
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

  fft = new FFT(this, bands);
  fft.input(mic);

  configureFeatureMode();

  textFont(createFont("Arial", 16));
}

void configureFeatureMode() {
  if (featureMode == 1) {
    numFeatureBands = 512;
  } else if (featureMode == 2) {
    numFeatureBands = 64;
  } else if (featureMode == 3) {
    numFeatureBands = 12;
  } else if (featureMode == 4) {
    numFeatureBands = 2;
  }

  features = new float[numFeatureBands];
  smoothFeatures = new float[numFeatureBands];
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
  // FFT with 512 bands
  fft.analyze(spectrum);

  if (featureMode == 1) {
    // Full 512-band FFT
    for (int i = 0; i < bands; i++) {
      smoothFeatures[i] = lerp(smoothFeatures[i], spectrum[i], 1.0 - smoothing);
      features[i] = smoothFeatures[i] * 10.0;
    }
  } else if (featureMode == 2) {
    // Reduced 64-band FFT
    downsampleSpectrum(64);
  } else if (featureMode == 3) {
    // Reduced 12-band FFT
    downsampleSpectrum(12);
  } else if (featureMode == 4) {
    // Mean and variance of the 512 FFT bands
    float mean = computeMean(spectrum);
    float variance = computeVariance(spectrum, mean);

    features[0] = mean;
    features[1] = variance;
  }
}

void downsampleSpectrum(int targetBands) {
  for (int i = 0; i < targetBands; i++) {
    int start = floor(i * bands / float(targetBands));
    int end = floor((i + 1) * bands / float(targetBands));

    float sum = 0;
    for (int j = start; j < end; j++) {
      sum += spectrum[j];
    }

    float avg = sum / float(end - start);

    // Smoothing
    smoothFeatures[i] = lerp(smoothFeatures[i], avg, 1.0 - smoothing);

    // Light amplification, same idea as the original sketch
    features[i] = smoothFeatures[i] * 10.0;
  }
}

float computeMean(float[] values) {
  float sum = 0;

  for (int i = 0; i < values.length; i++) {
    sum += values[i];
  }

  return sum / values.length;
}

float computeVariance(float[] values, float mean) {
  float sum = 0;

  for (int i = 0; i < values.length; i++) {
    float difference = values[i] - mean;
    sum += difference * difference;
  }

  return sum / values.length;
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
  text("Feature mode: " + featureMode, 30, 80);
  text("Inputs sent to Wekinator: " + features.length, 30, 110);

  if (featureMode == 1) {
    text("Mode 1: Full FFT with 512 bands", 30, 140);
  } else if (featureMode == 2) {
    text("Mode 2: Reduced FFT with 64 bands", 30, 140);
  } else if (featureMode == 3) {
    text("Mode 3: Reduced FFT with 12 bands", 30, 140);
  } else if (featureMode == 4) {
    text("Mode 4: Mean + variance", 30, 140);
  }

  // Feature bars.
  // For 512 inputs, only the first 64 are drawn to keep the screen readable.
  int displayBands = min(numFeatureBands, 64);
  int x0 = 30;
  int y0 = 200;
  int gap = 3;
  int maxH = 190;
  int barW = max(2, int((width - 60 - gap * (displayBands - 1)) / float(displayBands)));

  for (int i = 0; i < displayBands; i++) {
    float v = constrain(features[i], 0, 1.5);
    float h = map(v, 0, 1.5, 0, maxH);

    fill(80, 180, 255);
    rect(x0 + i * (barW + gap), y0 + maxH - h, barW, h);
  }

  // Full 512-band spectrum line
  stroke(0, 255, 140);
  noFill();
  beginShape();
  for (int i = 0; i < bands; i++) {
    float x = map(i, 0, bands - 1, 30, width - 30);
    float y = map(spectrum[i], 0, 0.2, height - 30, height - 160);
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
