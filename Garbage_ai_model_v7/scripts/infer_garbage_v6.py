import os
import glob
import cv2
from ultralytics import YOLO

PROJECT_ROOT = r"e:\nitin\models\Garbage_ai_model_v6"
MODEL_PATH = os.path.join(PROJECT_ROOT, "weights", "garbage_ai_model_v6_best.pt")
TEST_IMAGES_DIR = r"e:\nitin\models\datasets\images\test"
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "runs", "inference_samples")

os.makedirs(OUTPUT_DIR, exist_ok=True)

def run_inference(conf_thresh=0.25):
    print("=" * 60)
    print("      Garbage_ai_model_v6 Inference Verification      ")
    print("=" * 60)
    
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model weights not found at {MODEL_PATH}")
        return

    print(f"Loading trained model: {MODEL_PATH}")
    model = YOLO(MODEL_PATH)
    
    test_imgs = glob.glob(os.path.join(TEST_IMAGES_DIR, "*.*"))
    print(f"Running inference on {len(test_imgs)} test images...")
    
    total_detections = 0
    for idx, img_path in enumerate(test_imgs):
        results = model.predict(source=img_path, conf=conf_thresh, imgsz=640, verbose=False)
        res = results[0]
        
        # Save visual output image with bounding boxes
        annotated_img = res.plot()
        out_name = f"pred_{os.path.basename(img_path)}"
        out_path = os.path.join(OUTPUT_DIR, out_name)
        cv2.imwrite(out_path, annotated_img)
        
        num_boxes = len(res.boxes)
        total_detections += num_boxes
        if idx < 10:
            print(f" Image {idx+1}/{len(test_imgs)}: {os.path.basename(img_path)} -> {num_boxes} trash detected")

    print(f"\nInference complete! Processed {len(test_imgs)} images, detected {total_detections} trash items.")
    print(f"Annotated test predictions saved to: {OUTPUT_DIR}")

if __name__ == "__main__":
    run_inference()
