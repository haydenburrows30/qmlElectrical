import os
import sys
import time
from pathlib import Path

class CacheManager:
    """Manages QML cache for the application to improve load times."""
    
    def __init__(self):
        self._cache_dir = None
        self._cache_enabled = True
        self._cache_stats = {"hits": 0, "misses": 0}
    
    def initialize(self, app_name="QmlTableView"):
        """Initialize the cache directory and settings."""
        try:
            # Check if caching is explicitly disabled
            if "QT_QPA_DISABLE_DISK_CACHE" in os.environ:
                self._cache_enabled = False
                print("QML cache is explicitly disabled via environment variable")
                return False
                
            # Determine appropriate cache location based on platform and app state
            if hasattr(sys, 'frozen'):  # Running as packaged executable
                # Use user's AppData folder for packaged apps
                import tempfile
                self._cache_dir = os.path.join(tempfile.gettempdir(), app_name, "QmlCache")
            else:
                # Use local cache directory in development
                base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
                self._cache_dir = os.path.join(base_dir, "cache")
            
            # Ensure the cache directory exists
            os.makedirs(self._cache_dir, exist_ok=True)
            
            # Set environment variables for Qt to use the cache
            os.environ["QML_DISK_CACHE_PATH"] = self._cache_dir
            
            # Set reasonable cache size limit (512MB)
            os.environ["QML_DISK_CACHE_MAX_SIZE"] = "512"
            
            # Verify cache is working by checking directory
            self._verify_cache_directory()
            
            return True
            
        except Exception as e:
            print(f"Warning: Cache initialization failed: {e}")
            self._cache_enabled = False
            return False
    
    def _verify_cache_directory(self):
        """Verify the cache directory exists and is writable."""
        if not self._cache_dir or not os.path.exists(self._cache_dir):
            print(f"Warning: Cache directory doesn't exist: {self._cache_dir}")
            return False
            
        # Check if directory is writable by creating a test file
        test_file = os.path.join(self._cache_dir, "write_test.tmp")
        try:
            with open(test_file, 'w') as f:
                f.write("test")
            os.remove(test_file)
            return True
        except Exception as e:
            print(f"Warning: Cache directory is not writable: {e}")
            return False
    
    def get_cache_info(self):
        """Get information about the cache status and statistics."""
        if not self._cache_enabled or not self._cache_dir:
            return {"enabled": False, "directory": None, "size": 0, "files": 0}
        
        # Calculate cache size and file count
        total_size = 0
        file_count = 0
        
        try:
            for path in Path(self._cache_dir).rglob('*'):
                if path.is_file():
                    total_size += path.stat().st_size
                    file_count += 1
        except Exception as e:
            print(f"Error calculating cache size: {e}")
        
        return {
            "enabled": self._cache_enabled,
            "directory": self._cache_dir,
            "size": total_size,
            "size_mb": round(total_size / (1024 * 1024), 2),
            "files": file_count,
            "stats": self._cache_stats
        }
    
    def clear_cache(self):
        """Clear all cache files."""
        if not self._cache_enabled or not self._cache_dir:
            return False
            
        try:
            for path in Path(self._cache_dir).rglob('*'):
                if path.is_file():
                    path.unlink()
            return True
        except Exception as e:
            print(f"Error clearing cache: {e}")
            return False