# README — Deep Explanation of `SoundLabeling.pde`

## 1. BIG PICTURE FIRST

This Processing sketch is a **real-time visual receiver and sound label display system**.

In plain English, here is what the whole code is supposed to do:

* Another program, most likely **Wekinator**, listens to sound and decides what class the sound belongs to.
* That predicted class is sent into Processing through **OSC**.
* This Processing sketch receives that class.
* Then it updates the screen with a different animated visual style depending on the detected class.
* It also shows a large label such as **CLAP**, **SNAP**, or **VOICE** in the center of the screen.

So the purpose of this sketch is **not to analyze audio directly**, but to **visualize the result of sound classification**.

### What input does this sketch use?

This sketch uses:

* **OSC messages** arriving on port `12000`
* specifically messages with address pattern: `/wek/outputs`
* the first value inside the message is treated as the predicted class

### What output does it produce?

It produces:

* a graphical animated screen
* a different background style for each class
* particles and motion effects
* a text label in the center indicating the detected sound class

### External tools involved

Yes — this sketch clearly interacts with external tools:

#### Processing’s role

Processing is responsible for:

* receiving OSC data
* storing the detected class
* updating animations
* drawing visuals
* displaying the label

#### Wekinator’s role

Wekinator is expected to:

* receive sound features from another Processing sketch or audio-analysis system
* learn the mapping between sound examples and classes
* output a class prediction such as:

  * `1 = clap`
  * `2 = snap`
  * `3 = voice`

So this code is best understood as the **visual output stage** of a machine learning interactive system.

---

## 2. OVERALL FLOW OF THE PROGRAM

Let us walk through the flow from start to finish.

### Step 1: Global variables are created

At the top of the file, the program creates variables for:

* OSC communication
* the current predicted class
* the previous class
* the current text label
* animation values
* particles

This means the sketch prepares memory before anything starts drawing.

### Step 2: `setup()` runs once

When the sketch starts, `setup()` runs only one time.
It:

* creates the window
* enables smoothing
* starts the OSC receiver on port `12000`
* sets text alignment and drawing modes

So `setup()` is where the sketch gets ready.

### Step 3: `draw()` runs continuously

After `setup()`, Processing repeatedly calls `draw()` many times per second.

Every frame, the sketch does these things in order:

1. update animation values and particles
2. draw the background based on the current class
3. draw all particles
4. draw the center visual shape
5. draw the text label

That means the screen is being rebuilt continuously.

### Step 4: `oscEvent()` runs only when a message arrives

This is an event function.
It does **not** run continuously like `draw()`.
It runs only when an OSC message reaches the sketch.

When a message arrives:

* it checks whether the message address is `/wek/outputs`
* it reads the first number from the message
* it rounds that number to an integer class
* if the class changed, it updates the label and triggers a burst effect

So `oscEvent()` is the place where the sketch reacts to the outside world.

### Step 5: Visual state changes according to the class

The variable `predictedClass` controls almost everything:

* background style
* center geometry
* colors
* particle motion
* label text

That means the class value acts like the main control signal for the entire visual system.

---

## 3. BLOCK-BY-BLOCK EXPLANATION

## Block A — Imports and OSC setup

```java
import oscP5.*;
import netP5.*;
import java.util.ArrayList;

OscP5 oscP5;
```

### What this does

This imports the libraries needed for:

* OSC communication (`oscP5`, `netP5`)
* dynamic lists of particles (`ArrayList`)

### Why it is needed

Without these imports:

* the sketch cannot receive OSC messages
* the particle list cannot be used as written

### What would happen if removed?

* removing OSC imports would make `OscP5`, `OscMessage`, and network features fail
* removing `ArrayList` would break the particle system

### How it connects to the rest

These imports support two major systems:

* communication from Wekinator
* particle animation storage

---

## Block B — Class meaning and main state

```java
// ----------------------
// CLASSES
// 1 = clap
// 2 = snap
// 3 = voice
// ----------------------
int predictedClass = 0;
int previousClass = 0;

String currentLabel = "SILENCE";
```

### What this does

This defines the sound classes the sketch expects.
It also stores:

* `predictedClass`: the class currently being displayed
* `previousClass`: the class from before the most recent change
* `currentLabel`: the text currently shown on screen

### Why it is needed

The sketch needs a central state variable so it knows what to draw.

### Important practical meaning

* `0` means “nothing classified yet” or idle state
* `1` means clap
* `2` means snap
* `3` means voice

### What if it were changed?

If these class meanings do not match Wekinator’s outputs, the sketch will display the wrong visuals and wrong labels.

### Important observation

`previousClass` is updated when the class changes, but in this version of the code it is **not used elsewhere**. So it looks like the programmer intended to use it for future transitions or comparisons.

---

## Block C — Animation variables and particle container

```java
// text animation
float textPulse = 0;
float bgPulse = 0;
float transition = 0;

// particles
ArrayList<Particle> particles = new ArrayList<Particle>();
```

### What this does

These variables control animation over time:

* `textPulse` drives pulsing movement in text and visuals
* `bgPulse` drives slower background motion
* `transition` creates a temporary flash when class changes
* `particles` stores many small animated objects

### Why it is needed

Without these values, the visuals would be static and much less expressive.

### What if removed?

* no pulsing
* no transition flash
* no particle effects
* the sketch would still work, but would feel far more flat

---

## Block D — `setup()`

```java
void setup() {
  size(1000, 700, P2D);
  smooth(8);
  oscP5 = new OscP5(this, 12000);

  textAlign(CENTER, CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);
}
```

### What this does

This initializes the sketch.

### Explanation

* `size(1000, 700, P2D);` creates a window 1000 by 700 pixels and uses the `P2D` renderer
* `smooth(8);` improves visual quality
* `oscP5 = new OscP5(this, 12000);` opens OSC listening on port `12000`
* `textAlign(CENTER, CENTER);` centers text drawing
* `rectMode(CENTER);` makes rectangles draw from their center point
* `ellipseMode(CENTER);` makes ellipses draw from their center point

### Why it is needed

This is the one-time configuration stage.

### What if removed?

* without `size()`, there is no window
* without OSC setup, no classification messages arrive
* without center modes, many visuals would be positioned differently

---

## Block E — `draw()` main loop

```java
void draw() {
  updateAnimation();
  drawBackgroundByClass();
  drawParticles();
  drawCenterVisual();
  drawFancyLabel();
}
```

### What this does

This is the heart of the real-time visual system.

### Why it is needed

Processing redraws the screen continuously through `draw()`.
This lets the screen react frame by frame.

### Why this order matters

The order is important:

1. update data first
2. draw background next
3. draw particles on top of background
4. draw central shape on top of that
5. draw text last so it stays visible

### What if order changed?

If text were drawn before the background, it would be covered up.
If particles were drawn before the background, they would disappear behind it.

---

## Block F — OSC receiver

```java
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
```

### What this does

This function receives an OSC message and updates the visual state when a new class arrives.

### Why it is needed

This is how Processing learns what Wekinator predicted.
Without this function, the sketch would stay in its default state forever.

### Practical meaning

This block is basically saying:

> “If Wekinator says the class is clap, snap, or voice, update the screen to match that class.”

### What would happen if removed?

* the sketch would not respond to incoming predictions
* `predictedClass` would remain `0`
* the sketch would stay in the idle/silence visual state

### Why only update when class changes?

The line:

```java
if (incomingClass != predictedClass)
```

prevents unnecessary repeated triggering.
That means if Wekinator keeps sending `1, 1, 1, 1`, the burst effect is triggered only when the class first changes to `1`.
This avoids constant restarting of transitions.

---

## Block G — Class label conversion

```java
String classToLabel(int c) {
  if (c == 1) return "CLAP";
  if (c == 2) return "SNAP";
  if (c == 3) return "VOICE";
  return "CLASSE " + c;
}
```

### What this does

This converts a numeric class into human-readable text.

### Why it is needed

Humans understand words more easily than raw numbers.

### Important practical meaning

If Wekinator outputs `2`, the screen shows `SNAP`.

### What if changed?

If you rename labels here, the text shown on screen changes.
If Wekinator uses different class numbers, this function must be updated to match.

### Small detail

The fallback text is in Italian: `CLASSE` means `CLASS`.

---

## Block H — Animation updating

```java
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
```

### What this does

This function updates everything that changes over time.

### What each part means

* `textPulse += 0.08;` advances a time value for pulsing text and visuals
* `bgPulse += 0.02;` advances a slower time value for background motion
* `transition *= 0.92;` gradually fades the transition flash
* the `for` loop updates each particle and removes dead ones
* every 4 frames, a new particle is added near the center

### Why it is needed

Animation only works if values change frame by frame.

### Why loop backward?

The loop starts from the end and moves backward because particles may be removed during the loop.
If you remove items while looping forward, indexes can shift and cause errors or skipped particles.

### What if removed?

* no particle motion
* no fading transition
* no pulsing
* no new particles being generated

---

## Block I — Background by class

```java
void drawBackgroundByClass() {
  noStroke();

  if (predictedClass == 0) {
    ...
  }
  else if (predictedClass == 1) {
    ...
  }
  else if (predictedClass == 2) {
    ...
  }
  else if (predictedClass == 3) {
    ...
  }

  if (transition > 0.01) {
    fill(255, 255 * transition * 0.15);
    rect(width/2, height/2, width, height);
  }
}
```

### What this does

This draws a different background atmosphere depending on the class.

### Meaning of each class visually

#### Class 0 — idle / silence

* dark blue background
* floating soft circles
* calm and ambient feeling

#### Class 1 — clap

* purple/dark red background
* expanding circular rings
* radial, explosive feel

#### Class 2 — snap

* blue background
* random short lines
* sharper, more electric feeling

#### Class 3 — voice

* warm dark red background
* orbiting glowing circles
* organic, flowing feel

### Why it is needed

This gives each sound class its own visual identity.

### What would happen if removed?

The center visual and label would still change, but the atmosphere would be much weaker.

### Transition flash

The last rectangle creates a temporary bright flash when the class changes.
It fades because `transition` gets smaller over time.

---

## Block J — Center visual

```java
void drawCenterVisual() {
  pushMatrix();
  translate(width/2, height/2);

  float pulse = 1.0 + 0.08 * sin(textPulse * 2.5);

  noStroke();

  if (predictedClass == 0) {
    ...
  }
  else if (predictedClass == 1) {
    ...
  }
  else if (predictedClass == 2) {
    ...
  }
  else if (predictedClass == 3) {
    ...
  }

  popMatrix();
}
```

### What this does

This draws the main animated symbol in the center.

### Why it is needed

The center visual acts like the main emblem of the current sound class.
It makes the detected class feel immediate and expressive.

### Why `translate(width/2, height/2)`?

Instead of calculating the center in every shape, the code moves the coordinate system so `(0, 0)` becomes the center of the screen.
That makes centered drawing much easier.

### Why `pushMatrix()` and `popMatrix()`?

These save and restore the coordinate system so the translation and rotation inside this function do not affect the rest of the sketch.

---

## Block K — Fancy label text

```java
void drawFancyLabel() {
  float s = 92 + 10 * sin(textPulse * 3.0) + transition * 30;

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
```

### What this does

This draws the big label in the center and gives it a glow effect.

### How the glow works

The loop draws the same text several times at slightly larger sizes and low transparency.
That creates a halo or glow behind the main white text.

### Why it is needed

Without this function, the user would not clearly see the detected class as text.

### Practical meaning

* the main label is the detected class
* the text grows and shrinks slightly over time
* when class changes, `transition * 30` makes it pop larger for a moment
* the small text `classe rilevata` means “detected class”

---

## Block L — Label color functions

```java
float labelR() { ... }
float labelG() { ... }
float labelB() { ... }
```

### What this does

These functions return the red, green, and blue values used for the label glow color.

### Why it is needed

Instead of writing color logic repeatedly, the programmer separated it into reusable functions.

### What if removed?

The glow effect would need to use hard-coded values directly inside `drawFancyLabel()`.
That would make the code less organized.

---

## Block M — Trigger burst effect

```java
void triggerClassEffect(int c) {
  for (int i = 0; i < 40; i++) {
    particles.add(new Particle(width/2, height/2, c));
  }
}
```

### What this does

When the class changes, this creates 40 particles at the center.

### Why it is needed

This gives immediate feedback that a new class has been detected.

### Practical meaning

It is like a visual “impact” or “burst” that announces the class change.

### What if removed?

The sketch would still switch visuals, but the transition would feel less dramatic and responsive.

---

## Block N — Particle class

```java
class Particle {
  float x, y;
  float vx, vy;
  float life;
  float size;
  int type;
  ...
}
```

### What this does

This defines a custom object called `Particle`.
Each particle has:

* position: `x`, `y`
* velocity: `vx`, `vy`
* remaining life: `life`
* size
* type, which matches the class style

### Why it is needed

This lets the sketch create many small moving visual elements in a structured way.

### What if removed?

All particle behavior would need to be handled manually with arrays or separate variables, which would be much harder to manage.

---

## Block O — Particle constructor

```java
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
```

### What this does

This sets the starting values of a new particle.

### Practical meaning of motion styles

* type `0`: slow drift
* type `1`: outward burst in random direction
* type `2`: fast jittery motion
* type `3`: medium motion that later becomes wavy

### Why it is needed

Different classes should feel different, so particles are initialized differently depending on the class.

---

## Block P — Particle update

```java
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
```

### What this does

This moves the particle and ages it every frame.

### Why it is needed

Without this, particles would just stay frozen.

### Important logic

* every particle moves by velocity first
* then each type has its own behavior
* particles lose life over time
* when life reaches zero, the particle is removed

### Interesting detail

Type 1 particles slow down over time because velocity is multiplied by `0.97`.
This simulates friction or drag.

---

## Block Q — Particle drawing and death check

```java
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
```

### What this does

* `display()` draws the particle
* `dead()` tells whether the particle should be removed

### Why it is needed

This keeps the particle system manageable and efficient.
If dead particles were never removed, the list would grow forever.

---

## Block R — Draw all particles

```java
void drawParticles() {
  for (Particle p : particles) {
    p.display();
  }
}
```

### What this does

This draws every particle currently stored in the list.

### Why it is needed

The particles are updated in `updateAnimation()`, but they need a separate step to be rendered.

---

## 4. LINE-BY-LINE EXPLANATION FOR IMPORTANT PARTS

## Important Part 1 — OSC input

```java
void oscEvent(OscMessage msg) {
```

This defines a function named `oscEvent`.
In Processing with oscP5, this is called automatically when an OSC message arrives.
The parameter `msg` stores the incoming message.

```java
if (msg.checkAddrPattern("/wek/outputs")) {
```

This checks whether the message address is `/wek/outputs`.
This is important because many OSC messages could arrive, and the sketch only wants the ones coming from Wekinator’s outputs.

```java
if (msg.typetag().length() > 0) {
```

This checks whether the message contains at least one value.
It prevents trying to read data from an empty message.

```java
int incomingClass = round(msg.get(0).floatValue());
```

This reads the first value in the OSC message, converts it to a float, rounds it, and stores it as an integer.
That means even if Wekinator sends `1.0`, it becomes integer `1`.

```java
if (incomingClass != predictedClass) {
```

This checks whether the new class is different from the currently displayed class.
Only changes trigger updates.

```java
previousClass = predictedClass;
```

Before changing the class, the old value is saved.

```java
predictedClass = incomingClass;
```

Now the new detected class becomes the current one.

```java
currentLabel = classToLabel(predictedClass);
```

This converts the class number into a word like `CLAP`.

```java
triggerClassEffect(predictedClass);
```

This creates an immediate particle burst.

```java
transition = 1.0;
```

This starts the transition flash at full strength.

---

## Important Part 2 — Main draw loop

```java
void draw() {
  updateAnimation();
  drawBackgroundByClass();
  drawParticles();
  drawCenterVisual();
  drawFancyLabel();
}
```

### Runtime effect of each line

* `updateAnimation();` changes time-based values and particle state
* `drawBackgroundByClass();` paints the entire background depending on the class
* `drawParticles();` draws floating particles on top
* `drawCenterVisual();` draws the main symbolic shape
* `drawFancyLabel();` writes the class name on top of everything

This is a layered drawing pipeline.

---

## Important Part 3 — Particle lifecycle

```java
for (int i = particles.size() - 1; i >= 0; i--) {
  Particle p = particles.get(i);
  p.update();
  if (p.dead()) {
    particles.remove(i);
  }
}
```

### Syntax meaning

* `particles.size() - 1` starts from the last particle
* `i >= 0` continues until the first particle
* `i--` moves backward one index at a time
* `particles.get(i)` accesses a specific particle
* `p.update()` changes its state
* `p.dead()` checks whether it should be deleted

### Runtime effect

Each frame:

* every particle moves
* every particle loses life
* dead particles are removed from memory

This is the cleanup system of the particle engine.

---

## 5. VARIABLES AND DATA

## `OscP5 oscP5`

* stores the OSC receiver object
* exists so the sketch can listen for network messages
* created in `setup()`
* used indirectly when `oscEvent()` is triggered
* type: communication infrastructure

## `int predictedClass`

* stores the class currently active on screen
* values: usually `0`, `1`, `2`, or `3`
* changes when OSC input arrives
* used in nearly every drawing function
* type: input-derived control state

## `int previousClass`

* stores the class from before the latest update
* changes only when class changes
* currently not used elsewhere in this sketch
* type: history/intermediate state

## `String currentLabel`

* stores the text shown in the center
* starts as `SILENCE`
* changes through `classToLabel()`
* used in `drawFancyLabel()`
* type: output text state

## `float textPulse`

* stores a time-like animation value
* continuously increases in `updateAnimation()`
* used with `sin()` to create pulsing motion
* type: intermediate animation data

## `float bgPulse`

* stores a slower animation value for background movement
* continuously increases
* used in background calculations
* type: intermediate animation data

## `float transition`

* stores the strength of the class-change flash/pop effect
* set to `1.0` when class changes
* multiplied by `0.92` every frame so it fades out
* used in background flash and text sizing
* type: temporary transition state

## `ArrayList<Particle> particles`

* stores all active particles
* new particles are added over time and during transitions
* dead particles are removed
* used in `updateAnimation()` and `drawParticles()`
* type: dynamic visual object collection

## Particle variables

### `x`, `y`

position of the particle

### `vx`, `vy`

movement speed in horizontal and vertical directions

### `life`

how much life remains before disappearing

### `size`

particle diameter

### `type`

which class style this particle belongs to

---

## 6. FUNCTIONS

## `setup()`

### What it does

Initializes window, drawing modes, and OSC receiver.

### When it runs

Once at the beginning.

### Input

No explicit input.

### Output/effect

Creates the visual environment and opens OSC port `12000`.

### Contribution

Makes the sketch ready to run.

## `draw()`

### What it does

Continuously updates and redraws the entire scene.

### When it runs

Every frame.

### Input

Uses current global state.

### Output/effect

Produces the animated screen.

### Contribution

Main engine of the sketch.

## `oscEvent(OscMessage msg)`

### What it does

Receives OSC messages and updates the class state.

### When it runs

Only when OSC data arrives.

### Input

An incoming OSC message.

### Output/effect

Changes class, label, particles, and transition flash.

### Contribution

Connects external machine learning output to the visuals.

## `classToLabel(int c)`

### What it does

Converts a number into text.

### When it runs

When class changes.

### Input

An integer class value.

### Output/effect

Returns a label string.

### Contribution

Makes the class readable for the user.

## `updateAnimation()`

### What it does

Advances time variables, updates particles, removes dead particles, and spawns new ones.

### When it runs

Every frame.

### Input

Uses frame count and current class.

### Output/effect

Keeps the animation alive.

### Contribution

Maintains motion and transition behavior.

## `drawBackgroundByClass()`

### What it does

Draws the background style for the current class.

### When it runs

Every frame.

### Input

Uses `predictedClass`, `bgPulse`, and `transition`.

### Output/effect

Creates the mood and atmosphere.

### Contribution

Makes class identity visually strong.

## `drawCenterVisual()`

### What it does

Draws the central animated shape.

### When it runs

Every frame.

### Input

Uses class and pulse values.

### Output/effect

Displays a central symbol matching the detected sound.

### Contribution

Main focal visual.

## `drawFancyLabel()`

### What it does

Draws the class label with glow and pulse.

### When it runs

Every frame.

### Input

Uses `currentLabel`, `textPulse`, and `transition`.

### Output/effect

Shows readable class feedback.

### Contribution

Makes the system understandable at a glance.

## `labelR()`, `labelG()`, `labelB()`

### What they do

Return glow color values for the label.

### When they run

Inside `drawFancyLabel()`.

### Input

Implicitly use `predictedClass`.

### Output/effect

Provide color channels.

### Contribution

Keep color logic clean and modular.

## `triggerClassEffect(int c)`

### What it does

Creates a burst of particles for a new class.

### When it runs

Only when class changes.

### Input

Class number.

### Output/effect

Adds 40 particles.

### Contribution

Gives strong feedback on class transitions.

## `Particle(...)`

### What it does

Constructs a new particle with class-specific movement.

### When it runs

Whenever a particle is created.

### Input

Start position and particle type.

### Output/effect

Initializes particle state.

### Contribution

Defines starting behavior of particles.

## `Particle.update()`

### What it does

Moves and ages a particle.

### When it runs

Every frame for each particle.

### Input

Uses particle properties and frame count.

### Output/effect

Changes position and life.

### Contribution

Produces motion.

## `Particle.display()`

### What it does

Draws the particle.

### When it runs

Every frame for each particle.

### Input

Uses particle properties.

### Output/effect

Shows particle on screen.

### Contribution

Makes the particle visible.

## `Particle.dead()`

### What it does

Checks whether particle life is over.

### When it runs

During particle update loop.

### Input

Uses `life`.

### Output/effect

Returns `true` or `false`.

### Contribution

Allows cleanup.

## `drawParticles()`

### What it does

Draws all particles.

### When it runs

Every frame.

### Input

Uses the `particles` list.

### Output/effect

Displays the particle layer.

### Contribution

Renders the particle system.

---

## 7. LOGIC AND COMPUTATION

Now let us explain the logic behind the code.

## How decisions are made

Most decisions are based on this variable:

```java
predictedClass
```

The code uses `if / else if` branches such as:

* if class is `0`, draw idle mode
* if class is `1`, draw clap mode
* if class is `2`, draw snap mode
* if class is `3`, draw voice mode

So the whole visual system is a **state-based system**.
A state-based system means the program has a current state, and the behavior changes depending on that state.

## How loops work

The sketch uses loops for several reasons:

* to draw repeated rings or circles
* to create many particles
* to update all particles
* to draw glow text multiple times

A loop means “repeat the same action several times with slight changes.”

## How pulsing is calculated

The code uses:

```java
sin(textPulse * 2.5)
```

and similar expressions.

`sin()` is a mathematical function that oscillates smoothly between `-1` and `1`.
This is why it is useful for animation.
It creates smooth back-and-forth motion or size changes.

Example:

```java
float pulse = 1.0 + 0.08 * sin(textPulse * 2.5);
```

This means:

* start around `1.0`
* add a small oscillation
* result: scale gently grows and shrinks

## How transition fading works

```java
transition = 1.0;
transition *= 0.92;
```

This is exponential decay.
It means the value shrinks by 8% every frame.
So the flash starts strong and fades smoothly.

## How particles are controlled

Each particle has:

* position
* movement speed
* life
* type

Every frame:

* position is updated
* life decreases
* special class-specific behavior may happen
* particle disappears when life is over

This is a standard particle-system logic.

## How OSC data is interpreted

The code assumes the first OSC output value is the predicted class.
That means this sketch expects a classification result, not a continuous regression value.

Because it rounds the value:

```java
round(msg.get(0).floatValue())
```

it assumes the incoming number should map cleanly to an integer like `1`, `2`, or `3`.

---

## 8. WHAT I WILL SEE WHEN I RUN IT

Here is what you should expect when the sketch runs.

## At startup

You will see:

* a 1000×700 window
* a dark calm background
* a central label saying `SILENCE`
* soft blue ambient visuals
* particles slowly appearing around the center

This is the idle state because `predictedClass` starts at `0`.

## When class 1 is received

If OSC sends class `1`, you should see:

* the background change to purple/dark pink tones
* circular rings around the center
* radial lines shooting outward
* pinkish particles
* the big center text change to `CLAP`
* a momentary flash and burst effect

## When class 2 is received

If OSC sends class `2`, you should see:

* cooler blue background
* many short sharp line segments
* rectangular central geometry
* cyan particles
* the label `SNAP`
* a transition flash and burst

## When class 3 is received

If OSC sends class `3`, you should see:

* warm red/orange atmosphere
* soft orbiting circles
* glowing central blob-like structure
* orange particles with organic movement
* the label `VOICE`
* a transition flash and burst

## What changes over time

Even if the class stays the same:

* background still animates
* center shapes still pulse or rotate
* text gently pulses
* particles keep being generated and fading away

## What happens in the background

The sketch is also constantly listening on OSC port `12000`.
So visually you see animation, but technically it is waiting for incoming predictions.

---

## 9. PRACTICAL INTERPRETATION

Let us explain this code like a working system.

* `oscP5 = new OscP5(this, 12000);`

  * this part opens an OSC receiver so Processing can hear messages from Wekinator

* `oscEvent(...)`

  * this part listens for Wekinator’s classification result

* `incomingClass = round(...)`

  * this part takes the received prediction and turns it into a clean whole-number class

* `currentLabel = classToLabel(predictedClass);`

  * this part converts the numeric class into readable text

* `drawBackgroundByClass();`

  * this part changes the whole mood of the screen based on the sound type

* `drawCenterVisual();`

  * this part draws a unique visual symbol for the current class

* `triggerClassEffect(predictedClass);`

  * this part creates a burst when a new class is detected

* `particles.add(new Particle(...))`

  * this part continuously creates small moving elements to keep the screen alive

* `transition *= 0.92;`

  * this part makes the transition flash fade out gradually instead of disappearing instantly

So in practical terms, this code is:

> “A real-time animated display that turns machine learning sound classifications into a live visual performance.”

---

## 10. Probable Questions a Student Might Ask

### 1. Why do we need `setup()` and `draw()`?

`setup()` runs once and prepares the sketch.
`draw()` runs again and again, so it is used for animation and continuous display.
Without `draw()`, the screen would not animate.

### 2. Why is the class received through OSC instead of being calculated here?

Because this sketch is only the visual receiver.
The machine learning part is expected to happen elsewhere, likely in Wekinator.

### 3. Why is `predictedClass` an integer?

Because classification gives discrete categories such as class 1, 2, or 3.
An integer is a natural way to store such categories.

### 4. Why do we use `round()` on the incoming OSC value?

Wekinator often sends numbers as floats.
Even if it sends `1.0`, Processing reads it as a float.
`round()` converts that to integer `1`.

### 5. Why do we check `incomingClass != predictedClass`?

To avoid re-triggering the same visual burst every time the same class is sent again.
This keeps the animation cleaner.

### 6. Why is `currentLabel` a string when we already have `predictedClass`?

Because the screen should show words like `CLAP` instead of only numbers.
The integer is useful for logic, the string is useful for display.

### 7. Why are particles stored in an `ArrayList`?

Because the number of particles changes all the time.
An `ArrayList` can grow and shrink dynamically.

### 8. Why do we remove particles?

Because they are temporary visual objects.
If we never removed them, memory usage would keep growing and performance would get worse.

### 9. Why do some animations use `sin()`?

Because `sin()` produces smooth repeating motion.
It is very useful for pulses, waves, breathing effects, and oscillation.

### 10. Why are there different colors and shapes for each class?

To make each detected sound feel visually distinct.
This helps the user recognize the class immediately, even before reading the text.

### 11. Is this code doing classification or just displaying it?

This specific code is just displaying the result.
The classification is assumed to be done by Wekinator or another external tool.

### 12. Why does the label start as `SILENCE` but class 0 in `classToLabel()` would return `CLASSE 0`?

Because the initial label is manually set to `SILENCE` before any class update happens.
If class 0 were later sent through OSC and changed the label via `classToLabel(0)`, it would show `CLASSE 0`.
That means the code is slightly inconsistent here.
A clearer version would explicitly map 0 to `SILENCE`.

### 13. Why is `previousClass` there if nothing uses it later?

It was probably added for future use, such as smoother transitions or logging.
In the current sketch, it does not affect visible behavior.

### 14. Why is the text drawn multiple times?

That creates the glow effect.
Drawing the same text with low opacity and different sizes makes it look luminous.

### 15. Why does the loop over particles go backward?

Because the code removes particles during the loop.
Going backward avoids index problems.

---

## 11. Common Confusions and Mistakes

### Confusion 1: “This code is doing sound analysis.”

Not in this file.
This file does not open a microphone, compute FFT, or extract audio features.
It only receives the classification result from elsewhere.

### Confusion 2: “Processing and Wekinator are doing the same job.”

No.
They have different roles.

* Processing here = visualization and OSC receiving
* Wekinator = machine learning prediction

### Confusion 3: “If I run only this sketch, it should classify sounds.”

Not by itself.
You need another system sending OSC predictions to port `12000`.
Without that, the sketch stays mostly in idle mode.

### Confusion 4: “`previousClass` changes the graphics.”

Not in this version.
It is stored, but not actually used in drawing.

### Confusion 5: “Particles are permanent objects.”

No.
They are temporary.
They are born, move, fade, and disappear.

### Confusion 6: “The sketch draws once and keeps the result.”

No.
Processing redraws continuously in `draw()`.
Every frame is rebuilt.

### Confusion 7: “The glow is a built-in text effect.”

No.
The glow is manually created by drawing the text many times.

### Confusion 8: “Class 0 is fully defined like the others.”

Only partly.
It has idle visuals, but the text mapping is not fully consistent because `currentLabel` starts as `SILENCE` while `classToLabel(0)` would return `CLASSE 0`.

### Confusion 9: “If Wekinator sends floats, that means this is regression.”

Not necessarily.
Wekinator often sends outputs as floats even for classification.
This sketch converts that float into an integer class.

---

## 12. IF THIS CODE IS RELATED TO MACHINE LEARNING OR WEKINATOR

Yes — it is clearly related.

## Role of Processing in this file

This Processing sketch:

* receives OSC predictions
* stores the class
* maps class to label
* generates visuals
* animates particles and transitions

## Role of Wekinator

Wekinator is expected to:

* receive sound features from another source
* learn from examples
* output a predicted sound class

## What Processing is extracting or sending

In this particular file, Processing is **not extracting** sound features and **not sending** training inputs.
It is only **receiving** the prediction.

So if there is a larger system, this file is probably the **output visualization sketch**, not the feature extraction sketch.

## How many inputs and outputs this code implies

From the point of view of this sketch:

* input: one incoming predicted class value from OSC
* output: on-screen visualization

From the point of view of the ML system:

* Wekinator probably receives multiple audio features as inputs from another sketch
* Wekinator probably outputs **one classification value**

## Is this classification, regression, or feature extraction?

This sketch is best matched to **classification output visualization**.
It is not performing feature extraction or regression here.

Because the class values are discrete categories like `1`, `2`, `3`, this is a **classification context**.

---

## 13. SIMPLE SUMMARY

### 5-sentence simple summary

This sketch creates an animated screen that reacts to sound classes. It listens for OSC messages, probably from Wekinator, on port `12000`. When it receives a class such as clap, snap, or voice, it changes the background, particles, center graphics, and label text. The animation runs continuously using `draw()`, while `oscEvent()` updates the class whenever a new message arrives. So the sketch turns machine learning predictions into live visual feedback.

### One-paragraph conceptual summary

Conceptually, this program is a visual translator between machine learning output and human perception. An external classifier decides what sound is happening, and this Processing sketch converts that decision into color, shape, motion, text, and particle behavior. The current class acts as the main state of the system, and all visual layers respond to that state in different ways. The animation is kept alive with pulsing values, transition fades, and a particle system. In other words, the sketch is a real-time audiovisual interface where machine learning results become expressive graphics.

### One-sentence summary of the code’s purpose

This code receives sound classification results through OSC and visualizes each detected class with animated text, particles, and class-specific graphics.

---

## 14. Teaching Style Notes for Understanding

When you study this code, keep these interpretations in mind:

* a **variable** is a named storage box in memory
* a **function** is a reusable action block
* `setup()` means “prepare everything once”
* `draw()` means “repeat forever and redraw the screen”
* **OSC** is a way programs send real-time messages to each other
* a **class** in machine learning means a category, like clap or voice
* a **particle system** means many tiny objects animated together
* `sin()` is used to create smooth repeated motion

A good mental model is this:

> Wekinator decides the category. Processing performs the show.

---

## 15. FINAL CHECK

## The 3 most important ideas you must understand from this code

1. This sketch is primarily a **visual receiver**, not the sound classifier itself.
2. The variable `predictedClass` controls almost the entire visual behavior of the program.
3. The animation system works by continuously updating state in `draw()` and reacting to external OSC messages in `oscEvent()`.

## The 3 most important lines or code blocks

### 1.

```java
oscP5 = new OscP5(this, 12000);
```

This opens the OSC receiver and allows the sketch to communicate with Wekinator.

### 2.

```java
int incomingClass = round(msg.get(0).floatValue());
```

This is where the incoming prediction is actually read and converted into a usable class number.

### 3.

```java
void draw() {
  updateAnimation();
  drawBackgroundByClass();
  drawParticles();
  drawCenterVisual();
  drawFancyLabel();
}
```

This is the rendering pipeline that produces the full screen every frame.

## The 3 best follow-up questions you should ask next

1. How does the separate Processing or Wekinator sketch generate and send the class values to this visualizer?
2. How could I modify this code so class `0` is handled consistently as `SILENCE` everywhere?
3. How can I extend this sketch to support more sound classes or smoother transitions between classes?

---

## Extra Practical Note

If you run this file alone and nothing is sending OSC messages to port `12000`, the sketch will still open and animate, but it will remain in its idle state. That is normal. It does not mean the code is broken — it means the external classifier input is missing.
