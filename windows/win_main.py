"""
Entry point for Windows executable
"""
import os
import sys
from pathlib import Path

# Ensure we can import from the parent directory
app_path = Path(__file__).resolve().parent.parent
sys.path.append(str(app_path))

# Set environment variables needed for PySide6
os.environ["QT_QPA_PLATFORM_PLUGIN_PATH"] = os.path.join(os.path.dirname(os.path.abspath(__file__)), "platforms")
os.environ["QML_IMPORT_PATH"] = os.path.join(app_path, "qml")
os.environ["QML2_IMPORT_PATH"] = os.path.join(app_path, "qml")

# Windows-specific performance settings
os.environ["QT_ENABLE_HIGHDPI_SCALING"] = "0"
os.environ["QT_SCALE_FACTOR"] = "1"
os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"
os.environ["QT_OPENGL"] = "software"  # Use software OpenGL for better compatibility

# Import the main application
from main import main

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        # Create error log if application crashes
        with open(os.path.join(app_path, "error_log.txt"), "w") as f:
            import traceback
            f.write(f"Error running application: {e}\n")
            f.write(traceback.format_exc())
        sys.exit(1)
