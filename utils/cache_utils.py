"""Cross-platform utilities for QML caching."""
import os
import sys
import tempfile

def setup_qml_cache(current_dir: str, app_name: str = None):
    """Set up QML disk cache for better performance.
    
    This is a cross-platform utility that works on both Windows and Linux.
    
    Args:
        current_dir (str): The application's current directory
        app_name (str, optional): The application name. Defaults to "QmlTableView".
    """
    if "QT_QPA_DISABLE_DISK_CACHE" not in os.environ:
        try:
            # Use the provided app name or default to "QmlTableView"
            app_name = app_name or "QmlTableView"
            
            if hasattr(sys, 'frozen'):  # Running as packaged executable
                # Use user's temp folder for packaged apps
                cache_dir = os.path.join(tempfile.gettempdir(), app_name, "QmlCache")
            else:
                # Use local cache directory in development
                cache_dir = os.path.join(current_dir, "cache")
            
            os.makedirs(cache_dir, exist_ok=True)
            os.environ["QML_DISK_CACHE_PATH"] = cache_dir
            
            # Set cache limits for better performance
            os.environ["QML_DISK_CACHE_MAX_SIZE"] = "512"  # 512MB disk cache
            return True
        except Exception as e:
            print(f"Warning: Could not set up QML disk cache: {e}")
            return False
    return False
