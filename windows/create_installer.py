"""
Script to create Windows installer using NSIS
"""
import os
import subprocess
import sys
from pathlib import Path

def create_installer():
    """Create Windows installer using NSIS"""
    base_path = Path(__file__).resolve().parent.parent
    
    # Ensure PyInstaller build exists
    dist_path = base_path / "dist"
    if not dist_path.exists() or not any(dist_path.iterdir()):
        print("ERROR: No PyInstaller build found. Run build_windows.py first.")
        return False
        
    # Check for NSIS installation
    nsis_path = None
    possible_paths = [
        r"C:\Program Files (x86)\NSIS\makensis.exe",
        r"C:\Program Files\NSIS\makensis.exe"
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            nsis_path = path
            break
            
    if not nsis_path:
        print("ERROR: NSIS installation not found. Please install NSIS.")
        print("Download from: https://nsis.sourceforge.io/Download")
        return False
    
    # Run NSIS compiler
    nsi_script = base_path / "windows" / "installer.nsi"
    cmd = [nsis_path, str(nsi_script)]
    
    print("Creating installer...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Error creating installer:")
        print(result.stderr)
        return False
        
    print("Installer created successfully!")
    return True

if __name__ == "__main__":
    create_installer()
