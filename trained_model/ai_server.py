import os
import io
import time
import base64
import json
from pathlib import Path
from typing import Optional, List

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
import numpy as np
import cv2
from ultralytics import YOLO

app = FastAPI(title="Street AIQ Trash Detection Service", version="1.0.0")

# Enable CORS for Flutter Web apps (localhost:8080 and localhost:8082)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Directory setup
BASE_DIR = Path(__file__).resolve().parent
SNAPSHOTS_DIR = BASE_DIR / "snapshots"
SNAPSHOTS_DIR.mkdir(parents=True, exist_ok=True)

# Mount snapshots directory to serve annotated images
app.mount("/snapshots", StaticFiles(directory=str(SNAPSHOTS_DIR)), name="snapshots")

# Load YOLOv8 Trash Detection Model
weights_path = BASE_DIR / "trash_yolov8n.pt"
if not weights_path.exists():
    weights_path = BASE_DIR / "best.pt"

print(f"[*] Initializing YOLOv8 Trash Detection Model from: {weights_path}")
model = YOLO(str(weights_path))
print(f"[+] Model loaded successfully. Classes: {model.names}")

# In-memory store for snapshots
snapshots_history = []

class ProcessFrameRequest(BaseModel):
    image: str
    lat: Optional[float] = 0.0
    lng: Optional[float] = 0.0
    vehicle_number: Optional[str] = "Unknown Vehicle"
    ward: Optional[str] = "Ward 01"
    zone: Optional[str] = "Central Zone"

@app.get("/")
def root():
    return {
        "service": "Street AIQ Trash Detection API",
        "model": "trash_yolov8n",
        "status": "online",
        "classes": model.names,
        "input_resolution": [640, 640]
    }

@app.get("/health")
def health():
    return {"status": "ok", "timestamp": time.time()}

@app.get("/api/snapshots")
def get_snapshots():
    return {"snapshots": snapshots_history[-50:]}

@app.post("/process_frame")
async def process_frame(payload: ProcessFrameRequest):
    try:
        # 1. Parse base64 image
        image_data = payload.image
        if "," in image_data:
            image_data = image_data.split(",", 1)[1]

        image_bytes = base64.b64decode(image_data)
        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_np = np.array(pil_image)

        # 2. Run inference with custom YOLOv8 model
        # Recommended confidence: 0.25, IOU: 0.45
        results = model.predict(
            source=img_np,
            conf=0.25,
            iou=0.45,
            verbose=False
        )

        result = results[0]
        boxes = result.boxes
        trash_count = len(boxes)

        detected_boxes = []
        confidences = []

        for box in boxes:
            conf = float(box.conf[0].item())
            cls_id = int(box.cls[0].item())
            coords = [round(float(c), 1) for c in box.xyxy[0].tolist()]
            confidences.append(conf)
            detected_boxes.append({
                "class_id": cls_id,
                "class_name": result.names.get(cls_id, "trash"),
                "confidence": round(conf, 3),
                "box": coords
            })

        timestamp_ms = int(time.time() * 1000)
        spot_id = f"spot_{timestamp_ms}"
        iso_timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        # 3. Handle trash detected vs clean road / no trash
        if trash_count > 0:
            avg_conf = sum(confidences) / len(confidences) if confidences else 0.8
            max_conf = max(confidences) if confidences else 0.8
            road_status = "Trash Detected"
            decision = road_status

            # Render bounding boxes on image
            annotated_frame = result.plot()
            annotated_filename = f"annotated_{spot_id}.jpg"
            annotated_path = SNAPSHOTS_DIR / annotated_filename

            # Save annotated image
            cv2.imwrite(str(annotated_path), annotated_frame)
            image_url = f"/snapshots/{annotated_filename}"

            record = {
                "id": spot_id,
                "decision": "Trash Detected",
                "road_status": "Trash Detected",
                "display_class": "Trash Detected",
                "class": "Trash_Detected",
                "confidence": round(max_conf, 3),
                "trash_count": trash_count,
                "image_url": image_url,
                "lat": payload.lat,
                "lng": payload.lng,
                "vehicle_number": payload.vehicle_number,
                "ward": payload.ward,
                "zone": payload.zone,
                "timestamp": iso_timestamp,
                "boxes": detected_boxes,
                "is_trash": True
            }
            snapshots_history.append(record)

            print(f"[!] DETECTED TRASH: {trash_count} item(s) (Max Conf: {max_conf*100:.1f}%) in {payload.ward} by {payload.vehicle_number}")
            return JSONResponse(content=record)
        else:
            # Clean Road / No Trash - Save clean captured image too
            clean_filename = f"clean_{spot_id}.jpg"
            clean_path = SNAPSHOTS_DIR / clean_filename
            clean_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
            cv2.imwrite(str(clean_path), clean_bgr)
            image_url = f"/snapshots/{clean_filename}"

            record = {
                "id": spot_id,
                "decision": "No Trash",
                "road_status": "No Trash",
                "display_class": "No Trash",
                "class": "No_Trash",
                "confidence": 0.95,
                "trash_count": 0,
                "image_url": image_url,
                "lat": payload.lat,
                "lng": payload.lng,
                "vehicle_number": payload.vehicle_number,
                "ward": payload.ward,
                "zone": payload.zone,
                "timestamp": iso_timestamp,
                "boxes": [],
                "is_trash": False
            }
            snapshots_history.append(record)

            print(f"[✓] NO TRASH: Road Clean in {payload.ward} by {payload.vehicle_number}")
            return JSONResponse(content=record)

    except Exception as e:
        print(f"[ERROR] Inference error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    print("[*] Starting Street AIQ Inference Server on http://127.0.0.1:5002 ...")
    uvicorn.run(app, host="0.0.0.0", port=5002, log_level="info")

