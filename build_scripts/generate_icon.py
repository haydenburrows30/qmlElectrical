import os
from PIL import Image, ImageDraw

def create_icon():
    """Create a basic app icon."""
    size = 256
    icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    
    # Draw a simple circle
    margin = 20
    draw.ellipse([margin, margin, size-margin, size-margin], 
                 fill='#2196F3', outline='#1976D2', width=4)
    
    # Save in multiple sizes required for Windows
    sizes = [16, 24, 32, 48, 64, 128, 256]
    
    # Create resources/icons directory if it doesn't exist
    icon_dir = "resources/icons"
    os.makedirs(icon_dir, exist_ok=True)
    
    # Save as ICO file with multiple sizes
    icon_path = os.path.join(icon_dir, "app.ico")
    resized_images = []
    for s in sizes:
        resized = icon.resize((s, s), Image.Resampling.LANCZOS)
        resized_images.append(resized)
    
    icon.save(icon_path, format='ICO', sizes=[(s,s) for s in sizes])
    return icon_path

if __name__ == '__main__':
    import os
    path = create_icon()
    print(f"Created icon at: {path}")
