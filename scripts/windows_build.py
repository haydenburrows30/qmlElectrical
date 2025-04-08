import os
import shutil
import urllib.request
import zipfile
from pathlib import Path
import PyInstaller.__main__
from generate_icon import create_icon

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

def build_windows():
    """Build Windows executable using PyInstaller"""
    ROOT_DIR = Path(__file__).parent.parent
    DIST_DIR = ROOT_DIR / "dist"
    BUILD_DIR = ROOT_DIR / "build"
    ICONS_DIR = ROOT_DIR / "icons"
    
    # Try to download and setup UPX
    upx_dir = download_upx()
    
    # Create required directories
    os.makedirs(ROOT_DIR / "resources" / "icons", exist_ok=True)
    os.makedirs(ROOT_DIR / "qml", exist_ok=True)
    os.makedirs(ROOT_DIR / "data", exist_ok=True)
    
    # Generate icon if it doesn't exist
    icon_path = create_icon()
    
    # Get relative paths from build script location
    main_script = str(ROOT_DIR / "main.py")
    resources_dir = str(ROOT_DIR / "resources")
    qml_dir = str(ROOT_DIR / "qml")
    data_dir = str(ROOT_DIR / "data")
    icons_dir = str(ICONS_DIR)
    
    # Clean previous builds
    for dir in [DIST_DIR, BUILD_DIR]:
        if dir.exists():
            shutil.rmtree(dir)
    
    # Base PyInstaller arguments
    pyinstaller_args = [
        main_script,
        '--name=ElectricalCalculator',
        '--windowed',
        f'--icon={icon_path}',
        f'--add-data={qml_dir};qml',
        f'--add-data={resources_dir};resources',
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
        '--strip',
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
    PyInstaller.__main__.run(pyinstaller_args)

if __name__ == '__main__':
    build_windows()
