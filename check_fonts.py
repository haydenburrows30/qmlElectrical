import matplotlib.font_manager as fm
import os

def list_available_fonts():
    """List all available fonts that matplotlib can use."""
    fonts = fm.findSystemFonts()
    font_names = []
    
    print("Available system fonts for matplotlib:")
    print("=" * 40)
    
    for font in fonts:
        try:
            font_props = fm.FontProperties(fname=font)
            font_name = font_props.get_name()
            if font_name not in font_names:
                font_names.append(font_name)
                print(f"- {font_name} ({os.path.basename(font)})")
        except:
            # Skip fonts that can't be properly read
            pass
    
    print("\nTotal unique font names:", len(font_names))
    
    # Check for common math-friendly fonts
    good_math_fonts = ['DejaVu Sans', 'STIX', 'STIXGeneral', 'CMU Serif', 
                      'Computer Modern', 'Latin Modern Math', 'Liberation Serif']
    
    print("\nMath-friendly fonts found:")
    for font in good_math_fonts:
        if any(font.lower() in name.lower() for name in font_names):
            print(f"- {font}: AVAILABLE")
        else:
            print(f"- {font}: NOT FOUND")

    # Recommended font configuration
    print("\nRecommended font configuration for your system:")
    
    # Find a good sans-serif font
    sans_fonts = ['DejaVu Sans', 'Arial', 'Helvetica', 'Liberation Sans']
    found_sans = next((font for font in sans_fonts if any(font.lower() in name.lower() for name in font_names)), 'sans-serif')
    
    # Find a good serif font
    serif_fonts = ['DejaVu Serif', 'Times New Roman', 'Liberation Serif']
    found_serif = next((font for font in serif_fonts if any(font.lower() in name.lower() for name in font_names)), 'serif')
    
    # Find a good math font
    math_fonts = ['dejavusans', 'stix', 'cm']
    found_math = 'dejavusans'  # Default fallback
    
    print("rcParams['font.family'] = 'sans-serif'")
    print(f"rcParams['font.sans-serif'] = ['{found_sans}', 'sans-serif']")
    print(f"rcParams['font.serif'] = ['{found_serif}', 'serif']")
    print(f"rcParams['mathtext.fontset'] = '{found_math}'")

if __name__ == "__main__":
    list_available_fonts()
