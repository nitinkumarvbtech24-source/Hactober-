import os
import glob
import shutil
import cv2

DATASET_ROOT = r"e:\nitin\models\datasets"
TARGET_DIR = r"e:\nitin\models\datasets"

SUBSETS = [
    {"name": "ds1_trash_v2i", "path": os.path.join(DATASET_ROOT, "Trash.v2i.yolov8")},
    {"name": "ds2_aiq_trash", "path": os.path.join(DATASET_ROOT, "aiq trash detection 1.v2i.yolov8")},
    {"name": "ds3_box_ann", "path": os.path.join(DATASET_ROOT, "box annotations", "box annotations")},
]

SPLIT_MAP = {
    "train": "train",
    "valid": "val",
    "val": "val",
    "test": "test"
}

def analyze_and_merge():
    stats = {
        "train": {"images": 0, "labels": 0, "empty_labels": 0, "boxes": 0},
        "val": {"images": 0, "labels": 0, "empty_labels": 0, "boxes": 0},
        "test": {"images": 0, "labels": 0, "empty_labels": 0, "boxes": 0}
    }
    
    # Ensure target subdirectories exist
    for split in ["train", "val", "test"]:
        os.makedirs(os.path.join(TARGET_DIR, "images", split), exist_ok=True)
        os.makedirs(os.path.join(TARGET_DIR, "labels", split), exist_ok=True)

    print("Starting dataset analysis and merging...")
    
    for sub in SUBSETS:
        sub_prefix = sub["name"]
        sub_path = sub["path"]
        print(f"\nProcessing {sub_prefix} at: {sub_path}")
        
        for folder_name in os.listdir(sub_path):
            folder_path = os.path.join(sub_path, folder_name)
            if not os.path.isdir(folder_path) or folder_name not in SPLIT_MAP:
                continue
            
            target_split = SPLIT_MAP[folder_name]
            
            # Locate images and labels directories in this subset folder
            images_dir = os.path.join(folder_path, "images") if os.path.exists(os.path.join(folder_path, "images")) else folder_path
            labels_dir = os.path.join(folder_path, "labels") if os.path.exists(os.path.join(folder_path, "labels")) else folder_path
            
            # Gather images
            image_extensions = ("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.webp")
            image_files = []
            for ext in image_extensions:
                image_files.extend(glob.glob(os.path.join(images_dir, ext)))
                image_files.extend(glob.glob(os.path.join(images_dir, ext.upper())))
                
            print(f"  Found {len(image_files)} images in '{folder_name}' split -> mapping to '{target_split}'")
            
            for img_path in image_files:
                base_name = os.path.basename(img_path)
                name_no_ext, ext = os.path.splitext(base_name)
                
                # New unique filename to avoid collision across 3 datasets
                new_img_name = f"{sub_prefix}_{name_no_ext}{ext}"
                new_lbl_name = f"{sub_prefix}_{name_no_ext}.txt"
                
                dst_img_path = os.path.join(TARGET_DIR, "images", target_split, new_img_name)
                dst_lbl_path = os.path.join(TARGET_DIR, "labels", target_split, new_lbl_name)
                
                # Copy Image
                shutil.copy2(img_path, dst_img_path)
                stats[target_split]["images"] += 1
                
                # Look for matching label file
                src_lbl_path = os.path.join(labels_dir, f"{name_no_ext}.txt")
                if not os.path.exists(src_lbl_path):
                    # Also try checking if label file is in folder_path directly
                    src_lbl_path = os.path.join(folder_path, f"{name_no_ext}.txt")
                    
                if os.path.exists(src_lbl_path):
                    stats[target_split]["labels"] += 1
                    # Read and normalize label lines to class 0
                    normalized_lines = []
                    with open(src_lbl_path, "r", encoding="utf-8") as f:
                        lines = f.readlines()
                    
                    if len(lines) == 0:
                        stats[target_split]["empty_labels"] += 1
                    
                    for line in lines:
                        parts = line.strip().split()
                        if len(parts) >= 5:
                            # Force class_id to 0 for single-class trash detection
                            parts[0] = "0"
                            normalized_lines.append(" ".join(parts) + "\n")
                            stats[target_split]["boxes"] += 1
                            
                    with open(dst_lbl_path, "w", encoding="utf-8") as f:
                        f.writelines(normalized_lines)
                else:
                    # Create empty label file for background sample
                    with open(dst_lbl_path, "w", encoding="utf-8") as f:
                        f.write("")
                    stats[target_split]["empty_labels"] += 1

    print("\n================ DATASET MERGE SUMMARY ================")
    for split, s in stats.items():
        print(f"Split [{split.upper()}]:")
        print(f"  Total Images: {s['images']}")
        print(f"  Total Label Files: {s['labels']}")
        print(f"  Empty/Background Labels: {s['empty_labels']}")
        print(f"  Total Bounding Boxes: {s['boxes']}")

if __name__ == "__main__":
    analyze_and_merge()
