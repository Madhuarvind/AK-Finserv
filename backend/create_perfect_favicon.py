import os
from PIL import Image, ImageDraw, ImageOps

ASSET_LOGO = r"e:\Arun_Finance\frontend\assets\logo.png"
if not os.path.exists(ASSET_LOGO):
    ASSET_LOGO = r"e:\Arun_Finance\frontend\lib\assets\logo.png"
    
WEB_DIR = r"e:\Arun_Finance\frontend\web"
DEST_FILE = "favicon_perfect.png"

def create_perfect_icon():
    dest_path = os.path.join(WEB_DIR, DEST_FILE)
    
    if not os.path.exists(ASSET_LOGO):
        print("Error: Logo not found")
        return

    print(f"Loading {ASSET_LOGO}")
    img = Image.open(ASSET_LOGO).convert("RGBA")
    
    # 1. Mask the Source Logo to Circle (Remove black corners)
    # Create mask
    mask = Image.new("L", img.size, 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.ellipse((0, 0, img.width, img.height), fill=255)
    
    # Apply alpha mask to source
    # If source has no alpha, this adds it.
    output = ImageOps.fit(img, img.size, centering=(0.5, 0.5))
    output.putalpha(mask)
    
    # 2. Resize to fit in favicon
    icon_size = (48, 48) # Logo size
    output = output.resize(icon_size, Image.Resampling.LANCZOS)
    
    # 3. Create White Base Circle (64x64)
    final_size = (64, 64)
    bg = Image.new("RGBA", final_size, (0,0,0,0))
    draw_bg = ImageDraw.Draw(bg)
    draw_bg.ellipse((0, 0, final_size[0], final_size[1]), fill="white")
    
    # 4. Paste Circular Logo onto White Circle
    x = (final_size[0] - icon_size[0]) // 2
    y = (final_size[1] - icon_size[1]) // 2
    
    # Paste
    bg.paste(output, (x, y), output)
    
    bg.save(dest_path)
    print(f"Created {dest_path}")

if __name__ == "__main__":
    create_perfect_icon()
