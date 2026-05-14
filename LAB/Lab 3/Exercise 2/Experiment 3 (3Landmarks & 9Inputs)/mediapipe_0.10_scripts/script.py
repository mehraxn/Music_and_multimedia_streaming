"""
Lab 3 - Exercise 2
MediaPipe hand landmarks to Wekinator via OSC
3-landmark experiment version

This script:
1. Opens webcam
2. Detects one hand using MediaPipe
3. Extracts 3 selected hand landmark coordinates
4. Sends them to Wekinator using OSC

For LANDMARK_MODE = 3:
3 landmarks x 3 coordinates = 9 Wekinator inputs

Wekinator setup:
Input port: 6448
Input message: /wek/inputs
# inputs: 9

Outputs:
# outputs: 3
outputs-1 -> Red
outputs-2 -> Green
outputs-3 -> Blue

Important:
The Processing output sketch can stay the same because Wekinator still sends 3 RGB outputs.
Only the Python input number and the Wekinator input number change.
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

# 3-landmark experiment
LANDMARK_MODE = 3

# Landmark selections:
# 21: all hand landmarks
# 10: selected important landmarks
# 3: minimal version for comparison
LANDMARK_SETS = {
    21: list(range(21)),
    10: [0, 4, 5, 8, 9, 12, 13, 16, 17, 20],
    3: [0, 8, 20]
}

selected_landmarks = LANDMARK_SETS[LANDMARK_MODE]
input_count = len(selected_landmarks) * 3


# -----------------------------
# START INFORMATION
# -----------------------------

print("Lab 3 Exercise 2 - Python Input Script")
print("--------------------------------------")
print("Experiment: 3 landmarks / 9 Wekinator inputs")
print("Landmark mode:", LANDMARK_MODE)
print("Selected landmarks:", selected_landmarks)
print("Wekinator input count:", input_count)
print("OSC message:", WEKINATOR_MESSAGE)
print("OSC destination:", WEKINATOR_HOST, WEKINATOR_PORT)
print("--------------------------------------")


# -----------------------------
# OSC CLIENT
# -----------------------------

client = udp_client.SimpleUDPClient(WEKINATOR_HOST, WEKINATOR_PORT)


# -----------------------------
# MEDIAPIPE SETUP
# -----------------------------

base_options = python.BaseOptions(model_asset_path=MODEL_PATH)

options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1,
    min_hand_detection_confidence=0.7,
    min_hand_presence_confidence=0.7,
    min_tracking_confidence=0.7
)


# -----------------------------
# WEBCAM SETUP
# -----------------------------

cap = cv2.VideoCapture(0)


# -----------------------------
# MAIN LOOP
# -----------------------------

with vision.HandLandmarker.create_from_options(options) as landmarker:

    while cap.isOpened():

        ret, frame = cap.read()

        if not ret:
            break

        # Mirror the image for easier interaction
        frame = cv2.flip(frame, 1)

        # Convert OpenCV BGR image to RGB for MediaPipe
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Create MediaPipe image
        mp_image = mp.Image(
            image_format=mp.ImageFormat.SRGB,
            data=rgb
        )

        # Detect hand landmarks
        result = landmarker.detect(mp_image)

        hand_detected = len(result.hand_landmarks) > 0

        if hand_detected:

            hand = result.hand_landmarks[0]
            features = []

            h, w, _ = frame.shape

            # Draw landmarks on the camera image
            for i, lm in enumerate(hand):

                cx = int(lm.x * w)
                cy = int(lm.y * h)

                if i in selected_landmarks:
                    # Selected landmarks are shown in green
                    cv2.circle(frame, (cx, cy), 8, (0, 255, 0), -1)

                    cv2.putText(
                        frame,
                        str(i),
                        (cx + 5, cy - 5),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.5,
                        (0, 255, 0),
                        2
                    )

                else:
                    # Unused landmarks are shown in gray
                    cv2.circle(frame, (cx, cy), 3, (120, 120, 120), -1)

            # Extract x, y, z values for the selected 3 landmarks
            # 3 landmarks x 3 coordinates = 9 values
            for index in selected_landmarks:

                lm = hand[index]

                features.append(float(lm.x))
                features.append(float(lm.y))
                features.append(float(lm.z))

            # Send the 9 input features to Wekinator
            client.send_message(WEKINATOR_MESSAGE, features)

            status_text = "HAND DETECTED - SENDING 9 OSC INPUTS"
            status_color = (0, 255, 0)

        else:

            status_text = "NO HAND DETECTED"
            status_color = (0, 0, 255)


        # -----------------------------
        # DISPLAY TEXT ON CAMERA WINDOW
        # -----------------------------

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
            "Selected landmarks: 0, 8, 20",
            (10, 115),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        cv2.putText(
            frame,
            "Press q to quit",
            (10, 145),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        cv2.imshow(
            "Exercise 2 - 3 Hand Landmarks to Wekinator",
            frame
        )

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break


# -----------------------------
# CLEANUP
# -----------------------------

cap.release()
cv2.destroyAllWindows()