import os
import sys
import shutil
from pathlib import Path
import PyInstaller.__main__
from generate_icon import create_icon

def build_windows():
    """Build Windows executable using PyInstaller"""
    ROOT_DIR = Path(__file__).parent.parent
    DIST_DIR = ROOT_DIR / "dist"
    BUILD_DIR = ROOT_DIR / "build"
    
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
    
    # Clean previous builds
    for dir in [DIST_DIR, BUILD_DIR]:
        if dir.exists():
            shutil.rmtree(dir)
    
    PyInstaller.__main__.run([
        main_script,
        '--name=ElectricalCalculator',
        '--windowed',
        f'--icon={icon_path}',  # Use generated icon
        f'--add-data={qml_dir};qml',
        f'--add-data={resources_dir};resources',
        f'--add-data={data_dir};data',
        '--hidden-import=PySide6.QtQml',
        '--hidden-import=PySide6.QtQuick',
        '--hidden-import=PySide6.QtCore',
        '--hidden-import=PySide6.QtGui',
        '--hidden-import=PySide6.QtWidgets',
        '--hidden-import=PySide6.QtCharts',
        '--paths=.',
        '--clean',
        '--onefile'
    ])

if __name__ == '__main__':
    build_windows()
