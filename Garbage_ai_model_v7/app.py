import io
import base64
from pathlib import Path
from PIL import Image
import numpy as np
import cv2
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from fastapi.staticfiles import StaticFiles
import os
import uuid
from datetime import datetime
from contextlib import asynccontextmanager
from ultralytics import YOLO
import uvicorn
import torch
import torch.nn as nn
from torchvision import models, transforms

# Configuration
BASE_DIR = Path(__file__).parent
V6_DIR = BASE_DIR.parent / "Garbage_ai_model_v6"
MOBILENET_DIR = BASE_DIR.parent / "Garbage_ai_mobilenetv3"

def get_best_model_path():
    candidates = [
        BASE_DIR / "weights" / "garbage_ai_model_v7_best.pt",
        BASE_DIR / "weights" / "garbage_ai_model_v6_best.pt",
        BASE_DIR / "runs" / "garbage_ai_v6_experiment" / "weights" / "best.pt",
        V6_DIR / "weights" / "garbage_ai_model_v6_best.pt",
    ]
    for p in candidates:
        if p.exists():
            return p
    return BASE_DIR / "weights" / "garbage_ai_model_v6_best.pt"

def get_mobilenet_model_path():
    candidates = [
        BASE_DIR / "weights" / "garbage_ai_mobilenetv3_best.pt",
        MOBILENET_DIR / "weights" / "garbage_ai_mobilenetv3_best.pt",
    ]
    for p in candidates:
        if p.exists():
            return p
    return BASE_DIR / "weights" / "garbage_ai_mobilenetv3_best.pt"

YOLO_MODEL_PATH = get_best_model_path()
MOBILENET_MODEL_PATH = get_mobilenet_model_path()
RAW_DIR = BASE_DIR / "road cleanliness" if (BASE_DIR / "road cleanliness").exists() else (V6_DIR / "road cleanliness")

mobilenet_model = None
mobilenet_transform = None
torch_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Road Scene Verifier (Places365 + Texture Analysis)
places_model = None
places_classes = []
ROAD_CLASSES = {
    'street', 'highway', 'crosswalk', 'alley', 'parking_lot', 'driveway',
    'desert_road', 'field_road', 'forest_road', 'raceway', 'residential_neighborhood',
    'bridge', 'parking_garage/outdoor', 'construction_site', 'promenade', 'plaza', 'courtyard',
    'gas_station', 'trench', 'landfill', 'junkyard'
}
INDOOR_CLASSES = {
    'bedroom', 'living_room', 'home_office', 'office', 'classroom', 'kitchen', 'bathroom',
    'hotel_room', 'conference_room', 'dining_room', 'corridor', 'closet', 'staircase',
    'lobby', 'server_room', 'dorm_room', 'hospital_room', 'pantry', 'attic', 'basement',
    'nursery', 'playroom', 'television_studio', 'elevator'
}
road_indices = []
indoor_indices = []
places_transform = None

def init_road_verifier():
    global places_model, places_classes, road_indices, indoor_indices, places_transform
    weights_path = BASE_DIR / "weights" / "resnet18_places365.pth.tar"
    labels_path = BASE_DIR / "weights" / "categories_places365.txt"
    if weights_path.exists() and labels_path.exists():
        try:
            m = models.resnet18(num_classes=365)
            cp = torch.load(str(weights_path), map_location=torch_device)
            m.load_state_dict({k.replace('module.', ''): v for k, v in cp['state_dict'].items()})
            m.to(torch_device)
            m.eval()
            places_model = m

            with open(str(labels_path)) as f:
                places_classes = [line.strip().split(' ')[0][3:] for line in f]

            road_indices = [i for i, c in enumerate(places_classes) if c in ROAD_CLASSES]
            indoor_indices = [i for i, c in enumerate(places_classes) if c in INDOOR_CLASSES]

            places_transform = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
            ])
            print("✅ Places365 Road Scene Verifier loaded successfully!")
        except Exception as e:
            print(f"⚠️ Error loading Places365: {e}")
            places_model = None

@torch.no_grad()
def check_is_road_scene(img_pil: Image.Image) -> tuple:
    np_img = np.array(img_pil)
    gray = cv2.cvtColor(np_img, cv2.COLOR_RGB2GRAY)
    lap_var = cv2.Laplacian(gray, cv2.CV_64F).var()

    # Low texture check (plain walls, ceilings, monitors, blank surfaces)
    if lap_var < 50.0:
        return False, f"Low surface texture (plain wall/ceiling, Var: {lap_var:.1f})"

    # Scene check with Places365
    if places_model is not None and places_transform is not None:
        try:
            inp = places_transform(img_pil).unsqueeze(0).to(torch_device)
            probs = places_model(inp).squeeze(0).softmax(0)
            road_prob = sum(probs[i].item() for i in road_indices)
            indoor_prob = sum(probs[i].item() for i in indoor_indices)

            # If strongly indoor
            if indoor_prob > 0.35 and indoor_prob > road_prob:
                return False, f"Indoor scene detected ({indoor_prob*100:.0f}% indoor)"

            if road_prob > 0.12 or road_prob > indoor_prob:
                return True, f"Road scene verified ({road_prob*100:.0f}% road)"
        except Exception as e:
            print("Road scene check error:", e)

    return True, "Road surface texture"

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_yolo()
    init_mobilenet()
    init_road_verifier()
    organize_existing_snapshots()
    yield

app = FastAPI(title="Street AIQ — Dual YOLOv8 + MobileNetV3 Road Cleanliness Dashboard (v7)", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SNAPSHOTS_DIR = BASE_DIR / "snapshots"
ANALYSED_TRASH_DIR = SNAPSHOTS_DIR / "analysed" / "trash_detected"
ANALYSED_NO_TRASH_DIR = SNAPSHOTS_DIR / "analysed" / "no_trash_detected"
ANALYSED_NO_ROAD_DIR = SNAPSHOTS_DIR / "analysed" / "no_road_detected"
TRAINING_TRASH_DIR = SNAPSHOTS_DIR / "training" / "trash_detected"
TRAINING_NO_TRASH_DIR = SNAPSHOTS_DIR / "training" / "no_trash_detected"
TRAINING_NO_ROAD_DIR = SNAPSHOTS_DIR / "training" / "no_road_detected"

for folder in [ANALYSED_TRASH_DIR, ANALYSED_NO_TRASH_DIR, ANALYSED_NO_ROAD_DIR, TRAINING_TRASH_DIR, TRAINING_NO_TRASH_DIR, TRAINING_NO_ROAD_DIR]:
    os.makedirs(folder, exist_ok=True)

app.mount("/snapshots", StaticFiles(directory=str(SNAPSHOTS_DIR)), name="snapshots")

history = []
HISTORY_FILE = "history.json"

if os.path.exists(HISTORY_FILE):
    try:
        import json
        with open(HISTORY_FILE, "r") as f:
            history = json.load(f)
    except Exception as e:
        print("Error loading history:", e)
        history = []

yolo_model = None
current_confidence = 0.25
very_dirty_confidence_threshold = 0.50
clean_road_confidence_threshold = 0.55

def organize_existing_snapshots():
    global history
    modified = False
    import shutil
    for s in history:
        tag = s.get("training_tag", s.get("road_status", s.get("display_class", "No Trash Detected")))
        cat = "trash_detected" if (tag == "Trash Detected" or tag == "Very Dirty Road" or s.get("trash_count", 0) > 0) else "no_trash_detected"

        # 1. Categorize Analysed Image
        img_url = s.get("image_url", "")
        if img_url:
            old_name = Path(img_url).name
            target_path = SNAPSHOTS_DIR / "analysed" / cat / old_name
            source_path = SNAPSHOTS_DIR / old_name
            if source_path.exists() and source_path.is_file():
                shutil.move(str(source_path), str(target_path))
                s["image_url"] = f"/snapshots/analysed/{cat}/{old_name}"
                modified = True
            elif target_path.exists():
                s["image_url"] = f"/snapshots/analysed/{cat}/{old_name}"

        # 2. Categorize Training Image
        raw_url = s.get("raw_image_url", "")
        raw_name = Path(raw_url).name if raw_url else ""
        if raw_name:
            target_raw = SNAPSHOTS_DIR / "training" / cat / raw_name
            source_raw = SNAPSHOTS_DIR / raw_name
            if source_raw.exists() and source_raw.is_file():
                shutil.move(str(source_raw), str(target_raw))
                s["raw_image_url"] = f"/snapshots/training/{cat}/{raw_name}"
                modified = True
            elif target_raw.exists():
                s["raw_image_url"] = f"/snapshots/training/{cat}/{raw_name}"
        else:
            if s.get("image_url"):
                img_name = Path(s["image_url"]).name
                analysed_file = SNAPSHOTS_DIR / "analysed" / cat / img_name
                raw_filename = f"raw_{img_name}"
                target_raw = SNAPSHOTS_DIR / "training" / cat / raw_filename
                if analysed_file.exists() and not target_raw.exists():
                    shutil.copy2(str(analysed_file), str(target_raw))
                s["raw_image_url"] = f"/snapshots/training/{cat}/{raw_filename}"
                modified = True

    if modified:
        try:
            with open(HISTORY_FILE, "w") as f:
                import json
                json.dump(history, f)
            print("✅ Successfully categorized existing snapshots into analysed and training folders!")
        except Exception as e:
            print("Error updating history after organizing:", e)

def init_yolo():
    global yolo_model
    print(f"Loading Trained YOLOv8 Street AIQ Detector (v7) from: {YOLO_MODEL_PATH}")
    if YOLO_MODEL_PATH.exists():
        yolo_model = YOLO(str(YOLO_MODEL_PATH))
        print("✅ Trained YOLOv8 Street AIQ Model loaded successfully!")
    else:
        print("Fallback: Loading default yolov8n.pt model...")
        yolo_model = YOLO("yolov8n.pt")

def init_mobilenet():
    global mobilenet_model, mobilenet_transform
    print(f"Loading MobileNetV3 Road Cleanliness Classifier from: {MOBILENET_MODEL_PATH}")
    if MOBILENET_MODEL_PATH and MOBILENET_MODEL_PATH.exists():
        try:
            ckpt = torch.load(str(MOBILENET_MODEL_PATH), map_location=torch_device)
            m = models.mobilenet_v3_large(weights=None)
            in_features = m.classifier[3].in_features
            num_classes = ckpt.get("num_classes", 2) if isinstance(ckpt, dict) else 2
            m.classifier[3] = nn.Sequential(
                nn.Dropout(p=0.3),
                nn.Linear(in_features, num_classes)
            )
            state_dict = ckpt["state_dict"] if isinstance(ckpt, dict) and "state_dict" in ckpt else ckpt
            m.load_state_dict(state_dict)
            m.to(torch_device)
            m.eval()
            mobilenet_model = m

            norm_mean = [0.485, 0.456, 0.406]
            norm_std = [0.229, 0.224, 0.225]
            mobilenet_transform = transforms.Compose([
                transforms.Resize((384, 384)),
                transforms.ToTensor(),
                transforms.Normalize(mean=norm_mean, std=norm_std),
            ])
            print("✅ MobileNetV3 Road Cleanliness Classifier loaded successfully!")
        except Exception as e:
            print(f"❌ Error loading MobileNetV3 model: {e}")
            mobilenet_model = None
    else:
        print(f"⚠️ MobileNetV3 weights not found at {MOBILENET_MODEL_PATH}")

@torch.no_grad()
def classify_with_mobilenet(img_pil: Image.Image) -> dict:
    global mobilenet_model, mobilenet_transform
    if mobilenet_model is None or mobilenet_transform is None:
        return {
            "invoked": False,
            "class": "none",
            "prob_clean": 0.0,
            "prob_very_dirty": 0.0,
            "message": "MobileNetV3 not initialized"
        }
    try:
        tensor = mobilenet_transform(img_pil).unsqueeze(0).to(torch_device)
        logits = mobilenet_model(tensor)
        probs = torch.softmax(logits, dim=1)[0]
        prob_clean = float(probs[0].item())
        prob_very_dirty = float(probs[1].item())

        predicted_class = "very_dirty" if prob_very_dirty >= 0.50 else "clean_road"
        return {
            "invoked": True,
            "class": predicted_class,
            "prob_clean": round(prob_clean, 4),
            "prob_very_dirty": round(prob_very_dirty, 4)
        }
    except Exception as e:
        print(f"MobileNet inference error: {e}")
        return {
            "invoked": False,
            "class": "none",
            "prob_clean": 0.0,
            "prob_very_dirty": 0.0,
            "error": str(e)
        }

def detect_road_trash(img_bytes):
    global current_confidence, yolo_model, mobilenet_model
    if yolo_model is None:
        init_yolo()
    if mobilenet_model is None:
        init_mobilenet()

    img_pil = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    img_np = np.array(img_pil)
    img_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
    h, w, _ = img_bgr.shape
    
    # 1. Run YOLO object detection
    results = yolo_model(img_pil, conf=current_confidence)[0]
    boxes = results.boxes
    trash_count = len(boxes)
    
    annotated_bgr = img_bgr.copy()
    
    for box in boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
        conf = float(box.conf[0].item())
        
        # Red bounding box around detected trash
        cv2.rectangle(annotated_bgr, (x1, y1), (x2, y2), (0, 0, 255), 3)
        label_str = f"TRASH {conf*100:.0f}%"
        
        (text_w, text_h), _ = cv2.getTextSize(label_str, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
        cv2.rectangle(annotated_bgr, (x1, max(0, y1 - 25)), (x1 + text_w, max(0, y1)), (0, 0, 255), -1)
        cv2.putText(annotated_bgr, label_str, (x1, max(15, y1 - 8)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2, cv2.LINE_AA)

    # 2. Road Scene Verification Check
    is_road_surface, road_reason = check_is_road_scene(img_pil)

    if not is_road_surface:
        is_trash_detected = False
        road_status = "No Road Detected"
        decision_label = "NO ROAD DETECTED"
        cleanliness_score = 0.0
        badge_color = "#f59e0b" # Amber
        recommendation = f"⚠️ NO ROAD DETECTED: {road_reason}. Camera must be pointed at the road surface."
        mobilenet_res = {
            "invoked": False,
            "reason": road_reason,
            "class": "no_road",
            "prob_clean": 0.0,
            "prob_very_dirty": 0.0
        }
    # 3. Integrated Decision Logic:
    # Only images where trash was flagged by YOLO are forwarded to MobileNetV3.
    # If no trash is detected by YOLO, MobileNetV3 is not invoked and result is Clean Road.
    elif trash_count == 0:
        is_trash_detected = False
        road_status = "Clean Road"
        decision_label = "CLEAN ROAD"
        cleanliness_score = 100.0
        badge_color = "#22c55e" # Vibrant Green
        recommendation = "✅ CLEAN ROAD: Zero trash detected on the road surface. Road condition optimal."
        mobilenet_res = {
            "invoked": False,
            "reason": "No trash detected by YOLOv7 (Clean Road)",
            "class": "clean_road",
            "prob_clean": 1.0,
            "prob_very_dirty": 0.0
        }
    else:
        # Trash spots bounded by YOLO (trash_count > 0)
        # STRICT RULE: If trash spots got identified or got bounded,
        # it is EITHER 'Very Dirty Road' OR 'Trash Detected'. NEVER Clean Road!
        mobilenet_res = classify_with_mobilenet(img_pil)
        prob_clean = mobilenet_res.get("prob_clean", 0.0)
        prob_very_dirty = mobilenet_res.get("prob_very_dirty", 0.0)
        m_class = mobilenet_res.get("class", "")

        is_trash_detected = True

        # Branch 1: MobileNetV3 identifies Very Dirty conditions
        if m_class == "very_dirty" and prob_very_dirty >= very_dirty_confidence_threshold:
            road_status = "Very Dirty Road"
            decision_label = f"VERY DIRTY ROAD ({trash_count} Item(s), {prob_very_dirty*100:.0f}%)"
            cleanliness_score = max(5.0, round(100.0 - (trash_count * 20.0) - (prob_very_dirty * 25.0), 1))
            badge_color = "#ef4444" # Vibrant Red
            recommendation = f"🚨 VERY DIRTY ROAD: Severe dirty conditions detected with {trash_count} item(s) ({prob_very_dirty*100:.0f}% dirty, threshold: {very_dirty_confidence_threshold*100:.0f}%). High-priority municipal cleanup required."
        # Branch 2: Standard Trash Detected (Trash bounded, but not severe very dirty)
        else:
            road_status = "Trash Detected"
            decision_label = f"TRASH DETECTED ({trash_count} Item(s))"
            cleanliness_score = max(10.0, round(100.0 - (trash_count * 20.0), 1))
            badge_color = "#f97316" # Amber / Orange
            recommendation = f"⚠️ TRASH DETECTED: {trash_count} trash region(s) identified on road surface (MobileNetV3 dirty prob: {prob_very_dirty*100:.0f}%). Municipal cleanup scheduled."
        
    banner_h = max(45, int(h * 0.12))
    overlay = annotated_bgr.copy()
    cv2.rectangle(overlay, (0, 0), (w, banner_h), (15, 23, 42), -1)
    cv2.addWeighted(overlay, 0.8, annotated_bgr, 0.2, 0, annotated_bgr)
    
    cv2.putText(annotated_bgr, f"Street AIQ: {decision_label}", (20, int(banner_h * 0.65)),
                cv2.FONT_HERSHEY_SIMPLEX, max(0.55, w / 1000.0), (255, 255, 255), 2, cv2.LINE_AA)
                
    bar_h = max(8, int(h * 0.03))
    bar_w = int(w * (cleanliness_score / 100.0))
    # Bottom Status Bar Colors (RGB):
    # Clean Road: Green (34, 197, 94)
    # Very Dirty Road: Red (239, 68, 68)
    # Trash Detected: Amber/Orange (249, 115, 22)
    if road_status == "No Road Detected":
        rgb_color = (245, 158, 11)  # Amber
    elif not is_trash_detected:
        rgb_color = (34, 197, 94)   # Green
    elif road_status == "Very Dirty Road":
        rgb_color = (239, 68, 68)  # Red
    else:
        rgb_color = (249, 115, 22) # Amber / Orange
    cv2.rectangle(annotated_bgr, (0, h - bar_h), (bar_w, h), (rgb_color[2], rgb_color[1], rgb_color[0]), -1)
    
    annotated_rgb = cv2.cvtColor(annotated_bgr, cv2.COLOR_BGR2RGB)
    pil_out = Image.fromarray(annotated_rgb)
    
    buffer = io.BytesIO()
    pil_out.save(buffer, format="JPEG", quality=92)
    base64_str = base64.b64encode(buffer.getvalue()).decode("utf-8")
    
    return {
        "trash_detected": is_trash_detected,
        "road_status": road_status,
        "display_class": road_status,
        "decision": decision_label,
        "trash_count": trash_count if road_status != "No Road Detected" else 0,
        "cleanliness_score": round(cleanliness_score, 1),
        "road_confidence": round(cleanliness_score / 100.0, 3) if road_status != "No Road Detected" else 0.0,
        "badge_color": badge_color,
        "recommendation": recommendation,
        "annotated_image": f"data:image/jpeg;base64,{base64_str}",
        "mobilenet_result": mobilenet_res,
        "model_version": "v7_mobilenetv3",
        "is_road": (road_status != "No Road Detected"),
        "is_trash": is_trash_detected
    }

@app.post("/api/predict")
async def predict_file(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")
    contents = await file.read()
    res = detect_road_trash(contents)
    return JSONResponse(content=res)

@app.get("/api/settings")
async def get_settings():
    global current_confidence, very_dirty_confidence_threshold, clean_road_confidence_threshold
    return JSONResponse(content={
        "confidence_threshold": current_confidence,
        "very_dirty_threshold": very_dirty_confidence_threshold,
        "clean_road_threshold": clean_road_confidence_threshold,
    })

@app.post("/api/settings")
async def update_settings(req: dict):
    global current_confidence, very_dirty_confidence_threshold, clean_road_confidence_threshold
    if "confidence_threshold" in req:
        try:
            val = float(req["confidence_threshold"])
            if 0.05 <= val <= 0.99:
                current_confidence = round(val, 2)
        except (ValueError, TypeError):
            raise HTTPException(status_code=400, detail="Invalid confidence threshold")
    
    v_thresh = req.get("very_dirty_threshold", req.get("very_dirty_confidence_threshold"))
    if v_thresh is not None:
        try:
            val = float(v_thresh)
            if 0.10 <= val <= 0.99:
                very_dirty_confidence_threshold = round(val, 2)
        except (ValueError, TypeError):
            raise HTTPException(status_code=400, detail="Invalid very dirty confidence threshold")
            
    c_thresh = req.get("clean_road_threshold", req.get("clean_road_confidence_threshold"))
    if c_thresh is not None:
        try:
            val = float(c_thresh)
            if 0.10 <= val <= 0.99:
                clean_road_confidence_threshold = round(val, 2)
        except (ValueError, TypeError):
            pass

    return JSONResponse(content={
        "status": "success",
        "confidence_threshold": current_confidence,
        "very_dirty_threshold": very_dirty_confidence_threshold,
        "clean_road_threshold": clean_road_confidence_threshold,
    })

@app.get("/api/sample/{category}/{filename}")
async def predict_sample(category: str, filename: str):
    cat_folder = category.replace("_", " ")
    file_path = RAW_DIR / cat_folder / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Sample image not found.")
    with open(file_path, "rb") as f:
        contents = f.read()
    res = detect_road_trash(contents)
    return JSONResponse(content=res)

@app.get("/", response_class=HTMLResponse)
async def get_dashboard():
    samples = []
    for cat, folder in [("clean_roads", "clean roads"), ("slightly_dirty", "slightly dirty"), ("very_dirty", "very dirty")]:
        p = RAW_DIR / folder
        if p.exists():
            files = list(p.glob("*.jpg"))[:2]
            for f in files:
                samples.append({"category": cat, "filename": f.name, "label": f"{cat.replace('_', ' ').title()} Sample"})
                
    sample_buttons_html = "".join([
        f'<button class="sample-btn" onclick="loadSample(\'{s["category"]}\', \'{s["filename"]}\')">{s["label"]}</button>'
        for s in samples
    ])
    
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Street Cleanliness AI Dashboard — Dual YOLOv8 + MobileNetV3</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {{
            --bg-primary: #0b0f19;
            --bg-card: rgba(17, 24, 39, 0.82);
            --border-card: rgba(255, 255, 255, 0.08);
            --accent-green: #22c55e;
            --accent-red: #ef4444;
            --accent-cyan: #06b6d4;
            --text-primary: #f8fafc;
            --text-muted: #94a3b8;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: 'Outfit', sans-serif;
            background-color: var(--bg-primary);
            background-image: 
                radial-gradient(at 0% 0%, rgba(6, 182, 212, 0.12) 0px, transparent 50%),
                radial-gradient(at 100% 100%, rgba(34, 197, 94, 0.1) 0px, transparent 50%),
                radial-gradient(at 50% 20%, rgba(239, 68, 68, 0.06) 0px, transparent 40%);
            color: var(--text-primary);
            min-height: 100vh;
            padding: 24px;
        }}
        .container {{ max-width: 1320px; margin: 0 auto; }}
        header {{
            display: flex; justify-content: space-between; align-items: center;
            padding-bottom: 24px; margin-bottom: 24px; border-bottom: 1px solid var(--border-card);
        }}
        .brand {{ display: flex; align-items: center; gap: 14px; }}
        .logo-icon {{
            width: 44px; height: 44px;
            background: linear-gradient(135deg, #06b6d4, #3b82f6);
            border-radius: 12px; display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 22px; color: white; box-shadow: 0 0 20px rgba(6, 182, 212, 0.4);
        }}
        .brand-title {{
            font-size: 24px; font-weight: 700; letter-spacing: -0.5px;
            background: linear-gradient(90deg, #ffffff, #94a3b8);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }}
        .badge-live {{
            background: rgba(34, 197, 94, 0.15); color: #4ade80;
            border: 1px solid rgba(74, 222, 128, 0.3); padding: 6px 14px;
            border-radius: 20px; font-size: 13px; font-weight: 600;
            display: flex; align-items: center; gap: 8px;
        }}
        .pulse-dot {{
            width: 8px; height: 8px; background-color: #4ade80; border-radius: 50%;
            animation: pulse 1.8s infinite;
        }}
        @keyframes pulse {{
            0% {{ transform: scale(0.95); box-shadow: 0 0 0 0 rgba(74, 222, 128, 0.7); }}
            70% {{ transform: scale(1); box-shadow: 0 0 0 8px rgba(74, 222, 128, 0); }}
            100% {{ transform: scale(0.95); box-shadow: 0 0 0 0 rgba(74, 222, 128, 0); }}
        }}
        .card {{
            background: var(--bg-card); backdrop-filter: blur(16px);
            border: 1px solid var(--border-card); border-radius: 20px; padding: 24px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
        }}
        .card-header {{
            font-size: 18px; font-weight: 600; margin-bottom: 16px;
            display: flex; justify-content: space-between; align-items: center; color: #e2e8f0;
        }}

        /* Settings Card & Grid */
        .settings-card {{
            margin-bottom: 24px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            background: linear-gradient(180deg, rgba(23, 32, 54, 0.9) 0%, rgba(15, 23, 42, 0.85) 100%);
        }}
        .settings-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 18px;
        }}
        .setting-item {{
            background: rgba(15, 23, 42, 0.65);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 16px;
            padding: 18px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            transition: all 0.3s ease;
        }}
        .setting-item:hover {{
            border-color: rgba(255, 255, 255, 0.18);
        }}
        .setting-item.highlight-red {{
            background: linear-gradient(135deg, rgba(239, 68, 68, 0.1), rgba(15, 23, 42, 0.75));
            border: 1px solid rgba(239, 68, 68, 0.35);
            box-shadow: 0 0 25px rgba(239, 68, 68, 0.1);
        }}
        .setting-item.highlight-red:hover {{
            border-color: rgba(239, 68, 68, 0.6);
            box-shadow: 0 0 30px rgba(239, 68, 68, 0.2);
        }}
        .setting-top {{
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}
        .setting-title {{
            font-size: 15px;
            font-weight: 700;
            color: #f1f5f9;
        }}
        .setting-sub {{
            font-size: 11px;
            color: var(--text-muted);
            margin-top: 2px;
        }}
        .val-badge {{
            font-size: 14px;
            font-weight: 800;
            padding: 4px 12px;
            border-radius: 20px;
            letter-spacing: 0.5px;
        }}
        .badge-red {{
            background: rgba(239, 68, 68, 0.2);
            color: #f87171;
            border: 1px solid rgba(239, 68, 68, 0.4);
        }}
        .badge-cyan {{
            background: rgba(6, 182, 212, 0.2);
            color: #38bdf8;
            border: 1px solid rgba(6, 182, 212, 0.4);
        }}
        .badge-green {{
            background: rgba(34, 197, 94, 0.2);
            color: #4ade80;
            border: 1px solid rgba(34, 197, 94, 0.4);
        }}
        .slider-wrapper {{
            display: flex;
            align-items: center;
            gap: 12px;
        }}
        .slider-wrapper input[type="range"] {{
            flex: 1;
            height: 6px;
            border-radius: 4px;
            background: rgba(255, 255, 255, 0.15);
            outline: none;
            cursor: pointer;
            -webkit-appearance: none;
        }}
        .slider-wrapper input[type="range"]::-webkit-slider-thumb {{
            -webkit-appearance: none;
            width: 18px;
            height: 18px;
            border-radius: 50%;
            background: #f8fafc;
            border: 2px solid var(--accent-cyan);
            cursor: pointer;
            box-shadow: 0 0 10px rgba(6, 182, 212, 0.6);
            transition: all 0.2s ease;
        }}
        .highlight-red .slider-wrapper input[type="range"]::-webkit-slider-thumb {{
            border-color: #ef4444;
            box-shadow: 0 0 12px rgba(239, 68, 68, 0.8);
        }}
        .presets-row {{
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }}
        .preset-chip {{
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: #94a3b8;
            font-size: 11px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 8px;
            cursor: pointer;
            font-family: inherit;
            transition: all 0.2s ease;
        }}
        .preset-chip:hover {{
            background: rgba(255, 255, 255, 0.12);
            color: white;
        }}
        .preset-chip.active {{
            background: rgba(6, 182, 212, 0.25);
            border-color: #06b6d4;
            color: white;
        }}
        .highlight-red .preset-chip.active {{
            background: rgba(239, 68, 68, 0.25);
            border-color: #ef4444;
            color: white;
        }}
        .setting-desc {{
            font-size: 12px;
            color: var(--text-muted);
            line-height: 1.4;
        }}

        .main-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }}
        @media (max-width: 960px) {{ .main-grid {{ grid-template-columns: 1fr; }} }}

        .dropzone {{
            border: 2px dashed rgba(255, 255, 255, 0.15); border-radius: 16px;
            padding: 40px 20px; text-align: center; cursor: pointer; transition: all 0.3s ease;
            background: rgba(15, 23, 42, 0.4); margin-bottom: 20px;
        }}
        .dropzone:hover, .dropzone.dragover {{ border-color: var(--accent-cyan); background: rgba(6, 182, 212, 0.08); }}
        .upload-icon {{
            width: 56px; height: 56px; margin: 0 auto 16px; background: rgba(255, 255, 255, 0.05);
            border-radius: 50%; display: flex; align-items: center; justify-content: center;
        }}
        .sample-section {{ margin-top: 16px; }}
        .sample-title {{ font-size: 13px; color: var(--text-muted); margin-bottom: 10px; text-transform: uppercase; letter-spacing: 0.8px; }}
        .sample-grid {{ display: flex; flex-wrap: wrap; gap: 8px; }}
        .sample-btn {{
            background: rgba(255, 255, 255, 0.06); border: 1px solid rgba(255, 255, 255, 0.1);
            color: #cbd5e1; padding: 8px 14px; border-radius: 10px; font-size: 13px;
            font-family: inherit; cursor: pointer; transition: all 0.2s;
        }}
        .sample-btn:hover {{ background: rgba(6, 182, 212, 0.2); border-color: var(--accent-cyan); color: white; }}
        .preview-container {{
            position: relative; width: 100%; border-radius: 16px; overflow: hidden; background: #000;
            min-height: 280px; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(255, 255, 255, 0.08);
        }}
        .preview-img {{ width: 100%; max-height: 420px; object-fit: contain; display: block; }}
        .score-box {{
            display: flex; align-items: center; gap: 24px; margin-bottom: 24px; padding: 20px;
            background: rgba(15, 23, 42, 0.6); border-radius: 16px; border: 1px solid rgba(255, 255, 255, 0.06);
        }}
        .status-details {{ flex: 1; }}
        .status-label {{ font-size: 13px; color: var(--text-muted); text-transform: uppercase; }}
        .status-title {{ font-size: 22px; font-weight: 700; margin: 4px 0; }}
        .recommendation-box {{
            margin-top: 16px; padding: 16px; border-radius: 12px; background: rgba(255, 255, 255, 0.04);
            border-left: 4px solid var(--accent-cyan); font-size: 14px; line-height: 1.5; color: #cbd5e1;
        }}
        .spinner {{
            width: 36px; height: 36px; border: 4px solid rgba(255, 255, 255, 0.1);
            border-left-color: var(--accent-cyan); border-radius: 50%; animation: spin 1s linear infinite; display: none;
        }}
        @keyframes spin {{ 100% {{ transform: rotate(360deg); }} }}
    </style>
</head>
<body>

<div class="container">
    <header>
        <div class="brand">
            <div class="logo-icon">AIQ</div>
            <div>
                <div class="brand-title">Street Cleanliness AI Dashboard</div>
                <div style="font-size: 13px; color: var(--text-muted);">Dual-Model AI Engine: YOLOv8 Object Detection + MobileNetV3 Cleanliness Classification</div>
            </div>
        </div>
        <div class="badge-live">
            <div class="pulse-dot"></div> Dual-Model Pipeline Active (Port 5001)
        </div>
    </header>

    <!-- AI Model Settings Section -->
    <div class="card settings-card">
        <div class="card-header" style="margin-bottom: 16px;">
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="width: 32px; height: 32px; border-radius: 8px; background: rgba(6, 182, 212, 0.15); display: flex; align-items: center; justify-content: center;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                </div>
                <div>
                    <span style="font-size: 17px; font-weight: 700; color: #f8fafc;">AI Model Settings &amp; Confidence Thresholds</span>
                    <div style="font-size: 12px; color: var(--text-muted); font-weight: 400;">Real-time dual-model sensitivity controls &amp; decision boundaries</div>
                </div>
            </div>
            <div id="saveStatus" style="font-size: 12px; color: #4ade80; display: flex; align-items: center; gap: 6px; opacity: 0; transition: opacity 0.3s ease;">
                <span>✓ Settings synced live</span>
            </div>
        </div>

        <div class="settings-grid">
            <!-- Setting 1: Very Dirty Road Confidence Level Setter (MobileNetV3) -->
            <div class="setting-item highlight-red">
                <div class="setting-top">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 18px;">🚨</span>
                        <div>
                            <div class="setting-title" style="color: #f87171;">Very Dirty Road Confidence Level</div>
                            <div class="setting-sub">MobileNetV3 Classifier Escalation Threshold</div>
                        </div>
                    </div>
                    <div class="val-badge badge-red" id="veryDirtyVal">50%</div>
                </div>
                <div class="slider-wrapper">
                    <input type="range" id="veryDirtySlider" min="0.20" max="0.95" step="0.05" value="0.50" oninput="onThresholdChange('very_dirty', this.value)">
                </div>
                <div class="presets-row">
                    <button type="button" class="preset-chip" onclick="setPreset('very_dirty', 0.35)">35% Sensitive</button>
                    <button type="button" class="preset-chip active" onclick="setPreset('very_dirty', 0.50)">50% Balanced</button>
                    <button type="button" class="preset-chip" onclick="setPreset('very_dirty', 0.70)">70% Strict</button>
                    <button type="button" class="preset-chip" onclick="setPreset('very_dirty', 0.85)">85% Severe</button>
                </div>
                <div class="setting-desc">
                    When YOLO flags trash, MobileNetV3 must predict "Very Dirty" with &ge; this confidence to trigger <strong>VERY DIRTY ROAD</strong> (red alert) instead of standard trash detected.
                </div>
            </div>

            <!-- Setting 2: YOLO Detection Confidence -->
            <div class="setting-item">
                <div class="setting-top">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 18px;">🎯</span>
                        <div>
                            <div class="setting-title">YOLOv8 Detection Confidence</div>
                            <div class="setting-sub">Object Detection Bounding Box Threshold</div>
                        </div>
                    </div>
                    <div class="val-badge badge-cyan" id="yoloVal">25%</div>
                </div>
                <div class="slider-wrapper">
                    <input type="range" id="yoloSlider" min="0.10" max="0.90" step="0.05" value="0.25" oninput="onThresholdChange('yolo', this.value)">
                </div>
                <div class="presets-row">
                    <button type="button" class="preset-chip" onclick="setPreset('yolo', 0.15)">15% Sensitive</button>
                    <button type="button" class="preset-chip active" onclick="setPreset('yolo', 0.25)">25% Default</button>
                    <button type="button" class="preset-chip" onclick="setPreset('yolo', 0.40)">40% Moderate</button>
                    <button type="button" class="preset-chip" onclick="setPreset('yolo', 0.60)">60% Strict</button>
                </div>
                <div class="setting-desc">
                    Initial stage: Minimum neural confidence to identify road trash candidates and draw bounding boxes.
                </div>
            </div>

            <!-- Setting 3: Clean Road Verification Threshold -->
            <div class="setting-item">
                <div class="setting-top">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 18px;">🌿</span>
                        <div>
                            <div class="setting-title">Clean Road Filter Threshold</div>
                            <div class="setting-sub">MobileNetV3 False-Positive Suppression</div>
                        </div>
                    </div>
                    <div class="val-badge badge-green" id="cleanVal">55%</div>
                </div>
                <div class="slider-wrapper">
                    <input type="range" id="cleanSlider" min="0.30" max="0.90" step="0.05" value="0.55" oninput="onThresholdChange('clean', this.value)">
                </div>
                <div class="presets-row">
                    <button type="button" class="preset-chip" onclick="setPreset('clean', 0.45)">45% Relaxed</button>
                    <button type="button" class="preset-chip active" onclick="setPreset('clean', 0.55)">55% Default</button>
                    <button type="button" class="preset-chip" onclick="setPreset('clean', 0.70)">70% Strict</button>
                </div>
                <div class="setting-desc">
                    MobileNetV3 confidence to override YOLO candidate detections back to verified <strong>Clean Road</strong>.
                </div>
            </div>
        </div>
    </div>

    <div class="main-grid">
        <div class="card">
            <div class="card-header">
                <span>Upload Road Image</span>
                <span style="font-size: 13px; color: var(--text-muted);">JPG / PNG</span>
            </div>
            
            <div class="dropzone" id="dropzone" onclick="document.getElementById('fileInput').click()">
                <div class="upload-icon">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="17 8 12 3 7 8"></polyline>
                        <line x1="12" y1="3" x2="12" y2="15"></line>
                    </svg>
                </div>
                <div style="font-weight: 600; font-size: 16px; margin-bottom: 4px;">Drag & Drop or Click to Upload</div>
                <div style="font-size: 13px; color: var(--text-muted);">Dual YOLOv8 + MobileNetV3 Engine</div>
                <input type="file" id="fileInput" accept="image/*" style="display:none" onchange="handleFileUpload(this.files[0])">
            </div>

            <div class="sample-section">
                <div class="sample-title">⚡ 1-Click Test Samples</div>
                <div class="sample-grid">
                    {sample_buttons_html}
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <span>AI Pipeline Detection Analysis</span>
                <span id="confBadge" style="font-size: 13px; color: #4ade80; font-weight: 700;">--</span>
            </div>

            <div class="preview-container">
                <div class="spinner" id="spinner"></div>
                <img id="previewImg" class="preview-img" src="" alt="Road Preview" style="display:none;">
                <div id="placeholderText" style="color: var(--text-muted); font-size: 14px; text-align: center; padding: 20px;">
                    📷 Upload an image or select a sample above to inspect dual-model classification.
                </div>
            </div>

            <div id="resultsSection" style="margin-top: 24px; display: none;">
                <div class="score-box">
                    <div class="status-details">
                        <div class="status-label">Detection Status</div>
                        <div class="status-title" id="statusTitle">--</div>
                        <div style="font-size: 13px; color: var(--text-muted);" id="confidenceText">Trash Regions Found: 0</div>
                        <div id="mobilenetResultBox" style="margin-top: 8px; font-size: 12px; color: #94a3b8;">--</div>
                    </div>
                </div>

                <div class="recommendation-box" id="recommendationText">--</div>
            </div>
        </div>
    </div>
</div>

<script>
    const dropzone = document.getElementById('dropzone');
    let settingsDebounceTimer = null;

    dropzone.addEventListener('dragover', (e) => {{ e.preventDefault(); dropzone.classList.add('dragover'); }});
    dropzone.addEventListener('dragleave', () => {{ dropzone.classList.remove('dragover'); }});
    dropzone.addEventListener('drop', (e) => {{
        e.preventDefault(); dropzone.classList.remove('dragover');
        if (e.dataTransfer.files.length > 0) handleFileUpload(e.dataTransfer.files[0]);
    }});

    async function fetchSettings() {{
        try {{
            const res = await fetch('/api/settings');
            if (res.ok) {{
                const data = await res.json();
                applySettingsToUI(data);
            }}
        }} catch (e) {{
            console.error('Failed to load settings:', e);
        }}
    }}

    function applySettingsToUI(data) {{
        if (data.very_dirty_threshold !== undefined) {{
            const v = data.very_dirty_threshold;
            const slider = document.getElementById('veryDirtySlider');
            if (slider) slider.value = v;
            const badge = document.getElementById('veryDirtyVal');
            if (badge) badge.innerText = `${{Math.round(v * 100)}}%`;
            updatePresetActive('very_dirty', v);
        }}
        if (data.confidence_threshold !== undefined) {{
            const y = data.confidence_threshold;
            const slider = document.getElementById('yoloSlider');
            if (slider) slider.value = y;
            const badge = document.getElementById('yoloVal');
            if (badge) badge.innerText = `${{Math.round(y * 100)}}%`;
            updatePresetActive('yolo', y);
        }}
        if (data.clean_road_threshold !== undefined) {{
            const c = data.clean_road_threshold;
            const slider = document.getElementById('cleanSlider');
            if (slider) slider.value = c;
            const badge = document.getElementById('cleanVal');
            if (badge) badge.innerText = `${{Math.round(c * 100)}}%`;
            updatePresetActive('clean', c);
        }}
    }}

    function updatePresetActive(type, val) {{
        const targetClass = type === 'very_dirty' ? '.highlight-red .presets-row' : null;
        let parent = null;
        if (type === 'very_dirty') {{
            parent = document.querySelector('.highlight-red .presets-row');
        }} else if (type === 'yolo') {{
            const rows = document.querySelectorAll('.presets-row');
            if (rows.length > 1) parent = rows[1];
        }} else if (type === 'clean') {{
            const rows = document.querySelectorAll('.presets-row');
            if (rows.length > 2) parent = rows[2];
        }}
        if (!parent) return;
        const chips = parent.querySelectorAll('.preset-chip');
        chips.forEach(chip => {{
            const match = chip.innerText.includes(`${{Math.round(val * 100)}}%`);
            if (match) chip.classList.add('active');
            else chip.classList.remove('active');
        }});
    }}

    function onThresholdChange(type, value) {{
        const numVal = parseFloat(value);
        if (type === 'very_dirty') {{
            document.getElementById('veryDirtyVal').innerText = `${{Math.round(numVal * 100)}}%`;
        }} else if (type === 'yolo') {{
            document.getElementById('yoloVal').innerText = `${{Math.round(numVal * 100)}}%`;
        }} else if (type === 'clean') {{
            document.getElementById('cleanVal').innerText = `${{Math.round(numVal * 100)}}%`;
        }}
        updatePresetActive(type, numVal);

        clearTimeout(settingsDebounceTimer);
        settingsDebounceTimer = setTimeout(() => {{
            saveSettings();
        }}, 350);
    }}

    function setPreset(type, val) {{
        if (type === 'very_dirty') {{
            document.getElementById('veryDirtySlider').value = val;
            document.getElementById('veryDirtyVal').innerText = `${{Math.round(val * 100)}}%`;
        }} else if (type === 'yolo') {{
            document.getElementById('yoloSlider').value = val;
            document.getElementById('yoloVal').innerText = `${{Math.round(val * 100)}}%`;
        }} else if (type === 'clean') {{
            document.getElementById('cleanSlider').value = val;
            document.getElementById('cleanVal').innerText = `${{Math.round(val * 100)}}%`;
        }}
        updatePresetActive(type, val);
        saveSettings();
    }}

    async function saveSettings() {{
        const payload = {{
            confidence_threshold: parseFloat(document.getElementById('yoloSlider').value),
            very_dirty_threshold: parseFloat(document.getElementById('veryDirtySlider').value),
            clean_road_threshold: parseFloat(document.getElementById('cleanSlider').value)
        }};
        try {{
            const res = await fetch('/api/settings', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify(payload)
            }});
            if (res.ok) {{
                const statusEl = document.getElementById('saveStatus');
                if (statusEl) {{
                    statusEl.style.opacity = '1';
                    setTimeout(() => {{ statusEl.style.opacity = '0'; }}, 2200);
                }}
            }}
        }} catch (e) {{
            console.error('Error saving settings:', e);
        }}
    }}

    async function handleFileUpload(file) {{
        if (!file) return;
        showLoading();
        const formData = new FormData();
        formData.append('file', file);
        try {{
            const response = await fetch('/api/predict', {{ method: 'POST', body: formData }});
            const data = await response.json();
            renderResults(data);
        }} catch (err) {{
            alert('Error running inference.'); console.error(err);
        }}
    }}

    async function loadSample(category, filename) {{
        showLoading();
        try {{
            const response = await fetch(`/api/sample/${{category}}/${{filename}}`);
            const data = await response.json();
            renderResults(data);
        }} catch (err) {{
            alert('Error loading sample image.'); console.error(err);
        }}
    }}

    function showLoading() {{
        document.getElementById('placeholderText').style.display = 'none';
        document.getElementById('previewImg').style.display = 'none';
        document.getElementById('spinner').style.display = 'block';
        document.getElementById('resultsSection').style.display = 'none';
    }}

    function renderResults(data) {{
        document.getElementById('spinner').style.display = 'none';
        const img = document.getElementById('previewImg');
        img.src = data.annotated_image;
        img.style.display = 'block';

        document.getElementById('resultsSection').style.display = 'block';

        const titleEl = document.getElementById('statusTitle');
        titleEl.innerText = data.decision;
        titleEl.style.color = data.badge_color;

        document.getElementById('confidenceText').innerText = `Detected Bounding Boxes: ${{data.trash_count}}`;
        document.getElementById('confBadge').innerText = data.trash_detected ? (data.road_status === 'Very Dirty Road' ? 'VERY DIRTY' : 'TRASH DETECTED') : 'CLEAN ROAD';
        document.getElementById('confBadge').style.color = data.badge_color;
        document.getElementById('recommendationText').innerText = data.recommendation;
        document.getElementById('recommendationText').style.borderLeftColor = data.badge_color;

        const mBox = document.getElementById('mobilenetResultBox');
        if (mBox) {{
            const m = data.mobilenet_result || {{}};
            if (m.invoked) {{
                const dirtyPct = Math.round((m.prob_very_dirty || 0) * 100);
                const cleanPct = Math.round((m.prob_clean || 0) * 100);
                const activeThresh = Math.round(parseFloat(document.getElementById('veryDirtySlider').value) * 100);
                const statusTag = crossed ? '🚨 Exceeded' : 'Under';
                const tagColor = crossed ? '#f87171' : '#cbd5e1';
                mBox.innerHTML = `🔬 <strong>MobileNetV3 Classification:</strong> Dirty: <span style="color:${{tagColor}}; font-weight:700;">${{dirtyPct}}%</span> (Threshold: ${{activeThresh}}% ${{statusTag}}) &bull; Clean: ${{cleanPct}}%`;
            }} else {{
                mBox.innerHTML = `🔬 <strong>MobileNetV3 Classification:</strong> Bypassed (0 YOLO Trash candidates detected &bull; Clean Road)`;
            }}
        }}
    }}

    window.onload = async () => {{
        await fetchSettings();
        const firstBtn = document.querySelector('.sample-btn');
        if (firstBtn) firstBtn.click();
    }};
</script>
</body>
</html>"""
    return html_content
class FrameRequest(BaseModel):
    image: str
    lat: float = 0.0
    lng: float = 0.0
    vehicle_number: str = ""
    ward: str = ""
    zone: str = ""
    session_id: str = None
    point_type: str = None

@app.post("/process_frame")
async def process_frame(req: FrameRequest):
    encoded = req.image.split(",", 1)[1] if "," in req.image else req.image
    img_bytes = base64.b64decode(encoded)
    
    uid = str(uuid.uuid4())
    raw_filename = f"raw_{uid}.jpg"
    filename = f"{uid}.jpg"

    # 1. Run integrated AI detection (YOLOv7 + MobileNetV3)
    res = detect_road_trash(img_bytes)
    road_status = res.get("road_status", "Clean Road" if res["trash_count"] == 0 else "Trash Detected")
    display_class = res.get("display_class", road_status)
    
    if road_status == "No Road Detected":
        cat_subfolder = "no_road_detected"
    elif not res.get("trash_detected", True) or road_status == "Clean Road" or road_status == "No Trash Detected":
        cat_subfolder = "no_trash_detected"
    else:
        cat_subfolder = "trash_detected"

    # 2. Save pure raw image (NO annotations) into separate training folder
    training_target = SNAPSHOTS_DIR / "training" / cat_subfolder / raw_filename
    with open(training_target, "wb") as f:
        f.write(img_bytes)

    # 3. Save annotated image with bounding boxes & banner into separate analysed folder
    out_encoded = res["annotated_image"].split(",", 1)[1] if "," in res["annotated_image"] else res["annotated_image"]
    out_bytes = base64.b64decode(out_encoded)
    analysed_target = SNAPSHOTS_DIR / "analysed" / cat_subfolder / filename
    with open(analysed_target, "wb") as f:
        f.write(out_bytes)

    image_url = f"/snapshots/analysed/{cat_subfolder}/{filename}"
    raw_image_url = f"/snapshots/training/{cat_subfolder}/{raw_filename}"

    snapshot = {
        "id": uid,
        "display_class": display_class,
        "road_status": road_status,
        "decision": res.get("decision", ""),
        "training_tag": road_status,  # Tagged with model detection for training
        "confidence": res["cleanliness_score"] / 100.0,
        "road_confidence": res["cleanliness_score"] / 100.0,
        "cleanliness_score": res.get("cleanliness_score", 100.0),
        "badge_color": res.get("badge_color", "#22c55e"),
        "recommendation": res.get("recommendation", ""),
        "image_url": image_url,          # Analysed image (with bounding boxes & banners)
        "raw_image_url": raw_image_url,  # Raw captured image (ZERO annotations)
        "trash_count": res.get("trash_count", 0),
        "lat": req.lat,
        "lng": req.lng,
        "vehicle_number": req.vehicle_number,
        "ward": req.ward,
        "zone": req.zone,
        "timestamp": datetime.now().strftime("%Y-%m-%d %I:%M:%S %p"),
        "model_version": "v7_mobilenetv3",
        "mobilenet_result": res.get("mobilenet_result", {})
    }
    
    history.append(snapshot)
    if len(history) > 1000:
        history.pop(0)
        
    import json
    try:
        with open(HISTORY_FILE, "w") as f:
            json.dump(history, f)
    except Exception as e:
        print("Error saving history:", e)

    return snapshot

@app.get("/api/snapshots")
async def api_snapshots():
    for s in history:
        if "raw_image_url" not in s:
            s["raw_image_url"] = s.get("image_url")
        if "training_tag" not in s:
            s["training_tag"] = s.get("display_class", s.get("road_status", "No Trash Detected"))
    return {"snapshots": history}

@app.get("/api/training_dataset")
async def api_training_dataset():
    training_items = []
    for s in history:
        training_items.append({
            "id": s.get("id", ""),
            "raw_image_url": s.get("raw_image_url", s.get("image_url")),
            "training_tag": s.get("training_tag", s.get("road_status", "No Trash Detected")),
            "timestamp": s.get("timestamp", ""),
            "vehicle_number": s.get("vehicle_number", ""),
            "lat": s.get("lat", 0.0),
            "lng": s.get("lng", 0.0),
        })
    return {"training_dataset": training_items, "total": len(training_items)}

if __name__ == "__main__":
    # You might want to change the port if v5 is also running. Defaulting to 5001.
    uvicorn.run(app, host="0.0.0.0", port=5002)
