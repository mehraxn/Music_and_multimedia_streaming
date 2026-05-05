
import argparse
import os
import sys
from typing import Dict, List

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from pythonosc import udp_client


DEFAULT_MODEL_PATH = "hand_landmarker.task"
DEFAULT_CAMERA_INDEX = 0

WEKINATOR_HOST = "127.0.0.1"
WEKINATOR_INPUT_PORT = 6448
WEKINATOR_INPUT_MESSAGE = "/wek/inputs"

# Change this value to 21, 10, or 3 if you do not want to use command-line args.
LANDMARK_MODE = 21

SEND_ZEROS_WHEN_NO_HAND = False


LANDMARK_SETS: Dict[int, List[int]] = {
    21: list(range(21)),
    10: [0, 4, 5, 8, 9, 12, 13, 16, 17, 20],
    3: [0, 8, 20],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Send MediaPipe hand landmark coordinates to Wekinator via OSC."
    )

    parser.add_argument(
        "--mode",
        type=int,
        choices=[21, 10, 3],
        default=LANDMARK_MODE,
        help="Number of hand landmarks to send: 21, 10, or 3.",
    )

    parser.add_argument(
        "--model",
        type=str,
        default=DEFAULT_MODEL_PATH,
        help="Path to hand_landmarker.task.",
    )

    parser.add_argument(
        "--camera",
        type=int,
        default=DEFAULT_CAMERA_INDEX,
        help="Webcam index. Usually 0 for the default camera.",
    )

    parser.add_argument(
        "--host",
        type=str,
        default=WEKINATOR_HOST,
        help="Wekinator host. Use 127.0.0.1 when Wekinator runs on the same computer.",
    )

    parser.add_argument(
        "--port",
        type=int,
        default=WEKINATOR_INPUT_PORT,
        help="Wekinator input port. Default is 6448.",
    )

    parser.add_argument(
        "--mirror",
        action="store_true",
        help="Mirror the webcam image for easier interaction.",
    )

    return parser.parse_args()


def create_hand_landmarker(model_path: str) -> vision.HandLandmarker:
    if not os.path.exists(model_path):
        print(f"ERROR: Model file not found: {model_path}")
        print("Download hand_landmarker.task and place it next to this script.")
        sys.exit(1)

    base_options = python.BaseOptions(model_asset_path=model_path)

    options = vision.HandLandmarkerOptions(
        base_options=base_options,
        num_hands=1,
        min_hand_detection_confidence=0.7,
        min_hand_presence_confidence=0.7,
        min_tracking_confidence=0.7,
    )

    return vision.HandLandmarker.create_from_options(options)


def extract_landmark_features(hand_landmarks, selected_indexes: List[int]) -> List[float]:
    features: List[float] = []

    for index in selected_indexes:
        lm = hand_landmarks[index]
        features.append(float(lm.x))
        features.append(float(lm.y))
        features.append(float(lm.z))

    return features


def draw_landmarks(frame, hand_landmarks, selected_indexes: List[int]) -> None:
    h, w, _ = frame.shape
    selected_set = set(selected_indexes)

    for i, lm in enumerate(hand_landmarks):
        cx, cy = int(lm.x * w), int(lm.y * h)

        if i in selected_set:
            cv2.circle(frame, (cx, cy), 7, (0, 255, 0), -1)
            cv2.putText(
                frame,
                str(i),
                (cx + 6, cy - 6),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.4,
                (0, 255, 0),
                1,
                cv2.LINE_AA,
            )
        else:
            cv2.circle(frame, (cx, cy), 3, (120, 120, 120), -1)


def draw_status_text(frame, mode: int, input_count: int, hand_detected: bool, host: str, port: int) -> None:
    status = "HAND DETECTED" if hand_detected else "NO HAND DETECTED"

    lines = [
        "Lab 3 Exercise 2 - MediaPipe to Wekinator",
        f"Landmark mode: {mode} landmarks",
        f"Wekinator inputs: {input_count}",
        f"OSC: {WEKINATOR_INPUT_MESSAGE} -> {host}:{port}",
        status,
        "Press q to quit",
    ]

    y = 25
    for line in lines:
        cv2.putText(
            frame,
            line,
            (10, y),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.55,
            (255, 255, 255),
            2,
            cv2.LINE_AA,
        )
        y += 25


def main() -> None:
    args = parse_args()

    selected_indexes = LANDMARK_SETS[args.mode]
    input_count = len(selected_indexes) * 3

    print("----------------------------------------------------")
    print("Lab 3 Exercise 2 - Hand Landmark Input Script")
    print("----------------------------------------------------")
    print(f"Landmark mode: {args.mode}")
    print(f"Selected landmark indexes: {selected_indexes}")
    print(f"Wekinator input count: {input_count}")
    print(f"OSC message: {WEKINATOR_INPUT_MESSAGE}")
    print(f"OSC destination: {args.host}:{args.port}")
    print("----------------------------------------------------")
    print("Wekinator setup for this mode:")
    print(f"  # inputs: {input_count}")
    print("  # outputs: 3")
    print("  Output type: All continuous")
    print("----------------------------------------------------")

    client = udp_client.SimpleUDPClient(args.host, args.port)

    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        print(f"ERROR: Could not open webcam with index {args.camera}")
        sys.exit(1)

    with create_hand_landmarker(args.model) as landmarker:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                print("ERROR: Could not read frame from webcam.")
                break

            if args.mirror:
                frame = cv2.flip(frame, 1)

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

            result = landmarker.detect(mp_image)

            hand_detected = len(result.hand_landmarks) > 0

            if hand_detected:
                hand_landmarks = result.hand_landmarks[0]
                features = extract_landmark_features(hand_landmarks, selected_indexes)

                client.send_message(WEKINATOR_INPUT_MESSAGE, features)
                draw_landmarks(frame, hand_landmarks, selected_indexes)

            elif SEND_ZEROS_WHEN_NO_HAND:
                zero_features = [0.0] * input_count
                client.send_message(WEKINATOR_INPUT_MESSAGE, zero_features)

            draw_status_text(frame, args.mode, input_count, hand_detected, args.host, args.port)

            cv2.imshow("Exercise 2 - Hand Landmarks to Wekinator", frame)

            if cv2.waitKey(1) & 0xFF == ord("q"):
                break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()