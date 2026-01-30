import os
from PIL import Image

# Config
# Check both possible locations
ASSET_LOGO = r"e:\Arun_Finance\frontend\assets\logo.png"
if not os.path.exists(ASSET_LOGO):
    ASSET_LOGO = r"e:\Arun_Finance\frontend\lib\assets\logo.png"
    
WEB_DIR = r"e:\Arun_Finance\frontend\web"
DEST_FILE = "favicon_square.png"

def create_square_icon():
    dest_path = os.path.join(WEB_DIR, DEST_FILE)
    
    if not os.path.exists(ASSET_LOGO):
        print("Error: Logo not found")
        return

    print(f"Loading {ASSET_LOGO}")
    img = Image.open(ASSET_LOGO).convert("RGBA")
    
    size = (64, 64)
    
    # Create Opaque White Background (RGB mode ensures no alpha)
    bg = Image.new("RGB", size, (255, 255, 255))
    
    # Resize Logo
    # Scale to 80% to have some padding
    target_size = (int(size[0]*0.8), int(size[1]*0.8))
    img.thumbnail(target_size, Image.Resampling.LANCZOS)
    
    x = (size[0] - img.width) // 2
    y = (size[1] - img.height) // 2
    
    # Paste logo with mask
    bg.paste(img, (x, y), img)
    
    bg.save(dest_path)
    print(f"Created {dest_path}")

if __name__ == "__main__":
    create_square_icon()
