import os
import matplotlib.pyplot as plt
import matplotlib
import shutil
from pathlib import Path

def check_latex():
    """Check if LaTeX is installed and configured."""
    return shutil.which('latex') is not None

def setup_matplotlib():
    """Configure matplotlib based on LaTeX availability."""
    if check_latex():
        matplotlib.use('Agg')
        plt.rcParams.update({
            "text.usetex": True,
            "font.family": "serif",
            "font.serif": ["Computer Modern Roman"],
        })
    else:
        matplotlib.use('Agg')
        plt.rcParams.update({
            "text.usetex": False,
            "mathtext.fontset": "dejavusans",
        })
        print("LaTeX not found - using matplotlib math renderer")

def save_formula(formula, filename, directory):
    """Save formula as PNG image using either LaTeX or mathtext."""
    plt.figure(figsize=(8, 2))
    plt.text(0.5, 0.5, f"${formula}$", 
             fontsize=14, ha='center', va='center')
    plt.axis('off')
    plt.savefig(os.path.join(directory, f"{filename}.png"), 
                bbox_inches='tight', dpi=150, transparent=True,
                facecolor='none')
    plt.close()

def main():
    setup_matplotlib()
    formula_dir = Path("assets/formulas")
    formula_dir.mkdir(parents=True, exist_ok=True)
    
    # Dictionary of conversion types and their formulas
    formulas = {
        # Power & Energy
        "watts_to_dbm": r"P_{dBm} = 10 \log_{10}(P_W \cdot 1000)",
        "dbmw_to_watts": r"P_W = 10^{(P_{dBm}/10)} \cdot 10^{-3}",
        "hp_to_watts": r"P_W = P_{HP} \cdot 746",
        "watts_to_horsepower": r"P_{HP} = \frac{P_W}{746}",
        "joules_to_kwh": r"E_{kWh} = \frac{E_J}{3600000}",
        
        # Frequency & Angular
        "rad_to_hz": r"f = \frac{\omega}{2\pi}",
        "radians_to_hz": r"f = \frac{\omega}{2\pi}",
        "rpm_to_hz": r"f = \frac{N}{60}",
        "hz_to_rpm": r"N = f \cdot 60",
        
        # Three-Phase Relationships
        "line_phase_voltage": r"V_{ph} = \frac{V_L}{\sqrt{3}}",
        "phase_line_voltage": r"V_L = V_{ph} \cdot \sqrt{3}",
        "line_phase_current": r"I_{ph} = \frac{I_L}{\sqrt{3}}",
        "phase_line_current": r"I_L = I_{ph} \cdot \sqrt{3}",
        
        # Power Factor
        "power_factor": r"P = S \cdot \cos\phi",
        "kva_to_kw": r"P_{kW} = S_{kVA} \cdot \cos\phi",
        
        # Per Unit System
        "base_impedance": r"Z_{base} = \frac{kV_{base}^2}{MVA_{base}}",
        "per_unit": r"Z_{pu} = \frac{Z_{actual}}{Z_{base}}",
        "impedance_base_change": r"Z_{new} = Z_{old} \cdot \frac{MVA_{old}}{MVA_{new}}",
        
        # Sequence Components
        "sequence_pos": r"\vec{V_a} = V_1 \angle 0°",
        "sequence_neg": r"\vec{V_a} = V_2 \angle 0°",
        
        # Fault Calculations
        "sym_fault": r"I_{ph} = I_{sym} \cdot \sqrt{3}",
        
        # Temperature Conversions
        "celsius_to_fahrenheit": r"T_F = T_C \cdot \frac{9}{5} + 32",
        "fahrenheit_to_celsius": r"T_C = (T_F - 32) \cdot \frac{5}{9}",
        
        # Other Conversions
        "reactance_freq": r"X_{60} = X_{50} \cdot \frac{60}{50}",
        "three_phase_power": r"P_{phase} = \frac{P_{total}}{3}"
    }
    
    for name, formula in formulas.items():
        try:
            save_formula(formula, name, formula_dir)
            print(f"Generated {name}.png")
        except Exception as e:
            print(f"Error generating {name}: {e}")
            # Try fallback with simplified formula
            try:
                simplified = formula.replace(r"\frac", "/")
                save_formula(simplified, name, formula_dir)
                print(f"Generated {name}.png with simplified formula")
            except Exception as e2:
                print(f"Fallback failed for {name}: {e2}")

if __name__ == "__main__":
    main()
