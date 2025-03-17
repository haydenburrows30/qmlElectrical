import subprocess
import sys
import os

def install_pyside6_svg():
    """Install PySide6 with QtSvg support."""
    print("Installing PySide6 with QtSvg support...")
    
    # First, uninstall any existing PySide6 packages to avoid conflicts
    try:
        subprocess.call([sys.executable, "-m", "pip", "uninstall", "-y", "PySide6", "PySide6-Addons", "PySide6-Essentials", "shiboken6"])
    except:
        print("No existing PySide6 packages to uninstall.")
    
    # Install specific versions that are known to work together
    packages = [
        'PySide6==6.5.2',       # Main PySide6 package (more recent version)
        'PySide6-Addons==6.5.2', # Contains QtSvg
        'PySide6-Essentials==6.5.2',
        'shiboken6==6.5.2',     # Binding generator
        'numpy'                 # For calculations
    ]
    
    for package in packages:
        print(f"Installing {package}...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            print(f"Successfully installed {package}")
        except subprocess.CalledProcessError as e:
            print(f"Error installing {package}: {e}")
            return False
    
    print("\nAll dependencies installed successfully.")
    print("\nPlease restart your application.")
    return True

if __name__ == "__main__":
    install_pyside6_svg()
