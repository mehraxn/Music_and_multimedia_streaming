# README — Deep Explanation of `VideoMotionDetection.pde`

## The code we are studying

```java
import processing.video.*;
import oscP5.*;
import netP5.*;

Capture cam;
PImage prevFrame;

OscP5 oscP5;
NetAddress wekinator;

// Wekinator
String wekHost = "127.0.0.1";
int wekPort = 6448;
String oscAddress = "/wek/inputs";

// OSC local port
int localPort = 12001;

// motion detection
float threshold = 30;   // color pixel threshold to asses a motion
float motionAmount = 0;

// temporal buffer
int bufferSize = 30;
float[] motionBuffer = new float[bufferSize];

// image mirroring
boolean mirror = true;

void setup() {
  size(960, 722);

  oscP5 = new OscP5(this, localPort);
  wekinator = new NetAddress(wekHost, wekPort);

  String[] cameras = Capture.list();

  if (cameras == null || cameras.length == 0) {
    println("No cam found");
    exit();
  }

  println("Evailable cameras:");
  for (int i = 0; i < cameras.length; i++) {
    println(i + ": " + cameras[i]);
  }

  cam = new Capture(this, cameras[0]);
  cam.start();

  textFont(createFont("Arial", 14));
}

void captureEvent(Capture c) {
  c.read();
}

void draw() {
  background(0);

  cam.loadPixels();

  if (prevFrame == null) {
    prevFrame = cam.get();
    return;
  }

  prevFrame.loadPixels();

  int whiteCount = 0;
  int sampledCount = 0;

  // visual webcam
  pushMatrix();
  if (mirror) {
    translate(width, 0);
    scale(-1, 1);
  }
  image(cam, 0, 0, width, height);
  popMatrix();

  // ompute the difference with the previous frame
  for (int y = 0; y < cam.height; y++) {
    for (int x = 0; x < cam.width; x++) {
      int index = x + y * cam.width;

      color c1 = cam.pixels[index];
      color c2 = prevFrame.pixels[index];

      float b1 = brightness(c1);
      float b2 = brightness(c2);

      float diff = abs(b1 - b2);

      if (diff > threshold) {
        whiteCount++;
      }
      sampledCount++;
    }
  }

  // normalized quantity of movement 0..1 (weaighted by a factor)
  motionAmount = ((float)whiteCount / (float)sampledCount)*4;

  // update temporal buffer
  updateMotionBuffer(motionAmount);
  sendBufferToWekinator();

  // save current frame
  prevFrame = cam.get();

  // GUI
  drawHUD();
  drawBufferPreview();
}

void updateMotionBuffer(float value) {
  for (int i = 0; i < bufferSize - 1; i++) {
    motionBuffer[i] = motionBuffer[i + 1];
  }
  motionBuffer[bufferSize - 1] = value;
}

void sendBufferToWekinator() {
  OscMessage msg = new OscMessage(oscAddress);

  for (int i = 0; i < bufferSize; i++) {
    msg.add(motionBuffer[i]);
  }

  oscP5.send(msg, wekinator);
}

void drawHUD() {
  fill(0, 180);
  noStroke();
  rect(10, 10, 320, 110);

  fill(255);
  text("OSC -> " + wekHost + ":" + wekPort, 20, 35);
  text("Address: " + oscAddress, 20, 55);
  text("Motion amount: " + nf(motionAmount, 1, 4), 20, 75);
  text("Features sent: " + bufferSize, 20, 115);
}

void drawBufferPreview() {
  int gx = 20;
  int gy = height - 120;
  int gw = 300;
  int gh = 80;

  fill(0, 180);
  noStroke();
  rect(gx - 10, gy - 25, gw + 20, gh + 35);

  stroke(255);
  noFill();
  rect(gx, gy, gw, gh);

  noFill();
  stroke(0, 255, 0);
  beginShape();
  for (int i = 0; i < bufferSize; i++) {
    float x = map(i, 0, bufferSize - 1, gx, gx + gw);
    float y = map(motionBuffer[i], 0, 1, gy + gh, gy);
    vertex(x, y);
  }
  endShape();

  fill(255);
  text("Motion buffer (last " + bufferSize + " frames)", gx, gy - 8);
}
```

---

# 1. BIG PICTURE FIRST

In plain English, this sketch opens your webcam, watches how much the image changes from one frame to the next, turns that change into a motion value, stores the last 30 motion values, and sends those 30 numbers to Wekinator through OSC.

So this code is **not** doing machine learning by itself.
Its main job is to:

1. get live video from the webcam,
2. measure motion in that video,
3. build a short time-history of motion,
4. send that history to Wekinator,
5. show a visual interface so you can see what is happening.

### Purpose of the sketch

The purpose is to create a **motion feature extractor**.
A feature extractor is a program that takes raw input (here: webcam video) and turns it into numbers that another system can learn from.

Here, the extracted feature is not the whole image. Instead, it is:

* one motion amount per frame,
* stored across the last 30 frames,
* resulting in **30 input values**.

### What kind of input it uses

This sketch uses:

* **webcam input** from your camera,
* the current frame and previous frame,
* OSC networking to send data out.

### What kind of output it produces

It produces two kinds of output:

#### Visual output on screen

* the live webcam image,
* a HUD (heads-up display) showing motion and OSC information,
* a graph of the last 30 motion values.

#### Data output in the background

* an OSC message sent to Wekinator,
* containing **30 floating-point values**,
* one for each slot in the motion buffer.

### External tools involved

This sketch uses:

* **webcam**: to capture live video,
* **OSC**: Open Sound Control, a protocol for sending data between programs,
* **Wekinator**: receives the 30 motion values and learns from them if you train it.

So the practical system is:

**Camera → Processing → motion features → OSC → Wekinator**

---

# 2. OVERALL FLOW OF THE PROGRAM

Let us follow the full life of the sketch from beginning to continuous running.

## What happens first

When the sketch starts, `setup()` runs **once**.

Inside `setup()` the program:

* creates the window,
* starts OSC communication,
* prepares the Wekinator address,
* checks which cameras are available,
* chooses the first camera,
* starts the camera,
* sets the font for text display.

## What happens when camera frames arrive

Whenever the camera has a fresh frame ready, `captureEvent(Capture c)` runs.

That function calls `c.read();`, which tells Processing:

> “Take the newest camera frame and store it so the sketch can use it.”

Without this, the image would not update correctly.

## What happens continuously

After setup finishes, `draw()` runs over and over again, many times per second.

Each time `draw()` runs, the sketch:

1. clears the background,
2. loads the pixels of the current camera image,
3. checks whether there is a previous frame yet,
4. draws the webcam image,
5. compares current frame to previous frame pixel by pixel,
6. counts how many pixels changed enough to be considered motion,
7. converts that count into one normalized motion value,
8. pushes that value into a 30-value buffer,
9. sends the whole buffer to Wekinator,
10. saves the current frame as the new previous frame,
11. draws text and the graph.

## Role of `setup()` and `draw()`

### `setup()`

Runs once at the beginning.
Use it for preparation.
This is where you create objects, start devices, and configure the sketch.

### `draw()`

Runs repeatedly in a loop.
Use it for everything that must update continuously, such as:

* reading live input,
* analyzing motion,
* drawing graphics,
* sending updated values.

## Role of `captureEvent()`

This is an **event function**.
An event function is a function that runs automatically when a certain event happens.

Here, the event is:

* “the camera has a new frame ready.”

So `captureEvent()` is not called manually by you.
Processing calls it automatically.

---

# 3. BLOCK-BY-BLOCK EXPLANATION

## Block A — Library imports

```java
import processing.video.*;
import oscP5.*;
import netP5.*;
```

### What it does

This loads external libraries.

* `processing.video.*` gives webcam access.
* `oscP5.*` lets the sketch create and send OSC messages.
* `netP5.*` helps define network destinations such as IP address and port.

### Why it is needed

Without these libraries, the code would not understand camera capture or OSC communication.

### If removed

* remove video import → webcam code fails,
* remove OSC imports → networking code fails.

### How it connects to the sketch

These libraries provide the tools that make the whole project possible.

---

## Block B — Main objects

```java
Capture cam;
PImage prevFrame;

OscP5 oscP5;
NetAddress wekinator;
```

### What it does

This declares the major objects used later.

* `cam` represents the webcam stream.
* `prevFrame` stores the previous frame image.
* `oscP5` manages OSC communication.
* `wekinator` stores the network destination of Wekinator.

### Why it is needed

These are the core components of the system.
Without them there is no camera, no previous frame, and no OSC sending.

### If removed or changed

* remove `prevFrame` → no frame comparison, so no motion detection,
* remove `wekinator` → the sketch cannot know where to send OSC data.

### Connection to the rest

Nearly every important part of the program depends on these objects.

---

## Block C — Wekinator communication settings

```java
String wekHost = "127.0.0.1";
int wekPort = 6448;
String oscAddress = "/wek/inputs";

int localPort = 12001;
```

### What it does

This defines where OSC messages should go and which local port Processing should use.

* `wekHost = "127.0.0.1"` means “send to this same computer.”
* `wekPort = 6448` is the port Wekinator listens on.
* `oscAddress = "/wek/inputs"` is the OSC address pattern expected by Wekinator.
* `localPort = 12001` is the port on which this sketch creates its OSC object.

### Why it is needed

Network communication only works if both sides agree on:

* host,
* port,
* OSC address.

### If changed

If the port or address does not match Wekinator’s settings, Wekinator will receive nothing useful.

### Practical meaning

This is like writing the correct postal address on a package before sending it.

---

## Block D — Motion detection settings

```java
float threshold = 30;
float motionAmount = 0;
```

### What it does

* `threshold` decides when a pixel change is large enough to count as motion.
* `motionAmount` stores the final motion value computed for the current frame.

### Why it is needed

When comparing two frames, tiny changes can happen because of noise, lighting flicker, or camera sensor variation. A threshold avoids treating every tiny change as meaningful motion.

### If threshold is removed or set badly

* too low → almost everything counts as motion,
* too high → real movement may be ignored.

### Connection to the rest

The threshold directly controls the sensitivity of motion detection.

---

## Block E — Temporal buffer

```java
int bufferSize = 30;
float[] motionBuffer = new float[bufferSize];
```

### What it does

This creates an array of 30 floating-point values.

The array stores the last 30 motion values.

### Why it is needed

One motion value from one frame is often too limited.
A short history across time gives Wekinator more information.

For example:

* steady stillness,
* one sudden movement,
* repeated waving,
* gradual increase in motion,

all become different patterns when seen over 30 frames.

### If removed

The system would only send one number instead of a time pattern.
That would reduce expressive information.

### Practical meaning

This is like keeping the last 30 heartbeats instead of only the current heartbeat.

---

## Block F — Mirroring option

```java
boolean mirror = true;
```

### What it does

This decides whether the displayed camera image should be mirrored horizontally.

### Why it is useful

A mirrored image feels more natural to many users, like looking in a mirror.
When you move your right hand, the image appears to move as you expect.

### Important detail

This affects the **display**, not the motion calculation logic itself. The motion is calculated from the camera pixels, not from the mirrored drawing on screen.

---

## Block G — Setup

```java
void setup() {
  size(960, 722);

  oscP5 = new OscP5(this, localPort);
  wekinator = new NetAddress(wekHost, wekPort);

  String[] cameras = Capture.list();

  if (cameras == null || cameras.length == 0) {
    println("No cam found");
    exit();
  }

  println("Evailable cameras:");
  for (int i = 0; i < cameras.length; i++) {
    println(i + ": " + cameras[i]);
  }

  cam = new Capture(this, cameras[0]);
  cam.start();

  textFont(createFont("Arial", 14));
}
```

### What it does

This prepares the whole sketch.

### Why it is needed

The sketch cannot run properly unless it:

* opens a window,
* prepares OSC,
* finds a camera,
* starts the camera.

### If removed

Nothing important would initialize, so the sketch would not function.

### Connection to the rest

This is the foundation on which `draw()` depends.

---

## Block H — Camera event handler

```java
void captureEvent(Capture c) {
  c.read();
}
```

### What it does

When a new camera frame is available, this loads it into the capture object.

### Why it is needed

Without `c.read()`, the new frame may never be transferred into the sketch’s accessible memory.

### If removed

The video may freeze or not update correctly.

### Connection to the rest

Everything in `draw()` depends on current camera pixels being up to date.

---

## Block I — Beginning of `draw()`

```java
void draw() {
  background(0);

  cam.loadPixels();

  if (prevFrame == null) {
    prevFrame = cam.get();
    return;
  }
```

### What it does

* clears the window to black,
* loads current camera pixels,
* if there is no previous frame yet, saves the current frame as the first previous frame and stops this draw cycle.

### Why it is needed

Motion detection needs **two frames**:

* current frame,
* previous frame.

On the very first draw cycle, there is no previous frame yet.
So the sketch stores one and waits for the next cycle.

### If removed

The program would try to compare the current frame to `null`, which would cause errors.

---

## Block J — Prepare for motion analysis and draw webcam

```java
  prevFrame.loadPixels();

  int whiteCount = 0;
  int sampledCount = 0;

  pushMatrix();
  if (mirror) {
    translate(width, 0);
    scale(-1, 1);
  }
  image(cam, 0, 0, width, height);
  popMatrix();
```

### What it does

* loads previous frame pixels,
* creates counters,
* draws the camera image,
* optionally mirrors it.

### Why it is needed

* `whiteCount` counts how many pixels changed enough.
* `sampledCount` counts how many pixels were tested in total.
* the image drawing gives visual feedback.

### If removed

You would lose the counting logic and/or the live camera display.

### Practical meaning

This is the point where the sketch prepares to ask:

> “Out of all pixels, how many changed a lot?”

---

## Block K — Pixel-by-pixel motion detection

```java
  for (int y = 0; y < cam.height; y++) {
    for (int x = 0; x < cam.width; x++) {
      int index = x + y * cam.width;

      color c1 = cam.pixels[index];
      color c2 = prevFrame.pixels[index];

      float b1 = brightness(c1);
      float b2 = brightness(c2);

      float diff = abs(b1 - b2);

      if (diff > threshold) {
        whiteCount++;
      }
      sampledCount++;
    }
  }
```

### What it does

This is the heart of the motion detector.

For every pixel position:

1. find the pixel in the current frame,
2. find the pixel at the same position in the previous frame,
3. measure brightness in both,
4. compute the absolute difference,
5. if the difference is greater than the threshold, count it as motion,
6. count that one more pixel was examined.

### Why it is needed

Motion is detected by change over time.
If a part of the image becomes brighter or darker between frames, it often means something moved.

### If removed

There would be no motion calculation at all.

### Practical meaning

This is basically asking millions of tiny questions like:

> “Did this pixel change enough to matter?”

---

## Block L — Convert counts into one motion value

```java
  motionAmount = ((float)whiteCount / (float)sampledCount)*4;
```

### What it does

This computes the fraction of changed pixels.

Formula:

`motionAmount = changedPixels / totalPixels * 4`

### Why it is needed

`whiteCount` alone depends on camera resolution. A larger image would naturally have more changed pixels.
By dividing by total pixels, the code creates a normalized value.

### Why multiply by 4?

This scales the result upward.
It makes the motion values larger and possibly more useful or responsive for Wekinator and the graph.

### Important note

The comment says `0..1`, but because of `*4`, the value can be greater than 1.
So the comment is not fully accurate.
That is a very important beginner observation.

---

## Block M — Buffer update and OSC send

```java
  updateMotionBuffer(motionAmount);
  sendBufferToWekinator();
```

### What it does

* adds the newest motion value to the temporal history,
* sends the whole history to Wekinator.

### Why it is needed

This is where the sketch turns a single moment into a time-series feature vector.

### If removed

* without `updateMotionBuffer()` → history never changes,
* without `sendBufferToWekinator()` → Wekinator receives nothing.

### Practical meaning

This is the bridge from motion analysis to machine learning input.

---

## Block N — Save current frame and draw interface

```java
  prevFrame = cam.get();

  drawHUD();
  drawBufferPreview();
}
```

### What it does

* stores a copy of the current frame to become the previous frame next time,
* draws text overlay,
* draws the motion graph.

### Why it is needed

Motion comparison on the next frame needs this stored image.

### If removed

The next frame would not have a proper reference frame to compare with.

---

## Block O — Update the motion buffer

```java
void updateMotionBuffer(float value) {
  for (int i = 0; i < bufferSize - 1; i++) {
    motionBuffer[i] = motionBuffer[i + 1];
  }
  motionBuffer[bufferSize - 1] = value;
}
```

### What it does

This shifts all old values one place to the left and puts the newest value at the end.

### Why it is needed

This keeps the buffer as a moving window over recent time.

### If removed

The 30-value history would never update properly.

### Practical meaning

Imagine a row of 30 boxes:

* oldest value drops off the left side,
* everyone else moves left,
* newest value enters on the right.

---

## Block P — Send OSC to Wekinator

```java
void sendBufferToWekinator() {
  OscMessage msg = new OscMessage(oscAddress);

  for (int i = 0; i < bufferSize; i++) {
    msg.add(motionBuffer[i]);
  }

  oscP5.send(msg, wekinator);
}
```

### What it does

This creates an OSC message, fills it with the 30 buffer values, and sends it to Wekinator.

### Why it is needed

This is the actual data transfer step.
Without it, Processing would compute features but keep them to itself.

### If changed

* wrong address → Wekinator may ignore it,
* wrong number of inputs → Wekinator setup may not match.

### Practical meaning

This function packs the 30 recent motion values into a message and ships them out.

---

## Block Q — HUD drawing

```java
void drawHUD() {
  fill(0, 180);
  noStroke();
  rect(10, 10, 320, 110);

  fill(255);
  text("OSC -> " + wekHost + ":" + wekPort, 20, 35);
  text("Address: " + oscAddress, 20, 55);
  text("Motion amount: " + nf(motionAmount, 1, 4), 20, 75);
  text("Features sent: " + bufferSize, 20, 115);
}
```

### What it does

Draws a semi-transparent information box showing:

* destination IP and port,
* OSC address,
* current motion amount,
* number of features sent.

### Why it is needed

This helps you verify what the sketch is doing without reading the code each time.

### If removed

The program still works, but you lose useful debugging and learning feedback.

---

## Block R — Buffer graph drawing

```java
void drawBufferPreview() {
  int gx = 20;
  int gy = height - 120;
  int gw = 300;
  int gh = 80;

  fill(0, 180);
  noStroke();
  rect(gx - 10, gy - 25, gw + 20, gh + 35);

  stroke(255);
  noFill();
  rect(gx, gy, gw, gh);

  noFill();
  stroke(0, 255, 0);
  beginShape();
  for (int i = 0; i < bufferSize; i++) {
    float x = map(i, 0, bufferSize - 1, gx, gx + gw);
    float y = map(motionBuffer[i], 0, 1, gy + gh, gy);
    vertex(x, y);
  }
  endShape();

  fill(255);
  text("Motion buffer (last " + bufferSize + " frames)", gx, gy - 8);
}
```

### What it does

Draws a small graph showing the last 30 motion values.

### Why it is needed

A graph makes it much easier to understand the motion pattern over time.

### Important detail

The y-axis maps values from `0` to `1`, but the motion value can exceed `1` because of `*4`.
So strong motion might go outside the expected graph range.
That is another important detail a student should notice.

### Practical meaning

This graph is a visual preview of the very same 30 values being sent to Wekinator.

---

# 4. LINE-BY-LINE EXPLANATION FOR IMPORTANT PARTS

## Important Part 1 — First frame protection

```java
cam.loadPixels();

if (prevFrame == null) {
  prevFrame = cam.get();
  return;
}
```

### `cam.loadPixels();`

* **Syntax:** calls a method on the `cam` object.
* **Meaning:** make the camera’s pixel data available in the `cam.pixels[]` array.
* **Runtime effect:** after this line, the code can inspect camera pixels one by one.

### `if (prevFrame == null) {`

* **Syntax:** an `if` statement checks a condition.
* **Meaning:** ask whether a previous frame has not been stored yet.
* **Runtime effect:** on the first useful frame, this condition is true.

### `prevFrame = cam.get();`

* **Syntax:** assigns a copy of the current camera image.
* **Meaning:** save the current frame so it can be used as the “previous” frame next time.
* **Runtime effect:** initializes motion comparison.

### `return;`

* **Syntax:** exits the current function immediately.
* **Meaning:** stop this `draw()` cycle now.
* **Runtime effect:** avoids comparing current frame to a nonexistent previous frame.

---

## Important Part 2 — Pixel difference logic

```java
int index = x + y * cam.width;

color c1 = cam.pixels[index];
color c2 = prevFrame.pixels[index];

float b1 = brightness(c1);
float b2 = brightness(c2);

float diff = abs(b1 - b2);

if (diff > threshold) {
  whiteCount++;
}
```

### `int index = x + y * cam.width;`

* converts 2D coordinates `(x, y)` into a 1D array position,
* because pixel arrays are stored as one long line of values.

### `color c1 = cam.pixels[index];`

* gets the current frame pixel at that position.

### `color c2 = prevFrame.pixels[index];`

* gets the previous frame pixel at the same position.

### `float b1 = brightness(c1);`

* measures how bright the current pixel is.

### `float b2 = brightness(c2);`

* measures how bright the previous pixel was.

### `float diff = abs(b1 - b2);`

* computes the size of the brightness change,
* `abs()` means absolute value, so negative differences become positive.

### `if (diff > threshold) { whiteCount++; }`

* if the change is big enough, count this pixel as motion.

This sequence is the real motion detector.

---

## Important Part 3 — Converting motion to feature history

```java
motionAmount = ((float)whiteCount / (float)sampledCount)*4;
updateMotionBuffer(motionAmount);
sendBufferToWekinator();
```

### `motionAmount = ((float)whiteCount / (float)sampledCount)*4;`

* turns raw counts into a normalized motion measurement,
* `float` casts prevent integer division,
* multiplying by 4 scales the result.

### `updateMotionBuffer(motionAmount);`

* inserts the current motion amount into the history array.

### `sendBufferToWekinator();`

* sends the full 30-value time history to Wekinator.

This is the transition from raw computer vision to machine-learning-ready input.

---

# 5. VARIABLES AND DATA

## `Capture cam`

* **stores:** the live webcam stream,
* **why it exists:** to access current video frames,
* **how it changes:** it updates whenever new camera frames arrive,
* **where used:** `setup()`, `captureEvent()`, `draw()`,
* **type of data:** input.

## `PImage prevFrame`

* **stores:** the previous frame image,
* **why it exists:** motion detection needs a frame from the past,
* **how it changes:** replaced every draw cycle with the latest frame copy,
* **where used:** `draw()`,
* **type of data:** intermediate data.

## `OscP5 oscP5`

* **stores:** OSC communication manager,
* **why it exists:** to create/send OSC messages,
* **how it changes:** mainly stays the same after setup,
* **where used:** `setup()`, `sendBufferToWekinator()`,
* **type of data:** communication object.

## `NetAddress wekinator`

* **stores:** IP address and port of Wekinator,
* **why it exists:** tells OSC where to send data,
* **how it changes:** usually constant,
* **where used:** `setup()`, `sendBufferToWekinator()`,
* **type of data:** output destination info.

## `String wekHost`

* **stores:** host address,
* **value here:** `127.0.0.1`,
* **meaning:** same computer.

## `int wekPort`

* **stores:** target port number,
* **value here:** `6448`,
* **meaning:** Wekinator’s OSC input port.

## `String oscAddress`

* **stores:** OSC message address,
* **value here:** `/wek/inputs`,
* **meaning:** tells Wekinator what kind of OSC message this is.

## `int localPort`

* **stores:** Processing’s local OSC port,
* **why it exists:** required for OSC setup.

## `float threshold`

* **stores:** the minimum brightness difference needed to count as motion,
* **how it changes:** constant unless you edit the code,
* **type of data:** control parameter.

## `float motionAmount`

* **stores:** the current frame’s motion measure,
* **how it changes:** recalculated every `draw()`,
* **where used:** HUD, buffer update, graph indirectly,
* **type of data:** extracted feature.

## `int bufferSize`

* **stores:** number of history values to keep,
* **value here:** 30,
* **meaning:** 30 features will be sent.

## `float[] motionBuffer`

* **stores:** last 30 motion values,
* **how it changes:** values shift left and new value goes at the end,
* **where used:** OSC sending and graph drawing,
* **type of data:** feature vector / temporal history.

## `boolean mirror`

* **stores:** whether to mirror the displayed webcam image,
* **where used:** display section inside `draw()`,
* **type of data:** interface setting.

## `int whiteCount`

* **stores:** number of pixels whose change exceeds threshold,
* **how it changes:** reset every frame,
* **type of data:** intermediate motion count.

## `int sampledCount`

* **stores:** total number of compared pixels,
* **how it changes:** reset every frame,
* **type of data:** intermediate normalization count.

---

# 6. FUNCTIONS

## `setup()`

### What it does

Initializes the sketch window, OSC, camera, and font.

### When it runs

Once at startup.

### Input

No explicit input arguments.

### Output/effect

Creates the operating environment for the sketch.

### Contribution

Without this function, the system cannot start.

---

## `captureEvent(Capture c)`

### What it does

Reads the newest camera frame.

### When it runs

Automatically when the camera has a new frame ready.

### Input

`Capture c` — the capture object triggering the event.

### Output/effect

Updates camera data used by the sketch.

### Contribution

Ensures live video actually refreshes.

---

## `draw()`

### What it does

Performs the entire live cycle:

* read pixels,
* compare frames,
* calculate motion,
* update buffer,
* send OSC,
* draw interface.

### When it runs

Continuously.

### Input

No explicit arguments, but it uses global variables and current camera state.

### Output/effect

Produces graphics and sends data to Wekinator.

### Contribution

This is the main engine of the sketch.

---

## `updateMotionBuffer(float value)`

### What it does

Shifts the buffer left and inserts the new motion value.

### When it runs

Once per frame from `draw()`.

### Input

`value` — the newest motion amount.

### Output/effect

Updates temporal feature memory.

### Contribution

Creates a time-based input structure instead of a single number.

---

## `sendBufferToWekinator()`

### What it does

Creates and sends the OSC message containing all buffer values.

### When it runs

Once per frame from `draw()`.

### Input

Uses `motionBuffer`, `oscAddress`, `wekinator`.

### Output/effect

Sends 30 floats to Wekinator.

### Contribution

Connects Processing to the learning system.

---

## `drawHUD()`

### What it does

Draws informational text on the screen.

### When it runs

Once per frame from `draw()`.

### Input

Uses global values such as `motionAmount`, `wekHost`, `wekPort`, `bufferSize`.

### Output/effect

Shows status information visually.

### Contribution

Makes the system easier to understand and debug.

---

## `drawBufferPreview()`

### What it does

Draws a graph of the buffer values.

### When it runs

Once per frame from `draw()`.

### Input

Uses `motionBuffer` and window dimensions.

### Output/effect

Shows the recent motion history graphically.

### Contribution

Helps you visually understand what Wekinator is receiving.

---

# 7. LOGIC AND COMPUTATION

## How decisions are made

The main decision is here:

```java
if (diff > threshold)
```

This decides whether a pixel changed enough to count as motion.

So the logic is:

* compare brightness now vs before,
* if change is small → ignore,
* if change is big → count as movement.

## How loops work

The sketch uses nested loops:

```java
for (int y = 0; y < cam.height; y++) {
  for (int x = 0; x < cam.width; x++) {
```

A nested loop means one loop inside another.

This makes the program examine **every pixel** in the frame.

* outer loop goes row by row,
* inner loop goes across each pixel in that row.

## How comparisons work

It compares the brightness of the same pixel location in two frames.

That means the code is not tracking objects by name.
It is simply checking image change over time.

## How motion is calculated

The code does **frame differencing**.
Frame differencing means:

* take current frame,
* take previous frame,
* compare them,
* large changes suggest motion.

## Why brightness is used instead of full color difference

The code uses:

```java
brightness(c1)
brightness(c2)
```

This simplifies the comparison to one brightness value per pixel.
That is easier and cheaper than comparing red, green, and blue separately.

## What the threshold means

Threshold = sensitivity.

* smaller threshold → more sensitive,
* larger threshold → less sensitive.

If threshold is 30, then only brightness differences above 30 are counted.

## What the formula means

```java
motionAmount = ((float)whiteCount / (float)sampledCount)*4;
```

This means:

1. count changed pixels,
2. divide by total pixels,
3. scale the result.

So the final number expresses **how much of the image is moving**.

## What the temporal buffer means logically

The buffer turns a single snapshot into a short motion history.

This matters because many gestures are temporal, meaning they happen across time.

Examples:

* a quick hand raise,
* a repeated wave,
* staying still,
* shaking fast,

may have similar single-frame motion values but very different sequences over 30 frames.

---

# 8. WHAT I WILL SEE WHEN I RUN IT

When you run the sketch, you should expect the following:

## On screen

You will see:

* a large window,
* your webcam feed filling the window,
* probably mirrored horizontally if `mirror` is true,
* a dark information box at the top-left,
* a graph near the bottom-left showing recent motion values.

## In the HUD

You should see text such as:

* OSC destination host and port,
* OSC address `/wek/inputs`,
* current motion amount,
* number of features sent, which is 30.

## If you stay still

* `motionAmount` should stay low,
* the graph should be near the bottom,
* Wekinator will receive small values.

## If you move a lot

* `motionAmount` will rise,
* the graph will jump upward,
* Wekinator will receive larger buffer values.

## In the background

Every frame, Processing sends one OSC message to Wekinator.
That message contains 30 float values.

So even though you only see one graph, behind the scenes the sketch is continuously streaming feature data to Wekinator.

---

# 9. PRACTICAL INTERPRETATION

Let us explain the sketch as a real working system.

* **This part opens the camera**: `cam = new Capture(this, cameras[0]); cam.start();`
* **This part receives fresh webcam frames**: `captureEvent(Capture c) { c.read(); }`
* **This part compares current frame with previous frame**: the nested loops in `draw()`.
* **This part calculates motion amount**: `motionAmount = ((float)whiteCount / (float)sampledCount)*4;`
* **This part remembers recent motion over time**: `motionBuffer` plus `updateMotionBuffer()`.
* **This part sends values to Wekinator**: `sendBufferToWekinator()`.
* **This part draws the graph**: `drawBufferPreview()`.
* **This part shows status text**: `drawHUD()`.

So in practical terms, this sketch is like a sensor translator.
The webcam is the raw sensor.
Processing measures movement.
Then it transforms that movement into 30 numerical features for machine learning.

---

# 10. Probable Questions a Student Might Ask

## 1. Why do we need both `setup()` and `draw()`?

`setup()` is for things that should happen once, such as starting the camera.
`draw()` is for things that must repeat continuously, such as measuring motion and updating the screen.

## 2. Why do we need a previous frame?

Motion means change over time.
With only one frame, you only know what the image looks like now.
With two frames, you can detect what changed.

## 3. Why is `motionBuffer` an array?

Because the sketch stores many motion values, not just one.
An array is a structure that holds multiple values of the same type.
Here it holds 30 floats.

## 4. Why are there 30 inputs instead of 1?

Because 30 inputs carry temporal information.
One number tells only the current amount of motion.
Thirty numbers tell the recent motion pattern over time.
That is much more informative for Wekinator.

## 5. Why do we compare brightness instead of full color?

Brightness makes the comparison simpler and cheaper.
It reduces each pixel to one value.
That is often enough for basic motion detection.

## 6. What does the threshold do?

It decides what size of pixel change counts as meaningful motion.
Small differences below the threshold are ignored.

## 7. Why do we normalize by dividing by `sampledCount`?

Because otherwise the motion count would depend on image size.
Normalization turns the result into a proportion of changed pixels.

## 8. Why multiply by 4?

To amplify the motion signal.
This can make the values more responsive for visualization or machine learning.
But it also means the value may go above 1.

## 9. What is OSC?

OSC stands for Open Sound Control.
It is a messaging format used to send numbers and other data between programs in real time.

## 10. Is Processing doing machine learning here?

No.
Processing is only extracting features and sending them.
Wekinator is the system that learns from those features.

## 11. What exactly is sent to Wekinator?

A single OSC message containing 30 float values.
Those 30 values are the last 30 motion amounts stored in `motionBuffer`.

## 12. Why is the camera image mirrored?

Only for user comfort.
It makes the display feel more natural, like a mirror.

## 13. Why do we call `cam.loadPixels()` and `prevFrame.loadPixels()`?

Because before reading pixel arrays, Processing needs to make sure pixel data is loaded and available.

## 14. What happens on the first frame?

There is no previous frame yet, so the sketch saves the current frame and skips motion calculation once.

## 15. What does `return` do in that first-frame block?

It stops the current `draw()` function immediately so the code does not continue into invalid comparison logic.

---

# 11. Common Confusions and Mistakes

## Confusion 1 — “The mirrored image changes the motion calculation.”

Not here.
The mirroring is only for display.
The motion calculation uses the camera pixels directly.

## Confusion 2 — “Processing is learning the gestures.”

No.
Processing only measures and sends motion features.
Wekinator is the one that learns from training examples.

## Confusion 3 — “30 inputs means 30 images are sent.”

No.
The sketch is **not** sending 30 whole images.
It is sending 30 numbers.
Each number is one motion amount from one recent frame.

## Confusion 4 — “The buffer stores raw pixels.”

No.
It stores only motion summary values, not images.

## Confusion 5 — “Threshold detects objects.”

No.
Threshold only decides whether pixel brightness changed enough.
This is not object recognition.

## Confusion 6 — “`motionAmount` is always between 0 and 1.”

Not necessarily.
Because of `*4`, it can exceed 1.
That is important.

## Confusion 7 — “The graph always fits perfectly.”

Not necessarily.
The graph maps values from 0 to 1, but `motionAmount` can go above 1, so the graph may clip or go out of the intended range.

## Confusion 8 — “One big movement equals one pixel change.”

No.
A large movement usually changes many pixels, so `whiteCount` becomes larger.

## Confusion 9 — “If I increase `bufferSize`, nothing else changes.”

Actually, more features will be sent to Wekinator.
Then Wekinator must also be configured to expect that new number of inputs.

## Confusion 10 — “If Wekinator is not responding, the motion code is broken.”

Not always.
The motion code may be fine, but the OSC host, port, or address may be mismatched.

---

# 12. IF THIS CODE IS RELATED TO MACHINE LEARNING OR WEKINATOR

Yes, this code is related to Wekinator.

## Role of Processing

Processing is responsible for:

* opening the webcam,
* comparing frames,
* calculating motion features,
* building a temporal buffer,
* sending those numbers through OSC.

So Processing is the **feature extraction and communication side**.

## Role of Wekinator

Wekinator is responsible for:

* receiving the 30 input values,
* associating them with training examples and output labels or targets,
* learning a mapping from input features to outputs,
* making predictions later.

So Wekinator is the **machine learning side**.

## What Processing is extracting or sending

Processing extracts:

* one motion amount per frame,
* based on brightness change between current and previous frame.

Then it sends:

* the last 30 motion amounts,
* as a 30-dimensional feature vector.

## How many inputs and outputs this code implies

### Inputs to Wekinator

This code implies:

* **30 inputs** to Wekinator.

Because `bufferSize = 30`, and all 30 values are added to the OSC message.

### Outputs

This code does **not** define the machine learning outputs.
The outputs are decided in Wekinator when you create the project.

For example, Wekinator could be configured for:

* **classification**: such as still / wave / shake,
* **regression**: such as one continuous control value,
* **multiple outputs**: such as controlling sound parameters.

## Is this code doing classification, regression, or only feature extraction?

This code itself is doing **only feature extraction and transmission**.

It is not classifying.
It is not regressing.
It is not training.

Wekinator may later do classification or regression depending on how you configure it.

---

# 13. SIMPLE SUMMARY

## 5-sentence simple summary

This sketch opens a webcam and compares each new frame to the previous one. It checks how many pixels changed enough to count as motion. It turns that into one motion value per frame. It stores the last 30 motion values in an array. Then it sends those 30 values to Wekinator through OSC and also shows them on screen.

## One-paragraph conceptual summary

Conceptually, this sketch is a bridge between live video and machine learning. Instead of sending the full webcam image to Wekinator, it reduces the image to a much simpler description: how much motion is happening over time. Each frame produces one motion number, and the last 30 numbers form a short temporal pattern. That pattern becomes the machine-learning input. So the sketch is really a feature-extraction system that converts raw movement into a learnable time-series of 30 values.

## One-sentence summary of the code’s purpose

This code measures webcam motion over time and sends the last 30 motion values to Wekinator as OSC inputs.

---

# 14. TEACHING NOTES ON IMPORTANT IDEAS

Here are a few especially important conceptual translations:

* `prevFrame` means “what the camera looked like one moment ago.”
* `threshold` means “how big a change must be before we care.”
* `motionAmount` means “how much of the image seems to be moving right now.”
* `motionBuffer` means “the recent history of motion.”
* `sendBufferToWekinator()` means “send that history as machine-learning input.”

A very good mental model is this:

> The webcam gives raw images. Processing compresses those images into motion numbers. Wekinator learns patterns from those numbers.

---

# 15. FINAL CHECK

## The 3 most important ideas you must understand from this code

1. **Motion is detected by comparing the current frame to the previous frame.**
2. **The sketch sends 30 recent motion values, not full images, to Wekinator.**
3. **Processing extracts features; Wekinator learns from them.**

## The 3 most important lines or code blocks

### 1. First-frame initialization

```java
if (prevFrame == null) {
  prevFrame = cam.get();
  return;
}
```

Why important: without this, motion comparison cannot start safely.

### 2. Pixel difference logic

```java
float diff = abs(b1 - b2);
if (diff > threshold) {
  whiteCount++;
}
```

Why important: this is the core motion detection rule.

### 3. Buffer-to-Wekinator pipeline

```java
updateMotionBuffer(motionAmount);
sendBufferToWekinator();
```

Why important: this is where motion becomes machine-learning input.

## The 3 best follow-up questions you should ask next

1. How exactly does Wekinator interpret these 30 inputs during training and prediction?
2. How could we improve this motion detector so it tracks where motion happens, not just how much?
3. How would the behavior change if we used color difference, downsampling, or a different buffer size?

---

# One extra important observation as your professor

There are two small issues in the code/comments that are good learning opportunities:

1. The comment says the motion value is normalized to `0..1`, but because the code multiplies by `4`, the value can go above `1`.
2. The graph maps y-values from `0` to `1`, so if motion is stronger than `1`, the preview may not represent it perfectly.

That does not make the sketch useless. It simply means the code is a great example of how comments, visualization ranges, and actual numeric logic must stay consistent.

---

If you want, the next best study step is to ask for a **line-by-line beginner walkthrough of only the `draw()` function**, because that is where most of the real logic lives.
