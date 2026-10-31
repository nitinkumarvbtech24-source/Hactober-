import os
import glob
import shutil
import random

DATASET_ROOT = r"e:\nitin\models\datasets"
NO_TRASH_DIR = os.path.join(DATASET_ROOT, "no trash roads")

def integrate_background_images(sample_count=85, seed=42):
    """
    Integrates clean road images as hard negatives (background images with empty .txt labels).
    
    Why sample_count=85?
    The current positive training set has 244 images.
    Ultralytics YOLO guidelines recommend ~15-20% background images to eliminate
    false positives without overwhelming the positive trash examples.
    - Train: 60 clean images (~20% of train)
    - Val:   15 clean images (~18% of val)
    - Test:  10 clean images (~23% of test)
    """
    random.seed(seed)
    
    # 1. Find all clean road images
    img_extensions = ("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.webp")
    all_clean_imgs = []
    for ext in img_extensions:
        all_clean_imgs.extend(glob.glob(os.path.join(NO_TRASH_DIR, ext)))
        all_clean_imgs.extend(glob.glob(os.path.join(NO_TRASH_DIR, ext.upper())))
    
    all_clean_imgs = list(set(all_clean_imgs))
    all_clean_imgs.sort()
    
    total_found = len(all_clean_imgs)
    print(f"Found {total_found} clean road images in '{NO_TRASH_DIR}'")
    if total_found == 0:
        print("Error: No images found!")
        return
        
    # Shuffle with fixed seed for diverse selection across different video sequences
    shuffled = all_clean_imgs.copy()
    random.shuffle(shuffled)
    
    if sample_count and sample_count < total_found:
        selected = shuffled[:sample_count]
        print(f"Selected {len(selected)} diverse clean images (balanced ~18% background ratio).")
    else:
        selected = shuffled
        print(f"Using all {len(selected)} clean images.")
        
    # Split: ~70% train, ~18% val, ~12% test
    n_total = len(selected)
    n_train = int(n_total * 0.70)
    n_val = int(n_total * 0.18)
    n_test = n_total - n_train - n_val
    
    splits = {
        "train": selected[:n_train],
        "val": selected[n_train:n_train + n_val],
        "test": selected[n_train + n_val:]
    }
    
    print(f"\nDistribution plan:")
    print(f"  - train: {len(splits['train'])} background images")
    print(f"  - val:   {len(splits['val'])} background images")
    print(f"  - test:  {len(splits['test'])} background images")
    
    # 2. Copy images and create EMPTY .txt label files
    stats = {"train": 0, "val": 0, "test": 0}
    
    for split, img_list in splits.items():
        img_dest_dir = os.path.join(DATASET_ROOT, "images", split)
        lbl_dest_dir = os.path.join(DATASET_ROOT, "labels", split)
        os.makedirs(img_dest_dir, exist_ok=True)
        os.makedirs(lbl_dest_dir, exist_ok=True)
        
        for src_img_path in img_list:
            base_name = os.path.basename(src_img_path)
            name_no_ext, ext = os.path.splitext(base_name)
            
            # Destination filenames with bg_ prefix to prevent collisions
            dest_img_name = f"bg_{name_no_ext}{ext}"
            dest_lbl_name = f"bg_{name_no_ext}.txt"
            
            dest_img_path = os.path.join(img_dest_dir, dest_img_name)
            dest_lbl_path = os.path.join(lbl_dest_dir, dest_lbl_name)
            
            # Copy image
            shutil.copy2(src_img_path, dest_img_path)
            
            # Create completely EMPTY .txt file (0 bytes) for YOLO background image
            with open(dest_lbl_path, "w", encoding="utf-8") as f:
                pass  # Empty file
                
            stats[split] += 1
            
    # 3. Clean any existing YOLO caches so it rescans fresh background labels
    cache_files = glob.glob(os.path.join(DATASET_ROOT, "labels", "*.cache"))
    for cf in cache_files:
        try:
            os.remove(cf)
            print(f"Removed stale cache: {cf}")
        except Exception as e:
            print(f"Warning: could not remove cache {cf}: {e}")
            
    print("\n================ INTEGRATION COMPLETE ================")
    for split, count in stats.items():
        print(f"  Added {count} clean background images (+ empty .txt labels) to [{split}]")
    print("YOLO dataset is now configured with hard negative background images!")

if __name__ == "__main__":
    integrate_background_images()
