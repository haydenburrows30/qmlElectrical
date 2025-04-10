"""
PyInstaller configuration for Windows compilation
"""
import os
import sys
from pathlib import Path

# Add the application directory to path
app_path = Path(__file__).resolve().parent.parent
sys.path.append(str(app_path))

# Configuration for PyInstaller
datas = [
    # Include QML files
    (str(app_path / 'qml'), 'qml'),
    # Include icons
    (str(app_path / 'icons'), 'icons'),
    # Include additional resources
    (str(app_path / 'resources'), 'resources'),
]

# QML plugins needed
binaries = []

# Hidden imports to ensure all required modules are included
hiddenimports = [
    'PySide6.QtQml',
    'PySide6.QtQuick',
    'PySide6.QtCore',
    'PySide6.QtGui',
    'PySide6.QtWidgets',
    'PySide6.QtCharts',
    'numpy',
    'pyqtgraph',
]

# Exclude unnecessary packages to reduce size
excludes = [
    'tkinter',
    'matplotlib',
    'scipy',
    'PIL',
    'pytest',
    'sphinx',
    '_tkinter',
    'unittest',
    'doctest',
    'pdb',
]
