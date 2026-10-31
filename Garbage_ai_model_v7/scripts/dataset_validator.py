import os
import glob
import cv2

DATASET_DIR = r"e:\nitin\models\datasets"

def validate_dataset():
    print("Starting dataset validation...")
    issues = []
    total_imgs = 0
    total_valid_boxes = 0
    
    for split in ["train", "val", "test"]:
        img_dir = os.path.join(DATASET_DIR, "images", split)
        lbl_dir = os.path.join(DATASET_DIR, "labels", split)
        
        img_files = glob.glob(os.path.join(img_dir, "*.*"))
        print(f"\nValidating [{split.upper()}] split ({len(img_files)} images)...")
        
        for img_path in img_files:
            total_imgs += 1
            base_name = os.path.basename(img_path)
            name_no_ext = os.path.splitext(base_name)[0]
            lbl_path = os.path.join(lbl_dir, f"{name_no_ext}.txt")
            
            # Check image readability
            img = cv2.imread(img_path)
            if img is None:
                issues.append(f"Corrupted image: {img_path}")
                continue
                
            h, w, c = img.shape
            if h <= 0 or w <= 0:
                issues.append(f"Invalid image dimensions ({w}x{h}): {img_path}")
                continue
                
            if not os.path.exists(lbl_path):
                issues.append(f"Missing label file: {lbl_path}")
                continue
                
            # Validate bounding boxes
            with open(lbl_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                
            for idx, line in enumerate(lines):
                parts = line.strip().split()
                if len(parts) != 5:
                    issues.append(f"Invalid label format line {idx+1} in {lbl_path}: '{line.strip()}'")
                    continue
                try:
                    cls_id, cx, cy, bw, bh = int(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]), float(parts[4])
                    if cls_id != 0:
                        issues.append(f"Class ID {cls_id} != 0 in {lbl_path}")
                    if not (0 <= cx <= 1 and 0 <= cy <= 1 and 0 < bw <= 1 and 0 < bh <= 1):
                        issues.append(f"Out of bounds bbox [{cx}, {cy}, {bw}, {bh}] in {lbl_path}")
                    total_valid_boxes += 1
                except ValueError:
                    issues.append(f"Non-numeric values in line {idx+1} in {lbl_path}: '{line.strip()}'")

    print("\n================ VALIDATION RESULTS ================")
    print(f"Total Verified Images: {total_imgs}")
    print(f"Total Verified Bounding Boxes: {total_valid_boxes}")
    if issues:
        print(f"FOUND {len(issues)} ISSUES:")
        for issue in issues[:20]:
            print(f"  - {issue}")
        if len(issues) > 20:
            print(f"  ... and {len(issues) - 20} more issues.")
    else:
        print("[OK] DATASET IS 100% CLEAN AND VALIDATED WITH ZERO ERRORS!")

if __name__ == "__main__":
    validate_dataset()
