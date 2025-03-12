from PIL import Image, ImageDraw, ImageFont
import os

def create_placeholder(filename, text, size=(400, 300), bg_color=(240, 240, 240), text_color=(0, 0, 0)):
    """Create a placeholder image with text."""
    # Create directory if it doesn't exist
    os.makedirs('media', exist_ok=True)
    
    # Create a new image with the given background color
    img = Image.new('RGB', size, color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Try to use a default font
    try:
        font = ImageFont.truetype("arial.ttf", 20)
    except IOError:
        # Fallback to default font
        font = ImageFont.load_default()
    
    # Calculate text position for center alignment
    text_width, text_height = draw.textsize(text, font=font) if hasattr(draw, 'textsize') else (100, 20)
    position = ((size[0] - text_width) // 2, (size[1] - text_height) // 2)
    
    # Draw text
    draw.text(position, text, font=font, fill=text_color)
    
    # Add a border
    draw.rectangle([(0, 0), (size[0]-1, size[1]-1)], outline=(200, 200, 200))
    
    # Save the image
    img.save(f"media/{filename}")
    print(f"Created placeholder image: media/{filename}")

# Create the placeholder images
create_placeholder("transformer_formula.png", "Transformer Formula: Vp/Vs = Np/Ns = Is/Ip")
create_placeholder("transformer.png", "Transformer Diagram", size=(400, 400))
create_placeholder("voltage_drop.png", "Voltage Drop: Vdrop = I × R × L")

print("All placeholder images created in the 'media' directory.")
