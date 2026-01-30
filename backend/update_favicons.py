import os
from PIL import Image

# Config
ASSET_LOGO = r"e:\Arun_Finance\frontend\assets\logo.png"
WEB_DIR = r"e:\Arun_Finance\frontend\web"

# Files to update and their target sizes
# Added favicon_v2.png for cache busting
TARGETS = {
    "favicon_v2.png": (64, 64),
    "icons/Icon-192.png": (192, 192),
    "icons/Icon-512.png": (512, 512),
    "icons/Icon-maskable-192.png": (192, 192),
    "icons/Icon-maskable-512.png": (512, 512)
}

def update_icon(logo_path, dest_rel_path, size):
    dest_path = os.path.join(WEB_DIR, dest_rel_path)
    
    try:
        if not os.path.exists(logo_path):
            print(f"Error: Logo not found at {logo_path}")
            return
            
        print(f"Processing {dest_rel_path}...")
        
        img = Image.open(logo_path).convert("RGBA")
        
        # Create White Background
        bg = Image.new("RGBA", size, (255, 255, 255, 255))
        
        img.thumbnail(size, Image.Resampling.LANCZOS)
        
        x = (size[0] - img.width) // 2
        y = (size[1] - img.height) // 2
        bg.paste(img, (x, y), img)
        
        bg.save(dest_path)
        print(f"Updated {dest_rel_path}")
        
    except Exception as e:
        print(f"Failed {dest_rel_path}: {e}")

if __name__ == "__main__":
    # Check alternate logo path if primary missing
    if not os.path.exists(ASSET_LOGO):
        ASSET_LOGO = r"e:\Arun_Finance\frontend\lib\assets\logo.png"

    for rel_path, size in TARGETS.items():
        update_icon(ASSET_LOGO, rel_path, size)
    
    print("Done")
