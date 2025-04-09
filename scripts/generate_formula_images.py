import os
import matplotlib.pyplot as plt
import matplotlib
from matplotlib import rcParams

# Configure matplotlib for rendering without LaTeX dependencies
matplotlib.use("Agg")  # Use non-interactive backend

# Use a simpler font configuration that avoids the Computer Modern Roman font
rcParams['text.usetex'] = False  # Don't use real LaTeX
rcParams['mathtext.fontset'] = 'dejavusans'  # Use DejaVu Sans for math
rcParams['font.family'] = 'sans-serif'
rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica', 'sans-serif']
rcParams['font.size'] = 14

def create_formula_image(filename, formula, width=6, height=1.5, dpi=200, bg_color='white', 
                         text_color='black', with_frame=False, extra_padding=0.1):
    """
    Create an image from a LaTeX formula.
    
    Args:
        filename: Output filename (will be saved in the media directory)
        formula: LaTeX formula string (without $ $ delimiters)
        width: Width of the output image in inches
        height: Height of the output image in inches
        dpi: Resolution of the output image
        bg_color: Background color
        text_color: Text color
        with_frame: Whether to add a frame around the formula
        extra_padding: Extra padding around the formula (in inches)
    """
    # Create the media directory if it doesn't exist
    os.makedirs('assets', exist_ok=True)
    
    # Setup figure with transparent background
    fig = plt.figure(figsize=(width, height), dpi=dpi)
    fig.patch.set_facecolor(bg_color)
    
    # Add a single axes with no border
    ax = fig.add_subplot(111)
    ax.set_frame_on(with_frame)
    ax.set_xticks([])
    ax.set_yticks([])
    ax.axis('off')
    
    # Add formula text centered in the figure
    ax.text(0.5, 0.5, f"${formula}$", 
            horizontalalignment='center', 
            verticalalignment='center',
            fontsize=20, 
            color=text_color)
    
    # Adjust layout to fit text
    plt.tight_layout(pad=extra_padding)
    
    # Save the figure with transparent background
    output_path = os.path.join('assets/formulas', filename)
    plt.savefig(output_path, 
                format='png', 
                bbox_inches='tight',
                pad_inches=extra_padding,
                facecolor=bg_color,
                transparent=bg_color=='transparent')
    
    plt.close(fig)
    
    print(f"Created formula image: {output_path}")
    return output_path

def main():
    """Generate all needed formula images for the application."""
    formulas = {
        # Transformer formulas
        "transformer_formula.png": r"\frac{V_p}{V_s} = \frac{N_p}{N_s} = \frac{I_s}{I_p}",
        "transformer_power.png": r"P_{in} = P_{out} \Rightarrow V_p \times I_p = V_s \times I_s",
        
        # Voltage drop formulas
        "voltage_drop.png": r"V_{drop} = I \times R \times L \quad R = \frac{\rho}{A}",
        "voltage_drop_percent.png": r"\% V_{drop} = \frac{V_{drop}}{V_{supply}} \times 100\%",
        
        # Motor formulas
        "motor_formula.png": r"I = \frac{P}{{\sqrt{3} \times V \times PF \times \eta}}",
        "motor_torque.png": r"T = \frac{9.55 \times P}{n}",
        
        # Power triangle formula
        "power_triangle.png": r"S^2 = P^2 + Q^2 \quad PF = \cos \phi = \frac{P}{S}",
        
        # Impedance formula
        "impedance_formula.png": r"Z = \sqrt{R^2 + X^2} \quad \phi = \tan^{-1}\left(\frac{X}{R}\right)",
        
        # Resonant frequency
        "resonant_frequency.png": r"f_r = \frac{1}{2\pi\sqrt{LC}}",
        
        # Cable charging current
        "charging_current.png": r"I_c = 2\pi f C V \times 10^{-6} \times L",
        
        # Power Factor Correction formulas
        "pf_correction_formula.png": r"Q_C = P \times (\tan \phi_1 - \tan \phi_2)",
        "pf_correction_capacitance.png": r"C = \frac{Q_C \times 10^6}{2\pi f V^2}",
        
        # Cable Ampacity formulas
        "cable_ampacity_formula.png": r"I = I_b \times C_{temp} \times C_{group} \times C_{install}",
        
        # Protection Relay formulas
        "relay_formula.png": r"t = \frac{a \times TDS}{(I/I_{pickup})^b - 1}",
        
        # Harmonic Analysis formulas
        "thd_formula.png": r"THD = \frac{\sqrt{\sum_{n=2}^{\infty} V_n^2}}{V_1} \times 100\%",
        
        # CT/VT formulas
        "ct_vt_formula.png": r"V_{k} = 2 \times I_s \times \sqrt{VA_{burden}} \quad ALF = \frac{I_f}{I_{pn}}",
    }
    
    # Generate each formula
    for filename, formula in formulas.items():
        create_formula_image(filename, formula)

if __name__ == "__main__":
    main()
