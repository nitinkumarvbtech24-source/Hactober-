# Trash Detection Model (YOLOv8)

This directory contains the trained weights, model configuration, and integration code for the custom **Trash Detection YOLOv8 Model**.

---

## 📦 What's Inside This Folder

- **`trash_yolov8n.pt`** (6.5 MB): PyTorch weights for Python & Ultralytics workflows.
- **`trash_yolov8n.onnx`** (12.2 MB): Universal ONNX model (compatible with C++, C#, OpenCV `cv2.dnn`, ONNX Runtime, Android, iOS, ROS, Jetson, etc.).
- **`model_config.json`**: Model input dimensions, class ID mapping, recommended thresholds, and validation metrics.
- **`example_usage.py`**: A ready-to-run Python script showing how to load the model and run inference on any image or video.

---

## 🎯 Model Details

- **Target Class**: Single-class detection: `trash` (Class ID: `0`)
- **Input Resolution**: `640 x 640` (RGB)
- **Architecture**: YOLOv8 Nano (`yolov8n`)
- **Recommended Confidence**: `0.25`
- **Recommended NMS IoU**: `0.45`

---

## 🚀 Quick Integration Guide

### Option 1: Python (Ultralytics)

1. Install requirements:
   ```bash
   pip install ultralytics opencv-python pillow
   ```

2. Run inference:
   ```python
   from ultralytics import YOLO

   # Load model
   model = YOLO("trash_yolov8n.pt")

   # Predict on image or video
   results = model.predict(source="test.jpg", conf=0.25, save=True)

   # Access bounding boxes
   for r in results:
       for box in r.boxes:
           cls_id = int(box.cls[0].item())
           confidence = float(box.conf[0].item())
           bbox = box.xyxy[0].tolist()  # [x1, y1, x2, y2]
           print(f"Trash detected ({confidence*100:.1f}%) at {bbox}")
   ```

3. Or test with the included script:
   ```bash
   python example_usage.py path/to/image.jpg
   ```

---

### Option 2: ONNX Runtime (Universal / No PyTorch Needed)

```python
import cv2
import numpy as np
import onnxruntime as ort

# Load ONNX model
session = ort.InferenceSession("trash_yolov8n.onnx", providers=["CPUExecutionProvider"])
input_name = session.get_inputs()[0].name
output_name = session.get_outputs()[0].name

# Preprocess image to 640x640 RGB float32 [0, 1]
img = cv2.imread("test.jpg")
img_resized = cv2.resize(img, (640, 640))
input_tensor = np.transpose(img_resized[:, :, ::-1], (2, 0, 1)).astype(np.float32) / 255.0
input_tensor = np.expand_dims(input_tensor, axis=0)

# Run inference
outputs = session.run([output_name], {input_name: input_tensor})
```

---

### Option 3: Command Line (CLI)

```bash
# Using PyTorch model
yolo predict model=trash_yolov8n.pt source=test.jpg conf=0.25 save=True

# Using ONNX model
yolo predict model=trash_yolov8n.onnx source=test.jpg conf=0.25 save=True
```
