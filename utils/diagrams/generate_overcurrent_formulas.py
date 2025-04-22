import os
import matplotlib.pyplot as plt
import matplotlib
from pathlib import Path
import re

def setup_matplotlib():
    """Configure matplotlib for formula rendering."""
    matplotlib.use('Agg')
    plt.rcParams.update({
        "text.usetex": False,
        "mathtext.fontset": "dejavusans",
        'savefig.bbox': 'tight',
        'savefig.pad_inches': 0.01,
        'savefig.dpi': 300
    })

def save_formula(formula, filename, directory):
    """Save formula as SVG image using matplotlib's math renderer."""
    plt.figure(figsize=(5, 0.7))  # Much narrower figure width to reduce horizontal whitespace
    plt.text(0.5, 0.5, f"${formula}$", 
             fontsize=16, ha='center', va='center')
    plt.axis('off')
    plt.tight_layout(pad=0.0)  # Tightest possible layout
    
    output_path = os.path.join(directory, filename)
    plt.savefig(output_path, bbox_inches='tight', format='svg', transparent=True, 
                pad_inches=0.005)  # Minimal padding
    plt.close()
    
    # Post-process SVG to reduce whitespace
    reduce_svg_whitespace(output_path)
    print(f"Created: {output_path}")

def reduce_svg_whitespace(svg_path):
    """Reduce whitespace in SVG by adjusting viewBox and removing unnecessary attributes."""
    try:
        with open(svg_path, 'r') as f:
            svg_content = f.read()
        
        # Find viewBox
        viewbox_match = re.search(r'viewBox="([^"]+)"', svg_content)
        if viewbox_match:
            viewbox = viewbox_match.group(1)
            x, y, width, height = map(float, viewbox.split())
            
            # Find text element's x position and width if present
            text_match = re.search(r'<text[^>]*x="([^"]+)"[^>]*>', svg_content)
            if text_match:
                # Calculate tighter margins based on the text position
                text_x = float(text_match.group(1))
                # Estimate text width from viewBox (assuming centered text)
                text_width = width * 0.3  # Estimate text takes about 80% of current width
                
                # Calculate new x and width with minimal margins
                margin_x = width * 0.01  # 1% margin on each side
                new_x = max(0, text_x - text_width/2 - margin_x)
                new_width = text_width + 2 * margin_x
                
                # Apply y margins similarly but smaller
                margin_y = height * 0.1
                new_y = y - margin_y/2
                new_height = height + margin_y
                
                # Create new viewBox
                new_viewbox = f"{new_x} {new_y} {new_width} {new_height}"
                svg_content = svg_content.replace(viewbox_match.group(0), f'viewBox="{new_viewbox}"')
            else:
                # If no text element found, use a more conservative approach
                # Tighten the viewBox with a small margin
                margin_x = width * 0.12  # Reduce width by 20%
                new_viewbox = f"{x+margin_x} {y} {width-2*margin_x} {height}"
                svg_content = svg_content.replace(viewbox_match.group(0), f'viewBox="{new_viewbox}"')
            
            # Remove width and height attributes to allow proper scaling
            svg_content = re.sub(r'width="[^"]+"', '', svg_content)
            svg_content = re.sub(r'height="[^"]+"', '', svg_content)
            
            with open(svg_path, 'w') as f:
                f.write(svg_content)
            
            print(f"Successfully reduced whitespace in {svg_path}")
    except Exception as e:
        print(f"Error reducing whitespace in SVG: {e}")

def main():
    setup_matplotlib()
    
    # Create assets/formulas directory if it doesn't exist
    formula_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'formulas', 'overcurrent')
    os.makedirs(formula_dir, exist_ok=True)
    
    # Overcurrent protection calculator formulas
    overcurrent_formulas = {
        "cable_impedance.svg": r"Z_{cable} = \sqrt{(R_{ac} \times L)^2 + (X_{cable} \times L)^2}",
        "fault_current_3ph.svg": r"I_{f3\phi} = \frac{V_{base}}{\sqrt{3} \times Z_{total}}",
        "fault_current_2ph.svg": r"I_{f2\phi} = I_{f3\phi} \times \frac{\sqrt{3}}{2}",
        "fault_current_1ph.svg": r"I_{f1\phi} = \frac{3 \times V_{phase}}{Z_1 + Z_2 + Z_0}",
        "pickup_50.svg": r"I_{50} = \max(I_{f3\phi} \times 0.8, I_{load} \times 6)",
        "pickup_51.svg": r"I_{51} = \max(I_{load} \times 1.2, 20)",
        "pickup_50n.svg": r"I_{50N} = \min(I_{f1\phi} \times 0.5, 200)",
        "pickup_51n.svg": r"I_{51N} = \max(10, I_{load} \times 0.1)",
        "pickup_50q.svg": r"I_{50Q} = I_{load} \times 0.3",
    }
    
    # Generate each formula
    for filename, formula in overcurrent_formulas.items():
        try:
            save_formula(formula, filename, formula_dir)
        except Exception as e:
            print(f"Error generating {filename}: {e}")
            # Try fallback with simplified formula
            try:
                simplified = formula.replace(r"\frac", "/").replace(r"\left", "").replace(r"\right", "")
                save_formula(simplified, filename, formula_dir)
                print(f"Generated {filename} with simplified formula")
            except Exception as e2:
                print(f"Fallback failed for {filename}: {e2}")

if __name__ == "__main__":
    main()