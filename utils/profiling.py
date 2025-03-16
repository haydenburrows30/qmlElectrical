import time
import functools
from collections import defaultdict
import threading
import statistics
import psutil  # Add system monitoring
import gc      # Add garbage collection monitoring

class PerformanceProfiler:
    """Utility class for performance profiling across the application"""
    
    _instance = None
    _lock = threading.RLock()
    
    @classmethod
    def get_instance(cls):
        """Get singleton instance of the profiler"""
        with cls._lock:
            if cls._instance is None:
                cls._instance = cls()
            return cls._instance
    
    def __init__(self):
        self.profiling_enabled = False
        self.profile_data = defaultdict(list)  # Method name -> list of execution times
        self.call_counts = defaultdict(int)    # Method name -> number of calls
        self.frame_times = []  # Store frame render times
        self.last_frame_time = time.time()
        self.system_stats = []  # Store CPU/memory usage
        self.max_samples = 100  # Limit data collection to prevent memory issues
        self.detailed_logging = False  # Enable for verbose logging
        
    def enable(self):
        """Enable performance profiling"""
        self.profiling_enabled = True
        self.last_frame_time = time.time()
        
    def disable(self):
        """Disable performance profiling"""
        self.profiling_enabled = False
    
    def clear(self):
        """Clear all profiling data"""
        self.profile_data.clear()
        self.call_counts.clear()
        self.frame_times.clear()
        self.system_stats.clear()
        self.last_frame_time = time.time()
        
    def record_execution(self, method_name, execution_time):
        """Record execution time for a method"""
        if not self.profiling_enabled:
            return
            
        with self._lock:
            # Limit data collection to prevent memory issues
            if len(self.profile_data[method_name]) >= self.max_samples:
                self.profile_data[method_name].pop(0)  # Remove oldest
                
            self.profile_data[method_name].append(execution_time)
            self.call_counts[method_name] += 1
            
            # Detailed logging for very slow operations
            if self.detailed_logging and execution_time > 0.1:  # > 100ms
                print(f"SLOW OPERATION: {method_name} took {execution_time*1000:.2f}ms")
    
    def record_frame(self):
        """Record frame time for UI performance tracking"""
        if not self.profiling_enabled:
            return
            
        current_time = time.time()
        frame_time = current_time - self.last_frame_time
        self.last_frame_time = current_time
        
        with self._lock:
            if len(self.frame_times) >= self.max_samples:
                self.frame_times.pop(0)  # Remove oldest
            self.frame_times.append(frame_time)
            
            # Record system stats every 10 frames
            if len(self.frame_times) % 10 == 0:
                self.record_system_stats()
    
    def record_system_stats(self):
        """Record system resource usage"""
        if not self.profiling_enabled:
            return
            
        try:
            # Get memory and CPU stats
            process = psutil.Process()
            mem_info = process.memory_info()
            cpu_percent = process.cpu_percent(interval=0.1)
            
            stats = {
                "timestamp": time.time(),
                "memory_mb": mem_info.rss / (1024 * 1024),
                "cpu_percent": cpu_percent,
                "gc_objects": len(gc.get_objects()),
            }
            
            with self._lock:
                if len(self.system_stats) >= self.max_samples:
                    self.system_stats.pop(0)
                self.system_stats.append(stats)
                
        except Exception as e:
            print(f"Error recording system stats: {e}")
    
    def get_frame_stats(self):
        """Get frame timing statistics"""
        with self._lock:
            if not self.frame_times:
                return {"avg_fps": 0, "min_fps": 0, "max_fps": 0, "frame_count": 0}
                
            frame_times = self.frame_times.copy()
            
        # Calculate FPS stats (excluding outliers)
        frame_times.sort()
        # Remove top and bottom 10% to avoid outliers
        trim = max(1, int(len(frame_times) * 0.1))
        trimmed_times = frame_times[trim:-trim] if len(frame_times) > trim*2 else frame_times
        
        avg_time = statistics.mean(trimmed_times) if trimmed_times else 0
        min_time = min(trimmed_times) if trimmed_times else 0
        max_time = max(trimmed_times) if trimmed_times else 0
        
        # Convert times to FPS (frames per second)
        avg_fps = 1.0 / avg_time if avg_time > 0 else 0
        min_fps = 1.0 / max_time if max_time > 0 else 0
        max_fps = 1.0 / min_time if min_time > 0 else 0
        
        return {
            "avg_fps": avg_fps,
            "min_fps": min_fps,
            "max_fps": max_fps,
            "frame_count": len(self.frame_times)
        }
        
    def get_system_stats(self):
        """Get system resource usage summary"""
        with self._lock:
            if not self.system_stats:
                return {"avg_memory_mb": 0, "avg_cpu": 0}
                
            memory_values = [s["memory_mb"] for s in self.system_stats]
            cpu_values = [s["cpu_percent"] for s in self.system_stats]
            
        return {
            "avg_memory_mb": statistics.mean(memory_values) if memory_values else 0,
            "max_memory_mb": max(memory_values) if memory_values else 0,
            "avg_cpu": statistics.mean(cpu_values) if cpu_values else 0,
            "max_cpu": max(cpu_values) if cpu_values else 0
        }
    
    def get_summary(self):
        """Get summary of profiling data"""
        result = []
        
        with self._lock:
            for method_name, times in self.profile_data.items():
                if not times:
                    continue
                    
                result.append({
                    "method": method_name,
                    "calls": self.call_counts[method_name],
                    "total_time": sum(times),
                    "avg_time": statistics.mean(times) if times else 0,
                    "min_time": min(times) if times else 0,
                    "max_time": max(times) if times else 0,
                    "median_time": statistics.median(times) if times else 0,
                })
                
        # Sort by total time (highest first)
        result.sort(key=lambda x: x["total_time"], reverse=True)
        return result
    
    def print_summary(self):
        """Print profiling summary to console"""
        summary = self.get_summary()
        frame_stats = self.get_frame_stats()
        system_stats = self.get_system_stats()
        
        print("\n===== PERFORMANCE PROFILING SUMMARY =====")
        
        # Print UI performance first
        print("\n--- UI Performance ---")
        print(f"Average FPS: {frame_stats['avg_fps']:.1f}")
        print(f"Min FPS: {frame_stats['min_fps']:.1f}")
        print(f"Max FPS: {frame_stats['max_fps']:.1f}")
        print(f"Frame count: {frame_stats['frame_count']}")
        
        # Print system resource usage
        print("\n--- System Resources ---")
        print(f"Average Memory: {system_stats['avg_memory_mb']:.1f} MB")
        print(f"Max Memory: {system_stats['max_memory_mb']:.1f} MB")
        print(f"Average CPU: {system_stats['avg_cpu']:.1f}%")
        print(f"Max CPU: {system_stats['max_cpu']:.1f}%")
        
        # Print method performance
        print("\n--- Method Performance ---")
        print("{:<30} {:<10} {:<12} {:<12} {:<12}".format(
            "Method", "Calls", "Total (ms)", "Avg (ms)", "Max (ms)"))
        print("-" * 80)
        
        for item in summary:
            print("{:<30} {:<10} {:<12.2f} {:<12.2f} {:<12.2f}".format(
                item["method"], 
                item["calls"],
                item["total_time"] * 1000,  # Convert to ms
                item["avg_time"] * 1000,    # Convert to ms
                item["max_time"] * 1000     # Convert to ms
            ))
            
            # Add detailed analysis for slow methods
            if item["avg_time"] * 1000 > 100:  # If average time > 100ms
                print(f"   ⚠️ PERFORMANCE BOTTLENECK: {item['method']} is very slow")
                print(f"      Consider reducing connections or optimizing implementation")
            
        print("\n--- Potential Issues ---")
        
        # Check for potential QML bottlenecks
        if frame_stats['avg_fps'] < 30:
            print("⚠️ Low frame rate detected! UI operations may be causing lag.")
            print("   Solutions: Reduce QML animations, simplify UI, or optimize data binding")
        
        # Check for potential Python bottlenecks
        if system_stats['max_cpu'] > 80:
            print("⚠️ High CPU usage detected! Python calculations may be causing lag.")
            print("   Solutions: Optimize calculations, add caching, or move to background thread")
            
        print("========================================\n")

def profile(func=None, *, disabled=False):
    """Decorator for profiling methods
    
    Args:
        func: Function to decorate
        disabled: If True, profiling will be disabled for this method
        
    Usage:
        @profile  # Basic usage
        def my_method():
            pass
            
        @profile(disabled=True)  # Disable for specific method
        def another_method():
            pass
    """
    def decorator(f):
        @functools.wraps(f)
        def wrapper(*args, **kwargs):
            profiler = PerformanceProfiler.get_instance()
            
            if disabled or not profiler.profiling_enabled:
                return f(*args, **kwargs)
                
            start_time = time.time()
            try:
                result = f(*args, **kwargs)
            finally:
                end_time = time.time()
                execution_time = end_time - start_time
                profiler.record_execution(f.__qualname__, execution_time)
                
            return result
        return wrapper
        
    # Handle both @profile and @profile(disabled=...)
    if func is None:
        return decorator
    return decorator(func)
