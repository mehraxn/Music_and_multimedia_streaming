# README — Deep Explanation of `SoundProcessing.pde`

## What code I am explaining

I am explaining the uploaded Processing sketch `SoundProcessing.pde`.

---

# 1. Big Picture First

## What this whole code is supposed to do

This sketch builds a **real-time sound analysis system** in Processing. It listens to sound from your microphone, measures some important audio properties, shows those properties on the screen, and sends them to **Wekinator** using **OSC**.

In simple words:

* the microphone captures live sound
* the code measures **how loud the sound is**
* the code also measures **how the sound energy is distributed across frequencies**
* it reduces that frequency information into a smaller set of features
* it sends those features to Wekinator as machine learning inputs
* it also draws a visual interface so you can see the sound data changing in real time

## Purpose of the sketch

The purpose of the sketch is **not** to classify sound by itself.
Its main job is to:

1. **capture live audio**
2. **extract features** from that audio
3. **send those features to Wekinator**
4. **visualize** what is happening

So this sketch is mainly a **feature extractor + visualizer + OSC sender**.

## What input it uses

This code uses:

* **microphone audio input** from your computer

## What output or result it produces

This code produces several outputs:

* visual output in the Processing window
* numerical audio features stored in arrays
* OSC messages sent to Wekinator at `/wek/inputs`
* optional printed feature values in the console when you press `T`

## External tools or technologies involved

Yes — this code interacts with external tools:

### `processing.sound`

This library is used to:

* access microphone input
* compute amplitude
* compute FFT

### `oscP5` and `netP5`

These libraries are used to:

* create OSC messages
* send those messages to Wekinator

### Wekinator

Wekinator is expected to receive the features and learn patterns from them.
This code itself does **not** train a machine learning model. It only sends inputs.

---

# 2. Overall Flow of the Program

Let us walk through the full life of the program.

## What happens first

When the sketch starts, `setup()` runs **once**.
In `setup()` the code:

* creates the window
* gives the window a title
* opens OSC communication
* starts the microphone
* connects amplitude analysis to the microphone
* connects FFT analysis to the microphone
* prepares the font for on-screen text

## What happens continuously

After `setup()` finishes, `draw()` runs over and over again, many times per second.
Every time `draw()` runs, the code:

1. clears the screen
2. analyzes the newest microphone audio
3. sends features to Wekinator every 30 milliseconds
4. redraws the interface

## Role of `setup()`

`setup()` is the initialization phase.
It is where the program prepares everything it needs before live execution begins.

A beginner-friendly analogy:

* `setup()` is like preparing a laboratory before an experiment starts
* `draw()` is the experiment running again and again in real time

## Role of `draw()`

`draw()` is the real-time loop.
It keeps updating the analysis and the screen.
Without `draw()`, there would be no continuous sound analysis or visualization.

## Event function: `keyPressed()`

This function runs only when you press a key.
In this sketch, if you press `T` or `t`, it prints the current feature values into the Processing console.

That is useful for debugging because it lets you see the exact numbers being sent.

---

# 3. Block-by-Block Explanation

---

## Block A — Imports

```java
import processing.sound.*;
import oscP5.*;
import netP5.*;
```

### What it does

This loads external libraries.

### Why it is needed

* `processing.sound.*` gives access to microphone input, amplitude analysis, and FFT.
* `oscP5.*` allows OSC message creation and communication.
* `netP5.*` helps define the network address where OSC messages will be sent.

### What happens if removed

If you remove these imports, Processing will not understand classes like `AudioIn`, `Amplitude`, `FFT`, `OscP5`, `OscMessage`, or `NetAddress`.
The sketch will fail to compile.

### How it connects to the program

These imports make the core technologies of the sketch possible: **sound analysis** and **communication with Wekinator**.

---

## Block B — Audio objects and FFT storage

```java
AudioIn mic;
Amplitude amp;
FFT fft;

int bands = 512;
float[] spectrum = new float[bands];
```

### What it does

This declares objects and variables for audio processing.

### Why it is needed

* `mic` will represent the live microphone input.
* `amp` will calculate loudness.
* `fft` will calculate the frequency spectrum.
* `bands = 512` means the FFT will produce 512 bins, or frequency slices.
* `spectrum` stores those 512 FFT values.

### If removed or changed

* Without `mic`, no sound enters the system.
* Without `amp`, you cannot measure loudness.
* Without `fft`, you cannot analyze the spectrum.
* If `bands` changes, the number of FFT bins changes too.
* If `spectrum` is missing, there is nowhere to store FFT output.

### Connection to rest of program

This is the raw audio analysis layer. Everything later depends on it.

---

## Block C — Feature extraction setup

```java
int numFeatureBands = 12;
float[] features = new float[numFeatureBands + 1];
// features[0] = RMS
// features[1..12] = FFT bands
```

### What it does

This defines the final feature vector that will be sent to Wekinator.

### Why it is needed

Instead of sending all 512 FFT bins, the code compresses them into 12 larger groups. That keeps the input smaller and easier for machine learning.

The array has size `13` because:

* 1 feature for amplitude (RMS-like loudness)
* 12 features for grouped frequency information

### If removed or changed

Without `features`, the program would analyze sound but have no organized package of values to send.
If you increase `numFeatureBands`, Wekinator will need more inputs.
If you reduce it, you get less detail about the sound spectrum.

### Connection to rest of program

This is the feature vector that becomes the **machine learning input**.

---

## Block D — Smoothing variables

```java
float smoothAmp = 0;
float[] smoothBands = new float[numFeatureBands];
float smoothing = 0.85;
```

### What it does

This creates smoothed versions of the audio values.

### Why it is needed

Raw audio data changes very fast and can look shaky or noisy. Smoothing makes the values more stable.

### If removed or changed

* If removed, bars and values would jump more nervously.
* If `smoothing` becomes larger, values respond more slowly and look smoother.
* If `smoothing` becomes smaller, values respond faster but become more unstable.

### Connection to rest of program

These smoothed values are used both for display and for the features sent to Wekinator.
That is important because cleaner inputs often help machine learning.

---

## Block E — OSC and Wekinator connection

```java
OscP5 oscP5;
NetAddress wekinator;

int receivePort = 12001;
int sendPort = 6448;
```

### What it does

This prepares OSC communication.

### Why it is needed

* `oscP5` manages OSC messages.
* `wekinator` stores the destination address.
* `receivePort` is the port on which Processing could listen.
* `sendPort` is the port where Wekinator listens for input features.

### If removed or changed

Without this, the sketch can still analyze sound and draw graphics, but it cannot communicate with Wekinator.
If the port numbers do not match Wekinator’s settings, Wekinator will not receive the data.

### Connection to rest of program

This is the communication bridge from Processing to Wekinator.

---

## Block F — Send timing

```java
int sendIntervalMs = 30;
int lastSendTime = 0;
```

### What it does

This limits how often features are sent.

### Why it is needed

The `draw()` loop may run very fast. Instead of sending data every frame, this code sends roughly every 30 milliseconds, which is about 33 messages per second.

### If removed or changed

* If removed and you send every frame, the sending rate depends entirely on frame rate.
* If `sendIntervalMs` is smaller, messages are sent more often.
* If it is larger, messages are sent less often.

### Connection to rest of program

This controls the rhythm of communication with Wekinator.

---

## Block G — `setup()`

```java
void setup() {
  size(1000, 600);
  surface.setTitle("Realtime Sound Classifier - Processing + Wekinator");
  
  oscP5 = new OscP5(this, receivePort);
  wekinator = new NetAddress("127.0.0.1", sendPort);

  mic = new AudioIn(this, 0);
  mic.start();

  amp = new Amplitude(this);
  amp.input(mic);

  fft = new FFT(this, bands);
  fft.input(mic);

  textFont(createFont("Arial", 16));
}
```

### What it does

This initializes the entire system.

### Why it is needed

It connects the microphone to the sound analysis tools and creates the OSC connection.

### If removed

The sketch has no initialized system and nothing useful can happen.

### Connection to rest of program

This sets up the live environment that `draw()` uses every frame.

---

## Block H — `draw()`

```java
void draw() {
  background(15);
  
  analyzeAudio();
  
  if (millis() - lastSendTime >= sendIntervalMs) {
    sendFeaturesToWekinator();
    lastSendTime = millis();
  }
  
  drawUI();
}
```

### What it does

This is the main loop.

### Why it is needed

It keeps the sketch alive in real time.

### What each step means

* `background(15);` clears the screen to a dark color.
* `analyzeAudio();` updates the feature values.
* the `if` statement decides whether enough time has passed to send data again.
* `drawUI();` visualizes the results.

### If removed or changed

Without `draw()`, you lose the real-time behavior.
If `analyzeAudio()` is removed, the values never update.
If `drawUI()` is removed, you cannot see anything.
If the send block is removed, Wekinator receives nothing.

### Connection to rest of program

This is where all the parts are coordinated every frame.

---

## Block I — `analyzeAudio()`

```java
void analyzeAudio() {
  float currentAmp = amp.analyze();
  smoothAmp = lerp(smoothAmp, currentAmp, 1.0 - smoothing);
  features[0] = smoothAmp;

  fft.analyze(spectrum);

  int binSize = bands / numFeatureBands;

  for (int i = 0; i < numFeatureBands; i++) {
    int start = i * binSize;
    int end = min(start + binSize, bands);

    float sum = 0;
    for (int j = start; j < end; j++) {
      sum += spectrum[j];
    }

    float avg = sum / float(end - start);

    smoothBands[i] = lerp(smoothBands[i], avg, 1.0 - smoothing);
    features[i + 1] = smoothBands[i] * 10.0;
  }
}
```

### What it does

This is the core signal-processing block.
It computes the features from the microphone input.

### Why it is needed

Without feature extraction, there is no meaningful data to send to Wekinator.

### Main jobs of this block

1. measure amplitude
2. smooth amplitude
3. run FFT
4. compress 512 spectral bins into 12 averaged bands
5. smooth those band values
6. amplify them slightly for easier use and display
7. store them into the `features` array

### If removed

The feature vector would remain empty or outdated.
The system would stop functioning as an audio feature extractor.

### Connection to rest of program

This function creates the exact values that the visualization and Wekinator both use.

---

## Block J — `sendFeaturesToWekinator()`

```java
void sendFeaturesToWekinator() {
  OscMessage msg = new OscMessage("/wek/inputs");

  for (int i = 0; i < features.length; i++) {
    msg.add(features[i]);
  }

  oscP5.send(msg, wekinator);
}
```

### What it does

This packages the current features into an OSC message and sends them to Wekinator.

### Why it is needed

This is the actual machine-learning input transfer.

### If removed

The sketch would still analyze sound and show graphs, but Wekinator would receive nothing.

### Connection to rest of program

This is the output pipeline from Processing to external ML software.

---

## Block K — `drawUI()`

```java
void drawUI() {
  fill(255);
  textSize(24);
  text("Real time sound classification", 30, 40);

  textSize(18);
  text("RMS: " + nf(features[0], 1, 4), 30, 110);

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
```

### What it does

This draws the interface.

### Why it is needed

It lets you see what the sound analysis is doing.
That makes debugging and learning much easier.

### What visual elements it draws

* title text
* current RMS value
* 12 bars for the 12 FFT feature bands
* full green spectrum curve from all 512 FFT bins
* instruction text at the bottom

### If removed

The sketch would still work in the background, but you would lose all visual feedback.

### Connection to rest of program

This is the human-readable side of the sketch.

---

## Block L — `keyPressed()`

```java
void keyPressed() {
  if (key == 't' || key == 'T') {
    print("FEATURES: ");
    for (int i = 0; i < features.length; i++) {
      print(nf(features[i], 1, 4) + " ");
    }
    println();
  }
}
```

### What it does

When you press `T`, it prints the feature vector in the console.

### Why it is needed

This helps you inspect the actual numbers.

### If removed

You lose a useful debugging tool, but the main sketch still works.

### Connection to rest of program

It gives you direct access to the same data being sent to Wekinator.

---

# 4. Line-by-Line Explanation for Important Parts

## Important Part 1 — Microphone and analyzers

```java
mic = new AudioIn(this, 0);
mic.start();

amp = new Amplitude(this);
amp.input(mic);

fft = new FFT(this, bands);
fft.input(mic);
```

### Line 1

`mic = new AudioIn(this, 0);`

* **Syntax:** creates a new `AudioIn` object
* **Meaning:** use audio input device/channel 0
* **Runtime effect:** Processing prepares to access your microphone

### Line 2

`mic.start();`

* **Syntax:** calls the `start()` method
* **Meaning:** begin capturing live audio
* **Runtime effect:** microphone starts feeding signal into the program

### Line 3

`amp = new Amplitude(this);`

* **Syntax:** creates an amplitude analyzer
* **Meaning:** this object can measure loudness
* **Runtime effect:** you now have a tool for measuring audio level

### Line 4

`amp.input(mic);`

* **Syntax:** connects input source to the analyzer
* **Meaning:** analyze the microphone signal
* **Runtime effect:** `amp.analyze()` will use live mic data

### Line 5

`fft = new FFT(this, bands);`

* **Syntax:** creates an FFT analyzer with `bands` bins
* **Meaning:** the spectrum will be split into 512 frequency bins
* **Runtime effect:** program can now measure frequency content

### Line 6

`fft.input(mic);`

* **Syntax:** connects input source to FFT
* **Meaning:** analyze microphone frequencies
* **Runtime effect:** `fft.analyze(spectrum)` fills the spectrum array with live values

---

## Important Part 2 — Amplitude feature

```java
float currentAmp = amp.analyze();
smoothAmp = lerp(smoothAmp, currentAmp, 1.0 - smoothing);
features[0] = smoothAmp;
```

### Line 1

`float currentAmp = amp.analyze();`

* gets the current audio amplitude
* this is essentially a loudness-related measurement
* runtime effect: `currentAmp` becomes a fresh live value

### Line 2

`smoothAmp = lerp(smoothAmp, currentAmp, 1.0 - smoothing);`

* `lerp()` means **linear interpolation**, a smooth transition between two values
* it moves `smoothAmp` a little toward `currentAmp`
* since `smoothing = 0.85`, then `1.0 - smoothing = 0.15`
* so each update uses about 15% of the new value and keeps much of the old value
* runtime effect: loudness changes smoothly instead of shaking wildly

### Line 3

`features[0] = smoothAmp;`

* stores the smoothed amplitude in the first slot of the feature vector
* runtime effect: this becomes input number 1 for Wekinator

---

## Important Part 3 — Reducing FFT from 512 bins to 12 bands

```java
int binSize = bands / numFeatureBands;

for (int i = 0; i < numFeatureBands; i++) {
  int start = i * binSize;
  int end = min(start + binSize, bands);

  float sum = 0;
  for (int j = start; j < end; j++) {
    sum += spectrum[j];
  }

  float avg = sum / float(end - start);
  smoothBands[i] = lerp(smoothBands[i], avg, 1.0 - smoothing);
  features[i + 1] = smoothBands[i] * 10.0;
}
```

### `int binSize = bands / numFeatureBands;`

* calculates how many FFT bins belong to one feature band
* with 512 bands and 12 features, each feature band represents about 42 FFT bins

### Outer loop

`for (int i = 0; i < numFeatureBands; i++)`

* repeats once for each of the 12 feature bands
* runtime effect: the program constructs feature band 1, then 2, then 3, and so on

### `int start = i * binSize;`

* finds where this group starts inside the 512 FFT bins

### `int end = min(start + binSize, bands);`

* finds where this group ends
* `min(...)` prevents going outside the array

### `float sum = 0;`

* starts accumulation for averaging

### Inner loop

`for (int j = start; j < end; j++)`

* visits every FFT bin in this group
* adds their energy together

### `float avg = sum / float(end - start);`

* computes the average energy for the group
* this compresses many FFT bins into one simpler value

### `smoothBands[i] = lerp(...)`

* smooths each grouped spectral band

### `features[i + 1] = smoothBands[i] * 10.0;`

* stores the smoothed band into the features array
* uses `i + 1` because index 0 is reserved for amplitude
* multiplies by 10 to make small FFT values more usable and visible

---

## Important Part 4 — Sending OSC

```java
OscMessage msg = new OscMessage("/wek/inputs");

for (int i = 0; i < features.length; i++) {
  msg.add(features[i]);
}

oscP5.send(msg, wekinator);
```

### Line 1

Creates a message whose OSC address is `/wek/inputs`.
Wekinator expects inputs at that address.

### Loop

Adds all 13 features to the message one by one.

### Final line

Sends the message to the destination stored in `wekinator`, which is `127.0.0.1:6448`.

That means the data is sent to the same computer, to port 6448.

---

# 5. Variables and Data

## `AudioIn mic`

* stores the live microphone input object
* exists so the sketch can listen to sound
* does not store a single number; it represents an active audio source
* used in `setup()` and as input to `amp` and `fft`
* this is **input infrastructure**

## `Amplitude amp`

* stores the analyzer for amplitude
* exists so the sketch can measure loudness
* used in `analyzeAudio()`
* this is **analysis infrastructure**

## `FFT fft`

* stores the FFT analyzer
* exists so the sketch can measure spectral content
* used in `analyzeAudio()`
* this is **analysis infrastructure**

## `int bands = 512`

* stores the number of FFT bins
* exists to define spectral resolution
* if changed, FFT detail changes
* this is a **configuration variable**

## `float[] spectrum`

* stores the 512 live FFT values
* filled every frame by `fft.analyze(spectrum)`
* used for feature reduction and for drawing the green spectrum line
* this is **intermediate data**

## `int numFeatureBands = 12`

* stores the number of reduced spectral features
* exists to control the size of the ML input vector
* if changed, the number of ML inputs changes
* this is a **configuration variable**

## `float[] features`

* stores the final feature vector
* `features[0]` is amplitude
* `features[1]` to `features[12]` are reduced spectral bands
* used in sending, drawing, and printing
* this is the main **output feature data**

## `float smoothAmp`

* stores the smoothed amplitude value
* exists to reduce noisy jumps
* updated every frame
* used to fill `features[0]`
* this is **intermediate data**

## `float[] smoothBands`

* stores smoothed FFT band values
* exists to stabilize the spectral features
* updated every frame
* used to fill `features[1..12]`
* this is **intermediate data**

## `float smoothing = 0.85`

* controls smoothing strength
* higher means smoother but slower response
* lower means faster but more jittery response
* this is a **control parameter**

## `OscP5 oscP5`

* manages OSC communication
* this is **communication infrastructure**

## `NetAddress wekinator`

* stores the destination network address
* tells the sketch where to send the OSC message
* this is **communication infrastructure**

## `int receivePort = 12001`

* incoming OSC port for Processing
* not heavily used in this version because receiving code is commented out
* this is a **configuration variable**

## `int sendPort = 6448`

* outgoing destination port for Wekinator input
* must match Wekinator settings
* this is a **configuration variable**

## `int sendIntervalMs = 30`

* how often to send features
* 30 milliseconds between sends
* this is a **timing control variable**

## `int lastSendTime = 0`

* stores the last sending time
* used with `millis()` to decide when to send again
* this is **state data**

---

# 6. Functions

## `setup()`

### What this function does

Initializes the window, OSC, microphone, amplitude analyzer, FFT analyzer, and font.

### When it runs

Once, at the beginning.

### What input it receives

No explicit input parameters.

### What output or effect it creates

It prepares the sketch so real-time audio analysis can begin.

### Contribution to the full sketch

Without it, nothing is ready.

---

## `draw()`

### What this function does

Runs the main real-time loop.

### When it runs

Continuously after `setup()`.

### Input

No explicit parameters.

### Output/effect

Updates analysis, sends features, redraws the interface.

### Contribution

It is the live engine of the sketch.

---

## `analyzeAudio()`

### What this function does

Extracts amplitude and spectral features from live sound.

### When it runs

Every frame inside `draw()`.

### Input

Uses the current live microphone signal indirectly through `amp` and `fft`.

### Output/effect

Updates `features`, `smoothAmp`, `smoothBands`, and `spectrum`.

### Contribution

This is the core feature extraction function.

---

## `sendFeaturesToWekinator()`

### What this function does

Builds and sends the OSC message.

### When it runs

Every 30 milliseconds, controlled inside `draw()`.

### Input

Uses the current `features` array.

### Output/effect

Sends the 13 features to Wekinator.

### Contribution

This connects Processing to machine learning.

---

## `drawUI()`

### What this function does

Draws all on-screen visual feedback.

### When it runs

Every frame inside `draw()`.

### Input

Uses `features`, `spectrum`, and display configuration variables.

### Output/effect

Draws text, bars, and spectrum curve.

### Contribution

This makes the system understandable to the user.

---

## `keyPressed()`

### What this function does

Prints features when `T` is pressed.

### When it runs

Whenever a key is pressed.

### Input

The current keyboard key.

### Output/effect

Console output of feature values.

### Contribution

Helpful for debugging and learning.

---

# 7. Logic and Computation

## How decisions are made

The main decision in the code is:

```java
if (millis() - lastSendTime >= sendIntervalMs)
```

This checks whether enough time has passed since the last OSC send.
If yes, send again.
If no, wait.

So the program does not send continuously without limit. It sends at a controlled rate.

## How loops work

There are two important loops.

### Loop 1 — feature-band construction

The outer loop runs 12 times, once for each reduced spectral feature.

### Loop 2 — averaging FFT bins inside each feature band

The inner loop visits all FFT bins belonging to the current group and adds them up.
Then the code calculates their average.

So logically:

* 512 detailed FFT bins come in
* they are grouped into 12 larger regions
* one average value is produced for each region

## How comparisons work

The timing condition compares elapsed time with the target interval.

## How sound is calculated

### Amplitude

`amp.analyze()` measures overall strength of the signal.
This is related to loudness.

### Spectrum

`fft.analyze(spectrum)` measures how much energy exists at different frequencies.
This tells you more about the sound’s timbre, meaning its frequency character.

For example:

* a low hum and a whistle may have similar loudness
* but their frequency distributions are very different
* FFT helps distinguish them

## What smoothing means mathematically

The code uses:

```java
lerp(oldValue, newValue, 0.15)
```

This means:

* keep most of the old value
* move partway toward the new value

So smoothing is a kind of weighted averaging over time.
It acts like a soft filter against sudden jumps.

## What `* 10.0` means

FFT values can be quite small.
Multiplying by `10.0` makes them larger and easier to use for display and machine learning.
It is a scaling step.

## What thresholds or limits are used

### `constrain(features[i + 1], 0, 1.5)`

This limits bar values so they stay visually reasonable.
Even if the real value becomes large, the bar display is capped at 1.5.

### `map(...)`

This converts one range into another.
For example, a feature value between `0` and `1.5` becomes a bar height between `0` and `maxH`.

---

# 8. What I Will See When I Run It

When the sketch runs, you should expect the following:

## On the screen

* a dark background
* a title saying **Real time sound classification**
* a text label showing the current RMS/amplitude value
* 12 vertical blue bars representing the reduced FFT features
* a green spectrum curve showing the full 512-bin FFT
* text at the bottom saying OSC is sent to `/wek/inputs`
* text telling you to press `T` to print feature values

## When there is silence

* RMS will be low
* most bars will be low
* the green spectrum curve will stay near the bottom

## When you speak or make sounds

* RMS will rise and fall depending on loudness
* some bars will rise more than others depending on which frequencies are present
* the green spectrum curve will change shape in real time

## When you make different kinds of sounds

For example:

* a low sound may activate lower-frequency bins more strongly
* a sharp hiss may activate higher-frequency bins more strongly
* a clap may create a broad, sudden spectral response

## In the background

The sketch is repeatedly sending 13 numbers to Wekinator through OSC.
You may not see that directly, but it is happening continuously.

## If you press `T`

The console will print something like:

```text
FEATURES: 0.0231 0.1120 0.0873 ...
```

That is the exact feature vector at that moment.

---

# 9. Practical Interpretation

Let us translate the code into very practical language.

* **this part opens the microphone**

  * `mic = new AudioIn(this, 0);`
  * `mic.start();`

* **this part measures how loud the sound is**

  * `amp.analyze()`

* **this part calculates the frequency content of the sound**

  * `fft.analyze(spectrum)`

* **this part reduces 512 detailed frequency bins into 12 simpler features**

  * the averaging loop inside `analyzeAudio()`

* **this part smooths the values so they do not shake too much**

  * `lerp(...)`

* **this part stores the final machine-learning input values**

  * `features[0] = smoothAmp;`
  * `features[i + 1] = smoothBands[i] * 10.0;`

* **this part sends the features to Wekinator**

  * `sendFeaturesToWekinator()`

* **this part draws the bars and graph**

  * `drawUI()`

* **this part lets you inspect the numbers manually**

  * `keyPressed()`

So as a working system, this sketch is basically:

**live sound in → feature extraction → screen visualization → OSC output to Wekinator**

---

# 10. Probable Questions a Student Might Ask

## 1. Why do we need both `setup()` and `draw()`?

`setup()` is for one-time preparation. `draw()` is for repeated live updating. If you put everything in `setup()`, it would happen only once. Sound analysis needs to keep updating, so it must happen in `draw()`.

## 2. Why is the `features` variable an array?

Because there is not just one input value. The code produces multiple inputs: one loudness feature and twelve spectral features. An array is a convenient container for many related values.

## 3. Why are there 13 features instead of 12?

Because the first feature is amplitude/RMS, and the next 12 are FFT-based spectral bands.

## 4. Why not send all 512 FFT bins to Wekinator?

You could, but that would create a much larger input space. More inputs can make training harder, slower, and noisier. Grouping into 12 bands is simpler and often more practical.

## 5. What is FFT in simple words?

FFT is a method that breaks sound into frequency ingredients. It tells us how much low, medium, and high-frequency energy is present.

## 6. What does RMS mean here?

Strictly speaking, the code uses `Amplitude`, which behaves like a loudness/amplitude measurement. In practice, it is being used as a measure of how strong the sound is overall.

## 7. Why do we smooth the values?

Because live audio changes very quickly and can be noisy. Smoothing helps create more stable features and more readable graphics.

## 8. What does `lerp()` do?

It gradually moves one value toward another. Here it acts like a simple low-pass smoothing filter over time.

## 9. Why multiply the FFT feature by `10.0`?

Because FFT averages may be very small. Multiplying makes them easier to visualize and use.

## 10. Why do we use `features[i + 1]` and not `features[i]`?

Because `features[0]` is already reserved for amplitude. The FFT features start from index 1.

## 11. Why do we send OSC every 30 milliseconds?

Because sending on every frame may be too dependent on frame rate. A fixed interval gives steadier communication.

## 12. Is this code already doing classification?

No. This code is not making the class decision. It only extracts and sends the input features. Wekinator is the part that learns and predicts.

## 13. Why is the window title saying “classifier” if the code does not classify by itself?

Because the full system is intended for sound classification, but in this sketch the classification step is external, handled by Wekinator.

## 14. What happens if Wekinator is not open?

The sketch will still run, analyze sound, and draw graphics. The OSC messages will be sent, but nothing useful will receive them.

## 15. Why is there a receive port if I do not see prediction code?

Because the sketch may have been planned to receive predictions back from Wekinator. In fact, there are commented lines for a predicted class and label, which suggests this feature may be added later.

---

# 11. Common Confusions and Mistakes

## Confusion 1 — “Processing is doing the machine learning.”

Correct understanding: Processing is **not** training the model here. It is only extracting and sending input features. Wekinator is the machine learning tool.

## Confusion 2 — “The 12 bars are the full FFT.”

Correct understanding: the 12 bars are **reduced feature bands**, not the full FFT. The full FFT is the green spectrum line with 512 bins.

## Confusion 3 — “Amplitude and FFT are the same thing.”

Correct understanding: amplitude measures overall signal strength, while FFT measures how that energy is distributed across frequencies.

## Confusion 4 — “Higher smoothing means faster response.”

Correct understanding: higher smoothing here means the new value influences the result less, so the response becomes slower and smoother.

## Confusion 5 — “The code prints classification results when I press T.”

Correct understanding: pressing `T` prints the current feature values, not predicted classes.

## Confusion 6 — “If the bars move, that means Wekinator is learning.”

Correct understanding: moving bars only show that audio analysis is working. Wekinator learning is a separate process that happens inside Wekinator.

## Confusion 7 — “There are 12 inputs because there are 12 bars.”

Correct understanding: there are actually **13 inputs** in total: 1 amplitude feature + 12 spectral features.

## Confusion 8 — “The receive port means predictions are already coming back.”

Correct understanding: not in this version. The receiving part seems prepared conceptually but is not implemented here.

---

# 12. If This Code Is Related to Machine Learning or Wekinator

Yes, it is directly related.

## Role of Processing

Processing is responsible for:

* capturing live microphone audio
* extracting features from that audio
* smoothing those features
* visualizing them
* sending them through OSC

## Role of Wekinator

Wekinator is responsible for:

* receiving the features as inputs
* learning a mapping from inputs to outputs during training
* producing predictions during running mode

## What Processing is extracting or sending

Processing sends:

* 1 amplitude feature
* 12 grouped FFT features

So Processing sends **13 input values total**.

## How many inputs and outputs this code implies

### Inputs to Wekinator

* **13 inputs**

### Outputs

This code does **not** define the outputs itself.
The outputs depend on how you configure Wekinator.
For example:

* if you train 3 classes, Wekinator may output 1 class label or one-hot-like values depending on setup
* if you do regression, Wekinator may output one or more continuous values

## Is it classification, regression, or only feature extraction?

This code itself is **only feature extraction + sending**.
But because of the title and intended context, it is clearly designed for a **classification workflow** with Wekinator.

So the clearest answer is:

* **Processing side:** feature extraction only
* **overall system intention:** sound classification with Wekinator

## Important separation

A beginner must understand this very clearly:

### Processing does:

“Here are 13 numbers that describe the current sound.”

### Wekinator does:

“When I see those kinds of numbers, I predict class A, B, or C.”

That separation is one of the most important ideas in this whole project.

---

# 13. Simple Summary

## 5-sentence simple summary

This Processing sketch listens to live sound from the microphone. It calculates one loudness feature and twelve frequency-based features using FFT. It smooths those values so they are more stable. Then it shows them on screen and sends them to Wekinator through OSC. The sketch itself does not classify sounds; it prepares the inputs for a machine learning system.

## One-paragraph conceptual summary

Conceptually, this code is a bridge between raw sound and machine learning. Raw microphone audio is too complex to send directly in a useful way, so the sketch transforms it into a smaller set of meaningful numerical features: one feature describing overall signal strength and twelve features describing spectral content. Those features are smoothed to reduce noise, visualized to help the user understand what is happening, and transmitted by OSC so that Wekinator can learn how different sounds correspond to different outputs. In that sense, the sketch is an audio front-end for an interactive ML system.

## One-sentence summary of the code’s purpose

This sketch captures live sound, extracts 13 audio features, visualizes them, and sends them to Wekinator for machine-learning use.

---

# 14. Final Check

## The 3 most important ideas you must understand from this code

1. This sketch is mainly a **feature extractor**, not the classifier itself.
2. The code turns live microphone sound into **13 numerical inputs**: 1 amplitude value and 12 reduced FFT values.
3. Those inputs are sent by **OSC** to Wekinator, which is the part that can learn and classify.

## The 3 most important lines or code blocks

### 1. Microphone + analyzers setup

```java
mic = new AudioIn(this, 0);
mic.start();
amp.input(mic);
fft.input(mic);
```

This makes live audio analysis possible.

### 2. Feature extraction block

```java
float currentAmp = amp.analyze();
fft.analyze(spectrum);
features[i + 1] = smoothBands[i] * 10.0;
```

This is where raw sound becomes meaningful machine-learning inputs.

### 3. OSC sending block

```java
OscMessage msg = new OscMessage("/wek/inputs");
msg.add(features[i]);
oscP5.send(msg, wekinator);
```

This is where the features leave Processing and go to Wekinator.

## The 3 best follow-up questions you should ask next

1. How exactly do the 12 FFT feature bands correspond to low, medium, and high frequencies?
2. How should I configure Wekinator to match these 13 inputs correctly?
3. How can I modify this code so Processing also receives the predicted class back from Wekinator and shows it on the screen?

---

# Extra Teaching Note

There are commented lines in the sketch:

```java
//int predictedClass = -1;
//String predictedLabel = "nessuna";
```

and also a commented UI line:

```java
//text("Pedicted class: " + predictedLabel + " (" + predictedClass + ")", 30, 80);
```

This strongly suggests the sketch was intended to later receive classification results back from Wekinator and display them. But in the current version, that part is not active yet. So right now the code is a sender and visualizer, not a full closed-loop classifier interface.
