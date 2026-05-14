"""
Lab 3 - Exercise 2
MediaPipe hand landmarks to Wekinator via OSC

This script:
1. Opens webcam
2. Detects one hand using MediaPipe
3. Extracts selected hand landmark coordinates
4. Sends them to Wekinator using OSC

For LANDMARK_MODE = 21:
21 landmarks x 3 coordinates = 63 Wekinator inputs

Wekinator setup:
Input port: 6448
Input message: /wek/inputs
# inputs: 63

Outputs:
# outputs: 3
outputs-1 -> Red
outputs-2 -> Green
outputs-3 -> Blue
"""

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from pythonosc import udp_client

# -----------------------------
# SETTINGS
# -----------------------------

MODEL_PATH = "hand_landmarker.task"

WEKINATOR_HOST = "127.0.0.1"
WEKINATOR_PORT = 6448
WEKINATOR_MESSAGE = "/wek/inputs"

# Change this later to 10 or 3 for comparison
LANDMARK_MODE = 21

# Landmark selections
LANDMARK_SETS = {
    21: list(range(21)),
    10: [0, 4, 5, 8, 9, 12, 13, 16, 17, 20],
    3: [0, 8, 20]
}

selected_landmarks = LANDMARK_SETS[LANDMARK_MODE]
input_count = len(selected_landmarks) * 3

print("Lab 3 Exercise 2 - Python Input Script")
print("--------------------------------------")
print("Landmark mode:", LANDMARK_MODE)
print("Selected landmarks:", selected_landmarks)
print("Wekinator input count:", input_count)
print("OSC message:", WEKINATOR_MESSAGE)
print("OSC destination:", WEKINATOR_HOST, WEKINATOR_PORT)
print("--------------------------------------")

# OSC client for Wekinator
client = udp_client.SimpleUDPClient(WEKINATOR_HOST, WEKINATOR_PORT)

# MediaPipe setup
base_options = python.BaseOptions(model_asset_path=MODEL_PATH)
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1,
    min_hand_detection_confidence=0.7,
    min_hand_presence_confidence=0.7,
    min_tracking_confidence=0.7
)

cap = cv2.VideoCapture(0)

with vision.HandLandmarker.create_from_options(options) as landmarker:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Mirror image for easier interaction
        frame = cv2.flip(frame, 1)

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        result = landmarker.detect(mp_image)

        hand_detected = len(result.hand_landmarks) > 0

        if hand_detected:
            hand = result.hand_landmarks[0]

            features = []

            h, w, _ = frame.shape

            for i, lm in enumerate(hand):
                cx, cy = int(lm.x * w), int(lm.y * h)

                if i in selected_landmarks:
                    # Draw selected landmarks in green
                    cv2.circle(frame, (cx, cy), 7, (0, 255, 0), -1)
                    cv2.putText(
                        frame,
                        str(i),
                        (cx + 5, cy - 5),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.4,
                        (0, 255, 0),
                        1
                    )
                else:
                    # Draw unused landmarks in gray
                    cv2.circle(frame, (cx, cy), 3, (120, 120, 120), -1)

            # Extract x, y, z for selected landmarks
            for index in selected_landmarks:
                lm = hand[index]
                features.append(float(lm.x))
                features.append(float(lm.y))
                features.append(float(lm.z))

            # Send features to Wekinator
            client.send_message(WEKINATOR_MESSAGE, features)

            status_text = "HAND DETECTED - SENDING OSC"
            status_color = (0, 255, 0)

        else:
            status_text = "NO HAND DETECTED"
            status_color = (0, 0, 255)

        # Display status text
        cv2.putText(
            frame,
            "Lab 3 Exercise 2 - MediaPipe to Wekinator",
            (10, 25),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        cv2.putText(
            frame,
            "Mode: " + str(LANDMARK_MODE) + " landmarks | Inputs: " + str(input_count),
            (10, 55),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        cv2.putText(
            frame,
            status_text,
            (10, 85),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            status_color,
            2
        )

        cv2.putText(
            frame,
            "Press q to quit",
            (10, 115),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        cv2.imshow("Exercise 2 - Hand Landmarks to Wekinator", frame)

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

cap.release()
cv2.destroyAllWindows()