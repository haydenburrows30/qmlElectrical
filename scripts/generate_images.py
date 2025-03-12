import os
import sys
import subprocess
import importlib

def check_and_install_dependencies():
    """Check for required dependencies and install them if needed."""
    required_packages = ['matplotlib', 'numpy', 'pillow']
    
    for package in required_packages:
        try:
            importlib.__import__(package)
        except ImportError:
            print(f"Installing required package: {package}")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])

def generate_all_images():
    """Generate all formula and diagram images for the application."""
    # Import after ensuring dependencies are installed
    from scripts.generate_formula_images import main as generate_formulas
    from scripts.generate_diagram_images import main as generate_diagrams
    
    # Create media directory if it doesn't exist
    os.makedirs('media', exist_ok=True)
    
    # Generate all formula images
    print("Generating formula images...")
    generate_formulas()
    
    # Generate all diagram images
    print("Generating diagram images...")
    generate_diagrams()
    
    print("All images successfully generated in the media directory.")

if __name__ == "__main__":
    check_and_install_dependencies()
    generate_all_images()
