"""
Custom PyInstaller hook for PySide6 to ensure all necessary modules are included
"""
import os
from PyInstaller.utils.hooks import collect_data_files, collect_system_data_files

# Collect PySide6 data files (including Qt plugins and QML imports)
datas = collect_data_files('PySide6')

# Add Qt plugins (critical for Windows)
qt_plugins = collect_system_data_files('PySide6', 'plugins')
for plugin in qt_plugins:
    if 'platforms' in plugin[0] or 'styles' in plugin[0] or 'imageformats' in plugin[0]:
        datas.append(plugin)

# Get the QML modules path
qml_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "qml")
if os.path.exists(qml_path):
    datas.append((qml_path, "qml"))

# Include Qt Quick Controls
hiddenimports = [
    'PySide6.QtCore',
    'PySide6.QtGui',
    'PySide6.QtQml',
    'PySide6.QtQuick',
    'PySide6.QtQuickControls2',
    'PySide6.QtCharts',
    'PySide6.QtWidgets',
]
