import os
import sys
import torch
from ultralytics import YOLO

# Project paths
PROJECT_ROOT = r"e:\nitin\models\Garbage_ai_model_v6"
DATA_YAML = os.path.join(PROJECT_ROOT, "configs", "data.yaml")
WEIGHTS_DIR = os.path.join(PROJECT_ROOT, "weights")
RUNS_DIR = os.path.join(PROJECT_ROOT, "runs")

os.makedirs(WEIGHTS_DIR, exist_ok=True)
os.makedirs(RUNS_DIR, exist_ok=True)

def train_garbage_v6():
    print("=" * 60)
    print("      Garbage_ai_model_v6 (YOLOv8m) Training Pipeline      ")
    print("=" * 60)
    
    # Check GPU availability
    device = 0 if torch.cuda.is_available() else "cpu"
    device_name = torch.cuda.get_device_name(0) if torch.cuda.is_available() else "CPU"
    print(f"Hardware Compute Device: {device} ({device_name})")
    print(f"Data Configuration: {DATA_YAML}")
    print(f"Model Backbone: yolov8m.pt")
    print(f"Epochs: 100")
    print("-" * 60)
    
    # Initialize YOLOv8 Medium model
    model = YOLO("yolov8m.pt")
    
    # Train model
    results = model.train(
        data=DATA_YAML,
        epochs=100,
        imgsz=640,
        batch=16,
        device=device,
        project=RUNS_DIR,
        name="garbage_ai_v6_experiment",
        exist_ok=True,
        pretrained=True,
        optimizer="auto",
        verbose=True,
        seed=42,
        val=True,
        save=True,
        plots=True,
        close_mosaic=15,
        # Augmentations tuned for robust road trash detection with background images
        mosaic=0.5,
        mixup=0.1,
        degrees=10.0,
        translate=0.1,
        scale=0.5,
        shear=2.0,
        perspective=0.0005,
        flipud=0.0,
        fliplr=0.5,
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        erasing=0.0,
    )
    
    print("\nTraining completed successfully!")
    print(f"Best model weights saved in runs experiment: {results.save_dir}")
    
    # Copy best model to weights folder
    best_pt_path = os.path.join(results.save_dir, "weights", "best.pt")
    target_best_pt = os.path.join(WEIGHTS_DIR, "garbage_ai_model_v6_best.pt")
    
    if os.path.exists(best_pt_path):
        import shutil
        shutil.copy2(best_pt_path, target_best_pt)
        print(f"Copied best model weights to: {target_best_pt}")
    
    # Run final evaluation on test set
    print("\nRunning evaluation on test set...")
    val_model = YOLO(target_best_pt if os.path.exists(target_best_pt) else best_pt_path)
    metrics = val_model.val(data=DATA_YAML, split="test", imgsz=640, device=device)
    
    print("\n================ FINAL TEST METRICS ================")
    print(f"mAP50:     {metrics.box.map50:.4f}")
    print(f"mAP50-95:  {metrics.box.map:.4f}")
    print(f"Precision: {metrics.box.mp:.4f}")
    print(f"Recall:    {metrics.box.mr:.4f}")
    print("====================================================")

if __name__ == "__main__":
    train_garbage_v6()
