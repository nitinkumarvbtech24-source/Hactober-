"""
Trash Detection Model - Integration Example
============================================
This script demonstrates how to load and use the fine-tuned YOLOv8 trash detection model.

Requirements:
    pip install ultralytics opencv-python pillow
"""

import sys
from pathlib import Path
from ultralytics import YOLO

def main():
    # 1. Load the trained model
    model_dir = Path(__file__).resolve().parent
    weights_path = model_dir / "trash_yolov8n.pt"
    
    if not weights_path.exists():
        weights_path = model_dir / "best.pt"

    print(f"Loading trash detection model from: {weights_path}")
    model = YOLO(str(weights_path))

    # 2. Input image (can be image path, numpy array, PIL Image, or video)
    test_image = sys.argv[1] if len(sys.argv) > 1 else None
    if not test_image:
        print("\n[INFO] No image provided as command line argument.")
        print("Usage: python example_usage.py path/to/image.jpg")
        print("Using dummy input or model summary for verification...\n")
        print("Model classes:", model.names)
        return

    # 3. Run prediction
    results = model.predict(
        source=test_image,
        conf=0.25,        # Confidence threshold (0.05 - 0.95)
        iou=0.45,         # NMS IoU threshold
        save=True,        # Automatically save annotated image
        line_width=2
    )

    # 4. Parse detection results
    result = results[0]
    boxes = result.boxes

    print(f"\nFound {len(boxes)} trash instance(s) in {test_image}:")
    for i, box in enumerate(boxes):
        cls_id = int(box.cls[0].item())
        cls_name = result.names.get(cls_id, f"Class {cls_id}")
        confidence = float(box.conf[0].item())
        coords = [round(float(c), 1) for c in box.xyxy[0].tolist()]
        print(f"  #{i+1}: {cls_name} (Confidence: {confidence*100:.1f}%) | Bounding Box [x1, y1, x2, y2]: {coords}")

    print("\nInference successful! Annotated image saved by Ultralytics in 'runs/detect/predict'.")

if __name__ == "__main__":
    main()
