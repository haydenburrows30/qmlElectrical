"""
Script to build Windows executable
"""
import os
import subprocess
import shutil
from pathlib import Path

def build_exe():
    """Build Windows executable using PyInstaller"""
    # Get the base application path
    base_path = Path(__file__).resolve().parent.parent
    build_path = base_path / "build"
    dist_path = base_path / "dist"
    
    # Clean previous builds
    print("Cleaning previous builds...")
    for path in [build_path, dist_path]:
        if path.exists():
            shutil.rmtree(path)
            
    # Create version file
    version_file = base_path / "version.txt"
    if not version_file.exists():
        with open(version_file, "w") as f:
            f.write("1.0.0")
            
    # Read version
    with open(version_file, "r") as f:
        version = f.read().strip()
    
    print(f"Building version {version}...")
    
    # PyInstaller command
    cmd = [
        "pyinstaller",
        "--clean",
        "--onedir",  # Use --onefile for single executable (slower startup but easier distribution)
        "--windowed",  # Don't show console
        "--name", f"QMLTest-{version}",
        "--icon", str(base_path / "icons" / "app_icon.ico"),
        "--additional-hooks-dir", str(base_path / "windows" / "hooks"),
        "--runtime-hook", str(base_path / "windows" / "runtime_hooks.py"),
        "--add-data", f"{base_path/'qml'}:qml",
        "--add-data", f"{base_path/'icons'}:icons", 
        "--add-data", f"{base_path/'resources'}:resources",
        "--hidden-import", "PySide6.QtQml",
        "--hidden-import", "PySide6.QtQuick",
        "--hidden-import", "PySide6.QtCharts",
        str(base_path / "windows" / "win_main.py")
    ]
    
    # Run PyInstaller
    print("Running PyInstaller...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Check for errors
    if result.returncode != 0:
        print("Error building executable:")
        print(result.stderr)
        return False
        
    print("Build successful!")
    print(f"Executable located at: {dist_path / f'QMLTest-{version}'}")
    return True

if __name__ == "__main__":
    build_exe()
