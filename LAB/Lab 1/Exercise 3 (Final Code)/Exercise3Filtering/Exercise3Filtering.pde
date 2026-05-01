import processing.sound.*;
import processing.video.*;

Sound engine;
SoundFile audio;
FFT fft;
Capture cam;

int bands = 512;
float[] spectrum = new float[bands];

float sampleRate;
float centroidHz = 0;
float centroidMapped = 0;
float mouseMappedX = 0;
float mouseMappedY = 0;

void setup() {
  size(640, 480);

  // AUDIO
  engine = new Sound(this);
  sampleRate = Sound.sampleRate();

  audio = new SoundFile(this, "dogs.wav");
  audio.loop();

  fft = new FFT(this, bands);
  fft.input(audio);

  // CAMERA
  String[] cameras = Capture.list();

  if (cameras == null || cameras.length == 0) {
    println("No camera found.");
    exit();
    return;
  }

  cam = new Capture(this, cameras[0]);
  cam.start();

  textSize(16);
}

void draw() {
  background(0);

  // Camera
  if (cam.available()) {
    cam.read();
  }

  // Audio FFT
  fft.analyze(spectrum);

  // Spectral centroid
  centroidHz = computeSpectralCentroid(spectrum);

  float nyquist = sampleRate / 2.0;
  centroidMapped = map(centroidHz, 0, nyquist, 0, 255);
  centroidMapped = constrain(centroidMapped, 0, 255);

  // Mouse mapping
  mouseMappedX = map(mouseX, 0, width, 0, 255);
  mouseMappedX = constrain(mouseMappedX, 0, 255);

  mouseMappedY = map(mouseY, 0, height, 0, 255);
  mouseMappedY = constrain(mouseMappedY, 0, 255);

  // Tint + display
  tint(centroidMapped, mouseMappedX, mouseMappedY);
  image(cam, 0, 0, width, height);
  noTint();

  // Info
  fill(255, 230);
  rect(10, 10, 270, 100);

  fill(0);
  text("Centroid (Hz): " + nf(centroidHz, 0, 2), 20, 35);
  text("Centroid mapped: " + nf(centroidMapped, 0, 2), 20, 55);
  text("Mouse X mapped: " + nf(mouseMappedX, 0, 2), 20, 75);
  text("Mouse Y mapped: " + nf(mouseMappedY, 0, 2), 20, 95);
}

float computeSpectralCentroid(float[] spectrumData) {
  float weightedSum = 0;
  float magnitudeSum = 0;

  for (int k = 0; k < spectrumData.length; k++) {
    float frequency = k * sampleRate / (2.0 * spectrumData.length);
    float magnitude = spectrumData[k];

    weightedSum += frequency * magnitude;
    magnitudeSum += magnitude;
  }

  if (magnitudeSum == 0) {
    return 0;
  }

  return weightedSum / magnitudeSum;
}
