"""Cross-platform utilities for QML caching."""
import os
import sys
import tempfile
from pathlib import Path
from typing import Optional
import hashlib

def setup_qml_cache(current_dir: str, app_name: str = None) -> None:
    """Set up QML cache with versioning and monitoring.
    
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
            os.environ["QML_DISK_CACHE_MAX_SIZE"] = str(100 * 1024 * 1024)  # 100MB
            
            # Enable incremental compilation
            os.environ['QML_FORCE_DISK_CACHE'] = '1'
            
            # Set compiler cache path
            cache_path = _get_cache_path(app_name)
            os.environ['QML_DISK_CACHE'] = str(cache_path)
            return True
        except Exception as e:
            print(f"Warning: Could not set up QML disk cache: {e}")
            return False
    return False

def invalidate_qml_cache(file_path: str) -> None:
    """Invalidate QML cache for specific file."""
    from .cache_manager import CacheManager
    cache_manager = CacheManager()
    
    if cache_manager.is_qml_modified(file_path):
        cache_path = Path(os.environ.get('QML_DISK_CACHE', ''))
        if cache_path.exists():
            # Only remove cache for modified file
            cache_file = cache_path / hashlib.md5(
                file_path.encode()
            ).hexdigest()
            if cache_file.exists():
                cache_file.unlink()

def _get_cache_path(app_name: Optional[str]) -> Path:
    """Get platform-specific QML cache path."""
    if hasattr(sys, 'frozen'):  # Running as packaged executable
        return Path(tempfile.gettempdir()) / (app_name or "QmlTableView") / "QmlCache"
    else:
        return Path(os.getcwd()) / "cache"
