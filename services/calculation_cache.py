"""Efficient caching system for expensive calculations."""
import time
import hashlib
import threading
import json
from datetime import datetime
from typing import Dict, Any, Optional

class CalculationCache:
    """Thread-safe LRU cache for calculation results."""
    
    _instance = None
    _lock = threading.RLock()
    
    @classmethod
    def get_instance(cls):
        """Get or create the singleton instance."""
        with cls._lock:
            if cls._instance is None:
                cls._instance = cls()
            return cls._instance
    
    def __init__(self):
        """Initialize the cache with configuration parameters."""
        self._cache: Dict[str, Dict] = {}
        self._access_times: Dict[str, float] = {}
        self._hits = 0
        self._misses = 0
        self._max_size = 100  # Maximum number of cache entries
        self._enabled = True
        self._hit_threshold = 3  # Number of identical requests before caching
        self._request_counts: Dict[str, int] = {}
        
        # Add performance tracking
        self._perf_log = []
        self._timing_data = {}
        self._log_enabled = False
        self._log_file = None
        self._max_log_entries = 1000
        
    def start_timing(self, key: str, operation: str) -> None:
        """Start timing an operation for a specific key."""
        if not self._log_enabled:
            return
            
        with self._lock:
            if key not in self._timing_data:
                self._timing_data[key] = {}
            self._timing_data[key][operation] = time.time()
    
    def end_timing(self, key: str, operation: str, success: bool = True) -> None:
        """End timing an operation and record the result."""
        if not self._log_enabled:
            return
            
        with self._lock:
            if key in self._timing_data and operation in self._timing_data[key]:
                start_time = self._timing_data[key][operation]
                duration = time.time() - start_time
                
                # Log the performance data
                entry = {
                    "timestamp": datetime.now().isoformat(),
                    "key": key,
                    "operation": operation,
                    "duration_ms": duration * 1000,  # Convert to milliseconds
                    "success": success,
                    "cached": operation == "hit"
                }
                
                self._perf_log.append(entry)
                
                # Trim log if too large
                if len(self._perf_log) > self._max_log_entries:
                    self._perf_log = self._perf_log[-self._max_log_entries:]
                
                # Write to log file if enabled
                if self._log_file:
                    try:
                        with open(self._log_file, 'a') as f:
                            f.write(f"{entry['timestamp']},{entry['operation']},{entry['duration_ms']:.3f},{entry['cached']}\n")
                    except Exception as e:
                        print(f"Error writing to cache log: {e}")
                
                # Clean up
                del self._timing_data[key][operation]
    
    def get(self, key: str) -> Optional[Dict]:
        """Get a value from the cache if it exists."""
        if not self._enabled:
            return None
        
        self.start_timing(key, "lookup")
        with self._lock:
            if key in self._cache:
                self._hits += 1
                self._access_times[key] = time.time()
                result = self._cache[key]
                self.end_timing(key, "hit", True)
                return result
            self._misses += 1
            self.end_timing(key, "miss", False)
            return None
    
    def put(self, key: str, value: Dict) -> None:
        """Put a value in the cache, evicting old entries if needed."""
        if not self._enabled:
            return
        
        self.start_timing(key, "store")    
        with self._lock:
            # Increment request count for this key
            self._request_counts[key] = self._request_counts.get(key, 0) + 1
            
            # Only cache if this calculation has been requested multiple times
            if self._request_counts[key] >= self._hit_threshold:
                # Ensure we don't exceed maximum size
                if len(self._cache) >= self._max_size and key not in self._cache:
                    # Evict least recently used item
                    lru_key = min(self._access_times.items(), key=lambda x: x[1])[0]
                    self._cache.pop(lru_key, None)
                    self._access_times.pop(lru_key, None)
                
                # Store in cache
                self._cache[key] = value
                self._access_times[key] = time.time()
        
        self.end_timing(key, "store", True)
    
    def clear(self) -> None:
        """Clear the cache."""
        with self._lock:
            self._cache.clear()
            self._access_times.clear()
            self._request_counts.clear()
            self._hits = 0
            self._misses = 0
    
    def enable(self, enabled: bool = True) -> None:
        """Enable or disable the cache."""
        self._enabled = enabled
    
    def enable_logging(self, enabled: bool = True, log_file: Optional[str] = None) -> None:
        """Enable or disable performance logging."""
        with self._lock:
            self._log_enabled = enabled
            if log_file and enabled:
                self._log_file = log_file
                # Create or clear the log file
                try:
                    with open(self._log_file, 'w') as f:
                        f.write("timestamp,operation,duration_ms,cached\n")
                except Exception as e:
                    print(f"Error creating cache log file: {e}")
            elif not enabled:
                self._log_file = None
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        with self._lock:
            return {
                "hits": self._hits,
                "misses": self._misses,
                "hit_ratio": self._hits / (self._hits + self._misses) if (self._hits + self._misses) > 0 else 0,
                "size": len(self._cache),
                "max_size": self._max_size,
                "enabled": self._enabled
            }
    
    def get_performance_report(self) -> Dict[str, Any]:
        """Generate a performance improvement report."""
        with self._lock:
            if not self._perf_log:
                return {"status": "No performance data available"}
            
            # Calculate time saved by cache hits
            hit_times = [entry["duration_ms"] for entry in self._perf_log if entry["operation"] == "hit"]
            miss_times = [entry["duration_ms"] for entry in self._perf_log if entry["operation"] == "miss"]
            
            avg_hit_time = sum(hit_times) / len(hit_times) if hit_times else 0
            avg_miss_time = sum(miss_times) / len(miss_times) if miss_times else 0
            
            # Time saved is the difference between what a miss would have cost vs a hit
            time_saved_per_hit = avg_miss_time - avg_hit_time
            total_time_saved = time_saved_per_hit * len(hit_times)
            
            # Report stats
            return {
                "total_operations": len(self._perf_log),
                "hit_count": len(hit_times),
                "miss_count": len(miss_times),
                "avg_hit_time_ms": avg_hit_time,
                "avg_miss_time_ms": avg_miss_time,
                "time_saved_ms": total_time_saved,
                "hit_ratio": len(hit_times) / (len(hit_times) + len(miss_times)) if (len(hit_times) + len(miss_times)) > 0 else 0,
                "performance_improvement": (avg_miss_time / avg_hit_time) if avg_hit_time > 0 else 0
            }
    
    def export_performance_log(self, filename: str) -> bool:
        """Export the performance log to a CSV file."""
        try:
            with open(filename, 'w') as f:
                f.write("timestamp,operation,duration_ms,cached\n")
                for entry in self._perf_log:
                    f.write(f"{entry['timestamp']},{entry['operation']},{entry['duration_ms']:.3f},{entry['cached']}\n")
            return True
        except Exception as e:
            print(f"Error exporting performance log: {e}")
            return False
    
    def set_max_size(self, size: int) -> None:
        """Set the maximum cache size."""
        if size < 1:
            raise ValueError("Cache size must be positive")
        
        with self._lock:
            self._max_size = size
            
            # If current cache is too large, trim it
            while len(self._cache) > self._max_size:
                lru_key = min(self._access_times.items(), key=lambda x: x[1])[0]
                self._cache.pop(lru_key, None)
                self._access_times.pop(lru_key, None)

def generate_cache_key(params: Dict[str, Any]) -> str:
    """Generate a deterministic cache key from calculation parameters."""
    # Convert parameters to a JSON string (sorted to ensure determinism)
    param_str = json.dumps(params, sort_keys=True)
    # Create a hash for the parameter string
    return hashlib.md5(param_str.encode('utf-8')).hexdigest()
