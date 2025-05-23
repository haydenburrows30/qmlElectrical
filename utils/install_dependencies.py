import subprocess
import sys

def install_dependencies():
    """Install or upgrade required PySide6 components."""
    packages = [
        'PySide6==6.9.0',  # Use a specific version for consistency
        'PySide6-Addons==6.9.0',  # Contains QtSvg
        'PySide6-Essentials==6.9.0',
        'numpy==2.2.4',
        'reportlab',
        'psutil'
    ]
    
    for package in packages:
        print(f"Installing {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-U", package])
    
    print("Dependencies installed successfully.")
    
if __name__ == "__main__":
    install_dependencies()
