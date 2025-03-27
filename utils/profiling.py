import time
import functools
import psutil
import platform
import gc
import os
import threading
from datetime import datetime

class PerformanceProfiler:
    """Singleton performance profiling utility"""
    _instance = None
    _lock = threading.RLock()
    
    @classmethod
    def get_instance(cls):
        """Get or create the singleton instance"""
        with cls._lock:
            if cls._instance is None:
                cls._instance = cls()
            return cls._instance
    
    def __init__(self):
        """Initialize the profiler with empty metrics"""
        self.enabled = False
        self.detailed_logging = False
        self.function_stats = {}
        self.frame_times = []
        self.last_frame_time = time.time()
        self.log_file = None
        self.system_stats = {
            "start_time": time.time(),
            "start_memory_mb": self._get_memory_usage(),
            "max_memory_mb": 0,
            "platform": platform.system(),
            "python_version": platform.python_version(),
            "cpu_count": psutil.cpu_count(logical=False),
            "logical_cores": psutil.cpu_count(logical=True)
        }
        
    def _get_memory_usage(self):
        """Get current memory usage in MB"""
        try:
            # Force garbage collection to get accurate memory usage
            gc.collect()
            process = psutil.Process(os.getpid())
            memory_info = process.memory_info()
            # Convert to MB
            return memory_info.rss / (1024 * 1024)
        except Exception as e:
            print(f"Error getting memory usage: {e}")
            return 0
            
    def enable(self):
        """Enable the profiler"""
        self.enabled = True
        # Create a log file with timestamp if detailed logging is enabled
        if self.detailed_logging and not self.log_file:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_dir = os.path.join(os.path.expanduser("~"), "Documents", "performance_logs")
            os.makedirs(log_dir, exist_ok=True)
            self.log_file = open(os.path.join(log_dir, f"perf_log_{timestamp}.txt"), "w")
            self.log_file.write("Timestamp,Function,Duration_ms,Memory_MB\n")
    
    def disable(self):
        """Disable the profiler"""
        self.enabled = False
        # Close log file if open
        if self.log_file:
            self.log_file.close()
            self.log_file = None
            
    def clear(self):
        """Clear all profiling data"""
        self.function_stats = {}
        self.frame_times = []
        self.last_frame_time = time.time()
        # Reset max memory but keep current memory as starting point
        current_memory = self._get_memory_usage()
        self.system_stats["start_time"] = time.time()
        self.system_stats["start_memory_mb"] = current_memory
        self.system_stats["max_memory_mb"] = current_memory
            
    def record_function_call(self, name, duration_ms, memory_mb=None):
        """Record statistics for a function call"""
        if not self.enabled:
            return
            
        # Update memory tracking
        if memory_mb is None:
            memory_mb = self._get_memory_usage()
            
        # Update max memory if current usage is higher
        if memory_mb > self.system_stats.get("max_memory_mb", 0):
            self.system_stats["max_memory_mb"] = memory_mb
            
        # Create stats entry if it doesn't exist
        if name not in self.function_stats:
            self.function_stats[name] = {
                "count": 0,
                "total_time_ms": 0,
                "min_time_ms": float('inf'),
                "max_time_ms": 0,
                "average_time_ms": 0
            }
            
        # Update stats
        stats = self.function_stats[name]
        stats["count"] += 1
        stats["total_time_ms"] += duration_ms
        stats["min_time_ms"] = min(stats["min_time_ms"], duration_ms)
        stats["max_time_ms"] = max(stats["max_time_ms"], duration_ms)
        stats["average_time_ms"] = stats["total_time_ms"] / stats["count"]
        
        # Log to file if detailed logging is enabled
        if self.detailed_logging and self.log_file:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
            self.log_file.write(f"{timestamp},{name},{duration_ms:.3f},{memory_mb:.2f}\n")
            self.log_file.flush()  # Ensure it's written immediately
    
    def record_frame(self):
        """Record frame time for UI performance tracking"""
        if not self.enabled:
            return
            
        current_time = time.time()
        frame_time_ms = (current_time - self.last_frame_time) * 1000
        self.last_frame_time = current_time
        
        # Only track reasonable frame times (exclude initial frames or pauses)
        if 1.0 <= frame_time_ms <= 1000.0:
            self.frame_times.append(frame_time_ms)
            # Limit the number of stored frame times to avoid memory growth
            if len(self.frame_times) > 1000:
                self.frame_times = self.frame_times[-1000:]
    
    def get_frame_stats(self):
        """Get statistics about frame times"""
        if not self.frame_times:
            return {
                "count": 0,
                "average_ms": 0,
                "min_ms": 0,
                "max_ms": 0,
                "fps": 0
            }
            
        count = len(self.frame_times)
        avg_time = sum(self.frame_times) / count
        fps = 1000 / avg_time if avg_time > 0 else 0
        
        return {
            "count": count,
            "average_ms": avg_time,
            "min_ms": min(self.frame_times),
            "max_ms": max(self.frame_times),
            "fps": fps
        }
    
    def print_summary(self):
        """Print a summary of profiling data with error handling"""
        if not self.enabled:
            print("Profiling is not enabled")
            return
            
        print("\n===== PERFORMANCE PROFILING SUMMARY =====")
        
        # Print system stats safely, handling missing keys
        print("\nSYSTEM INFORMATION:")
        system_stats = self.system_stats or {}
        print(f"Platform: {system_stats.get('platform', 'Unknown')}")
        print(f"Python: {system_stats.get('python_version', 'Unknown')}")
        print(f"CPU: {system_stats.get('cpu_count', 0)} cores ({system_stats.get('logical_cores', 0)} logical)")
        
        # Handle memory stats safely
        try:
            current_memory = self._get_memory_usage()
            start_memory = system_stats.get('start_memory_mb', 0)
            max_memory = system_stats.get('max_memory_mb', current_memory)
            
            print(f"Current Memory: {current_memory:.1f} MB")
            print(f"Starting Memory: {start_memory:.1f} MB")
            print(f"Max Memory: {max_memory:.1f} MB")
            print(f"Memory Growth: {(current_memory - start_memory):.1f} MB")
        except Exception as e:
            print(f"Error calculating memory stats: {e}")
            print("Memory stats: Unavailable")
            
        # Total execution time
        try:
            duration = time.time() - system_stats.get('start_time', time.time())
            print(f"Profiling Duration: {duration:.1f} seconds")
        except Exception:
            print("Profiling Duration: Unknown")
            
        # Frame stats
        try:
            frame_stats = self.get_frame_stats()
            if frame_stats["count"] > 0:
                print(f"\nFRAME PERFORMANCE:")
                print(f"Frame Count: {frame_stats['count']}")
                print(f"Average Frame Time: {frame_stats['average_ms']:.2f} ms")
                print(f"FPS: {frame_stats['fps']:.1f}")
                print(f"Min/Max Frame Time: {frame_stats['min_ms']:.2f}/{frame_stats['max_ms']:.2f} ms")
        except Exception as e:
            print(f"Error calculating frame stats: {e}")
            
        # Function stats
        if self.function_stats:
            print("\nFUNCTION PERFORMANCE:")
            print(f"{'Function':<40} {'Count':>8} {'Total (ms)':>12} {'Avg (ms)':>10} {'Min (ms)':>10} {'Max (ms)':>10}")
            print("-" * 100)
            
            # Sort by total time
            sorted_stats = sorted(self.function_stats.items(), 
                                 key=lambda x: x[1]['total_time_ms'], 
                                 reverse=True)
            
            for name, stats in sorted_stats:
                # Truncate long function names
                display_name = name if len(name) <= 37 else name[:34] + "..."
                print(f"{display_name:<40} {stats['count']:>8} {stats['total_time_ms']:>12.2f} "
                      f"{stats['average_time_ms']:>10.2f} {stats['min_time_ms']:>10.2f} "
                      f"{stats['max_time_ms']:>10.2f}")
        else:
            print("\nNo function calls recorded")
        
        print("\n========================================")

def profile(func):
    """Decorator to profile function execution time"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        profiler = PerformanceProfiler.get_instance()
        
        if not profiler.enabled:
            return func(*args, **kwargs)
            
        # Record memory before function call
        start_memory = profiler._get_memory_usage()
        start_time = time.time()
        
        try:
            result = func(*args, **kwargs)
        finally:
            end_time = time.time()
            end_memory = profiler._get_memory_usage()
            
            # Calculate execution time in milliseconds
            duration_ms = (end_time - start_time) * 1000
            
            # Get function name
            function_name = f"{func.__module__}.{func.__name__}"
            
            # Record in profiler
            profiler.record_function_call(
                function_name, 
                duration_ms, 
                end_memory
            )
            
        return result
    return wrapper