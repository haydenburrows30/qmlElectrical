# Formula definitions for VR32CL7 calculator
# These formulas will be rendered using matplotlib and saved as images

# Define the formulas for VR32CL7 with LaTeX syntax
vr32cl7_formulas = {
    # Total cable length formula
    "total_length": r"L_{total} = L_{cable} + L_{load}",
    
    # Total resistance formula
    "resistance": r"R_{total} = R_{per\ km} \times L_{total}",
    
    # Total reactance formula
    "reactance": r"X_{total} = X_{per\ km} \times L_{total}",
    
    # Impedance magnitude formula
    "impedance": r"Z = \sqrt{R_{total}^2 + X_{total}^2}",
    
    # Impedance angle formula
    "impedance_angle": r"\theta = \tan^{-1}\left(\frac{X_{total}}{R_{total}}\right)",
    
    # Overall impedance formula with complex notation
    "overall": r"Z = R_{total} + jX_{total} = |Z| \angle \theta"
}

# You can add more formula sets for other calculators here