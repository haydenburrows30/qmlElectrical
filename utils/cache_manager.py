import os
import json
import hashlib
import time
from pathlib import Path
from typing import Dict, Any, Optional
from functools import lru_cache

class CacheManager:
    CACHE_VERSION = "1.0"
    
    def __init__(self):
        self.cache_dir = None
        self.metadata_file = None
        self.memory_cache: Dict[str, Any] = {}
        self.max_cache_size = 100 * 1024 * 1024  # 100MB

    def initialize(self, app_name: str) -> None:
        """Initialize cache manager with application specific settings"""
        self.cache_dir = Path.home() / ".cache" / app_name
        self.metadata_file = self.cache_dir / "cache_metadata.json"
        self._init_cache_dir()

    def _init_cache_dir(self) -> None:
        """Initialize cache directory and metadata"""
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        if not self.metadata_file.exists():
            self._save_metadata({
                "version": self.CACHE_VERSION,
                "last_cleanup": time.time(),
                "file_hashes": {}
            })

    @lru_cache(maxsize=1000)
    def get_cached_calculation(self, key: str) -> Optional[Any]:
        """Get cached calculation result with memory caching"""
        if key in self.memory_cache:
            return self.memory_cache[key]
        
        cache_file = self.cache_dir / f"{key}.cache"
        if cache_file.exists():
            try:
                with open(cache_file, 'r') as f:
                    result = json.load(f)
                self.memory_cache[key] = result
                return result
            except Exception:
                return None
        return None

    def cache_calculation(self, key: str, value: Any) -> None:
        """Cache calculation result both in memory and on disk"""
        self.memory_cache[key] = value
        cache_file = self.cache_dir / f"{key}.cache"
        
        try:
            with open(cache_file, 'w') as f:
                json.dump(value, f)
            self._manage_cache_size()
        except Exception as e:
            print(f"Failed to cache calculation: {e}")

    def _manage_cache_size(self) -> None:
        """Manage cache size and cleanup old entries"""
        total_size = sum(f.stat().st_size for f in self.cache_dir.glob('*.cache'))
        
        if total_size > self.max_cache_size:
            files = sorted(
                self.cache_dir.glob('*.cache'),
                key=lambda x: x.stat().st_atime
            )
            
            # Remove oldest files until under max size
            for file in files:
                if total_size <= self.max_cache_size:
                    break
                total_size -= file.stat().st_size
                file.unlink()

    def is_qml_modified(self, file_path: str) -> bool:
        """Check if QML file has been modified since last cache"""
        metadata = self._load_metadata()
        file_path = str(Path(file_path).resolve())
        current_hash = self._calculate_file_hash(file_path)
        
        if file_path not in metadata["file_hashes"]:
            metadata["file_hashes"][file_path] = current_hash
            self._save_metadata(metadata)
            return True
            
        return metadata["file_hashes"][file_path] != current_hash

    def _calculate_file_hash(self, file_path: str) -> str:
        """Calculate file hash for cache invalidation"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception:
            return ""

    def _load_metadata(self) -> Dict:
        """Load cache metadata"""
        try:
            with open(self.metadata_file, 'r') as f:
                return json.load(f)
        except Exception:
            return {"version": self.CACHE_VERSION, "file_hashes": {}}

    def _save_metadata(self, metadata: Dict) -> None:
        """Save cache metadata"""
        with open(self.metadata_file, 'w') as f:
            json.dump(metadata, f)

    def clear_cache(self) -> None:
        """Clear all cache data"""
        self.memory_cache.clear()
        for cache_file in self.cache_dir.glob('*.cache'):
            cache_file.unlink()
        self._save_metadata({
            "version": self.CACHE_VERSION,
            "last_cleanup": time.time(),
            "file_hashes": {}
        })