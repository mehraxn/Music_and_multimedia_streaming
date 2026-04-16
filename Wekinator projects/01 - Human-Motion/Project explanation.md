# README: Webcam Motion Classification with Wekinator and Processing

## Overview

This project demonstrates a complete interactive machine learning workflow using **Wekinator** and **Processing**. The system uses a webcam to detect motion, converts that motion into numerical input features, trains a classifier in Wekinator, and then sends predicted class labels back to a Processing sketch that visualizes the result as different color tints.

The final behavior of the system is:

* **Camera motion is measured in real time**
* **Motion data is sent to Wekinator through OSC**
* **Wekinator learns to classify different kinds of movement**
* **Predicted classes are sent back out through OSC**
* **A Processing sketch receives the prediction and changes the visual output**

This is a supervised learning example in which motion patterns are manually labeled and used to train a model that can later classify new movement in real time.

---

## Project Goal

The goal of the project is to recognize different **qualities of motion** from webcam input and map them to three classes:

1. **STILL**
2. **FLOW**
3. **CHAOS**

These three classes are not derived automatically. They are defined by the user during training. Wekinator learns the relationship between the incoming motion features and the chosen class labels.

After training, the system can observe a new motion pattern and predict which of the three categories it most closely matches.

---

## Main Components

The project is built from three cooperating parts:

### 1. `VideoMotionDetection.pde`

This Processing sketch acts as the **input generator**.

Its role is to:

* access the webcam
* compare the current video frame with the previous frame
* estimate how much motion is happening
* store a recent history of motion measurements
* send that history to Wekinator as input features

This sketch does **not** send the raw image itself to Wekinator. Instead, it extracts a simpler numerical description of movement.

### 2. Wekinator

Wekinator acts as the **machine learning system**.

Its role is to:

* receive motion features from Processing
* record labeled training examples
* train a classification model
* predict classes from new incoming motion data
* send the predicted class back out using OSC

### 3. `CameraTint.pde`

This Processing sketch acts as the **output visualizer**.

Its role is to:

* listen for Wekinator's predicted output
* interpret the predicted class label
* change the visual appearance of the screen accordingly

This sketch provides immediate feedback showing how Wekinator is interpreting the motion.

---

## Conceptual Workflow

The project follows the standard supervised interactive machine learning cycle:

### Step 1: Input arrives from the camera

The webcam captures video frames continuously.

### Step 2: Motion features are extracted

Instead of using the full image, the input sketch computes a motion value based on frame-to-frame pixel changes.

### Step 3: Features are sent to Wekinator

A sequence of recent motion values is transmitted to Wekinator through OSC.

### Step 4: Examples are labeled

The user decides which motion behavior corresponds to which class and records examples for each class.

### Step 5: Wekinator trains a model

Wekinator learns the mapping between motion features and class labels.

### Step 6: New motion is classified

When the system runs after training, Wekinator predicts a class for unseen incoming motion.

### Step 7: Output is visualized

The predicted class is sent to the output sketch, which changes the tint of the display.

This creates a full real-time loop between **human movement**, **feature extraction**, **machine learning**, and **interactive audiovisual feedback**.

---

## What the Input Sketch Actually Sends

A key part of this project is understanding what Wekinator is learning from.

The input sketch does not send:

* object identity
* face recognition
* body pose
* raw camera frames
* color content of the scene

Instead, it sends a **temporal motion descriptor**.

The process is:

1. capture the current webcam frame
2. compare it with the previous frame
3. determine how much changed
4. produce a single motion amount value
5. keep the most recent **30 motion values** in a buffer
6. send all 30 values to Wekinator as one input vector

This means Wekinator receives a short recent history of motion rather than a single instantaneous measurement.

That is important because movement categories such as stillness, smooth flow, and chaotic motion are better described over time than by one isolated frame.

### Input dimensionality

The correct number of inputs is therefore:

**30 inputs**

Each input represents one element of the recent motion history.

---

## What Wekinator Learns

Wekinator learns a mapping from:

**recent motion pattern → class label**

The intended interpretation of the three classes is:

### Class 1: STILL

This class represents very low movement or near absence of motion.

Typical examples:

* standing still
* holding the body steady
* producing minimal frame-to-frame change

### Class 2: FLOW

This class represents moderate, continuous, smooth motion.

Typical examples:

* slowly waving a hand
* moving the body gently and regularly
* producing ongoing but not abrupt changes

### Class 3: CHAOS

This class represents large, irregular, fast, or abrupt motion.

Typical examples:

* shaking rapidly
* moving unpredictably
* generating strong frame-to-frame differences

Wekinator does not memorize one exact example and replay it like a lookup table. Instead, it tries to learn general patterns so that new motion that resembles earlier training examples can be classified appropriately.

---

## OSC Communication Structure

The project depends on correct OSC communication between the sketches and Wekinator.

### Input communication

The input sketch sends data to Wekinator using:

* **OSC address:** `/wek/inputs`
* **Destination host:** `127.0.0.1` or `localhost`
* **Destination port:** `6448`

This is the channel through which motion features reach Wekinator.

### Output communication

Wekinator sends predictions to the output sketch using:

* **OSC address:** `/wek/outputs`
* **Destination host:** `localhost`
* **Destination port:** `12000`

This is the channel through which the predicted class reaches the visualization sketch.

---

## Correct Wekinator Project Setup

To make the system work properly, the Wekinator project must be configured with the same structure expected by the Processing sketches.

### Receiving OSC

* **Listening port:** `6448`

### Inputs

* **OSC message:** `/wek/inputs`
* **Number of inputs:** `30`

### Outputs

* **OSC message:** `/wek/outputs`
* **Host:** `localhost`
* **Port:** `12000`
* **Number of outputs:** `1`

### Output type

* **Type:** discrete classification

This configuration is necessary because the system is not predicting a continuous floating-point control value. It is predicting one class label among several categories.

---

## Why the Output Count Must Be 1

Although the project has three conceptual categories, the Processing output sketch expects Wekinator to send a **single predicted value** representing the current class.

That means the output is one number such as:

* `1`
* `2`
* `3`

Those numbers are interpreted as class identities rather than as three separate continuous channels.

So the correct Wekinator setting is:

**1 output**

not 3 outputs and not 5 outputs.

---

## Training Procedure

The model is trained by recording examples for each class while the input sketch is actively sending motion features.

### Preparation

Before training:

1. Wekinator is opened and configured correctly
2. `VideoMotionDetection.pde` is run so that motion features are sent into Wekinator
3. `CameraTint.pde` is also run so that output can later be displayed
4. The OSC indicators in Wekinator confirm successful communication

### Recording examples

Training is performed class by class.

#### Recording class 1: STILL

* choose output label `1`
* start recording
* remain very still for a short period
* stop recording

#### Recording class 2: FLOW

* choose output label `2`
* start recording
* move smoothly and continuously
* stop recording

#### Recording class 3: CHAOS

* choose output label `3`
* start recording
* move quickly, abruptly, or irregularly
* stop recording

This process should be repeated several times per class so that the model sees multiple examples and can learn more robustly.

### Training the model

After recording examples for all classes:

* press **Train** in Wekinator

Wekinator then builds a classifier from the recorded examples.

### Running the model

After training:

* press **Run** in Wekinator

At this stage the model begins classifying live incoming motion and sending predictions to the output sketch.

---

## Interpreting the Wekinator Interface

Several visual indicators in Wekinator are important during the workflow.

### OSC In

When this indicator turns green, it means Wekinator is successfully receiving input data from the Processing input sketch.

### OSC Out

When this indicator turns green, it means Wekinator is successfully sending output data out to the Processing output sketch.

### Predicted class value

While running, the model display shows the current predicted class. This indicates how Wekinator is interpreting the live motion at that moment.

For example:

* current prediction = `1` means Wekinator believes the motion matches **STILL**
* current prediction = `2` means Wekinator believes the motion matches **FLOW**
* current prediction = `3` means Wekinator believes the motion matches **CHAOS**

---

## Result of the Final Working System

Once the system is trained and running successfully, the complete pipeline behaves as follows:

1. the webcam captures motion continuously
2. motion intensity is estimated frame by frame
3. the last 30 motion values are packaged as a feature vector
4. the feature vector is sent to Wekinator
5. Wekinator classifies the motion according to the training it received
6. the predicted class is sent back out over OSC
7. the output sketch receives the class and changes the visual tint

This means the system can now respond to **new, previously unseen motion input** based on learned behavior rather than explicit hard-coded rules.

That is the central achievement of the project: it demonstrates how a machine learning system can be trained by examples and then used interactively in real time.

---

## What the Visual Output Represents

The tint shown by the output sketch is not the thing being learned. It is the **display of the prediction**.

The learned relationship is between:

* motion feature history
  n- class label

The tint is simply a readable feedback layer that allows the user to observe the classification result.

In practical terms:

* when motion resembles trained stillness, the display moves toward the visual appearance associated with **STILL**
* when motion resembles smooth movement, the display shifts toward the appearance associated with **FLOW**
* when motion resembles irregular or intense movement, the display changes toward the appearance associated with **CHAOS**

This makes the invisible machine learning decision visible and immediate.

---

## Educational Significance of the Project

This project is a strong example of interactive machine learning because it clearly illustrates all the main ideas in a compact form.

### 1. Feature extraction

The system does not learn directly from raw reality. It learns from selected numerical features.

### 2. Supervised learning

The categories are defined by the user, and the model is trained with labeled examples.

### 3. Generalization

After training, the model can respond to new motion that was not recorded exactly before.

### 4. Real-time interaction

The learning system is embedded in a live loop where sensing, prediction, and output happen continuously.

### 5. Human-defined meaning

The classes STILL, FLOW, and CHAOS are meaningful because the user decides what kinds of motion they represent during the recording process.

---

## Why Results May Vary

The quality of classification depends heavily on the quality of the training data.

Performance may improve or degrade depending on:

* how clearly different the three motion classes are during recording
* whether enough examples were recorded for each class
* lighting stability in the webcam scene
* background noise or unintended movement
* whether the movements used in testing resemble the movements demonstrated in training

A model trained with few or ambiguous examples may confuse the classes. A model trained with richer and more distinct examples usually performs better.

---

## Good Practice for Improving the Model

To improve reliability:

* record multiple examples for each class
* keep the classes behaviorally distinct
* use consistent demonstrations when training
* retrain after adding better examples
* test repeatedly and observe how the predicted class changes

In interactive machine learning, model development is often iterative: record, train, test, revise, and retrain.

---

## Final Summary

This project successfully implements a real-time supervised machine learning system using Wekinator and Processing.

The input sketch converts webcam motion into a 30-value feature history. Wekinator receives these values through OSC, learns to classify them into the three user-defined classes STILL, FLOW, and CHAOS, and then sends a predicted class back out through OSC. The output sketch receives that prediction and visualizes it through screen tint changes.

The completed system demonstrates the full pipeline of:

**sensor input → feature extraction → labeled training → machine learning model → real-time prediction → interactive output**

As a result, the project provides both a practical working example and a clear conceptual model of how Wekinator can be used to build interactive machine learning applications from live media input.
