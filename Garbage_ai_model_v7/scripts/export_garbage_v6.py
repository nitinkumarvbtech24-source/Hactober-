import os
from ultralytics import YOLO

PROJECT_ROOT = r"e:\nitin\models\Garbage_ai_model_v6"
MODEL_PATH = os.path.join(PROJECT_ROOT, "weights", "garbage_ai_model_v6_best.pt")

def export_model():
    print("Exporting best PyTorch model to ONNX format...")
    model = YOLO(MODEL_PATH)
    onnx_path = model.export(format="onnx", imgsz=640, dynamic=True)
    print(f"ONNX model exported successfully to: {onnx_path}")

if __name__ == "__main__":
    export_model()
