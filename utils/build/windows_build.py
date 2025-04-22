import os
import shutil
import urllib.request
import zipfile
from pathlib import Path
import PyInstaller.__main__
from utils.diagrams.generate_icon import create_icon
import time

def download_upx():
    """Download and extract UPX if not already present"""
    ROOT_DIR = Path(__file__).parent.parent
    UPX_DIR = ROOT_DIR / "tools" / "upx"
    UPX_EXE = UPX_DIR / "upx.exe"
    
    # If UPX is already downloaded, return its path
    if UPX_EXE.exists():
        return str(UPX_DIR)
    
    # Create tools directory if it doesn't exist
    os.makedirs(UPX_DIR, exist_ok=True)
    
    try:
        # URL for UPX download (update version as needed)
        upx_url = "https://github.com/upx/upx/releases/download/v5.0.0/upx-5.0.0-win64.zip"
        zip_path = UPX_DIR / "upx.zip"
        
        # Download UPX
        print(f"Downloading UPX from {upx_url}")
        urllib.request.urlretrieve(upx_url, zip_path)
        
        # Extract the zip file
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(UPX_DIR)
        
        # Remove the zip file
        os.unlink(zip_path)
        
        # Find the upx.exe in the extracted directory
        for root, _, files in os.walk(UPX_DIR):
            for file in files:
                if file == "upx.exe":
                    src_path = Path(root) / file
                    if src_path != UPX_EXE:
                        shutil.move(str(src_path), str(UPX_EXE))
                        
        print(f"UPX successfully installed at {UPX_DIR}")
        return str(UPX_DIR)
    except Exception as e:
        print(f"Failed to download UPX: {e}")
        return None

def safe_rmtree(path, max_retries=5, retry_delay=1):
    """Safely remove a directory tree with retries for Windows permission issues."""
    path = Path(path)
    if not path.exists():
        return
    
    for attempt in range(max_retries):
        try:
            if path.is_dir():
                # Try using rmtree with ignore_errors first
                shutil.rmtree(path, ignore_errors=True)
                # Check if directory was actually removed
                if not path.exists():
                    return
                
                # If directory still exists, try removing files one by one
                for item in path.glob('**/*'):
                    try:
                        if item.is_file():
                            item.unlink(missing_ok=True)
                        elif item.is_dir() and not any(item.iterdir()):
                            item.rmdir()
                    except Exception:
                        pass
                
                # Final attempt to remove the directory
                shutil.rmtree(path, ignore_errors=True)
                return
            else:
                return
        except Exception as e:
            print(f"Error deleting {path}: {e}. Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)
    
    print(f"Warning: Could not fully remove {path}. Continuing anyway...")

def build_windows():
    """Build Windows executable using PyInstaller"""
    ROOT_DIR = Path(__file__).parent.parent
    DIST_DIR = ROOT_DIR / "dist"
    BUILD_DIR = ROOT_DIR / "build"
    ICONS_DIR = ROOT_DIR / "icons"
    
    # Try to download and setup UPX
    upx_dir = download_upx()
    
    # Create required directories
    os.makedirs(ROOT_DIR / "icons", exist_ok=True)
    os.makedirs(ROOT_DIR / "qml", exist_ok=True)
    os.makedirs(ROOT_DIR / "data", exist_ok=True)
    
    # Generate icon if it doesn't exist
    icon_path = create_icon()
    
    # Get relative paths from build script location
    main_script = str(ROOT_DIR / "main.py")
    qml_dir = str(ROOT_DIR / "qml")
    data_dir = str(ROOT_DIR / "data")
    icons_dir = str(ICONS_DIR)
    
    # Clean previous builds with safe removal
    print("Cleaning previous builds...")
    for dir_path in [DIST_DIR, BUILD_DIR]:
        print(f"Removing {dir_path}...")
        safe_rmtree(dir_path)
    
    # If build directory still exists, create a uniquely named directory
    if BUILD_DIR.exists():
        print("Warning: Could not fully remove old build directory.")
        timestamp = int(time.time())
        BUILD_DIR = ROOT_DIR / f"build_{timestamp}"
        print(f"Using alternative build directory: {BUILD_DIR}")
    
    # Base PyInstaller arguments
    pyinstaller_args = [
        main_script,
        '--name=ElectricalCalculator',
        '--windowed',
        f'--icon={icon_path}',
        f'--add-data={qml_dir};qml',
        f'--add-data={data_dir};data',
        f'--add-data={icons_dir};icons',
        '--hidden-import=PySide6.QtQml',
        '--hidden-import=PySide6.QtQuick',
        '--hidden-import=PySide6.QtCore',
        '--hidden-import=PySide6.QtGui',
        '--hidden-import=PySide6.QtWidgets',
        '--hidden-import=PySide6.QtCharts',
        '--paths=.',
        '--clean',
        f'--workpath={BUILD_DIR}',
        '--onefile'
    ]
    
    # Add UPX options if UPX is available
    if upx_dir:
        pyinstaller_args.extend([
            f'--upx-dir={upx_dir}',
            '--upx-exclude=vcruntime140.dll',
            '--upx-exclude=python3*.dll',
            '--upx-exclude=Qt*.dll'
        ])
    else:
        print("UPX not available, building without compression")
    
    # Run PyInstaller
    print("Running PyInstaller...")
    try:
        PyInstaller.__main__.run(pyinstaller_args)
        print("PyInstaller completed successfully!")
    except Exception as e:
        print(f"PyInstaller encountered an error: {e}")
        # Try to continue if possible

if __name__ == '__main__':
    build_windows()
