import os
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import rcParams
from PIL import Image
import re

# Directory to save formula images
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'formulas')

# Create the directory if it doesn't exist
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configure matplotlib for high quality rendering
rcParams['mathtext.fontset'] = 'stix'
rcParams['font.family'] = 'STIXGeneral'
rcParams['text.usetex'] = False
rcParams['savefig.bbox'] = 'tight'  # This is crucial for tight cropping
rcParams['savefig.pad_inches'] = 0.05  # Small padding
rcParams['savefig.dpi'] = 300  # High DPI for better quality

def generate_formula_image(formula, filename, fontsize=16):
    """
    Generate an image of a mathematical formula with tight cropping.
    
    Args:
        formula (str): The LaTeX formula to render.
        filename (str): Output filename without extension.
        fontsize (int): Font size for the formula.
    """
    plt.figure(figsize=(10, 1))  # Start with a narrow figure
    plt.text(0.5, 0.5, f"${formula}$", fontsize=fontsize, 
             ha='center', va='center', transform=plt.gca().transAxes)
    plt.axis('off')  # Turn off the axis
    
    # Save with tight layout - this minimizes whitespace
    output_path = os.path.join(OUTPUT_DIR, f"{filename}.png")
    plt.savefig(output_path, bbox_inches='tight', pad_inches=0.05, transparent=True)
    plt.close()
    
    # Further optimize the image using PIL
    img = Image.open(output_path)
    
    # Convert to RGBA if not already
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Find the bounding box of non-transparent pixels
    data = np.array(img)
    non_transparent = data[:,:,3] > 0
    if non_transparent.any():
        rows = np.any(non_transparent, axis=1)
        cols = np.any(non_transparent, axis=0)
        y_min, y_max = np.where(rows)[0][[0, -1]]
        x_min, x_max = np.where(cols)[0][[0, -1]]
        
        # Add a small padding
        pad = 10
        y_min = max(0, y_min - pad)
        y_max = min(data.shape[0], y_max + pad)
        x_min = max(0, x_min - pad)
        x_max = min(data.shape[1], x_max + pad)
        
        # Crop the image
        img = img.crop((x_min, y_min, x_max, y_max))
    
    # Save the final cropped image
    img.save(output_path)
    print(f"Generated formula image: {output_path}")

if __name__ == "__main__":
    print("Running formula image generator...")
    
    # Import the formulas from the generate_formulas module
    from generate_formulas import vr32cl7_formulas
    
    # Generate images for all formulas
    for name, formula in vr32cl7_formulas.items():
        generate_formula_image(formula, f"vr32cl7_{name}", fontsize=24)
    
    print("Formula image generation complete.")