"""
Runtime hooks for PyInstaller to initialize correctly on Windows
"""
import os
import sys
import pathlib

# Fix QML import path at runtime
base_dir = getattr(sys, '_MEIPASS', os.path.abspath(os.path.dirname(__file__)))
os.environ["QML_IMPORT_PATH"] = os.path.join(base_dir, "qml")
os.environ["QML2_IMPORT_PATH"] = os.path.join(base_dir, "qml")

# Set up app directories for storing user data and logs
def setup_app_dirs():
    """Create application directories for storing user data"""
    app_name = "QMLTest"
    app_data = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), app_name)
    
    # Create directories
    for subdir in ["data", "logs", "cache"]:
        full_path = os.path.join(app_data, subdir)
        pathlib.Path(full_path).mkdir(parents=True, exist_ok=True)
        
    return app_data

# Create app directories
APP_DATA = setup_app_dirs()
