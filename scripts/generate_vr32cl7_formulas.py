import os
import matplotlib.pyplot as plt
import matplotlib
from pathlib import Path

def setup_matplotlib():
    """Configure matplotlib for formula rendering."""
    matplotlib.use('Agg')
    plt.rcParams.update({
        "text.usetex": False,
        "mathtext.fontset": "dejavusans",
    })

def save_formula(formula, filename, directory):
    """Save formula as PNG image using matplotlib's math renderer."""
    plt.figure(figsize=(8, 1.5))
    plt.text(0.5, 0.5, f"${formula}$", 
             fontsize=16, ha='center', va='center')
    plt.axis('off')
    plt.savefig(os.path.join(directory, filename), 
                bbox_inches='tight', dpi=150, transparent=True)
    plt.close()
    print(f"Created: {os.path.join(directory, filename)}")

def main():
    setup_matplotlib()
    
    # Create assets/formulas directory if it doesn't exist
    formula_dir = Path("assets/formulas")
    formula_dir.mkdir(parents=True, exist_ok=True)
    
    # VR32 CL-7 Calculator formulas
    vr32cl7_formulas = {
        "vr32cl7_total_length.png": r"L_{total} = L_{cable} + L_{load}",
        "vr32cl7_resistance.png": r"R_{total} = R_{per\_km} \times L_{total}",
        "vr32cl7_reactance.png": r"X_{total} = X_{per\_km} \times L_{total}",
        "vr32cl7_impedance.png": r"Z = \sqrt{R_{total}^2 + X_{total}^2}",
        "vr32cl7_impedance_angle.png": r"\phi = \tan^{-1}\left(\frac{X_{total}}{R_{total}}\right) \times \frac{180}{\pi}",
        "vr32cl7_overall.png": r"Z \angle \phi = \sqrt{R_{total}^2 + X_{total}^2} \angle \tan^{-1}\left(\frac{X_{total}}{R_{total}}\right)",
    }
    
    # Generate each formula
    for filename, formula in vr32cl7_formulas.items():
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