#!/usr/bin/env python
"""
check_cache.py - Utility to verify QML caching is working effectively
"""

import os
import sys
import time
from pathlib import Path

# Add the project root to the Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

from utils.cache_manager import CacheManager

def check_cache_persistence():
    """Check if the QML cache exists and is being used between sessions"""
    print("\n=== QML Cache Inspector ===\n")
    
    # Initialize cache manager
    cache = CacheManager()
    cache.initialize()
    
    # Get cache info
    info = cache.get_cache_info()
    
    if not info["enabled"]:
        print("❌ QML cache is DISABLED")
        print("   No persistence between sessions will occur")
        return
    
    print(f"✅ QML cache is ENABLED")
    print(f"   Cache directory: {info['directory']}")
    
    if info["files"] > 0:
        print(f"✅ Found existing cache with {info['files']} files ({info['size_mb']} MB)")
        print("   Cache is persisting between application sessions")
        
        # List some cache files for verification
        print("\nSample cache files:")
        try:
            for i, path in enumerate(Path(info['directory']).rglob('*')):
                if path.is_file():
                    modified_time = time.ctime(path.stat().st_mtime)
                    size_kb = path.stat().st_size / 1024
                    print(f"   - {path.name} ({size_kb:.1f} KB, modified: {modified_time})")
                    if i >= 4:  # Show only first 5 files
                        print(f"   - ... and {info['files'] - 5} more files")
                        break
        except Exception as e:
            print(f"   Error listing cache files: {e}")
    else:
        print("⚠️ No cache files found. This could mean:")
        print("   1. The application hasn't been run yet")
        print("   2. The cache was recently cleared")
        print("   3. The cache isn't working properly")
    
    # Check environment variables
    print("\nCaching environment variables:")
    cache_path = os.environ.get("QML_DISK_CACHE_PATH", "Not set")
    cache_size = os.environ.get("QML_DISK_CACHE_MAX_SIZE", "Not set")
    cache_disabled = os.environ.get("QT_QPA_DISABLE_DISK_CACHE", "No")
    
    print(f"   QML_DISK_CACHE_PATH: {cache_path}")
    print(f"   QML_DISK_CACHE_MAX_SIZE: {cache_size}")
    print(f"   QT_QPA_DISABLE_DISK_CACHE: {cache_disabled}")
    
    print("\nCache performance recommendations:")
    if info["files"] > 0:
        print("✅ Cache appears to be working correctly and persisting between sessions")
        
        # Check cache size and suggest tuning if needed
        if info["size_mb"] > 400:
            print("⚠️ Cache is getting large. Consider increasing QML_DISK_CACHE_MAX_SIZE or clearing old entries")
        elif info["size_mb"] < 1:
            print("⚠️ Cache is very small. The application might not be caching properly")
    else:
        print("⚠️ To improve caching performance:")
        print("   1. Make sure cache directory is writable")
        print("   2. Run the application at least once with --debug flag")
        print("   3. Check for any caching errors in the console output")
    
    # Offer to clear the cache
    if info["files"] > 0:
        choice = input("\nWould you like to clear the cache? (y/n): ")
        if choice.lower() == 'y':
            if cache.clear_cache():
                print("✅ Cache cleared successfully")
            else:
                print("❌ Failed to clear cache")

def main():
    check_cache_persistence()
    
if __name__ == "__main__":
    main()