import os
import sys
from PySide6.QtCore import QLibraryInfo

def check_qt_plugins():
    """Check Qt plugin paths and available plugins."""
    plugin_path = QLibraryInfo.path(QLibraryInfo.PluginsPath)
    print(f"Qt plugin path: {plugin_path}")
    
    # Check for QtSvg plugin
    svg_plugin = os.path.join(plugin_path, "imageformats", "qsvg.dll" if sys.platform == "win32" else "libqsvg.so")
    if os.path.exists(svg_plugin):
        print(f"QtSvg plugin found at: {svg_plugin}")
    else:
        print(f"QtSvg plugin not found at: {svg_plugin}")
        
    # Check directory contents
    imageformats_dir = os.path.join(plugin_path, "imageformats")
    if os.path.isdir(imageformats_dir):
        print(f"\nContents of {imageformats_dir}:")
        for file in os.listdir(imageformats_dir):
            print(f"  - {file}")
    else:
        print(f"Directory not found: {imageformats_dir}")
        
if __name__ == "__main__":
    check_qt_plugins()
