IMPORTANT - 

This project keeps the correct OSC setup for Lab 3 Exercise 1:
- Input port: 6448
- Input OSC message: /wek/inputs
- Number of inputs: 3
- Output OSC message: /wek/outputs
- Output host: localhost
- Output port: 12000
- Number of outputs: 2

The original recordings all used outputs-1 = 0.2 and outputs-2 = 0.2, so the circle output stayed fixed.

This corrected version changes the recorded target outputs by training round:
- Round 1: outputs-1 = 0.2, outputs-2 = 0.2
- Round 2: outputs-1 = 0.2, outputs-2 = 0.8
- Round 3: outputs-1 = 0.8, outputs-2 = 0.8
- Round 4: outputs-1 = 0.8, outputs-2 = 0.2

Very important:
After opening this project in Wekinator, click Train again, then click Run.
The saved model files may still represent the previous trained model until you retrain.

Meaning of outputs:
- outputs-1 controls circle size
- outputs-2 controls outline alpha/transparency
