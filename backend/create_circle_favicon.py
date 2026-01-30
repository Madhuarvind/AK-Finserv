import os
from PIL import Image, ImageDraw

# Config
ASSET_LOGO = r"e:\Arun_Finance\frontend\assets\logo.png"
if not os.path.exists(ASSET_LOGO):
    ASSET_LOGO = r"e:\Arun_Finance\frontend\lib\assets\logo.png"
    
WEB_DIR = r"e:\Arun_Finance\frontend\web"
DEST_FILE = "favicon_circle.png"

def create_circle_icon():
    dest_path = os.path.join(WEB_DIR, DEST_FILE)
    
    if not os.path.exists(ASSET_LOGO):
        print("Error: Logo not found")
        return

    print(f"Loading {ASSET_LOGO}")
    img = Image.open(ASSET_LOGO).convert("RGBA")
    
    # Size for favicon
    size = (64, 64)
    # Super-sampling size
    s2 = (256, 256)
    
    # Create Circle Mask/Background
    circle = Image.new("RGBA", s2, (0,0,0,0))
    draw = ImageDraw.Draw(circle)
    # White Circle
    draw.ellipse((0, 0, s2[0], s2[1]), fill="white")
    
    # Resize circle to target
    circle = circle.resize(size, Image.Resampling.LANCZOS)
    
    # Process Logo
    # Maintain aspect ratio, fit inside circle (approx 70% of size)
    icon_size = (int(size[0] * 0.7), int(size[1] * 0.7))
    img.thumbnail(icon_size, Image.Resampling.LANCZOS)
    
    # Center logo
    x = (size[0] - img.width) // 2
    y = (size[1] - img.height) // 2
    
    # Composite: Paste logo onto white circle
    circle.paste(img, (x, y), img)
    
    circle.save(dest_path)
    print(f"Created {dest_path}")

if __name__ == "__main__":
    create_circle_icon()
